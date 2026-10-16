import 'package:railway_hrms/modules/inspection/station/models.dart';

/// The five signal-quality checks rendered for every fixed signal card.
const List<List<String>> kSignalParts = [
  ['foundation', 'Foundation condition'],
  ['pole', 'Pole condition'],
  ['visibility', 'Visibility'],
  ['focus', 'Focus'],
  ['lens', 'Signal lens'],
];

/// Repeatable-row schemas: points, level crossings, track circuits, and the
/// quarterly failure summary.
final Map<String, RepeatDef> kRepeatDefs = {
  'points': RepeatDef('Point', 2, [
    RepeatColumn(
      'pointNo',
      'Point #',
      (fid) => FieldSpec(fid, 'Point #', FieldKind.text, placeholder: 'e.g. 1'),
    ),
    RepeatColumn(
      'gaugeTest',
      'Point setting test',
      (fid) => FieldSpec(
        fid,
        'Point Setting Test',
        FieldKind.select,
        options: const ['Pass', 'Fail'],
      ),
    ),
    RepeatColumn(
      'gaugeValue',
      'Point gauge value',
      (fid) => FieldSpec(
        fid,
        'Point Gauge (Test Value)',
        FieldKind.select,
        options: const ['2 mm', '3 mm', '1/8 in', '3/8 in'],
      ),
    ),
    RepeatColumn(
      'trackGauge',
      'Track gauge',
      (fid) => FieldSpec(
        fid,
        'Track Gauge OK',
        FieldKind.toggle,
        options: const ['Yes', 'No'],
        span2: true,
      ),
    ),
    RepeatColumn(
      'trackGaugeRemark',
      '',
      (fid) => FieldSpec(
        fid,
        'Track Gauge — if No',
        FieldKind.text,
        placeholder: 'Value / remark',
      ),
    ),
    RepeatColumn(
      'packing',
      'Packing',
      (fid) => FieldSpec(
        fid,
        'Packing of Sleepers',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
        span2: true,
      ),
    ),
    RepeatColumn(
      'throwOk',
      'Throw of point',
      (fid) => FieldSpec(
        fid,
        'Throw of Point OK',
        FieldKind.toggle,
        options: const ['Yes', 'No'],
        span2: true,
      ),
    ),
    RepeatColumn(
      'throwRemark',
      '',
      (fid) => FieldSpec(
        fid,
        'Throw of Point — if No',
        FieldKind.text,
        placeholder: 'Value / remark',
      ),
    ),
    RepeatColumn(
      'switchCondition',
      'Switch/tongue rail',
      (fid) => FieldSpec(
        fid,
        'Condition of Switch / Tongue Rail',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
        span2: true,
      ),
    ),
    RepeatColumn(
      'fitting',
      'Fitting & fastening',
      (fid) => FieldSpec(
        fid,
        'Fitting & Fastening',
        FieldKind.toggle,
        options: const ['Complete', 'Incomplete'],
        span2: true,
      ),
    ),
  ]),
  'lx': RepeatDef('Level Crossing', 1, [
    RepeatColumn(
      'lxNo',
      'L-X #',
      (fid) =>
          FieldSpec(fid, 'L-X #', FieldKind.text, placeholder: 'e.g. LC-12'),
    ),
    RepeatColumn(
      'communication',
      'Communication',
      (fid) => FieldSpec(
        fid,
        'Communication',
        FieldKind.toggle,
        options: const ['Good', 'Poor'],
      ),
    ),
    RepeatColumn(
      'warningBell',
      'Warning bell',
      (fid) => FieldSpec(
        fid,
        'Warning Bell',
        FieldKind.toggle,
        options: const ['Functional', 'Non-functional'],
      ),
    ),
    RepeatColumn(
      'operation',
      'Operation',
      (fid) => FieldSpec(
        fid,
        'Operation of L-Crossing',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
    RepeatColumn(
      'complaintBook',
      'Complaint book',
      (fid) => FieldSpec(
        fid,
        'Complaint Book',
        FieldKind.toggle,
        options: const ['Available', 'Not Available'],
      ),
    ),
    RepeatColumn(
      'batteryVolts',
      'Battery voltage',
      (fid) => FieldSpec(fid, 'Battery Voltage', FieldKind.decimal, unit: 'V'),
    ),
    RepeatColumn(
      'batteryStatus',
      'Battery status',
      (fid) => FieldSpec(
        fid,
        'Battery Status',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
  ]),
  'tc': RepeatDef('Track Circuit', 2, [
    RepeatColumn(
      'circuitNo',
      'Circuit #',
      (fid) => FieldSpec(
        fid,
        'Track Circuit #',
        FieldKind.text,
        placeholder: 'e.g. 1T',
      ),
    ),
    RepeatColumn(
      'feedVolt',
      'Feed end volt',
      (fid) => FieldSpec(
        fid,
        'Feed End Voltage',
        FieldKind.decimal,
        unit: 'V',
        hint: 'Typical 0.5 – 5.0 V',
      ),
    ),
    RepeatColumn(
      'relayVolt',
      'Relay end volt',
      (fid) => FieldSpec(
        fid,
        'Relay End Voltage',
        FieldKind.decimal,
        unit: 'V',
        hint: 'Typical 1.5 – 3.0 V',
      ),
    ),
    RepeatColumn(
      'irj',
      'IRJ',
      (fid) => FieldSpec(
        fid,
        'Condition of IRJ',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
    RepeatColumn(
      'jumper',
      'Jumper',
      (fid) => FieldSpec(
        fid,
        'Condition of Jumper',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
    RepeatColumn(
      'bondWire',
      'Bond wire',
      (fid) => FieldSpec(
        fid,
        'Condition of Bond Wire',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
    RepeatColumn(
      'trackPod',
      'Track pod',
      (fid) => FieldSpec(
        fid,
        'Condition of Track Pod',
        FieldKind.toggleRemark,
        options: const ['Satisfactory', 'Unsatisfactory'],
      ),
    ),
  ]),
  'failures': RepeatDef('Quarter', 2, [
    RepeatColumn(
      'quarter',
      'Quarter',
      (fid) => FieldSpec(
        fid,
        'Quarter',
        FieldKind.text,
        placeholder: 'e.g. Q1 2026',
      ),
    ),
    RepeatColumn(
      'engg',
      'Engg',
      (fid) =>
          FieldSpec(fid, 'Engg (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'elect',
      'ELECT',
      (fid) =>
          FieldSpec(fid, 'ELECT (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'tcom',
      'T.Com',
      (fid) =>
          FieldSpec(fid, 'T.Com (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'tfc',
      'TFC',
      (fid) =>
          FieldSpec(fid, 'TFC (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'sig',
      'SIG',
      (fid) =>
          FieldSpec(fid, 'SIG (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'oc',
      'O/C',
      (fid) =>
          FieldSpec(fid, 'O/C (0–100)', FieldKind.number, min: 0, max: 100),
    ),
    RepeatColumn(
      'store',
      'STORE',
      (fid) =>
          FieldSpec(fid, 'STORE (0–100)', FieldKind.number, min: 0, max: 100),
    ),
  ], hasTotal: true),
};

/// The 18-point inspection schema, in display order.
final List<InspectionSection> kInspectionSections = [
  InspectionSection(
    id: 'asm',
    title: 'Office',
    blurb:
        'Station Master readiness, slide frame overhauling and testing, yard diagram, working rule and fire safety.',
    items: [
      FieldFormItem(const FieldSpec('smName', 'SM Name', FieldKind.text)),
      FieldFormItem(
        const FieldSpec(
          'uniform',
          'In Proper Uniform',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'conversant',
          'Conversant with Train Operation',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      SubheadFormItem(
        'S.M. Slide Frame',
        note: 'Overhauling due every 3 years · Testing due every 1 year',
      ),
      FieldFormItem(
        const FieldSpec(
          'slideOverhaulDate',
          'Last Overhauling Date',
          FieldKind.dateOverdue,
          overdueYears: 3,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'slideTestDate',
          'Testing Date',
          FieldKind.dateOverdue,
          overdueYears: 1,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'slideLockingTest',
          'Locking Test Result',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      SubheadFormItem('Yard & Documentation'),
      FieldFormItem(
        const FieldSpec(
          'iyd',
          'Interlocked Yard Diagram (IYD)',
          FieldKind.toggle,
          options: ['Available', 'Not available'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'workingRule',
          'Station Working Rule',
          FieldKind.toggle,
          options: ['Available', 'Not available'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'ruleOfMonth',
          'Rule of the Month',
          FieldKind.toggle,
          options: ['Available', 'Not available'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'specialBulletin',
          'Special Bulletin',
          FieldKind.toggle,
          options: ['Available', 'Not available'],
        ),
      ),
      SubheadFormItem(
        'Fire Safety',
        note: 'Refill due every 1 year, per extinguisher',
      ),
      FieldFormItem(
        const FieldSpec(
          'fireExtCount',
          'Number of Fire Extinguishers',
          FieldKind.stepper,
          note: 'Use − / + to set how many are at this station.',
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'panel',
    title: 'Control & Indication Panel',
    blurb:
        'EBI screen / auto block panel — locking & sealing and functional indications.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'lockingSealing',
          'Locking & Sealing Available',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'signalIndications',
          'Signal Indications Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'trackIndications',
          'Track Indications Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'pointIndications',
          'Point Indications Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'powerIndications',
          'Power Indications Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'block',
    title: 'Block Instrument',
    blurb:
        "Neal's Token (10 yrs), Tyer's Block DL (7 yrs), Siemens token-less or axle counter — overhauling period is set automatically from the type selected.",
    items: [
      FieldFormItem(
        const FieldSpec(
          'blockType',
          'Block Instrument Type',
          FieldKind.select,
          options: [
            "Neal's Token",
            "Tyer's DL",
            'Siemens Token-Less',
            'Axle Counter',
          ],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'blockSealing',
          'Sealing & Locking Available',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'blockOverhaulDate',
          'Date of Overhauling',
          FieldKind.dateOverdue,
          overdueYears: 5,
          note: 'Overhauling period follows the instrument type above.',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'blockTestDate',
          'Date of Testing',
          FieldKind.dateOverdue,
          overdueYears: 1,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'blockTestResult',
          'Testing Result',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'phones',
    title: 'Magneto / Block Phones',
    blurb: 'Speech quality check and battery condition.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'speechQuality',
          'Speech Quality (Checked / Tested)',
          FieldKind.toggle,
          options: ['Good', 'Satisfactory', 'Poor'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'batteryCondition',
          '3V Battery Condition (1 = weak, 3 = good)',
          FieldKind.select,
          options: ['1', '2', '3'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'route',
    title: 'Route Testing',
    blurb: 'Route checks for up and down line movements.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'upRoute',
          'Route for Up Train — Checked Up Line',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'downRoute',
          'Route for Down Train — Checked Down Line',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'maint',
    title: 'Maintenance Schedules',
    blurb: 'Confirm scheduled maintenance has been carried out.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'sigMaintained',
          'Signal 101 / 103 / 105 / 107 Maintained',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'telecomMaintained',
          'Telecom Schedule Maintained',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'paint',
    title: 'Painting Programme',
    blurb: 'Three painting cycles, each with an automatic overdue calculation.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'paint1',
          'Painting Programme I — Date',
          FieldKind.dateOverdue,
          overdueYears: 1,
          note: 'Every 1 year',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'paint2',
          'Painting Programme II — Date',
          FieldKind.dateOverdue,
          overdueYears: 3,
          note: 'Every 3 years',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'paint3',
          'Painting Programme III — Date',
          FieldKind.dateOverdue,
          overdueYears: 5,
          note: 'Every 5 years',
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'battery',
    title: 'Batteries',
    blurb: 'Voltage readings — an out-of-range warning appears automatically.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'mainBattery',
          'Main Battery Voltage',
          FieldKind.decimal,
          unit: 'V',
          min: 55,
          max: 82.5,
          hint: 'Expected 55.0 – 82.5 V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'addBattery',
          'Additional Battery Voltage',
          FieldKind.decimal,
          unit: 'V',
          min: 55,
          max: 82.5,
          hint: 'Expected 55.0 – 82.5 V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'trackBattery',
          'Track Battery Voltage',
          FieldKind.decimal,
          unit: 'V',
          min: 13.2,
          max: 19.8,
          hint: 'Expected 13.2 – 19.8 V',
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'cabin',
    title: 'Overhauling & Testing — Cabin Lever Frames',
    blurb:
        'Frame A (East / North) and Frame B (West / South). Overhauling every 3 years, locking test every 1 year.',
    items: [
      SubheadFormItem('East North - A'),
      FieldFormItem(
        const FieldSpec(
          'cabinA_overhaulDate',
          'Overhauling Date',
          FieldKind.dateOverdue,
          overdueYears: 3,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinA_interlocking',
          'Interlocking of Levers',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinA_testDate',
          'Scheduled Locking Test Date',
          FieldKind.dateOverdue,
          overdueYears: 1,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinA_sealing',
          'Sealing Intact',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      SubheadFormItem('West South - B'),
      FieldFormItem(
        const FieldSpec(
          'cabinB_overhaulDate',
          'Overhauling Date',
          FieldKind.dateOverdue,
          overdueYears: 3,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinB_interlocking',
          'Interlocking of Levers',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinB_testDate',
          'Scheduled Locking Test Date',
          FieldKind.dateOverdue,
          overdueYears: 1,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'cabinB_sealing',
          'Sealing Intact',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'equipRoom',
    title: 'Equipment Room',
    blurb: 'Log book (BS-11) and room utilities.',
    items: [
      SubheadFormItem('Log Book — BS-11'),
      FieldFormItem(
        const FieldSpec(
          'logLastDate',
          'Last Date of Opening / Closing',
          FieldKind.date,
        ),
      ),
      FieldFormItem(
        const FieldSpec('logPurpose', 'Purpose of Opening', FieldKind.text),
      ),
      FieldFormItem(
        const FieldSpec('logAsm', 'ASM Name on Duty', FieldKind.text),
      ),
      SubheadFormItem('Room Utilities'),
      FieldFormItem(
        const FieldSpec(
          'ups',
          'UPS',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'staticInvertor',
          'Static Invertor',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'avr',
          'AVR',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'roomAc',
          'Air Conditioners',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'roomLights',
          'Lights',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'roomFans',
          'Fans',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'batteryRoom',
    title: 'Battery Room',
    blurb: 'Charger output and room utilities.',
    items: [
      FieldFormItem(
        const FieldSpec(
          'chargerFunctional',
          'Battery Charger Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
          note: 'Expected 55.0 – 82.5 V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'chargerOutputV',
          'Charger Output Voltage',
          FieldKind.decimal,
          unit: 'V',
          min: 55,
          max: 82.5,
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'brLights',
          'Lights Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'brFans',
          'Fans Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
    ],
  ),
  const InspectionSection(
    id: 'signals',
    title: 'Signals',
    blurb:
        'Foundation, pole, visibility, focus and lens condition for each fixed signal.',
    repeatType: 'signals',
  ),
  const InspectionSection(
    id: 'points',
    title: 'Testing / Inspection of Points',
    blurb:
        'Add a row for every point tested — gauge, packing, throw, switch condition and fittings.',
    repeatType: 'points',
  ),
  const InspectionSection(
    id: 'levelCrossing',
    title: 'Level Crossing in Yard',
    blurb: 'Add a row for every level crossing in the yard.',
    repeatType: 'lx',
  ),
  const InspectionSection(
    id: 'trackCircuit',
    title: 'Sample Test of Track Circuits',
    blurb:
        'Test at least 2–3 track circuits — feed / relay end voltages and IRJ / jumper / bond wire / track pod condition.',
    repeatType: 'tc',
  ),
  const InspectionSection(
    id: 'failures',
    title: 'Summary of Signal Failures',
    blurb:
        'Quarterly failure counts by department. The total is calculated automatically.',
    repeatType: 'failures',
  ),
  InspectionSection(
    id: 'telecom',
    title: 'Telecom Equipment',
    blurb:
        'VHF radio, PCP charger, UHF/MW radio, room utilities, diesel generator, towers and PA system.',
    items: [
      SubheadFormItem('VHF Radio (45–50 W)'),
      FieldFormItem(
        const FieldSpec(
          'vhfWorking',
          'Working',
          FieldKind.toggle,
          options: ['Working', 'Not working'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'vhfCondition',
          'Overall Condition',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'vhfPowerSupplyV',
          'Power Supply Voltage',
          FieldKind.decimal,
          unit: 'V',
          hint: 'Nominal 13.8 V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'vhfBatteryV',
          'Battery Voltage',
          FieldKind.decimal,
          unit: 'V',
          hint: 'Nominal 12 V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'vhfAntenna',
          'VHF Antenna Condition',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      SubheadFormItem('PCP Charger'),
      FieldFormItem(
        const FieldSpec(
          'pcpCondition',
          'Overall Condition',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'pcpOutputV',
          'Output Voltage',
          FieldKind.decimal,
          unit: 'V DC',
          hint: 'Nominal 26.4 V DC',
        ),
      ),
      SubheadFormItem('UHF / MW Radio'),
      FieldFormItem(
        const FieldSpec(
          'uhfBrand',
          'Battery Capacity / Brand Name',
          FieldKind.text,
        ),
      ),
      FieldFormItem(
        const FieldSpec('uhfSignal', 'Signal Strength', FieldKind.text),
      ),
      FieldFormItem(
        const FieldSpec(
          'uhfBatteryV',
          'Battery Voltage',
          FieldKind.decimal,
          unit: 'V',
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'uhfStatus',
          'Radio Functional',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      SubheadFormItem('Room & Comfort'),
      FieldFormItem(
        const FieldSpec(
          'telecomAc',
          'Air Conditioners (if installed)',
          FieldKind.toggle,
          options: ['Working', 'Not working'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'telecomLights',
          'Equipment Room Lights',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'telecomFans',
          'Fans / Exhaust',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      SubheadFormItem('Diesel Generator Set'),
      FieldFormItem(
        const FieldSpec(
          'dgSwitchStart',
          'Switch Start',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'dgCrankStart',
          'Crank Handle Start',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'dgStatus',
          'Status',
          FieldKind.toggle,
          options: ['Prime', 'Standby'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'dgLogbook',
          'Log Book Maintained',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      SubheadFormItem('Towers'),
      FieldFormItem(
        const FieldSpec(
          'towerType',
          'Type',
          FieldKind.toggle,
          options: ['Self-supported', 'Guys'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'towerPaint',
          'Paint Condition',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      FieldFormItem(const FieldSpec('towerHeight', 'Height', FieldKind.text)),
      FieldFormItem(
        const FieldSpec(
          'towerLight',
          'Tower Light',
          FieldKind.toggle,
          options: ['Functional', 'Non-functional'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'towerEarth',
          'Earth Connectivity',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'towerFencing',
          'Fencing',
          FieldKind.toggle,
          options: ['Yes', 'No'],
        ),
      ),
      FieldFormItem(
        const FieldSpec(
          'towerFoundation',
          'Foundation Condition',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
      SubheadFormItem('Public Address'),
      FieldFormItem(
        const FieldSpec(
          'paSystem',
          'PA System',
          FieldKind.toggleRemark,
          options: ['Satisfactory', 'Unsatisfactory'],
        ),
      ),
    ],
  ),
  InspectionSection(
    id: 'submit',
    title: 'Submitted By & Review',
    blurb: 'Sign off the inspection and generate a printable summary.',
    isReview: true,
    items: [
      /*FieldFormItem(const FieldSpec('submittedName', 'Name', FieldKind.text)),
      FieldFormItem(const FieldSpec('submittedDesignation', 'Designation', FieldKind.text)),*/
      FieldFormItem(const FieldSpec('submittedDate', 'Date', FieldKind.date)),
      FieldFormItem(
        const FieldSpec(
          'remarks',
          'Overall Remarks',
          FieldKind.textarea,
          placeholder: 'Any general observations for this inspection…',
        ),
      ),
    ],
  ),
];

/// Block-instrument overhaul period (years) keyed by the selected type,
/// mirroring the web proforma's auto-adjustment of the overhaul field.
const Map<String, int> kBlockOverhaulYears = {
  "Neal's Token": 10,
  "Tyer's DL": 7,
  'Siemens Token-Less': 5,
  'Axle Counter': 5,
};
