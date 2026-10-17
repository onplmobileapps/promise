import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/module_notifications.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_rtl_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/inspection_approval_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_screen.dart';
import 'package:railway_hrms/modules/inspection/station/station_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_inspection_home.dart';

/// The kinds of inspection, in the order they are offered.
enum InspectionKind { footplate, station, motorTrolley, locomotive, electrical }

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
    InspectionKind.electrical => const ElectricalRtlInspectionScreen(),
  };
}

/// e Inspection: this month's plan, the drafts to finish, and every kind
/// of inspection to start.
class InspectionDashboardScreen extends StatefulWidget {
  const InspectionDashboardScreen({super.key, this.now});

  /// The clock; the device's by default.
  final DateTime Function()? now;

  @override
  State<InspectionDashboardScreen> createState() =>
      _InspectionDashboardScreenState();
}

class _InspectionDashboardScreenState extends State<InspectionDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _records =
      StorageService.getInspectionRecords();
  User? _user;
  final _draftsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUser();
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

  /// The plan for the kinds the signed-in employee inspects.
  List<InspectionQuota> get _quota {
    final user = _user;
    if (user == null) return kInspectionQuota;
    final role = (user.roleData?.name ?? '').toLowerCase();
    final code = (user.roleData?.codeName ?? '').toLowerCase();
    final designation = (user.designation ?? '').toLowerCase();
    if (user.isSuperuser == true ||
        user.isHqUser == true ||
        designation.contains('officer') ||
        designation.contains('admin') ||
        designation.isEmpty ||
        designation == 'end user') {
      return kInspectionQuota;
    }
    final mine = [
      for (final item in kInspectionQuota)
        if (item.roles.any(
          (r) =>
              r == 'all' ||
              role.contains(r) ||
              code.contains(r) ||
              designation.contains(r),
        ))
          item,
    ];
    return mine.isEmpty ? kInspectionQuota : mine;
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
    } else if (type == 'electrical') {
      final assetData = payload['assetData'] as Map<String, dynamic>? ?? {};
      final fields =
          department == null || subDepartment == null || asset == null
          ? null
          : ElectricalInspectionCatalog.resolveFields(
              department,
              subDepartment,
              asset,
              assetData,
            );
      if (fields != null && formId != null) {
        screen = ElectricalAssetFormScreen(
          department: department!,
          subDepartment: subDepartment!,
          asset: asset!,
          fields: fields,
          formId: formId,
          assetData: assetData,
        );
      }
    } else if (type == 'station' || type == 'signal') {
      screen = const StationInspectionScreen();
    } else if (type == 'motor_trolley') {
      screen = const MotorTrolleyInspectionScreen();
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
    final quota = _quota;
    // A page of its own now, so back and the iOS swipe close it as any.
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _records,
          builder: (context, snapshot) {
            final drafts = <Map<String, dynamic>>[
              for (final record in snapshot.data ?? const [])
                if (record['status'] == 'in_progress') record,
            ];
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
                    for (final item in quota)
                      AppListRow(
                        leading: AppIconTile(
                          size: AppSizes.rowTile,
                          child: AppGlyphIcon(
                            item.kind.glyph,
                            size: AppSizes.iconMd,
                            color: context.colors.iconAccent,
                          ),
                        ),
                        title: item.kind.title(l10n),
                        subtitle: item.kind.about(l10n),
                        showChevron: true,
                        onTap: () => _start(item.kind),
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
/// each kind's share under it.
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
                  fraction: total == 0 ? 0 : done / total,
                  color: colors.primaryShade,
                  size: AppSizes.planRing,
                  stroke: AppSizes.planRingStroke,
                  semanticLabel: l10n.inspDoneOf(done, total),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$done'),
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
                  child: Column(
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
              '${item.done}/${item.total}',
              style: text.labelMedium?.copyWith(
                color: colors.textTertiary,
                fontFeatures: AppFonts.tabularFigures,
              ),
            ),
          ],
        ),
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
      extra += math.max(0, item.done - item.total);
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
  static InspectionKind? ofDraft(Map<String, dynamic> record) =>
      switch (record['payload']?['type']?.toString()) {
        'station' || 'signal' || 'traffic' => InspectionKind.station,
        'electrical' => InspectionKind.electrical,
        'civil' || 'motor_trolley' => InspectionKind.motorTrolley,
        null || '' || 'footplate' => InspectionKind.footplate,
        _ => null,
      };
}

// ─── Quota data ───────────────────────────────────────────────────────────

/// One kind of inspection's share of the month's plan, and who inspects it.
@immutable
class InspectionQuota {
  const InspectionQuota({
    required this.kind,
    required this.done,
    required this.total,
    required this.roles,
    this.overdue = 0,
  });

  final InspectionKind kind;
  final int done;
  final int total;

  /// Left over from earlier months.
  final int overdue;

  /// Words in a role or designation that inspect this kind.
  final List<String> roles;
}

/// This month's plan. The server doesn't send one yet, so this stands in.
const List<InspectionQuota> kInspectionQuota = [
  InspectionQuota(
    kind: InspectionKind.footplate,
    done: 2,
    total: 3,
    roles: ['loco', 'mechanical', 'driver', 'officer', 'all'],
  ),
  InspectionQuota(
    kind: InspectionKind.station,
    done: 2,
    total: 3,
    roles: ['station', 'traffic', 'officer', 'all'],
  ),
  InspectionQuota(
    kind: InspectionKind.motorTrolley,
    done: 1,
    total: 2,
    overdue: 1,
    roles: ['trolley', 'civil', 'mechanical', 'officer', 'all'],
  ),
  InspectionQuota(
    kind: InspectionKind.locomotive,
    done: 1,
    total: 2,
    roles: ['loco', 'mechanical', 'officer', 'all'],
  ),
  InspectionQuota(
    kind: InspectionKind.electrical,
    done: 2,
    total: 2,
    roles: ['electrical', 'officer', 'all'],
  ),
];
