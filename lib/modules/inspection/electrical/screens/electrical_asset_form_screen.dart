import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/device_utils.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_field_spec.dart';
import 'package:railway_hrms/modules/inspection/electrical/services/electrical_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/electrical/widgets/dynamic_electrical_form.dart';
import 'package:railway_hrms/modules/inspection/electrical/widgets/electrical_form_widgets.dart';

/// Renders any resolved [ElectricalFieldSpec] list as a full inspection form,
/// with the read-only Asset Details accordion on top, offline draft
/// save/resume, elapsed-time tracking, and GPS capture on submit — the
/// generic requirements from page 4 of the BRD.
class ElectricalAssetFormScreen extends StatefulWidget {
  final String department;
  final String subDepartment;
  final String asset;
  final List<ElectricalFieldSpec> fields;

  /// Unique id for this inspection instance, e.g.
  /// "electrical_power_workshop_room1". Used as the draft/submission key.
  final String formId;

  /// Additional asset data (coach details, etc.) for RTL inspections
  final Map<String, dynamic> assetData;

  const ElectricalAssetFormScreen({
    super.key,
    required this.department,
    required this.subDepartment,
    required this.asset,
    required this.fields,
    required this.formId,
    this.assetData = const {},
  });

  @override
  State<ElectricalAssetFormScreen> createState() =>
      _ElectricalAssetFormScreenState();
}

class _ElectricalAssetFormScreenState extends State<ElectricalAssetFormScreen> {
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
    final draft = await ElectricalInspectionDraftService.loadDraft(
      widget.formId,
    );
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
    await ElectricalInspectionDraftService.saveDraft(
      formId: widget.formId,
      answers: _answers,
      startedAt: _startedAt,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      department: widget.department,
      subDepartment: widget.subDepartment,
      asset: widget.asset,
      assetData: widget.assetData,
    );
    setState(() => _saving = false);
    if (!silent && mounted) {
      showAppMessage(context, 'Draft saved', tone: AppDialogTone.success);
    }
  }

  Future<bool> _verifyFace() async {
    setState(() => _saving = true);
    try {
      final result = await DeviceUtils.performFaceVerification(context);
      if (result == null || result.images.isEmpty) {
        setState(() => _saving = false);
        return false;
      }

      final user = await StorageService.getUser();
      final employeeId = user?.user?.empid.toString() ?? '';
      final position = await CurrentLocationService.getCurrentLocation();
      final latitude = position?.latitude ?? 0.0;
      final longitude = position?.longitude ?? 0.0;

      final List<MultipartFile> multipartImages = [];
      for (var img in result.images) {
        multipartImages.add(
          await MultipartFile.fromFile(img.path, filename: img.name),
        );
      }

      final repo = sl<FaceRepository>();
      final responseEither = await repo.verifyFace(
        employeeId,
        multipartImages,
        result.embeddings,
        latitude,
        longitude,
      );

      bool isVerified = false;
      responseEither.fold((_) => isVerified = false, (response) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;
        final status = data?['status'] as String?;
        if (status == 'matched' || status == 'success') {
          isVerified = true;
        }
      });

      setState(() => _saving = false);
      if (!isVerified) {
        if (mounted) {
          showAppMessage(
            context,
            'Face verification failed for submission.',
            tone: AppDialogTone.error,
          );
        }
      }
      return isVerified;
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        showAppMessage(
          context,
          'Error verifying face: $e',
          tone: AppDialogTone.error,
        );
      }
      return false;
    }
  }

  Future<void> _submit() async {
    final verified = await _verifyFace();
    if (!verified) return;

    setState(() => _saving = true);
    final pos = await _tryGetLocation();
    final record = await ElectricalInspectionDraftService.submit(
      formId: widget.formId,
      answers: _answers,
      startedAt: _startedAt,
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      department: widget.department,
      subDepartment: widget.subDepartment,
      asset: widget.asset,
      assetData: widget.assetData,
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
          'Face Verified ✓\n'
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

    // Build extra details for the asset accordion
    final extraDetails = <String, String>{
      'Inspection started': _formatTime(_startedAt),
    };

    // Add asset-specific details for RTL inspections
    if (widget.assetData.isNotEmpty) {
      if (widget.assetData['role'] != null) {
        extraDetails['Inspecting Role'] = widget.assetData['role'].toString();
      }
      if (widget.assetData['coach_type'] != null) {
        extraDetails['Coach Type'] = widget.assetData['coach_type'].toString();
      }
      if (widget.assetData['category'] != null) {
        extraDetails['Category'] = widget.assetData['category'].toString();
      }
      if (widget.assetData['ac_quantity'] != null) {
        extraDetails['AC Units'] = widget.assetData['ac_quantity'].toString();
      }
      if (widget.assetData['dg_quantity'] != null) {
        extraDetails['DG Sets'] = widget.assetData['dg_quantity'].toString();
      }
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
          ElectricalAssetDetailsAccordion(
            department: widget.department,
            subDepartment: widget.subDepartment,
            asset: widget.asset,
            extraDetails: extraDetails,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: DynamicElectricalForm(
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
