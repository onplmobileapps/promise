import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/constants/app_assets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/module_notifications.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_state.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/extensions/accident_display_extension.dart';
import 'package:railway_hrms/modules/prams/screens/accident_report_details_screen.dart';
import 'package:railway_hrms/modules/prams/screens/report_accident_screen.dart';

/// How bad an accident is, as the server words its class.
enum AccidentSeverity {
  critical,
  moderate,
  minor;

  static AccidentSeverity of(String? severity) =>
      switch ((severity ?? '').toLowerCase()) {
        'critical' || 'major' || 'high' => critical,
        'medium' || 'moderate' => moderate,
        _ => minor,
      };
}

/// Where a case stands on its way from report to clear.
enum AccidentStage {
  reported,
  acknowledged,
  relief,
  cleared;

  static AccidentStage of(String? status) =>
      switch ((status ?? '').toLowerCase().replaceAll('_', ' ').trim()) {
        'resolved' || 'closed' || 'cleared' => cleared,
        'under investigation' ||
        'in progress' ||
        'relief' ||
        'investigating' => relief,
        'approved' || 'acknowledged' || 'accepted' => acknowledged,
        _ => reported,
      };
}

/// PRAMS: a way to report an accident at the top, this month's cases, and
/// the cases themselves to search and filter by how bad they are.
class PramsDashboardScreen extends StatefulWidget {
  const PramsDashboardScreen({super.key, this.cubit, this.now});

  /// The cases' source; one of its own by default.
  final AccidentCubit? cubit;

  /// The clock; the device's by default.
  final DateTime Function()? now;

  @override
  State<PramsDashboardScreen> createState() => _PramsDashboardScreenState();
}

class _PramsDashboardScreenState extends State<PramsDashboardScreen> {
  // A cubit for the list alone, so a case's details never replace it.
  late final AccidentCubit _cubit =
      widget.cubit ??
      (AccidentCubit(repository: sl<AccidentRepository>())..loadAccidentList());

  /// The severity shown; every one when null.
  AccidentSeverity? _severity;
  String _query = '';

  @override
  void dispose() {
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  void _leave() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ModuleBackNotification().dispatch(context);
    }
  }

  Future<void> _report() async {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: (_) => AccidentReportingScreen()));
    if (mounted) await _cubit.loadAccidentList();
  }

  void _open(Accidents accident) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => AccidentReportDetailsScreen(accident: accident),
      ),
    );
  }

  bool _matches(Accidents accident) {
    final query = _query.trim().toLowerCase();
    return (_severity == null ||
            AccidentSeverity.of(accident.severity) == _severity) &&
        (query.isEmpty || accident.searchBlob.contains(query));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (widget.now ?? DateTime.now)();
    // A page of its own now, so back and the iOS swipe close it as any.
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: BlocBuilder<AccidentCubit, AccidentState>(
          bloc: _cubit,
          buildWhen: (a, b) => a.status != b.status || a.accident != b.accident,
          builder: (context, state) {
            final accidents = state.accident ?? const <Accidents>[];
            final loading =
                state.status == AccidentStatus.loadingList && accidents.isEmpty;
            final failed =
                state.status == AccidentStatus.listError && accidents.isEmpty;
            final found = accidents.where(_matches).toList();
            return AppScrollPage(
              onRefresh: _cubit.loadAccidentList,
              children: [
                AppHeaderBar(
                  title: l10n.modulePramsTitle,
                  subtitle: l10n.pramsSubtitle,
                  onBack: _leave,
                ),
                AppSpacing.gapLg,
                _ReportCard(onReport: _report),
                AppSpacing.gapMd,
                _MonthCard(accidents: accidents, now: now, loading: loading),
                AppSpacing.gapLg,
                AppSearchField(
                  hint: l10n.pramsSearch,
                  onChanged: (query) => setState(() => _query = query),
                ),
                AppSpacing.gapSm,
                AppFilterChips<AccidentSeverity?>(
                  selected: _severity,
                  onSelected: (severity) =>
                      setState(() => _severity = severity),
                  options: [
                    AppFilterOption(
                      value: null,
                      label: l10n.pramsAll,
                      urgent: false,
                    ),
                    for (final severity in AccidentSeverity.values)
                      AppFilterOption(
                        value: severity,
                        label: _severityLabel(l10n, severity),
                        mark: _severityColor(context.colors, severity),
                        urgent: false,
                      ),
                  ],
                ),
                AppSpacing.gapMd,
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: AppLoader()),
                  )
                else if (failed) ...[
                  AppEmptyState(
                    glyph: AppGlyphs.wifiOff,
                    title: l10n.pramsLoadFailed,
                    message: state.errorMessage,
                  ),
                  AppButton(
                    label: l10n.actionRetry,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: _cubit.loadAccidentList,
                  ),
                ] else if (found.isEmpty)
                  AppEmptyState(
                    glyph: AppGlyphs.shieldCheck,
                    title: accidents.isEmpty
                        ? l10n.pramsNoCases
                        : l10n.pramsNoMatch,
                    message: accidents.isEmpty
                        ? l10n.pramsNoCasesMessage
                        : l10n.pramsNoMatchMessage,
                  )
                else
                  for (final (i, accident) in found.indexed) ...[
                    if (i > 0) AppSpacing.gapMd,
                    _CaseCard(
                      accident: accident,
                      now: now,
                      onTap: accident.id == null ? null : () => _open(accident),
                    ),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _severityLabel(AppLocalizations l10n, AccidentSeverity severity) =>
    switch (severity) {
      AccidentSeverity.critical => l10n.pramsCritical,
      AccidentSeverity.moderate => l10n.pramsModerate,
      AccidentSeverity.minor => l10n.pramsMinor,
    };

Color _severityColor(AppColors colors, AccidentSeverity severity) =>
    switch (severity) {
      AccidentSeverity.critical => colors.danger,
      AccidentSeverity.moderate => colors.gold,
      AccidentSeverity.minor => colors.infoMark,
    };

/// A train as the design names it: "1UP Khyber Mail".
String _trainLabel(Accidents accident) {
  final label = [
    '${accident.trainNumber ?? ''}${accident.trainDirection ?? ''}',
    accident.trainName ?? '',
  ].where((part) => part.isNotEmpty).join(' ');
  return label.isEmpty ? accident.trainRoute : label;
}

AppTone _severityTone(AccidentSeverity severity) => switch (severity) {
  AccidentSeverity.critical => AppTone.danger,
  AccidentSeverity.moderate => AppTone.warning,
  AccidentSeverity.minor => AppTone.info,
};

/// The way to report an accident: a coral card with its 3D picture and the
/// key that opens the form.
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderHeroCard,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.dangerContainer, colors.surface],
          stops: const [0, 0.7],
        ),
        border: Border.all(color: colors.dangerRing),
        boxShadow: context.elevations.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIconTile(
                  size: AppSizes.reportTile,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Image.asset(AppAssets.modulePrams),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.pramsReportTitle, style: text.titleLarge),
                      AppSpacing.gapXxs,
                      Text(
                        l10n.pramsReportSubtitle,
                        style: text.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            _Halo(
              child: AppButton(
                label: l10n.pramsReportAction,
                leadingGlyph: AppGlyphs.plus,
                variant: AppButtonVariant.danger,
                onPressed: onReport,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// This month's cases: open, being looked into and closed, beside a bar a
/// week, the latest week standing out.
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.accidents,
    required this.now,
    required this.loading,
  });

  final List<Accidents> accidents;
  final DateTime now;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final month = [
      for (final accident in accidents)
        if (DateTime.tryParse(accident.accidentDateTime ?? '') case final at?
            when at.year == now.year && at.month == now.month)
          (accident, at),
    ];
    var open = 0;
    var investigating = 0;
    var closed = 0;
    // Four weeks; the month's last days count in the fourth.
    final weeks = List.filled(4, 0);
    for (final (accident, at) in month) {
      switch (AccidentStage.of(accident.status)) {
        case AccidentStage.cleared:
          closed++;
        case AccidentStage.relief:
          investigating++;
        case AccidentStage.reported || AccidentStage.acknowledged:
          open++;
      }
      weeks[math.min(weeks.length - 1, (at.day - 1) ~/ 7)]++;
    }
    final current = math.min(weeks.length - 1, (now.day - 1) ~/ 7);
    return DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pramsThisMonth.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final (value, label) in [
                        (open, l10n.pramsOpen),
                        (investigating, l10n.pramsInvestigating),
                        (closed, l10n.pramsClosed),
                      ])
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loading ? '–' : '$value',
                              style: text.headlineSmall?.copyWith(
                                fontFeatures: AppFonts.tabularFigures,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              label,
                              style: text.labelMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.gapMd,
            _WeekBars(weeks: weeks, current: current),
          ],
        ),
      ),
    );
  }
}

/// A 3D bar a week, as tall as its count; the [current] week in coral.
class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.weeks, required this.current});

  final List<int> weeks;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final most = weeks.fold(1, math.max);
    return Semantics(
      label: context.l10n.pramsWeeks(weeks.join(', ')),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.medium * 2,
          curve: AppMotion.enter,
          builder: (context, grown, _) => CustomPaint(
            size: const Size(AppSizes.weekBarsWidth, AppSizes.weekBars),
            painter: _BarsPainter(
              shares: [for (final count in weeks) 0.18 + 0.82 * count / most],
              grown: grown,
              current: current,
              faces: (
                colors.outline,
                colors.surfaceSunken,
                colors.outlineStrong,
              ),
              hot: (
                colors.dangerShade,
                colors.dangerHighlight,
                colors.dangerEdge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bars drawn as blocks: a front, a top leaning back and a side.
class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.shares,
    required this.grown,
    required this.current,
    required this.faces,
    required this.hot,
  });

  final List<double> shares;
  final double grown;
  final int current;

  /// Front, top and side.
  final (Color, Color, Color) faces;
  final (Color, Color, Color) hot;

  @override
  void paint(Canvas canvas, Size size) {
    final depth = size.width * 0.05;
    final gap = size.width * 0.11;
    final width =
        (size.width - depth - gap * (shares.length - 1)) / shares.length;
    final floor = size.height;
    for (final (i, share) in shares.indexed) {
      final (front, top, side) = i == current ? hot : faces;
      final left = i * (width + gap);
      final right = left + width;
      final roof = floor - (size.height - depth) * share * grown;
      canvas
        ..drawRect(
          Rect.fromLTRB(left, roof, right, floor),
          Paint()..color = front,
        )
        ..drawPath(
          Path()
            ..moveTo(left, roof)
            ..lineTo(right, roof)
            ..lineTo(right + depth, roof - depth * 0.8)
            ..lineTo(left + depth, roof - depth * 0.8)
            ..close(),
          Paint()..color = top,
        )
        ..drawPath(
          Path()
            ..moveTo(right, floor)
            ..lineTo(right + depth, floor - depth * 0.8)
            ..lineTo(right + depth, roof - depth * 0.8)
            ..lineTo(right, roof)
            ..close(),
          Paint()..color = side,
        );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.grown != grown ||
      old.current != current ||
      old.faces != faces ||
      old.hot != hot ||
      !listEquals(old.shares, shares);
}

/// A ring that keeps spreading from [child]'s edge and fading, calling the
/// eye to it.
class _Halo extends StatefulWidget {
  const _Halo({required this.child});

  final Widget child;

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo> with AppLoopsMixin {
  late final AppLoop _pulse = loop(AppMotion.halo);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Still for those who ask for less motion.
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else {
      _pulse.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _HaloPainter(
        progress: _pulse,
        color: context.colors.danger,
      ),
      child: widget.child,
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.progress, required this.color})
    : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(AppRadius.buttonLarge),
      ).inflate(AppSpacing.sm * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.5 * (1 - t)),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.color != color;
}

/// A case: how bad it is and when it was last updated, the train and what
/// happened, where, and how far it has come from report to clear.
class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.accident, required this.now, this.onTap});

  final Accidents accident;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final severity = AccidentSeverity.of(accident.severity);
    final stage = AccidentStage.of(accident.status);
    final steps = [
      l10n.pramsStageReported,
      l10n.pramsStageAcknowledged,
      l10n.pramsStageRelief,
      l10n.pramsStageCleared,
    ];
    return AppInkSurface(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppPill(
                  _severityLabel(l10n, severity),
                  tone: _severityTone(severity),
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    l10n.pramsUpdated(accident.updatedLabel),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Text(
              '${_trainLabel(accident)} · ${accident.displayTitle}',
              style: text.titleSmall,
            ),
            Text(
              [
                if ((accident.kilometerNumber ?? '').isNotEmpty)
                  l10n.pramsKm(accident.kilometerNumber!),
                accident.incidentLocation,
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            AppSpacing.gapMd,
            AppProgressSteps(
              steps: steps,
              current: stage.index,
              semanticLabel: l10n.pramsStageOf(
                stage.index + 1,
                steps.length,
                steps[stage.index],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
