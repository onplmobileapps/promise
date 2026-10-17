/// Station-wise asset model for footplate inspection
class StationAsset {
  final String id;
  final String stationName;
  final String stationCode;
  final List<StationAssetItem> assets;
  String? overallRemarks;
  bool isCompleted;

  StationAsset({
    required this.id,
    required this.stationName,
    required this.stationCode,
    required this.assets,
    this.overallRemarks,
    this.isCompleted = false,
  });

  int get completedAssets => assets.where((a) => a.isChecked).length;
  int get totalAssets => assets.length;
  int get issueCount => assets.where((a) => a.hasIssue).length;

  StationAsset copyWith({
    String? id,
    String? stationName,
    String? stationCode,
    List<StationAssetItem>? assets,
    String? overallRemarks,
    bool? isCompleted,
  }) {
    return StationAsset(
      id: id ?? this.id,
      stationName: stationName ?? this.stationName,
      stationCode: stationCode ?? this.stationCode,
      assets: assets ?? this.assets,
      overallRemarks: overallRemarks ?? this.overallRemarks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationName': stationName,
      'stationCode': stationCode,
      'assets': assets.map((a) => a.toJson()).toList(),
      'overallRemarks': overallRemarks,
      'isCompleted': isCompleted,
    };
  }

  factory StationAsset.fromJson(Map<String, dynamic> json) {
    return StationAsset(
      id: json['id'] as String,
      stationName: json['stationName'] as String,
      stationCode: json['stationCode'] as String,
      assets: (json['assets'] as List)
          .map((a) => StationAssetItem.fromJson(a as Map<String, dynamic>))
          .toList(),
      overallRemarks: json['overallRemarks'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class StationAssetItem {
  final String id;
  final String assetType;
  final String assetName;
  final String? location;
  final String? category;
  bool isChecked;
  String? status;
  String? remarks;
  List<String> photos;

  StationAssetItem({
    required this.id,
    required this.assetType,
    required this.assetName,
    this.location,
    this.category,
    this.isChecked = false,
    this.status,
    this.remarks,
    List<String>? photos,
  }) : photos = photos ?? [];

  bool get hasIssue =>
      status != null &&
      status != 'Good' &&
      status != 'Satisfactory' &&
      status != 'Provided';

  StationAssetItem copyWith({
    String? id,
    String? assetType,
    String? assetName,
    String? location,
    String? category,
    bool? isChecked,
    String? status,
    String? remarks,
    List<String>? photos,
  }) {
    return StationAssetItem(
      id: id ?? this.id,
      assetType: assetType ?? this.assetType,
      assetName: assetName ?? this.assetName,
      location: location ?? this.location,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      photos: photos ?? this.photos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetType': assetType,
      'assetName': assetName,
      'location': location,
      'category': category,
      'isChecked': isChecked,
      'status': status,
      'remarks': remarks,
      'photos': photos,
    };
  }

  factory StationAssetItem.fromJson(Map<String, dynamic> json) {
    return StationAssetItem(
      id: json['id'] as String,
      assetType: json['assetType'] as String,
      assetName: json['assetName'] as String,
      location: json['location'] as String?,
      category: json['category'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      status: json['status'] as String?,
      remarks: json['remarks'] as String?,
      photos: (json['photos'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// The assets every station on a run is checked for.
class StationAssetData {
  /// The assets a station is checked for: its signals, its tracks and its
  /// platform.
  static const List<(String, String)> _standard = [
    ('Signal', 'Home Signal'),
    ('Signal', 'Starting Signal'),
    ('Track', 'Main Line Track'),
    ('Track', 'Loop Line Track'),
    ('Platform', 'Platform'),
  ];

  /// [station], as a station picker names it ("Lahore Junction (LHR)"),
  /// with the assets every station is checked for.
  static StationAsset forStation(String station) {
    final code = RegExp(r'\(([^)]+)\)\s*$').firstMatch(station)?.group(1);
    final name = station.replaceFirst(RegExp(r'\s*\([^)]+\)\s*$'), '');
    final id =
        'stn_${station.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_')}';
    return StationAsset(
      id: id,
      stationName: name,
      stationCode: code ?? '',
      assets: [
        for (final (type, asset) in _standard)
          StationAssetItem(
            id: '${id}_${asset.toLowerCase().replaceAll(' ', '_')}',
            assetType: type,
            assetName: asset,
            category: type,
            photos: [],
          ),
      ],
    );
  }

  static List<String> getStatusOptions(String assetType) {
    switch (assetType) {
      case 'Signal':
        return ['Good', 'Poor', 'Obstructed', 'Not Working'];
      case 'Track':
        return [
          'Good',
          'Rough Riding',
          'Lurching',
          'Oscillation',
          'Needs Repair',
        ];
      case 'Level Crossing':
        return ['Good', 'Needs Repair', 'Gate Not Working', 'Satisfactory'];
      case 'Platform':
        return ['Satisfactory', 'Need Repair', 'Good Condition'];
      case 'Bridge':
        return ['Good', 'Needs Attention', 'Critical', 'Satisfactory'];
      case 'Tunnel':
        return ['Sound', 'Cracked', 'Bulged', 'Needs Repair'];
      case 'Curve':
        return ['Good', 'Rough', 'Oscillation', 'Kinky'];
      default:
        return ['Good', 'Satisfactory', 'Needs Repair', 'Critical'];
    }
  }
}
