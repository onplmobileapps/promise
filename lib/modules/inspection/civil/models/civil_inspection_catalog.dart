import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';

/// Common, reused option sets (kept centralized so wording stays
/// consistent with the BRD across forms).
class _Opt {
  static const yesNo = ['Yes', 'No'];
  static const intactLoose = ['Intact', 'Loose'];
  static const intactDamaged = ['Intact', 'Damaged'];
  static const satisfactoryNeedRepair = ['Satisfactory', 'Need Repair'];
  static const satisfactoryCorroded = ['Satisfactory', 'Corroded'];
  static const satisfactoryNeedPainting = ['Satisfactory', 'Need Painting'];
  static const tightLoose = ['Tight', 'Loose'];
  static const exactWithinNeedAdjustment = [
    'Exact',
    'Within limit',
    'Need Adjustment',
  ];
  static const correctKinkyNeedAdjustment = [
    'Correct',
    'Kinky',
    'Need Adjustment',
  ];
  static const railCondition = [
    'Serviceable',
    'Ultrasonic Flaw Detective (USFD)',
    'Wheel Burnt',
    'Excessive Wear',
    'End battered',
    'Hogged',
    'Worn Out',
  ];
  static const fittings = [
    'Complete',
    'Tight',
    'Need Adjustment',
    'Need Replacement',
    'Missing',
  ];
  static const unServiceServiceable = ['Un-Service', 'Serviceable'];
  static const goodWearNeedReplacement = ['Good', 'Wear', 'Need Replacement'];
  static const withinLimitNeedAdjustment = ['Within Limit', 'Need Adjustment'];
}

/// Reused sub-groups (rails/fittings/sleepers block repeats verbatim in
/// Turntable, Bridge(Track), Station, Tunnel(Track), Level Crossing).
List<CivilFieldSpec> _trackGeometryFields({
  bool includeRailsAndFittings = true,
}) {
  return [
    CivilFieldSpec.radio('gauge', 'Gauge', _Opt.exactWithinNeedAdjustment),
    CivilFieldSpec.radio(
      'crossLevel',
      'Cross Level',
      _Opt.exactWithinNeedAdjustment,
    ),
    CivilFieldSpec.radio(
      'alignment',
      'Alignment',
      _Opt.correctKinkyNeedAdjustment,
    ),
    if (includeRailsAndFittings) ...[
      CivilFieldSpec.radio('rails', 'Rails', _Opt.railCondition),
      CivilFieldSpec.radio('fittings', 'Fittings', _Opt.fittings),
    ],
  ];
}

/// The "Foundation" repeatable sub-form (opens once per Pier / Abutment).
final List<CivilFieldSpec> _bridgeFoundationTemplate = [
  CivilFieldSpec.radio('scouring', 'Scouring', _Opt.yesNo),
  CivilFieldSpec.radio('silting', 'Silting', _Opt.yesNo),
  CivilFieldSpec.radio(
    'alignmentDisplacement',
    'Alignment Displacement',
    _Opt.yesNo,
  ),
  CivilFieldSpec.radio('levelOut', 'Level Out', _Opt.yesNo),
  CivilFieldSpec.radio('cracks', 'Cracks', _Opt.yesNo),
  CivilFieldSpec.radio(
    'tellTailProvided',
    'Tell Tail Provided',
    _Opt.yesNo,
    conditionKey: 'cracks',
    conditionValue: 'Yes',
  ),
  CivilFieldSpec.radio(
    'tellTailResult',
    'Tell Tail Result',
    const ['Crack Progressive', 'Intact'],
    conditionKey: 'tellTailProvided',
    conditionValue: 'Yes',
  ),
  CivilFieldSpec.radio('shaken', 'Shaken', _Opt.yesNo),
  CivilFieldSpec.radio('crushed', 'Crushed', _Opt.yesNo),
  CivilFieldSpec.radio('bulgedOut', 'Bulged out', _Opt.yesNo),
  CivilFieldSpec.radio('outOfPlumb', 'Out of Plumb', _Opt.yesNo),
  CivilFieldSpec.radio('deterioration', 'Deterioration', _Opt.yesNo),
  CivilFieldSpec.radio('saltPeter', 'Salt Peter', _Opt.yesNo),
  CivilFieldSpec.radio('pointing', 'Pointing', _Opt.intactLoose),
  CivilFieldSpec.radio('waterSeepage', 'Water Seepage', _Opt.yesNo),
];

final List<CivilFieldSpec> _archBridgeFields = [
  CivilFieldSpec.section('For Arch Bridge'),
  CivilFieldSpec.radio('conditionOfBricks', 'Condition of Bricks', const [
    'Good',
    'Damage',
  ]),
  CivilFieldSpec.radio('conditionOfStone', 'Condition of Stone', const [
    'Good',
    'Soft',
  ]),
  CivilFieldSpec.radio('archPointing', 'Pointing', _Opt.intactLoose),
  CivilFieldSpec.radio('bricksAndStone', 'Bricks and Stone', _Opt.intactLoose),
  CivilFieldSpec.radio('bricksMovement', 'Bricks Movement / Sleep', _Opt.yesNo),
  CivilFieldSpec.radio('archRing', 'Arch Ring', const ['Plan', 'Flatten']),
  CivilFieldSpec.radio('archWaterSeepage', 'Water Seepage', _Opt.yesNo),
  CivilFieldSpec.radio('archCracks', 'Cracks', _Opt.yesNo),
  CivilFieldSpec.radio(
    'archTellTailProvided',
    'Tell Tail Provided',
    _Opt.yesNo,
    conditionKey: 'archCracks',
    conditionValue: 'Yes',
  ),
  CivilFieldSpec.radio(
    'archTellTailResult',
    'Tell Tail Result',
    const ['Crack Progressive', 'Intact'],
    conditionKey: 'archTellTailProvided',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _girderBridgeFields = [
  CivilFieldSpec.section('For Girder Bridge'),
  CivilFieldSpec.radio(
    'condConcrete',
    'Condition of Concrete',
    _Opt.satisfactoryNeedRepair,
  ),
  CivilFieldSpec.radio(
    'stoneWoodenBlocks',
    'Stone Wooden Blocks',
    _Opt.satisfactoryNeedRepair,
  ),
  CivilFieldSpec.radio('movementBedStone', 'Movement of Bed Stone', _Opt.yesNo),
  CivilFieldSpec.radio('beddingMasonry', 'Bedding on Masonry', const [
    'Proper',
    'Improper',
  ]),
  CivilFieldSpec.radio('hdBolts', 'HD Bolts', const ['Proper', 'Improper']),
  CivilFieldSpec.radio('ciBearingPads', 'CI Bearing Pads', const [
    'Proper',
    'Improper',
  ]),
  CivilFieldSpec.section('Bearings'),
  CivilFieldSpec.radio('properlySeated', 'Properly Seated', _Opt.yesNo),
  CivilFieldSpec.radio('bearingAlignment', 'Alignment', const [
    'Satisfactory',
    'Not Satisfactory',
  ]),
  CivilFieldSpec.radio('graphiting', 'Graphiting', _Opt.yesNo),
  CivilFieldSpec.radio('locationStrips', 'Location Strips', _Opt.intactDamaged),
  CivilFieldSpec.radio('casing', 'Casing', const ['Intact', 'Missing']),
  CivilFieldSpec.radio('bearingSteel', 'Steel', _Opt.satisfactoryCorroded),
  CivilFieldSpec.radio('ciBoringPad', 'CI Boring Pad', _Opt.intactDamaged),
  CivilFieldSpec.section('Girders'),
  CivilFieldSpec.radio('girderAlignment', 'Alignment', const [
    'Satisfactory',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio(
    'longTransMovement',
    'Longitudinal or Transverse Movement',
    const ['Proper', 'Improper'],
  ),
  CivilFieldSpec.radio('seatingOfGirders', 'Seating of Girders', const [
    'Proper',
    'Improper',
  ]),
  CivilFieldSpec.radio('deflection', 'Deflection', _Opt.yesNo),
  CivilFieldSpec.radio('distortion', 'Distortion', _Opt.yesNo),
];

final List<CivilFieldSpec> _rccSlabBridgeFields = [
  CivilFieldSpec.section('For RCC Slab Bridge'),
  CivilFieldSpec.radio(
    'rccConcrete',
    'Condition of Concrete',
    _Opt.satisfactoryNeedRepair,
  ),
  CivilFieldSpec.radio('rccConcreteCover', 'Concrete Cover', const [
    'Fallen',
    'Intact',
  ]),
  CivilFieldSpec.radio('rccSlabsExposed', 'Slabs Exposed', _Opt.yesNo),
  CivilFieldSpec.radio('rccSlabsSeated', 'Slabs Properly Seated', _Opt.yesNo),
  CivilFieldSpec.radio(
    'rccBallastRetainers',
    'Ballast Retainers',
    _Opt.satisfactoryNeedRepair,
  ),
];

/// -------------------- WORKS sub-department --------------------

/// 3.1 — Workshop, Washing Line, Sick Line, Shed, Train Examining Depot,
/// Station, Staff Quarters. Building/Room accordion + per-attribute
/// Functional/Not Functional + conditional count, plus the Water Tank
/// block that only applies when the station's Water Facility = Yes.
final List<CivilFieldSpec> buildingRoomFormSpec = [
  CivilFieldSpec.dropdown('building', 'Select Building', const [
    'Building 1',
    'Building 2',
    'Building 3',
  ]),
  CivilFieldSpec.dropdown('room', 'Select Room', const [
    'Room 1',
    'Room 2',
    'Room 3',
  ]),
  CivilFieldSpec.section('Room Attributes'),
  CivilFieldSpec.radio('window', 'Window', const [
    'Functional',
    'Not Functional',
  ]),
  CivilFieldSpec.radio('door', 'Door', const ['Functional', 'Not Functional']),
  CivilFieldSpec.number(
    'notFunctionalCount',
    'Count of Not Functional',
    conditionKey: 'window',
    conditionValue: 'Not Functional',
  ),
  CivilFieldSpec.group(
    'Water Tank (only if Water Facility = Yes on this asset)',
    [
      CivilFieldSpec.section('Tank'),
      CivilFieldSpec.radio('kindOfPlates', 'Kind of Plates', const [
        'M.S',
        'C.I',
      ]),
      CivilFieldSpec.radio('tankPlates', 'Plates', const [
        'Satisfactory',
        'Corroded',
        'Need Replacement',
      ]),
      CivilFieldSpec.radio('tankJoints', 'Joints', const [
        'Satisfactory',
        'Corroded',
        'Need Replacement',
      ]),
      CivilFieldSpec.section('Inside Painting'),
      CivilFieldSpec.radio(
        'insidePaintCondition',
        'Painting Condition',
        _Opt.satisfactoryNeedPainting,
      ),
      CivilFieldSpec.date('insidePaintDate', 'Date of Painting'),
      CivilFieldSpec.section('Outside Painting'),
      CivilFieldSpec.radio(
        'outsidePaintCondition',
        'Painting Condition',
        _Opt.satisfactoryNeedPainting,
      ),
      CivilFieldSpec.date('outsidePaintDate', 'Date of Painting'),
    ],
  ),
];

/// 3.2 — Turntable (Works).
final List<CivilFieldSpec> worksTurntableFormSpec = [
  CivilFieldSpec.radio('pitWall', 'Pit Wall', const [
    'Working Properly',
    'Defective',
  ]),
];

/// 3.3 — Platform Shelter, Foot Over Bridge.
final List<CivilFieldSpec> platformShelterFobFormSpec = [
  CivilFieldSpec.section('Columns, Trestles and Stagings'),
  CivilFieldSpec.radio('columnsSteelWork', 'Steel Work', const [
    'Satisfactory',
    'Corroded',
    'Need Repair',
  ]),
  CivilFieldSpec.radio('columnsBases', 'Bases', _Opt.intactLoose),
  CivilFieldSpec.radio(
    'holdingDownBolts',
    'Holding Down Bolts',
    _Opt.tightLoose,
  ),
  CivilFieldSpec.radio(
    'protectionOfBases',
    'Protection Of Bases',
    _Opt.intactLoose,
  ),
  CivilFieldSpec.radio(
    'columnsPaintCondition',
    'Painting Condition',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.date('columnsPaintDate', 'Date of Painting'),
  CivilFieldSpec.section('Roof Trusses, Girders and Runaway Girders'),
  CivilFieldSpec.radio('trussesSteelWork', 'Steel Work', const [
    'Satisfactory',
    'Corroded',
    'Need Repair',
  ]),
  CivilFieldSpec.radio('bearingsIntact', 'Bearings', _Opt.intactLoose),
  CivilFieldSpec.radio(
    'anchorsFasteningBolts',
    'Anchors or fastening Bolts',
    _Opt.tightLoose,
  ),
  CivilFieldSpec.radio(
    'trussesPaintCondition',
    'Painting Condition',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.date('trussesPaintDate', 'Date of Painting'),
  CivilFieldSpec.section('Roof, Drain Pipes and Gutters'),
  CivilFieldSpec.radio('kindOfSheets', 'Kind of Sheets', const [
    'Asbestos',
    'Corrugated Iron',
  ]),
  CivilFieldSpec.radio('sheetsCondition', 'Sheets', const [
    'Satisfactory',
    'Need Replacement',
  ]),
  CivilFieldSpec.radio('windTies', 'Provision of wind Ties', const [
    'Intact',
    'Missing',
  ]),
  CivilFieldSpec.radio(
    'roofPaintCondition',
    'Painting Condition',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.date('roofPaintDate', 'Date of Painting'),
  CivilFieldSpec.radio('gutters', 'Gutters', const [
    'Satisfactory',
    'Missing',
    'Need Replacement',
  ]),
  CivilFieldSpec.radio('drainPipes', 'Drain Pipes', const [
    'Satisfactory',
    'Missing',
    'Need Replacement',
  ]),
];

/// 3.4 — Road Over Bridge, Underpass.
final List<CivilFieldSpec> roadOverBridgeUnderpassFormSpec = [
  CivilFieldSpec.radio(
    'condOfConcrete',
    'Condition of Concrete',
    _Opt.satisfactoryNeedRepair,
  ),
  CivilFieldSpec.radio('concreteCover', 'Concrete Cover', const [
    'Fallen',
    'Intact',
  ]),
  CivilFieldSpec.radio('slabsExposed', 'Slabs Exposed', _Opt.yesNo),
  CivilFieldSpec.radio(
    'slabsProperlySeated',
    'Slabs Properly Seated',
    _Opt.yesNo,
  ),
  CivilFieldSpec.radio(
    'ballastRetainers',
    'Ballast Retainers',
    _Opt.satisfactoryNeedRepair,
  ),
];

/// 3.5 — Tunnel (Works).
final List<CivilFieldSpec> worksTunnelFormSpec = [
  CivilFieldSpec.radio('ventilationShaft', 'Ventilation Shaft', const [
    'Provided',
    'Not Provided',
  ]),
  CivilFieldSpec.radio('conditionOfLining', 'Condition of Lining', const [
    'Sound',
    'Cracked',
    'Bulged',
    'Spelled',
  ]),
  CivilFieldSpec.radio('cracksInLining', 'Cracks in Lining', const [
    'None',
    'Minor',
    'Major',
  ]),
  CivilFieldSpec.radio('seepageDampness', 'Seepage / Dampness', const [
    'None',
    'Minor',
    'Heavy',
  ]),
  CivilFieldSpec.radio(
    'efflorescenceSaltDeposit',
    'Efflorescence / Salt Deposit',
    _Opt.yesNo,
  ),
  CivilFieldSpec.radio(
    'leakageThroughRoof',
    'Leakage through Roof',
    _Opt.yesNo,
  ),
  CivilFieldSpec.radio('vegetationGrowth', 'Vegetation Growth', _Opt.yesNo),
  CivilFieldSpec.radio('invertFloor', 'Invert (Floor)', const [
    'Sound',
    'Broken',
    'Uneven',
  ]),
  CivilFieldSpec.radio('drainHolesInLining', 'Drain Holes in Lining', const [
    'Clear',
    'Blocked',
    'Non Provided',
  ]),
  CivilFieldSpec.radio(
    'retainingWallCondition',
    'Retaining Wall Condition',
    const ['Good', 'Cracked', 'Collapsed'],
  ),
  CivilFieldSpec.radio('sideDrainAlongTrack', 'Side Drain Along Track', const [
    'Clear',
    'Blocked',
  ]),
];

/// 3.6 — Bridge (Works). Steel work + River Training + repeatable
/// Foundation per Pier/Abutment + conditional Arch/Girder/RCC blocks.
final List<CivilFieldSpec> worksBridgeFormSpec = [
  CivilFieldSpec.section('River Training works'),
  CivilFieldSpec.radio('guideBund', 'Guide Bund', _Opt.intactDamaged),
  CivilFieldSpec.radio('spur', 'Spur', _Opt.intactDamaged),
  CivilFieldSpec.repeatGroup(
    'foundation',
    'Foundation (opens per Pier / Abutment)',
    'Pier/Abutment',
    _bridgeFoundationTemplate,
  ),
  CivilFieldSpec.section('For Steel Work in Bridge'),
  CivilFieldSpec.radio('bridgeSteel', 'Steel', _Opt.satisfactoryCorroded),
  CivilFieldSpec.radio('bridgeJoints', 'Joints', const ['Intact', 'Corroded']),
  CivilFieldSpec.radio('bridgeRivets', 'Rivets', const ['Intact', 'Loose']),
  CivilFieldSpec.radio(
    'bridgePainting',
    'Painting',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.date('bridgePaintingDate', 'Date of Painting'),
  CivilFieldSpec.radio('bridgeBearings', 'Bearings', const [
    'Satisfactory',
    'Rusted',
  ]),
  CivilFieldSpec.radio('weepHoles', 'Weep Holes', const [
    'Provided',
    'Not Provided',
  ]),
  CivilFieldSpec.radio(
    'weepHolesFilledOpen',
    'Weep Holes Condition',
    const ['Filled', 'Open'],
    conditionKey: 'weepHoles',
    conditionValue: 'Provided',
  ),
  CivilFieldSpec.radio(
    'steelUnderTimber',
    'Condition of Steel under Timber',
    _Opt.satisfactoryCorroded,
  ),
  CivilFieldSpec.radio(
    'paintUnderTimber',
    'Condition of Paint under Timber',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.dropdown(
    'bridgeType',
    'Bridge Type (for the section below)',
    const ['Arch Bridge', 'Girder Bridge', 'RCC Slab Bridge'],
  ),
  CivilFieldSpec.group(
    'For Arch Bridge',
    _archBridgeFields.skip(1).toList(),
    conditionKey: 'bridgeType',
    conditionValue: 'Arch Bridge',
  ),
  CivilFieldSpec.group(
    'For Girder Bridge',
    _girderBridgeFields.skip(1).toList(),
    conditionKey: 'bridgeType',
    conditionValue: 'Girder Bridge',
  ),
  CivilFieldSpec.group(
    'For RCC Slab Bridge',
    _rccSlabBridgeFields.skip(1).toList(),
    conditionKey: 'bridgeType',
    conditionValue: 'RCC Slab Bridge',
  ),
];

/// -------------------- BRIDGE (aen) sub-department --------------------

/// 4.1 — Bridge (Bridge dept). Just the steel-work section (BRD section 4).
final List<CivilFieldSpec> bridgeDeptFormSpec = [
  CivilFieldSpec.section('For Steel Work in Bridge'),
  CivilFieldSpec.radio('steel', 'Steel', _Opt.satisfactoryCorroded),
  CivilFieldSpec.radio('joints', 'Joints', const ['Intact', 'Corroded']),
  CivilFieldSpec.radio('rivets', 'Rivets', const ['Intact', 'Loose']),
  CivilFieldSpec.radio('painting', 'Painting', _Opt.satisfactoryNeedPainting),
  CivilFieldSpec.date('paintingDate', 'Date of Painting'),
  CivilFieldSpec.radio('bearings', 'Bearings', const [
    'Satisfactory',
    'Rusted',
  ]),
  CivilFieldSpec.radio('weepHoles', 'Weep Holes', const [
    'Provided',
    'Not Provided',
  ]),
  CivilFieldSpec.radio(
    'weepHolesFilledOpen',
    'Weep Holes Condition',
    const ['Filled', 'Open'],
    conditionKey: 'weepHoles',
    conditionValue: 'Provided',
  ),
  CivilFieldSpec.radio(
    'steelUnderTimber',
    'Condition of Steel under Timber',
    _Opt.satisfactoryCorroded,
  ),
  CivilFieldSpec.radio(
    'paintUnderTimber',
    'Condition of Paint under Timber',
    _Opt.satisfactoryNeedPainting,
  ),
];

/// -------------------- TRACK sub-department --------------------

/// 5.1 — Turntable (Track).
final List<CivilFieldSpec> trackTurntableFormSpec = _trackGeometryFields();

/// 5.2 — Bridge (Track).
final List<CivilFieldSpec> trackBridgeFormSpec = [
  ..._trackGeometryFields(includeRailsAndFittings: false),
  CivilFieldSpec.radio('spacingOfTimber', 'Spacing of Timber', const [
    'Satisfactory',
    'Un-Satisfactory',
    'Need Replacement',
  ]),
  CivilFieldSpec.radio('hookBolt', 'Hook Bolt', const [
    'Tight',
    'Loose',
    'Missing',
  ]),
  CivilFieldSpec.radio('railJoints', 'Rail Joints', const [
    'Square',
    'Un-Square',
  ]),
  CivilFieldSpec.radio('fittingsAndFastenings', 'Fittings & Fastenings', const [
    'Square',
    'Un-Square',
  ]),
  CivilFieldSpec.radio('clearanceGuardRail', 'Clearance of Guard Rail', const [
    'Satisfactory',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio(
    'clearanceBallastWall',
    'Clearance of Ballast wall',
    const ['Satisfactory', 'Need Adjustment'],
  ),
];

/// 5.3 — Station (Track). Point & Crossing repeats per point; Loop &
/// Siding repeats per line.
final List<CivilFieldSpec> _pointCrossingTemplate = [
  CivilFieldSpec.radio('condSwitchRail', 'Condition of Switch Rail', const [
    'Good',
    'Wear',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio('throughOfSwitch', 'Through of Switch', const [
    'Exact',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio('heelDivergence', 'Heel Divergence', const [
    'Exact',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio(
    'condCrossing',
    'Condition of Crossing',
    _Opt.goodWearNeedReplacement,
  ),
  CivilFieldSpec.radio(
    'clearanceNoseLeft',
    'Clearance of Nose of Crossing – Left Hand',
    _Opt.withinLimitNeedAdjustment,
  ),
  CivilFieldSpec.radio(
    'clearanceNoseRight',
    'Clearance of Nose of Crossing – Right Hand',
    _Opt.withinLimitNeedAdjustment,
  ),
  CivilFieldSpec.radio(
    'clearanceCheckRail',
    'Clearance of Check Rail',
    _Opt.withinLimitNeedAdjustment,
  ),
];

final List<CivilFieldSpec> _loopSidingLineTemplate = [
  ..._trackGeometryFields(includeRailsAndFittings: false),
  CivilFieldSpec.radio('joints', 'Joints', const ['Level', 'Low', 'Blowing']),
  CivilFieldSpec.radio('rails', 'Rails', _Opt.railCondition),
  CivilFieldSpec.radio('sleepers', 'Sleepers', _Opt.unServiceServiceable),
  CivilFieldSpec.radio('fittings', 'Fittings', _Opt.fittings),
];

final List<CivilFieldSpec> stationFormSpec = [
  CivilFieldSpec.repeatGroup(
    'pointCrossing',
    'Point & Crossing (opens for each point in the station)',
    'Point',
    _pointCrossingTemplate,
  ),
  CivilFieldSpec.repeatGroup(
    'loopSiding',
    'Loop & Siding (opens for each line)',
    'Line',
    _loopSidingLineTemplate,
  ),
];

/// 5.4 — Tunnel (Track).
final List<CivilFieldSpec> trackTunnelFormSpec = [
  ..._trackGeometryFields(includeRailsAndFittings: false),
  CivilFieldSpec.radio('lowJoints', 'Low Joints', const [
    'Satisfactory',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio('rails', 'Rails', _Opt.railCondition),
  CivilFieldSpec.radio('sleepers', 'Sleepers', _Opt.unServiceServiceable),
  CivilFieldSpec.radio('fittings', 'Fittings', _Opt.fittings),
  CivilFieldSpec.radio('clearances', 'Clearances', const [
    'Side Clearance',
    'Top Clearance',
  ]),
];

/// 5.5 — Curves.
final List<CivilFieldSpec> curvesFormSpec = [
  CivilFieldSpec.radio('degree', 'Degree', const ['Exact', 'Need Adjustment']),
  CivilFieldSpec.radio('versine', 'Versine', const [
    'Correct',
    'Within limit',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio(
    'additionalBallast',
    'Additional Ballast on Shoulders',
    const ['Provided', 'Sufficient', 'Required', 'Not Required'],
  ),
  CivilFieldSpec.radio('curvePost', 'Curve Post', const [
    'Provided',
    'Not Provided',
    'Maintained',
    'Not Maintained',
  ]),
];

/// 5.6 — Level Crossing.
final List<CivilFieldSpec> levelCrossingFormSpec = [
  ..._trackGeometryFields(includeRailsAndFittings: false),
  CivilFieldSpec.radio('rails', 'Rails', _Opt.railCondition),
  CivilFieldSpec.radio('sleepers', 'Sleepers', _Opt.unServiceServiceable),
  CivilFieldSpec.radio('fittings', 'Fittings', _Opt.fittings),
  CivilFieldSpec.radio('overhauling', 'Overhauling', const ['Due', 'Not Due']),
  CivilFieldSpec.radio('condRoadSurface', 'Condition of Road surface', const [
    'Good',
    'Satisfactory',
    'Poor',
    'Need Repair',
  ]),
  CivilFieldSpec.radio('condPainting', 'Condition of Painting', const [
    'Good',
    'Fair',
    'Poor',
  ]),
  CivilFieldSpec.radio('equipment', 'Equipment', const [
    'Complete',
    'Good Condition',
    'In-Complete',
  ]),
  CivilFieldSpec.radio('dutyRoster', 'Duty Roster', const [
    'Available',
    'Not Available',
  ]),
  CivilFieldSpec.radio('complaintRegister', 'Complaint Register', const [
    'Available',
    'Not Available',
  ]),
  CivilFieldSpec.radio('checkRailClearance', 'Check Rail Clearance', const [
    'Correct',
    'Need Adjustment',
  ]),
  CivilFieldSpec.radio('distanceBlocks', 'Distance Blocks', const [
    'Tights',
    'Loose',
  ]),
  CivilFieldSpec.radio('boltNuts', 'Bolt & Nuts', const ['Tights', 'Loose']),
  CivilFieldSpec.radio('bearingPlates', 'Bearing Plates', const [
    'Tights',
    'Loose',
  ]),
  CivilFieldSpec.radio('condFittings', 'Condition of Fittings', const [
    'Satisfactory',
    'Un-Satisfactory',
    'Need Replacement',
  ]),
  CivilFieldSpec.radio('roadSignBoards', 'Road Sign Boards', const [
    'Available',
    'Not Available',
  ]),
  CivilFieldSpec.radio('visibility', 'Visibility', const [
    'Good',
    'Fair',
    'Poor',
  ]),
  CivilFieldSpec.date('fogSignalsExpiry', 'Fog Signals — Date of Expiry'),
  CivilFieldSpec.radio('drainageCondition', 'Drainage condition', const [
    'Good',
    'Fair',
    'Poor',
  ]),
  CivilFieldSpec.radio('fencing', 'Fencing', const [
    'Available',
    'Not Available',
  ]),
  CivilFieldSpec.radio(
    'fencingPaintCondition',
    'Fencing Painting Condition',
    _Opt.satisfactoryNeedPainting,
  ),
  CivilFieldSpec.radio(
    'whistleBoardCondition',
    'Whistle Board condition',
    const ['Good', 'Missing'],
  ),
  // "Only show in case of 'Man Availability' selected as 'Unmanned' in
  // assets form" — modelled here as a local toggle since the real trigger
  // lives on the asset master, out of scope for this form module.
  CivilFieldSpec.radio(
    'manAvailability',
    'Man Availability (from asset master)',
    const ['Manned', 'Unmanned'],
  ),
  CivilFieldSpec.radio(
    'speedBreaker',
    'Speed Breaker',
    const ['Provided', 'Not Provided'],
    conditionKey: 'manAvailability',
    conditionValue: 'Unmanned',
  ),
];

/// -------------------- Department / Sub-department / Asset map --------
/// Mirrors the "How assets Work" table on page 5 of the BRD.
class CivilDeptAssetMap {
  static const Map<String, Map<String, List<String>>> table = {
    'Civil': {
      'Works': [
        'Workshop',
        'Washing Line',
        'Sick Line',
        'Shed',
        'Train Examining Depot',
        'Turn Table',
        'Platform Shelter',
        'Bridge',
        'Foot Over Bridge',
        'Underpass',
        'Road Over Bridge',
        'Station',
        'Staff Quarters',
        'Tunnel',
      ],
      'Track': [
        'Turn Table',
        'Bridge',
        'Station',
        'Private Sidings',
        'Tunnel',
        'Rails',
        'Sleepers',
        'Curves',
        'Level Crossing',
        'Point & Crossings',
        'Loops & Sidings',
      ],
      'Bridge (aen)': ['Bridge'],
    },
  };

  /// Resolves which field spec list to render for a given
  /// department/sub-department/asset combination.
  static List<CivilFieldSpec>? resolveFields(
    String department,
    String subDepartment,
    String asset,
  ) {
    if (department != 'Civil') return null;

    if (subDepartment == 'Works') {
      const buildingAssets = {
        'Workshop',
        'Washing Line',
        'Sick Line',
        'Shed',
        'Train Examining Depot',
        'Station',
        'Staff Quarters',
      };
      if (buildingAssets.contains(asset)) return buildingRoomFormSpec;
      if (asset == 'Turn Table') return worksTurntableFormSpec;
      if (asset == 'Platform Shelter' || asset == 'Foot Over Bridge') {
        return platformShelterFobFormSpec;
      }
      if (asset == 'Road Over Bridge' || asset == 'Underpass') {
        return roadOverBridgeUnderpassFormSpec;
      }
      if (asset == 'Tunnel') return worksTunnelFormSpec;
      if (asset == 'Bridge') return worksBridgeFormSpec;
    }

    if (subDepartment == 'Bridge (aen)' && asset == 'Bridge') {
      return bridgeDeptFormSpec;
    }

    if (subDepartment == 'Track') {
      if (asset == 'Turn Table') return trackTurntableFormSpec;
      if (asset == 'Bridge') return trackBridgeFormSpec;
      if (asset == 'Station') return stationFormSpec;
      if (asset == 'Tunnel') return trackTunnelFormSpec;
      if (asset == 'Curves') return curvesFormSpec;
      if (asset == 'Level Crossing') return levelCrossingFormSpec;
      // 'Private Sidings' / 'Rails' / 'Sleepers' / 'Point & Crossings' /
      // 'Loops & Sidings' are all served by the bespoke
      // Sleepers/Rails/Private Sidings screen (section 5.7 of the BRD).
    }

    return null;
  }
}
