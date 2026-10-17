import 'package:railway_hrms/modules/inspection/shared/spec/form_spec.dart';

/// Field specification for electrical inspection forms.
/// Defines the structure, validation rules, and conditional logic for each field.
class ElectricalFieldSpec implements FormSpec {
  @override
  final String key;
  @override
  final String label;
  final ElectricalFieldType type;
  final List<String>? options;
  final String? conditionKey;
  final String? conditionValue;
  @override
  final int? maxValue;
  @override
  final String? unit;
  final List<ElectricalFieldSpec>? children;

  @override
  FormSpecKind get kind => switch (type) {
    ElectricalFieldType.section => FormSpecKind.section,
    ElectricalFieldType.group => FormSpecKind.group,
    ElectricalFieldType.text => FormSpecKind.text,
    ElectricalFieldType.number => FormSpecKind.number,
    ElectricalFieldType.radio ||
    ElectricalFieldType.checkbox => FormSpecKind.choice,
    ElectricalFieldType.dropdown => FormSpecKind.select,
    ElectricalFieldType.date => FormSpecKind.date,
  };

  @override
  List<String> get choices =>
      options ??
      (type == ElectricalFieldType.checkbox ? const ['Yes', 'No'] : const []);

  @override
  List<FormSpec> get parts => children ?? const [];

  @override
  String? get showIfKey => conditionKey;

  @override
  Object? get showIfValue => conditionValue;

  @override
  String? get shownValue => null;

  @override
  String? get itemLabel => null;

  @override
  String? get note => null;

  @override
  List<String> get faults => const [];

  const ElectricalFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.conditionKey,
    this.conditionValue,
    this.maxValue,
    this.unit,
    this.children,
  });

  const ElectricalFieldSpec.section(this.label)
    : key = '',
      type = ElectricalFieldType.section,
      options = null,
      conditionKey = null,
      conditionValue = null,
      maxValue = null,
      unit = null,
      children = null;

  const ElectricalFieldSpec.group(this.label, this.children)
    : key = '',
      type = ElectricalFieldType.group,
      options = null,
      conditionKey = null,
      conditionValue = null,
      maxValue = null,
      unit = null;

  const ElectricalFieldSpec.radio(
    this.key,
    this.label,
    this.options, {
    this.conditionKey,
    this.conditionValue,
  }) : type = ElectricalFieldType.radio,
       maxValue = null,
       unit = null,
       children = null;

  const ElectricalFieldSpec.dropdown(
    this.key,
    this.label,
    this.options, {
    this.conditionKey,
    this.conditionValue,
  }) : type = ElectricalFieldType.dropdown,
       maxValue = null,
       unit = null,
       children = null;

  ElectricalFieldSpec.number(
    this.key,
    this.label, {
    this.maxValue,
    this.unit,
    this.conditionKey,
    this.conditionValue,
  }) : type = ElectricalFieldType.number,
       options = null,
       children = null;

  const ElectricalFieldSpec.text(
    this.key,
    this.label, {
    this.conditionKey,
    this.conditionValue,
  }) : type = ElectricalFieldType.text,
       options = null,
       maxValue = null,
       unit = null,
       children = null;

  const ElectricalFieldSpec.date(
    this.key,
    this.label, {
    this.conditionKey,
    this.conditionValue,
  }) : type = ElectricalFieldType.date,
       options = null,
       maxValue = null,
       unit = null,
       children = null;
}

enum ElectricalFieldType {
  section,
  group,
  text,
  number,
  radio,
  dropdown,
  date,
  checkbox,
}

/// Common option sets for electrical inspections matching the document proforma
class _ElectricalOpt {
  static const odm = ['Okay / Serviceable (O)', 'Defective (D)', 'Missing (M)'];
  static const odmNa = [
    'Okay / Serviceable (O)',
    'Defective (D)',
    'Missing (M)',
    'Not Applicable (NA)',
  ];
  static const yesNo = ['Yes', 'No'];
  static const yN = ['Y', 'N'];
  static const satisfactoryUnsatisfactory = ['Satisfactory', 'Unsatisfactory'];
  static const fitNotFit = ['Fit', 'Not Fit'];
  static const compliantDue = ['Compliant', 'Due'];
}

/// Electrical inspection field specifications for different sub-departments and assets
class ElectricalFieldSpecs {
  /// Power - Room inspection fields
  static List<ElectricalFieldSpec> powerRoomFormSpec(
    List<String> roomAttributes, {
    String role = 'Officer / Inspector',
  }) {
    return [
      const ElectricalFieldSpec.dropdown('building', 'Select Building', [
        'Building 1',
        'Building 2',
        'Building 3',
      ]),
      const ElectricalFieldSpec.dropdown('room', 'Select Room', [
        'Room 1',
        'Room 2',
        'Room 3',
      ]),
      ElectricalFieldSpec.section(
        'Electrical (Power) Room Attributes ($role Scope)',
      ),
      ...roomAttributes
          .map(
            (attr) => [
              ElectricalFieldSpec.radio('${attr.toLowerCase()}_status', attr, [
                'Functional',
                'Not Functional',
              ]),
              ElectricalFieldSpec.number(
                '${attr.toLowerCase()}_count',
                'Count of Not Functional',
                conditionKey: '${attr.toLowerCase()}_status',
                conditionValue: 'Not Functional',
              ),
            ],
          )
          .expand((x) => x),
    ];
  }

  /// RTL - Workshop inspection fields (AC Coach as per Electrical RTL - Field Inspection.docx)
  static List<ElectricalFieldSpec> rtlWorkshopFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'Officer / Inspector',
  }) {
    final fields = <ElectricalFieldSpec>[
      ElectricalFieldSpec.section(
        'A. AC / STANDARD COACH - WORKSHOP INSPECTION ($role)',
      ),
      ElectricalFieldSpec.text(
        'coach_id_stage',
        'Coach identification & work stage (Coach no., class, cause, checking date, fit date/out date)',
      ),

      ElectricalFieldSpec.section('2. AC Unit – general'),
      ElectricalFieldSpec.radio(
        'ac_unit_general',
        'Canvas duct removed/provided; both AC units stripped/checked; washed/serviced at final stage',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('ac_gen_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('ac_gen_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('ac_gen_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('3. Compressor'),
      ElectricalFieldSpec.radio(
        'compressor_status',
        'Each compressor checked; defective compressor identified/replaced/repaired; final operation satisfactory',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('comp_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('comp_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('comp_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('4. Filter'),
      ElectricalFieldSpec.radio(
        'ac_filter',
        'AC filter condition and replacement where defective',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('5. Blower motors'),
      ElectricalFieldSpec.radio(
        'blower_motors_status',
        'Blower motors checked; defective motors removed/repaired/rewound and refitted',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('blower_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('blower_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('blower_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('6. Condenser motors'),
      ElectricalFieldSpec.radio(
        'condenser_motors_status',
        'Condenser motors checked; defective motors repaired/rewound and refitted',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('7. AC tub / leakage'),
      ElectricalFieldSpec.radio(
        'ac_tub_leakage',
        'AC tub checked for leakage and paint/finish condition',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('8. Air diffusers'),
      ElectricalFieldSpec.radio(
        'air_diffusers',
        'All air diffusers checked; removed for repair/overhauling and refitted',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('9. Underframe M/L sockets'),
      ElectricalFieldSpec.radio(
        'underframe_ml_sockets',
        'M/L sockets checked; repair/overhauling and secure refitting verified',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('10. Underframe duct / GI pipe'),
      ElectricalFieldSpec.radio(
        'underframe_duct_gi',
        'Underframe cable duct / GI pipe checked for condition and secure routing',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('11. Underframe junction boxes'),
      ElectricalFieldSpec.radio(
        'underframe_junction_boxes',
        'Junction box connections checked and secured',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('12. Underframe wiring'),
      ElectricalFieldSpec.radio(
        'wiring_120mm',
        '120 mm² cable condition, routing and termination',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wiring_50mm',
        '50 mm² cable condition, routing and termination',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wiring_95mm',
        '95 mm² cable condition, routing and termination',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'main_cable_7_029',
        'Main cable 7/029″ size/condition and termination',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'loop_wire',
        'Loop wire condition and connections checked',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'sure_supply_box',
        'Sure supply box checked and serviceable',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'battery_box_set',
        'Battery box and battery set condition/installation checked',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'train_line_ab_cables',
        'Both side train-line A/B cables and cable tray checked and secured',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'rotary_switch_100a',
        'Rotary switch 100 A checked; missing/defective unit replaced',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'complete_heater_assembly',
        'Heater assembly checked/installed where fitted',
        _ElectricalOpt.odmNa,
      ),

      ElectricalFieldSpec.section('22. Lighting – shades'),
      ElectricalFieldSpec.radio(
        'lighting_shades',
        '24″ shades checked, washed/cleaned and refitted; missing accounted for',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('shades_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('shades_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('shades_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('23. Lighting – tube rods'),
      ElectricalFieldSpec.radio(
        'lighting_tube_rods',
        '24″ tube rods checked, tested/cleaned and refitted',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('tubes_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('tubes_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('tubes_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('24. Lighting – C/B 06 A'),
      ElectricalFieldSpec.radio(
        'cb_06a',
        '6 A circuit breakers checked and serviceable',
        _ElectricalOpt.odm,
      ),

      ElectricalFieldSpec.section('29. USB ports'),
      ElectricalFieldSpec.radio(
        'usb_ports',
        'USB charging ports checked for presence and operation',
        _ElectricalOpt.odmNa,
      ),

      ElectricalFieldSpec.section('30. Fans'),
      ElectricalFieldSpec.radio(
        'fans_workshop',
        'All fans checked, repaired/painted where required and properly refitted',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.number('fans_ok', 'Quantity - OK'),
      ElectricalFieldSpec.number('fans_def', 'Quantity - Defective'),
      ElectricalFieldSpec.number('fans_mis', 'Quantity - Missing'),

      ElectricalFieldSpec.section('31. AC control panels'),
      ElectricalFieldSpec.radio(
        'ac_control_panels',
        'Both AC control panels physically checked; power and control circuits verified',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'overload_relays',
        'Overload relays (1.5–2.5 A, 4–6 A and 8–12 A as applicable)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'timers',
        'Timers checked for condition and operation',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'indication_lights',
        'Panel indication lights checked and serviceable',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'fc_10_fc_25',
        'FC-10 and FC-25 components checked where fitted',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'cb_40a',
        '40 A circuit breaker checked and serviceable',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'power_monitor',
        'Power monitor checked and serviceable where fitted',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'internal_wiring_connections',
        'Internal wiring of fans, lights and AC units checked; loose connections tightened',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'workshop_workmanship',
        'Quality of repair, rewinding, wiring, mounting, finishing and component refitting',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'post_repair_functional_test',
        'AC, lighting, fans and associated electrical equipment functionally tested before release',
        _ElectricalOpt.odmNa,
      ),

      ElectricalFieldSpec.section('A-1. AC COACH - RUNNING / TEST RECORD'),
      ElectricalFieldSpec.text(
        'heat_temp_test',
        'Heating – temperature test (Ambient / room temperature / time)',
      ),
      ElectricalFieldSpec.text(
        'cool_temp_test',
        'Cooling – temperature test (Ambient / room temperature / time)',
      ),
      ElectricalFieldSpec.number(
        'comp_1_amp',
        'Compressor – Unit 1 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'comp_2_amp',
        'Compressor – Unit 2 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'blower_1_amp',
        'Blower motor – Unit 1 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'blower_2_amp',
        'Blower motor – Unit 2 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'cond_1_amp',
        'Condenser motor – Unit 1 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'cond_2_amp',
        'Condenser motor – Unit 2 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'heater_1_amp',
        'Heater – Unit 1 Current (Amp)',
      ),
      ElectricalFieldSpec.number(
        'heater_2_amp',
        'Heater – Unit 2 Current (Amp)',
      ),
      ElectricalFieldSpec.text(
        'internal_megger',
        'Internal wiring Megger test (U-V, V-W, U-W, U-N, V-N, W-N in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'through_line_a',
        'Through wiring – Line A (Megger test in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'through_line_b',
        'Through wiring – Line B (Megger test in MΩ)',
      ),

      ElectricalFieldSpec.section('D. WORKSHOP RELEASE / FINAL VERIFICATION'),
      ElectricalFieldSpec.radio(
        'defects_recorded',
        'All identified defects / missing materials recorded',
        _ElectricalOpt.yesNo,
      ),
      ElectricalFieldSpec.radio(
        'rectification_verified',
        'Rectification / replacement of defective items verified',
        _ElectricalOpt.yesNo,
      ),
      ElectricalFieldSpec.radio(
        'tests_completed',
        'Required Megger / functional / load tests completed',
        _ElectricalOpt.yesNo,
      ),
      ElectricalFieldSpec.radio(
        'safety_verified',
        'Safety and protection devices verified',
        _ElectricalOpt.yesNo,
      ),
      ElectricalFieldSpec.radio(
        'coach_fit_release',
        'Coach / PV-TL van fit for release from electrical workshop',
        _ElectricalOpt.fitNotFit,
      ),
      ElectricalFieldSpec.text(
        'outstanding_work',
        'Outstanding work / material requirement details',
      ),
      ElectricalFieldSpec.text(
        'maintenance_incharge',
        'Maintenance In-charge / EFO / AEFO / AEE / RTL signature & date',
      ),
    ];

    return fields;
  }

  /// B. ECONOMY CLASS COACH - WORKSHOP INSPECTION
  static List<ElectricalFieldSpec> rtlEconomyWorkshopFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'Officer / Inspector',
  }) {
    return [
      ElectricalFieldSpec.section(
        'B. ECONOMY CLASS COACH - WORKSHOP INSPECTION ($role)',
      ),
      ElectricalFieldSpec.text(
        'eco_coach_id',
        'Coach identification, checking date, fit date & out date',
      ),
      ElectricalFieldSpec.radio(
        'eco_mech_sockets',
        'Mechanical lock sockets (Condition, quantity and secure connections)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_gi_pipe',
        'Underframe cable duct / GI pipe (Condition and routing)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_junction_box',
        'Underframe junction box connections (Terminations and security)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_underframe_wiring',
        'Underframe Wiring (Condition, routing and termination)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'eco_main_cable',
        'Main cable 7/029″ (Condition and termination)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'eco_loop_wire',
        'Loop wire (Condition and connection)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'eco_sure_supply',
        'Sure Supply Box (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_battery_box',
        'Battery box (Condition and installation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_battery_set',
        'Battery set (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_rotary_switch',
        'Rotary / selector switch (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_cb_30a',
        'C/B 30 A (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_cb_06a',
        'C/B 06 A (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_cb_16a',
        'C/B 16 A double pole (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_fuse_base_32a',
        'Fuse base 32 A (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_charging_module',
        'Charging module (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_rectifying_module',
        'Rectifying module (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_48v_supply',
        '48 V DC supply circuit (Supply circuit condition and connections)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_anti_skid',
        'Anti-skid device (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_hot_axle_monitor',
        'Hot axle monitor device (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_magnetic_contactors',
        'Magnetic contactors (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_ac_dc_volt_meter',
        'AC volt meter / DC volt meter (Condition and indication)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_ampere_meter',
        'Ampere meter (Condition and indication)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.section('Lighting & Fittings'),
      ElectricalFieldSpec.radio(
        'eco_led_24',
        'LED rod 220 V 24″ (Condition, quantity and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.number('eco_led_24_ok', 'LED 24" OK Qty'),
      ElectricalFieldSpec.number('eco_led_24_def', 'LED 24" Defective Qty'),
      ElectricalFieldSpec.number('eco_led_24_mis', 'LED 24" Missing Qty'),
      ElectricalFieldSpec.radio(
        'eco_led_18',
        'LED rod 220 V 18″ (Condition, quantity and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_ms_tube_fittings',
        'MS tube light fittings (Condition and mounting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_perplex_shade',
        'Perplex shade 24″ / 18″ (Condition and secure mounting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_fan_220v',
        'Fan 220 V (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_exhaust_fan',
        'Exhaust fan (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_switches_plates',
        'Switches / plates (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_side_lamp',
        'Side lamp (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_usb_ports',
        'USB ports / charging points (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_tail_light',
        'Tail light (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_lamp_holders',
        'Lamp holders / tube light holders (Condition and secure mounting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_step_lights',
        'Step lights (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_door_switches',
        'Door switches (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_toilet_indication',
        'Toilet indication lights (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_broadcasting_socket',
        'Broad casting sockets + LED (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_hot_axle_sensors',
        'Hot axle sensors (Condition and connection)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_earth_leads',
        'Earth leads (Continuity, condition and secure connection)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_speakers',
        'Speakers with covers (Condition and mounting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'eco_volume_control',
        'Volume control switch + knob (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.section(
        'B-1. ECONOMY COACH - INTERNAL & EXTERNAL MEGGER TEST',
      ),
      ElectricalFieldSpec.text(
        'eco_ext_megger_a',
        'External Megger – Line A (U-V, U-W, V-W, U-N, V-N, W-N in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'eco_ext_megger_b',
        'External Megger – Line B (U-V, U-W, V-W, U-N, V-N, W-N in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'eco_int_megger',
        'Internal Megger (Phase-to-body, phase-to-neutral, phase-to-phase in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'eco_test_record',
        'Test record (Coach no., checking date, fit date and out date recorded)',
      ),
    ];
  }

  /// C. POWER VAN / TL VAN - WORKSHOP INSPECTION
  static List<ElectricalFieldSpec> rtlPowerVanWorkshopFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'Officer / Inspector',
  }) {
    return [
      ElectricalFieldSpec.section(
        'C. POWER VAN / TL VAN - WORKSHOP INSPECTION ($role)',
      ),
      ElectricalFieldSpec.text(
        'pv_id',
        'PV/TL van no., make, capacity; DG Set-1, DG Set-2 and DG Set-3/small set',
      ),
      ElectricalFieldSpec.radio(
        'pv_dg_status',
        'Inspection of DG sets working hours and schedule',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_kitchen_fridge',
        'Kitchen – fridge (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_kitchen_exhaust',
        'Kitchen – exhaust fan (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_kitchen_cb',
        'Kitchen – circuit breaker (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_panel_630a',
        'Panel – 630 A circuit breaker (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_panel_fuses',
        'Panel – fuses / miniature relays (Condition and serviceability)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_panel_ol_relays',
        'Panel – O/L relays / automation (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_panel_indication',
        'Panel – indication lights (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_engine_control',
        'Engine control module (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_panel_fire_alarm',
        'Panel – AC / fire alarm box checked',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_manual_start_key',
        'Manual start key / static battery charger (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_fire_bottle',
        'Fire bottle / gauges / water level indication (Availability and condition)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_fuel_gauge',
        'Fuel tank digital gauge PMO-I (Condition and indication)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_engine_head',
        'Engine – head / block (Condition and visible defects)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_engine_mounting',
        'Engine – mounting pad / foundation bolts (Tightness and secure mounting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_fuel_system',
        'Fuel system (Fuel filter, filter assembly and supply valve)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_engine_components',
        'Engine components (Tapped cover, dynamo charger, lube-oil stick/filter)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_radiator_room',
        'Radiator room (Radiator water/air, pipes, blower motor and valve)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_guard_room',
        'Guard room (Fan 220V, light 220V, guard room panel and broadcasting)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_battery_boxes',
        'Battery boxes (24 V cells and 48 V cells checked)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_tail_side_lamps',
        'Tail / side lamps (Condition and operation)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_fuel_tank_cap',
        'Fuel tank / cap (Main fuel tank and fuel tank cap checked)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'pv_main_trainline',
        'Main train-line cables A+B (Condition, insulation and secure connection)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.section(
        'C-1. POWER VAN - RESISTIVE LOAD, TRAIN-LINE & SAFETY TESTS',
      ),
      ElectricalFieldSpec.text(
        'pv_load_test_1',
        'DG Set No. 1 – resistive load test (Time, amp, volt, frequency, oil pressure, temp, RPM)',
      ),
      ElectricalFieldSpec.text(
        'pv_load_test_2',
        'DG Set No. 2 – resistive load test (Time, amp, volt, frequency, oil pressure, temp, RPM)',
      ),
      ElectricalFieldSpec.text(
        'pv_trainline_ins_a',
        'Train-line insulation – Line A (UV, UW, VW, UN, VN, WN in MΩ)',
      ),
      ElectricalFieldSpec.text(
        'pv_trainline_ins_b',
        'Train-line insulation – Line B (UV, UW, VW, UN, VN, WN in MΩ)',
      ),
      ElectricalFieldSpec.radio(
        'pv_prot_water_temp',
        'High water temperature protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_prot_lube_oil',
        'Low lube-oil pressure protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_prot_over_current',
        'Over-current protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_prot_over_speed',
        'Over-speed protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_prot_over_voltage',
        'Over-voltage protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_safety_breakers',
        'Safety breakers functional condition checked',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_earthing_system',
        'Earthing system continuity and condition checked',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_ground_fault',
        'Ground fault protection functional test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'pv_high_winding',
        'High winding / bearing temperature protection test',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
    ];
  }

  /// Supervisory & Verification Inspection Proforma (DEE / AEE)
  static List<ElectricalFieldSpec> rtlSupervisoryFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'DEE / AEE',
  }) {
    return [
      ElectricalFieldSpec.section(
        'DEE / AEE - Supervisory & Verification Inspection Proforma ($role)',
      ),
      ElectricalFieldSpec.radio(
        'sup_coverage',
        'EFO/AEFO inspection coverage (whether required units/coaches/PV-TL vans were inspected)',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_defects',
        'Outstanding defects (Defects, Duration and Remedial Measures)',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_lighting_fans',
        'Coach lighting/fans/sockets (Remedial check against EFO record)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'sup_ac_units',
        'AC units (Check compressors, motors, panels, safeties, diffuser, heating)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'sup_couplers',
        'Inter-car couplers / train lines condition and safe connection',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'sup_workmanship',
        'Workmanship quality check',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_drs_card',
        'DRS card availability and maintenance',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'sup_records',
        'Inspection records availability and maintenance',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'sup_manpower',
        'Manpower deployment adequacy and allocation',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_spares',
        'Material / spare availability (identify recurring shortages)',
        ['Available', 'Not Available'],
      ),
      ElectricalFieldSpec.radio(
        'sup_preventive_maint',
        'Preventive maintenance adherence to prescribed schedules',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_washingline_release',
        'Washingline release condition maintained / not maintained',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'sup_panel_safety',
        'Panel safety devices intact',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section(
        'Power Van / TL Van Supervisory Verification',
      ),
      ElectricalFieldSpec.radio(
        'sup_schedule_compliance',
        'A/B & C Schedule compliance (verify schedules and overdue cases)',
        _ElectricalOpt.compliantDue,
      ),
      ElectricalFieldSpec.radio(
        'sup_dg_readings',
        'DG set readings (current, voltage, frequency, oil pressure)',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_electrical_protection',
        'Electrical protection (sample-check breakers, panel safety)',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'sup_fuel_control',
        'Fuel control (verify PV-95/fuel records and abnormal consumption)',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
    ];
  }

  /// RTL - Washing Line inspection fields as per Electrical RTL - Field Inspection.docx
  static List<ElectricalFieldSpec> rtlWashingLineFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'Officer / Inspector',
  }) {
    return [
      ElectricalFieldSpec.section(
        'Washing Line - Complete Rake / Train Inspection ($role)',
      ),
      ElectricalFieldSpec.text(
        'train_formation',
        'Train / coach identification and formation (train, coach no., class)',
      ),
      ElectricalFieldSpec.section('1. Tube lights / light fittings'),
      ElectricalFieldSpec.number('wl_lights_total', 'Total Lights'),
      ElectricalFieldSpec.number('wl_lights_working', 'Working Lights'),
      ElectricalFieldSpec.number('wl_lights_defective', 'Defective Lights'),
      ElectricalFieldSpec.number('wl_lights_missing', 'Missing Lights'),
      ElectricalFieldSpec.section('2. Tube-light shades'),
      ElectricalFieldSpec.radio(
        'wl_shades_status',
        'Condition, completeness and secure mounting',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('3. Fans'),
      ElectricalFieldSpec.number('wl_fans_working', 'Working Fans'),
      ElectricalFieldSpec.number('wl_fans_defective', 'Defective Fans'),
      ElectricalFieldSpec.number('wl_fans_missing', 'Missing Fans'),
      ElectricalFieldSpec.section('4. Mobile charging sockets'),
      ElectricalFieldSpec.number('wl_mcu_working', 'Working Sockets'),
      ElectricalFieldSpec.number('wl_mcu_defective', 'Defective Sockets'),
      ElectricalFieldSpec.number('wl_mcu_missing', 'Missing Sockets'),
      ElectricalFieldSpec.section('5. Train-line electrical supply'),
      ElectricalFieldSpec.radio(
        'wl_train_line_a',
        'Line-A condition and continuity',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wl_train_line_b',
        'Line-B condition and continuity',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('6. Inter-car coupler'),
      ElectricalFieldSpec.radio(
        'wl_intercar_coupler',
        'Physical condition and secure connection',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('7. AC Units & Heating'),
      ElectricalFieldSpec.radio(
        'wl_ac_1',
        'AC Unit-I status (compressor, blowers, condenser, panel)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_ac_2',
        'AC Unit-II status',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_heating',
        'AC heating arrangement function in winter',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_air_diffuser',
        'Air diffuser and temperature indication/condition',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.section('8. Escort, DRS & Destination Board'),
      ElectricalFieldSpec.radio(
        'wl_escort',
        'Electrical escort available / not available',
        [
          'Available with Uniform',
          'Available without Uniform',
          'Not Available',
        ],
      ),
      ElectricalFieldSpec.radio(
        'wl_drs_card',
        'DRS card available and maintained',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'wl_destination_board',
        'Destination board (Manual/electrical; working/not working)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('9. Coach Special Fittings & General'),
      ElectricalFieldSpec.radio(
        'wl_toilet_lights',
        'Toilet indication lights',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_berth_lights',
        'Berth lights',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_dining',
        'Dining car electrical equipment (if dining car)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_call_bell',
        'Sleeper coach call bell (if sleeper)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_sliding_door',
        'Parlor car electrical sliding doors',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'wl_door_closer',
        'Mechanical door closer condition',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wl_cleanliness',
        'Overall cleanliness / housekeeping',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wl_work_dispatch',
        'Train lighting work before dispatch (rectified before release)',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'wl_intercar_connections',
        'Inter-car electrical connections correctly connected & secured',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'wl_wiring_test',
        'Wiring Megger Test, Continuity Test, No loose wire',
        _ElectricalOpt.satisfactoryUnsatisfactory,
      ),
      ElectricalFieldSpec.radio(
        'wl_panel_safety',
        'Panel safety devices intact',
        _ElectricalOpt.odm,
      ),
    ];
  }

  /// RTL - Station inspection fields as per Electrical RTL - Field Inspection.docx
  static List<ElectricalFieldSpec> rtlStationFormSpec(
    Map<String, dynamic> coachAsset, {
    String role = 'Officer / Inspector',
  }) {
    return [
      ElectricalFieldSpec.section('Station - Detailed Inspection ($role)'),
      ElectricalFieldSpec.text(
        'st_coach_no',
        'Coach No. / Train Identification',
      ),
      ElectricalFieldSpec.section('1. Tube lights / light fittings'),
      ElectricalFieldSpec.number('st_lights_total', 'Total Lights'),
      ElectricalFieldSpec.number('st_lights_working', 'Working Lights'),
      ElectricalFieldSpec.number('st_lights_defective', 'Defective Lights'),
      ElectricalFieldSpec.number('st_lights_missing', 'Missing Lights'),
      ElectricalFieldSpec.section('2. Tube-light shades'),
      ElectricalFieldSpec.radio(
        'st_shades_status',
        'Condition, completeness and secure mounting',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('3. Fans'),
      ElectricalFieldSpec.number('st_fans_working', 'Working Fans'),
      ElectricalFieldSpec.number('st_fans_defective', 'Defective Fans'),
      ElectricalFieldSpec.number('st_fans_missing', 'Missing Fans'),
      ElectricalFieldSpec.section('4. Mobile charging sockets'),
      ElectricalFieldSpec.number('st_mcu_working', 'Working Sockets'),
      ElectricalFieldSpec.number('st_mcu_defective', 'Defective Sockets'),
      ElectricalFieldSpec.number('st_mcu_missing', 'Missing Sockets'),
      ElectricalFieldSpec.section('5. Train-line electrical supply'),
      ElectricalFieldSpec.radio(
        'st_train_line_a',
        'Line-A condition and continuity',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'st_train_line_b',
        'Line-B condition and continuity',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('6. Inter-car coupler'),
      ElectricalFieldSpec.radio(
        'st_intercar_coupler',
        'Physical condition and secure connection',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('7. AC Units & Heating'),
      ElectricalFieldSpec.radio(
        'st_ac_1',
        'AC Unit-I status',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_ac_2',
        'AC Unit-II status',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_heating',
        'AC heating arrangement function',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_air_diffuser',
        'Air diffuser and temperature indication',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.section('8. Escort, DRS & Destination Board'),
      ElectricalFieldSpec.radio(
        'st_escort',
        'Electrical escort available / not available',
        [
          'Available with Uniform',
          'Available without Uniform',
          'Not Available',
        ],
      ),
      ElectricalFieldSpec.radio(
        'st_drs_card',
        'DRS card available and maintained',
        _ElectricalOpt.yN,
      ),
      ElectricalFieldSpec.radio(
        'st_destination_board',
        'Destination board (Manual/electrical; working/not working)',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.section('9. Coach Special Fittings & General'),
      ElectricalFieldSpec.radio(
        'st_toilet_lights',
        'Toilet indication lights',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_berth_lights',
        'Berth lights',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_dining',
        'Dining car electrical equipment (if dining car)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_call_bell',
        'Sleeper coach call bell (if sleeper)',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_sliding_door',
        'Parlor car electrical sliding doors',
        _ElectricalOpt.odmNa,
      ),
      ElectricalFieldSpec.radio(
        'st_door_closer',
        'Mechanical door closer condition',
        _ElectricalOpt.odm,
      ),
      ElectricalFieldSpec.radio(
        'st_cleanliness',
        'Overall cleanliness / housekeeping',
        _ElectricalOpt.odm,
      ),
    ];
  }
}
