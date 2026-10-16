import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/services/civil_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/civil/widgets/civil_form_widgets.dart';
import 'package:railway_hrms/modules/inspection/civil/widgets/dynamic_civil_form.dart';

/// Renders any resolved [CivilFieldSpec] list as a full inspection form,
/// with the read-only Asset Details accordion on top, offline draft
/// save/resume, elapsed-time tracking, and GPS capture on submit — the
/// generic requirements from page 4 of the BRD.
class CivilAssetFormScreen extends StatefulWidget {
  final String department;
  final String subDepartment;
  final String asset;
  final List<CivilFieldSpec> fields;

  /// Unique id for this inspection instance, e.g.
  /// "civil_works_bridge_KHI-BR-014". Used as the draft/submission key.
  final String formId;

  const CivilAssetFormScreen({
    super.key,
    required this.department,
    required this.subDepartment,
    required this.asset,
    required this.fields,
    required this.formId,
  });

  @override
  State<CivilAssetFormScreen> createState() => _CivilAssetFormScreenState();
}

class _CivilAssetFormScreenState extends State<CivilAssetFormScreen> {
  final Map<String, dynamic> _answers = {};
  DateTime _startedAt = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final draft = await CivilInspectionDraftService.loadDraft(widget.formId);
    if (draft != null) {
      _answers.addAll(draft['answers'] as Map<String, dynamic>);
      _startedAt =
          DateTime.tryParse(draft['startedAt'] as String? ?? '') ??
          DateTime.now();
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Where the inspection is made, when location can be had. Only saves the
  /// user asks for may ask for location; saves made while typing never
  /// interrupt with a prompt.
  Future<Position?> _tryGetLocation({bool ask = true}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      final gate = sl<PermissionGate>();
      final allowed = ask && mounted
          ? await gate.request(AppPermission.location, context: context)
          : await gate.isGranted(AppPermission.location);
      if (!allowed) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      // Offline / no GPS fix — form still saves without coordinates,
      // per the BRD's offline-mode requirement.
      return null;
    }
  }

  Future<void> _saveDraft({bool silent = false}) async {
    setState(() => _saving = true);
    final pos = await _tryGetLocation(ask: !silent);
    await CivilInspectionDraftService.saveDraft(
      formId: widget.formId,
      answers: _answers,
      startedAt: _startedAt,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      department: widget.department,
      subDepartment: widget.subDepartment,
      asset: widget.asset,
    );
    setState(() => _saving = false);
    if (!silent && mounted) {
      showAppMessage(context, 'Draft saved', tone: AppDialogTone.success);
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final pos = await _tryGetLocation();
    final record = await CivilInspectionDraftService.submit(
      formId: widget.formId,
      answers: _answers,
      startedAt: _startedAt,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      department: widget.department,
      subDepartment: widget.subDepartment,
      asset: widget.asset,
    );
    setState(() => _saving = false);
    if (!mounted) return;

    final minutes = ((record['timeSpentSeconds'] as int) / 60).toStringAsFixed(
      1,
    );
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Inspection Submitted'),
        content: Text(
          'Time spent: $minutes min'
          '${pos == null ? '\n(coordinates unavailable — saved offline)' : ''}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(body: AppLoader.page());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.asset),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: _saving ? null : () => _saveDraft(),
          ),
        ],
      ),
      body: Column(
        children: [
          CivilAssetDetailsAccordion(
            department: widget.department,
            subDepartment: widget.subDepartment,
            asset: widget.asset,
            extraDetails: {'Inspection started': _formatTime(_startedAt)},
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: DynamicCivilForm(
                fields: widget.fields,
                answers: _answers,
                onChanged: () => _saveDraft(silent: true),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _saveDraft(),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
