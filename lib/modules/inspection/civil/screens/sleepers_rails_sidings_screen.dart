import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';

const _railConditions = [
  'Serviceable',
  'Ultrasonic Flaw Detective (USFD)',
  'Wheel Burnt',
  'Excessive Wear',
  'End battered',
  'Hogged',
  'Worn Out',
];

/// The "During Inspection: Exists/Removed -> Same/New -> [details]"
/// blocks that repeat for Trespassing, Electric Crossing, Encroachments,
/// and Sui Gas Crossing (BRD pages 23-25).
final List<CivilFieldSpec> _trespassingFields = [
  CivilFieldSpec.radio(
    'trespassingPresent',
    'Un-Authorized Trespassing',
    const ['Yes', 'No'],
  ),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.dropdown('trespassingType', 'Type', const [
        'Shop',
        'Path',
        'Structure',
      ]),
      CivilFieldSpec.dropdown('trespassingRemedy', 'Remedy', const [
        'FIR',
        'Notice',
        'Removal',
      ]),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'trespassing',
        newFields: [
          CivilFieldSpec.dropdown('trespassingNewType', 'Type', const [
            'Shop',
            'Path',
            'Structure',
          ]),
          CivilFieldSpec.dropdown('trespassingNewRemedy', 'Remedy', const [
            'FIR',
            'Notice',
            'Removal',
          ]),
        ],
      ),
    ],
    conditionKey: 'trespassingPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _electricCrossingFields = [
  CivilFieldSpec.radio('electricCrossingPresent', 'Electric Crossing', const [
    'Yes',
    'No',
  ]),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number('electricVoltage', 'Voltage'),
      CivilFieldSpec.radio('electricPassingFrom', 'Passing From', const [
        'Over Head',
        'Under Ground',
      ]),
      CivilFieldSpec.number('electricDiameter', 'Diameter', unit: 'Inches'),
      CivilFieldSpec.date('electricCrossingDate', 'Crossing Date'),
      CivilFieldSpec.radio('electricNocApproved', 'NOC Approved', const [
        'Yes',
        'No',
      ]),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'electricCrossing',
        newFields: [
          CivilFieldSpec.number('electricNewVoltage', 'Voltage'),
          CivilFieldSpec.radio('electricNewPassingFrom', 'Passing From', const [
            'Over Head',
            'Under Ground',
          ]),
          CivilFieldSpec.number(
            'electricNewDiameter',
            'Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.date('electricNewCrossingDate', 'Crossing Date'),
          CivilFieldSpec.radio('electricNewNocApproved', 'NOC Approved', const [
            'Yes',
            'No',
          ]),
        ],
      ),
    ],
    conditionKey: 'electricCrossingPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _encroachmentFields = [
  CivilFieldSpec.radio('encroachmentPresent', 'Encroachments', const [
    'Yes',
    'No',
  ]),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number(
        'encroachLeftFeet',
        'Left Side Encroachment',
        unit: 'Feet',
      ),
      CivilFieldSpec.number(
        'encroachRightFeet',
        'Right Side Encroachment',
        unit: 'Feet',
      ),
      CivilFieldSpec.text('encroacherName', 'Name of Encroacher'),
      CivilFieldSpec.dropdown('encroachType', 'Type of Encroachment', const [
        'Brackets',
        'Shop',
        'Structure',
        'Other',
      ]),
      CivilFieldSpec.number('encroachSinceYear', 'Encroachment Since (Year)'),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'encroachment',
        newFields: [
          CivilFieldSpec.number(
            'encroachNewLeftFeet',
            'Left Side Encroachment',
            unit: 'Feet',
          ),
          CivilFieldSpec.number(
            'encroachNewRightFeet',
            'Right Side Encroachment',
            unit: 'Feet',
          ),
          CivilFieldSpec.text('encroachNewName', 'Name of Encroacher'),
          CivilFieldSpec.dropdown(
            'encroachNewType',
            'Type of Encroachment',
            const ['Brackets', 'Shop', 'Structure', 'Other'],
          ),
          CivilFieldSpec.number(
            'encroachNewSinceYear',
            'Encroachment Since (Year)',
          ),
        ],
      ),
    ],
    conditionKey: 'encroachmentPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _suiGasFields = [
  CivilFieldSpec.radio(
    'suiGasPresent',
    'Sui Gas Crossing on this Decimal',
    const ['Yes', 'No'],
  ),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number(
        'suiGasPipeDiameter',
        'Pipe Diameter',
        unit: 'Inches',
      ),
      CivilFieldSpec.number(
        'suiGasCasingDiameter',
        'Casing Diameter',
        unit: 'Inches',
      ),
      CivilFieldSpec.text('suiGasApprovalNo', 'HQ / FGIR Approval No'),
      CivilFieldSpec.radio(
        'suiGasIndicationBoard',
        'Indication Board of Sui Gas Xing',
        const ['Provided', 'Not Provided'],
      ),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'suiGas',
        newFields: [
          CivilFieldSpec.number(
            'suiGasNewPipeDiameter',
            'Pipe Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.number(
            'suiGasNewCasingDiameter',
            'Casing Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.text('suiGasNewApprovalNo', 'HQ / FGIR Approval No'),
          CivilFieldSpec.radio(
            'suiGasNewIndicationBoard',
            'Indication Board of Sui Gas Xing',
            const ['Provided', 'Not Provided'],
          ),
        ],
      ),
    ],
    conditionKey: 'suiGasPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _embankmentAndBoundaryFields = [
  _civilSectionAsGroup('Embankment', [
    CivilFieldSpec.number(
      'embankmentWidthFeet',
      'Width Embankment',
      unit: 'Feet',
    ),
    CivilFieldSpec.number(
      'embankmentWidthInches',
      'Width Embankment',
      unit: 'Inches',
    ),
    CivilFieldSpec.number(
      'avgHeightNSL',
      'Average height of bank w.r.t NSL (Natural Surface Level)',
    ),
    CivilFieldSpec.number(
      'actualWidthEmbankment',
      'Actual Width of Embankment',
    ),
  ]),
  _civilSectionAsGroup('Land Boundary', [
    CivilFieldSpec.number('landBoundaryLeftFeet', 'Left Side', unit: 'Feet'),
    CivilFieldSpec.number('landBoundaryRightFeet', 'Right Side', unit: 'Feet'),
  ]),
];

/// Small helper so a labelled block of plain fields reads as one visual
/// group without pulling in the full conditional machinery.
CivilFieldSpec _civilSectionAsGroup(
  String label,
  List<CivilFieldSpec> fields,
) => CivilFieldSpec.group(label, fields);

/// The stretch walked, from pole to pole: its rails and sleepers found
/// wanting, the embankment and boundary, and what crosses or encroaches
/// on it.
final List<CivilFieldSpec> sleepersRailsSidingsFields = [
  CivilFieldSpec.section('Stretch'),
  CivilFieldSpec.number('kmFrom', 'KM From', unit: 'km'),
  CivilFieldSpec.number('kmTo', 'KM To', unit: 'km'),
  CivilFieldSpec.number('pole', 'Pole'),
  CivilFieldSpec.number('decimal', 'Decimal'),
  CivilFieldSpec.section('Rails'),
  CivilFieldSpec.number('railsChecked', 'Rails checked'),
  CivilFieldSpec.repeatGroup('railDefects', 'Rails found wanting', 'Rail', [
    CivilFieldSpec.number('number', 'Rail number'),
    CivilFieldSpec.dropdown('condition', 'Condition', _railConditions),
  ]),
  CivilFieldSpec.section('Sleepers'),
  CivilFieldSpec.number('sleepersChecked', 'Sleepers checked'),
  CivilFieldSpec.number('sleepersUnserviceable', 'Un-serviceable sleepers'),
  CivilFieldSpec.section('Embankment & Boundary'),
  ..._embankmentAndBoundaryFields,
  CivilFieldSpec.section('Trespassing'),
  ..._trespassingFields,
  CivilFieldSpec.section('Electric Crossing'),
  ..._electricCrossingFields,
  CivilFieldSpec.section('Encroachments'),
  ..._encroachmentFields,
  CivilFieldSpec.section('Sui Gas Crossing'),
  ..._suiGasFields,
];

/// Sleepers, rails and private sidings, inspected stretch by stretch.
class SleepersRailsSidingsScreen extends StatelessWidget {
  const SleepersRailsSidingsScreen({super.key});

  @override
  Widget build(BuildContext context) => CivilAssetFormScreen(
    department: 'Civil',
    subDepartment: 'Track',
    asset: 'Sleepers, Rails, Private Sidings',
    fields: sleepersRailsSidingsFields,
    formId: 'civil_track_sleepers_rails_private_sidings',
  );
}
