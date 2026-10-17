import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';

/// A step of an inspection form: its [title], what it asks, and how much
/// of it is answered.
@immutable
class InspectionStep {
  const InspectionStep({
    required this.title,
    required this.builder,
    this.total = 0,
    this.answered = 0,
  });

  final String title;

  /// Builds the step's fields when it is open.
  final WidgetBuilder builder;

  /// Questions it asks, and how many have answers; none counted if zero.
  final int total;
  final int answered;

  int get left => (total - answered).clamp(0, total);
  bool get complete => total > 0 && left == 0;
}

/// An answer the inspector tapped on the report to change: a [row] of one
/// of its sections, or of its facts when [section] is null.
@immutable
class InspectionEdit {
  const InspectionEdit({this.section, this.row});

  final ReportSection? section;

  /// The row's label, as the report reads it.
  final String? row;
}

/// Takes a review's edit back to the form it was opened from.
///
/// A form's review is pushed as a page of its own, away from the form, by
/// code the form calls; the form runs that call in [run], and the review
/// finds where to send an edit with [current], as long as it was opened
/// from within the call.
abstract final class InspectionEditing {
  static final Object _key = Object();

  /// Runs [review], sending an edit asked of it to [open].
  static Future<T> run<T>(
    ValueChanged<InspectionEdit> open,
    Future<T> Function() review,
  ) => runZoned(review, zoneValues: {_key: open});

  /// Where an edit asked now goes, if a form is waiting for one.
  static ValueChanged<InspectionEdit>? get current =>
      Zone.current[_key] as ValueChanged<InspectionEdit>?;
}

/// The page every inspection form is: a header, the steps as chips that
/// show what each still needs, the open step's fields, and a bar at the
/// foot that moves step to step and, on the last, to the report.
///
/// Leaving with answers given asks first, saying whether they are kept as
/// a draft ([onLeave] keeps them) or lost. An answer tapped on the report
/// opens its step again, scrolled to the question.
class InspectionFormScaffold extends StatefulWidget {
  const InspectionFormScaffold({
    super.key,
    required this.title,
    required this.steps,
    required this.onReview,
    this.subtitle,
    this.header,
    this.actions = const [],
    this.dirty = false,
    this.onLeave,
    this.missing,
    this.initialStep = 0,
    this.onStepChanged,
  });

  final String title;
  final String? subtitle;
  final List<InspectionStep> steps;

  /// Opens the report, once every step has been through.
  final Future<void> Function() onReview;

  /// Shown over the steps, as what is being inspected.
  final Widget? header;
  final List<Widget> actions;

  /// Something has been filled in.
  final bool dirty;

  /// Keeps the answers as a draft when the form is left part-way.
  final Future<void> Function()? onLeave;

  /// What must be filled in before the report can be read, as the station;
  /// nothing by default.
  final List<String> Function()? missing;
  final int initialStep;

  /// Told the step moved to, as a draft keeps where it was left.
  final ValueChanged<int>? onStepChanged;

  @override
  State<InspectionFormScaffold> createState() => _InspectionFormScaffoldState();
}

/// The open step's fields, told apart from any other key in the form.
class _StepKey extends ValueKey<int> {
  const _StepKey(super.value);
}

class _InspectionFormScaffoldState extends State<InspectionFormScaffold> {
  late int _step = widget.initialStep.clamp(0, widget.steps.length - 1);
  final ScrollController _scroll = ScrollController();
  bool _forward = true;
  bool _reviewing = false;
  bool _leaving = false;

  @override
  void didUpdateWidget(InspectionFormScaffold old) {
    super.didUpdateWidget(old);
    if (_step >= widget.steps.length) _step = widget.steps.length - 1;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _last => _step == widget.steps.length - 1;

  void _go(int to) {
    if (to == _step || to < 0 || to >= widget.steps.length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = to > _step;
      _step = to;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    widget.onStepChanged?.call(to);
  }

  Future<void> _review() async {
    if (_reviewing) return;
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final missing = widget.missing?.call() ?? const [];
    if (missing.isNotEmpty) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.inspFormRequiredTitle,
        message: missing.map((item) => '• $item').join('\n'),
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    final blank = widget.steps.fold(0, (sum, step) => sum + step.left);
    if (blank > 0) {
      final anyway = await showAppDialog(
        context: context,
        tone: AppDialogTone.confirm,
        title: l10n.inspFormBlankTitle,
        message: l10n.inspFormBlankMessage(blank),
        primaryLabel: l10n.inspFormReviewAnyway,
        secondaryLabel: l10n.inspFormShowBlank,
      );
      if (!mounted || anyway == null) return;
      if (!anyway) {
        _go(widget.steps.indexWhere((step) => step.left > 0));
        return;
      }
    }
    setState(() => _reviewing = true);
    try {
      await InspectionEditing.run(_edit, widget.onReview);
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  /// The step [edit] is answered on: the one its section names, or the
  /// first for the facts at the head of the report.
  int? _stepOf(InspectionEdit edit) {
    final section = edit.section;
    if (section == null) return 0;
    final steps = widget.steps;
    if (section.step case final step? when step >= 0 && step < steps.length) {
      return step;
    }
    final title = _plain(section.title);
    final same = steps.indexWhere((step) => _plain(step.title) == title);
    if (same >= 0) return same;
    final part = steps.indexWhere((step) {
      final name = _plain(step.title);
      return title.startsWith(name) || name.startsWith(title);
    });
    return part >= 0 ? part : null;
  }

  /// Opens the step [edit] is answered on and brings its question into
  /// view, marked for a moment.
  void _edit(InspectionEdit edit) {
    if (!mounted) return;
    final step = _stepOf(edit);
    if (step != null) _go(step);
    final row = edit.row;
    if (row == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final question = _questionFor(row);
      final shown = question?.findRenderObject();
      if (question == null || shown is! RenderBox) return;
      await Scrollable.ensureVisible(
        question,
        alignment: 0.25,
        duration: AppMotion.medium,
        curve: AppMotion.enter,
      );
      if (mounted && shown.attached) _mark(shown);
    });
  }

  /// The label of the open step's question [row] answers, as the report
  /// names it: the same words, or the last part of a name such as
  /// "Pump 1 · Discharge".
  Element? _questionFor(String row) {
    Element? stepFields;
    void findStep(Element element) {
      if (stepFields != null) return;
      if (element.widget.key == _StepKey(_step)) {
        stepFields = element;
        return;
      }
      element.visitChildElements(findStep);
    }

    (context as Element).visitChildElements(findStep);
    final fields = stepFields;
    if (fields == null) return null;
    final labels = <(String, Element)>[];
    void collect(Element element) {
      if (element.widget case Text(:final data, :final textSpan)) {
        final words = data ?? textSpan?.toPlainText();
        if (words != null && words.trim().isNotEmpty) {
          labels.add((_plain(words), element));
        }
      }
      element.visitChildElements(collect);
    }

    fields.visitChildElements(collect);
    // A numbered item, as "4. Fuel Oil Pressure", is labelled without it.
    final unnumbered = row.replaceFirst(RegExp(r'^[\d.]+\s+'), '');
    final names = {
      _plain(row),
      _plain(unnumbered),
      _plain(unnumbered.split(' · ').last),
      _plain(row.split(' — ').first),
    }..remove('');
    for (final name in names) {
      for (final (words, element) in labels) {
        if (words == name) return element;
      }
    }
    for (final name in names) {
      for (final (words, element) in labels) {
        if (words.startsWith(name) || name.startsWith(words)) return element;
      }
    }
    return null;
  }

  /// A ring around [label] that fades, so the eye finds it.
  void _mark(RenderBox label) {
    final overlay = Overlay.maybeOf(context);
    final ground = overlay?.context.findRenderObject();
    if (overlay == null || ground is! RenderBox) return;
    final at = label.localToGlobal(Offset.zero, ancestor: ground) & label.size;
    final colors = context.colors;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fromRect(
        rect: at.inflate(AppSpacing.sm),
        child: IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 1600),
            curve: Curves.easeInCubic,
            onEnd: entry.remove,
            builder: (_, fade, _) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderMd,
                color: colors.primaryContainer.withValues(alpha: 0.5 * fade),
                border: Border.all(
                  color: colors.primary.withValues(alpha: fade),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }

  /// [words] as compared: lower case, without a required mark or extra
  /// spaces.
  static String _plain(String words) => words
      .replaceAll('*', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toLowerCase();

  Future<void> _leave() async {
    if (_leaving) return;
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final onLeave = widget.onLeave;
    final sure = await showAppDialog(
      context: context,
      tone: AppDialogTone.warning,
      title: l10n.inspFormLeaveTitle,
      message: onLeave == null
          ? l10n.inspFormLeaveLost
          : l10n.inspFormLeaveDraft,
      primaryLabel: l10n.inspFormLeave,
      secondaryLabel: l10n.inspFormStay,
    );
    if (sure != true || !mounted) return;
    _leaving = true;
    await onLeave?.call();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final steps = widget.steps;
    final step = steps[_step];
    final total = steps.fold(0, (sum, s) => sum + s.total);
    final answered = steps.fold(
      0,
      (sum, s) => sum + s.answered.clamp(0, s.total),
    );
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final header = widget.header;
    return PopScope(
      canPop: !widget.dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: AppScrollPage(
          backdrop: AppPageBackdrop.blobs,
          controller: _scroll,
          children: [
            AppHeaderBar(
              title: widget.title,
              subtitle: widget.subtitle,
              onBack: () => Navigator.of(context).maybePop(),
              actions: widget.actions,
            ),
            if (header != null) ...[AppSpacing.gapLg, header],
            AppSpacing.gapLg,
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.inspFormStepOf(_step + 1, steps.length),
                    style: text.labelMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (total > 0)
                  Text(
                    l10n.inspFormProgress(answered, total),
                    style: text.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontFeatures: AppFonts.tabularFigures,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapXs,
            TweenAnimationBuilder<double>(
              tween: Tween(
                end: total > 0 ? answered / total : (_step + 1) / steps.length,
              ),
              duration: AppMotion.medium,
              curve: AppMotion.enter,
              builder: (context, at, _) => AppProgressTrack(
                to: at,
                semanticLabel: total > 0
                    ? l10n.inspFormProgress(answered, total)
                    : l10n.inspFormStepOf(_step + 1, steps.length),
              ),
            ),
            if (steps.length > 1) ...[
              AppSpacing.gapMd,
              AppFilterChips<int>(
                options: [
                  for (final (i, s) in steps.indexed)
                    AppFilterOption(
                      value: i,
                      label: s.title,
                      count: s.left,
                      urgent: false,
                      mark: s.complete
                          ? colors.success
                          : s.answered > 0
                          ? colors.gold
                          : null,
                    ),
                ],
                selected: _step,
                onSelected: _go,
              ),
            ],
            AppSpacing.gapLg,
            AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.enter,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                final entering = child.key == _StepKey(_step);
                final from = (entering == _forward ? 1 : -1) * 0.06;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(from, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: _StepKey(_step),
                child: Builder(builder: step.builder),
              ),
            ),
          ],
        ),
        bottomNavigationBar: AnimatedSwitcher(
          duration: AppMotion.short,
          child: typing
              ? const SizedBox.shrink()
              : _StepBar(
                  first: _step == 0,
                  last: _last,
                  reviewing: _reviewing,
                  onBack: () => _go(_step - 1),
                  onNext: _last ? _review : () => _go(_step + 1),
                ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({
    required this.first,
    required this.last,
    required this.reviewing,
    required this.onBack,
    required this.onNext,
  });

  final bool first;
  final bool last;
  final bool reviewing;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
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
          child: Row(
            children: [
              AnimatedSize(
                duration: AppMotion.short,
                curve: AppMotion.enter,
                child: first
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSpacing.sm,
                        ),
                        child: AppButton(
                          label: l10n.actionBack,
                          variant: AppButtonVariant.secondary,
                          leadingGlyph: AppGlyphs.arrowLeft,
                          expand: false,
                          onPressed: onBack,
                        ),
                      ),
              ),
              Expanded(
                child: AppButton(
                  label: last ? l10n.inspFormReview : l10n.inspFormNext,
                  leadingGlyph: last ? AppGlyphs.clipboardList : null,
                  trailingGlyph: last ? null : AppGlyphs.arrowRight,
                  isLoading: reviewing,
                  onPressed: onNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
