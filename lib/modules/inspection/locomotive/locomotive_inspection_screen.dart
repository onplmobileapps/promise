import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/locomotive/loco_proformas.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_launcher.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_officer.dart';
import 'package:railway_hrms/modules/inspection/shed/shed_premises.dart';

/// The officers' inspections of the year a locomotive proforma records.
ProformaTable _officers(AppLocalizations l10n) => ProformaTable(
  'OFFICER_INSPECTIONS',
  l10n.inspOfficersTable,
  [
    ProformaField('officer', l10n.inspOfficersName, ProformaFieldKind.text),
    ProformaField(
      'designation',
      l10n.inspProformaDesignation,
      ProformaFieldKind.text,
    ),
    ProformaField(
      'annual_quota',
      l10n.inspOfficersQuota,
      ProformaFieldKind.number,
    ),
    ProformaField(
      'last_inspection_date',
      l10n.inspOfficersLast,
      ProformaFieldKind.date,
    ),
  ],
  item: l10n.inspOfficersRow,
  about: l10n.inspOfficersTableAbout,
);

/// A locomotive of [proforma]'s class inspected at its shed, sent to the
/// shed's inspections as the proforma numbers it.
ProformaDefinition locoDefinition(
  AppLocalizations l10n,
  LocoProforma proforma,
) => ProformaDefinition(
  id: 'loco_${proforma.locoClass.replaceAll('/', '-')}',
  title: l10n.inspLocomotiveTitle,
  subtitle: proforma.locoClass,
  glyph: AppGlyphs.train,
  header: [
    ProformaField(
      'loco_number',
      l10n.inspProformaLocoNumber,
      ProformaFieldKind.text,
      required: true,
    ),
    ProformaField(
      'shed_name',
      l10n.inspProformaShed,
      ProformaFieldKind.text,
      required: true,
    ),
    ProformaField(
      'station',
      l10n.inspFormStation,
      ProformaFieldKind.station,
      required: true,
    ),
    ...officerFields(l10n),
  ],
  sections: proforma.sections,
  tables: [if (proforma.officers) _officers(l10n)],
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
  prefill: officerPrefill,
  describe: (answers) =>
      [proforma.locoClass, ?answers.field('loco_number')].join(' · '),
  api: InspectionApi.shed,
  noteKey: 'remarks',
  noteLabel: l10n.inspFormRemarkLabel,
  payload: (context) {
    final officers = context.answers.rowsOf('OFFICER_INSPECTIONS');
    final officer = context.text('inspecting_officer_name');
    final day = context.text('inspection_date');
    return {
      'loco_class': proforma.locoClass,
      'loco_number': ?context.text('loco_number'),
      'shed_name': ?context.text('shed_name'),
      'division': ?context.user?.division,
      'station': ?context.field('station'),
      'inspection_date': ?day,
      'inspecting_officer_name': ?officer,
      'designation': ?context.text('designation'),
      'inspection_result': ?context.field('inspection_result'),
      'data': {
        ...context.data,
        if (officers.isNotEmpty)
          'OFFICER_INSPECTIONS': {
            for (final (n, row) in officers.indexed) '${n + 1}': row,
          },
      },
      'signatures': [
        {
          'role': context.text('designation') ?? '',
          'name': officer ?? '',
          'signed_date': ?day,
        },
      ],
      'overall_remarks': context.text('overall_remarks') ?? '',
    };
  },
);

/// Loco and shed inspections: a locomotive of any class the shed keeps,
/// each on its own proforma, or the shed itself.
class LocomotiveInspectionScreen extends StatelessWidget {
  const LocomotiveInspectionScreen({super.key, this.verifier});

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shed = shedPremisesDefinition(l10n);
    return ProformaLauncher(
      title: l10n.inspLocomotive,
      subtitle: l10n.inspLocomotiveAbout,
      verifier: verifier,
      groups: [
        ProformaGroup(l10n.inspProformaClass, [
          for (final proforma in kLocoProformas)
            ProformaChoice(
              locoDefinition(l10n, proforma),
              title: proforma.locoClass,
              subtitle: l10n.inspProformaSize(
                proforma.sections.length,
                proforma.sections.fold(
                  0,
                  (sum, section) => sum + section.items.length,
                ),
              ),
              glyph: AppGlyphs.train,
            ),
        ]),
        ProformaGroup(l10n.inspShedPremises, [
          ProformaChoice(
            shed,
            title: shed.title,
            subtitle: l10n.inspShedPremisesAbout,
            glyph: AppGlyphs.building,
          ),
        ]),
      ],
    );
  }
}
