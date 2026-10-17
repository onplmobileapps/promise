import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_officer.dart';

const _satisfactory = [
  ProformaOption('Satisfactory'),
  ProformaOption('Unsatisfactory'),
];
const _satisfactoryFaults = {'Unsatisfactory'};
const _maintained = [
  ProformaOption('Maintained'),
  ProformaOption('Not Maintained'),
];
const _maintainedFaults = {'Not Maintained'};
const _working = [ProformaOption('Working'), ProformaOption('Not Working')];
const _workingFaults = {'Not Working'};

/// The shed inspection proforma's sections, as it numbers and words them.
const List<ProformaSection> kShedPremisesSections = [
  ProformaSection('GENERAL_CLEANLINESS', 'General Cleanliness', [
    ProformaItem(
      '1',
      'Condition of running shed/pits/floor',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '2',
      'Heavy repair shop',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '3',
      'Lubritorium room',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '4',
      'Offices of shed',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '5',
      'Sections of shed staff',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '6',
      'Lighting arrangements',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
  ]),
  ProformaSection('SCHEDULE_OFFICE', 'Schedule Office', [
    ProformaItem(
      '1',
      'MEDE-I/Revised form',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '2',
      'Locomotive running overdue register',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '3',
      'Maintenance schedule forms',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '4',
      'Trip/A-Schedule (attended/Not a)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '5',
      'C-Schedule',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '6',
      'D-Schedule',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '7',
      'E-Schedule',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '8',
      'Personal files of Locos',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '9',
      'Wheel profiles register (ME-30)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '10',
      'Repeated failure register (OP-191)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '11',
      'Register of Lube oil v/s fuel consumption',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '12',
      'AC (Assistant Chemist) Form (ME/DE-31-B/REV)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '13',
      'Kilometer/Mileage form (ME-41)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '14',
      'Performance of base shed Locomotives',
      options: _maintained,
      faults: _maintainedFaults,
    ),
  ]),
  ProformaSection('LABORATORY_RECORD', 'Laboratory · Record', [
    ProformaItem(
      '1',
      'Checking of lube oil viscosity',
      options: _maintained,
      faults: _maintainedFaults,
      note: '595-855 SUS',
    ),
    ProformaItem(
      '2',
      'Lube oil toping up record',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '3',
      'Lube oil analysis record (By Spectrometer Machine)',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '4',
      'Lube oil blotting paper record',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '5',
      'Lube oil moisture test record',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '6',
      'Water inhibitor record',
      options: _maintained,
      faults: _maintainedFaults,
    ),
  ]),
  ProformaSection('LABORATORY_APPARATUS', 'Laboratory · Apparatus', [
    ProformaItem('1', 'PH meter', options: _working, faults: _workingFaults),
    ProformaItem('2', 'Hot plate', options: _working, faults: _workingFaults),
    ProformaItem('3', 'Viscometer', options: _working, faults: _workingFaults),
    ProformaItem(
      '4',
      'Spectrometer machine',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem('5', 'TDS meter', options: _working, faults: _workingFaults),
    ProformaItem(
      '6',
      'Cleveland open cup (for flash point)',
      options: _working,
      faults: _workingFaults,
    ),
  ]),
  ProformaSection('STORE', 'Store', [
    ProformaItem(
      '1',
      'Vital item list',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '2',
      'Material Ledger card',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '3',
      'Consumable items',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '4',
      'Z- items',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '5',
      'Common user items',
      options: _maintained,
      faults: _maintainedFaults,
    ),
    ProformaItem(
      '6',
      'Tool & plant register',
      options: _maintained,
      faults: _maintainedFaults,
    ),
  ]),
  ProformaSection('HEAVY_REPAIR_SHOP', 'Heavy Repair Shop', [
    ProformaItem(
      '1',
      'Fuel Injection Pump & Nozzle Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '2',
      'Electric Panel Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '3',
      'Air Brake Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '4',
      'Truck Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '5',
      'Engine rebuild section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '6',
      'Power assembly section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '7',
      'Air Condition Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '8',
      'Pump Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '9',
      'Governor Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '10',
      'Auxiliary Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '11',
      'Traction Motor Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '12',
      'Millwright Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '13',
      'Air Compressor Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
    ProformaItem(
      '14',
      'Battery Section',
      options: _satisfactory,
      faults: _satisfactoryFaults,
    ),
  ]),
  ProformaSection('PLANT_MACHINERY', 'Plant & Machinery', [
    ProformaItem(
      '1',
      'Over Head Electric Crane',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem(
      '2',
      'Lifting Jacks',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem('3', 'RO Plant', options: _working, faults: _workingFaults),
    ProformaItem(
      '4',
      'Water Softening Plant',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem(
      '5',
      'Under Floor Wheel Lathe Machine',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem('6', 'Fork Lifter', options: _working, faults: _workingFaults),
    ProformaItem('7', 'Trucks', options: _working, faults: _workingFaults),
    ProformaItem('8', 'Fire Truck', options: _working, faults: _workingFaults),
    ProformaItem(
      '9',
      'Stationary air compressor',
      options: _working,
      faults: _workingFaults,
    ),
    ProformaItem(
      '10',
      'Steam / Gas Boiler',
      options: _working,
      faults: _workingFaults,
    ),
  ]),
];

/// The shed itself inspected: its cleanliness, schedule office,
/// laboratory, store, heavy repair shop and machinery. It has no server
/// yet, so it is kept on the phone, signed, with what it would send.
ProformaDefinition shedPremisesDefinition(AppLocalizations l10n) =>
    ProformaDefinition(
      id: 'shed_premises',
      title: l10n.inspShedPremisesTitle,
      subtitle: l10n.inspShedPremisesAbout,
      glyph: AppGlyphs.building,
      header: [
        ProformaField(
          'shed_name',
          l10n.inspProformaShed,
          ProformaFieldKind.text,
          required: true,
        ),
        ProformaField(
          'department',
          l10n.inspProformaDepartment,
          ProformaFieldKind.text,
        ),
        ...officerFields(l10n),
      ],
      sections: kShedPremisesSections,
      closing: [
        ProformaField(
          'inspection_result',
          l10n.inspProformaResult,
          ProformaFieldKind.choice,
          options: resultOptions(l10n),
          required: true,
        ),
        ProformaField(
          'overall_remarks',
          l10n.inspProformaRemarks,
          ProformaFieldKind.multiline,
        ),
      ],
      prefill: (user) => {...officerPrefill(user), 'department': 'Mechanical'},
      describe: (answers) => answers.field('shed_name')?.toString(),
      noteKey: 'remarks',
      noteLabel: l10n.inspFormRemarkLabel,
    );
