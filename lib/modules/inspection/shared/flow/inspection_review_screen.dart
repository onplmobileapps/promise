import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/files/app_downloads.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report_pdf.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';

/// Keeps a finished inspection, signed with [signatures]: what was said
/// of it, or why it couldn't be kept.
typedef InspectionSubmitter =
    Future<Either<AppException, String>> Function(
      InspectionSignatures signatures,
    );

/// A finished inspection, signed with [signatures], as it goes to the
/// server: sent at once, or kept to go out by itself when there is no
/// connection.
typedef InspectionParcel = OutboxItem Function(InspectionSignatures signatures);

/// Draws a report as the PDF it goes out as.
typedef ReportRenderer =
    Future<Uint8List> Function(
      InspectionReport report,
      AppLocalizations l10n,
      String locale,
    );

Future<Uint8List> _renderPdf(
  InspectionReport report,
  AppLocalizations l10n,
  String locale,
) async => InspectionReportPdf(
  report,
  l10n,
  await ReportAssets.load(),
  locale: locale,
).build();

/// Shows [report], every answer and the PDF it will go out as, and lets
/// it be submitted only once the inspector has read and confirmed it and
/// verified their face again. True once it was submitted.
///
/// An inspection the server takes is given as its [send] parcel: it goes
/// out at once, or, with no connection, waits on the phone and goes out
/// by itself. One kept on the phone is given as [submit].
///
/// The report is signed with the face check the inspection was started
/// with (its [InspectionSession]) and the one made here. Opened from an
/// inspection form, a tap on an answer takes the inspector back to it.
Future<bool> reviewAndSubmit(
  BuildContext context, {
  required InspectionReport report,
  InspectionSubmitter? submit,
  InspectionParcel? send,
  InspectionFaceVerifier? verifier,
  ReportRenderer? render,
}) async {
  assert(submit != null || send != null, 'Nothing to submit the report to');
  FocusManager.instance.primaryFocus?.unfocus();
  final start = InspectionSession.maybeOf(context)?.start;
  final edit = InspectionEditing.current;
  final outcome = await Navigator.of(context).push<Object?>(
    MaterialPageRoute(
      builder: (_) => InspectionReviewScreen(
        report: report.copyWith(
          signatures: report.signatures.copyWith(start: start),
        ),
        submit: submit,
        send: send,
        verifier: verifier,
        render: render,
        editable: edit != null,
      ),
    ),
  );
  if (outcome is InspectionEdit) edit?.call(outcome);
  return outcome == true;
}

/// The last steps of an inspection: read the report, confirm it, verify
/// the face, submit. Each opens only once the one before is done.
///
/// The report reads as its answers, section by section, and as its PDF.
/// When [editable], a tap on an answer closes the review with an
/// [InspectionEdit] saying which.
class InspectionReviewScreen extends StatefulWidget {
  const InspectionReviewScreen({
    super.key,
    required this.report,
    this.submit,
    this.send,
    this.verifier,
    this.render,
    this.editable = false,
  });

  final InspectionReport report;
  final InspectionSubmitter? submit;
  final InspectionParcel? send;
  final InspectionFaceVerifier? verifier;

  /// Draws the PDF; [InspectionReportPdf] unless a test stands in.
  final ReportRenderer? render;
  final bool editable;

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

enum _Step { review, verify, submit }

/// The answers shown: every one, those that report something wrong, or
/// those left blank.
enum _Showing { all, findings, blank }

class _InspectionReviewScreenState extends State<InspectionReviewScreen>
    with SingleTickerProviderStateMixin {
  late InspectionReport _report = widget.report;
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    animationDuration: Duration.zero,
  )..addListener(_tabChanged);
  _Showing _showing = _Showing.all;
  Uint8List? _pdf;
  List<ui.Image>? _pages;

  /// The report couldn't be drawn as pages; it is shown as a list instead.
  bool _noPreview = false;
  bool _confirmed = false;
  bool _verifying = false;
  bool _submitting = false;

  /// Bumped for each new drawing, so a slower older one is dropped.
  int _drawing = 0;

  InspectionFaceVerifier get _verifier =>
      widget.verifier ?? sl<InspectionFaceVerifier>();

  _Step get _step => !_confirmed
      ? _Step.review
      : _report.signatures.submit == null
      ? _Step.verify
      : _Step.submit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pdf == null && _drawing == 0) unawaited(_prepare());
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    _disposePages(_pages);
    super.dispose();
  }

  void _tabChanged() {
    if (!_tabs.indexIsChanging) setState(() {});
  }

  void _disposePages(List<ui.Image>? pages) {
    for (final page in pages ?? const <ui.Image>[]) {
      page.dispose();
    }
  }

  Future<void> _prepare() async {
    final user = (await StorageService.getUser())?.user;
    final inspector = [
      user?.fullName?.trim() ?? '',
      user?.designation?.trim() ?? '',
    ].where((part) => part.isNotEmpty).join(' · ');
    if (inspector.isNotEmpty) _report = _report.copyWith(inspector: inspector);
    await _draw();
  }

  /// Makes the PDF of the report as it stands, and its pages to show.
  Future<void> _draw() async {
    if (!mounted) return;
    final drawing = ++_drawing;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final view = MediaQuery.of(context);
    try {
      final pdf = await (widget.render ?? _renderPdf)(_report, l10n, locale);
      if (!mounted || drawing != _drawing) return;
      setState(() => _pdf = pdf);
      // Sharp at the screen's own width, never heavier than it needs.
      final pixels = view.size.width * view.devicePixelRatio;
      final dpi = (pixels / (PdfPageFormat.a4.width / PdfPageFormat.inch))
          .clamp(72.0, 160.0);
      final pages = <ui.Image>[];
      await for (final page in Printing.raster(pdf, dpi: dpi)) {
        pages.add(await page.toImage());
      }
      if (!mounted || drawing != _drawing) {
        _disposePages(pages);
        return;
      }
      final old = _pages;
      setState(() {
        _pages = pages;
        _noPreview = pages.isEmpty;
      });
      _disposePages(old);
    } catch (_) {
      // No way to draw pages here: the report shows as a list.
      if (mounted && drawing == _drawing) setState(() => _noPreview = true);
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    final result = await _verifier.verify(context, InspectionMoment.submit);
    if (!mounted) return;
    setState(() => _verifying = false);
    switch (result) {
      case FaceCheckPassed(:final identity):
        setState(
          () => _report = _report.copyWith(
            signatures: _report.signatures.copyWith(submit: identity),
          ),
        );
        // The PDF that goes out carries the check.
        unawaited(_draw());
        if (!identity.matched) {
          await showAppMessage(context, context.l10n.inspFaceKeptOffline);
        }
      case FaceCheckFailed(:final message):
        await showAppDialog(
          context: context,
          tone: AppDialogTone.error,
          title: context.l10n.inspVerifyFailedTitle,
          message: message,
          primaryLabel: context.l10n.actionOk,
        );
      case FaceCheckCancelled():
        break;
    }
  }

  Future<void> _submit() async {
    if (_submitting || _step != _Step.submit) return;
    setState(() => _submitting = true);
    final send = widget.send;
    final Either<AppException, InspectionDelivery> result;
    if (send != null) {
      result = await deliverInspection(
        send(_report.signatures),
        outbox: sl<InspectionOutbox>(),
        repository: sl<InspectionRepository>(),
        matcher: sl<InspectionFaceMatcher>(),
      );
    } else {
      result = (await widget.submit!(
        _report.signatures,
      )).fold(Left.new, (said) => Right(InspectionDelivery.sent(said)));
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    final l10n = context.l10n;
    final failure = result.fold<AppException?>((e) => e, (_) => null);
    if (failure != null) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.error,
        title: l10n.inspSubmitFailedTitle,
        message: failure.message,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    final delivery = result.fold(
      (_) => const InspectionDelivery.queued(),
      (done) => done,
    );
    await showAppDialog(
      context: context,
      tone: delivery.queued ? AppDialogTone.info : AppDialogTone.success,
      // Sent: the report flies up and away.
      glyph: delivery.queued ? null : AppGlyphs.upload,
      title: delivery.queued ? l10n.inspQueuedTitle : l10n.inspSubmittedTitle,
      message: delivery.queued
          ? l10n.inspQueuedMessage
          : delivery.message.isEmpty
          ? l10n.inspSubmittedMessage
          : delivery.message,
      primaryLabel: l10n.actionOk,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  /// Back to the form, at the answer [row] of [section], or of the facts.
  void _edit(ReportSection? section, String? row) {
    Navigator.of(context).pop(InspectionEdit(section: section, row: row));
  }

  Future<void> _savePdf() async {
    final pdf = _pdf;
    if (pdf == null) return;
    final l10n = context.l10n;
    final day = DateFormat('yyyy-MM-dd').format(_report.date);
    final name =
        '${_report.title}${_report.subtitle == null ? '' : ' ${_report.subtitle}'} $day'
            .replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '')
            .trim();
    try {
      final file = await AppDownloads.save(
        pdf,
        name: '$name.pdf',
        mime: 'application/pdf',
      );
      if (!mounted) return;
      final opened = await AppDownloads.open(file);
      if (!opened && mounted) {
        await showAppMessage(
          context,
          l10n.inspPdfSaved,
          tone: AppDialogTone.success,
        );
      }
    } catch (_) {
      if (mounted) {
        await showAppMessage(
          context,
          l10n.inspPdfSaveFailed,
          tone: AppDialogTone.error,
        );
      }
    }
  }

  void _openPage(int index) {
    final pages = _pages;
    if (pages == null) return;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: context.colors.scrim,
        pageBuilder: (context, _, _) => _PageViewer(image: pages[index]),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final pages = _pages;
    final rows = [for (final section in _report.sections) ...section.rows];
    final findings = rows.where((row) => row.tone == ReportTone.bad).length;
    final blank = rows.where((row) => !row.answered).length;
    final Widget pdf;
    if (_noPreview) {
      pdf = AppEmptyState(
        key: const ValueKey('no-pdf'),
        glyph: AppGlyphs.layers,
        title: l10n.inspReviewNoPreview,
      );
    } else if (pages == null) {
      pdf = Padding(
        key: const ValueKey('loading'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
        child: AppLoader(label: l10n.inspReviewPreparing),
      );
    } else {
      pdf = Column(
        key: ValueKey(pages),
        children: [
          for (final (i, page) in pages.indexed) ...[
            if (i > 0) AppSpacing.gapLg,
            _PagePreview(
              image: page,
              caption: l10n.inspReviewPage(i + 1, pages.length),
              onTap: () => _openPage(i),
            ),
          ],
        ],
      );
    }
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.inspReviewTitle,
            subtitle: [
              _report.title,
              if (_report.subtitle case final s? when s.isNotEmpty) s,
            ].join(' · '),
            onBack: () => Navigator.of(context).maybePop(),
            actions: [
              AppTileButton(
                icon: const AppGlyphIcon(AppGlyphs.download),
                tooltip: l10n.inspSavePdf,
                onPressed: _pdf == null ? null : _savePdf,
              ),
            ],
          ),
          AppSpacing.gapLg,
          Text(
            widget.editable ? l10n.inspReviewLeadEdit : l10n.inspReviewLead,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          AppSpacing.gapLg,
          AppSegmentedTabs(
            controller: _tabs,
            segments: [
              AppSegment(
                label: l10n.inspReviewAnswers,
                glyph: AppGlyphs.clipboardList,
              ),
              AppSegment(label: l10n.inspReviewPdf, glyph: AppGlyphs.layers),
            ],
          ),
          AppSpacing.gapLg,
          AnimatedSwitcher(
            duration: AppMotion.short,
            child: _tabs.index == 0
                ? KeyedSubtree(
                    key: const ValueKey('answers'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppFilterChips<_Showing>(
                          options: [
                            AppFilterOption(
                              value: _Showing.all,
                              label: l10n.inspReviewAll,
                              count: rows.length,
                              urgent: false,
                            ),
                            AppFilterOption(
                              value: _Showing.findings,
                              label: l10n.inspReviewFindings,
                              count: findings,
                              mark: findings > 0 ? colors.danger : null,
                            ),
                            AppFilterOption(
                              value: _Showing.blank,
                              label: l10n.inspReviewBlank,
                              count: blank,
                              urgent: false,
                            ),
                          ],
                          selected: _showing,
                          onSelected: (showing) =>
                              setState(() => _showing = showing),
                        ),
                        AppSpacing.gapLg,
                        _Answers(
                          report: _report,
                          showing: _showing,
                          onEdit: widget.editable ? _edit : null,
                        ),
                      ],
                    ),
                  )
                : KeyedSubtree(key: const ValueKey('pdf'), child: pdf),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        step: _step,
        ready: true,
        verifying: _verifying,
        submitting: _submitting,
        verifiedAt: _report.signatures.submit?.verifiedAt,
        onConfirm: () => setState(() => _confirmed = true),
        onEdit: () => Navigator.of(context).maybePop(),
        onVerify: _verify,
        onSubmit: _submit,
      ),
    );
  }
}

/// The step under way and its one action, kept in reach at the foot of
/// the screen.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.step,
    required this.ready,
    required this.verifying,
    required this.submitting,
    required this.verifiedAt,
    required this.onConfirm,
    required this.onEdit,
    required this.onVerify,
    required this.onSubmit,
  });

  final _Step step;

  /// The report is ready to be confirmed.
  final bool ready;
  final bool verifying;
  final bool submitting;
  final DateTime? verifiedAt;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onVerify;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final verifiedAt = this.verifiedAt;
    Widget done(String label) => Row(
      children: [
        AppGlyphIcon(
          AppGlyphs.check,
          size: AppSizes.iconSm,
          color: colors.success,
        ),
        AppSpacing.gapXs,
        Expanded(
          child: Text(
            label,
            style: text.labelMedium?.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
    final actions = switch (step) {
      _Step.review => Column(
        key: const ValueKey(_Step.review),
        children: [
          AppButton(
            label: l10n.inspReviewConfirm,
            leadingGlyph: AppGlyphs.check,
            onPressed: ready ? onConfirm : null,
          ),
          AppSpacing.gapSm,
          AppButton(
            label: l10n.inspReviewEdit,
            variant: AppButtonVariant.secondary,
            onPressed: onEdit,
          ),
        ],
      ),
      _Step.verify => Column(
        key: const ValueKey(_Step.verify),
        children: [
          done(l10n.inspReviewConfirmed),
          AppSpacing.gapSm,
          AppButton(
            label: l10n.inspReviewVerify,
            leadingGlyph: AppGlyphs.scanFace,
            isLoading: verifying,
            onPressed: onVerify,
          ),
        ],
      ),
      _Step.submit => Column(
        key: const ValueKey(_Step.submit),
        children: [
          if (verifiedAt != null)
            done(
              l10n.inspReviewVerified(DateFormat.jm(locale).format(verifiedAt)),
            ),
          AppSpacing.gapSm,
          AppButton(
            label: l10n.inspSubmit,
            leadingGlyph: AppGlyphs.arrowUpRight,
            isLoading: submitting,
            loadingLabel: l10n.inspSubmitting,
            onPressed: onSubmit,
          ),
        ],
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderSheetTop,
        boxShadow: context.elevations.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppProgressSteps(
                steps: [
                  l10n.inspStepReview,
                  l10n.inspStepVerify,
                  l10n.inspStepSubmit,
                ],
                current: step.index,
              ),
              AppSpacing.gapMd,
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.enter,
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page of the report, as printed, on a card.
class _PagePreview extends StatelessWidget {
  const _PagePreview({
    required this.image,
    required this.caption,
    required this.onTap,
  });

  final ui.Image image;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: appCardDecoration(context),
            child: ClipRRect(
              borderRadius: AppRadius.borderXl,
              child: AspectRatio(
                aspectRatio: image.width / image.height,
                child: RawImage(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
        AppSpacing.gapXs,
        Text(
          caption,
          style: context.textTheme.labelSmall?.copyWith(
            color: colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// A page full screen, to be zoomed and read closely.
class _PageViewer extends StatelessWidget {
  const _PageViewer({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(context).pop(),
    child: SafeArea(
      child: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: RawImage(image: image, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}

/// The report's answers, section by section, each in the tone it reads
/// in; with [onEdit], each opens its question on the form to change.
class _Answers extends StatelessWidget {
  const _Answers({
    required this.report,
    required this.showing,
    required this.onEdit,
  });

  final InspectionReport report;
  final _Showing showing;
  final void Function(ReportSection? section, String? row)? onEdit;

  /// The longest an answer is to sit beside its question, as a pill.
  static const int _short = 22;

  bool _shows(ReportRow row) => switch (showing) {
    _Showing.all => true,
    _Showing.findings => row.tone == ReportTone.bad,
    _Showing.blank => !row.answered,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final onEdit = this.onEdit;
    AppTone toneOf(ReportTone tone) => switch (tone) {
      ReportTone.good => AppTone.brand,
      ReportTone.bad => AppTone.danger,
      ReportTone.missing => AppTone.neutral,
      ReportTone.plain => AppTone.neutral,
    };
    Widget answer(ReportSection? section, ReportRow row) {
      final value = row.answered ? row.value : l10n.inspPdfUnanswered;
      final long = value.length > _short;
      return AppListRow(
        title: row.label,
        subtitle: long ? value : null,
        trailing: long
            ? null
            : AppPill(
                value,
                tone: toneOf(row.tone),
                dot: row.tone == ReportTone.bad ? colors.danger : null,
              ),
        showChevron: onEdit != null,
        onTap: onEdit == null ? null : () => onEdit(section, row.label),
      );
    }

    final facts = [
      for (final fact in report.facts)
        if (fact.answered) fact,
    ];
    final parts = <Widget>[
      if (showing == _Showing.all && facts.isNotEmpty)
        AppListGroup(children: [for (final fact in facts) answer(null, fact)]),
      for (final section in report.sections)
        if (section.rows.where(_shows).toList() case final rows
            when rows.isNotEmpty ||
                (showing == _Showing.all && !section.isEmpty)) ...[
          AppSectionTitle(
            section.title,
            trailing: onEdit == null
                ? null
                : AppButton(
                    label: l10n.inspReviewChange,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.small,
                    leadingGlyph: AppGlyphs.fileEdit,
                    expand: false,
                    onPressed: () => onEdit(section, null),
                  ),
          ),
          AppSpacing.gapSm,
          AppListGroup(
            children: [
              for (final row in rows) answer(section, row),
              if (showing == _Showing.all)
                if (section.note case final note? when note.trim().isNotEmpty)
                  AppListRow(
                    title: note.trim(),
                    leading: AppGlyphIcon(
                      AppGlyphs.fileEdit,
                      color: colors.iconAccent,
                    ),
                  ),
            ],
          ),
        ],
    ];
    if (parts.isEmpty) {
      return AppEmptyState(
        glyph: showing == _Showing.findings
            ? AppGlyphs.badgeCheck
            : AppGlyphs.check,
        title: showing == _Showing.findings
            ? l10n.inspReviewNoFindings
            : l10n.inspReviewNoBlank,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0 && part is AppSectionTitle) AppSpacing.gapLg,
          part,
        ],
      ],
    );
  }
}
