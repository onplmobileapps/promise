// inspection_param_configs.dart
//
// Config-driven field definitions for the repetitive
// "Parameter | Standard | Actual | Remedy" tables in the Motor Trolley
// Inspection Proforma (Bridges, Level Crossings, Tunnel, Station Buildings,
// Yards, Block Sections, plus the Sleeper/Fittings/Ballast/Embankment/
// Drainage/Joints/Oiling/Trespassing sub-parts of Track Geometry).
//
// New parameters are added here, not in the widget tree — the
// `_ParamRow` widget in the screen renders whatever this file describes.

/// How the "Actual" value for a parameter should be captured.
enum ParamInputType { dropdown, text, number }

class ParamField {
  final String key; // unique key into state.values
  final String label;
  final String? standard; // static reference text shown under the label
  final ParamInputType type;
  final List<String>? options; // for dropdown
  final List<String>? remedyOptions; // second dropdown, if any
  final String? remedyStatic; // static remedy text instead of a dropdown
  final String? hint;

  const ParamField({
    required this.key,
    required this.label,
    this.standard,
    this.type = ParamInputType.dropdown,
    this.options,
    this.remedyOptions,
    this.remedyStatic,
    this.hint,
  });
}

class ParamSection {
  final String title;
  final List<ParamField> fields;
  final bool initiallyExpanded;
  const ParamSection({
    required this.title,
    required this.fields,
    this.initiallyExpanded = false,
  });
}

// ── I. Track Geometry — remaining sub-parts (v–ix, IIX) ────────────────
// Rendered inline inside the existing "I. Track Geometry" expansion tile.
const List<ParamField> trackGeometryExtraFields = [
  ParamField(
    key: 'sleeperType',
    label: 'Sleeper Type',
    standard: 'Standard: 100% Fit',
    options: ['PSC', 'RCC', 'Wooden', 'Steel Trough', 'Metal'],
  ),
  ParamField(
    key: 'sleeperTrackType',
    label: 'Track Type',
    options: ['Welded Track', 'Welded & Jointed Track'],
  ),
  ParamField(
    key: 'sleeperSeason',
    label: 'Season',
    options: ['Summer (Mid MAR to Mid OCT)', 'Winter (Mid OCT to Mid MAR)'],
  ),
  ParamField(
    key: 'sleeperUsPercentage',
    label: 'US % / Recorded Speed (KMPH)',
    type: ParamInputType.number,
    hint: 'e.g. 25 or 55',
  ),
  ParamField(
    key: 'fittingType',
    label: 'Fitting Type',
    standard: 'Standard: 100% available and tight',
    options: ['W-14', 'RN', 'Others'],
  ),
  ParamField(
    key: 'fittingTrackType',
    label: 'Track Type',
    options: ['Welded Track', 'Welded & Jointed Track'],
  ),
  ParamField(
    key: 'fittingSeason',
    label: 'Season',
    options: ['Summer (Mid MAR to Mid OCT)', 'Winter (Mid OCT to Mid MAR)'],
  ),
  ParamField(
    key: 'fittingUsPercentage',
    label: 'US % / Recorded Speed (KMPH)',
    type: ParamInputType.number,
    hint: 'e.g. 25 or 55',
  ),
  ParamField(
    key: 'ballastCushion',
    label: 'Ballast Cushion',
    options: ['12"', '8-10"', '6-8"', 'Less than 6"'],
    remedyOptions: [
      'Ideal',
      'Within limit',
      'Fouled/Rolled down - recoupment & Deep Screening',
      'Re-Ballasting',
    ],
  ),
  ParamField(
    key: 'embankmentDimension',
    label: 'Embankment Dimension',
    options: [
      "24' with 2750mm Sleeper (Single Line)",
      "22' with 2600mm Sleeper (Single Line)",
      "39.5' with 2750mm Sleeper (Double Line)",
      "37.5' with 2600mm Sleeper (Double Line)",
    ],
  ),
  ParamField(
    key: 'embankmentCondition',
    label: 'Embankment Condition',
    options: ['Standard', 'Short (1-5 RH/LH)', 'Worst (More than 5 RH/LH)'],
    remedyOptions: ['Ideal', 'Recoupment', 'Immediate Recoupment'],
  ),
  ParamField(
    key: 'drainageType',
    label: 'Drainage Type',
    options: ['Cross Drain', 'Longitudinal'],
  ),
  ParamField(
    key: 'drainageCondition',
    label: 'Drainage Condition',
    options: ['Available', 'Not Available'],
    remedyOptions: ['Clean', 'Blocked'],
  ),
  ParamField(
    key: 'jointsCondition',
    label: 'Joints',
    options: ['Leveled', 'Low', 'Excessive Gap'],
    remedyOptions: ['Satisfactory', 'Not satisfactory'],
  ),
  ParamField(
    key: 'oilingGraphitting',
    label: 'Oiling & Graphitting of Fish Plated Joints',
    options: ['Yes', 'No'],
    remedyOptions: ['Even Year', 'Odd Year'],
  ),
  ParamField(
    key: 'trespassing',
    label: 'Trespassing',
    options: ['Yes', 'No'],
    remedyOptions: ['Fencing Provided', 'Trenches Done'],
  ),
];

// ── 4. Bridges ───────────────────────────────────────────────────────
const List<ParamField> bridgeSubStructureFields = [
  ParamField(
    key: 'bridgeScouring',
    label: 'Scouring',
    standard: 'Standard: No Scouring',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Refilling with Pitching Stone',
  ),
  ParamField(
    key: 'bridgeBrickMasonry',
    label: 'Brick Masonry',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need Repair / Replacement',
  ),
  ParamField(
    key: 'bridgeFlooringApron',
    label: 'Flooring / Apron',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeAbutment',
    label: 'Abutment',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgePier',
    label: 'Pier',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeFoundation',
    label: 'Foundation',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeWingWall',
    label: 'Wing Wall',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeDropWall',
    label: 'Drop Wall',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeCurtainWall',
    label: 'Curtain Wall',
    standard: 'Standard: Good Condition',
    options: ['Satisfactory', 'Unsatisfactory'],
  ),
  ParamField(
    key: 'bridgeWaterWays',
    label: 'Water Ways',
    standard: 'Standard: Clear',
    options: ['Clear', 'Obstructed', 'Blocked'],
    remedyStatic: 'Clear water way',
  ),
  ParamField(
    key: 'bridgeSettlement',
    label: 'Settlement of Sub-structure',
    standard: 'Standard: No Settlement',
    options: ['Yes', 'No'],
    remedyStatic: 'Reconstruction',
  ),
  ParamField(
    key: 'bridgeEarthExcavation',
    label: 'Earth Excavation on Up & Dn Stream Sides',
    standard: 'Standard: No excavation within 500 ft on Up & Dn Stream side',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Immediate refilling of Dip',
  ),
];

const List<ParamField> bridgeSuperStructureFields = [
  ParamField(
    key: 'bridgeGauge',
    label: 'Gauge',
    standard: 'Standard: 1676 mm',
    options: ['Exact', 'Slack', 'Tight'],
    remedyStatic: 'Re-adjustment',
  ),
  ParamField(
    key: 'bridgeCrossLevel',
    label: 'Cross Level',
    standard: 'Standard: Exact',
    options: ['Exact', 'Out'],
    remedyStatic: 'Re-adjustment',
  ),
  ParamField(
    key: 'bridgeRattling',
    label: 'Rattling',
    standard: 'Standard: No Retiling',
    options: ['Yes', 'No'],
    remedyStatic: 'Re-adjustment',
  ),
  ParamField(
    key: 'bridgeGuardRails',
    label: 'Guard Rails',
    standard: 'Standard: 250 mm',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'bridgeGangway',
    label: 'Gangway',
    standard: 'Standard: Maintained',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Repair',
  ),
  ParamField(
    key: 'bridgeGirderPainting',
    label: 'Girder Bridge Painting',
    standard: 'Standard: Good',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Re-painting',
  ),
  ParamField(
    key: 'bridgeBearingOiling',
    label: 'Bearing Oiling Record',
    standard: 'Standard: Yes',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Oiling',
  ),
  ParamField(
    key: 'bridgeBallastWallClearance',
    label: 'Ballast Wall Clearance',
    standard: 'Standard: 38 mm',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'bridgeBedStones',
    label: 'Bed Stones',
    standard: 'Standard: Maintained',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'bridgeApproaches',
    label: 'Bridge Approaches',
    standard: 'Standard: Packed',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'bridgeTimbers',
    label: 'Bridge Timbers — US %',
    standard: 'Standard: 100% Serviceable',
    type: ParamInputType.number,
    remedyStatic: 'Need Replacement',
  ),
  ParamField(
    key: 'bridgeTimberSquaring',
    label: 'Bridge Timbers Squaring / Spacing',
    standard: 'Standard: All Square',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Squaring',
  ),
  ParamField(
    key: 'bridgeHoldingDownBolts',
    label: 'Holding-down Bolts',
    standard: 'Standard: 100%',
    options: ['Tight', 'Loose', 'Arrow Position Correct'],
    remedyStatic: 'Need Adjustment',
  ),
];

// ── 5. Level Crossings (Manned) ─────────────────────────────────────
const List<ParamField> levelCrossingMannedFields = [
  ParamField(
    key: 'lcGateSignals',
    label: 'Gate Signals',
    standard: 'Standard: Good Condition',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'lcTelecomSystem',
    label: 'Telecommunication System',
    standard: 'Standard: Good',
    options: ['Magneto', 'Bell', 'Other'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'lcInterlocking',
    label: 'Interlocking',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
  ),
  ParamField(
    key: 'lcGauge',
    label: 'Gauge',
    standard: 'Standard: 1676',
    options: ['Exact', 'Slack', 'Tight'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcCrossLevel',
    label: 'Cross Level',
    standard: 'Standard: Exact',
    options: ['Exact', 'Out'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcTrackApproaches',
    label: 'Track Approaches',
    standard: 'Standard: Level',
    options: ['Level', 'Grade'],
  ),
  ParamField(
    key: 'lcGateLeaves',
    label: 'Gate Leaves',
    standard: 'Standard: Good Maintained',
    options: ['Good', 'Fair', 'Poor'],
  ),
  ParamField(
    key: 'lcWarningBoards',
    label: 'Warning / Whistle Boards',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
    remedyStatic: 'Be provided',
  ),
  ParamField(
    key: 'lcSdBoard',
    label: 'SD Board',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
    remedyStatic: 'Be provided',
  ),
  ParamField(
    key: 'lcRoadSurfacing',
    label: 'Road Surfacing',
    standard: 'Standard: Good',
    options: ['Maintained', 'Not Maintained'],
    remedyStatic: 'Maintained',
  ),
  ParamField(
    key: 'lcCheckRailClearanceH',
    label: 'Check Rail Clearance (Horizontal)',
    standard: 'Standard: 50–57 mm',
    type: ParamInputType.number,
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcCheckRailDepthV',
    label: 'Check Rail Depth (Vertical)',
    standard: 'Standard: 38 mm',
    type: ParamInputType.number,
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcDistanceBlocks',
    label: 'Distance Blocks',
    standard: 'Standard: Squared & Tight',
    options: ['Loose', 'Broken', 'Un-squared'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcEquipment',
    label: 'Level Crossing Equipment',
    standard: 'Standard: Complete',
    options: ['Good', 'Need Repair'],
  ),
  ParamField(
    key: 'lcTurnStyle',
    label: 'Turn Style',
    standard: 'Standard: Good Condition',
    options: ['Available', 'Maintained'],
  ),
  ParamField(
    key: 'lcGatekeeperKnowledge',
    label: 'Gatekeeper / Gateman Safety Knowledge',
    standard: 'Standard: Conversant',
    options: ['Conversant', 'Need Coaching'],
  ),
  ParamField(
    key: 'lcInspectionRecord',
    label: 'Inspection Record',
    standard: 'Standard: Maintained',
    options: ['Maintained', 'Not Maintained'],
  ),
  ParamField(
    key: 'lcVisibility',
    label: 'Visibility',
    standard: 'Standard: Good',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Clear obstruction',
  ),
  ParamField(
    key: 'lcFencing',
    label: 'Fencing',
    standard: 'Standard: Good Condition',
    options: ['Available', 'Not Available', 'Maintained'],
  ),
];

// ── 5A. Level Crossings (Un-Manned) ─────────────────────────────────
const List<ParamField> levelCrossingUnmannedFields = [
  ParamField(
    key: 'lcuGauge',
    label: 'Gauge',
    standard: 'Standard: 1676',
    options: ['Exact', 'Slack', 'Tight'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcuCrossLevel',
    label: 'Cross Level',
    standard: 'Standard: Exact',
    options: ['Exact', 'Out'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcuTrackApproaches',
    label: 'Track Approaches',
    standard: 'Standard: Level',
    options: ['Level', 'Grade'],
    remedyStatic: 'Level',
  ),
  ParamField(
    key: 'lcuWarningBoards',
    label: 'Warning / Whistle Boards',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
    remedyStatic: 'Be-provided',
  ),
  ParamField(
    key: 'lcuSpeedBreakers',
    label: 'Speed Breakers',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
    remedyStatic: 'Be-provided',
  ),
  ParamField(
    key: 'lcuRoadSurface',
    label: 'Road Surface',
    standard: 'Standard: Maintained',
    options: ['Maintained', 'Not Maintained'],
  ),
  ParamField(
    key: 'lcuCheckRailClearanceH',
    label: 'Check Rail Clearance (Horizontal)',
    standard: 'Standard: 50–57 mm',
    type: ParamInputType.number,
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcuCheckRailDepthV',
    label: 'Check Rail Depth (Vertical)',
    standard: 'Standard: 38 mm',
    type: ParamInputType.number,
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'lcuDistanceBlocks',
    label: 'Distance Blocks',
    standard: 'Standard: Squared & Tight',
    options: ['Loose', 'Broken', 'Un-squared'],
  ),
  ParamField(
    key: 'lcuVisibility',
    label: 'Visibility',
    standard: 'Standard: Good',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Clear obstruction',
  ),
];

// ── 6. Tunnel ────────────────────────────────────────────────────────
const List<ParamField> tunnelFields = [
  ParamField(
    key: 'tunnelPortal',
    label: 'Portal',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Repairing / Replacement',
  ),
  ParamField(
    key: 'tunnelRoofCrown',
    label: 'Roof / Crown',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Repairing / Replacement',
  ),
  ParamField(
    key: 'tunnelWallLining',
    label: 'Wall Lining',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelInvertFloor',
    label: 'Invert / Floor',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelWeepHoles',
    label: 'Weep Holes',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need Cleaning',
  ),
  ParamField(
    key: 'tunnelSideDrains',
    label: 'Side Drains',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need Cleaning',
  ),
  ParamField(
    key: 'tunnelRefuges',
    label: 'Tunnel Refuges',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelRoofTopDrain',
    label: 'Roof Top Drain',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelWalkway',
    label: 'Walkway',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelVentilation',
    label: 'Ventilation / Shaft',
    standard: 'Standard: Maintained',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need repair',
  ),
  ParamField(
    key: 'tunnelHorizontalClearance',
    label: 'Horizontal Clearance',
    standard: 'Standard: 1905 mm',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'tunnelVerticalClearance',
    label: 'Vertical Clearance',
    standard: 'Standard: 5410 mm',
    options: ['Satisfactory', 'Unsatisfactory'],
    remedyStatic: 'Need Maintenance',
  ),
  ParamField(
    key: 'tunnelTrackGauge',
    label: 'Track Gauge',
    standard: 'Standard: 1676',
    options: ['Exact', 'Slack', 'Tight'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'tunnelTrackCrossLevel',
    label: 'Track Cross Level',
    standard: 'Standard: Exact',
    options: ['Exact', 'Out'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'tunnelTrackAlignment',
    label: 'Track Alignment',
    standard: 'Standard: Straight',
    options: ['Straight', 'Kinky'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'tunnelMagnifiedGlass',
    label: 'Magnified Glass',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
    remedyStatic: 'Need Provision',
  ),
];

// ── Station Buildings ────────────────────────────────────────────────
const List<ParamField> stationBuildingFields = [
  ParamField(
    key: 'sbApproach',
    label: 'Approach',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing',
  ),
  ParamField(
    key: 'sbFacade',
    label: 'Facade',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing',
  ),
  ParamField(
    key: 'sbRoofType',
    label: 'Roof Type',
    options: ['Jack Arched', 'RCC', 'Precast Slab'],
  ),
  ParamField(
    key: 'sbRoofCondition',
    label: 'Roof Condition',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Replacement',
  ),
  ParamField(
    key: 'sbRoofDrainage',
    label: 'Roof Drainage',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Cleaning',
  ),
  ParamField(
    key: 'sbWaitingRooms',
    label: 'Waiting Rooms',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbWashroom',
    label: 'Washroom',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbDoors',
    label: 'Doors',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbWindows',
    label: 'Windows',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbPainting',
    label: 'Painting',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Painting',
  ),
  ParamField(
    key: 'sbPlatforms',
    label: 'Platforms',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing',
  ),
  ParamField(
    key: 'sbFootOverBridges',
    label: 'Foot Over Bridges',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Replacement',
  ),
  ParamField(
    key: 'sbShelters',
    label: 'Shelters',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbWateringArrangements',
    label: 'Watering Arrangements',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Make arrangements',
  ),
  ParamField(
    key: 'sbSewerage',
    label: 'Sewerage',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Replacement',
  ),
  ParamField(
    key: 'sbSignalingCabins',
    label: 'Signaling Cabins',
    options: ['Good', 'Fair', 'Poor'],
    remedyStatic: 'Need Repairing / Painting',
  ),
  ParamField(
    key: 'sbEscalator',
    label: 'Escalator',
    standard: 'Standard: Available',
    options: ['Yes', 'No'],
  ),
];

// ── 8. Yards ─────────────────────────────────────────────────────────
const List<ParamField> yardFields = [
  ParamField(
    key: 'yardGauge',
    label: 'Gauge',
    standard: 'Standard: 1676',
    options: ['Exact', 'Slack', 'Tight'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'yardCrossLevel',
    label: 'Cross Level',
    standard: 'Standard: Exact',
    options: ['Exact', 'Out'],
    remedyStatic: 'Need Adjustment',
  ),
  ParamField(
    key: 'yardSleepers',
    label: 'Sleepers — US %',
    standard: 'Standard: 100%',
    type: ParamInputType.number,
    remedyStatic: 'Above 20% need Replacement',
  ),
  ParamField(key: 'yardBallast', label: 'Ballast', type: ParamInputType.text),
  ParamField(key: 'yardLoops', label: 'Loops', type: ParamInputType.text),
  ParamField(
    key: 'yardSignaling',
    label: 'Signaling',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'yardWashingLines',
    label: 'Washing Lines',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'yardSickLine',
    label: 'Sick Line',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'yardSnagDeadEnd',
    label: 'Snag Dead End',
    type: ParamInputType.text,
  ),
];

// ── 9. Block Sections ────────────────────────────────────────────────
const List<ParamField> blockSectionFields = [
  ParamField(
    key: 'bsBoundaryPillars',
    label: 'Boundary Pillars',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsEncroachments',
    label: 'Encroachments',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsTrespassing',
    label: 'Trespassing',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsSuiGasCrossing',
    label: 'Sui Gas Crossing',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsElectricCrossing',
    label: 'Electric Crossing',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsUnderPass',
    label: 'Under Pass',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsCableCrossings',
    label: 'Cable Crossings',
    type: ParamInputType.text,
  ),
  ParamField(
    key: 'bsOverheadBridges',
    label: 'Overhead Bridges',
    type: ParamInputType.text,
  ),
];
