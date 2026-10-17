import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';

/// How a form's answer goes to the server.
enum _As {
  /// A choice, in the server's capitals: "Not available" as
  /// "NOT AVAILABLE".
  choice,

  /// As typed or picked.
  text,
  date,
  number,
  count,
}

/// The server's name for each of the form's questions, and how it is sent.
const Map<String, (String, _As)> _fields = {
  'smName': ('sm_name', _As.text),
  'uniform': ('sm_uniform', _As.choice),
  'conversant': ('sm_conversant', _As.choice),
  'slideOverhaulDate': ('sm_slide_frame_overhaul_date', _As.date),
  'slideTestDate': ('sm_slide_frame_testing_date', _As.date),
  'slideLockingTest': ('sm_slide_frame_locking_test', _As.choice),
  'iyd': ('sm_iyd', _As.choice),
  'workingRule': ('sm_working_rules', _As.choice),
  'ruleOfMonth': ('sm_rule_of_month', _As.choice),
  'specialBulletin': ('sm_special_bulletin', _As.choice),
  'fireExtCount': ('fire_extinguishers_count', _As.count),
  'lockingSealing': ('panel_locking_sealing', _As.choice),
  'signalIndications': ('panel_signal_indications', _As.choice),
  'trackIndications': ('panel_track_indications', _As.choice),
  'pointIndications': ('panel_point_indications', _As.choice),
  'powerIndications': ('panel_power_indications', _As.choice),
  'blockType': ('block_instrument_type', _As.text),
  'blockSealing': ('block_instrument_sealing_locking', _As.choice),
  'blockOverhaulDate': ('block_instrument_overhaul_date', _As.date),
  'blockTestDate': ('block_instrument_testing_date', _As.date),
  'blockTestResult': ('block_instrument_testing_result', _As.choice),
  'speechQuality': ('magneto_speech_quality', _As.choice),
  'batteryCondition': ('magneto_3v_battery_condition', _As.count),
  'upRoute': ('route_up_train', _As.choice),
  'downRoute': ('route_down_train', _As.choice),
  'sigMaintained': ('signal_maintenance_schedule', _As.choice),
  'telecomMaintained': ('telecom_maintenance_schedule', _As.choice),
  'paint1': ('painting_program_1_year_date', _As.date),
  'paint2': ('painting_program_3_year_date', _As.date),
  'paint3': ('painting_program_5_year_date', _As.date),
  'mainBattery': ('main_battery_voltage', _As.number),
  'addBattery': ('additional_battery_voltage', _As.number),
  'trackBattery': ('track_battery_voltage', _As.number),
  'cabinA_overhaulDate': ('lever_east_north_overhaul_date', _As.date),
  'cabinA_interlocking': ('lever_east_north_interlocking', _As.choice),
  'cabinA_testDate': ('lever_east_north_locking_test_date', _As.date),
  'cabinA_sealing': ('lever_east_north_sealing_intact', _As.choice),
  'cabinB_overhaulDate': ('lever_west_south_overhaul_date', _As.date),
  'cabinB_interlocking': ('lever_west_south_interlocking', _As.choice),
  'cabinB_testDate': ('lever_west_south_locking_test_date', _As.date),
  'cabinB_sealing': ('lever_west_south_sealing_intact', _As.choice),
  'logLastDate': ('equipment_room_log_book_date', _As.date),
  'logPurpose': ('equipment_room_log_book_purpose', _As.text),
  'logAsm': ('equipment_room_log_book_asm_name', _As.text),
  'ups': ('relay_room_ups', _As.choice),
  'staticInvertor': ('relay_room_static_invertor', _As.choice),
  'avr': ('relay_room_avr', _As.choice),
  'roomAc': ('relay_room_ac', _As.choice),
  'roomLights': ('relay_room_lights', _As.choice),
  'roomFans': ('relay_room_fans', _As.choice),
  'chargerFunctional': ('battery_charger_functional', _As.choice),
  'chargerOutputV': ('charger_output_voltage', _As.number),
  'brLights': ('battery_room_lights', _As.choice),
  'brFans': ('battery_room_fans', _As.choice),
  'vhfWorking': ('vhf_working', _As.choice),
  'vhfCondition': ('vhf_overall_condition', _As.choice),
  'vhfPowerSupplyV': ('vhf_power_supply_volt', _As.number),
  'vhfBatteryV': ('vhf_battery_voltage', _As.number),
  'vhfAntenna': ('vhf_antenna', _As.choice),
  'pcpCondition': ('pcp_overall_condition', _As.choice),
  'pcpOutputV': ('pcp_output_volt', _As.number),
  'uhfBrand': ('uhf_battery_capacity_brand', _As.text),
  'uhfSignal': ('uhf_signal_strength', _As.text),
  'uhfBatteryV': ('uhf_battery_voltage', _As.number),
  'uhfStatus': ('uhf_mw_battery', _As.choice),
  'telecomAc': ('telecom_ac_working', _As.choice),
  'telecomLights': ('telecom_room_lights', _As.choice),
  'telecomFans': ('telecom_room_fans', _As.choice),
  'dgSwitchStart': ('dg_switch_start', _As.choice),
  'dgCrankStart': ('dg_crank_handle_start', _As.choice),
  'dgStatus': ('dg_status', _As.choice),
  'dgLogbook': ('dg_log_book_maintained', _As.choice),
  'towerType': ('tower_type', _As.choice),
  'towerPaint': ('tower_paint_condition', _As.choice),
  'towerHeight': ('tower_height', _As.number),
  'towerLight': ('tower_light', _As.choice),
  'towerEarth': ('tower_earth_connectivity', _As.choice),
  'towerFencing': ('tower_fencing', _As.choice),
  'towerFoundation': ('tower_foundation_condition', _As.choice),
  'paSystem': ('pa_system', _As.choice),
};

/// Each repeated entry's columns, by the server's names.
const Map<String, Map<String, String>> _rowFields = {
  'points': {
    'pointNo': 'point_number',
    'gaugeTest': 'point_setting_test',
    'gaugeValue': 'point_gauge_test_value',
    'trackGauge': 'track_gauge_ok',
    'trackGaugeRemark': 'track_gauge_remark',
    'packing': 'packing_of_sleepers',
    'throwOk': 'throw_of_point_ok',
    'throwRemark': 'throw_of_point_remark',
    'switchCondition': 'switch_tongue_rail_condition',
    'fitting': 'fitting_fastening',
  },
  'lx': {
    'lxNo': 'crossing_no',
    'communication': 'communication',
    'warningBell': 'warning_bell',
    'operation': 'operation',
    'complaintBook': 'complaint_book',
    'batteryVolts': 'battery_voltage',
    'batteryStatus': 'battery_status',
  },
  'tc': {
    'circuitNo': 'circuit_id',
    'feedVolt': 'feed_end_volt',
    'relayVolt': 'volt_at_relay',
    'irj': 'condition_irj',
    'jumper': 'condition_jumper',
    'bondWire': 'condition_bond_wire',
    'trackPod': 'condition_track_pod',
  },
  'failures': {
    'quarter': 'quarter',
    'engg': 'engg',
    'elect': 'elec',
    'tcom': 't_com',
    'tfc': 'tfc',
    'sig': 'sig',
    'oc': 'o_c',
    'store': 'store',
  },
};

/// The server's names for a signal's checks.
const Map<String, String> _signalParts = {
  'foundation': 'foundation_condition',
  'pole': 'pole_condition',
  'visibility': 'visibility',
  'focus': 'focus',
  'lens': 'signal_lens',
};

/// A station inspection as the server takes it: the answers given, under
/// the server's names, and nothing made up. A question left blank is left
/// out, for the server to take or refuse.
abstract final class StationInspectionPayload {
  static Map<String, dynamic> build(
    StationInspectionController form, {
    required int? stationId,
    LoginResponse? user,
  }) {
    final payload = <String, dynamic>{
      'division': ?user?.user?.division,
      'section': ?user?.user?.section,
      'station': ?stationId,
      'current_step': kInspectionSections.length,
    };
    for (final MapEntry(key: id, value: (name, kind)) in _fields.entries) {
      final value = _value(form.fields[id], kind);
      if (value != null) payload[name] = value;
    }
    final remarks = _remarks(form);
    if (remarks.isNotEmpty) payload['overall_remarks'] = remarks;

    final block = _rowOf(form, {
      'blockType': 'instrument_type',
      'blockSealing': 'locking_sealing',
      'blockOverhaulDate': 'overhauling_date',
      'blockTestDate': 'testing_date',
      'blockTestResult': 'testing_result',
    });
    if (block.isNotEmpty) {
      payload['block_instruments'] = [
        {...block, 'is_enabled': true},
      ];
    }
    payload['battery_banks'] = [
      for (final (bank, id) in const [
        ('Main', 'mainBattery'),
        ('Additional', 'addBattery'),
        ('Track', 'trackBattery'),
      ])
        if (_number(form.fields[id]) case final voltage?)
          {
            'bank_type': bank,
            if (bank == 'Main')
              'charger_voltage': ?_number(form.fields['chargerOutputV']),
            'batteries': [
              {'battery_number': 1, 'voltage': voltage},
            ],
          },
    ];
    payload['signals'] = [
      for (final (i, name) in kSignalNames.indexed)
        if (_rowOf(form, {
              for (final part in _signalParts.entries)
                'sig_${i}_${part.key}': part.value,
            })
            case final checks when checks.isNotEmpty)
          {'signal_id': name, ...checks},
    ];
    final year = form.inspDate.year;
    for (final (type, name) in const [
      ('points', 'points'),
      ('lx', 'level_crossings'),
      ('tc', 'track_circuits'),
      ('failures', 'signal_failure_records'),
    ]) {
      final columns = _rowFields[type]!;
      payload[name] = [
        for (final row in form.rowsFor(type))
          if (_rowOf(form, {
                for (final column in columns.entries)
                  '${form.rowPrefix(type, row)}_${column.key}': column.value,
              })
              case final entry when entry.isNotEmpty)
            {
              ...entry,
              if (type == 'failures') 'year': _yearIn(entry['quarter']) ?? year,
            },
      ];
    }
    return payload;
  }

  /// The answers of one entry, by the server's names; empty if none.
  static Map<String, dynamic> _rowOf(
    StationInspectionController form,
    Map<String, String> names,
  ) => {
    for (final MapEntry(key: id, value: name) in names.entries)
      name: ?_value(form.fields[id], _kindOf(form.fields[id])),
  };

  static _As _kindOf(Object? value) => switch (value) {
    DateTime() => _As.date,
    num() => _As.number,
    _ => _As.text,
  };

  static Object? _value(Object? value, _As as) {
    if (value == null) return null;
    return switch (as) {
      _As.date => switch (value) {
        DateTime() => _date(value),
        _ => switch (DateTime.tryParse(value.toString())) {
          final day? => _date(day),
          null => null,
        },
      },
      _As.number => _number(value),
      _As.count => switch (value) {
        num() => value.toInt(),
        _ => int.tryParse(value.toString().trim()),
      },
      _As.choice => _text(value)?.toUpperCase(),
      _As.text => _text(value),
    };
  }

  static String? _text(Object value) {
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _number(Object? value) => switch (value) {
    null => null,
    num() => value.toDouble(),
    _ => double.tryParse(value.toString().trim()),
  };

  static String _date(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static int? _yearIn(Object? quarter) {
    final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch('${quarter ?? ''}');
    return match == null ? null : int.parse(match.group(0)!);
  }

  /// The overall remarks, with the notes written for every fault found, as
  /// the server has no place of its own for them.
  static String _remarks(StationInspectionController form) {
    final overall = form.fields['remarks']?.toString().trim() ?? '';
    final notes = <String>[];
    for (final section in kInspectionSections) {
      for (final item in section.items) {
        if (item is! FieldFormItem) continue;
        final spec = item.spec;
        if (spec.kind != FieldKind.toggleRemark) continue;
        final note = form.fields[spec.remarkId]?.toString().trim() ?? '';
        if (note.isNotEmpty) notes.add('${spec.label}: $note');
      }
    }
    for (final (i, name) in kSignalNames.indexed) {
      for (final part in kSignalParts) {
        final note =
            form.fields['sig_${i}_${part[0]}_remark']?.toString().trim() ?? '';
        if (note.isNotEmpty) notes.add('$name, ${part[1]}: $note');
      }
    }
    for (final MapEntry(key: type, value: def) in kRepeatDefs.entries) {
      for (final (n, row) in form.rowsFor(type).indexed) {
        for (final column in def.cols) {
          final spec = column.build(
            '${form.rowPrefix(type, row)}_${column.key}',
          );
          if (spec.kind != FieldKind.toggleRemark) continue;
          final note = form.fields[spec.remarkId]?.toString().trim() ?? '';
          if (note.isNotEmpty) {
            notes.add('${def.label} ${n + 1}, ${spec.label}: $note');
          }
        }
      }
    }
    return [
      if (overall.isNotEmpty) overall,
      if (notes.isNotEmpty) 'Findings:\n${notes.map((n) => '- $n').join('\n')}',
    ].join('\n\n');
  }
}
