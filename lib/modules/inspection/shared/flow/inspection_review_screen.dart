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
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report_pdf.dart';

/// Sends a finished inspection, signed with [signatures]: what the server
/// said, or why it couldn't.
typedef InspectionSubmitter =
    Future<Either<AppException, String>> Function(
      InspectionSignatures signatures,
    );

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

/// Shows [report] as the PDF it will go out as, and lets it be submitted
/// only once the inspector has read and confirmed it and verified their
/// face again; [submit] then sends it. True once it was submitted.
///
/// The report is signed with the face check the inspection was started
/// with (its [InspectionSession]) and the one made here.
Future<bool> reviewAndSubmit(
  BuildContext context, {
  required InspectionReport report,
  required InspectionSubmitter submit,
  InspectionFaceVerifier? verifier,
  ReportRenderer? render,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final start = InspectionSession.maybeOf(context)?.start;
  final submitted = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => InspectionReviewScreen(
        report: report.copyWith(
          signatures: report.signatures.copyWith(start: start),
        ),
        submit: submit,
        verifier: verifier,
        render: render,
      ),
    ),
  );
  return submitted == true;
}

/// The last steps of an inspection: read the report, confirm it, verify
/// the face, submit. Each opens only once the one before is done.
class InspectionReviewScreen extends StatefulWidget {
  const InspectionReviewScreen({
    super.key,
    required this.report,
    required this.submit,
    this.verifier,
    this.render,
  });

  final InspectionReport report;
  final InspectionSubmitter submit;
  final InspectionFaceVerifier? verifier;

  /// Draws the PDF; [InspectionReportPdf] unless a test stands in.
  final ReportRenderer? render;

  @override
  State<InspectionReviewScreen> createState() => _InspectionReviewScreenState();
}

enum _Step { review, verify, submit }

class _InspectionReviewScreenState extends State<InspectionReviewScreen> {
  late InspectionReport _report = widget.report;
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
    _disposePages(_pages);
    super.dispose();
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
    final result = await widget.submit(_report.signatures);
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
    final message = result.fold((_) => '', (said) => said);
    await showAppDialog(
      context: context,
      tone: AppDialogTone.success,
      title: l10n.inspSubmittedTitle,
      message: message.isEmpty ? l10n.inspSubmittedMessage : message,
      primaryLabel: l10n.actionOk,
    );
    if (mounted) Navigator.of(context).pop(true);
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
            l10n.inspReviewLead,
            style: text.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          AppSpacing.gapLg,
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: _noPreview
                ? _ReportList(key: const ValueKey('list'), report: _report)
                : pages == null
                ? Padding(
                    key: const ValueKey('loading'),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxxl,
                    ),
                    child: AppLoader(label: l10n.inspReviewPreparing),
                  )
                : Column(
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
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        step: _step,
        ready: _pdf != null || _noPreview,
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

/// The report as a list, where its pages can't be drawn.
class _ReportList extends StatelessWidget {
  const _ReportList({super.key, required this.report});

  final InspectionReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    AppTone toneOf(ReportTone tone) => switch (tone) {
      ReportTone.good => AppTone.brand,
      ReportTone.bad => AppTone.danger,
      ReportTone.missing => AppTone.neutral,
      ReportTone.plain => AppTone.neutral,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.facts.isNotEmpty)
          AppListGroup(
            children: [
              for (final fact in report.facts.where((f) => f.answered))
                AppListRow(title: fact.label, meta: fact.value),
            ],
          ),
        for (final section in report.sections)
          if (!section.isEmpty) ...[
            AppSpacing.gapLg,
            AppSectionTitle(section.title),
            AppSpacing.gapSm,
            AppListGroup(
              children: [
                for (final row in section.rows)
                  AppListRow(
                    title: row.label,
                    trailing: AppPill(
                      row.answered ? row.value : l10n.inspPdfUnanswered,
                      tone: toneOf(row.tone),
                    ),
                  ),
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
      ],
    );
  }
}
