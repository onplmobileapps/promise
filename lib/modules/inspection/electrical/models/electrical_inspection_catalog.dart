import 'package:railway_hrms/modules/inspection/electrical/models/electrical_field_spec.dart';

/// Catalog for electrical inspection forms organized by department, sub-department, and asset.
/// Follows the BRD structure for Electrical department with Power and RTL sub-departments.
class ElectricalInspectionCatalog {
  /// Department -> Sub-department -> Assets hierarchy
  static const Map<String, Map<String, List<String>>> table = {
    'Electrical': {
      'Power': ['Workshop', 'Washing Line', 'Station', 'Staff Quarters'],
      'RTL': ['Workshop', 'Washing Line', 'Station'],
    },
  };

  /// Resolve field specifications for a given department, sub-department, and asset.
  /// Returns null if the combination requires a special/custom form screen.
  static List<ElectricalFieldSpec>? resolveFields(
    String department,
    String subDepartment,
    dynamic assets,
    Map<String, dynamic> assetData, {
    String role = 'Officer / Inspector',
  }) {
    if (department != 'Electrical') return null;

    final assetList = assets is List
        ? assets.cast<String>()
        : assets is Set
        ? assets.cast<String>().toList()
        : [assets.toString()];

    final mergedFields = <ElectricalFieldSpec>[];

    for (final asset in assetList) {
      List<ElectricalFieldSpec>? fields;
      switch (subDepartment) {
        case 'Power':
          fields = _resolvePowerFields(asset, assetData, role: role);
          break;
        case 'RTL':
          fields = _resolveRTLFields(asset, assetData, role: role);
          break;
      }

      if (fields != null && fields.isNotEmpty) {
        if (assetList.length > 1) {
          mergedFields.add(
            ElectricalFieldSpec.section('=== Asset: $asset ==='),
          );
        }
        mergedFields.addAll(fields);
      }
    }

    return mergedFields.isNotEmpty ? mergedFields : null;
  }

  static List<ElectricalFieldSpec> _resolvePowerFields(
    String asset,
    Map<String, dynamic> assetData, {
    String role = 'Officer / Inspector',
  }) {
    final roomAttributes =
        assetData['room_attributes'] as List<String>? ??
        ['AC', 'Fans', 'Lights', 'Ceiling', 'Windows', 'Door'];

    return ElectricalFieldSpecs.powerRoomFormSpec(roomAttributes, role: role);
  }

  static List<ElectricalFieldSpec> _resolveRTLFields(
    String asset,
    Map<String, dynamic> assetData, {
    String role = 'Officer / Inspector',
  }) {
    // If supervisory role DEE / AEE is selected
    if (role.toLowerCase().contains('dee') ||
        role.toLowerCase().contains('aee') ||
        role.toLowerCase().contains('supervis')) {
      return ElectricalFieldSpecs.rtlSupervisoryFormSpec(assetData, role: role);
    }

    switch (asset) {
      case 'Workshop':
        final coachType = assetData['coach_type']?.toString();
        final vanType = assetData['van_type']?.toString();
        if (coachType == 'Economy') {
          return ElectricalFieldSpecs.rtlEconomyWorkshopFormSpec(
            assetData,
            role: role,
          );
        } else if (vanType == 'Power Van' || vanType == 'TL Van') {
          return ElectricalFieldSpecs.rtlPowerVanWorkshopFormSpec(
            assetData,
            role: role,
          );
        }
        return ElectricalFieldSpecs.rtlWorkshopFormSpec(assetData, role: role);
      case 'Washing Line':
        return ElectricalFieldSpecs.rtlWashingLineFormSpec(
          assetData,
          role: role,
        );
      case 'Station':
        return ElectricalFieldSpecs.rtlStationFormSpec(assetData, role: role);
      default:
        return [];
    }
  }

  /// Check if a given combination requires a special/custom form screen
  /// rather than the generic dynamic form.
  static bool requiresCustomForm(
    String department,
    String subDepartment,
    String asset,
  ) {
    // Currently all electrical forms use the dynamic form system
    // This can be extended if specific assets need custom UI
    return false;
  }
}
