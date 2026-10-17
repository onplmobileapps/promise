import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/services/electrical_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_catalog_home.dart';

/// Electrical inspections: pick the department, sub-department and asset,
/// or look back over those finished on this phone.
class ElectricalInspectionHomeScreen extends StatelessWidget {
  const ElectricalInspectionHomeScreen({super.key});

  /// The coach an RTL asset is inspected on. There is no coach register to
  /// pick from yet, so this stands in; it decides which checks are asked.
  static const _rtlCoach = {
    'coach_type': 'German',
    'category': 'AC Sleeper',
    'dining': true,
    'sleeper': true,
    'parlour': false,
    'destination_board': 'Electrical',
    'ac_quantity': 2,
    'dg_quantity': 1,
    'fire_extinguishers_quantity': 2,
    'lights_door': 2,
    'lights_hall': 4,
    'lights_toilet': 2,
    'lights_panel': 1,
    'fans': 8,
    'shades': 4,
    'mobile_charging_units': 4,
  };

  Future<void> _open(
    BuildContext context,
    String department,
    String subDepartment,
    String asset,
  ) async {
    final navigator = Navigator.of(context);
    final assetData = subDepartment == 'RTL'
        ? _rtlCoach
        : const <String, dynamic>{};
    final fields = ElectricalInspectionCatalog.resolveFields(
      department,
      subDepartment,
      asset,
      assetData,
    );
    if (fields == null) return;
    final formId = 'electrical_${department}_${subDepartment}_$asset'
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ElectricalAssetFormScreen(
          department: department,
          subDepartment: subDepartment,
          asset: asset,
          fields: fields,
          formId: formId,
          assetData: assetData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => InspectionCatalogHome(
    title: context.l10n.inspElectrical,
    subtitle: context.l10n.inspElectricalSubtitle,
    glyph: AppGlyphs.zap,
    table: ElectricalInspectionCatalog.table,
    onOpen: _open,
    history: ElectricalInspectionDraftService.getSubmittedRecords,
  );
}
