import 'package:intl/intl.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';

class MotorTrolleyInspectionSubmitModel {
  final String inspectingOfficerNameDesignation;
  final String inspectionDate;
  final String sectionFrom;
  final String sectionTo;
  final double? kmFrom;
  final double? kmTo;

  final double? alignmentReadingMm;
  final String alignmentOutOfLimit;
  final String gaugeSpeedCategory;
  final double? gaugeReadingMm;
  final String gaugeOutOfLimit;
  final double? crossLevelReadingMm;
  final String crossLevelOutOfLimit;
  final String railType;
  final String railRemarks;

  final String sleeperType;
  final String sleeperTrackType;
  final String sleeperSeason;
  final String sleeperUsPctRecordedSpeedKmph;
  final String fittingsFittingType;
  final String fittingsTrackType;
  final String fittingsSeason;
  final String fittingsUsPctRecordedSpeedKmph;
  final String ballastCushion;
  final String ballastRemedy;
  final String embankmentDimension;
  final String embankmentCondition;
  final String embankmentRemedy;
  final String drainageType;
  final String drainageCondition;
  final String drainageRemedy;
  final String joints;
  final String jointsRemedy;
  final String oilingGraphittingFishPlatedJoints;
  final String oilingGraphittingRemedy;
  final String trespassing;
  final String trespassingRemedy;

  final String curveNo;
  final String degreeOfCurve;
  final String curveSpeedKmph;
  final double? gaugeOnCurveReadingMm;
  final String gaugeOnCurveOutOfLimit;
  final double? superElevationReadingMm;
  final String superElevationAction;
  final String curvePostStandard1000;
  final String checkRailClearance6DegAbove;
  final String checkRailClearanceStatus;

  final String pointsGauge;
  final String pointsCrossLevel;
  final double? pointsFittingsPct;
  final String wearOfSwitchAction;
  final String wearOfSwitchReason;
  final String wearOfCrossingAction;
  final String wearOfCrossingReason;
  final double? checkRailsClearanceStandard45;
  final double? wingRailClearanceStandard4547;
  final double? crossingTimbersUsPct;
  final String crossingTimbersAction;
  final String crossingTimbersReason;

  final String bridgesScouring;
  final String bridgesBrickMasonry;
  final String bridgesFlooringApron;
  final String bridgesAbutment;
  final String bridgesPier;
  final String bridgesFoundation;
  final String bridgesWingWall;
  final String bridgesDropWall;
  final String bridgesCurtainWall;
  final String bridgesWaterWays;
  final String bridgesSettlementOfSubstructure;
  final String bridgesEarthExcavationStreamSides;
  final String bridgesSuperGauge;
  final String bridgesSuperCrossLevel;
  final String bridgesSuperRattling;
  final String bridgesSuperGuardRails;
  final String bridgesSuperGangway;
  final String bridgesSuperGirderBridgePainting;
  final String bridgesSuperBearingOilingRecord;
  final String bridgesSuperBallastWallClearance;
  final String bridgesSuperBedStones;
  final String bridgesSuperBridgeApproaches;
  final double? bridgesSuperBridgeTimbersUsPct;
  final String bridgesSuperBridgeTimbersSquaringSpacing;
  final String bridgesSuperHoldingDownBolts;

  final double? lcMannedKmFrom;
  final double? lcMannedKmTo;
  final String lcMannedGateSignals;
  final String lcMannedTelecomSystem;
  final String lcMannedInterlocking;
  final String lcMannedGauge;
  final String lcMannedCrossLevel;
  final String lcMannedTrackApproaches;
  final String lcMannedGateLeaves;
  final String lcMannedWarningWhistleBoards;
  final String lcMannedSdBoard;
  final String lcMannedRoadSurfacing;
  final double? lcMannedCheckRailClearanceHorizontal;
  final double? lcMannedCheckRailDepthVertical;
  final String lcMannedDistanceBlocks;
  final String lcMannedLevelCrossingEquipment;
  final String lcMannedTurnStyle;
  final String lcMannedGatekeeperSafetyKnowledge;
  final String lcMannedInspectionRecord;
  final String lcMannedVisibility;
  final String lcMannedFencing;

  final double? lcUnmannedKmFrom;
  final double? lcUnmannedKmTo;
  final String lcUnmannedGauge;
  final String lcUnmannedCrossLevel;
  final String lcUnmannedTrackApproaches;
  final String lcUnmannedWarningWhistleBoards;
  final String lcUnmannedSpeedBreakers;
  final String lcUnmannedRoadSurface;
  final double? lcUnmannedCheckRailClearanceHorizontal;
  final double? lcUnmannedCheckRailDepthVertical;
  final String lcUnmannedDistanceBlocks;
  final String lcUnmannedVisibility;

  final String tunnelPortal;
  final String tunnelRoofCrown;
  final String tunnelWallLining;
  final String tunnelInvertFloor;
  final String tunnelWeepHoles;
  final String tunnelSideDrains;
  final String tunnelRefuges;
  final String tunnelRoofTopDrain;
  final String tunnelWalkway;
  final String tunnelVentilationShaft;
  final String tunnelHorizontalClearance;
  final String tunnelVerticalClearance;
  final String tunnelTrackGauge;
  final String tunnelTrackCrossLevel;
  final String tunnelTrackAlignment;
  final String tunnelMagnifiedGlass;

  final String stationBldgName;
  final double? stationBldgKm;
  final String stationBldgSection;
  final String stationBldgApproach;
  final String stationBldgFacade;
  final String stationBldgRoofType;
  final String stationBldgRoofCondition;
  final String stationBldgRoofDrainage;
  final String stationBldgWaitingRooms;
  final String stationBldgWashroom;
  final String stationBldgDoors;
  final String stationBldgWindows;
  final String stationBldgPainting;
  final String stationBldgPlatforms;
  final String stationBldgFootOverBridges;
  final String stationBldgShelters;
  final String stationBldgWateringArrangements;
  final String stationBldgSewerage;
  final String stationBldgSignalingCabins;
  final String stationBldgEscalator;

  final String yardsGauge;
  final String yardsCrossLevel;
  final double? yardsSleepersUsPct;
  final String yardsBallast;
  final String yardsLoops;
  final String yardsSignaling;
  final String yardsWashingLines;
  final String yardsSickLine;
  final String yardsSnagDeadEnd;

  final String blockBoundaryPillars;
  final String blockEncroachments;
  final String blockTrespassing;
  final String blockSuiGasCrossing;
  final String blockElectricCrossing;
  final String blockUnderPass;
  final String blockCableCrossings;
  final String blockOverheadBridges;

  final String inspectedBy;
  final String inspectedByDesignation;
  final String pwiInCharge;
  final String verifiedBy;

  const MotorTrolleyInspectionSubmitModel({
    required this.inspectingOfficerNameDesignation,
    required this.inspectionDate,
    required this.sectionFrom,
    required this.sectionTo,
    this.kmFrom,
    this.kmTo,
    this.alignmentReadingMm,
    required this.alignmentOutOfLimit,
    required this.gaugeSpeedCategory,
    this.gaugeReadingMm,
    required this.gaugeOutOfLimit,
    this.crossLevelReadingMm,
    required this.crossLevelOutOfLimit,
    required this.railType,
    required this.railRemarks,
    required this.sleeperType,
    required this.sleeperTrackType,
    required this.sleeperSeason,
    required this.sleeperUsPctRecordedSpeedKmph,
    required this.fittingsFittingType,
    required this.fittingsTrackType,
    required this.fittingsSeason,
    required this.fittingsUsPctRecordedSpeedKmph,
    required this.ballastCushion,
    required this.ballastRemedy,
    required this.embankmentDimension,
    required this.embankmentCondition,
    required this.embankmentRemedy,
    required this.drainageType,
    required this.drainageCondition,
    required this.drainageRemedy,
    required this.joints,
    required this.jointsRemedy,
    required this.oilingGraphittingFishPlatedJoints,
    required this.oilingGraphittingRemedy,
    required this.trespassing,
    required this.trespassingRemedy,
    required this.curveNo,
    required this.degreeOfCurve,
    required this.curveSpeedKmph,
    this.gaugeOnCurveReadingMm,
    required this.gaugeOnCurveOutOfLimit,
    this.superElevationReadingMm,
    required this.superElevationAction,
    required this.curvePostStandard1000,
    required this.checkRailClearance6DegAbove,
    required this.checkRailClearanceStatus,
    required this.pointsGauge,
    required this.pointsCrossLevel,
    this.pointsFittingsPct,
    required this.wearOfSwitchAction,
    required this.wearOfSwitchReason,
    required this.wearOfCrossingAction,
    required this.wearOfCrossingReason,
    this.checkRailsClearanceStandard45,
    this.wingRailClearanceStandard4547,
    this.crossingTimbersUsPct,
    required this.crossingTimbersAction,
    required this.crossingTimbersReason,
    required this.bridgesScouring,
    required this.bridgesBrickMasonry,
    required this.bridgesFlooringApron,
    required this.bridgesAbutment,
    required this.bridgesPier,
    required this.bridgesFoundation,
    required this.bridgesWingWall,
    required this.bridgesDropWall,
    required this.bridgesCurtainWall,
    required this.bridgesWaterWays,
    required this.bridgesSettlementOfSubstructure,
    required this.bridgesEarthExcavationStreamSides,
    required this.bridgesSuperGauge,
    required this.bridgesSuperCrossLevel,
    required this.bridgesSuperRattling,
    required this.bridgesSuperGuardRails,
    required this.bridgesSuperGangway,
    required this.bridgesSuperGirderBridgePainting,
    required this.bridgesSuperBearingOilingRecord,
    required this.bridgesSuperBallastWallClearance,
    required this.bridgesSuperBedStones,
    required this.bridgesSuperBridgeApproaches,
    this.bridgesSuperBridgeTimbersUsPct,
    required this.bridgesSuperBridgeTimbersSquaringSpacing,
    required this.bridgesSuperHoldingDownBolts,
    this.lcMannedKmFrom,
    this.lcMannedKmTo,
    required this.lcMannedGateSignals,
    required this.lcMannedTelecomSystem,
    required this.lcMannedInterlocking,
    required this.lcMannedGauge,
    required this.lcMannedCrossLevel,
    required this.lcMannedTrackApproaches,
    required this.lcMannedGateLeaves,
    required this.lcMannedWarningWhistleBoards,
    required this.lcMannedSdBoard,
    required this.lcMannedRoadSurfacing,
    this.lcMannedCheckRailClearanceHorizontal,
    this.lcMannedCheckRailDepthVertical,
    required this.lcMannedDistanceBlocks,
    required this.lcMannedLevelCrossingEquipment,
    required this.lcMannedTurnStyle,
    required this.lcMannedGatekeeperSafetyKnowledge,
    required this.lcMannedInspectionRecord,
    required this.lcMannedVisibility,
    required this.lcMannedFencing,
    this.lcUnmannedKmFrom,
    this.lcUnmannedKmTo,
    required this.lcUnmannedGauge,
    required this.lcUnmannedCrossLevel,
    required this.lcUnmannedTrackApproaches,
    required this.lcUnmannedWarningWhistleBoards,
    required this.lcUnmannedSpeedBreakers,
    required this.lcUnmannedRoadSurface,
    this.lcUnmannedCheckRailClearanceHorizontal,
    this.lcUnmannedCheckRailDepthVertical,
    required this.lcUnmannedDistanceBlocks,
    required this.lcUnmannedVisibility,
    required this.tunnelPortal,
    required this.tunnelRoofCrown,
    required this.tunnelWallLining,
    required this.tunnelInvertFloor,
    required this.tunnelWeepHoles,
    required this.tunnelSideDrains,
    required this.tunnelRefuges,
    required this.tunnelRoofTopDrain,
    required this.tunnelWalkway,
    required this.tunnelVentilationShaft,
    required this.tunnelHorizontalClearance,
    required this.tunnelVerticalClearance,
    required this.tunnelTrackGauge,
    required this.tunnelTrackCrossLevel,
    required this.tunnelTrackAlignment,
    required this.tunnelMagnifiedGlass,
    required this.stationBldgName,
    this.stationBldgKm,
    required this.stationBldgSection,
    required this.stationBldgApproach,
    required this.stationBldgFacade,
    required this.stationBldgRoofType,
    required this.stationBldgRoofCondition,
    required this.stationBldgRoofDrainage,
    required this.stationBldgWaitingRooms,
    required this.stationBldgWashroom,
    required this.stationBldgDoors,
    required this.stationBldgWindows,
    required this.stationBldgPainting,
    required this.stationBldgPlatforms,
    required this.stationBldgFootOverBridges,
    required this.stationBldgShelters,
    required this.stationBldgWateringArrangements,
    required this.stationBldgSewerage,
    required this.stationBldgSignalingCabins,
    required this.stationBldgEscalator,
    required this.yardsGauge,
    required this.yardsCrossLevel,
    this.yardsSleepersUsPct,
    required this.yardsBallast,
    required this.yardsLoops,
    required this.yardsSignaling,
    required this.yardsWashingLines,
    required this.yardsSickLine,
    required this.yardsSnagDeadEnd,
    required this.blockBoundaryPillars,
    required this.blockEncroachments,
    required this.blockTrespassing,
    required this.blockSuiGasCrossing,
    required this.blockElectricCrossing,
    required this.blockUnderPass,
    required this.blockCableCrossings,
    required this.blockOverheadBridges,
    required this.inspectedBy,
    required this.inspectedByDesignation,
    required this.pwiInCharge,
    required this.verifiedBy,
  });

  factory MotorTrolleyInspectionSubmitModel.fromState(
    MotorTrolleyInspectionState state,
  ) {
    final values = state.values;

    String dateStr = '';
    if (state.inspectionDate != null) {
      dateStr = DateFormat('yyyy-MM-dd').format(state.inspectionDate!);
    } else {
      dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    return MotorTrolleyInspectionSubmitModel(
      inspectingOfficerNameDesignation: state.inspectingOfficer ?? '',
      inspectionDate: dateStr,
      sectionFrom: state.sectionFrom ?? '',
      sectionTo: state.sectionTo ?? '',
      kmFrom: _parseDouble(state.kmFrom),
      kmTo: _parseDouble(state.kmTo),
      alignmentReadingMm: _parseDouble(state.alignmentReading),
      alignmentOutOfLimit: state.alignmentOutOfLimit ?? 'No',
      gaugeSpeedCategory: state.gaugeSpeedCategory ?? '',
      gaugeReadingMm: _parseDouble(state.gaugeReading),
      gaugeOutOfLimit: state.gaugeOutOfLimit ?? 'No',
      crossLevelReadingMm: _parseDouble(state.crossLevelReading),
      crossLevelOutOfLimit: state.crossLevelOutOfLimit ?? 'No',
      railType: state.railType ?? '',
      railRemarks: state.railRemarks ?? '',
      sleeperType: values['sleeperType'] ?? '',
      sleeperTrackType: values['sleeperTrackType'] ?? '',
      sleeperSeason: values['sleeperSeason'] ?? '',
      sleeperUsPctRecordedSpeedKmph: values['sleeperUsPercentage'] ?? '',
      fittingsFittingType: values['fittingType'] ?? '',
      fittingsTrackType: values['fittingTrackType'] ?? '',
      fittingsSeason: values['fittingSeason'] ?? '',
      fittingsUsPctRecordedSpeedKmph: values['fittingUsPercentage'] ?? '',
      ballastCushion: values['ballastCushion'] ?? '',
      ballastRemedy: values['ballastCushion_remedy'] ?? '',
      embankmentDimension: values['embankmentDimension'] ?? '',
      embankmentCondition: values['embankmentCondition'] ?? '',
      embankmentRemedy: values['embankmentCondition_remedy'] ?? '',
      drainageType: values['drainageType'] ?? '',
      drainageCondition: values['drainageCondition'] ?? '',
      drainageRemedy: values['drainageCondition_remedy'] ?? '',
      joints: values['jointsCondition'] ?? '',
      jointsRemedy: values['jointsCondition_remedy'] ?? '',
      oilingGraphittingFishPlatedJoints: values['oilingGraphitting'] ?? '',
      oilingGraphittingRemedy: values['oilingGraphitting_remedy'] ?? '',
      trespassing: values['trespassing'] ?? '',
      trespassingRemedy: values['trespassing_remedy'] ?? '',
      curveNo: state.curveNo ?? '',
      degreeOfCurve: state.degreeOfCurve ?? '',
      curveSpeedKmph: state.curveSpeed ?? '',
      gaugeOnCurveReadingMm: _parseDouble(state.curveGaugeReading),
      gaugeOnCurveOutOfLimit: state.curveGaugeOutOfLimit ?? 'No',
      superElevationReadingMm: _parseDouble(state.superElevationReading),
      superElevationAction: state.superElevationAction ?? '',
      curvePostStandard1000: state.curvePostAvailable ?? '',
      checkRailClearance6DegAbove: state.checkRailClearanceCurveReading ?? '',
      checkRailClearanceStatus: state.checkRailClearanceCurveStatus ?? '',
      pointsGauge: state.pcGauge ?? '',
      pointsCrossLevel: state.pcCrossLevel ?? '',
      pointsFittingsPct: _parseDouble(state.pcFittingsPercentage),
      wearOfSwitchAction: state.pcSwitchWearAction ?? '',
      wearOfSwitchReason: state.pcSwitchWearReason ?? '',
      wearOfCrossingAction: state.pcCrossingWearAction ?? '',
      wearOfCrossingReason: state.pcCrossingWearReason ?? '',
      checkRailsClearanceStandard45: _parseDouble(state.pcCheckRailsClearance),
      wingRailClearanceStandard4547: _parseDouble(state.pcWingRailClearance),
      crossingTimbersUsPct: _parseDouble(state.pcCrossingTimbersPercentage),
      crossingTimbersAction: state.pcCrossingTimbersAction ?? '',
      crossingTimbersReason: state.pcCrossingTimbersReason ?? '',
      bridgesScouring: values['bridgeScouring'] ?? '',
      bridgesBrickMasonry: values['bridgeBrickMasonry'] ?? '',
      bridgesFlooringApron: values['bridgeFlooringApron'] ?? '',
      bridgesAbutment: values['bridgeAbutment'] ?? '',
      bridgesPier: values['bridgePier'] ?? '',
      bridgesFoundation: values['bridgeFoundation'] ?? '',
      bridgesWingWall: values['bridgeWingWall'] ?? '',
      bridgesDropWall: values['bridgeDropWall'] ?? '',
      bridgesCurtainWall: values['bridgeCurtainWall'] ?? '',
      bridgesWaterWays: values['bridgeWaterWays'] ?? '',
      bridgesSettlementOfSubstructure: values['bridgeSettlement'] ?? '',
      bridgesEarthExcavationStreamSides: values['bridgeEarthExcavation'] ?? '',
      bridgesSuperGauge: values['bridgeGauge'] ?? '',
      bridgesSuperCrossLevel: values['bridgeCrossLevel'] ?? '',
      bridgesSuperRattling: values['bridgeRattling'] ?? '',
      bridgesSuperGuardRails: values['bridgeGuardRails'] ?? '',
      bridgesSuperGangway: values['bridgeGangway'] ?? '',
      bridgesSuperGirderBridgePainting: values['bridgeGirderPainting'] ?? '',
      bridgesSuperBearingOilingRecord: values['bridgeBearingOiling'] ?? '',
      bridgesSuperBallastWallClearance:
          values['bridgeBallastWallClearance'] ?? '',
      bridgesSuperBedStones: values['bridgeBedStones'] ?? '',
      bridgesSuperBridgeApproaches: values['bridgeApproaches'] ?? '',
      bridgesSuperBridgeTimbersUsPct: _parseDouble(values['bridgeTimbers']),
      bridgesSuperBridgeTimbersSquaringSpacing:
          values['bridgeTimberSquaring'] ?? '',
      bridgesSuperHoldingDownBolts: values['bridgeHoldingDownBolts'] ?? '',
      lcMannedKmFrom: _parseDouble(state.lcMannedKmFrom),
      lcMannedKmTo: _parseDouble(state.lcMannedKmTo),
      lcMannedGateSignals: values['lcGateSignals'] ?? '',
      lcMannedTelecomSystem: values['lcTelecomSystem'] ?? '',
      lcMannedInterlocking: values['lcInterlocking'] ?? '',
      lcMannedGauge: values['lcGauge'] ?? '',
      lcMannedCrossLevel: values['lcCrossLevel'] ?? '',
      lcMannedTrackApproaches: values['lcTrackApproaches'] ?? '',
      lcMannedGateLeaves: values['lcGateLeaves'] ?? '',
      lcMannedWarningWhistleBoards: values['lcWarningBoards'] ?? '',
      lcMannedSdBoard: values['lcSdBoard'] ?? '',
      lcMannedRoadSurfacing: values['lcRoadSurfacing'] ?? '',
      lcMannedCheckRailClearanceHorizontal: _parseDouble(
        values['lcCheckRailClearanceH'],
      ),
      lcMannedCheckRailDepthVertical: _parseDouble(values['lcCheckRailDepthV']),
      lcMannedDistanceBlocks: values['lcDistanceBlocks'] ?? '',
      lcMannedLevelCrossingEquipment: values['lcEquipment'] ?? '',
      lcMannedTurnStyle: values['lcTurnStyle'] ?? '',
      lcMannedGatekeeperSafetyKnowledge: values['lcGatekeeperKnowledge'] ?? '',
      lcMannedInspectionRecord: values['lcInspectionRecord'] ?? '',
      lcMannedVisibility: values['lcVisibility'] ?? '',
      lcMannedFencing: values['lcFencing'] ?? '',
      lcUnmannedKmFrom: _parseDouble(state.lcUnmannedKmFrom),
      lcUnmannedKmTo: _parseDouble(state.lcUnmannedKmTo),
      lcUnmannedGauge: values['lcuGauge'] ?? '',
      lcUnmannedCrossLevel: values['lcuCrossLevel'] ?? '',
      lcUnmannedTrackApproaches: values['lcuTrackApproaches'] ?? '',
      lcUnmannedWarningWhistleBoards: values['lcuWarningBoards'] ?? '',
      lcUnmannedSpeedBreakers: values['lcuSpeedBreakers'] ?? '',
      lcUnmannedRoadSurface: values['lcuRoadSurface'] ?? '',
      lcUnmannedCheckRailClearanceHorizontal: _parseDouble(
        values['lcuCheckRailClearanceH'],
      ),
      lcUnmannedCheckRailDepthVertical: _parseDouble(
        values['lcuCheckRailDepthV'],
      ),
      lcUnmannedDistanceBlocks: values['lcuDistanceBlocks'] ?? '',
      lcUnmannedVisibility: values['lcuVisibility'] ?? '',
      tunnelPortal: values['tunnelPortal'] ?? '',
      tunnelRoofCrown: values['tunnelRoofCrown'] ?? '',
      tunnelWallLining: values['tunnelWallLining'] ?? '',
      tunnelInvertFloor: values['tunnelInvertFloor'] ?? '',
      tunnelWeepHoles: values['tunnelWeepHoles'] ?? '',
      tunnelSideDrains: values['tunnelSideDrains'] ?? '',
      tunnelRefuges: values['tunnelRefuges'] ?? '',
      tunnelRoofTopDrain: values['tunnelRoofTopDrain'] ?? '',
      tunnelWalkway: values['tunnelWalkway'] ?? '',
      tunnelVentilationShaft: values['tunnelVentilation'] ?? '',
      tunnelHorizontalClearance: values['tunnelHorizontalClearance'] ?? '',
      tunnelVerticalClearance: values['tunnelVerticalClearance'] ?? '',
      tunnelTrackGauge: values['tunnelTrackGauge'] ?? '',
      tunnelTrackCrossLevel: values['tunnelTrackCrossLevel'] ?? '',
      tunnelTrackAlignment: values['tunnelTrackAlignment'] ?? '',
      tunnelMagnifiedGlass: values['tunnelMagnifiedGlass'] ?? '',
      stationBldgName: state.sbName ?? '',
      stationBldgKm: _parseDouble(state.sbKm),
      stationBldgSection: state.sbSection ?? '',
      stationBldgApproach: values['sbApproach'] ?? '',
      stationBldgFacade: values['sbFacade'] ?? '',
      stationBldgRoofType: values['sbRoofType'] ?? '',
      stationBldgRoofCondition: values['sbRoofCondition'] ?? '',
      stationBldgRoofDrainage: values['sbRoofDrainage'] ?? '',
      stationBldgWaitingRooms: values['sbWaitingRooms'] ?? '',
      stationBldgWashroom: values['sbWashroom'] ?? '',
      stationBldgDoors: values['sbDoors'] ?? '',
      stationBldgWindows: values['sbWindows'] ?? '',
      stationBldgPainting: values['sbPainting'] ?? '',
      stationBldgPlatforms: values['sbPlatforms'] ?? '',
      stationBldgFootOverBridges: values['sbFootOverBridges'] ?? '',
      stationBldgShelters: values['sbShelters'] ?? '',
      stationBldgWateringArrangements: values['sbWateringArrangements'] ?? '',
      stationBldgSewerage: values['sbSewerage'] ?? '',
      stationBldgSignalingCabins: values['sbSignalingCabins'] ?? '',
      stationBldgEscalator: values['sbEscalator'] ?? '',
      yardsGauge: values['yardGauge'] ?? '',
      yardsCrossLevel: values['yardCrossLevel'] ?? '',
      yardsSleepersUsPct: _parseDouble(values['yardSleepers']),
      yardsBallast: values['yardBallast'] ?? '',
      yardsLoops: values['yardLoops'] ?? '',
      yardsSignaling: values['yardSignaling'] ?? '',
      yardsWashingLines: values['yardWashingLines'] ?? '',
      yardsSickLine: values['yardSickLine'] ?? '',
      yardsSnagDeadEnd: values['yardSnagDeadEnd'] ?? '',
      blockBoundaryPillars: values['bsBoundaryPillars'] ?? '',
      blockEncroachments: values['bsEncroachments'] ?? '',
      blockTrespassing: values['bsTrespassing'] ?? '',
      blockSuiGasCrossing: values['bsSuiGasCrossing'] ?? '',
      blockElectricCrossing: values['bsElectricCrossing'] ?? '',
      blockUnderPass: values['bsUnderPass'] ?? '',
      blockCableCrossings: values['bsCableCrossings'] ?? '',
      blockOverheadBridges: values['bsOverheadBridges'] ?? '',
      inspectedBy: state.inspectedBy ?? '',
      inspectedByDesignation: state.designation ?? '',
      pwiInCharge: state.pwiIncharge ?? '',
      verifiedBy: state.verifiedBy ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inspecting_officer_name_designation': inspectingOfficerNameDesignation,
      'inspection_date': inspectionDate,
      'section_from': sectionFrom,
      'section_to': sectionTo,
      'km_from': kmFrom,
      'km_to': kmTo,
      'alignment_reading_mm': alignmentReadingMm,
      'alignment_out_of_limit': alignmentOutOfLimit,
      'gauge_speed_category': gaugeSpeedCategory,
      'gauge_reading_mm': gaugeReadingMm,
      'gauge_out_of_limit': gaugeOutOfLimit,
      'cross_level_reading_mm': crossLevelReadingMm,
      'cross_level_out_of_limit': crossLevelOutOfLimit,
      'rail_type': railType,
      'rail_remarks': railRemarks,
      'sleeper_type': sleeperType,
      'sleeper_track_type': sleeperTrackType,
      'sleeper_season': sleeperSeason,
      'sleeper_us_pct_recorded_speed_kmph': sleeperUsPctRecordedSpeedKmph,
      'fittings_fitting_type': fittingsFittingType,
      'fittings_track_type': fittingsTrackType,
      'fittings_season': fittingsSeason,
      'fittings_us_pct_recorded_speed_kmph': fittingsUsPctRecordedSpeedKmph,
      'ballast_cushion': ballastCushion,
      'ballast_remedy': ballastRemedy,
      'embankment_dimension': embankmentDimension,
      'embankment_condition': embankmentCondition,
      'embankment_remedy': embankmentRemedy,
      'drainage_type': drainageType,
      'drainage_condition': drainageCondition,
      'drainage_remedy': drainageRemedy,
      'joints': joints,
      'joints_remedy': jointsRemedy,
      'oiling_graphitting_fish_plated_joints':
          oilingGraphittingFishPlatedJoints,
      'oiling_graphitting_remedy': oilingGraphittingRemedy,
      'trespassing': trespassing,
      'trespassing_remedy': trespassingRemedy,
      'curve_no': curveNo,
      'degree_of_curve': degreeOfCurve,
      'curve_speed_kmph': curveSpeedKmph,
      'gauge_on_curve_reading_mm': gaugeOnCurveReadingMm,
      'gauge_on_curve_out_of_limit': gaugeOnCurveOutOfLimit,
      'super_elevation_reading_mm': superElevationReadingMm,
      'super_elevation_action': superElevationAction,
      'curve_post_standard_1000': curvePostStandard1000,
      'check_rail_clearance_6_deg_above': checkRailClearance6DegAbove,
      'check_rail_clearance_status': checkRailClearanceStatus,
      'points_gauge': pointsGauge,
      'points_cross_level': pointsCrossLevel,
      'points_fittings_pct': pointsFittingsPct,
      'wear_of_switch_action': wearOfSwitchAction,
      'wear_of_switch_reason': wearOfSwitchReason,
      'wear_of_crossing_action': wearOfCrossingAction,
      'wear_of_crossing_reason': wearOfCrossingReason,
      'check_rails_clearance_standard_45': checkRailsClearanceStandard45,
      'wing_rail_clearance_standard_45_47': wingRailClearanceStandard4547,
      'crossing_timbers_us_pct': crossingTimbersUsPct,
      'crossing_timbers_action': crossingTimbersAction,
      'crossing_timbers_reason': crossingTimbersReason,
      'bridges_scouring': bridgesScouring,
      'bridges_brick_masonry': bridgesBrickMasonry,
      'bridges_flooring_apron': bridgesFlooringApron,
      'bridges_abutment': bridgesAbutment,
      'bridges_pier': bridgesPier,
      'bridges_foundation': bridgesFoundation,
      'bridges_wing_wall': bridgesWingWall,
      'bridges_drop_wall': bridgesDropWall,
      'bridges_curtain_wall': bridgesCurtainWall,
      'bridges_water_ways': bridgesWaterWays,
      'bridges_settlement_of_substructure': bridgesSettlementOfSubstructure,
      'bridges_earth_excavation_stream_sides':
          bridgesEarthExcavationStreamSides,
      'bridges_super_gauge': bridgesSuperGauge,
      'bridges_super_cross_level': bridgesSuperCrossLevel,
      'bridges_super_rattling': bridgesSuperRattling,
      'bridges_super_guard_rails': bridgesSuperGuardRails,
      'bridges_super_gangway': bridgesSuperGangway,
      'bridges_super_girder_bridge_painting': bridgesSuperGirderBridgePainting,
      'bridges_super_bearing_oiling_record': bridgesSuperBearingOilingRecord,
      'bridges_super_ballast_wall_clearance': bridgesSuperBallastWallClearance,
      'bridges_super_bed_stones': bridgesSuperBedStones,
      'bridges_super_bridge_approaches': bridgesSuperBridgeApproaches,
      'bridges_super_bridge_timbers_us_pct': bridgesSuperBridgeTimbersUsPct,
      'bridges_super_bridge_timbers_squaring_spacing':
          bridgesSuperBridgeTimbersSquaringSpacing,
      'bridges_super_holding_down_bolts': bridgesSuperHoldingDownBolts,
      'lc_manned_km_from': lcMannedKmFrom,
      'lc_manned_km_to': lcMannedKmTo,
      'lc_manned_gate_signals': lcMannedGateSignals,
      'lc_manned_telecom_system': lcMannedTelecomSystem,
      'lc_manned_interlocking': lcMannedInterlocking,
      'lc_manned_gauge': lcMannedGauge,
      'lc_manned_cross_level': lcMannedCrossLevel,
      'lc_manned_track_approaches': lcMannedTrackApproaches,
      'lc_manned_gate_leaves': lcMannedGateLeaves,
      'lc_manned_warning_whistle_boards': lcMannedWarningWhistleBoards,
      'lc_manned_sd_board': lcMannedSdBoard,
      'lc_manned_road_surfacing': lcMannedRoadSurfacing,
      'lc_manned_check_rail_clearance_horizontal':
          lcMannedCheckRailClearanceHorizontal,
      'lc_manned_check_rail_depth_vertical': lcMannedCheckRailDepthVertical,
      'lc_manned_distance_blocks': lcMannedDistanceBlocks,
      'lc_manned_level_crossing_equipment': lcMannedLevelCrossingEquipment,
      'lc_manned_turn_style': lcMannedTurnStyle,
      'lc_manned_gatekeeper_safety_knowledge':
          lcMannedGatekeeperSafetyKnowledge,
      'lc_manned_inspection_record': lcMannedInspectionRecord,
      'lc_manned_visibility': lcMannedVisibility,
      'lc_manned_fencing': lcMannedFencing,
      'lc_unmanned_km_from': lcUnmannedKmFrom,
      'lc_unmanned_km_to': lcUnmannedKmTo,
      'lc_unmanned_gauge': lcUnmannedGauge,
      'lc_unmanned_cross_level': lcUnmannedCrossLevel,
      'lc_unmanned_track_approaches': lcUnmannedTrackApproaches,
      'lc_unmanned_warning_whistle_boards': lcUnmannedWarningWhistleBoards,
      'lc_unmanned_speed_breakers': lcUnmannedSpeedBreakers,
      'lc_unmanned_road_surface': lcUnmannedRoadSurface,
      'lc_unmanned_check_rail_clearance_horizontal':
          lcUnmannedCheckRailClearanceHorizontal,
      'lc_unmanned_check_rail_depth_vertical': lcUnmannedCheckRailDepthVertical,
      'lc_unmanned_distance_blocks': lcUnmannedDistanceBlocks,
      'lc_unmanned_visibility': lcUnmannedVisibility,
      'tunnel_portal': tunnelPortal,
      'tunnel_roof_crown': tunnelRoofCrown,
      'tunnel_wall_lining': tunnelWallLining,
      'tunnel_invert_floor': tunnelInvertFloor,
      'tunnel_weep_holes': tunnelWeepHoles,
      'tunnel_side_drains': tunnelSideDrains,
      'tunnel_refuges': tunnelRefuges,
      'tunnel_roof_top_drain': tunnelRoofTopDrain,
      'tunnel_walkway': tunnelWalkway,
      'tunnel_ventilation_shaft': tunnelVentilationShaft,
      'tunnel_horizontal_clearance': tunnelHorizontalClearance,
      'tunnel_vertical_clearance': tunnelVerticalClearance,
      'tunnel_track_gauge': tunnelTrackGauge,
      'tunnel_track_cross_level': tunnelTrackCrossLevel,
      'tunnel_track_alignment': tunnelTrackAlignment,
      'tunnel_magnified_glass': tunnelMagnifiedGlass,
      'station_bldg_name': stationBldgName,
      'station_bldg_km': stationBldgKm,
      'station_bldg_section': stationBldgSection,
      'station_bldg_approach': stationBldgApproach,
      'station_bldg_facade': stationBldgFacade,
      'station_bldg_roof_type': stationBldgRoofType,
      'station_bldg_roof_condition': stationBldgRoofCondition,
      'station_bldg_roof_drainage': stationBldgRoofDrainage,
      'station_bldg_waiting_rooms': stationBldgWaitingRooms,
      'station_bldg_washroom': stationBldgWashroom,
      'station_bldg_doors': stationBldgDoors,
      'station_bldg_windows': stationBldgWindows,
      'station_bldg_painting': stationBldgPainting,
      'station_bldg_platforms': stationBldgPlatforms,
      'station_bldg_foot_over_bridges': stationBldgFootOverBridges,
      'station_bldg_shelters': stationBldgShelters,
      'station_bldg_watering_arrangements': stationBldgWateringArrangements,
      'station_bldg_sewerage': stationBldgSewerage,
      'station_bldg_signaling_cabins': stationBldgSignalingCabins,
      'station_bldg_escalator': stationBldgEscalator,
      'yards_gauge': yardsGauge,
      'yards_cross_level': yardsCrossLevel,
      'yards_sleepers_us_pct': yardsSleepersUsPct,
      'yards_ballast': yardsBallast,
      'yards_loops': yardsLoops,
      'yards_signaling': yardsSignaling,
      'yards_washing_lines': yardsWashingLines,
      'yards_sick_line': yardsSickLine,
      'yards_snag_dead_end': yardsSnagDeadEnd,
      'block_boundary_pillars': blockBoundaryPillars,
      'block_encroachments': blockEncroachments,
      'block_trespassing': blockTrespassing,
      'block_sui_gas_crossing': blockSuiGasCrossing,
      'block_electric_crossing': blockElectricCrossing,
      'block_under_pass': blockUnderPass,
      'block_cable_crossings': blockCableCrossings,
      'block_overhead_bridges': blockOverheadBridges,
      'inspected_by': inspectedBy,
      'inspected_by_designation': inspectedByDesignation,
      'pwi_in_charge': pwiInCharge,
      'verified_by': verifiedBy,
    };
  }

  factory MotorTrolleyInspectionSubmitModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MotorTrolleyInspectionSubmitModel(
      inspectingOfficerNameDesignation:
          json['inspecting_officer_name_designation']?.toString() ?? '',
      inspectionDate: json['inspection_date']?.toString() ?? '',
      sectionFrom: json['section_from']?.toString() ?? '',
      sectionTo: json['section_to']?.toString() ?? '',
      kmFrom: _parseDouble(json['km_from']),
      kmTo: _parseDouble(json['km_to']),
      alignmentReadingMm: _parseDouble(json['alignment_reading_mm']),
      alignmentOutOfLimit: json['alignment_out_of_limit']?.toString() ?? '',
      gaugeSpeedCategory: json['gauge_speed_category']?.toString() ?? '',
      gaugeReadingMm: _parseDouble(json['gauge_reading_mm']),
      gaugeOutOfLimit: json['gauge_out_of_limit']?.toString() ?? '',
      crossLevelReadingMm: _parseDouble(json['cross_level_reading_mm']),
      crossLevelOutOfLimit: json['cross_level_out_of_limit']?.toString() ?? '',
      railType: json['rail_type']?.toString() ?? '',
      railRemarks: json['rail_remarks']?.toString() ?? '',
      sleeperType: json['sleeper_type']?.toString() ?? '',
      sleeperTrackType: json['sleeper_track_type']?.toString() ?? '',
      sleeperSeason: json['sleeper_season']?.toString() ?? '',
      sleeperUsPctRecordedSpeedKmph:
          json['sleeper_us_pct_recorded_speed_kmph']?.toString() ?? '',
      fittingsFittingType: json['fittings_fitting_type']?.toString() ?? '',
      fittingsTrackType: json['fittings_track_type']?.toString() ?? '',
      fittingsSeason: json['fittings_season']?.toString() ?? '',
      fittingsUsPctRecordedSpeedKmph:
          json['fittings_us_pct_recorded_speed_kmph']?.toString() ?? '',
      ballastCushion: json['ballast_cushion']?.toString() ?? '',
      ballastRemedy: json['ballast_remedy']?.toString() ?? '',
      embankmentDimension: json['embankment_dimension']?.toString() ?? '',
      embankmentCondition: json['embankment_condition']?.toString() ?? '',
      embankmentRemedy: json['embankment_remedy']?.toString() ?? '',
      drainageType: json['drainage_type']?.toString() ?? '',
      drainageCondition: json['drainage_condition']?.toString() ?? '',
      drainageRemedy: json['drainage_remedy']?.toString() ?? '',
      joints: json['joints']?.toString() ?? '',
      jointsRemedy: json['joints_remedy']?.toString() ?? '',
      oilingGraphittingFishPlatedJoints:
          json['oiling_graphitting_fish_plated_joints']?.toString() ?? '',
      oilingGraphittingRemedy:
          json['oiling_graphitting_remedy']?.toString() ?? '',
      trespassing: json['trespassing']?.toString() ?? '',
      trespassingRemedy: json['trespassing_remedy']?.toString() ?? '',
      curveNo: json['curve_no']?.toString() ?? '',
      degreeOfCurve: json['degree_of_curve']?.toString() ?? '',
      curveSpeedKmph: json['curve_speed_kmph']?.toString() ?? '',
      gaugeOnCurveReadingMm: _parseDouble(json['gauge_on_curve_reading_mm']),
      gaugeOnCurveOutOfLimit:
          json['gauge_on_curve_out_of_limit']?.toString() ?? '',
      superElevationReadingMm: _parseDouble(json['super_elevation_reading_mm']),
      superElevationAction: json['super_elevation_action']?.toString() ?? '',
      curvePostStandard1000: json['curve_post_standard_1000']?.toString() ?? '',
      checkRailClearance6DegAbove:
          json['check_rail_clearance_6_deg_above']?.toString() ?? '',
      checkRailClearanceStatus:
          json['check_rail_clearance_status']?.toString() ?? '',
      pointsGauge: json['points_gauge']?.toString() ?? '',
      pointsCrossLevel: json['points_cross_level']?.toString() ?? '',
      pointsFittingsPct: _parseDouble(json['points_fittings_pct']),
      wearOfSwitchAction: json['wear_of_switch_action']?.toString() ?? '',
      wearOfSwitchReason: json['wear_of_switch_reason']?.toString() ?? '',
      wearOfCrossingAction: json['wear_of_crossing_action']?.toString() ?? '',
      wearOfCrossingReason: json['wear_of_crossing_reason']?.toString() ?? '',
      checkRailsClearanceStandard45: _parseDouble(
        json['check_rails_clearance_standard_45'],
      ),
      wingRailClearanceStandard4547: _parseDouble(
        json['wing_rail_clearance_standard_45_47'],
      ),
      crossingTimbersUsPct: _parseDouble(json['crossing_timbers_us_pct']),
      crossingTimbersAction: json['crossing_timbers_action']?.toString() ?? '',
      crossingTimbersReason: json['crossing_timbers_reason']?.toString() ?? '',
      bridgesScouring: json['bridges_scouring']?.toString() ?? '',
      bridgesBrickMasonry: json['bridges_brick_masonry']?.toString() ?? '',
      bridgesFlooringApron: json['bridges_flooring_apron']?.toString() ?? '',
      bridgesAbutment: json['bridges_abutment']?.toString() ?? '',
      bridgesPier: json['bridges_pier']?.toString() ?? '',
      bridgesFoundation: json['bridges_foundation']?.toString() ?? '',
      bridgesWingWall: json['bridges_wing_wall']?.toString() ?? '',
      bridgesDropWall: json['bridges_drop_wall']?.toString() ?? '',
      bridgesCurtainWall: json['bridges_curtain_wall']?.toString() ?? '',
      bridgesWaterWays: json['bridges_water_ways']?.toString() ?? '',
      bridgesSettlementOfSubstructure:
          json['bridges_settlement_of_substructure']?.toString() ?? '',
      bridgesEarthExcavationStreamSides:
          json['bridges_earth_excavation_stream_sides']?.toString() ?? '',
      bridgesSuperGauge: json['bridges_super_gauge']?.toString() ?? '',
      bridgesSuperCrossLevel:
          json['bridges_super_cross_level']?.toString() ?? '',
      bridgesSuperRattling: json['bridges_super_rattling']?.toString() ?? '',
      bridgesSuperGuardRails:
          json['bridges_super_guard_rails']?.toString() ?? '',
      bridgesSuperGangway: json['bridges_super_gangway']?.toString() ?? '',
      bridgesSuperGirderBridgePainting:
          json['bridges_super_girder_bridge_painting']?.toString() ?? '',
      bridgesSuperBearingOilingRecord:
          json['bridges_super_bearing_oiling_record']?.toString() ?? '',
      bridgesSuperBallastWallClearance:
          json['bridges_super_ballast_wall_clearance']?.toString() ?? '',
      bridgesSuperBedStones: json['bridges_super_bed_stones']?.toString() ?? '',
      bridgesSuperBridgeApproaches:
          json['bridges_super_bridge_approaches']?.toString() ?? '',
      bridgesSuperBridgeTimbersUsPct: _parseDouble(
        json['bridges_super_bridge_timbers_us_pct'],
      ),
      bridgesSuperBridgeTimbersSquaringSpacing:
          json['bridges_super_bridge_timbers_squaring_spacing']?.toString() ??
          '',
      bridgesSuperHoldingDownBolts:
          json['bridges_super_holding_down_bolts']?.toString() ?? '',
      lcMannedKmFrom: _parseDouble(json['lc_manned_km_from']),
      lcMannedKmTo: _parseDouble(json['lc_manned_km_to']),
      lcMannedGateSignals: json['lc_manned_gate_signals']?.toString() ?? '',
      lcMannedTelecomSystem: json['lc_manned_telecom_system']?.toString() ?? '',
      lcMannedInterlocking: json['lc_manned_interlocking']?.toString() ?? '',
      lcMannedGauge: json['lc_manned_gauge']?.toString() ?? '',
      lcMannedCrossLevel: json['lc_manned_cross_level']?.toString() ?? '',
      lcMannedTrackApproaches:
          json['lc_manned_track_approaches']?.toString() ?? '',
      lcMannedGateLeaves: json['lc_manned_gate_leaves']?.toString() ?? '',
      lcMannedWarningWhistleBoards:
          json['lc_manned_warning_whistle_boards']?.toString() ?? '',
      lcMannedSdBoard: json['lc_manned_sd_board']?.toString() ?? '',
      lcMannedRoadSurfacing: json['lc_manned_road_surfacing']?.toString() ?? '',
      lcMannedCheckRailClearanceHorizontal: _parseDouble(
        json['lc_manned_check_rail_clearance_horizontal'],
      ),
      lcMannedCheckRailDepthVertical: _parseDouble(
        json['lc_manned_check_rail_depth_vertical'],
      ),
      lcMannedDistanceBlocks:
          json['lc_manned_distance_blocks']?.toString() ?? '',
      lcMannedLevelCrossingEquipment:
          json['lc_manned_level_crossing_equipment']?.toString() ?? '',
      lcMannedTurnStyle: json['lc_manned_turn_style']?.toString() ?? '',
      lcMannedGatekeeperSafetyKnowledge:
          json['lc_manned_gatekeeper_safety_knowledge']?.toString() ?? '',
      lcMannedInspectionRecord:
          json['lc_manned_inspection_record']?.toString() ?? '',
      lcMannedVisibility: json['lc_manned_visibility']?.toString() ?? '',
      lcMannedFencing: json['lc_manned_fencing']?.toString() ?? '',
      lcUnmannedKmFrom: _parseDouble(json['lc_unmanned_km_from']),
      lcUnmannedKmTo: _parseDouble(json['lc_unmanned_km_to']),
      lcUnmannedGauge: json['lc_unmanned_gauge']?.toString() ?? '',
      lcUnmannedCrossLevel: json['lc_unmanned_cross_level']?.toString() ?? '',
      lcUnmannedTrackApproaches:
          json['lc_unmanned_track_approaches']?.toString() ?? '',
      lcUnmannedWarningWhistleBoards:
          json['lc_unmanned_warning_whistle_boards']?.toString() ?? '',
      lcUnmannedSpeedBreakers:
          json['lc_unmanned_speed_breakers']?.toString() ?? '',
      lcUnmannedRoadSurface: json['lc_unmanned_road_surface']?.toString() ?? '',
      lcUnmannedCheckRailClearanceHorizontal: _parseDouble(
        json['lc_unmanned_check_rail_clearance_horizontal'],
      ),
      lcUnmannedCheckRailDepthVertical: _parseDouble(
        json['lc_unmanned_check_rail_depth_vertical'],
      ),
      lcUnmannedDistanceBlocks:
          json['lc_unmanned_distance_blocks']?.toString() ?? '',
      lcUnmannedVisibility: json['lc_unmanned_visibility']?.toString() ?? '',
      tunnelPortal: json['tunnel_portal']?.toString() ?? '',
      tunnelRoofCrown: json['tunnel_roof_crown']?.toString() ?? '',
      tunnelWallLining: json['tunnel_wall_lining']?.toString() ?? '',
      tunnelInvertFloor: json['tunnel_invert_floor']?.toString() ?? '',
      tunnelWeepHoles: json['tunnel_weep_holes']?.toString() ?? '',
      tunnelSideDrains: json['tunnel_side_drains']?.toString() ?? '',
      tunnelRefuges: json['tunnel_refuges']?.toString() ?? '',
      tunnelRoofTopDrain: json['tunnel_roof_top_drain']?.toString() ?? '',
      tunnelWalkway: json['tunnel_walkway']?.toString() ?? '',
      tunnelVentilationShaft:
          json['tunnel_ventilation_shaft']?.toString() ?? '',
      tunnelHorizontalClearance:
          json['tunnel_horizontal_clearance']?.toString() ?? '',
      tunnelVerticalClearance:
          json['tunnel_vertical_clearance']?.toString() ?? '',
      tunnelTrackGauge: json['tunnel_track_gauge']?.toString() ?? '',
      tunnelTrackCrossLevel: json['tunnel_track_cross_level']?.toString() ?? '',
      tunnelTrackAlignment: json['tunnel_track_alignment']?.toString() ?? '',
      tunnelMagnifiedGlass: json['tunnel_magnified_glass']?.toString() ?? '',
      stationBldgName: json['station_bldg_name']?.toString() ?? '',
      stationBldgKm: _parseDouble(json['station_bldg_km']),
      stationBldgSection: json['station_bldg_section']?.toString() ?? '',
      stationBldgApproach: json['station_bldg_approach']?.toString() ?? '',
      stationBldgFacade: json['station_bldg_facade']?.toString() ?? '',
      stationBldgRoofType: json['station_bldg_roof_type']?.toString() ?? '',
      stationBldgRoofCondition:
          json['station_bldg_roof_condition']?.toString() ?? '',
      stationBldgRoofDrainage:
          json['station_bldg_roof_drainage']?.toString() ?? '',
      stationBldgWaitingRooms:
          json['station_bldg_waiting_rooms']?.toString() ?? '',
      stationBldgWashroom: json['station_bldg_washroom']?.toString() ?? '',
      stationBldgDoors: json['station_bldg_doors']?.toString() ?? '',
      stationBldgWindows: json['station_bldg_windows']?.toString() ?? '',
      stationBldgPainting: json['station_bldg_painting']?.toString() ?? '',
      stationBldgPlatforms: json['station_bldg_platforms']?.toString() ?? '',
      stationBldgFootOverBridges:
          json['station_bldg_foot_over_bridges']?.toString() ?? '',
      stationBldgShelters: json['station_bldg_shelters']?.toString() ?? '',
      stationBldgWateringArrangements:
          json['station_bldg_watering_arrangements']?.toString() ?? '',
      stationBldgSewerage: json['station_bldg_sewerage']?.toString() ?? '',
      stationBldgSignalingCabins:
          json['station_bldg_signaling_cabins']?.toString() ?? '',
      stationBldgEscalator: json['station_bldg_escalator']?.toString() ?? '',
      yardsGauge: json['yards_gauge']?.toString() ?? '',
      yardsCrossLevel: json['yards_cross_level']?.toString() ?? '',
      yardsSleepersUsPct: _parseDouble(json['yards_sleepers_us_pct']),
      yardsBallast: json['yards_ballast']?.toString() ?? '',
      yardsLoops: json['yards_loops']?.toString() ?? '',
      yardsSignaling: json['yards_signaling']?.toString() ?? '',
      yardsWashingLines: json['yards_washing_lines']?.toString() ?? '',
      yardsSickLine: json['yards_sick_line']?.toString() ?? '',
      yardsSnagDeadEnd: json['yards_snag_dead_end']?.toString() ?? '',
      blockBoundaryPillars: json['block_boundary_pillars']?.toString() ?? '',
      blockEncroachments: json['block_encroachments']?.toString() ?? '',
      blockTrespassing: json['block_trespassing']?.toString() ?? '',
      blockSuiGasCrossing: json['block_sui_gas_crossing']?.toString() ?? '',
      blockElectricCrossing: json['block_electric_crossing']?.toString() ?? '',
      blockUnderPass: json['block_under_pass']?.toString() ?? '',
      blockCableCrossings: json['block_cable_crossings']?.toString() ?? '',
      blockOverheadBridges: json['block_overhead_bridges']?.toString() ?? '',
      inspectedBy: json['inspected_by']?.toString() ?? '',
      inspectedByDesignation:
          json['inspected_by_designation']?.toString() ?? '',
      pwiInCharge: json['pwi_in_charge']?.toString() ?? '',
      verifiedBy: json['verified_by']?.toString() ?? '',
    );
  }

  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      if (val.trim().isEmpty) return null;
      return double.tryParse(val.trim());
    }
    return null;
  }
}
