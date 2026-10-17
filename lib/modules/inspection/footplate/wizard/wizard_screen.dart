import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/station_asset_model.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/footplate_report.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/asset_checks_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/locomotive_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/punctuality_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/station_asset_inspection_step.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/steps/train_schedule_step.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';

/// A footplate inspection, ridden on the train: the inspector's face
/// first, then the train and crew, the locomotive, each station's assets,
/// the assets passed, punctuality and caution orders, and the signed
/// report kept on the phone for the supervisor.
class FootplateWizardScreen extends StatelessWidget {
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
    this.verifier,
  });

  final String? resumeId;
  final String? initialTrain;
  final String? initialStation;
  final TimeOfDay? initialDeparture;
  final TimeOfDay? initialArrival;
  final Person? initialDriver;
  final Person? initialAssistantDriver;
  final Person? initialGuardIncharge;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: context.l10n.inspFootplateTitle,
    verifier: verifier,
    child: _FootplateForm(screen: this),
  );
}

class _FootplateForm extends StatefulWidget {
  const _FootplateForm({required this.screen});

  final FootplateWizardScreen screen;

  @override
  State<_FootplateForm> createState() => _FootplateFormState();
}

class _FootplateFormState extends State<_FootplateForm> {
  final FootplateInspectionData data = FootplateInspectionData();
  bool _ready = false;
  bool _dirty = false;
  int _step = 0;
  Timer? _autosave;

  @override
  void initState() {
    super.initState();
    final screen = widget.screen;
    final resume = screen.resumeId;
    if (resume != null) {
      data.id = resume;
      unawaited(_restoreDraft());
      return;
    }
    data.trainSchedule
      ..trainNo = screen.initialTrain
      ..station = screen.initialStation
      ..departure = screen.initialDeparture
      ..arrival = screen.initialArrival
      ..driver = screen.initialDriver
      ..assistantDriver = screen.initialAssistantDriver
      ..guardIncharge = screen.initialGuardIncharge;
    // The stations on the run and their assets. There is no register to
    // load them from yet, so these stand in.
    data.stationAssets.addAll(StationAssetData.getMockStations());
    _ready = true;
  }

  @override
  void dispose() {
    _autosave?.cancel();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final raw = await StorageService.getInspectionDraft(data.id);
    if (raw != null && raw.isNotEmpty) {
      try {
        _restorePayload(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // An older draft that can't be read starts afresh.
      }
    }
    if (data.stationAssets.isEmpty) {
      data.stationAssets.addAll(StationAssetData.getMockStations());
    }
    if (mounted) setState(() => _ready = true);
  }

  void _changed() {
    setState(() => _dirty = true);
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _persistDraft);
  }

  Future<void> _persistDraft() async {
    _autosave?.cancel();
    await StorageService.saveInspectionDraft(
      data.id,
      jsonEncode(_buildPayload('in_progress')),
    );
    await _saveInspectionRecord('in_progress');
  }

  Future<void> _saveInspectionRecord(
    String status, {
    Map<String, dynamic> extra = const {},
  }) => StorageService.saveInspectionRecord({
    'id': data.id,
    'status': status,
    'train': data.trainSchedule.trainNo ?? 'Inspection',
    'date': DateTime.now().toIso8601String(),
    'payload': {..._buildPayload(status), ...extra},
  });

  Future<void> _review() async {
    final l10n = context.l10n;
    await _persistDraft();
    if (!mounted) return;
    final kept = await reviewAndSubmit(
      context,
      verifier: widget.screen.verifier,
      report: footplateReport(data, title: l10n.inspFootplateTitle),
      submit: (signatures) async {
        // Kept for the supervisor's approval, signed.
        await _saveInspectionRecord('pending', extra: signatures.toJson());
        await StorageService.clearInspectionDraft(data.id);
        return Right(l10n.inspFormSavedLocally);
      },
    );
    if (kept && mounted) Navigator.of(context).pop();
  }

  Map<String, dynamic> _buildPayload(String status) {
    return {
      'id': data.id,
      'status': status,
      'step': _step,
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
      'punctuality': [
        for (final stop in data.punctuality)
          {
            'station': stop.station,
            'scheduleArrival': stop.scheduleArrival?.toIso8601String(),
            'actualArrival': stop.actualArrival?.toIso8601String(),
            'scheduleDeparture': stop.scheduleDeparture?.toIso8601String(),
            'actualDeparture': stop.actualDeparture?.toIso8601String(),
            'remarks': stop.remarks,
          },
      ],
      'remarks': data.finalRemarks,
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
      ..driver = _personFromDisplay(schedule['driver'])
      ..assistantDriver = _personFromDisplay(schedule['assistantDriver'])
      ..guardIncharge = _personFromDisplay(schedule['guardIncharge']);

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
    data.punctuality
      ..clear()
      ..addAll(
        (payload['punctuality'] as List? ?? []).whereType<Map>().map(
          (item) => PunctualityEntry(station: '${item['station'] ?? ''}')
            ..scheduleArrival = DateTime.tryParse('${item['scheduleArrival']}')
            ..actualArrival = DateTime.tryParse('${item['actualArrival']}')
            ..scheduleDeparture = DateTime.tryParse(
              '${item['scheduleDeparture']}',
            )
            ..actualDeparture = DateTime.tryParse('${item['actualDeparture']}')
            ..remarks = '${item['remarks'] ?? ''}',
        ),
      );
    data.finalRemarks = payload['remarks'] as String? ?? '';
    _step = (payload['step'] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_ready) return const Scaffold(body: Center(child: AppLoader()));
    final schedule = data.trainSchedule;
    return InspectionFormScaffold(
      title: l10n.inspFootplateTitle,
      subtitle: schedule.trainNo ?? l10n.inspFootplateAbout,
      initialStep: _step,
      dirty: _dirty,
      onLeave: _persistDraft,
      onStepChanged: (step) {
        _step = step;
        unawaited(_persistDraft());
      },
      missing: () => [
        if (schedule.trainNo == null) 'Train No',
        if (schedule.engineNo == null) 'Engine No',
      ],
      onReview: _review,
      steps: [
        InspectionStep(
          title: 'Train Schedule',
          total: 6,
          answered: [
            schedule.trainNo,
            schedule.engineNo,
            schedule.station,
            schedule.driver,
            schedule.assistantDriver,
            schedule.guardIncharge,
          ].nonNulls.length,
          builder: (_) =>
              TrainScheduleStep(data: schedule, onChanged: _changed),
        ),
        InspectionStep(
          title: 'Locomotive',
          builder: (_) =>
              LocomotiveStep(data: data.locomotive, onChanged: _changed),
        ),
        InspectionStep(
          title: 'Station Assets',
          total: data.stationAssets.fold(0, (n, s) => n + s.totalAssets),
          answered: data.stationAssets.fold(0, (n, s) => n + s.completedAssets),
          builder: (_) => StationAssetInspectionStep(
            stationAssets: data.stationAssets,
            onChanged: _changed,
          ),
        ),
        InspectionStep(
          title: 'Asset Checks',
          total: kAssetTypes.length,
          answered: data.assetChecks.where((e) => e.answers.isNotEmpty).length,
          builder: (_) =>
              AssetChecksStep(entries: data.assetChecks, onChanged: _changed),
        ),
        InspectionStep(
          title: 'Punctuality & OPs',
          builder: (_) => PunctualityStep(
            punctuality: data.punctuality,
            ops: data.ops,
            onChanged: _changed,
          ),
        ),
        InspectionStep(
          title: 'Remarks',
          builder: (_) => InspectionCard(
            title: l10n.inspFormNote,
            glyph: AppGlyphs.fileEdit,
            children: [
              InspectionTextInput(
                label: l10n.inspFormRemarkLabel,
                hint: l10n.inspFormNoteHint,
                kind: InspectionTextKind.multiline,
                value: data.finalRemarks,
                onChanged: (typed) {
                  data.finalRemarks = typed;
                  _changed();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
