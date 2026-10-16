import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/station_asset_model.dart';
import 'package:railway_hrms/modules/inspection/footplate/widgets/stored_image.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';

class StationAssetInspectionStep extends StatefulWidget {
  final List<StationAsset> stationAssets;
  final VoidCallback onChanged;

  const StationAssetInspectionStep({
    super.key,
    required this.stationAssets,
    required this.onChanged,
  });

  @override
  State<StationAssetInspectionStep> createState() =>
      _StationAssetInspectionStepState();
}

class _StationAssetInspectionStepState
    extends State<StationAssetInspectionStep> {
  String _selectedStationId = '';
  String _searchQuery = '';
  AssetCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.stationAssets.isNotEmpty) {
      _selectedStationId = widget.stationAssets.first.id;
    }
  }

  StationAsset? get _selectedStation =>
      widget.stationAssets.where((s) => s.id == _selectedStationId).firstOrNull;

  List<StationAssetItem> get _filteredAssets {
    final station = _selectedStation;
    if (station == null) return [];

    var assets = station.assets;

    if (_searchQuery.isNotEmpty) {
      assets = assets
          .where(
            (a) =>
                a.assetName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                a.assetType.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    if (_selectedCategory != null) {
      assets = assets
          .where((a) => a.category == _selectedCategory?.label)
          .toList();
    }

    return assets;
  }

  void _updateAsset(StationAssetItem updatedAsset) {
    setState(() {
      final station = _selectedStation;
      if (station != null) {
        final index = station.assets.indexWhere((a) => a.id == updatedAsset.id);
        if (index != -1) {
          station.assets[index] = updatedAsset;
          // Update station completion status
          station.isCompleted = station.completedAssets == station.totalAssets;
        }
      }
    });
    widget.onChanged();
  }

  void _openAssetDetail(StationAssetItem asset) async {
    final result = await showModalBottomSheet<StationAssetItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssetDetailSheet(
        asset: asset,
        stationName: _selectedStation?.stationName ?? '',
      ),
    );

    if (result != null) {
      _updateAsset(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Station selector
              SliverToBoxAdapter(child: _buildStationSelector(scheme)),

              // Search and filter
              SliverToBoxAdapter(child: _buildSearchAndFilter(scheme)),

              // Assets list
              if (_selectedStation == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                _buildSliverAssetsList(scheme),
            ],
          ),
        ),

        // Bottom summary
        _buildBottomSummary(scheme),
      ],
    );
  }

  Widget _buildStationSelector(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Station Inspection',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a station to inspect its assets',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.stationAssets.map((station) {
                final isSelected = station.id == _selectedStationId;
                final progress = station.totalAssets > 0
                    ? station.completedAssets / station.totalAssets
                    : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _StationChip(
                    station: station,
                    isSelected: isSelected,
                    progress: progress,
                    onTap: () =>
                        setState(() => _selectedStationId = station.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search assets...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AssetCategory>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
            onSelected: (category) =>
                setState(() => _selectedCategory = category),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Categories')),
              ...AssetCategory.values.map(
                (cat) => PopupMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: cat.color),
                      const SizedBox(width: 8),
                      Text(cat.label),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAssetsList(ColorScheme scheme) {
    final assets = _filteredAssets;

    if (assets.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildAssetsEmptyState(scheme),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final asset = assets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AssetCard(
              asset: asset,
              onTap: () => _openAssetDetail(asset),
            ),
          );
        }, childCount: assets.length),
      ),
    );
  }

  Widget _buildAssetsEmptyState(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No assets found',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.train, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No stations available',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(ColorScheme scheme) {
    final station = _selectedStation;
    if (station == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${station.completedAssets}/${station.totalAssets} assets checked',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (station.issueCount > 0)
                  Text(
                    '${station.issueCount} issue(s) found',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
              ],
            ),
          ),
          if (station.completedAssets == station.totalAssets)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Complete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StationChip extends StatelessWidget {
  final StationAsset station;
  final bool isSelected;
  final double progress;
  final VoidCallback onTap;

  const _StationChip({
    required this.station,
    required this.isSelected,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                station.stationCode,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                station.stationName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 60,
                height: 4,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isSelected
                      ? scheme.onPrimary.withValues(alpha: 0.3)
                      : scheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected ? scheme.onPrimary : scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final StationAssetItem asset;
  final VoidCallback onTap;

  const _AssetCard({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = AssetCategory.values.firstWhere(
      (cat) => cat.label == asset.category,
      orElse: () => AssetCategory.other,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: asset.isChecked
              ? (asset.hasIssue ? Colors.orange : Colors.green)
              : scheme.outlineVariant,
          width: asset.isChecked ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Asset icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: category.color, size: 24),
              ),
              const SizedBox(width: 12),
              // Asset details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.assetName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (asset.location != null) ...[
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            asset.location!,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (asset.status != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: asset.hasIssue
                                  ? Colors.orange.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              asset.status!,
                              style: TextStyle(
                                fontSize: 10,
                                color: asset.hasIssue
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Status indicator
              if (asset.isChecked)
                Icon(
                  asset.hasIssue ? Icons.warning : Icons.check_circle,
                  color: asset.hasIssue ? Colors.orange : Colors.green,
                )
              else
                const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetDetailSheet extends StatefulWidget {
  final StationAssetItem asset;
  final String stationName;

  const _AssetDetailSheet({required this.asset, required this.stationName});

  @override
  State<_AssetDetailSheet> createState() => _AssetDetailSheetState();
}

class _AssetDetailSheetState extends State<_AssetDetailSheet> {
  late bool _isChecked;
  late String? _status;
  late List<String> _photos;
  late final TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.asset.isChecked;
    _status = widget.asset.status;
    _remarksController = TextEditingController(
      text: widget.asset.remarks ?? '',
    );
    _photos = List.from(widget.asset.photos); // Create a mutable copy
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await PhotoPicker.pick(
      source: ImageSource.camera,
      context: context,
    );
    if (image != null && mounted) {
      final permanentPath = await FootplateFileUtils.saveImagePermanently(
        image.path,
      );
      setState(() {
        _photos.add(permanentPath);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusOptions = StationAssetData.getStatusOptions(
      widget.asset.assetType,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.asset.assetName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            widget.stationName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Check status
                    Material(
                      child: SwitchListTile(
                        title: const Text('Asset Inspected'),
                        subtitle: const Text('Mark this asset as checked'),
                        value: _isChecked,
                        onChanged: (value) =>
                            setState(() => _isChecked = value),
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Status selection
                    if (_isChecked) ...[
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: statusOptions.map((status) {
                          final isSelected = _status == status;
                          return FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) => setState(
                              () => _status = selected ? status : null,
                            ),
                            selectedColor: scheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: scheme.primary,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                    ],

                    // Remarks
                    Text(
                      'Remarks',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any observations or notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Photos (${_photos.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add Photo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_photos.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photos.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 80,
                                      height: 80,
                                      child: StoredImage(path: _photos[index]),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removePhoto(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () {
                    final updatedAsset = widget.asset.copyWith(
                      isChecked: _isChecked,
                      status: _status,
                      remarks: _remarksController.text.trim().isNotEmpty
                          ? _remarksController.text.trim()
                          : null,
                      photos: _photos,
                    );
                    Navigator.pop(context, updatedAsset);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
