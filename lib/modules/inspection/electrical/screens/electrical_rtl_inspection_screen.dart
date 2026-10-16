import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/device_utils.dart';
import 'package:railway_hrms/core/widgets/login_background_header.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_asset_form_screen.dart';

class ElectricalRtlInspectionScreen extends StatefulWidget {
  const ElectricalRtlInspectionScreen({super.key});

  @override
  State<ElectricalRtlInspectionScreen> createState() =>
      _ElectricalRtlInspectionScreenState();
}

class _ElectricalRtlInspectionScreenState
    extends State<ElectricalRtlInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _inspectionDate = DateTime.now();
  final Set<String> _selectedAssets = {};
  final List<String> _assets = ['Workshop', 'Washing Line', 'Station'];

  String _selectedRole = 'Officer / Inspector';
  final List<String> _roles = [
    'Officer / Inspector',
    'Supervisor / JE / SSE',
    'Electrical Staff / Technician',
  ];

  bool _isFaceVerified = false;
  bool _isVerifying = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _inspectionDate = picked);
    }
  }

  Future<void> _verifyFace() async {
    setState(() => _isVerifying = true);
    try {
      final result = await DeviceUtils.performFaceVerification(context);
      if (result == null || result.images.isEmpty) {
        setState(() => _isVerifying = false);
        return;
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

      if (mounted) {
        setState(() {
          _isFaceVerified = isVerified;
          _isVerifying = false;
        });

        showAppMessage(
          context,
          isVerified
              ? 'Face verification successful! ✓'
              : 'Face verification failed.',
          tone: isVerified ? AppDialogTone.success : AppDialogTone.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        showAppMessage(
          context,
          'Error verifying face: $e',
          tone: AppDialogTone.error,
        );
      }
    }
  }

  void _startInspection() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssets.isEmpty) {
      showAppMessage(
        context,
        'Please select at least one inspection asset / location first.',
        tone: AppDialogTone.error,
      );
      return;
    }

    if (!_isFaceVerified) {
      await _verifyFace();
      if (!_isFaceVerified) return;
    }

    if (!mounted) return;

    final assetsList = _selectedAssets.toList();
    final assetsTitle = assetsList.join(', ');
    final formId = 'electrical_rtl_${assetsList.join('_')}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');

    final fields = ElectricalInspectionCatalog.resolveFields(
      'Electrical',
      'RTL',
      assetsList,
      {
        'coach_type': 'German',
        'category': 'AC Sleeper',
        'inspection_date': _inspectionDate.toIso8601String(),
        'role': _selectedRole,
      },
      role: _selectedRole,
    );

    if (fields == null || fields.isEmpty) {
      showAppMessage(
        context,
        'Could not resolve inspection form fields.',
        tone: AppDialogTone.error,
      );
      return;
    }

    await StorageService.saveInspectionRecord({
      'id': formId,
      'train': 'Electrical (RTL) Inspection - $assetsTitle ($_selectedRole)',
      'date': _inspectionDate.toIso8601String(),
      'status': 'in_progress',
      'payload': {
        'type': 'electrical',
        'title': 'Electrical (RTL)',
        'formId': formId,
        'department': 'Electrical',
        'subDepartment': 'RTL',
        'asset': assetsTitle,
        'assets': assetsList,
        'assetData': {
          'inspection_date': _inspectionDate.toIso8601String(),
          'role': _selectedRole,
        },
      },
    });

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ElectricalAssetFormScreen(
          department: 'Electrical',
          subDepartment: 'RTL',
          asset: assetsTitle,
          fields: fields,
          formId: formId,
          assetData: {
            'inspection_date': _inspectionDate.toIso8601String(),
            'role': _selectedRole,
            'assets': assetsList,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final double screenHeight = MediaQuery.of(context).size.height;
    const brandGreen = Color(0xFF5CA38E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Header
          LoginBackgroundHeader(
            height: screenHeight * 0.57,
            overlayHeight: screenHeight * 0.30,
            overlayColor: const Color(0xFFF8FAFC),
            overlayAlpha: 0.35,
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(children: [const AppBackButton()]),
              ),
            ),
          ),

          // Bottom Sheet Container Card
          Positioned.fill(
            top: screenHeight * 0.22,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.surface,
                    colorScheme.surface.withValues(alpha: 0.96),
                    Color.lerp(colorScheme.surface, brandGreen, 0.08)!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: brandGreen.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.electrical_services_rounded,
                                color: brandGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Electrical (RTL) Inspection',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Field inspection preparation & verification',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Inspection Date Picker
                        const Text(
                          'Inspection Date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.calendar_today_rounded,
                                color: brandGreen,
                              ),
                              suffixIcon: const Icon(Icons.expand_more_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            child: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_inspectionDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Asset Selection (Checkboxes - Multiple Selection)
                        const Text(
                          'Inspection Assets / Locations (Select multiple)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            children: _assets.map((asset) {
                              final isSelected = _selectedAssets.contains(
                                asset,
                              );
                              return Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  title: Text(
                                    asset,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: brandGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  onChanged: (bool? val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedAssets.add(asset);
                                      } else {
                                        _selectedAssets.remove(asset);
                                      }
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Role Selection
                        const Text(
                          'Inspecting Role / Designation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.badge_rounded,
                              color: brandGreen,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                          items: _roles
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Face Verification Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isFaceVerified
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isFaceVerified
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.4)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isFaceVerified
                                      ? const Color(0xFF10B981)
                                      : brandGreen.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isFaceVerified
                                      ? Icons.check_rounded
                                      : Icons.face_rounded,
                                  color: _isFaceVerified
                                      ? Colors.white
                                      : brandGreen,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isFaceVerified
                                          ? 'Face Verified'
                                          : 'Officer Face Verification',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _isFaceVerified
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isFaceVerified
                                          ? 'Biometric verification completed successfully.'
                                          : 'Verify your identity before starting inspection.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _isFaceVerified
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_isFaceVerified)
                                FilledButton(
                                  onPressed: _isVerifying ? null : _verifyFace,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: brandGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: _isVerifying
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Verify',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Start Inspection Button
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isVerifying ? null : _startInspection,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Inspection'),
                            style: FilledButton.styleFrom(
                              backgroundColor: brandGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
