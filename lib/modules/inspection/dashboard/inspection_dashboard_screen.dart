import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/module_notifications.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/dashboard/inspection_plan.dart';
import 'package:railway_hrms/modules/inspection/electrical/electrical_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/inspection_approval_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_screen.dart';
import 'package:railway_hrms/modules/inspection/proformas.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/station/station_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_inspection_home.dart';

extension on InspectionKind {
  String title(AppLocalizations l10n) => switch (this) {
    InspectionKind.footplate => l10n.inspFootplate,
    InspectionKind.station => l10n.inspStation,
    InspectionKind.motorTrolley => l10n.inspMotorTrolley,
    InspectionKind.locomotive => l10n.inspLocomotive,
    InspectionKind.electrical => l10n.inspElectrical,
  };

  String about(AppLocalizations l10n) => switch (this) {
    InspectionKind.footplate => l10n.inspFootplateAbout,
    InspectionKind.station => l10n.inspStationAbout,
    InspectionKind.motorTrolley => l10n.inspMotorTrolleyAbout,
    InspectionKind.locomotive => l10n.inspLocomotiveAbout,
    InspectionKind.electrical => l10n.inspElectricalAbout,
  };

  AppGlyph get glyph => switch (this) {
    InspectionKind.footplate => AppGlyphs.train,
    InspectionKind.station => AppGlyphs.station,
    InspectionKind.motorTrolley => AppGlyphs.truck,
    InspectionKind.locomotive => AppGlyphs.wrench,
    InspectionKind.electrical => AppGlyphs.zap,
  };

  Widget screen() => switch (this) {
    InspectionKind.footplate => const InspectionApprovalScreen(),
    InspectionKind.station => const StationInspectionScreen(),
    InspectionKind.motorTrolley => const MotorTrolleyInspectionScreen(),
    InspectionKind.locomotive => const LocomotiveInspectionScreen(),
    InspectionKind.electrical => const ElectricalInspectionScreen(),
  };
}

/// e Inspection: this month's plan, the inspections waiting to be sent,
/// the drafts to finish, and every kind of inspection to start.
class InspectionDashboardScreen extends StatefulWidget {
  const InspectionDashboardScreen({super.key, this.now, this.outbox});

  /// The clock; the device's by default.
  final DateTime Function()? now;

  /// What waits to be sent; the app's own unless a test stands in.
  final InspectionOutbox? outbox;

  @override
  State<InspectionDashboardScreen> createState() =>
      _InspectionDashboardScreenState();
}

class _InspectionDashboardScreenState extends State<InspectionDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _records =
      StorageService.getInspectionRecords();
  User? _user;
  final _draftsKey = GlobalKey();

  InspectionOutbox? get _outbox =>
      widget.outbox ??
      (sl.isRegistered<InspectionOutbox>() ? sl<InspectionOutbox>() : null);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// Sends what waits, and says how it went.
  Future<void> _sendWaiting(
    InspectionOutbox outbox, {
    bool retry = false,
  }) async {
    final l10n = context.l10n;
    final round = await outbox.send(retry: retry);
    if (!mounted) return;
    await showAppMessage(
      context,
      [
        l10n.inspOutboxSent(round.sent),
        if (round.waiting > 0) l10n.inspOutboxStill(round.waiting),
      ].join(' '),
      tone: round.sent > 0 ? AppDialogTone.success : AppDialogTone.info,
    );
  }

  /// What can be done with one inspection waiting: send it again, or take
  /// it off the phone.
  Future<void> _openWaiting(InspectionOutbox outbox, OutboxItem item) async {
    final l10n = context.l10n;
    final again = await showAppDialog(
      context: context,
      tone: item.refused ? AppDialogTone.warning : AppDialogTone.info,
      title: [item.title, ?item.subtitle].join(' · '),
      message: item.refused
          ? l10n.inspOutboxRefused(item.error ?? '')
          : l10n.inspOutboxWaiting,
      primaryLabel: item.refused
          ? l10n.inspOutboxTryAgain
          : l10n.inspOutboxSendNow,
      secondaryLabel: l10n.inspOutboxRemove,
    );
    if (!mounted || again == null) return;
    if (again) {
      await _sendWaiting(outbox, retry: true);
      return;
    }
    final sure = await showAppDialog(
      context: context,
      tone: AppDialogTone.warning,
      title: l10n.inspOutboxRemoveTitle,
      message: l10n.inspOutboxRemoveMessage,
      primaryLabel: l10n.inspOutboxRemove,
      secondaryLabel: l10n.actionCancel,
    );
    if (sure == true) await outbox.remove(item.id);
  }

  Future<void> _loadUser() async {
    final login = await StorageService.getUser();
    if (mounted) setState(() => _user = login?.user);
  }

  Future<void> _refresh() async {
    final records = StorageService.getInspectionRecords();
    setState(() => _records = records);
    await records;
  }

  void _leave() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      ModuleBackNotification().dispatch(context);
    }
  }

  Future<void> _start(InspectionKind kind) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => kind.screen()));
    if (mounted) await _refresh();
  }

  Future<void> _delete(Map<String, dynamic> draft) async {
    final l10n = context.l10n;
    final sure = await showAppDialog(
      context: context,
      tone: AppDialogTone.warning,
      title: l10n.inspDeleteDraftTitle,
      message: l10n.inspDeleteDraftMessage,
      primaryLabel: l10n.inspDeleteDraft,
      secondaryLabel: l10n.actionCancel,
    );
    if (sure != true) return;
    await StorageService.deleteInspectionRecord(draft['id']?.toString() ?? '');
    if (mounted) await _refresh();
  }

  /// Opens a saved inspection where it was left.
  Future<void> _resume(Map<String, dynamic> record) async {
    final navigator = Navigator.of(context);
    final id = record['id']?.toString();
    final payload = record['payload'] as Map<String, dynamic>? ?? const {};
    final type = payload['type']?.toString();
    final department = payload['department']?.toString();
    final subDepartment = payload['subDepartment']?.toString();
    final asset = payload['asset']?.toString();
    final formId = payload['formId']?.toString();
    Widget? screen;
    if (type == 'traffic') {
      screen = TrafficInspectionHome(
        stationName: payload['stationName']?.toString() ?? '',
        resumeId: id,
      );
    } else if (type == 'civil') {
      if (formId == 'civil_track_sleepers_rails_private_sidings') {
        await navigator.pushNamed(AppRoutes.civilInspectionSleepersRails);
        if (mounted) await _refresh();
        return;
      }
      final fields =
          department == null || subDepartment == null || asset == null
          ? null
          : CivilDeptAssetMap.resolveFields(department, subDepartment, asset);
      if (fields != null && formId != null) {
        screen = CivilAssetFormScreen(
          department: department!,
          subDepartment: subDepartment!,
          asset: asset!,
          fields: fields,
          formId: formId,
        );
      }
    } else if (type == 'proforma') {
      final definition = proformaNamed(
        context.l10n,
        payload['proforma']?.toString(),
      );
      if (definition != null) {
        screen = ProformaInspectionScreen(definition: definition);
      }
    } else if (type == 'electrical') {
      screen = const ElectricalInspectionScreen();
    } else if (type == 'station' || type == 'signal') {
      screen = const StationInspectionScreen();
    } else if (type == 'motor_trolley') {
      screen = const MotorTrolleyInspectionScreen();
    } else if (type == 'locomotive') {
      screen = const LocomotiveInspectionScreen();
    } else {
      screen = FootplateWizardScreen(resumeId: id);
    }
    if (screen == null) return;
    final opened = screen;
    await navigator.push(MaterialPageRoute<void>(builder: (_) => opened));
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = (widget.now ?? DateTime.now)();
    // A page of its own now, so back and the iOS swipe close it as any.
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _records,
          builder: (context, snapshot) {
            final records = snapshot.data ?? const <Map<String, dynamic>>[];
            final drafts = <Map<String, dynamic>>[
              for (final record in records)
                if (record['status'] == 'in_progress') record,
            ];
            final quota = monthlyPlan(
              _user,
              records,
              now,
              kindOf: InspectionKindDrafts.ofDraft,
            );
            return AppScrollPage(
              onRefresh: _refresh,
              children: [
                AppHeaderBar(
                  title: l10n.moduleInspectionTitle,
                  subtitle: l10n.inspSubtitle,
                  onBack: _leave,
                  actions: [
                    AppTileButton(
                      icon: const AppGlyphIcon(AppGlyphs.fileEdit),
                      tooltip: l10n.inspDrafts,
                      count: drafts.length,
                      onPressed: () {
                        final target = _draftsKey.currentContext;
                        if (target != null) {
                          Scrollable.ensureVisible(
                            target,
                            duration: AppMotion.medium,
                            curve: AppMotion.enter,
                          );
                        }
                      },
                    ),
                  ],
                ),
                AppSpacing.gapLg,
                _PlanCard(quota: quota, now: now),
                AppSpacing.gapMd,
                _Counts(quota: quota, now: now),
                if (_outbox case final outbox?)
                  ListenableBuilder(
                    listenable: outbox,
                    builder: (context, _) => outbox.items.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xl),
                            child: _Waiting(
                              outbox: outbox,
                              onSend: () => _sendWaiting(outbox),
                              onOpen: (item) => _openWaiting(outbox, item),
                            ),
                          ),
                  ),
                if (drafts.isNotEmpty) ...[
                  AppSpacing.gapXl,
                  AppSectionTitle(key: _draftsKey, l10n.inspContinue),
                  AppSpacing.gapSm,
                  _Drafts(drafts: drafts, onResume: _resume, onDelete: _delete),
                ],
                AppSpacing.gapXl,
                AppSectionTitle(l10n.inspStart),
                AppSpacing.gapSm,
                AppListGroup(
                  children: [
                    for (final kind in InspectionKind.values)
                      AppListRow(
                        leading: AppIconTile(
                          size: AppSizes.rowTile,
                          child: AppGlyphIcon(
                            kind.glyph,
                            size: AppSizes.iconMd,
                            color: context.colors.iconAccent,
                          ),
                        ),
                        title: kind.title(l10n),
                        subtitle: kind.about(l10n),
                        showChevron: true,
                        onTap: () => _start(kind),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The month's plan: how many of the inspections are done, on a ring, and
/// each kind's share under it. With no plan for the designation, what was
/// done this month.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.quota, required this.now});

  final List<InspectionQuota> quota;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final done = quota.fold(
      0,
      (sum, item) => sum + math.min(item.done, item.total),
    );
    final total = quota.fold(0, (sum, item) => sum + item.total);
    final made = quota.fold(0, (sum, item) => sum + item.done);
    final planned = total > 0;
    final due = DateTime(now.year, now.month + 1, 0);
    return DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    l10n.inspPlan(DateFormat.MMMM(locale).format(now)),
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  l10n.inspDue(DateFormat('d MMM', locale).format(due)),
                  style: text.labelMedium?.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
            AppSpacing.gapMd,
            Row(
              children: [
                AppRingGauge(
                  fraction: planned ? done / total : (made > 0 ? 1 : 0),
                  color: colors.primaryShade,
                  size: AppSizes.planRing,
                  stroke: AppSizes.planRingStroke,
                  semanticLabel: planned
                      ? l10n.inspDoneOf(done, total)
                      : '$made ${l10n.inspDone}',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: planned ? '$done' : '$made'),
                            if (planned)
                              TextSpan(
                                text: '/$total',
                                style: text.titleSmall?.copyWith(
                                  color: colors.textTertiary,
                                ),
                              ),
                          ],
                        ),
                        style: text.headlineSmall?.copyWith(
                          fontFeatures: AppFonts.tabularFigures,
                          height: 1,
                        ),
                      ),
                      Text(
                        l10n.inspDone,
                        style: text.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: quota.isEmpty
                      ? Text(
                          l10n.inspPlanNone,
                          style: text.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (final (i, item) in quota.indexed) ...[
                              if (i > 0) AppSpacing.gapSm,
                              _KindProgress(item: item),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One kind's name, how many are done of its share, and a bar of it: gold
/// while half or less is done.
class _KindProgress extends StatelessWidget {
  const _KindProgress({required this.item});

  final InspectionQuota item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final share = item.total == 0 ? 0.0 : item.done / item.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.kind.title(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: AppFonts.semiBold,
                ),
              ),
            ),
            Text(
              item.total == 0 ? '${item.done}' : '${item.done}/${item.total}',
              style: text.labelMedium?.copyWith(
                color: colors.textTertiary,
                fontFeatures: AppFonts.tabularFigures,
              ),
            ),
          ],
        ),
        if (item.total > 0) ...[
          AppSpacing.gapXxs,
          AppProgressTrack(
            to: share,
            height: AppSizes.progressThin,
            fill: share > 0.5
                ? null
                : LinearGradient(colors: [colors.goldContainer, colors.gold]),
            semanticLabel: l10n.inspDoneOf(item.done, item.total),
          ),
        ],
      ],
    );
  }
}

/// Completed, pending, overdue and extra inspections, side by side.
class _Counts extends StatelessWidget {
  const _Counts({required this.quota, required this.now});

  final List<InspectionQuota> quota;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    var completed = 0;
    var pending = 0;
    var extra = 0;
    for (final item in quota) {
      completed += item.done;
      pending += math.max(0, item.total - item.done);
      // Beyond a plan; with none, nothing is extra.
      if (item.total > 0) extra += math.max(0, item.done - item.total);
    }
    // The plan is monthly; what is left of an earlier month is overdue.
    final overdue = quota.fold(0, (sum, item) => sum + item.overdue);
    final counts = [
      (completed, l10n.inspCompleted, colors.success),
      (pending, l10n.inspPending, colors.warningMark),
      (overdue, l10n.inspOverdue, colors.danger),
      (extra, l10n.inspExtra, colors.infoMark),
    ];
    return Row(
      children: [
        for (final (i, (value, label, mark)) in counts.indexed) ...[
          if (i > 0) AppSpacing.gapSm,
          Expanded(
            child: AppStatTile(
              value: '$value',
              label: label,
              mark: mark,
              style: AppStatTileStyle.raised,
            ),
          ),
        ],
      ],
    );
  }
}

/// The inspections submitted with no connection, each saying whether it
/// waits for one or was turned down, and a way to send them now.
class _Waiting extends StatelessWidget {
  const _Waiting({
    required this.outbox,
    required this.onSend,
    required this.onOpen,
  });

  final InspectionOutbox outbox;
  final VoidCallback onSend;
  final ValueChanged<OutboxItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionTitle(
          l10n.inspOutboxTitle,
          badge: AppPill('${outbox.items.length}', tone: AppTone.warning),
          trailing: AppButton(
            label: l10n.inspOutboxSendNow,
            variant: AppButtonVariant.tonal,
            size: AppButtonSize.small,
            leadingGlyph: AppGlyphs.refresh,
            expand: false,
            isLoading: outbox.sending,
            loadingLabel: l10n.inspOutboxSending,
            onPressed: outbox.sending ? null : onSend,
          ),
        ),
        AppSpacing.gapSm,
        AppListGroup(
          children: [
            for (final item in outbox.items)
              AppListRow(
                leading: AppToneIcon(
                  glyph: item.refused
                      ? AppGlyphs.triangleAlert
                      : AppGlyphs.hourglass,
                  tone: item.refused ? AppTone.danger : AppTone.warning,
                ),
                title: [item.title, ?item.subtitle].join(' · '),
                subtitle: item.refused
                    ? l10n.inspOutboxRefused(item.error ?? '')
                    : '${l10n.inspOutboxWaiting} · ${l10n.inspOutboxQueuedAt(DateFormat('d MMM, HH:mm', locale).format(item.queuedAt))}',
                showChevron: true,
                onTap: () => onOpen(item),
              ),
          ],
        ),
      ],
    );
  }
}

/// The inspections left part-way, two to a row, each with a way back in.
class _Drafts extends StatelessWidget {
  const _Drafts({
    required this.drafts,
    required this.onResume,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> drafts;
  final ValueChanged<Map<String, dynamic>> onResume;
  final ValueChanged<Map<String, dynamic>> onDelete;

  @override
  Widget build(BuildContext context) {
    return AppGrid(
      columns: 2,
      children: [
        for (final (i, draft) in drafts.indexed)
          _DraftCard(
            draft: draft,
            latest: i == 0,
            onResume: () => onResume(draft),
            onDelete: () => onDelete(draft),
          ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.latest,
    required this.onResume,
    required this.onDelete,
  });

  final Map<String, dynamic> draft;

  /// The one saved last, whose key stands out.
  final bool latest;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final kind = InspectionKindDrafts.ofDraft(draft);
    final saved = DateTime.tryParse(draft['date']?.toString() ?? '');
    final progress = switch (draft['progress']) {
      final num value => (value > 1 ? value / 100 : value).toDouble(),
      _ => null,
    };
    return GestureDetector(
      // Held down, a draft offers to go.
      onLongPress: onDelete,
      child: DecoratedBox(
        decoration: appCardDecoration(
          context,
          radius: AppRadius.borderHeroCard,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md - AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      (kind?.title(l10n) ?? l10n.inspDraft).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  if (progress != null)
                    Text(
                      '${(progress * 100).round()}%',
                      style: text.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                ],
              ),
              AppSpacing.gapXxs,
              Text(
                draft['train']?.toString() ?? l10n.inspDraft,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall,
              ),
              if (saved != null)
                Text(
                  l10n.inspSaved(
                    DateFormat('d MMM, HH:mm', locale).format(saved),
                  ),
                  style: text.bodySmall,
                ),
              if (progress != null) ...[
                AppSpacing.gapSm,
                AppProgressTrack(to: progress, height: AppSizes.progressThin),
              ],
              AppSpacing.gapMd,
              AppButton(
                label: l10n.inspResume,
                size: AppButtonSize.small,
                variant: latest
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: onResume,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reads which kind a saved draft is.
extension InspectionKindDrafts on InspectionKind {
  static InspectionKind? ofDraft(Map<String, dynamic> record) {
    final payload = record['payload'];
    final type = payload is Map ? payload['type']?.toString() : null;
    return switch (type) {
      'station' || 'signal' || 'traffic' => InspectionKind.station,
      'electrical' => InspectionKind.electrical,
      'locomotive' => InspectionKind.locomotive,
      'civil' || 'motor_trolley' => InspectionKind.motorTrolley,
      'proforma' => switch ('${payload['proforma']}') {
        final id when id.startsWith('power_') || id.startsWith('rtl_') =>
          InspectionKind.electrical,
        _ => InspectionKind.locomotive,
      },
      null || '' || 'footplate' => InspectionKind.footplate,
      _ => null,
    };
  }
}
