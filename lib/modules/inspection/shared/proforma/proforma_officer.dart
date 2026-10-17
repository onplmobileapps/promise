import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';

/// The facts every inspection by an officer starts with: the day, and
/// who inspected, as the signed-in employee unless changed.
List<ProformaField> officerFields(AppLocalizations l10n) => [
  ProformaField(
    'inspection_date',
    l10n.inspFormDate,
    ProformaFieldKind.date,
    required: true,
  ),
  ProformaField(
    'inspecting_officer_name',
    l10n.inspProformaOfficer,
    ProformaFieldKind.text,
    required: true,
  ),
  ProformaField(
    'designation',
    l10n.inspProformaDesignation,
    ProformaFieldKind.text,
  ),
];

/// The day and the signed-in employee, filled in for a new inspection.
Map<String, Object?> officerPrefill(User? user) {
  // A name the server sent in parts, without the parts it left out.
  final full = (user?.fullName ?? '')
      .split(' ')
      .where((part) => part.isNotEmpty && part != 'null')
      .join(' ');
  return {
    'inspection_date': proformaDay(DateTime.now()),
    'inspecting_officer_name': full.isNotEmpty ? full : user?.name?.trim(),
    'designation': user?.designation?.trim(),
  };
}

/// An inspection's overall result, as the server takes it.
List<ProformaOption> resultOptions(
  AppLocalizations l10n, {
  bool graded = false,
}) => [
  ProformaOption('SATISFACTORY', l10n.inspResultSatisfactory),
  if (graded) ProformaOption('NEEDS_IMPROVEMENT', l10n.inspResultImprove),
  ProformaOption('UNSATISFACTORY', l10n.inspResultUnsatisfactory),
  if (graded) ProformaOption('CRITICAL_DEFICIENCY', l10n.inspResultCritical),
];
