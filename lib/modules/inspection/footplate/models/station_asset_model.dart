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

/// Asset categories for organization
/// Mock station data with predefined assets
class StationAssetData {
  static List<StationAsset> getMockStations() {
    return [
      StationAsset(
        id: 'stn_001',
        stationName: 'Lahore Railway Station',
        stationCode: 'LHR',
        assets: _getLahoreAssets(),
      ),
      StationAsset(
        id: 'stn_002',
        stationName: 'Raiwind',
        stationCode: 'RWD',
        assets: _getRaiwindAssets(),
      ),
      StationAsset(
        id: 'stn_003',
        stationName: 'Sahiwal',
        stationCode: 'SWL',
        assets: _getSahiwalAssets(),
      ),
      StationAsset(
        id: 'stn_004',
        stationName: 'Multan Cantt',
        stationCode: 'MCO',
        assets: _getMultanAssets(),
      ),
      StationAsset(
        id: 'stn_005',
        stationName: 'Khanewal',
        stationCode: 'KWL',
        assets: _getKhanewalAssets(),
      ),
    ];
  }

  static List<StationAssetItem> _getLahoreAssets() {
    return [
      StationAssetItem(
        id: 'lhr_sig_001',
        assetType: 'Signal',
        assetName: 'Home Signal',
        location: 'Platform 1',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_sig_002',
        assetType: 'Signal',
        assetName: 'Starting Signal',
        location: 'Platform 2',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_trk_001',
        assetType: 'Track',
        assetName: 'Main Line Track',
        location: 'Platform 1-2',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_trk_002',
        assetType: 'Track',
        assetName: 'Loop Line Track',
        location: 'Platform 3-4',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_plt_001',
        assetType: 'Platform',
        assetName: 'Platform 1',
        location: 'Main Building',
        category: 'Platform',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_plt_002',
        assetType: 'Platform',
        assetName: 'Platform 2',
        location: 'Main Building',
        category: 'Platform',
        photos: [],
      ),
      StationAssetItem(
        id: 'lhr_lc_001',
        assetType: 'Level Crossing',
        assetName: 'LC Gate 1',
        location: 'Station Entrance',
        category: 'Level Crossing',
        photos: [],
      ),
    ];
  }

  static List<StationAssetItem> _getRaiwindAssets() {
    return [
      StationAssetItem(
        id: 'rwd_sig_001',
        assetType: 'Signal',
        assetName: 'Home Signal',
        location: 'Platform 1',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'rwd_trk_001',
        assetType: 'Track',
        assetName: 'Main Line Track',
        location: 'Station Area',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'rwd_lc_001',
        assetType: 'Level Crossing',
        assetName: 'LC Gate 1',
        location: 'North End',
        category: 'Level Crossing',
        photos: [],
      ),
    ];
  }

  static List<StationAssetItem> _getSahiwalAssets() {
    return [
      StationAssetItem(
        id: 'swl_sig_001',
        assetType: 'Signal',
        assetName: 'Home Signal',
        location: 'Platform 1',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'swl_trk_001',
        assetType: 'Track',
        assetName: 'Main Line Track',
        location: 'Station Area',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'swl_plt_001',
        assetType: 'Platform',
        assetName: 'Platform 1',
        location: 'Main Building',
        category: 'Platform',
        photos: [],
      ),
      StationAssetItem(
        id: 'swl_br_001',
        assetType: 'Bridge',
        assetName: 'Rail Bridge',
        location: 'South End',
        category: 'Bridge',
        photos: [],
      ),
    ];
  }

  static List<StationAssetItem> _getMultanAssets() {
    return [
      StationAssetItem(
        id: 'mco_sig_001',
        assetType: 'Signal',
        assetName: 'Home Signal',
        location: 'Platform 1',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_sig_002',
        assetType: 'Signal',
        assetName: 'Starting Signal',
        location: 'Platform 2',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_trk_001',
        assetType: 'Track',
        assetName: 'Main Line Track',
        location: 'Platform 1-2',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_plt_001',
        assetType: 'Platform',
        assetName: 'Platform 1',
        location: 'Main Building',
        category: 'Platform',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_plt_002',
        assetType: 'Platform',
        assetName: 'Platform 2',
        location: 'Main Building',
        category: 'Platform',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_lc_001',
        assetType: 'Level Crossing',
        assetName: 'LC Gate 1',
        location: 'Station Entrance',
        category: 'Level Crossing',
        photos: [],
      ),
      StationAssetItem(
        id: 'mco_tun_001',
        assetType: 'Tunnel',
        assetName: 'Tunnel Section',
        location: 'North Approach',
        category: 'Tunnel',
        photos: [],
      ),
    ];
  }

  static List<StationAssetItem> _getKhanewalAssets() {
    return [
      StationAssetItem(
        id: 'kwl_sig_001',
        assetType: 'Signal',
        assetName: 'Home Signal',
        location: 'Platform 1',
        category: 'Signal',
        photos: [],
      ),
      StationAssetItem(
        id: 'kwl_trk_001',
        assetType: 'Track',
        assetName: 'Main Line Track',
        location: 'Station Area',
        category: 'Track',
        photos: [],
      ),
      StationAssetItem(
        id: 'kwl_lc_001',
        assetType: 'Level Crossing',
        assetName: 'LC Gate 1',
        location: 'East End',
        category: 'Level Crossing',
        photos: [],
      ),
      StationAssetItem(
        id: 'kwl_cv_001',
        assetType: 'Curve',
        assetName: 'Sharp Curve',
        location: 'South Approach',
        category: 'Curve',
        photos: [],
      ),
    ];
  }

  /// Get status options for each asset type
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
