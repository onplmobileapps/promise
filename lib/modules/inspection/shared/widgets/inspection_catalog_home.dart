import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// Where a department's inspections start: its sub-departments and their
/// assets to pick from, and the inspections already finished on this
/// phone.
class InspectionCatalogHome extends StatefulWidget {
  const InspectionCatalogHome({
    super.key,
    required this.title,
    required this.subtitle,
    required this.glyph,
    required this.table,
    required this.onOpen,
    required this.history,
  });

  final String title;
  final String subtitle;
  final AppGlyph glyph;

  /// Assets by department and sub-department.
  final Map<String, Map<String, List<String>>> table;

  /// Opens an asset's inspection.
  final Future<void> Function(
    BuildContext context,
    String department,
    String subDepartment,
    String asset,
  )
  onOpen;

  /// The inspections finished on this phone, newest last.
  final Future<List<Map<String, dynamic>>> Function() history;

  @override
  State<InspectionCatalogHome> createState() => _InspectionCatalogHomeState();
}

class _InspectionCatalogHomeState extends State<InspectionCatalogHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    animationDuration: Duration.zero,
  )..addListener(_tabChanged);
  late String _department = widget.table.keys.first;
  late String _subDepartment = widget.table[_department]!.keys.first;
  late Future<List<Map<String, dynamic>>> _done = widget.history();

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    super.dispose();
  }

  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {
      if (_tabs.index == 1) _done = widget.history();
    });
  }

  Future<void> _open(String asset) async {
    await widget.onOpen(context, _department, _subDepartment, asset);
    if (mounted) setState(() => _done = widget.history());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: widget.title,
            subtitle: widget.subtitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          AppSegmentedTabs(
            controller: _tabs,
            segments: [
              AppSegment(label: l10n.inspCatalogNew, glyph: AppGlyphs.plus),
              AppSegment(
                label: l10n.inspCatalogDone,
                glyph: AppGlyphs.calendarCheck,
              ),
            ],
          ),
          AppSpacing.gapLg,
          AnimatedSwitcher(
            duration: AppMotion.short,
            child: _tabs.index == 0
                ? KeyedSubtree(key: const ValueKey('new'), child: _picker())
                : KeyedSubtree(key: const ValueKey('done'), child: _history()),
          ),
        ],
      ),
    );
  }

  Widget _picker() {
    final l10n = context.l10n;
    final colors = context.colors;
    final subDepartments = widget.table[_department]!;
    final assets = subDepartments[_subDepartment] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: appCardDecoration(
            context,
            radius: AppRadius.borderHeroCard,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionLabel(l10n.inspCatalogDepartment),
                AppSpacing.gapSm,
                AppChoiceChips<String>(
                  choices: [
                    for (final department in widget.table.keys)
                      AppChoice(department, department),
                  ],
                  selected: _department,
                  onSelected: (department) => setState(() {
                    _department = department;
                    _subDepartment = widget.table[department]!.keys.first;
                  }),
                ),
                AppSpacing.gapLg,
                AppSectionLabel(l10n.inspCatalogSubDepartment),
                AppSpacing.gapSm,
                AppChoiceChips<String>(
                  choices: [
                    for (final sub in subDepartments.keys) AppChoice(sub, sub),
                  ],
                  selected: _subDepartment,
                  onSelected: (sub) => setState(() => _subDepartment = sub),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.gapXl,
        AppSectionLabel(l10n.inspCatalogAssets),
        AppSpacing.gapSm,
        AppListGroup(
          children: [
            for (final asset in assets)
              AppListRow(
                leading: AppIconTile(
                  size: AppSizes.rowTile,
                  child: AppGlyphIcon(
                    widget.glyph,
                    size: AppSizes.iconMd,
                    color: colors.iconAccent,
                    depth: true,
                  ),
                ),
                title: asset,
                showChevron: true,
                onTap: () => _open(asset),
              ),
          ],
        ),
      ],
    );
  }

  Widget _history() {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _done,
      builder: (context, snapshot) {
        final records = snapshot.data;
        if (records == null) return const Center(child: AppLoader());
        if (records.isEmpty) {
          return AppEmptyState(
            glyph: AppGlyphs.clipboardList,
            title: l10n.inspCatalogEmpty,
            message: l10n.inspCatalogEmptyMessage,
          );
        }
        return AppListGroup(
          children: [
            for (final record in records.reversed)
              AppListRow(
                leading: const AppToneIcon(
                  glyph: AppGlyphs.check,
                  tone: AppTone.brand,
                ),
                title: '${record['asset'] ?? record['formId']}',
                subtitle: [
                  if (DateTime.tryParse('${record['finishedAt']}')
                      case final at?)
                    DateFormat('d MMM yyyy, HH:mm', locale).format(at),
                  if (record['timeSpentSeconds'] case final num seconds)
                    l10n.inspCatalogTook((seconds / 60).toStringAsFixed(1)),
                ].join(' · '),
              ),
          ],
        );
      },
    );
  }
}
