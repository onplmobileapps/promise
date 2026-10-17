import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_field_spec.dart';
import 'package:railway_hrms/modules/inspection/electrical/services/electrical_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_inspection_screen.dart';

/// An electrical asset's inspection, from its resolved questions: the
/// asset's details over each section as a step, a draft kept as it is
/// filled in, and the signed report kept on the phone at the end.
class ElectricalAssetFormScreen extends StatelessWidget {
  const ElectricalAssetFormScreen({
    super.key,
    required this.department,
    required this.subDepartment,
    required this.asset,
    required this.fields,
    required this.formId,
    this.assetData = const {},
    this.verifier,
  });

  final String department;
  final String subDepartment;
  final String asset;
  final List<ElectricalFieldSpec> fields;

  /// Unique id for this inspection instance, e.g.
  /// "electrical_power_workshop_room1". Used as the draft/submission key.
  final String formId;

  /// Additional asset data (coach details, etc.) for RTL inspections
  final Map<String, dynamic> assetData;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  static const _details = {
    'role': 'Inspecting role',
    'coach_type': 'Coach type',
    'category': 'Category',
    'ac_quantity': 'AC units',
    'dg_quantity': 'DG sets',
  };

  @override
  Widget build(BuildContext context) => SpecInspectionScreen(
    title: asset,
    subtitle: '$department · $subDepartment',
    specs: fields,
    glyph: AppGlyphs.zap,
    verifier: verifier,
    facts: [
      ('Department', department),
      ('Sub-department', subDepartment),
      ('Asset', asset),
      for (final MapEntry(:key, value: label) in _details.entries)
        if (assetData[key] case final Object value) (label, '$value'),
    ],
    store: _ElectricalStore(this),
  );
}

class _ElectricalStore implements SpecFormStore {
  const _ElectricalStore(this.form);

  final ElectricalAssetFormScreen form;

  @override
  Future<SpecDraft?> load() async {
    final draft = await ElectricalInspectionDraftService.loadDraft(form.formId);
    if (draft == null) return null;
    return (
      answers: Map<String, dynamic>.from(draft['answers'] as Map),
      startedAt:
          DateTime.tryParse('${draft['startedAt'] ?? ''}') ?? DateTime.now(),
      step: (draft['step'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> saveDraft(
    Map<String, dynamic> answers,
    DateTime startedAt, {
    int step = 0,
  }) => ElectricalInspectionDraftService.saveDraft(
    formId: form.formId,
    answers: answers,
    startedAt: startedAt,
    step: step,
    department: form.department,
    subDepartment: form.subDepartment,
    asset: form.asset,
    assetData: form.assetData,
  );

  @override
  Future<void> complete(
    Map<String, dynamic> answers,
    DateTime startedAt,
    InspectionSignatures signatures,
  ) => ElectricalInspectionDraftService.submit(
    formId: form.formId,
    answers: answers,
    startedAt: startedAt,
    latitude: signatures.submit?.latitude,
    longitude: signatures.submit?.longitude,
    department: form.department,
    subDepartment: form.subDepartment,
    asset: form.asset,
    assetData: form.assetData,
    verification: signatures.toJson(),
  );
}
