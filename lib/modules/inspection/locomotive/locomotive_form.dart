import 'package:railway_hrms/modules/inspection/shared/spec/form_spec.dart';

/// A question of the locomotive (GEU-40) inspection.
class LocoSpec implements FormSpec {
  const LocoSpec._(
    this.key,
    this.label,
    this.kind, {
    this.choices = const [],
    this.unit,
    this.note,
    this.faults = const [],
    this.showIfKey,
    this.showIfValue,
  });

  const LocoSpec.section(String label)
    : this._('', label, FormSpecKind.section);

  const LocoSpec.text(String key, String label)
    : this._(key, label, FormSpecKind.text);

  const LocoSpec.date(String key, String label, {String? note})
    : this._(key, label, FormSpecKind.date, note: note);

  @override
  final String key;
  @override
  final String label;
  @override
  final FormSpecKind kind;
  @override
  final List<String> choices;
  @override
  final String? unit;
  @override
  final String? note;
  @override
  final List<String> faults;
  @override
  final String? showIfKey;
  @override
  final Object? showIfValue;

  @override
  num? get maxValue => null;
  @override
  List<FormSpec> get parts => const [];
  @override
  String? get shownValue => null;
  @override
  String? get itemLabel => null;
}

/// A check of a part: how it was found, with a reading against its
/// [standard] when it is measured, and, once it is found at fault, the
/// likely [causes] and a note on what was seen, with [action] said under
/// it.
///
/// Every answer after the first reports the fault unless [faults] says
/// otherwise.
List<LocoSpec> check(
  String key,
  String label,
  List<String> answers, {
  String? standard,
  String? unit,
  List<String>? faults,
  List<String> causes = const [],
  String? action,
}) {
  final bad = faults ?? answers.skip(1).toList();
  return [
    LocoSpec._(
      key,
      label,
      FormSpecKind.choice,
      choices: answers,
      faults: bad,
      note: unit == null && standard != null ? 'Standard: $standard' : null,
    ),
    if (unit != null)
      LocoSpec._(
        '${key}_value',
        '$label — reading',
        FormSpecKind.number,
        unit: unit,
        note: standard == null ? null : 'Standard: $standard',
      ),
    if (causes.isNotEmpty)
      LocoSpec._(
        '${key}_cause',
        'Likely cause',
        FormSpecKind.choice,
        choices: causes,
        showIfKey: key,
        showIfValue: bad,
      ),
    LocoSpec._(
      '${key}_remarks',
      'What was found',
      FormSpecKind.text,
      note: action,
      showIfKey: key,
      showIfValue: bad,
    ),
  ];
}

const _ok = ['Satisfactory', 'Unsatisfactory'];
const _working = ['Working', 'Not Working'];
const _intact = ['Intact', 'Leaking'];

/// The GEU-40 locomotive inspection, part by part, as the proforma has it.
final List<LocoSpec> kLocomotiveSpecs = [
  const LocoSpec.section('Locomotive'),
  const LocoSpec.text('shed', 'Shed Name'),
  const LocoSpec.text('locoClass', 'Class of Loco'),
  const LocoSpec.text('locoNumber', 'Loco Number'),
  const LocoSpec.text('officer', 'Inspecting Officer'),
  const LocoSpec.section('Driver Cab'),
  ...check('cabArea', 'Driver Cab Area', ['Clean', 'Dirty']),
  ...check('seats', 'Driver / Assistant Driver Seat', [
    'Comfortable',
    'Not Comfortable',
  ]),
  ...check('display', 'Display Screen', _working),
  ...check(
    'fuelOilPressure',
    'Fuel Oil Pressure',
    _ok,
    standard: '600–700 KPA',
    unit: 'KPA',
  ),
  ...check(
    'cabLubeOilPressure',
    'Lube Oil Pressure',
    _ok,
    standard: '150–240 KPA',
    unit: 'KPA',
  ),
  ...check(
    'cabBoosterPressure',
    'Booster Pressure',
    _ok,
    standard: '80–110 KPA',
    unit: 'KPA',
  ),
  ...check('vigilance', 'Vigilance Device', ['Active', 'Inactive']),
  ...check('wheelSlip', 'Wheel Slip', _working),
  ...check('groundRelay', 'Ground Relay', ['Active', 'Inactive']),
  ...check('headLights', 'Head Lights', _working),
  ...check('bufferLight', 'Buffer Light', _working),
  ...check('horn', 'Horn', _working),
  ...check('wipers', 'Wipers', _working),
  ...check(
    'independentBrake',
    'Independent Brake',
    _ok,
    standard: '4.2 bar',
    unit: 'bar',
  ),
  ...check(
    'proportionalBrake',
    'Proportional Brake',
    _ok,
    standard: '4.2 bar',
    unit: 'bar',
  ),
  ...check(
    'marPressure',
    'MAR Pressure',
    _ok,
    standard: '8.3–9.8 bar',
    unit: 'bar',
  ),
  const LocoSpec.date(
    'fireExtinguisherExpiry',
    'Fire Extinguisher Expiry',
    note: 'DCP is valid for 6 months',
  ),
  ...check('handBrake', 'Hand Brake', _working),
  const LocoSpec.section('Battery'),
  ...check('terminalLeads', 'Terminal Leads', ['Tight', 'Loose']),
  ...check('leadConnection', 'Lead Connection', ['Tight', 'Loose']),
  ...check(
    'cellVoltages',
    'Cell Voltages',
    _ok,
    standard: '8 cells, 2 V each',
    unit: 'V',
  ),
  ...check('crate', 'Crate Condition', ['Good', 'Fair', 'Damaged']),
  const LocoSpec.section('Engine Room'),
  ...check('crankCaseOil', 'Crank Case Oil Level', ['Full', 'Mid', 'Low']),
  ...check('waterLevel', 'Water Level', ['Full', 'Dead']),
  ...check('exhausterManifold', 'Exhauster Manifold', _intact),
  ...check('fuelLines', 'Fuel Lines', _intact),
  ...check('fuelInjectionPump', 'Fuel Injection Pump', _working),
  ...check('waterPump', 'Water Pump', _intact),
  ...check('lubeOilPump', 'Lube Oil Pump', _working),
  ...check('lubeOilFilter', 'Lube Oil Filter Zone', ['Green', 'Yellow', 'Red']),
  ...check('fuelFilterHousing', 'Fuel Filter Housing', _intact),
  ...check('fuelStrainer', 'Fuel Strainer', _intact),
  ...check('fuelRacks', 'Fuel Racks Assembly (Firing Order)', ['Yes', 'No']),
  const LocoSpec.section('Compressor Room'),
  ...check('compressorOil', 'Oil Level', ['Green', 'Red']),
  ...check(
    'safetyValves',
    'Safety Valves Blowing',
    _ok,
    causes: ['Air Compress Valves Malfunctioned', 'Excess Air Pressure'],
  ),
  ...check('knocking', 'Any Knocking Sound', ['Yes', 'No'], faults: ['Yes']),
  ...check(
    'abnormalTemperature',
    'Abnormal Temperature',
    ['Yes', 'No'],
    faults: ['Yes'],
  ),
  ...check(
    'compressorLubeOil',
    'Lube Oil Pressure',
    _ok,
    standard: '> 10 psi',
    unit: 'psi',
  ),
  ...check(
    'compressorLoading',
    'Air Compressor Loading',
    _ok,
    standard: '30–35 s at 600–650 RPM',
    causes: [
      'Shaft uncoupled',
      'Hose pipe uncoupled',
      'Valve malfunctioned',
      'Aux voltage drop',
      'Other',
    ],
  ),
  const LocoSpec.section('Under Truck'),
  ...check('brakeShoe', 'Brake Shoe', _ok, standard: '> 0.5 in', unit: 'in'),
  ...check('wheelDefects', 'Wheel Defects (Profile Gauge)', [
    'Go In',
    'Go Out',
  ], action: 'Replace the wheel if it goes out.'),
  ...check(
    'buffers',
    'Buffers Length',
    _ok,
    standard: '620–625 mm',
    unit: 'mm',
    action: 'Replace the buffer if out of range.',
  ),
  ...check('shockAbsorber', 'Shock Absorber', _intact),
  ...check(
    'gearCaseOil',
    'Gear Case Oil Level',
    _ok,
    standard: '7–10.5 L',
    unit: 'L',
    action: 'Replace the gear case or seal if unsatisfactory.',
  ),
  ...check('coilSprings', 'Coil Springs', ['Intact', 'Broken']),
  ...check('guideLink', 'Guide Link', ['Intact', 'Broken']),
  const LocoSpec.section('Electrical Compartment'),
  ...check('cards', 'Cards / Panels (SDIP Test)', _working),
  ...check('blowers', 'Blowers & Motors (SDIP Test)', _working),
  const LocoSpec.section('Traction Motor'),
  ...check('inspectionCover', 'Inspection Cover', ['Fitted', 'Not Fitted']),
  ...check('leads', 'Leads Condition', ['Intact', 'Perished']),
  ...check('thimble', 'Thimble', ['Intact', 'Loose']),
  ...check('airBootDuct', 'Air Boot Duct', ['Intact', 'Broken']),
  const LocoSpec.section('Load Test'),
  ...check('engineRpm', 'Engine RPM', _ok, standard: '1000–1050'),
  ...check('loadBooster', 'Booster Pressure', _ok, standard: '300–330 KPA'),
  ...check('loadLubeOil', 'Lube Oil Pressure', _ok, standard: '> 600 KPA'),
  ...check('loadFuel', 'Fuel Pressure', _ok, standard: '550–600 KPA'),
  ...check('alternator', 'Alternator Voltages', _ok, standard: '1250–1300 V'),
  ...check('grossKw', 'Gross KW', _ok, standard: '3400 KW'),
];
