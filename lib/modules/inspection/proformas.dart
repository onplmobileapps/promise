import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/electrical/power/power_inspection.dart';
import 'package:railway_hrms/modules/inspection/electrical/rtl/rtl_inspection.dart';
import 'package:railway_hrms/modules/inspection/locomotive/loco_proformas.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shed/shed_premises.dart';

/// Every inspection made on a proforma.
List<ProformaDefinition> allProformas(AppLocalizations l10n) => [
  for (final proforma in kLocoProformas) locoDefinition(l10n, proforma),
  shedPremisesDefinition(l10n),
  for (final power in powerDefinitions(l10n)) power.definition,
  for (final rtl in rtlDefinitions(l10n)) rtl.definition,
];

/// The proforma a saved inspection was made on, by its [id].
ProformaDefinition? proformaNamed(AppLocalizations l10n, String? id) {
  for (final definition in allProformas(l10n)) {
    if (definition.id == id) return definition;
  }
  return null;
}
