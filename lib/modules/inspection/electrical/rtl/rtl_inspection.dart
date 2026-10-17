import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/electrical/rtl/rtl_proformas.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_officer.dart';

/// Where a train lighting inspection is made.
abstract final class RtlPoint {
  static const station = 'STATION';
  static const washingline = 'WASHINGLINE';
  static const workshop = 'WORKSHOP';
}

/// What a workshop inspection is of, and the sections that inspect it.
const Map<String, List<String>> _workshopSections = {
  'AC_COACH': ['AC_COACH', 'AC_COACH_TESTS'],
  'ECONOMY_COACH': ['ECONOMY_COACH', 'ECONOMY_COACH_MEGGER'],
  'POWER_VAN': ['POWER_VAN_WORKSHOP', 'POWER_VAN_TESTS'],
};

/// The field inspection's sections at [point]: a coach and its power van
/// at a station or a washingline; at the workshop, the coach or van being
/// worked on, and its release.
bool _fieldShows(ProformaSection section, ProformaAnswers answers) =>
    switch (answers.field('inspection_point')) {
      RtlPoint.station => const {'STATION', 'POWER_VAN'}.contains(section.key),
      RtlPoint.washingline => const {
        'WASHINGLINE',
        'WASHINGLINE_POWER_VAN',
      }.contains(section.key),
      RtlPoint.workshop =>
        section.key == 'RELEASE' ||
            (_workshopSections[answers.field('rolling_stock')] ?? const [])
                .contains(section.key),
      _ => false,
    };

bool _atWorkshop(ProformaAnswers answers) =>
    answers.field('inspection_point') == RtlPoint.workshop;

/// One of the four train lighting inspection proformas, each made by its
/// level of officer, sent to the RTL inspections as [code].
ProformaDefinition _rtl(
  AppLocalizations l10n, {
  required String code,
  required String title,
  required String role,
  required List<ProformaSection> sections,
  bool Function(ProformaSection section, ProformaAnswers answers)? shows,
  bool field = false,
}) {
  final points = [
    ProformaOption(RtlPoint.station, l10n.inspRtlPointStation),
    ProformaOption(RtlPoint.washingline, l10n.inspRtlPointWashingline),
    ProformaOption(RtlPoint.workshop, l10n.inspRtlPointWorkshop),
  ];
  return ProformaDefinition(
    id: 'rtl_${code.toLowerCase()}',
    title: l10n.inspRtlTitle,
    subtitle: title,
    glyph: AppGlyphs.zap,
    header: [
      ProformaField(
        'inspection_point',
        l10n.inspRtlPoint,
        ProformaFieldKind.choice,
        options: points,
        required: true,
      ),
      if (field) ...[
        ProformaField(
          'rolling_stock',
          l10n.inspRtlStock,
          ProformaFieldKind.choice,
          options: [
            ProformaOption('AC_COACH', l10n.inspRtlStockAc),
            ProformaOption('ECONOMY_COACH', l10n.inspRtlStockEconomy),
            ProformaOption('POWER_VAN', l10n.inspRtlStockPowerVan),
          ],
          required: true,
          when: _atWorkshop,
        ),
        ProformaField(
          'work_stage',
          l10n.inspRtlStage,
          ProformaFieldKind.choice,
          options: [
            ProformaOption('POH', l10n.inspRtlStagePoh),
            ProformaOption('FIRST_STAGE', l10n.inspRtlStageFirst),
            ProformaOption('FINAL_STAGE', l10n.inspRtlStageFinal),
            ProformaOption('REPAIR', l10n.inspRtlStageRepair),
            ProformaOption('OTHER', l10n.inspRtlStageOther),
          ],
          when: _atWorkshop,
        ),
        ProformaField(
          'cause_date_received',
          l10n.inspRtlCause,
          ProformaFieldKind.text,
          when: _atWorkshop,
        ),
      ],
      ProformaField(
        'station',
        l10n.inspFormStation,
        ProformaFieldKind.station,
        required: true,
      ),
      ...officerFields(l10n),
      ProformaField(
        'train_coach_pv_no',
        l10n.inspRtlTrain,
        ProformaFieldKind.text,
      ),
      ProformaField(
        'class_make_capacity',
        l10n.inspRtlClass,
        ProformaFieldKind.text,
      ),
      ProformaField(
        'previous_inspection_date',
        l10n.inspRtlPreviousDate,
        ProformaFieldKind.date,
      ),
      ProformaField(
        'previous_outstanding_defects',
        l10n.inspRtlPreviousDefects,
        ProformaFieldKind.multiline,
      ),
    ],
    sections: sections,
    shows: shows,
    closing: [
      if (field)
        ProformaField(
          'maintenance_incharge',
          l10n.inspRtlIncharge,
          ProformaFieldKind.text,
        ),
      ProformaField(
        'overall_remarks',
        l10n.inspProformaRemarks,
        ProformaFieldKind.multiline,
      ),
    ],
    prefill: officerPrefill,
    describe: (answers) {
      String? labelOf(Object? code) {
        for (final point in points) {
          if (point.code == code) return point.label;
        }
        return null;
      }

      final parts = [
        ?labelOf(answers.field('inspection_point')),
        ?answers.field('train_coach_pv_no')?.toString(),
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    },
    api: InspectionApi.rtl,
    payload: (context) {
      final day = context.text('inspection_date');
      final workshop = _atWorkshop(context.answers);
      return {
        'proforma': code,
        'inspection_point': ?context.field('inspection_point'),
        'division': ?context.user?.division,
        'station': ?context.field('station'),
        'inspection_date': ?day,
        'train_coach_pv_no': context.text('train_coach_pv_no') ?? '',
        'class_make_capacity': context.text('class_make_capacity') ?? '',
        'previous_inspection_date': ?context.text('previous_inspection_date'),
        'previous_outstanding_defects':
            context.text('previous_outstanding_defects') ?? '',
        if (workshop) ...{
          'rolling_stock': ?context.field('rolling_stock'),
          'work_stage': ?context.field('work_stage'),
          'cause_date_received': ?context.text('cause_date_received'),
        },
        'data': context.data,
        'signatures': [
          if (context.text('maintenance_incharge') case final incharge?)
            {
              'role': 'Maintenance In-charge',
              'name': incharge,
              'signed_date': ?day,
            },
          {
            'role': role,
            'name': context.text('inspecting_officer_name') ?? '',
            'signed_date': ?day,
          },
        ],
        'overall_remarks': context.text('overall_remarks') ?? '',
      };
    },
  );
}

/// The four train lighting proformas, by officer, with how often each
/// is made.
List<({ProformaDefinition definition, String frequency})> rtlDefinitions(
  AppLocalizations l10n,
) => [
  (
    definition: _rtl(
      l10n,
      code: 'EFO_AEFO_FIELD',
      title: l10n.inspRtlEfo,
      role: 'EFO / AEFO',
      sections: kRtlFieldSections,
      shows: _fieldShows,
      field: true,
    ),
    frequency: l10n.inspRtlEfoFrequency,
  ),
  (
    definition: _rtl(
      l10n,
      code: 'DEE_AEE_SUPERVISORY',
      title: l10n.inspRtlDee,
      role: 'DEE / AEE',
      sections: kRtlSupervisorySections,
      // The records are verified at the washing line.
      shows: (section, answers) =>
          section.key != 'RECORDS' ||
          answers.field('inspection_point') == RtlPoint.washingline,
    ),
    frequency: l10n.inspRtlDeeFrequency,
  ),
  (
    definition: _rtl(
      l10n,
      code: 'DY_CEE_DIVISIONAL',
      title: l10n.inspRtlDyCee,
      role: 'Dy. CEE',
      sections: kRtlDivisionalSections,
    ),
    frequency: l10n.inspRtlDyCeeFrequency,
  ),
  (
    definition: _rtl(
      l10n,
      code: 'CEE_DEPARTMENTAL',
      title: l10n.inspRtlCee,
      role: 'CEE',
      sections: kRtlDepartmentalSections,
    ),
    frequency: l10n.inspRtlCeeFrequency,
  ),
];
