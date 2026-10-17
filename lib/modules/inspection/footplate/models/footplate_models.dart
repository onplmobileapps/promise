import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/station_asset_model.dart';

class Person {
  final String name;
  final String designation;
  final String department;
  final String orgUnit;

  const Person({
    required this.name,
    required this.designation,
    required this.department,
    required this.orgUnit,
  });

  /// A crew member named on the form, in the role they ride in.
  const Person.named(this.name, {required this.designation})
    : department = '',
      orgUnit = '';

  /// Who they are, as their name and whatever else is known of them.
  String get display => [
    name,
    designation,
    department,
    orgUnit,
  ].where((part) => part.isNotEmpty).join(', ');

  /// A crew member as [display] wrote them.
  static Person? fromDisplay(Object? display) {
    if (display is! String || display.trim().isEmpty) return null;
    final parts = display.split(',').map((part) => part.trim()).toList();
    String at(int i) => i < parts.length ? parts[i] : '';
    return Person(
      name: at(0),
      designation: at(1),
      department: at(2),
      orgUnit: at(3),
    );
  }

  @override
  String toString() => display;
}

const List<String> kCautionOrders = [
  'OP-354',
  '354-A',
  'OP-373',
  'OP-371',
  'OP-374',
  'OP-238',
  'OP-239',
  'OP-122',
  'OP-128',
  'OP-129',
  'OP-460',
  'OP-38',
  'OP-39',
];

// ---------------------------------------------------------------------------
// Step 1: Train Schedule
// ---------------------------------------------------------------------------
class TrainScheduleData {
  String? trainNo;
  String load = '';
  String? engineNo;
  String direction = 'Up';
  String? station;
  TimeOfDay? arrival;
  TimeOfDay? departure;
  int lateMargin = 0;
  Person? driver;
  Person? assistantDriver;
  Person? guardIncharge;

  bool get isComplete =>
      trainNo != null &&
      engineNo != null &&
      station != null &&
      driver != null &&
      assistantDriver != null &&
      guardIncharge != null;
}

// ---------------------------------------------------------------------------
// Step 2: Condition of Locomotive
// ---------------------------------------------------------------------------
const List<String> kLocomotiveItems = [
  'Speedo Meter',
  'Vigilance Device',
  'Traction Motors',
  'Notches',
  'Hand Brake',
  'VHF Set Driver',
  'VHF Guard',
  'Buffer Light',
  'Headlights',
  'Whistle',
  'Detonator',
  'Deadman Pedal',
  'Weather',
  'Fire Extinguisher',
  'Motorola Set',
  'B.P Pressure',
  'M.A.R',
  'Visibility',
];

enum LocomotiveFieldType { boolean, integer, date, multiSelect }

class LocomotiveFieldConfig {
  final String key;
  final List<String> options; // For multi-select fields
  final LocomotiveFieldType fieldType;
  final bool requiresInteger;
  final bool requiresDate;
  // When true, this item skips the OK/Issue toggle entirely and shows its
  // selection panel (chips) directly — used for items like Weather that
  // describe a condition rather than a pass/fail check.
  final bool directSelect;

  const LocomotiveFieldConfig({
    required this.key,
    this.options = const [],
    this.fieldType = LocomotiveFieldType.boolean,
    this.requiresInteger = false,
    this.requiresDate = false,
    this.directSelect = false,
  });
}

final Map<String, LocomotiveFieldConfig> kLocomotiveFieldConfigs = {
  'Notches': LocomotiveFieldConfig(
    key: 'Notches',
    fieldType: LocomotiveFieldType.integer,
    requiresInteger: true,
  ),
  'Detonator': LocomotiveFieldConfig(
    key: 'Detonator',
    fieldType: LocomotiveFieldType.multiSelect,
    requiresInteger: true,
    requiresDate: true,
    options: ['Expired', 'Damaged', 'Missing', 'Low Stock', 'Other'],
  ),
  'Deadman Pedal': LocomotiveFieldConfig(
    key: 'Deadman Pedal',
    fieldType: LocomotiveFieldType.multiSelect,
    options: ['Stuck', 'Loose', 'Not Responding', 'Damaged', 'Other'],
  ),
  'Weather': LocomotiveFieldConfig(
    key: 'Weather',
    fieldType: LocomotiveFieldType.multiSelect,
    options: ['Clear', 'Rain', 'Fog', 'Snow', 'Storm', 'Other'],
    directSelect: true,
  ),
  'Fire Extinguisher': LocomotiveFieldConfig(
    key: 'Fire Extinguisher',
    fieldType: LocomotiveFieldType.multiSelect,
    options: [
      'Expired',
      'Empty',
      'Damaged',
      'Missing',
      'Pressure Low',
      'Other',
    ],
  ),
  'Motorola Set': LocomotiveFieldConfig(
    key: 'Motorola Set',
    fieldType: LocomotiveFieldType.multiSelect,
    options: [
      'Not Working',
      'Poor Signal',
      'Battery Low',
      'Damaged',
      'Missing',
      'Other',
    ],
  ),
  'B.P Pressure': LocomotiveFieldConfig(
    key: 'B.P Pressure',
    fieldType: LocomotiveFieldType.multiSelect,
    options: ['Low', 'High', 'Fluctuating', 'Leaking', 'Gauge Faulty', 'Other'],
  ),
  'M.A.R': LocomotiveFieldConfig(
    key: 'M.A.R',
    fieldType: LocomotiveFieldType.multiSelect,
    options: [
      'Not Working',
      'Damaged',
      'Calibration Issue',
      'Missing',
      'Other',
    ],
  ),
  'Visibility': LocomotiveFieldConfig(
    key: 'Visibility',
    fieldType: LocomotiveFieldType.multiSelect,
    options: ['Poor', 'Obstructed', 'Fog', 'Night', 'Other'],
  ),
};

class LocomotiveEquipmentStatus {
  bool isFunctional;
  List<String> selectedIssues;
  int? integerValue;
  DateTime? dateValue;

  LocomotiveEquipmentStatus({
    this.isFunctional = true,
    this.selectedIssues = const [],
    this.integerValue,
    this.dateValue,
  });

  bool get hasIssue => !isFunctional || selectedIssues.isNotEmpty;
}

class LocomotiveCondition {
  // Map of equipment name to its status
  final Map<String, LocomotiveEquipmentStatus> equipmentStatus = {};

  LocomotiveCondition() {
    // Initialize all equipment with default status
    for (final item in kLocomotiveItems) {
      equipmentStatus[item] = LocomotiveEquipmentStatus();
    }
  }

  int get issueCount => equipmentStatus.values.where((s) => s.hasIssue).length;

  LocomotiveEquipmentStatus getStatus(String item) {
    return equipmentStatus[item] ?? LocomotiveEquipmentStatus();
  }

  void setStatus(String item, LocomotiveEquipmentStatus status) {
    equipmentStatus[item] = status;
  }
}

// ---------------------------------------------------------------------------
// Step 3: Asset Checks (Signal / Track / Level Crossing / Tunnel / Bridge / Curve / Station)
// ---------------------------------------------------------------------------
class RadioFieldConfig {
  final String key;
  final String label;
  final List<String> options;
  // Optional conditional visibility: only show this field if `showIfKey` == `showIfValue`
  final String? showIfKey;
  final String? showIfValue;

  const RadioFieldConfig({
    required this.key,
    required this.label,
    required this.options,
    this.showIfKey,
    this.showIfValue,
  });
}

const List<String> kAssetTypes = [
  'Signal', 'Track', 'Level Crossing - Manned', 'Level Crossing - Unmanned',
  'Tunnel', 'Bridge', 'Curve',
  // 'Station' intentionally excluded — station inspection is already covered
  // in-depth by the dedicated "Station Assets" wizard step, so keeping it
  // here duplicated the same inspection twice in the flow.
];

const _rideQuality = [
  'Rough Riding',
  'Lurching',
  'Oscillation',
  'Kinky',
  'Jerk',
];

final Map<String, List<RadioFieldConfig>> kAssetFieldConfig = {
  'Signal': [
    RadioFieldConfig(
      key: 'visibility',
      label: 'Signal Visibility',
      options: ['Good', 'Poor', 'Obstructed'],
    ),
  ],
  'Track': [
    RadioFieldConfig(
      key: 'ride_quality',
      label: 'Track ride quality',
      options: _rideQuality,
    ),
    // The remaining fields only apply when the inspecting officer is from the Civil dept.
    RadioFieldConfig(
      key: 'rails',
      label: 'Rails',
      options: ['Wheel Burnt', 'End Battered', 'Hogged'],
      showIfKey: '_civil',
      showIfValue: 'yes',
    ),
    RadioFieldConfig(
      key: 'rail_joints',
      label: 'Rail Joints',
      options: ['Low', 'Aligned'],
      showIfKey: '_civil',
      showIfValue: 'yes',
    ),
    RadioFieldConfig(
      key: 'ballast_cushion',
      label: 'Ballast Cushion',
      options: ['Proper', 'Scattered', 'Fouled'],
      showIfKey: '_civil',
      showIfValue: 'yes',
    ),
    RadioFieldConfig(
      key: 'sleepers',
      label: 'Sleepers',
      options: ['Serviceable', 'Un-Serviceable'],
      showIfKey: '_civil',
      showIfValue: 'yes',
    ),
    RadioFieldConfig(
      key: 'boundary_marks',
      label: 'Boundary Marks',
      options: ['Fixed', 'Not Fixed'],
      showIfKey: '_civil',
      showIfValue: 'yes',
    ),
  ],
  'Level Crossing - Manned': [
    RadioFieldConfig(
      key: 'road_surface',
      label: 'Condition of road surface',
      options: ['Good', 'Needs Repair', 'Satisfactory'],
    ),
    RadioFieldConfig(
      key: 'gatekeeper_alert',
      label: 'Alertness of gatekeeper',
      options: ['Alert', 'Not Alert'],
    ),
    RadioFieldConfig(
      key: 'give_signal',
      label: 'Give signal',
      options: ['Yes', 'No'],
      showIfKey: 'gatekeeper_alert',
      showIfValue: 'Alert',
    ),
    RadioFieldConfig(
      key: 'gate_signal_visibility',
      label: 'Visibility of Gate signals',
      options: ['Good', 'Poor'],
      showIfKey: 'gatekeeper_alert',
      showIfValue: 'Alert',
    ),
    RadioFieldConfig(
      key: 'vehicle_visibility',
      label: 'Visibility of Train/Road Vehicle',
      options: ['Good', 'Fair', 'Obstructed'],
    ),
    RadioFieldConfig(
      key: 'bridge_approaches',
      label: 'Bridge approaches',
      options: _rideQuality,
    ),
    RadioFieldConfig(
      key: 'points_crossing',
      label: 'Points & crossing',
      options: _rideQuality,
    ),
    RadioFieldConfig(
      key: 'person_available',
      label: 'Person Available',
      options: ['Patrollers', 'Keymen', 'Not Available'],
    ),
    RadioFieldConfig(
      key: 'trespassing',
      label: 'Trespassing',
      options: ['Fencing Provided', 'Fencing not Provided', 'Partial fencing'],
    ),
  ],
  'Level Crossing - Unmanned': [
    RadioFieldConfig(
      key: 'sign_boards',
      label: 'Sign boards',
      options: ['Provided', 'Not provided'],
    ),
    RadioFieldConfig(
      key: 'speed_breakers',
      label: 'Speed breakers',
      options: ['Provided', 'Not provided'],
    ),
    RadioFieldConfig(
      key: 'boundary_pillar',
      label: 'Boundary Pillar',
      options: ['Provided', 'Not provided'],
    ),
  ],
  'Tunnel': [
    RadioFieldConfig(
      key: 'lining',
      label: 'Condition of Lining',
      options: ['Sound', 'Cracked', 'Bulged', 'Spelled'],
    ),
    RadioFieldConfig(
      key: 'seepage',
      label: 'Seepage / Dampness',
      options: ['None', 'Minor', 'Heavy'],
    ),
    RadioFieldConfig(
      key: 'roof_leakage',
      label: 'Leakage through Roof',
      options: ['Yes', 'No'],
    ),
    RadioFieldConfig(
      key: 'drain_holes',
      label: 'Drain Holes in Lining',
      options: ['Clear', 'Blocked', 'Not Provided'],
    ),
    RadioFieldConfig(
      key: 'side_drain',
      label: 'Side Drain Along Track',
      options: ['Clear', 'Blocked'],
    ),
    RadioFieldConfig(
      key: 'clearance',
      label: 'Clearance',
      options: ['Horizontal', 'Vertical'],
    ),
  ],
  'Bridge': [
    RadioFieldConfig(
      key: 'cross_level',
      label: 'Cross Level',
      options: ['Exact', 'Within limit', 'Need Adjustment'],
    ),
    RadioFieldConfig(
      key: 'timber_spacing',
      label: 'Spacing of Timber',
      options: ['Satisfactory', 'Un-Satisfactory', 'Need Replacement'],
    ),
    RadioFieldConfig(
      key: 'approaching_joints',
      label: 'Approaching Joints',
      options: ['Low', 'Aligned'],
    ),
  ],
  'Curve': [
    RadioFieldConfig(
      key: 'ride_quality',
      label: 'Track ride quality',
      options: _rideQuality,
    ),
  ],
};

class AssetCheckEntry {
  String assetType;
  bool civilDept;
  double? decimalKm;
  final Map<String, dynamic> answers = {};

  AssetCheckEntry({
    required this.assetType,
    this.civilDept = false,
    this.decimalKm,
  });

  int get issueCount {
    // A rough heuristic: anything not in the first ("good") option counts as an issue.
    int count = 0;
    final fields = kAssetFieldConfig[assetType] ?? [];
    for (final f in fields) {
      final ans = answers[f.key];
      if (ans != null && f.options.isNotEmpty && ans != f.options.first) {
        count++;
      }
    }
    return count;
  }
}

// ---------------------------------------------------------------------------
// Step 4: Punctuality of Trains + Caution Orders / OPs
// ---------------------------------------------------------------------------
class PunctualityEntry {
  String station;
  DateTime? scheduleArrival;
  DateTime? actualArrival;
  DateTime? scheduleDeparture;
  DateTime? actualDeparture;
  String remarks = '';

  PunctualityEntry({required this.station});

  Duration? get arrivalDiff =>
      (scheduleArrival != null && actualArrival != null)
      ? actualArrival!.difference(scheduleArrival!)
      : null;
  Duration? get departureDiff =>
      (scheduleDeparture != null && actualDeparture != null)
      ? actualDeparture!.difference(scheduleDeparture!)
      : null;

  bool get hasDifference =>
      (arrivalDiff != null && arrivalDiff!.inSeconds != 0) ||
      (departureDiff != null && departureDiff!.inSeconds != 0);
}

class OPEntry {
  String opCode;
  String decimal;
  OPEntry({required this.opCode, this.decimal = ''});
}

// ---------------------------------------------------------------------------
// Root data object for the whole wizard
// ---------------------------------------------------------------------------
class FootplateInspectionData {
  String id = 'inspection-${DateTime.now().millisecondsSinceEpoch}';
  final TrainScheduleData trainSchedule = TrainScheduleData();
  final LocomotiveCondition locomotive = LocomotiveCondition();
  final List<StationAsset> stationAssets = [];
  final List<AssetCheckEntry> assetChecks = [];
  final List<PunctualityEntry> punctuality = [];
  final List<OPEntry> ops = [];
  String finalRemarks = '';
}
