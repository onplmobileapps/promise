import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/station_asset_model.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_station_input.dart';

/// A kind of asset's 3D mark.
AppGlyph footplateAssetGlyph(String type) => switch (type) {
  'Signal' => AppGlyphs.signal,
  'Track' => AppGlyphs.route,
  'Level Crossing' ||
  'Level Crossing - Manned' ||
  'Level Crossing - Unmanned' => AppGlyphs.triangleAlert,
  'Tunnel' => AppGlyphs.locate,
  'Bridge' => AppGlyphs.map,
  'Curve' => AppGlyphs.gauge,
  'Station' => AppGlyphs.station,
  'Platform' => AppGlyphs.building,
  _ => AppGlyphs.clipboardList,
};

/// The assets of each station on the run: the stations added on the way,
/// picked from chips, each station's assets to search, and a sheet that
/// checks each one.
class StationAssetInspectionStep extends StatefulWidget {
  const StationAssetInspectionStep({
    super.key,
    required this.stationAssets,
    required this.onChanged,
  });

  final List<StationAsset> stationAssets;
  final VoidCallback onChanged;

  @override
  State<StationAssetInspectionStep> createState() =>
      _StationAssetInspectionStepState();
}

class _StationAssetInspectionStepState
    extends State<StationAssetInspectionStep> {
  late String _station = widget.stationAssets.firstOrNull?.id ?? '';
  String _query = '';

  Future<void> _check(StationAsset station, StationAssetItem asset) async {
    final checked = await showAppSheet<StationAssetItem>(
      context: context,
      title: asset.assetName,
      subtitle: [?asset.category, ?asset.location].join(' · '),
      closeLabel: context.l10n.actionClose,
      builder: (_) => _AssetCheck(asset: asset),
    );
    if (checked == null) return;
    final i = station.assets.indexOf(asset);
    if (i < 0) return;
    setState(() => station.assets[i] = checked);
    widget.onChanged();
  }

  /// Adds a station on the run, with the assets every station has.
  Future<void> _addStation() async {
    final l10n = context.l10n;
    final station = await showAppSheet<String>(
      context: context,
      title: l10n.inspFootplateAddStation,
      closeLabel: l10n.actionClose,
      builder: (_) => const _AddStation(),
    );
    if (station == null || station.trim().isEmpty) return;
    final added = StationAssetData.forStation(station.trim());
    final stations = widget.stationAssets;
    if (!stations.any((s) => s.id == added.id)) stations.add(added);
    setState(() => _station = added.id);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final stations = widget.stationAssets;
    final add = AppButton(
      label: l10n.inspFootplateAddStation,
      variant: AppButtonVariant.secondary,
      leadingGlyph: AppGlyphs.plus,
      onPressed: _addStation,
    );
    if (stations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppEmptyState(
            glyph: AppGlyphs.station,
            title: l10n.inspFootplateNoStations,
            message: l10n.inspFootplateNoStationsAbout,
          ),
          AppSpacing.gapMd,
          add,
        ],
      );
    }
    final station = stations.firstWhere(
      (s) => s.id == _station,
      orElse: () => stations.first,
    );
    final query = _query.trim().toLowerCase();
    final assets = [
      for (final asset in station.assets)
        if (query.isEmpty ||
            asset.assetName.toLowerCase().contains(query) ||
            asset.assetType.toLowerCase().contains(query))
          asset,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFilterChips<String>(
          options: [
            for (final s in stations)
              AppFilterOption(
                value: s.id,
                label: s.stationName,
                count: s.totalAssets - s.completedAssets,
                urgent: false,
                mark: s.completedAssets == s.totalAssets
                    ? colors.success
                    : s.issueCount > 0
                    ? colors.danger
                    : null,
              ),
          ],
          selected: station.id,
          onSelected: (id) => setState(() => _station = id),
        ),
        AppSpacing.gapMd,
        AppSearchField(
          hint: 'Search assets',
          onChanged: (typed) => setState(() => _query = typed),
        ),
        AppSpacing.gapMd,
        if (assets.isEmpty)
          const AppEmptyState(glyph: AppGlyphs.search, title: 'No assets match')
        else
          AppListGroup(
            children: [
              for (final asset in assets)
                AppListRow(
                  leading: AppIconTile(
                    size: AppSizes.rowTile,
                    child: AppGlyphIcon(
                      footplateAssetGlyph(asset.category ?? asset.assetType),
                      size: AppSizes.iconMd,
                      color: colors.iconAccent,
                      depth: true,
                    ),
                  ),
                  title: asset.assetName,
                  subtitle: [asset.assetType, ?asset.location].join(' · '),
                  trailing: asset.isChecked
                      ? AppPill(
                          asset.status ?? 'Checked',
                          tone: asset.hasIssue ? AppTone.danger : AppTone.brand,
                        )
                      : null,
                  showChevron: !asset.isChecked,
                  onTap: () => _check(station, asset),
                ),
            ],
          ),
        AppSpacing.gapMd,
        add,
        AppSpacing.gapMd,
        InspectionTextInput(
          label: 'Station remarks',
          kind: InspectionTextKind.multiline,
          value: station.overallRemarks,
          onChanged: (typed) {
            station.overallRemarks = typed;
            widget.onChanged();
          },
        ),
      ],
    );
  }
}

/// Asks which station to add: picked from the employee's, or typed.
class _AddStation extends StatefulWidget {
  const _AddStation();

  @override
  State<_AddStation> createState() => _AddStationState();
}

class _AddStationState extends State<_AddStation> {
  String _station = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Scrolls, and rises over the keyboard, as a sheet's body must.
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectionStationInput(
            label: l10n.inspFormStation,
            value: _station,
            onChanged: (picked) => setState(() => _station = picked),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: l10n.inspFootplateAddStation,
            leadingGlyph: AppGlyphs.plus,
            onPressed: _station.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_station.trim()),
          ),
        ],
      ),
    );
  }
}

/// Checks one asset: how it was found, a note, and photos.
class _AssetCheck extends StatefulWidget {
  const _AssetCheck({required this.asset});

  final StationAssetItem asset;

  @override
  State<_AssetCheck> createState() => _AssetCheckState();
}

class _AssetCheckState extends State<_AssetCheck> {
  late String? _status = widget.asset.status;
  late String _remarks = widget.asset.remarks ?? '';
  late List<String> _photos = [...widget.asset.photos];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = StationAssetData.getStatusOptions(widget.asset.assetType);
    // Scrolls, and rises over the keyboard, as a sheet's body must.
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectionChoiceInput(
            label: 'Found',
            options: options,
            value: _status,
            toneOf: (option) =>
                option == options.first ||
                    option == 'Satisfactory' ||
                    option == 'Good Condition'
                ? AppTone.brand
                : AppTone.danger,
            onChanged: (picked) => setState(() => _status = picked),
          ),
          AppSpacing.gapLg,
          InspectionTextInput(
            label: l10n.inspFormRemarkLabel,
            kind: InspectionTextKind.multiline,
            value: _remarks,
            onChanged: (typed) => _remarks = typed,
          ),
          AppSpacing.gapLg,
          InspectionPhotosInput(
            photos: _photos,
            onChanged: (photos) => setState(() => _photos = photos),
          ),
          AppSpacing.gapLg,
          AppButton(
            label: l10n.inspFormDone,
            leadingGlyph: AppGlyphs.check,
            onPressed: _status == null
                ? null
                : () => Navigator.of(context).pop(
                    widget.asset.copyWith(
                      isChecked: true,
                      status: _status,
                      remarks: _remarks.trim(),
                      photos: _photos,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
