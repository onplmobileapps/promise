import 'package:railway_hrms/modules/inspection/motor_trolley/inspection_params_config.dart';

/// Something on a step of the trolley form: a heading or a question.
sealed class TrolleyItem {
  const TrolleyItem();
}

/// A heading over the questions after it, with its standard as a [note].
final class TrolleyHeading extends TrolleyItem {
  const TrolleyHeading(this.title, {this.note});

  final String title;
  final String? note;
}

/// A question, as its [field] describes it.
final class TrolleyAsk extends TrolleyItem {
  const TrolleyAsk(this.field);

  final ParamField field;
}

/// A step of the trolley form.
final class TrolleyStep {
  const TrolleyStep(this.id, this.title, this.items);

  final String id;
  final String title;
  final List<TrolleyItem> items;

  /// Its questions, without the headings.
  Iterable<ParamField> get fields =>
      items.whereType<TrolleyAsk>().map((ask) => ask.field);
}

const _yesNo = ['Yes', 'No'];

const _reasons = ['Short Fitting', 'US Sleepers', 'Defective Rail', 'Others'];

List<TrolleyItem> _asks(Iterable<ParamField> fields) => [
  for (final field in fields) TrolleyAsk(field),
];

/// The motor trolley inspection, step by step, as the proforma has it.
final List<TrolleyStep> kTrolleySteps = [
  const TrolleyStep('header', 'Inspection', [
    TrolleyAsk(
      ParamField(
        key: 'inspectingOfficer',
        label: 'Name / Designation of Inspecting Officer',
        type: ParamInputType.text,
        hint: 'Name & designation',
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'betweenStation',
        label: 'Between Stations',
        type: ParamInputType.text,
        hint: 'e.g. Lahore – Raiwind',
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'sectionFrom',
        label: 'Section From',
        type: ParamInputType.text,
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'sectionTo',
        label: 'Section To',
        type: ParamInputType.text,
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'kmFrom',
        label: 'KM From',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'kmTo',
        label: 'KM To',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
  ]),
  TrolleyStep('geometry', 'I. Track Geometry', [
    const TrolleyHeading(
      'Alignment',
      note: 'Standard: Straight · Permissible: ±5 mm',
    ),
    const TrolleyAsk(
      ParamField(
        key: 'alignmentReading',
        label: 'Reading',
        type: ParamInputType.number,
        unit: 'mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'alignmentOutOfLimit',
        label: 'Out of Limit',
        options: _yesNo,
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'alignmentReason',
        label: 'Reason',
        options: _reasons,
        showWhen: ('alignmentOutOfLimit', 'Yes'),
      ),
    ),
    const TrolleyHeading('Gauge'),
    const TrolleyAsk(
      ParamField(
        key: 'gaugeSpeedCategory',
        label: 'Speed Category',
        options: [
          'Above 100 Kmph',
          '80 to 100 km/h',
          '60 to 80 km/h',
          '60 km/h and below',
        ],
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'gaugeReading',
        label: 'Reading',
        type: ParamInputType.number,
        unit: 'mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'gaugeOutOfLimit',
        label: 'Out of Limit',
        options: _yesNo,
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'gaugeReason',
        label: 'Reason',
        options: _reasons,
        showWhen: ('gaugeOutOfLimit', 'Yes'),
      ),
    ),
    const TrolleyHeading(
      'Cross Level',
      note: 'Standard: Level · Permissible: ±6 mm',
    ),
    const TrolleyAsk(
      ParamField(
        key: 'crossLevelReading',
        label: 'Reading',
        type: ParamInputType.number,
        unit: 'mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'crossLevelOutOfLimit',
        label: 'Out of Limit',
        options: _yesNo,
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'crossLevelReason',
        label: 'Reason',
        options: ['Loose Packing', 'Short Ballast Cushion', 'Others'],
        showWhen: ('crossLevelOutOfLimit', 'Yes'),
      ),
    ),
    const TrolleyHeading('Rail'),
    const TrolleyAsk(
      ParamField(
        key: 'railType',
        label: 'Rail Type',
        options: [
          'UIC-54',
          '100 RE',
          '90-R',
          '90-BSS',
          '75-R',
          '75-BSS',
          '75/87',
          '75/92',
          '87-FF',
        ],
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'railRemarks',
        label: 'Remarks',
        options: [
          'Top wear',
          'Side wear',
          'End Bettered',
          'Hogged',
          'Wheel Burnt',
          'Defective',
        ],
      ),
    ),
    const TrolleyHeading('Sleeper'),
    ..._asks(
      trackGeometryExtraFields.where((f) => f.key.startsWith('sleeper')),
    ),
    const TrolleyHeading('Fittings'),
    ..._asks(
      trackGeometryExtraFields.where((f) => f.key.startsWith('fitting')),
    ),
    const TrolleyHeading('Ballast, Embankment, Drainage & Other'),
    ..._asks(
      trackGeometryExtraFields.where(
        (f) => !f.key.startsWith('sleeper') && !f.key.startsWith('fitting'),
      ),
    ),
  ]),
  TrolleyStep('curves', '2. Curves', [
    const TrolleyAsk(
      ParamField(key: 'curveNo', label: 'Curve No', type: ParamInputType.text),
    ),
    TrolleyAsk(
      ParamField(
        key: 'degreeOfCurve',
        label: 'Degree of Curve',
        options: [for (var d = 1; d <= 20; d++) '${d / 2}'],
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curveSpeed',
        label: 'Speed (KMPH)',
        options: ['Above 100', '80 to 100', '60 to 80', 'Below 60'],
      ),
    ),
    const TrolleyHeading(
      'Gauge on Curve',
      note: 'Standard: 1676 · Permissible: ≤4° +13/-3 to +15/-4, >4° +20 mm',
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curveGaugeReading',
        label: 'Reading',
        type: ParamInputType.number,
        unit: 'mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curveGaugeOutOfLimit',
        label: 'Out of Limit',
        options: _yesNo,
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curveGaugeAction',
        label: 'Action',
        options: ['Adjustment (Versine)', 'Re-alignment'],
        showWhen: ('curveGaugeOutOfLimit', 'Yes'),
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curveGaugeReason',
        label: 'Reason',
        options: ['Excessive side rail wear', 'Less Ballast on Shoulders'],
        showWhen: ('curveGaugeOutOfLimit', 'Yes'),
      ),
    ),
    const TrolleyHeading('Super Elevation', note: 'Standard: Max 165 mm'),
    const TrolleyAsk(
      ParamField(
        key: 'superElevationReading',
        label: 'Reading',
        type: ParamInputType.number,
        unit: 'mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'superElevationAction',
        label: 'Action',
        options: ['Adjusted Super Elevation'],
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'curvePostAvailable',
        label: 'Curve Post (Standard: 1000)',
        options: ['Available', 'Not Available'],
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'checkRailClearanceCurveReading',
        label: 'Check Rail Clearance (6° & above)',
        type: ParamInputType.number,
        unit: 'mm',
        standard: 'Standard: 47 mm',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'checkRailClearanceCurveStatus',
        label: 'Check Rail Clearance Status',
        options: [
          '< 47 (need adjustment)',
          '> 47 (need adjustment)',
          '= 47 (OK)',
        ],
      ),
    ),
  ]),
  const TrolleyStep('points', '3. Points & Crossings', [
    TrolleyAsk(
      ParamField(
        key: 'pcGauge',
        label: 'Gauge',
        options: ['Exact', 'Slack', 'Tight'],
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossLevel',
        label: 'Cross Level',
        options: ['Exact', 'Out'],
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcFittingsPercentage',
        label: 'Fittings',
        type: ParamInputType.number,
        unit: '%',
        standard: 'Standard: 100%',
      ),
    ),
    TrolleyHeading('Wear of Switch', note: 'Permissible: 0–150'),
    TrolleyAsk(
      ParamField(
        key: 'pcSwitchWearAction',
        label: 'Action',
        options: ['Within Limit', 'Replace Switch'],
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcSwitchWearReason',
        label: 'Reason',
        options: ['Excessive wear', 'Broken'],
      ),
    ),
    TrolleyHeading('Wear of Crossing', note: 'Permissible: 0–9.5'),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossingWearAction',
        label: 'Action',
        options: ['Within Limit', 'Replace Crossing'],
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossingWearReason',
        label: 'Reason',
        options: ['Excessive wear', 'Broken', 'Ultrasonic Defective'],
      ),
    ),
    TrolleyHeading('Clearances'),
    TrolleyAsk(
      ParamField(
        key: 'pcCheckRailsClearance',
        label: 'Check Rails Clearance',
        type: ParamInputType.number,
        unit: 'mm',
        standard: 'Standard: 45',
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcWingRailClearance',
        label: 'Wing Rail Clearance',
        type: ParamInputType.number,
        unit: 'mm',
        standard: 'Standard: 45–47',
      ),
    ),
    TrolleyHeading('Crossing Timbers'),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossingTimbersPercentage',
        label: 'US Percentage',
        type: ParamInputType.number,
        unit: '%',
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossingTimbersAction',
        label: 'Action',
        options: [
          '95 (Engg Speed Restriction)',
          '90',
          '70',
          '65',
          '60',
          '50',
          '20 to 50',
        ],
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pcCrossingTimbersReason',
        label: 'Reason',
        options: ['Increase US percentage'],
      ),
    ),
  ]),
  TrolleyStep('bridges', '4. Bridges', [
    const TrolleyHeading('Sub-structure'),
    ..._asks(bridgeSubStructureFields),
    const TrolleyHeading('Super-structure'),
    ..._asks(bridgeSuperStructureFields),
  ]),
  TrolleyStep('lcManned', '5. Level Crossings (Manned)', [
    const TrolleyAsk(
      ParamField(
        key: 'lcMannedKmFrom',
        label: 'Km From',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'lcMannedKmTo',
        label: 'Km To',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    ..._asks(levelCrossingMannedFields),
  ]),
  TrolleyStep('lcUnmanned', '5A. Level Crossings (Unmanned)', [
    const TrolleyAsk(
      ParamField(
        key: 'lcUnmannedKmFrom',
        label: 'Km From',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'lcUnmannedKmTo',
        label: 'Km To',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    ..._asks(levelCrossingUnmannedFields),
  ]),
  TrolleyStep('tunnel', '6. Tunnel', _asks(tunnelFields)),
  TrolleyStep('buildings', '7. Station Buildings', [
    const TrolleyAsk(
      ParamField(key: 'sbName', label: 'Name', type: ParamInputType.text),
    ),
    const TrolleyAsk(
      ParamField(
        key: 'sbKm',
        label: 'Km',
        type: ParamInputType.number,
        unit: 'km',
      ),
    ),
    const TrolleyAsk(
      ParamField(key: 'sbSection', label: 'Section', type: ParamInputType.text),
    ),
    ..._asks(stationBuildingFields),
  ]),
  TrolleyStep('yards', '8. Yards', _asks(yardFields)),
  TrolleyStep('block', '9. Block Sections', _asks(blockSectionFields)),
  const TrolleyStep('certification', 'Certification', [
    TrolleyAsk(
      ParamField(
        key: 'inspectedBy',
        label: 'Inspected by',
        type: ParamInputType.text,
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'designation',
        label: 'Designation',
        type: ParamInputType.text,
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'pwiIncharge',
        label: 'PWI / In-charge',
        type: ParamInputType.text,
      ),
    ),
    TrolleyAsk(
      ParamField(
        key: 'verifiedBy',
        label: 'Verified by',
        type: ParamInputType.text,
      ),
    ),
  ]),
];
