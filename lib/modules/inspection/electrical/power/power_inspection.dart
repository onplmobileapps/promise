import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/electrical/power/power_proformas.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_officer.dart';

/// The areas a power inspection covers, by code, as the server is sent
/// them.
const Map<String, String> _areas = {
  'STATION': 'Station',
  'WORKSHOP': 'Workshop',
  'SUB_STATION': 'Sub-Station',
  'SOLAR': 'Solar',
  'CROSSING': 'WAPDA Crossing',
};

bool _covers(ProformaAnswers answers, String area) {
  final areas = answers.field('applicable_areas');
  return areas is List && areas.contains(area);
}

/// One level of officer's electrical power inspection, sent to the power
/// inspections as [level].
ProformaDefinition _power(
  AppLocalizations l10n, {
  required String level,
  required String title,
  required List<ProformaSection> sections,
  bool byArea = false,
}) {
  final areas = [
    ProformaOption('STATION', l10n.inspPowerAreaStation),
    ProformaOption('WORKSHOP', l10n.inspPowerAreaWorkshop),
    ProformaOption('SUB_STATION', l10n.inspPowerAreaSubStation),
    ProformaOption('SOLAR', l10n.inspPowerAreaSolar),
    ProformaOption('CROSSING', l10n.inspPowerAreaCrossing),
  ];
  final yesNo = [
    ProformaOption('YES', l10n.inspYes),
    ProformaOption('NO', l10n.inspNo),
  ];
  return ProformaDefinition(
    id: 'power_${level.toLowerCase()}',
    title: l10n.inspPowerTitle,
    subtitle: title,
    glyph: AppGlyphs.zap,
    header: [
      ProformaField(
        'station',
        l10n.inspFormStation,
        ProformaFieldKind.station,
        required: true,
      ),
      ProformaField(
        'location',
        l10n.inspPowerLocation,
        ProformaFieldKind.text,
        required: true,
      ),
      ProformaField(
        'applicable_areas',
        l10n.inspPowerAreas,
        ProformaFieldKind.multi,
        options: areas,
        required: byArea,
        note: byArea ? l10n.inspPowerAreasNote : null,
      ),
      if (byArea)
        ProformaField(
          'sub_station_name',
          l10n.inspPowerSubStation,
          ProformaFieldKind.text,
          when: (answers) => _covers(answers, 'SUB_STATION'),
        ),
      ...officerFields(l10n),
    ],
    sections: sections,
    // The foreman inspects only the areas picked.
    shows: byArea ? (section, answers) => _covers(answers, section.key) : null,
    closing: [
      ProformaField(
        'previous_reviewed',
        l10n.inspPowerReviewed,
        ProformaFieldKind.choice,
        options: yesNo,
      ),
      ProformaField(
        'previous_rectified',
        l10n.inspPowerRectified,
        ProformaFieldKind.choice,
        options: yesNo,
      ),
      ProformaField(
        'previous_pending',
        l10n.inspPowerPending,
        ProformaFieldKind.choice,
        options: yesNo,
      ),
      ProformaField(
        'inspection_result',
        l10n.inspProformaResult,
        ProformaFieldKind.choice,
        options: resultOptions(l10n, graded: true),
        required: true,
      ),
      ProformaField(
        'overall_remarks',
        l10n.inspProformaRemarks,
        ProformaFieldKind.multiline,
      ),
    ],
    prefill: officerPrefill,
    describe: (answers) => answers.field('location')?.toString(),
    api: InspectionApi.power,
    payload: (context) {
      final picked = context.field('applicable_areas');
      final officer = context.text('inspecting_officer_name');
      final designation = context.text('designation');
      return {
        'officer_level': level,
        'division': ?context.user?.division,
        'station': ?context.field('station'),
        'location': context.text('location') ?? '',
        'applicable_areas': [
          for (final area in picked is List ? picked : const []) ?_areas[area],
        ].join(', '),
        'sub_station_name': ?context.text('sub_station_name'),
        'inspection_date': ?context.text('inspection_date'),
        'previous_reviewed': ?context.field('previous_reviewed'),
        'previous_rectified': ?context.field('previous_rectified'),
        'previous_pending': ?context.field('previous_pending'),
        'inspection_result': ?context.field('inspection_result'),
        'data': context.data,
        'signatures': [
          {
            'name_designation': [
              ?officer,
              if (designation != null) '($designation)',
            ].join(' '),
            'signed_date': ?context.text('inspection_date'),
          },
        ],
        'overall_remarks': context.text('overall_remarks') ?? '',
      };
    },
  );
}

/// The five levels' power proformas, with how often each is made.
List<({ProformaDefinition definition, String frequency})> powerDefinitions(
  AppLocalizations l10n,
) => [
  (
    definition: _power(
      l10n,
      level: 'FOREMAN',
      title: l10n.inspPowerForeman,
      sections: kPowerForemanSections,
      byArea: true,
    ),
    frequency: l10n.inspPowerForemanFrequency,
  ),
  (
    definition: _power(
      l10n,
      level: 'AEE',
      title: l10n.inspPowerAee,
      sections: kPowerAeeSections,
    ),
    frequency: l10n.inspPowerAeeFrequency,
  ),
  (
    definition: _power(
      l10n,
      level: 'DEE',
      title: l10n.inspPowerDee,
      sections: kPowerDeeSections,
    ),
    frequency: l10n.inspPowerDeeFrequency,
  ),
  (
    definition: _power(
      l10n,
      level: 'DY_CEE',
      title: l10n.inspPowerDyCee,
      sections: kPowerDyCeeSections,
    ),
    frequency: l10n.inspPowerDyCeeFrequency,
  ),
  (
    definition: _power(
      l10n,
      level: 'CEE',
      title: l10n.inspPowerCee,
      sections: kPowerCeeSections,
    ),
    frequency: l10n.inspPowerCeeFrequency,
  ),
];
