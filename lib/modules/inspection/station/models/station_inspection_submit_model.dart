import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';

class StationInspectionSubmitModel {
  final int division;
  final int section;
  final int station;
  final int currentStep;
  final String smName;
  final String smUniform;
  final String smConversant;
  final String smSlideFrameOverhaulDate;
  final String smSlideFrameTestingDate;
  final String smSlideFrameLockingTest;
  final String smIyd;
  final String smWorkingRules;
  final String smRuleOfMonth;
  final String smSpecialBulletin;
  final int fireExtinguishersCount;
  final String lastOverhaulingDate;
  final String lastTestingDate;
  final String panelLockingSealing;
  final String panelSignalIndications;
  final String panelTrackIndications;
  final String panelPointIndications;
  final String panelPowerIndications;
  final String ebiSignalIndications;
  final String ebiTrackIndications;
  final String ebiPointIndications;
  final String ebiPowerIndications;
  final String magnetoTelephoneCondition;
  final String magnetoSpeechQuality;
  final int magneto3vBatteryCondition;
  final String blockInstrumentType;
  final String blockInstrumentSealingLocking;
  final String blockInstrumentOverhaulDate;
  final String blockInstrumentTestingDate;
  final String blockInstrumentTestingResult;
  final String routeUpTrain;
  final String routeDownTrain;
  final String signalMaintenanceSchedule;
  final String telecomMaintenanceSchedule;
  final String paintingProgram1YearDate;
  final String paintingProgram3YearDate;
  final String paintingProgram5YearDate;
  final double mainBatteryVoltage;
  final double additionalBatteryVoltage;
  final double trackBatteryVoltage;
  final String leverEastNorthOverhaulDate;
  final String leverEastNorthInterlocking;
  final String leverEastNorthLockingTestDate;
  final String leverEastNorthSealingIntact;
  final String leverWestSouthOverhaulDate;
  final String leverWestSouthInterlocking;
  final String leverWestSouthLockingTestDate;
  final String leverWestSouthSealingIntact;
  final String equipmentRoomLogBookDate;
  final String equipmentRoomLogBookPurpose;
  final String equipmentRoomLogBookAsmName;
  final String relayRoomLockingSealing;
  final String relayRoomLighting;
  final String relayRoomUps;
  final String relayRoomStaticInvertor;
  final String relayRoomAvr;
  final String relayRoomAc;
  final String relayRoomLights;
  final String relayRoomFans;
  final String batteryChargerFunctional;
  final double chargerOutputVoltage;
  final String batteryRoomLights;
  final String batteryRoomFans;
  final String vhfWorking;
  final String vhfOverallCondition;
  final double vhfPowerSupplyVolt;
  final double vhfBatteryVoltage;
  final String vhfAntenna;
  final double commPowerSupplyVolt;
  final String zongGsm;
  final String pcpOverallCondition;
  final double pcpInputVolt;
  final double pcpOutputVolt;
  final String uhfBatteryCapacityBrand;
  final String uhfSignalStrength;
  final double uhfBatteryVoltage;
  final String uhfMwBattery;
  final String telecomAcWorking;
  final String telecomRoomLights;
  final String telecomRoomFans;
  final String signalDgLogBook;
  final String signalDgOverhaulingDate;
  final String telecomDgLogBook;
  final String telecomDgOverhaulingDate;
  final String dgSwitchStart;
  final String dgCrankHandleStart;
  final String dgStatus;
  final String dgLogBookMaintained;
  final String towerType;
  final String towerPaintCondition;
  final double towerHeight;
  final String towerLight;
  final String towerEarthConnectivity;
  final String towerFencing;
  final String towerFoundationCondition;
  final String earthTestDate;
  final String paSystem;
  final String overallRemarks;

  final List<Map<String, dynamic>> blockInstruments;
  final List<Map<String, dynamic>> batteryBanks;
  final List<Map<String, dynamic>> points;
  final List<Map<String, dynamic>> signals;
  final List<Map<String, dynamic>> trackCircuits;
  final List<Map<String, dynamic>> levelCrossings;
  final List<Map<String, dynamic>> signalFailureRecords;

  StationInspectionSubmitModel({
    required this.division,
    required this.section,
    required this.station,
    required this.currentStep,
    required this.smName,
    required this.smUniform,
    required this.smConversant,
    required this.smSlideFrameOverhaulDate,
    required this.smSlideFrameTestingDate,
    required this.smSlideFrameLockingTest,
    required this.smIyd,
    required this.smWorkingRules,
    required this.smRuleOfMonth,
    required this.smSpecialBulletin,
    required this.fireExtinguishersCount,
    required this.lastOverhaulingDate,
    required this.lastTestingDate,
    required this.panelLockingSealing,
    required this.panelSignalIndications,
    required this.panelTrackIndications,
    required this.panelPointIndications,
    required this.panelPowerIndications,
    required this.ebiSignalIndications,
    required this.ebiTrackIndications,
    required this.ebiPointIndications,
    required this.ebiPowerIndications,
    required this.magnetoTelephoneCondition,
    required this.magnetoSpeechQuality,
    required this.magneto3vBatteryCondition,
    required this.blockInstrumentType,
    required this.blockInstrumentSealingLocking,
    required this.blockInstrumentOverhaulDate,
    required this.blockInstrumentTestingDate,
    required this.blockInstrumentTestingResult,
    required this.routeUpTrain,
    required this.routeDownTrain,
    required this.signalMaintenanceSchedule,
    required this.telecomMaintenanceSchedule,
    required this.paintingProgram1YearDate,
    required this.paintingProgram3YearDate,
    required this.paintingProgram5YearDate,
    required this.mainBatteryVoltage,
    required this.additionalBatteryVoltage,
    required this.trackBatteryVoltage,
    required this.leverEastNorthOverhaulDate,
    required this.leverEastNorthInterlocking,
    required this.leverEastNorthLockingTestDate,
    required this.leverEastNorthSealingIntact,
    required this.leverWestSouthOverhaulDate,
    required this.leverWestSouthInterlocking,
    required this.leverWestSouthLockingTestDate,
    required this.leverWestSouthSealingIntact,
    required this.equipmentRoomLogBookDate,
    required this.equipmentRoomLogBookPurpose,
    required this.equipmentRoomLogBookAsmName,
    required this.relayRoomLockingSealing,
    required this.relayRoomLighting,
    required this.relayRoomUps,
    required this.relayRoomStaticInvertor,
    required this.relayRoomAvr,
    required this.relayRoomAc,
    required this.relayRoomLights,
    required this.relayRoomFans,
    required this.batteryChargerFunctional,
    required this.chargerOutputVoltage,
    required this.batteryRoomLights,
    required this.batteryRoomFans,
    required this.vhfWorking,
    required this.vhfOverallCondition,
    required this.vhfPowerSupplyVolt,
    required this.vhfBatteryVoltage,
    required this.vhfAntenna,
    required this.commPowerSupplyVolt,
    required this.zongGsm,
    required this.pcpOverallCondition,
    required this.pcpInputVolt,
    required this.pcpOutputVolt,
    required this.uhfBatteryCapacityBrand,
    required this.uhfSignalStrength,
    required this.uhfBatteryVoltage,
    required this.uhfMwBattery,
    required this.telecomAcWorking,
    required this.telecomRoomLights,
    required this.telecomRoomFans,
    required this.signalDgLogBook,
    required this.signalDgOverhaulingDate,
    required this.telecomDgLogBook,
    required this.telecomDgOverhaulingDate,
    required this.dgSwitchStart,
    required this.dgCrankHandleStart,
    required this.dgStatus,
    required this.dgLogBookMaintained,
    required this.towerType,
    required this.towerPaintCondition,
    required this.towerHeight,
    required this.towerLight,
    required this.towerEarthConnectivity,
    required this.towerFencing,
    required this.towerFoundationCondition,
    required this.earthTestDate,
    required this.paSystem,
    required this.overallRemarks,
    required this.blockInstruments,
    required this.batteryBanks,
    required this.points,
    required this.signals,
    required this.trackCircuits,
    required this.levelCrossings,
    required this.signalFailureRecords,
  });

  static String _fmtDate(dynamic v) {
    if (v is DateTime) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    if (v != null && v.toString().trim().isNotEmpty) {
      return v.toString().trim();
    }
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static double _toDbl(dynamic v, [double def = 0.0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  static int _toI(dynamic v, [int def = 0]) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  static String _toS(dynamic v, [String def = 'SATISFACTORY']) {
    if (v == null || v.toString().trim().isEmpty) return def;
    return v.toString().trim();
  }

  factory StationInspectionSubmitModel.fromController(
    StationInspectionController controller, {
    LoginResponse? user,
    int? stationId,
  }) {
    final get = controller.get;

    final userDiv = user?.user?.division ?? 31;
    final userSec = user?.user?.section ?? 00;
    final userStationId = stationId ?? 6438;

    return StationInspectionSubmitModel(
      division: userDiv,
      section: userSec,
      station: userStationId,
      currentStep: 18,
      smName: _toS(get('submittedName') ?? get('sm_name'), 'Haseeb'),
      smUniform: _toS(get('uniform') ?? get('sm_uniform'), 'YES'),
      smConversant: _toS(get('conversant') ?? get('sm_conversant'), 'YES'),
      smSlideFrameOverhaulDate: _fmtDate(
        get('overhaulingDateSM') ?? get('sm_slide_frame_overhaul_date'),
      ),
      smSlideFrameTestingDate: _fmtDate(
        get('testingDateSM') ?? get('sm_slide_frame_testing_date'),
      ),
      smSlideFrameLockingTest: _toS(
        get('sm_slide_frame_locking_test'),
        'SATISFACTORY',
      ),
      smIyd: _toS(get('iyd') ?? get('sm_iyd'), 'AVAILABLE'),
      smWorkingRules: _toS(
        get('workingRules') ?? get('sm_working_rules'),
        'AVAILABLE',
      ),
      smRuleOfMonth: _toS(get('sm_rule_of_month'), 'AVAILABLE'),
      smSpecialBulletin: _toS(get('sm_special_bulletin'), 'AVAILABLE'),
      fireExtinguishersCount: _toI(
        get('fireExtCount') ?? get('fire_extinguishers_count'),
        0,
      ),
      lastOverhaulingDate: _fmtDate(get('last_overhauling_date')),
      lastTestingDate: _fmtDate(get('last_testing_date')),
      panelLockingSealing: _toS(get('panel_locking_sealing'), 'YES'),
      panelSignalIndications: _toS(get('panel_signal_indications'), 'YES'),
      panelTrackIndications: _toS(get('panel_track_indications'), 'YES'),
      panelPointIndications: _toS(get('panel_point_indications'), 'YES'),
      panelPowerIndications: _toS(get('panel_power_indications'), 'YES'),
      ebiSignalIndications: _toS(get('ebi_signal_indications'), 'SATISFACTORY'),
      ebiTrackIndications: _toS(get('ebi_track_indications'), 'SATISFACTORY'),
      ebiPointIndications: _toS(get('ebi_point_indications'), 'SATISFACTORY'),
      ebiPowerIndications: _toS(get('ebi_power_indications'), 'SATISFACTORY'),
      magnetoTelephoneCondition: _toS(
        get('magnetoTelephone') ?? get('magneto_telephone_condition'),
        'SATISFACTORY',
      ),
      magnetoSpeechQuality: _toS(get('magneto_speech_quality'), 'GOOD'),
      magneto3vBatteryCondition: _toI(get('magneto_3v_battery_condition'), 2),
      blockInstrumentType: _toS(get('block_instrument_type'), "Neal's Token"),
      blockInstrumentSealingLocking: _toS(
        get('block_instrument_sealing_locking'),
        'YES',
      ),
      blockInstrumentOverhaulDate: _fmtDate(
        get('block_instrument_overhaul_date'),
      ),
      blockInstrumentTestingDate: _fmtDate(
        get('block_instrument_testing_date'),
      ),
      blockInstrumentTestingResult: _toS(
        get('block_instrument_testing_result'),
        'SATISFACTORY',
      ),
      routeUpTrain: _toS(get('route_up_train'), 'SATISFACTORY'),
      routeDownTrain: _toS(get('route_down_train'), 'SATISFACTORY'),
      signalMaintenanceSchedule: _toS(
        get('signal_maintenance_schedule'),
        'YES',
      ),
      telecomMaintenanceSchedule: _toS(
        get('telecom_maintenance_schedule'),
        'YES',
      ),
      paintingProgram1YearDate: _fmtDate(
        get('paintingDateI') ?? get('painting_program_1_year_date'),
      ),
      paintingProgram3YearDate: _fmtDate(
        get('paintingDateII') ?? get('painting_program_3_year_date'),
      ),
      paintingProgram5YearDate: _fmtDate(
        get('paintingDateIII') ?? get('painting_program_5_year_date'),
      ),
      mainBatteryVoltage: _toDbl(get('main_battery_voltage'), 55.0),
      additionalBatteryVoltage: _toDbl(get('additional_battery_voltage'), 55.0),
      trackBatteryVoltage: _toDbl(get('track_battery_voltage'), 14.0),
      leverEastNorthOverhaulDate: _fmtDate(
        get('lever_east_north_overhaul_date'),
      ),
      leverEastNorthInterlocking: _toS(
        get('lever_east_north_interlocking'),
        'SATISFACTORY',
      ),
      leverEastNorthLockingTestDate: _fmtDate(
        get('lever_east_north_locking_test_date'),
      ),
      leverEastNorthSealingIntact: _toS(
        get('lever_east_north_sealing_intact'),
        'YES',
      ),
      leverWestSouthOverhaulDate: _fmtDate(
        get('lever_west_south_overhaul_date'),
      ),
      leverWestSouthInterlocking: _toS(
        get('lever_west_south_interlocking'),
        'SATISFACTORY',
      ),
      leverWestSouthLockingTestDate: _fmtDate(
        get('lever_west_south_locking_test_date'),
      ),
      leverWestSouthSealingIntact: _toS(
        get('lever_west_south_sealing_intact'),
        'YES',
      ),
      equipmentRoomLogBookDate: _fmtDate(get('equipment_room_log_book_date')),
      equipmentRoomLogBookPurpose: _toS(
        get('equipment_room_log_book_purpose'),
        'test',
      ),
      equipmentRoomLogBookAsmName: _toS(
        get('equipment_room_log_book_asm_name'),
        'hasseeb',
      ),
      relayRoomLockingSealing: _toS(
        get('lockingSealingRelayRoom') ?? get('relay_room_locking_sealing'),
        'YES',
      ),
      relayRoomLighting: _toS(
        get('lightingRelayRoom') ?? get('relay_room_lighting'),
        'YES',
      ),
      relayRoomUps: _toS(
        get('upsRelayRoom') ?? get('relay_room_ups'),
        'FUNCTIONAL',
      ),
      relayRoomStaticInvertor: _toS(
        get('staticInvertorRelayRoom') ?? get('relay_room_static_invertor'),
        'FUNCTIONAL',
      ),
      relayRoomAvr: _toS(get('relay_room_avr'), 'FUNCTIONAL'),
      relayRoomAc: _toS(
        get('acRelayRoom') ?? get('relay_room_ac'),
        'FUNCTIONAL',
      ),
      relayRoomLights: _toS(get('relay_room_lights'), 'FUNCTIONAL'),
      relayRoomFans: _toS(
        get('fansRelayRoom') ?? get('relay_room_fans'),
        'FUNCTIONAL',
      ),
      batteryChargerFunctional: _toS(get('battery_charger_functional'), 'YES'),
      chargerOutputVoltage: _toDbl(get('charger_output_voltage'), 55.0),
      batteryRoomLights: _toS(get('battery_room_lights'), 'YES'),
      batteryRoomFans: _toS(get('battery_room_fans'), 'YES'),
      vhfWorking: _toS(get('vhfWorking') ?? get('vhf_working'), 'WORKING'),
      vhfOverallCondition: _toS(
        get('vhfOverallCondition') ?? get('vhf_overall_condition'),
        'SATISFACTORY',
      ),
      vhfPowerSupplyVolt: _toDbl(
        get('vhfPowerSupplyVolt') ?? get('vhf_power_supply_volt'),
        12.0,
      ),
      vhfBatteryVoltage: _toDbl(
        get('vhfBatteryVoltage') ?? get('vhf_battery_voltage'),
        12.0,
      ),
      vhfAntenna: _toS(get('vhfAntenna') ?? get('vhf_antenna'), 'SATISFACTORY'),
      commPowerSupplyVolt: _toDbl(
        get('commPowerSupplyVolt') ?? get('comm_power_supply_volt'),
        12.0,
      ),
      zongGsm: _toS(get('zongCondition') ?? get('zong_gsm'), 'FUNCTIONAL'),
      pcpOverallCondition: _toS(
        get('pcpOverallCondition') ?? get('pcp_overall_condition'),
        'SATISFACTORY',
      ),
      pcpInputVolt: _toDbl(get('pcpInputVolt') ?? get('pcp_input_volt'), 230.0),
      pcpOutputVolt: _toDbl(
        get('pcpOutputVolt') ?? get('pcp_output_volt'),
        20.0,
      ),
      uhfBatteryCapacityBrand: _toS(get('uhf_battery_capacity_brand'), 'test'),
      uhfSignalStrength: _toS(get('uhf_signal_strength'), '5'),
      uhfBatteryVoltage: _toDbl(get('uhf_battery_voltage'), 100.0),
      uhfMwBattery: _toS(get('uhf_mw_battery'), 'YES'),
      telecomAcWorking: _toS(get('telecom_ac_working'), 'WORKING'),
      telecomRoomLights: _toS(get('telecom_room_lights'), 'SATISFACTORY'),
      telecomRoomFans: _toS(get('telecom_room_fans'), 'SATISFACTORY'),
      signalDgLogBook: _toS(
        get('dgLogBookSignal') ?? get('signal_dg_log_book'),
        'YES',
      ),
      signalDgOverhaulingDate: _fmtDate(
        get('dgOverhaulingSignal') ?? get('signal_dg_overhauling_date'),
      ),
      telecomDgLogBook: _toS(
        get('dgLogBookTelecom') ?? get('telecom_dg_log_book'),
        'YES',
      ),
      telecomDgOverhaulingDate: _fmtDate(
        get('dgOverhaulingTelecom') ?? get('telecom_dg_overhauling_date'),
      ),
      dgSwitchStart: _toS(get('dg_switch_start'), 'YES'),
      dgCrankHandleStart: _toS(get('dg_crank_handle_start'), 'YES'),
      dgStatus: _toS(get('dg_status'), 'PRIME'),
      dgLogBookMaintained: _toS(get('dg_log_book_maintained'), 'YES'),
      towerType: _toS(get('tower_type'), 'SELF-SUPPORTED'),
      towerPaintCondition: _toS(get('tower_paint_condition'), 'SATISFACTORY'),
      towerHeight: _toDbl(get('tower_height'), 100.0),
      towerLight: _toS(get('towerLight') ?? get('tower_light'), 'FUNCTIONAL'),
      towerEarthConnectivity: _toS(get('tower_earth_connectivity'), 'YES'),
      towerFencing: _toS(get('tower_fencing'), 'YES'),
      towerFoundationCondition: _toS(
        get('tower_foundation_condition'),
        'SATISFACTORY',
      ),
      earthTestDate: _fmtDate(get('towerEarthTest') ?? get('earth_test_date')),
      paSystem: _toS(get('pa_system'), 'SATISFACTORY'),
      overallRemarks: _toS(
        get('remarks') ?? get('overall_remarks'),
        'test remarks',
      ),

      blockInstruments: [
        {
          "instrument_type": "Neal's Token",
          "is_enabled": true,
          "locking_sealing": "Yes",
          "sm_control_key": "FUNCTIONAL",
          "overall_working": "Satisfactory",
          "overhauling_date": _fmtDate(DateTime.now()),
          "testing_date": _fmtDate(DateTime.now()),
          "testing_result": "Satisfactory",
        },
      ],
      batteryBanks: [
        {
          "bank_type": "Main",
          "charger_voltage": 55.0,
          "batteries": [
            {"battery_number": 1, "voltage": 55.0},
          ],
        },
      ],
      points: [
        {
          "point_number": "1",
          "point_type": "ELECTRICAL",
          "point_voltage": 0.0,
          "alignment": "SATISFACTORY",
          "plunger": "SATISFACTORY",
          "point_setting_test": "Pass",
          "point_gauge_test_value": "3 mm",
          "track_gauge_ok": "Yes",
          "track_gauge_remark": "1",
          "packing_of_sleepers": "Satisfactory",
          "throw_of_point_ok": "Yes",
          "throw_of_point_remark": "1",
          "switch_tongue_rail_condition": "Satisfactory",
          "fitting_fastening": "Complete",
        },
      ],
      signals: [
        {
          "signal_id": "Up OHS",
          "visibility": "Satisfactory",
          "focus": "Satisfactory",
          "foundation_condition": "Satisfactory",
          "pole_condition": "Satisfactory",
          "signal_lens": "Satisfactory",
        },
      ],
      trackCircuits: [
        {
          "circuit_id": "1t",
          "feed_end_volt": 4.0,
          "volt_at_relay": 3.0,
          "condition_irj": "Satisfactory",
          "condition_jumper": "Satisfactory",
          "condition_bond_wire": "Satisfactory",
          "condition_track_pod": "Satisfactory",
        },
      ],
      levelCrossings: [
        {
          "crossing_no": "lc-12",
          "communication": "Good",
          "operation": "Satisfactory",
          "alignment": "SATISFACTORY",
          "plunger": "SATISFACTORY",
          "warning_bell": "Functional",
          "complaint_book": "Available",
          "battery_voltage": 11.0,
          "battery_status": "Satisfactory",
        },
      ],
      signalFailureRecords: [
        {
          "quarter": "2025",
          "year": 2026,
          "engg": 11,
          "elec": 11,
          "t_com": 11,
          "tfc": 11,
          "sig": 11,
          "o_c": 11,
          "store": 11,
        },
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "division": division,
      "section": section,
      "station": station,
      "current_step": currentStep,
      "sm_name": smName,
      "sm_uniform": smUniform,
      "sm_conversant": smConversant,
      "sm_slide_frame_overhaul_date": smSlideFrameOverhaulDate,
      "sm_slide_frame_testing_date": smSlideFrameTestingDate,
      "sm_slide_frame_locking_test": smSlideFrameLockingTest,
      "sm_iyd": smIyd,
      "sm_working_rules": smWorkingRules,
      "sm_rule_of_month": smRuleOfMonth,
      "sm_special_bulletin": smSpecialBulletin,
      "fire_extinguishers_count": fireExtinguishersCount,
      "last_overhauling_date": lastOverhaulingDate,
      "last_testing_date": lastTestingDate,
      "panel_locking_sealing": panelLockingSealing,
      "panel_signal_indications": panelSignalIndications,
      "panel_track_indications": panelTrackIndications,
      "panel_point_indications": panelPointIndications,
      "panel_power_indications": panelPowerIndications,
      "ebi_signal_indications": ebiSignalIndications,
      "ebi_track_indications": ebiTrackIndications,
      "ebi_point_indications": ebiPointIndications,
      "ebi_power_indications": ebiPowerIndications,
      "magneto_telephone_condition": magnetoTelephoneCondition,
      "magneto_speech_quality": magnetoSpeechQuality,
      "magneto_3v_battery_condition": magneto3vBatteryCondition,
      "block_instrument_type": blockInstrumentType,
      "block_instrument_sealing_locking": blockInstrumentSealingLocking,
      "block_instrument_overhaul_date": blockInstrumentOverhaulDate,
      "block_instrument_testing_date": blockInstrumentTestingDate,
      "block_instrument_testing_result": blockInstrumentTestingResult,
      "route_up_train": routeUpTrain,
      "route_down_train": routeDownTrain,
      "signal_maintenance_schedule": signalMaintenanceSchedule,
      "telecom_maintenance_schedule": telecomMaintenanceSchedule,
      "painting_program_1_year_date": paintingProgram1YearDate,
      "painting_program_3_year_date": paintingProgram3YearDate,
      "painting_program_5_year_date": paintingProgram5YearDate,
      "main_battery_voltage": mainBatteryVoltage,
      "additional_battery_voltage": additionalBatteryVoltage,
      "track_battery_voltage": trackBatteryVoltage,
      "lever_east_north_overhaul_date": leverEastNorthOverhaulDate,
      "lever_east_north_interlocking": leverEastNorthInterlocking,
      "lever_east_north_locking_test_date": leverEastNorthLockingTestDate,
      "lever_east_north_sealing_intact": leverEastNorthSealingIntact,
      "lever_west_south_overhaul_date": leverWestSouthOverhaulDate,
      "lever_west_south_interlocking": leverWestSouthInterlocking,
      "lever_west_south_locking_test_date": leverWestSouthLockingTestDate,
      "lever_west_south_sealing_intact": leverWestSouthSealingIntact,
      "equipment_room_log_book_date": equipmentRoomLogBookDate,
      "equipment_room_log_book_purpose": equipmentRoomLogBookPurpose,
      "equipment_room_log_book_asm_name": equipmentRoomLogBookAsmName,
      "relay_room_locking_sealing": relayRoomLockingSealing,
      "relay_room_lighting": relayRoomLighting,
      "relay_room_ups": relayRoomUps,
      "relay_room_static_invertor": relayRoomStaticInvertor,
      "relay_room_avr": relayRoomAvr,
      "relay_room_ac": relayRoomAc,
      "relay_room_lights": relayRoomLights,
      "relay_room_fans": relayRoomFans,
      "battery_charger_functional": batteryChargerFunctional,
      "charger_output_voltage": chargerOutputVoltage,
      "battery_room_lights": batteryRoomLights,
      "battery_room_fans": batteryRoomFans,
      "vhf_working": vhfWorking,
      "vhf_overall_condition": vhfOverallCondition,
      "vhf_power_supply_volt": vhfPowerSupplyVolt,
      "vhf_battery_voltage": vhfBatteryVoltage,
      "vhf_antenna": vhfAntenna,
      "comm_power_supply_volt": commPowerSupplyVolt,
      "zong_gsm": zongGsm,
      "pcp_overall_condition": pcpOverallCondition,
      "pcp_input_volt": pcpInputVolt,
      "pcp_output_volt": pcpOutputVolt,
      "uhf_battery_capacity_brand": uhfBatteryCapacityBrand,
      "uhf_signal_strength": uhfSignalStrength,
      "uhf_battery_voltage": uhfBatteryVoltage,
      "uhf_mw_battery": uhfMwBattery,
      "telecom_ac_working": telecomAcWorking,
      "telecom_room_lights": telecomRoomLights,
      "telecom_room_fans": telecomRoomFans,
      "signal_dg_log_book": signalDgLogBook,
      "signal_dg_overhauling_date": signalDgOverhaulingDate,
      "telecom_dg_log_book": telecomDgLogBook,
      "telecom_dg_overhauling_date": telecomDgOverhaulingDate,
      "dg_switch_start": dgSwitchStart,
      "dg_crank_handle_start": dgCrankHandleStart,
      "dg_status": dgStatus,
      "dg_log_book_maintained": dgLogBookMaintained,
      "tower_type": towerType,
      "tower_paint_condition": towerPaintCondition,
      "tower_height": towerHeight,
      "tower_light": towerLight,
      "tower_earth_connectivity": towerEarthConnectivity,
      "tower_fencing": towerFencing,
      "tower_foundation_condition": towerFoundationCondition,
      "earth_test_date": earthTestDate,
      "pa_system": paSystem,
      "overall_remarks": overallRemarks,
      "block_instruments": blockInstruments,
      "battery_banks": batteryBanks,
      "points": points,
      "signals": signals,
      "track_circuits": trackCircuits,
      "level_crossings": levelCrossings,
      "signal_failure_records": signalFailureRecords,
    };
  }
}
