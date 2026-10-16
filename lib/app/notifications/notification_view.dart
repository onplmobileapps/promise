import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/app/notifications/app_alert.dart';
import 'package:railway_hrms/app/notifications/demo_alerts.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/prams/screens/accident_approval_screen.dart';

/// Which alerts the list shows.
enum AlertFilter {
  all,
  accidents,
  leave,
  attendance;

  bool admits(AppAlert alert) => switch (this) {
    all => true,
    accidents => alert.kind == AlertKind.accident,
    leave => alert.kind == AlertKind.leave,
    attendance => alert.kind == AlertKind.attendance,
  };
}

/// The alerts: grouped by day, newest first, filterable by what they are
/// about. An accident that opens a case shows how far the case has got.
class NotificationView extends StatefulWidget {
  const NotificationView({super.key, this.alerts, this.now});

  /// What to list; the sample alerts by default.
  final List<AppAlert>? alerts;

  /// The time the list is read at; the clock's by default.
  final DateTime Function()? now;

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  late List<AppAlert> _alerts = widget.alerts ?? demoAlerts(_now());
  AlertFilter _filter = AlertFilter.all;

  void _markAllRead() =>
      setState(() => _alerts = [for (final alert in _alerts) alert.read()]);

  void _markRead(AppAlert alert) {
    if (!alert.unread) return;
    setState(() {
      _alerts = [
        for (final each in _alerts) each.id == alert.id ? each.read() : each,
      ];
    });
  }

  void _openCase(AppAlert alert) {
    _markRead(alert);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccidentApprovalScreen()),
    );
  }

  int _unread(AlertFilter filter) =>
      _alerts.where((alert) => alert.unread && filter.admits(alert)).length;

  /// "Today", "Yesterday", or the day's date.
  String _dayLabel(DateTime day, DateTime today, String locale) {
    final l10n = context.l10n;
    final date = DateUtils.dateOnly(day);
    final difference = DateUtils.dateOnly(today).difference(date).inDays;
    return switch (difference) {
      0 => l10n.alertsToday,
      1 => l10n.alertsYesterday,
      _ => DateFormat.MMMMEEEEd(locale).format(date),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = _now();
    final unread = _unread(AlertFilter.all);
    final date = DateFormat('EEE dd MMM', locale).format(now);
    final shown = [
      for (final alert in _alerts)
        if (_filter.admits(alert)) alert,
    ]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    // Grouped by day, in order.
    final days = <DateTime, List<AppAlert>>{};
    for (final alert in shown) {
      days
          .putIfAbsent(DateUtils.dateOnly(alert.receivedAt), () => [])
          .add(alert);
    }
    final canGoBack = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      body: AppBackdrop.blobs(
        blobIntensity: AppSizes.blobIntensityStrong,
        child: SafeArea(
          bottom: false,
          child: ResponsiveBuilder(
            builder: (context, layout) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                layout.gutter,
                AppSpacing.md,
                layout.gutter,
                AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canGoBack) ...[
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppTileButton(
                            icon: const AppGlyphIcon(AppGlyphs.chevronLeft),
                            tooltip: l10n.actionBack,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        AppSpacing.gapSm,
                      ],
                      AppPageHeader(
                        overline: unread > 0
                            ? l10n.alertsOverline(unread, date)
                            : date,
                        title: l10n.alertsTitle,
                        action: unread > 0
                            ? AppButton(
                                label: l10n.alertsMarkAllRead,
                                variant: AppButtonVariant.text,
                                size: AppButtonSize.small,
                                underlined: false,
                                expand: false,
                                onPressed: _markAllRead,
                              )
                            : null,
                      ),
                      AppSpacing.gapSm,
                      AppFilterChips<AlertFilter>(
                        selected: _filter,
                        onSelected: (filter) =>
                            setState(() => _filter = filter),
                        options: [
                          AppFilterOption(
                            value: AlertFilter.all,
                            label: l10n.alertsFilterAll,
                          ),
                          AppFilterOption(
                            value: AlertFilter.accidents,
                            label: l10n.alertsFilterAccidents,
                            count: _unread(AlertFilter.accidents),
                          ),
                          AppFilterOption(
                            value: AlertFilter.leave,
                            label: l10n.alertsFilterLeave,
                            count: _unread(AlertFilter.leave),
                          ),
                          AppFilterOption(
                            value: AlertFilter.attendance,
                            label: l10n.alertsFilterAttendance,
                            count: _unread(AlertFilter.attendance),
                          ),
                        ],
                      ),
                      if (days.isEmpty)
                        AppEmptyState(
                          glyph: AppGlyphs.bell,
                          title: l10n.alertsEmptyTitle,
                          message: l10n.alertsEmptyMessage,
                        ),
                      for (final MapEntry(key: day, value: alerts)
                          in days.entries) ...[
                        AppSpacing.gapXl,
                        AppSectionLabel(_dayLabel(day, now, locale)),
                        AppSpacing.gapSm,
                        for (final alert in alerts.where((a) => a.opensCase))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.smd,
                            ),
                            child: _CaseCard(
                              alert: alert,
                              time: DateFormat.Hm(
                                locale,
                              ).format(alert.receivedAt),
                              onOpen: () => _openCase(alert),
                            ),
                          ),
                        if (alerts.any((a) => !a.opensCase))
                          AppListGroup(
                            children: [
                              for (final alert in alerts.where(
                                (a) => !a.opensCase,
                              ))
                                _AlertRow(
                                  alert: alert,
                                  time: DateFormat.Hm(
                                    locale,
                                  ).format(alert.receivedAt),
                                  onTap: () => _markRead(alert),
                                ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark and tint for what an alert signals.
(AppGlyph, AppTone) _markOf(AlertSignal signal) => switch (signal) {
  AlertSignal.alarm => (AppGlyphs.siren, AppTone.danger),
  AlertSignal.progress => (AppGlyphs.gauge, AppTone.warning),
  AlertSignal.done => (AppGlyphs.check, AppTone.brand),
};

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.alert,
    required this.time,
    required this.onTap,
  });

  final AppAlert alert;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (glyph, tone) = _markOf(alert.signal);
    return AppListRow(
      leading: AppToneIcon(glyph: glyph, tone: tone),
      title: alert.title,
      meta: time,
      subtitle: alert.body,
      onTap: onTap,
      trailing: alert.unread ? const _UnreadDot() : null,
    );
  }
}

/// An accident that opens a case: the alert, the case's progress, and the
/// way into it.
class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.alert,
    required this.time,
    required this.onOpen,
  });

  final AppAlert alert;
  final String time;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final (glyph, tone) = _markOf(alert.signal);
    final steps = [
      l10n.caseReported,
      l10n.caseAcknowledged,
      l10n.caseRelief,
      l10n.caseCleared,
    ];
    final stage = alert.caseStage!.clamp(0, steps.length - 1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.outline),
        boxShadow: context.elevations.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppToneIcon(glyph: glyph, tone: tone),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: text.labelLarge?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          AppSpacing.gapSm,
                          Text(
                            time,
                            style: text.bodySmall?.copyWith(
                              fontFeatures: AppFonts.tabularFigures,
                            ),
                          ),
                          if (alert.unread) ...[
                            AppSpacing.gapSm,
                            const _UnreadDot(),
                          ],
                        ],
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        alert.body,
                        style: text.labelMedium?.copyWith(
                          fontWeight: AppFonts.regular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapMd,
            AppProgressSteps(
              steps: steps,
              current: stage,
              semanticLabel: l10n.caseStepOf(
                stage + 1,
                steps.length,
                steps[stage],
              ),
            ),
            AppSpacing.gapMd,
            AppButton(
              label: l10n.alertsOpenCase,
              size: AppButtonSize.medium,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.alertUnread,
    child: Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs + AppSpacing.xxs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.primaryShade,
        ),
        child: const SizedBox.square(dimension: AppSizes.unreadDot),
      ),
    ),
  );
}
