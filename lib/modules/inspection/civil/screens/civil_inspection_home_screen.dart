import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/civil/services/civil_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_catalog_home.dart';

/// Civil inspections: pick the department, sub-department and asset, or
/// look back over those finished on this phone.
class CivilInspectionHomeScreen extends StatelessWidget {
  const CivilInspectionHomeScreen({super.key});

  Future<void> _open(
    BuildContext context,
    String department,
    String subDepartment,
    String asset,
  ) async {
    final navigator = Navigator.of(context);
    final fields = CivilDeptAssetMap.resolveFields(
      department,
      subDepartment,
      asset,
    );
    if (fields == null) {
      // Sleepers, rails and sidings are walked stretch by stretch.
      await navigator.pushNamed(AppRoutes.civilInspectionSleepersRails);
      return;
    }
    final formId = 'civil_${department}_${subDepartment}_$asset'
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CivilAssetFormScreen(
          department: department,
          subDepartment: subDepartment,
          asset: asset,
          fields: fields,
          formId: formId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => InspectionCatalogHome(
    title: context.l10n.inspCivilTitle,
    subtitle: context.l10n.inspCivilSubtitle,
    glyph: AppGlyphs.building,
    table: CivilDeptAssetMap.table,
    onOpen: _open,
    history: CivilInspectionDraftService.getSubmittedRecords,
  );
}
