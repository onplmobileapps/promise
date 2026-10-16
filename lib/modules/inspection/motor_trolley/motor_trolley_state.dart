// motortroley_state.dart
import 'package:railway_hrms/core/utils/equatable.dart';

class MotorTrolleyInspectionState extends Equatable {
  // ── Header ────────────────────────────────────────────────────────
  final String? inspectingOfficer;
  final DateTime? inspectionDate;
  final String? betweenStation;
  final String? sectionFrom;
  final String? sectionTo;
  final String? kmFrom;
  final String? kmTo;

  // ── I. Track Geometry — Alignment ────────────────────────────────
  final String? alignmentReading;
  final String? alignmentOutOfLimit;
  final String? alignmentReason;

  // ── I. Track Geometry — Gauge ────────────────────────────────────
  final String? gaugeSpeedCategory;
  final String? gaugeReading;
  final String? gaugeOutOfLimit;
  final String? gaugeReason;

  // ── I. Track Geometry — Cross Level ──────────────────────────────
  final String? crossLevelReading;
  final String? crossLevelOutOfLimit;
  final String? crossLevelReason;

  // ── I. Track Geometry — Rail ─────────────────────────────────────
  final String? railType;
  final String? railRemarks;

  // ── 2. Curves ─────────────────────────────────────────────────────
  final String? curveNo;
  final String? degreeOfCurve;
  final String? curveSpeed;
  final String? curveGaugeReading;
  final String? curveGaugeOutOfLimit;
  final String? curveGaugeAction;
  final String? curveGaugeReason;
  final String? superElevationReading;
  final String? superElevationAction;
  final String? curvePostAvailable;
  final String? checkRailClearanceCurveReading;
  final String? checkRailClearanceCurveStatus;

  // ── 3. Points & Crossings ────────────────────────────────────────
  final String? pcGauge;
  final String? pcCrossLevel;
  final String? pcFittingsPercentage;
  final String? pcSwitchWearAction;
  final String? pcSwitchWearReason;
  final String? pcCrossingWearAction;
  final String? pcCrossingWearReason;
  final String? pcCheckRailsClearance;
  final String? pcWingRailClearance;
  final String? pcCrossingTimbersPercentage;
  final String? pcCrossingTimbersAction;
  final String? pcCrossingTimbersReason;

  // ── 5. Level Crossings — location context ────────────────────────
  final String? lcMannedKmFrom;
  final String? lcMannedKmTo;
  final String? lcUnmannedKmFrom;
  final String? lcUnmannedKmTo;

  // ── Station Buildings — location context ─────────────────────────
  final String? sbName;
  final String? sbKm;
  final String? sbSection;

  // ── Generic config-driven fields (Sleeper, Fittings, Ballast,
  //     Embankment, Drainage, Joints, Oiling, Trespassing, Bridges,
  //     Level Crossings, Tunnel, Station Buildings, Yards, Block
  //     Sections). Keyed by ParamField.key from
  //     inspection_param_configs.dart. ─────────────────────────────
  final Map<String, String> values;

  // ── Certification ─────────────────────────────────────────────────
  final String? inspectedBy;
  final String? designation;
  final String? pwiIncharge;
  final String? verifiedBy;

  // ── Submission ────────────────────────────────────────────────────
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;

  const MotorTrolleyInspectionState({
    this.inspectingOfficer,
    this.inspectionDate,
    this.betweenStation,
    this.sectionFrom,
    this.sectionTo,
    this.kmFrom,
    this.kmTo,
    this.alignmentReading,
    this.alignmentOutOfLimit,
    this.alignmentReason,
    this.gaugeSpeedCategory,
    this.gaugeReading,
    this.gaugeOutOfLimit,
    this.gaugeReason,
    this.crossLevelReading,
    this.crossLevelOutOfLimit,
    this.crossLevelReason,
    this.railType,
    this.railRemarks,
    this.curveNo,
    this.degreeOfCurve,
    this.curveSpeed,
    this.curveGaugeReading,
    this.curveGaugeOutOfLimit,
    this.curveGaugeAction,
    this.curveGaugeReason,
    this.superElevationReading,
    this.superElevationAction,
    this.curvePostAvailable,
    this.checkRailClearanceCurveReading,
    this.checkRailClearanceCurveStatus,
    this.pcGauge,
    this.pcCrossLevel,
    this.pcFittingsPercentage,
    this.pcSwitchWearAction,
    this.pcSwitchWearReason,
    this.pcCrossingWearAction,
    this.pcCrossingWearReason,
    this.pcCheckRailsClearance,
    this.pcWingRailClearance,
    this.pcCrossingTimbersPercentage,
    this.pcCrossingTimbersAction,
    this.pcCrossingTimbersReason,
    this.lcMannedKmFrom,
    this.lcMannedKmTo,
    this.lcUnmannedKmFrom,
    this.lcUnmannedKmTo,
    this.sbName,
    this.sbKm,
    this.sbSection,
    this.values = const {},
    this.inspectedBy,
    this.designation,
    this.pwiIncharge,
    this.verifiedBy,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  /// Reads a config-driven field out of [values].
  String? value(String key) => values[key];

  bool _isFilled(String? val) => val != null && val.trim().isNotEmpty;

  /// Returns true if all required inspection fields are filled in the form.
  bool get isFormComplete {
    // Header
    if (!_isFilled(inspectingOfficer) ||
        inspectionDate == null ||
        !_isFilled(sectionFrom) ||
        !_isFilled(sectionTo) ||
        !_isFilled(kmFrom) ||
        !_isFilled(kmTo)) {
      return false;
    }

    // Track Geometry
    if (!_isFilled(alignmentReading) ||
        !_isFilled(alignmentOutOfLimit) ||
        !_isFilled(gaugeSpeedCategory) ||
        !_isFilled(gaugeReading) ||
        !_isFilled(gaugeOutOfLimit) ||
        !_isFilled(crossLevelReading) ||
        !_isFilled(crossLevelOutOfLimit) ||
        !_isFilled(railType) ||
        !_isFilled(railRemarks)) {
      return false;
    }

    // Curves
    if (!_isFilled(curveNo) ||
        !_isFilled(degreeOfCurve) ||
        !_isFilled(curveSpeed) ||
        !_isFilled(curveGaugeReading) ||
        !_isFilled(curveGaugeOutOfLimit) ||
        !_isFilled(superElevationReading) ||
        !_isFilled(superElevationAction) ||
        !_isFilled(curvePostAvailable) ||
        !_isFilled(checkRailClearanceCurveReading) ||
        !_isFilled(checkRailClearanceCurveStatus)) {
      return false;
    }

    // Points & Crossings
    if (!_isFilled(pcGauge) ||
        !_isFilled(pcCrossLevel) ||
        !_isFilled(pcFittingsPercentage) ||
        !_isFilled(pcSwitchWearAction) ||
        !_isFilled(pcSwitchWearReason) ||
        !_isFilled(pcCrossingWearAction) ||
        !_isFilled(pcCrossingWearReason) ||
        !_isFilled(pcCheckRailsClearance) ||
        !_isFilled(pcWingRailClearance) ||
        !_isFilled(pcCrossingTimbersPercentage) ||
        !_isFilled(pcCrossingTimbersAction) ||
        !_isFilled(pcCrossingTimbersReason)) {
      return false;
    }

    // Certification
    if (!_isFilled(inspectedBy) ||
        !_isFilled(designation) ||
        !_isFilled(pwiIncharge) ||
        !_isFilled(verifiedBy)) {
      return false;
    }

    // Config fields (Sleeper, Fittings, Ballast, Embankment, Drainage, Joints, Oiling, Trespassing, Bridges, LC, Tunnel, SB, Yards, Block)
    const requiredConfigKeys = [
      'sleeperType',
      'sleeperTrackType',
      'sleeperSeason',
      'sleeperUsPercentage',
      'fittingType',
      'fittingTrackType',
      'fittingSeason',
      'fittingUsPercentage',
      'ballastCushion',
      'embankmentDimension',
      'embankmentCondition',
      'drainageType',
      'drainageCondition',
      'jointsCondition',
      'oilingGraphitting',
      'trespassing',
      'bridgeScouring',
      'bridgeBrickMasonry',
      'bridgeFlooringApron',
      'bridgeAbutment',
      'bridgePier',
      'bridgeFoundation',
      'bridgeWingWall',
      'bridgeDropWall',
      'bridgeCurtainWall',
      'bridgeWaterWays',
      'bridgeSettlement',
      'bridgeEarthExcavation',
      'bridgeGauge',
      'bridgeCrossLevel',
      'bridgeRattling',
      'bridgeGuardRails',
      'bridgeGangway',
      'bridgeGirderPainting',
      'bridgeBearingOiling',
      'bridgeBallastWallClearance',
      'bridgeBedStones',
      'bridgeApproaches',
      'bridgeTimbers',
      'bridgeTimberSquaring',
      'bridgeHoldingDownBolts',
      'lcGateSignals',
      'lcTelecomSystem',
      'lcInterlocking',
      'lcGauge',
      'lcCrossLevel',
      'lcTrackApproaches',
      'lcGateLeaves',
      'lcWarningBoards',
      'lcSdBoard',
      'lcRoadSurfacing',
      'lcCheckRailClearanceH',
      'lcCheckRailDepthV',
      'lcDistanceBlocks',
      'lcEquipment',
      'lcTurnStyle',
      'lcGatekeeperKnowledge',
      'lcInspectionRecord',
      'lcVisibility',
      'lcFencing',
      'lcuGauge',
      'lcuCrossLevel',
      'lcuTrackApproaches',
      'lcuWarningBoards',
      'lcuSpeedBreakers',
      'lcuRoadSurface',
      'lcuCheckRailClearanceH',
      'lcuCheckRailDepthV',
      'lcuDistanceBlocks',
      'lcuVisibility',
      'tunnelPortal',
      'tunnelRoofCrown',
      'tunnelWallLining',
      'tunnelInvertFloor',
      'tunnelWeepHoles',
      'tunnelSideDrains',
      'tunnelRefuges',
      'tunnelRoofTopDrain',
      'tunnelWalkway',
      'tunnelVentilation',
      'tunnelHorizontalClearance',
      'tunnelVerticalClearance',
      'tunnelTrackGauge',
      'tunnelTrackCrossLevel',
      'tunnelTrackAlignment',
      'tunnelMagnifiedGlass',
      'sbApproach',
      'sbFacade',
      'sbRoofType',
      'sbRoofCondition',
      'sbRoofDrainage',
      'sbWaitingRooms',
      'sbWashroom',
      'sbDoors',
      'sbWindows',
      'sbPainting',
      'sbPlatforms',
      'sbFootOverBridges',
      'sbShelters',
      'sbWateringArrangements',
      'sbSewerage',
      'sbSignalingCabins',
      'sbEscalator',
      'yardGauge',
      'yardCrossLevel',
      'yardSleepers',
      'yardBallast',
      'yardLoops',
      'yardSignaling',
      'yardWashingLines',
      'yardSickLine',
      'yardSnagDeadEnd',
      'bsBoundaryPillars',
      'bsEncroachments',
      'bsTrespassing',
      'bsSuiGasCrossing',
      'bsElectricCrossing',
      'bsUnderPass',
      'bsCableCrossings',
      'bsOverheadBridges',
    ];

    for (final key in requiredConfigKeys) {
      if (!_isFilled(values[key])) {
        return false;
      }
    }

    return true;
  }

  MotorTrolleyInspectionState copyWith({
    String? inspectingOfficer,
    DateTime? inspectionDate,
    String? betweenStation,
    String? sectionFrom,
    String? sectionTo,
    String? kmFrom,
    String? kmTo,
    String? alignmentReading,
    String? alignmentOutOfLimit,
    String? alignmentReason,
    String? gaugeSpeedCategory,
    String? gaugeReading,
    String? gaugeOutOfLimit,
    String? gaugeReason,
    String? crossLevelReading,
    String? crossLevelOutOfLimit,
    String? crossLevelReason,
    String? railType,
    String? railRemarks,
    String? curveNo,
    String? degreeOfCurve,
    String? curveSpeed,
    String? curveGaugeReading,
    String? curveGaugeOutOfLimit,
    String? curveGaugeAction,
    String? curveGaugeReason,
    String? superElevationReading,
    String? superElevationAction,
    String? curvePostAvailable,
    String? checkRailClearanceCurveReading,
    String? checkRailClearanceCurveStatus,
    String? pcGauge,
    String? pcCrossLevel,
    String? pcFittingsPercentage,
    String? pcSwitchWearAction,
    String? pcSwitchWearReason,
    String? pcCrossingWearAction,
    String? pcCrossingWearReason,
    String? pcCheckRailsClearance,
    String? pcWingRailClearance,
    String? pcCrossingTimbersPercentage,
    String? pcCrossingTimbersAction,
    String? pcCrossingTimbersReason,
    String? lcMannedKmFrom,
    String? lcMannedKmTo,
    String? lcUnmannedKmFrom,
    String? lcUnmannedKmTo,
    String? sbName,
    String? sbKm,
    String? sbSection,
    Map<String, String>? values,
    String? inspectedBy,
    String? designation,
    String? pwiIncharge,
    String? verifiedBy,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MotorTrolleyInspectionState(
      inspectingOfficer: inspectingOfficer ?? this.inspectingOfficer,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      betweenStation: betweenStation ?? this.betweenStation,
      sectionFrom: sectionFrom ?? this.sectionFrom,
      sectionTo: sectionTo ?? this.sectionTo,
      kmFrom: kmFrom ?? this.kmFrom,
      kmTo: kmTo ?? this.kmTo,
      alignmentReading: alignmentReading ?? this.alignmentReading,
      alignmentOutOfLimit: alignmentOutOfLimit ?? this.alignmentOutOfLimit,
      alignmentReason: alignmentReason ?? this.alignmentReason,
      gaugeSpeedCategory: gaugeSpeedCategory ?? this.gaugeSpeedCategory,
      gaugeReading: gaugeReading ?? this.gaugeReading,
      gaugeOutOfLimit: gaugeOutOfLimit ?? this.gaugeOutOfLimit,
      gaugeReason: gaugeReason ?? this.gaugeReason,
      crossLevelReading: crossLevelReading ?? this.crossLevelReading,
      crossLevelOutOfLimit: crossLevelOutOfLimit ?? this.crossLevelOutOfLimit,
      crossLevelReason: crossLevelReason ?? this.crossLevelReason,
      railType: railType ?? this.railType,
      railRemarks: railRemarks ?? this.railRemarks,
      curveNo: curveNo ?? this.curveNo,
      degreeOfCurve: degreeOfCurve ?? this.degreeOfCurve,
      curveSpeed: curveSpeed ?? this.curveSpeed,
      curveGaugeReading: curveGaugeReading ?? this.curveGaugeReading,
      curveGaugeOutOfLimit: curveGaugeOutOfLimit ?? this.curveGaugeOutOfLimit,
      curveGaugeAction: curveGaugeAction ?? this.curveGaugeAction,
      curveGaugeReason: curveGaugeReason ?? this.curveGaugeReason,
      superElevationReading:
          superElevationReading ?? this.superElevationReading,
      superElevationAction: superElevationAction ?? this.superElevationAction,
      curvePostAvailable: curvePostAvailable ?? this.curvePostAvailable,
      checkRailClearanceCurveReading:
          checkRailClearanceCurveReading ?? this.checkRailClearanceCurveReading,
      checkRailClearanceCurveStatus:
          checkRailClearanceCurveStatus ?? this.checkRailClearanceCurveStatus,
      pcGauge: pcGauge ?? this.pcGauge,
      pcCrossLevel: pcCrossLevel ?? this.pcCrossLevel,
      pcFittingsPercentage: pcFittingsPercentage ?? this.pcFittingsPercentage,
      pcSwitchWearAction: pcSwitchWearAction ?? this.pcSwitchWearAction,
      pcSwitchWearReason: pcSwitchWearReason ?? this.pcSwitchWearReason,
      pcCrossingWearAction: pcCrossingWearAction ?? this.pcCrossingWearAction,
      pcCrossingWearReason: pcCrossingWearReason ?? this.pcCrossingWearReason,
      pcCheckRailsClearance:
          pcCheckRailsClearance ?? this.pcCheckRailsClearance,
      pcWingRailClearance: pcWingRailClearance ?? this.pcWingRailClearance,
      pcCrossingTimbersPercentage:
          pcCrossingTimbersPercentage ?? this.pcCrossingTimbersPercentage,
      pcCrossingTimbersAction:
          pcCrossingTimbersAction ?? this.pcCrossingTimbersAction,
      pcCrossingTimbersReason:
          pcCrossingTimbersReason ?? this.pcCrossingTimbersReason,
      lcMannedKmFrom: lcMannedKmFrom ?? this.lcMannedKmFrom,
      lcMannedKmTo: lcMannedKmTo ?? this.lcMannedKmTo,
      lcUnmannedKmFrom: lcUnmannedKmFrom ?? this.lcUnmannedKmFrom,
      lcUnmannedKmTo: lcUnmannedKmTo ?? this.lcUnmannedKmTo,
      sbName: sbName ?? this.sbName,
      sbKm: sbKm ?? this.sbKm,
      sbSection: sbSection ?? this.sbSection,
      values: values ?? this.values,
      inspectedBy: inspectedBy ?? this.inspectedBy,
      designation: designation ?? this.designation,
      pwiIncharge: pwiIncharge ?? this.pwiIncharge,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    inspectingOfficer,
    inspectionDate,
    betweenStation,
    sectionFrom,
    sectionTo,
    kmFrom,
    kmTo,
    alignmentReading,
    alignmentOutOfLimit,
    alignmentReason,
    gaugeSpeedCategory,
    gaugeReading,
    gaugeOutOfLimit,
    gaugeReason,
    crossLevelReading,
    crossLevelOutOfLimit,
    crossLevelReason,
    railType,
    railRemarks,
    curveNo,
    degreeOfCurve,
    curveSpeed,
    curveGaugeReading,
    curveGaugeOutOfLimit,
    curveGaugeAction,
    curveGaugeReason,
    superElevationReading,
    superElevationAction,
    curvePostAvailable,
    checkRailClearanceCurveReading,
    checkRailClearanceCurveStatus,
    pcGauge,
    pcCrossLevel,
    pcFittingsPercentage,
    pcSwitchWearAction,
    pcSwitchWearReason,
    pcCrossingWearAction,
    pcCrossingWearReason,
    pcCheckRailsClearance,
    pcWingRailClearance,
    pcCrossingTimbersPercentage,
    pcCrossingTimbersAction,
    pcCrossingTimbersReason,
    lcMannedKmFrom,
    lcMannedKmTo,
    lcUnmannedKmFrom,
    lcUnmannedKmTo,
    sbName,
    sbKm,
    sbSection,
    values,
    inspectedBy,
    designation,
    pwiIncharge,
    verifiedBy,
    isSubmitting,
    isSuccess,
    errorMessage,
  ];
}
