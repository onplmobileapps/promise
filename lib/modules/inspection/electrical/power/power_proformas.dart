// The electrical power inspection proformas, one for each level of
// officer, as the proforma document numbers and words them. Written from
// that document; change it there first.

import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';

/// The Electrical Foreman / Sub-Engineer's inspection, area by area.
const List<ProformaSection> kPowerForemanSections = [
  ProformaSection('STATION', 'Station Electrical Installation', [
    ProformaItem(
      '1',
      'Lighting arrangements',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '2',
      'Fans',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '3',
      'HT / LT network',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '4',
      'Water cooler / chiller',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '5',
      'Air conditioners',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '6',
      'Attendance & store records',
      options: [
        ProformaOption('Properly Maintained'),
        ProformaOption('Not Maintained'),
        ProformaOption('Wrongly managed'),
      ],
      faults: {'Not Maintained', 'Wrongly managed'},
    ),
    ProformaItem(
      '7',
      'WAPDA KWH meter',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Improper reading'),
      ],
      faults: {'Not working', 'Improper reading'},
    ),
    ProformaItem(
      '8',
      'Pumping plant',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '9',
      'DG set',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '10',
      'DG Set log book',
      options: [
        ProformaOption('Properly Maintained'),
        ProformaOption('Not Maintained'),
        ProformaOption('Wrongly managed'),
      ],
      faults: {'Not Maintained', 'Wrongly managed'},
    ),
    ProformaItem(
      '11.1',
      'Panels cleanliness',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar System',
    ),
    ProformaItem(
      '11.2',
      'Inverter',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Solar System',
    ),
    ProformaItem(
      '11.3',
      'Batteries',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Solar System',
    ),
    ProformaItem(
      '11.4',
      'Mounting structure',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar System',
    ),
    ProformaItem(
      '11.5',
      'Earthing condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar System',
    ),
  ]),
  ProformaSection('WORKSHOP', 'Workshop', [
    ProformaItem(
      '1',
      'Lighting arrangements',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '2',
      'HT / LT network',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '3',
      'Electrical motors',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '4',
      'Electrical traverser',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '5',
      'Water coolers',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '6',
      'Pumping plant',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '7',
      'DG set',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '8',
      'Office Records',
      options: [
        ProformaOption('Properly Maintained'),
        ProformaOption('Not Maintained'),
        ProformaOption('Wrongly managed'),
      ],
      faults: {'Not Maintained', 'Wrongly managed'},
    ),
  ]),
  ProformaSection('SUB_STATION', 'Sub-Station', [
    ProformaItem(
      '1',
      'HT Panel Condition',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '2',
      'LT Panel Condition',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '3',
      'Transformer',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '4',
      'Earthing Condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
        ProformaOption('Not available'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '5',
      'Lighting Arrestor',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
  ]),
  ProformaSection('SOLAR', 'Solar', [
    ProformaItem(
      '1',
      'Solar panels',
      options: [
        ProformaOption('Clean'),
        ProformaOption('Dusty'),
        ProformaOption('Damaged'),
      ],
      faults: {'Dusty', 'Damaged'},
    ),
    ProformaItem(
      '2',
      'Inverter',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '3',
      'Batteries',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '4',
      'MCCB / protection',
      options: [
        ProformaOption('Working'),
        ProformaOption('Not working'),
        ProformaOption('Not available'),
      ],
      faults: {'Not working'},
    ),
    ProformaItem(
      '5',
      'Wiring / connections',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
        ProformaOption('Not available'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '6',
      'Mounting structure condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
        ProformaOption('Not available'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '7',
      'Earthing',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
        ProformaOption('Not available'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '8',
      'Energy Generation (KWH)',
      options: [ProformaOption('Produced'), ProformaOption('Not produced')],
      faults: {'Not produced'},
    ),
    ProformaItem(
      '9',
      'Log book',
      options: [
        ProformaOption('Properly Maintained'),
        ProformaOption('Not Maintained'),
        ProformaOption('Wrongly managed'),
      ],
      faults: {'Not Maintained', 'Wrongly managed'},
    ),
  ]),
  ProformaSection('CROSSING', 'WAPDA Overhead / Underground Crossing', [
    ProformaItem(
      '1',
      'Authorization status',
      options: [ProformaOption('Authorized'), ProformaOption('Un-authorized')],
      faults: {'Un-authorized'},
    ),
    ProformaItem(
      '2',
      'Guard wire / mesh',
      options: [ProformaOption('Provided'), ProformaOption('Not provided')],
      faults: {'Not provided'},
    ),
    ProformaItem(
      '3',
      'Pole foundation',
      options: [ProformaOption('Provided'), ProformaOption('Not provided')],
      faults: {'Not provided'},
    ),
    ProformaItem(
      '4',
      'Earthing',
      options: [ProformaOption('Provided'), ProformaOption('Not provided')],
      faults: {'Not provided'},
    ),
    ProformaItem(
      '5',
      'Anti-climbing device',
      options: [ProformaOption('Provided'), ProformaOption('Not provided')],
      faults: {'Not provided'},
    ),
    ProformaItem(
      '6',
      'Stay / guys',
      options: [ProformaOption('Provided'), ProformaOption('Not provided')],
      faults: {'Not provided'},
    ),
    ProformaItem(
      '7',
      'Danger board',
      options: [ProformaOption('Upto Standard'), ProformaOption('Inadequate')],
      faults: {'Inadequate'},
    ),
    ProformaItem(
      '8',
      'Vertical clearance',
      options: [ProformaOption('Upto Standard'), ProformaOption('Inadequate')],
      faults: {'Inadequate'},
    ),
    ProformaItem(
      '9',
      'Horizontal clearance',
      options: [ProformaOption('Upto Standard'), ProformaOption('Inadequate')],
      faults: {'Inadequate'},
    ),
  ]),
];

/// The Assistant Electrical Engineer's inspection.
const List<ProformaSection> kPowerAeeSections = [
  ProformaSection('CHECKLIST', 'Inspection Checklist', [
    ProformaItem(
      '1',
      'Foreman inspection review',
      options: [ProformaOption('Complete'), ProformaOption('Deficient')],
      faults: {'Deficient'},
    ),
    ProformaItem(
      '2.1',
      'Lighting arrangement',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '2.2',
      'Fan',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '2.3',
      'AC / Cooler',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '2.4',
      'Water Cooler',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '2.5',
      'DG Sets',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '2.6',
      'DISCO KWH meter',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Station facilities',
    ),
    ProformaItem(
      '3.1',
      'HT / LT Panel',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Sub-Station',
    ),
    ProformaItem(
      '3.2',
      'Transformer',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Sub-Station',
    ),
    ProformaItem(
      '3.3',
      'Earthing Condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Sub-Station',
    ),
    ProformaItem(
      '4',
      'DG Sets',
      options: [ProformaOption('Working'), ProformaOption('Not Working')],
      faults: {'Not Working'},
    ),
    ProformaItem(
      '5',
      'Pumping plant',
      options: [ProformaOption('Working'), ProformaOption('Not Working')],
      faults: {'Not Working'},
    ),
    ProformaItem(
      '6.1',
      'Panels cleanliness',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar performance',
    ),
    ProformaItem(
      '6.2',
      'Inverter',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Solar performance',
    ),
    ProformaItem(
      '6.3',
      'Batteries',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
      group: 'Solar performance',
    ),
    ProformaItem(
      '6.4',
      'Mounting structure',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar performance',
    ),
    ProformaItem(
      '6.5',
      'Earthing condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
      group: 'Solar performance',
    ),
    ProformaItem(
      '7',
      'Crossing safety',
      options: [ProformaOption('Available'), ProformaOption('Not Available')],
      faults: {'Not Available'},
    ),
    ProformaItem(
      '8',
      'Corrective action',
      options: [ProformaOption('Due'), ProformaOption('Not Due')],
      faults: {'Due'},
    ),
  ]),
];

/// The Divisional Electrical Engineer's inspection of stations.
const List<ProformaSection> kPowerDeeSections = [
  ProformaSection('CHECKLIST', 'Inspection Checklist for Stations', [
    ProformaItem(
      '1',
      'Review of AEE/Foreman Inspection',
      options: [ProformaOption('Complete'), ProformaOption('Deficient')],
      faults: {'Deficient'},
    ),
    ProformaItem(
      '2',
      'Station / platform facilities',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '3',
      'Sub-station maintenance status and record',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '4',
      'DG Sets status',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
    ),
    ProformaItem(
      '5',
      'DG Sets Log Book',
      options: [ProformaOption('Maintained'), ProformaOption('Not Maintained')],
      faults: {'Not Maintained'},
    ),
    ProformaItem(
      '6',
      'Pumping plants',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
    ),
    ProformaItem(
      '7',
      'Solar installations',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '8',
      'Crossings safety',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '9',
      'Attendance and store record',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '10',
      'Reporting',
      options: [ProformaOption('Submitted'), ProformaOption('Not Submitted')],
      faults: {'Not Submitted'},
    ),
  ]),
];

/// The Deputy Chief Electrical Engineer's inspection.
const List<ProformaSection> kPowerDyCeeSections = [
  ProformaSection('CHECKLIST', 'Inspection Checklist', [
    ProformaItem(
      '1',
      'Safety compliance',
      options: [ProformaOption('Compliant'), ProformaOption('Deficient')],
      faults: {'Deficient'},
    ),
    ProformaItem(
      '2',
      'Recurring defects',
      options: [ProformaOption('Exist'), ProformaOption('Not exist')],
      faults: {'Exist'},
    ),
    ProformaItem(
      '3',
      'Records maintenance',
      options: [ProformaOption('Correct'), ProformaOption('Not correct')],
      faults: {'Not correct'},
    ),
    ProformaItem(
      '4',
      'Station facilities',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '5',
      'DG Sets',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
    ),
    ProformaItem(
      '6',
      'Pumping plant',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
    ),
    ProformaItem(
      '7',
      'Solar condition',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
    ProformaItem(
      '8',
      'Crossing safety',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not satisfactory'),
      ],
      faults: {'Not satisfactory'},
    ),
  ]),
];

/// The Chief Electrical Engineer's inspection.
const List<ProformaSection> kPowerCeeSections = [
  ProformaSection('CHECKLIST', 'Inspection Checklist', [
    ProformaItem(
      '1',
      'Review all levels inspection report',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '2',
      'Safety compliance',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '3',
      'Station facilities',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '4',
      'Sub-station maintenance',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '5',
      'DG Set Maintenance',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '6',
      'Pumping plant',
      options: [ProformaOption('Working'), ProformaOption('Not working')],
      faults: {'Not working'},
    ),
    ProformaItem(
      '7',
      'Solar Maintenance',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '8',
      'Crossings / public safety',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
    ProformaItem(
      '9',
      'Office Records',
      options: [
        ProformaOption('Satisfactory'),
        ProformaOption('Not Satisfactory'),
      ],
      faults: {'Not Satisfactory'},
    ),
  ]),
];
