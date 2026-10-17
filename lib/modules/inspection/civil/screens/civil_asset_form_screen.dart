import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/services/civil_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_inspection_screen.dart';

/// A civil asset's inspection, from its resolved questions: the asset's
/// details over each section as a step, a draft kept as it is filled in,
/// and the signed report kept on the phone at the end.
class CivilAssetFormScreen extends StatelessWidget {
  const CivilAssetFormScreen({
    super.key,
    required this.department,
    required this.subDepartment,
    required this.asset,
    required this.fields,
    required this.formId,
    this.verifier,
  });

  final String department;
  final String subDepartment;
  final String asset;
  final List<CivilFieldSpec> fields;

  /// Unique id for this inspection instance, e.g.
  /// "civil_works_bridge_KHI-BR-014". Used as the draft/submission key.
  final String formId;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => SpecInspectionScreen(
    title: asset,
    subtitle: '$department · $subDepartment',
    specs: fields,
    glyph: AppGlyphs.building,
    verifier: verifier,
    facts: [
      ('Department', department),
      ('Sub-department', subDepartment),
      ('Asset', asset),
    ],
    store: _CivilStore(this),
  );
}

class _CivilStore implements SpecFormStore {
  const _CivilStore(this.form);

  final CivilAssetFormScreen form;

  @override
  Future<SpecDraft?> load() async {
    final draft = await CivilInspectionDraftService.loadDraft(form.formId);
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
  }) => CivilInspectionDraftService.saveDraft(
    formId: form.formId,
    answers: answers,
    startedAt: startedAt,
    step: step,
    department: form.department,
    subDepartment: form.subDepartment,
    asset: form.asset,
  );

  @override
  Future<void> complete(
    Map<String, dynamic> answers,
    DateTime startedAt,
    InspectionSignatures signatures,
  ) => CivilInspectionDraftService.submit(
    formId: form.formId,
    answers: answers,
    startedAt: startedAt,
    latitude: signatures.submit?.latitude,
    longitude: signatures.submit?.longitude,
    department: form.department,
    subDepartment: form.subDepartment,
    asset: form.asset,
    verification: signatures.toJson(),
  );
}
