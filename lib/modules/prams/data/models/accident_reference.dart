int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

String? _asString(dynamic v) => v?.toString();

class AccidentClass {
  final int id;
  final String code;
  final String shortMeaning;
  final String detailedDescription;
  final String defaultSeverity;

  const AccidentClass({
    required this.id,
    required this.code,
    required this.shortMeaning,
    required this.detailedDescription,
    required this.defaultSeverity,
  });

  factory AccidentClass.fromJson(Map<String, dynamic> json) => AccidentClass(
    id: _asInt(json['id'])!,
    code: json['code'] as String,
    shortMeaning: json['short_meaning'] as String? ?? '',
    detailedDescription: json['detailed_description'] as String? ?? '',
    defaultSeverity: json['default_severity'] as String? ?? '',
  );
}

// ── Divisions / sections / block sections ──────────────────────────────

class RefSection {
  final int id;
  final String name;
  final String? line;
  final int? lineId;

  const RefSection({
    required this.id,
    required this.name,
    this.line,
    this.lineId,
  });

  factory RefSection.fromJson(Map<String, dynamic> json) => RefSection(
    id: _asInt(json['id'])!,
    name: json['name'] as String? ?? '',
    line: _asString(json['line']),
    lineId: _asInt(json['line_id']),
  );
}

class RefBlockSection {
  final String id; // UUID string
  final String name;
  final String? label;

  const RefBlockSection({required this.id, required this.name, this.label});

  factory RefBlockSection.fromJson(Map<String, dynamic> json) =>
      RefBlockSection(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        label: _asString(json['label']),
      );
}

class RefDivision {
  final int id;
  final String name;
  final String? code;
  final List<RefSection> sections;
  final List<RefBlockSection> blockSections;

  const RefDivision({
    required this.id,
    required this.name,
    this.code,
    this.sections = const [],
    this.blockSections = const [],
  });

  factory RefDivision.fromJson(Map<String, dynamic> json) => RefDivision(
    id: _asInt(json['id'])!,
    name: json['name'] as String? ?? '',
    code: _asString(json['code']),
    sections: (json['sections'] as List<dynamic>? ?? [])
        .map((e) => RefSection.fromJson(e as Map<String, dynamic>))
        .toList(),
    blockSections: (json['block_sections'] as List<dynamic>? ?? [])
        .map((e) => RefBlockSection.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ── Small shared reference objects nested inside a train ───────────────

class RefLine {
  final int id;
  final String name;

  const RefLine({required this.id, required this.name});

  factory RefLine.fromJson(Map<String, dynamic> json) =>
      RefLine(id: _asInt(json['id'])!, name: json['name'] as String? ?? '');
}

class RefStation {
  final int id;
  final String name;
  final String? stationCode;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final double? stationKm;
  final int? line;

  const RefStation({
    required this.id,
    required this.name,
    this.stationCode,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.stationKm,
    this.line,
  });

  factory RefStation.fromJson(Map<String, dynamic> json) => RefStation(
    id: _asInt(json['id'])!,
    name: json['name'] as String? ?? '',
    stationCode: _asString(json['station_code']),
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    distanceKm: _asDouble(json['distance_km']),
    stationKm: _asDouble(json['station_km']),
    line: _asInt(json['line']),
  );
}

class TrainDivisionRef {
  final int id;
  final String name;
  final String? code;

  const TrainDivisionRef({required this.id, required this.name, this.code});

  factory TrainDivisionRef.fromJson(Map<String, dynamic> json) =>
      TrainDivisionRef(
        id: _asInt(json['id'])!,
        name: json['name'] as String? ?? '',
        code: _asString(json['code']),
      );
}

class TrainSectionRef {
  final int id;
  final String name;
  final String? line;

  const TrainSectionRef({required this.id, required this.name, this.line});

  factory TrainSectionRef.fromJson(Map<String, dynamic> json) =>
      TrainSectionRef(
        id: _asInt(json['id'])!,
        name: json['name'] as String? ?? '',
        line: _asString(json['line']),
      );
}

class TrainBlockSectionRef {
  final String id; // UUID
  final String name;
  final String? label;

  const TrainBlockSectionRef({
    required this.id,
    required this.name,
    this.label,
  });

  factory TrainBlockSectionRef.fromJson(Map<String, dynamic> json) =>
      TrainBlockSectionRef(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        label: _asString(json['label']),
      );
}

class RollingStockItem {
  final int order;
  final String category;
  final String type;
  final int assetId;
  final String assetNumber;

  const RollingStockItem({
    required this.order,
    required this.category,
    required this.type,
    required this.assetId,
    required this.assetNumber,
  });

  factory RollingStockItem.fromJson(Map<String, dynamic> json) =>
      RollingStockItem(
        order: _asInt(json['order']) ?? 0,
        category: json['category'] as String? ?? '',
        type: json['type'] as String? ?? '',
        assetId: _asInt(json['asset_id']) ?? 0,
        assetNumber: json['asset_number'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'order': order,
    'category': category,
    'type': type,
    'asset_id': assetId,
    'asset_number': assetNumber,
  };
}

// ── Active train ─────────────────────────────────────────────────────

class ActiveTrain {
  final int formationId;
  final int trainId;
  final String trainName;
  final String fullTrainName;
  final String trainNumber;
  final String direction;
  final String
  trainType; // API sometimes sends this as an int; normalized to String
  final String effectiveDate;
  final int? deviceId;
  final double? latitude;
  final double? longitude;
  final String? location;
  final TrainDivisionRef? division;
  final TrainSectionRef? section;
  final TrainBlockSectionRef? blockSection;
  final RefLine? line;
  final RefStation? nearestStation;
  final double? kilometerNumber;
  final RefStation? lastCrossedStation;
  final String? locomotiveNumber;
  final List<RollingStockItem> attachedRollingStock;
  final RefStation? originStation;
  final RefStation? destinationStation;

  const ActiveTrain({
    required this.formationId,
    required this.trainId,
    required this.trainName,
    required this.fullTrainName,
    required this.trainNumber,
    required this.direction,
    required this.trainType,
    required this.effectiveDate,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.location,
    this.division,
    this.section,
    this.blockSection,
    this.line,
    this.nearestStation,
    this.kilometerNumber,
    this.lastCrossedStation,
    this.locomotiveNumber,
    this.attachedRollingStock = const [],
    this.originStation,
    this.destinationStation,
  });

  /// Label for a train picker, e.g. "127-UP · Special Train"
  String get displayLabel =>
      trainName.isNotEmpty ? fullTrainName : '$trainNumber-$direction';

  factory ActiveTrain.fromJson(Map<String, dynamic> json) => ActiveTrain(
    formationId: _asInt(json['formation_id']) ?? 0,
    trainId: _asInt(json['train_id']) ?? 0,
    trainName: json['train_name'] as String? ?? '',
    fullTrainName: json['full_train_name'] as String? ?? '',
    trainNumber: json['train_number'] as String? ?? '',
    direction: json['direction'] as String? ?? '',
    // train_type is occasionally an int in the API response — normalize.
    trainType: _asString(json['train_type']) ?? '',
    effectiveDate: json['effective_date'] as String? ?? '',
    deviceId: _asInt(json['device_id']),
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    location: _asString(json['location']),
    division: json['division'] == null
        ? null
        : TrainDivisionRef.fromJson(json['division'] as Map<String, dynamic>),
    section: json['section'] == null
        ? null
        : TrainSectionRef.fromJson(json['section'] as Map<String, dynamic>),
    blockSection: json['block_section'] == null
        ? null
        : TrainBlockSectionRef.fromJson(
            json['block_section'] as Map<String, dynamic>,
          ),
    line: json['line'] == null
        ? null
        : RefLine.fromJson(json['line'] as Map<String, dynamic>),
    nearestStation: json['nearest_station'] == null
        ? null
        : RefStation.fromJson(json['nearest_station'] as Map<String, dynamic>),
    kilometerNumber: _asDouble(json['kilometer_number']),
    lastCrossedStation: json['last_crossed_station'] == null
        ? null
        : RefStation.fromJson(
            json['last_crossed_station'] as Map<String, dynamic>,
          ),
    locomotiveNumber: _asString(json['locomotive_number']),
    attachedRollingStock:
        (json['attached_rolling_stock'] as List<dynamic>? ?? [])
            .map((e) => RollingStockItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    originStation: json['origin_station'] == null
        ? null
        : RefStation.fromJson(json['origin_station'] as Map<String, dynamic>),
    destinationStation: json['destination_station'] == null
        ? null
        : RefStation.fromJson(
            json['destination_station'] as Map<String, dynamic>,
          ),
  );
}

// ── Top-level payload ───────────────────────────────────────────────────

class AccidentReferenceData {
  final List<AccidentClass> accidentClasses;
  final List<RefDivision> divisions;
  final List<ActiveTrain> activeTrains;

  const AccidentReferenceData({
    required this.accidentClasses,
    required this.divisions,
    required this.activeTrains,
  });

  factory AccidentReferenceData.fromJson(Map<String, dynamic> json) =>
      AccidentReferenceData(
        accidentClasses: (json['accident_classes'] as List<dynamic>? ?? [])
            .map((e) => AccidentClass.fromJson(e as Map<String, dynamic>))
            .toList(),
        divisions: (json['divisions'] as List<dynamic>? ?? [])
            .map((e) => RefDivision.fromJson(e as Map<String, dynamic>))
            .toList(),
        activeTrains: (json['active_trains'] as List<dynamic>? ?? [])
            .map((e) => ActiveTrain.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
