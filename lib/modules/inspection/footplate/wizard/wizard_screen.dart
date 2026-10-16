import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/station_asset_model.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/start_selfie_gate.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/step_sidebar.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/asset_checks_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/locomotive_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/punctuality_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/review_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/station_asset_inspection_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/train_schedule_step.dart';

class FootplateWizardScreen extends StatefulWidget {
  final String? resumeId;
  final String? initialTrain;
  final String? initialStation;
  final TimeOfDay? initialDeparture;
  final TimeOfDay? initialArrival;
  final Person? initialDriver;
  final Person? initialAssistantDriver;
  final Person? initialGuardIncharge;

  const FootplateWizardScreen({
    super.key,
    this.resumeId,
    this.initialTrain,
    this.initialStation,
    this.initialDeparture,
    this.initialArrival,
    this.initialDriver,
    this.initialAssistantDriver,
    this.initialGuardIncharge,
  });
  @override
  State<FootplateWizardScreen> createState() => _FootplateWizardScreenState();
}

class _FootplateWizardScreenState extends State<FootplateWizardScreen> {
  final FootplateInspectionData data = FootplateInspectionData();
  int currentStep = 0;
  int maxReachedStep = 0;
  bool _isRestoringDraft = true;

  static const double _wideBreakpoint = 900;

  @override
  void initState() {
    super.initState();
    if (widget.resumeId != null) {
      data.id = widget.resumeId!;
      _restoreDraft();
    } else {
      data.trainSchedule
        ..trainNo = widget.initialTrain
        ..station = widget.initialStation
        ..departure = widget.initialDeparture
        ..arrival = widget.initialArrival
        ..driver = widget.initialDriver ?? kStaffDirectory[5]
        ..assistantDriver = widget.initialAssistantDriver ?? kStaffDirectory[4]
        ..guardIncharge = widget.initialGuardIncharge ?? kStaffDirectory[6];
      data.ops.addAll([
        OPEntry(opCode: 'OP-354', decimal: '425/0.987'),
        OPEntry(opCode: 'OP-373', decimal: '430/1.204'),
      ]);
      // Initialize station assets if empty
      if (data.stationAssets.isEmpty) {
        data.stationAssets.addAll(StationAssetData.getMockStations());
      }
      _isRestoringDraft = false;
    }
  }

  Future<void> _restoreDraft() async {
    final raw = await StorageService.getInspectionDraft(data.id);
    if (raw != null && raw.isNotEmpty) {
      try {
        _restorePayload(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Keep defaults when an older draft cannot be decoded.
      }
    }
    if (mounted) setState(() => _isRestoringDraft = false);
  }

  void _goTo(int step) {
    if (step > maxReachedStep) return;
    setState(() => currentStep = step);
  }

  void _next() {
    setState(() {
      if (currentStep < kSteps.length - 1) {
        currentStep++;
        if (currentStep > maxReachedStep) maxReachedStep = currentStep;
      }
    });
  }

  void _onDataChanged() {
    if (!mounted) return;
    setState(() {});
    _persistDraft();
  }

  void _back() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _saveInspectionRecord('pending');
    StorageService.clearInspectionDraft(data.id);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Inspection Submitted'),
        content: const Text(
          'The Footplate Inspection has been submitted for review by your supervisor.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              FocusScope.of(context).unfocus();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    await _persistDraft();
    if (mounted) {
      showAppMessage(
        context,
        'Inspection draft saved',
        tone: AppDialogTone.success,
      );
    }
  }

  Future<void> _persistDraft() async {
    await StorageService.saveInspectionDraft(
      data.id,
      jsonEncode(_buildPayload('in_progress')),
    );
    await _saveInspectionRecord('in_progress');
  }

  Future<void> _saveInspectionRecord(String status) async {
    final payload = _buildPayload(status);
    await StorageService.saveInspectionRecord({
      'id': data.id,
      'status': status,
      'train': data.trainSchedule.trainNo ?? 'Inspection',
      'date': DateTime.now().toIso8601String(),
      'payload': payload,
    });
  }

  Map<String, dynamic> _buildPayload(String status) {
    return {
      'id': data.id,
      'status': status,
      'step': currentStep,
      'trainSchedule': {
        'trainNo': data.trainSchedule.trainNo,
        'load': data.trainSchedule.load,
        'engineNo': data.trainSchedule.engineNo,
        'direction': data.trainSchedule.direction,
        'station': data.trainSchedule.station,
        'arrival': _timeToJson(data.trainSchedule.arrival),
        'departure': _timeToJson(data.trainSchedule.departure),
        'driver': data.trainSchedule.driver?.display,
        'assistantDriver': data.trainSchedule.assistantDriver?.display,
        'guardIncharge': data.trainSchedule.guardIncharge?.display,
      },
      'locomotive': data.locomotive.equipmentStatus.map(
        (key, value) => MapEntry(key, {
          'isFunctional': value.isFunctional,
          'selectedIssues': value.selectedIssues,
          'integerValue': value.integerValue,
          'dateValue': value.dateValue?.toIso8601String(),
        }),
      ),
      'stationAssets': data.stationAssets.map((s) => s.toJson()).toList(),
      'assets': data.assetChecks
          .map(
            (entry) => {
              'type': entry.assetType,
              'civilDept': entry.civilDept,
              'answers': entry.answers.map(
                (key, value) => MapEntry(key, _encodeValue(value)),
              ),
            },
          )
          .toList(),
      'ops': data.ops
          .map((op) => {'code': op.opCode, 'decimal': op.decimal})
          .toList(),
      'remarks': data.finalRemarks,
      'startSelfiePath': data.startSelfiePath,
      'startSelfieTime': data.startSelfieTime?.toIso8601String(),
      'endSelfiePath': data.endSelfiePath,
      'endSelfieTime': data.endSelfieTime?.toIso8601String(),
      'savedAt': DateTime.now().toIso8601String(),
    };
  }

  dynamic _encodeValue(dynamic value) {
    if (value is Uint8List) {
      return {'type': 'bytes', 'value': base64Encode(value)};
    }
    if (value is List) return value.map(_encodeValue).toList();
    return value;
  }

  dynamic _decodeValue(dynamic value) {
    if (value is Map && value['type'] == 'bytes') {
      return Uint8List.fromList(base64Decode(value['value'] as String));
    }
    if (value is List) return value.map(_decodeValue).toList();
    return value;
  }

  Map<String, dynamic>? _timeToJson(TimeOfDay? time) =>
      time == null ? null : {'hour': time.hour, 'minute': time.minute};

  TimeOfDay? _timeFromJson(dynamic value) {
    if (value is! Map) return null;
    return TimeOfDay(
      hour: (value['hour'] as num?)?.toInt() ?? 0,
      minute: (value['minute'] as num?)?.toInt() ?? 0,
    );
  }

  Person? _personFromDisplay(dynamic value) {
    if (value is! String) return null;
    for (final person in kStaffDirectory) {
      if (person.display == value) return person;
    }
    return null;
  }

  void _restorePayload(Map<String, dynamic> payload) {
    data.id = payload['id'] as String? ?? data.id;
    final schedule = Map<String, dynamic>.from(
      payload['trainSchedule'] as Map? ?? {},
    );
    data.trainSchedule
      ..trainNo = schedule['trainNo'] as String?
      ..load = schedule['load'] as String? ?? ''
      ..engineNo = schedule['engineNo'] as String?
      ..direction = schedule['direction'] as String? ?? 'Up'
      ..station = schedule['station'] as String?
      ..arrival = _timeFromJson(schedule['arrival'])
      ..departure = _timeFromJson(schedule['departure'])
      ..driver = _personFromDisplay(schedule['driver']) ?? kStaffDirectory[5]
      ..assistantDriver =
          _personFromDisplay(schedule['assistantDriver']) ?? kStaffDirectory[4]
      ..guardIncharge =
          _personFromDisplay(schedule['guardIncharge']) ?? kStaffDirectory[6];

    final locomotive = payload['locomotive'];
    if (locomotive is Map) {
      // Restore locomotive equipment status
      for (final entry in locomotive.entries) {
        final item = entry.key.toString();
        final statusData = entry.value;
        if (statusData is Map) {
          data.locomotive.setStatus(
            item,
            LocomotiveEquipmentStatus(
              isFunctional: statusData['isFunctional'] as bool? ?? true,
              selectedIssues:
                  (statusData['selectedIssues'] as List?)?.cast<String>() ?? [],
              integerValue: statusData['integerValue'] as int?,
              dateValue: statusData['dateValue'] != null
                  ? DateTime.tryParse(statusData['dateValue'] as String)
                  : null,
            ),
          );
        }
      }
    }

    if (payload['stationAssets'] != null) {
      data.stationAssets
        ..clear()
        ..addAll(
          (payload['stationAssets'] as List).map(
            (s) => StationAsset.fromJson(s as Map<String, dynamic>),
          ),
        );
    }

    data.assetChecks
      ..clear()
      ..addAll(
        (payload['assets'] as List? ?? []).whereType<Map>().map((item) {
          final entry = AssetCheckEntry(
            assetType: item['type'] as String? ?? kAssetTypes.first,
            civilDept: item['civilDept'] == true,
          );
          final answers = item['answers'];
          if (answers is Map) {
            entry.answers.addAll(
              answers.map(
                (key, value) => MapEntry(key.toString(), _decodeValue(value)),
              ),
            );
          }
          return entry;
        }),
      );
    data.ops
      ..clear()
      ..addAll(
        (payload['ops'] as List? ?? []).whereType<Map>().map(
          (item) => OPEntry(
            opCode: item['code'] as String? ?? '',
            decimal: item['decimal'] as String? ?? '',
          ),
        ),
      );
    data.finalRemarks = payload['remarks'] as String? ?? '';
    data.startSelfiePath = payload['startSelfiePath'] as String?;
    data.startSelfieTime = payload['startSelfieTime'] != null
        ? DateTime.tryParse(payload['startSelfieTime'] as String)
        : null;
    data.endSelfiePath = payload['endSelfiePath'] as String?;
    data.endSelfieTime = payload['endSelfieTime'] != null
        ? DateTime.tryParse(payload['endSelfieTime'] as String)
        : null;
    currentStep = (payload['step'] as num?)?.toInt() ?? 0;
    maxReachedStep = currentStep;
  }

  void _onStartSelfieCaptured(String path) {
    setState(() {
      data.startSelfiePath = path;
      data.startSelfieTime = DateTime.now();
    });
    _persistDraft();
  }

  Widget _buildStepContent() {
    if (_isRestoringDraft) {
      return Center(child: AppLoader());
    }

    switch (currentStep) {
      case 0:
        return TrainScheduleStep(
          data: data.trainSchedule,
          onChanged: _onDataChanged,
        );
      case 1:
        return LocomotiveStep(data: data.locomotive, onChanged: _onDataChanged);
      case 2:
        return StationAssetInspectionStep(
          stationAssets: data.stationAssets,
          onChanged: _onDataChanged,
        );
      case 3:
        return AssetChecksStep(
          entries: data.assetChecks,
          onChanged: _onDataChanged,
        );
      case 4:
        return PunctualityStep(
          punctuality: data.punctuality,
          ops: data.ops,
          onChanged: _onDataChanged,
        );
      case 5:
        return ReviewStep(
          data: data,
          onChanged: _onDataChanged,
          onSubmit: _submit,
          onSaveDraft: _saveDraft,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The inspection envelope must be bounded by a start selfie before any
    // wizard step is reachable — the matching end selfie is captured on the
    // Review & Submit step.
    if (!_isRestoringDraft && data.startSelfiePath == null) {
      return StartSelfieGate(
        trainLabel: data.trainSchedule.trainNo ?? '',
        onCaptured: _onStartSelfieCaptured,
      );
    }

    final isWide = MediaQuery.of(context).size.width >= _wideBreakpoint;
    final isLastStep = currentStep == kSteps.length - 1;

    final content = Column(
      children: [
        Expanded(child: _buildStepContent()),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                if (currentStep > 0)
                  OutlinedButton.icon(
                    onPressed: _back,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox(width: 96),
                const Spacer(),
                Text(
                  'Step ${currentStep + 1} of ${kSteps.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (!isLastStep)
                  FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  )
                else
                  const SizedBox(width: 96),
              ],
            ),
          ),
        ),
      ],
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            StepSidebar(
              currentStep: currentStep,
              maxReachedStep: maxReachedStep,
              onStepTapped: _goTo,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(kSteps[currentStep].title),
        centerTitle: false,
        bottom: StepTopBar(
          currentStep: currentStep,
          maxReachedStep: maxReachedStep,
          onStepTapped: _goTo,
        ),
      ),
      body: content,
    );
  }
}
