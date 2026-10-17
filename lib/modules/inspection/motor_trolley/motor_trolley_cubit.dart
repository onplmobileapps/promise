import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';

/// Keeps a motor trolley inspection's answers, and its draft on the phone.
class MotorTrolleyInspectionCubit
    extends SafeCubit<MotorTrolleyInspectionState> {
  MotorTrolleyInspectionCubit()
    : super(MotorTrolleyInspectionState(inspectionDate: DateTime.now()));

  /// Where the draft is kept; also its entry among the dashboard's drafts.
  static const draftId = 'motor_trolley_draft_v1';

  void set(String key, String value) =>
      emit(state.copyWith(values: {...state.values, key: value}));

  void setDate(DateTime day) => emit(state.copyWith(inspectionDate: day));

  void setStep(int step) => emit(state.copyWith(step: step));

  Future<void> loadDraft() async {
    final raw = await StorageService.getInspectionDraft(draftId);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      emit(
        MotorTrolleyInspectionState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        ),
      );
    } on Object catch (e) {
      debugPrint('Motor trolley draft could not be read: $e');
    }
  }

  Future<void> saveDraft() async {
    if (!state.hasAnswers) return;
    await StorageService.saveInspectionDraft(
      draftId,
      jsonEncode(state.toJson()),
    );
    var answered = 0;
    var total = 0;
    for (final step in kTrolleySteps) {
      final (a, t) = state.progressOf(step);
      answered += a;
      total += t;
    }
    final from = state.value('sectionFrom')?.trim() ?? '';
    final to = state.value('sectionTo')?.trim() ?? '';
    await StorageService.saveInspectionRecord({
      'id': draftId,
      'train': from.isEmpty && to.isEmpty
          ? 'Motor trolley inspection'
          : 'Motor trolley · $from – $to',
      'date': DateTime.now().toIso8601String(),
      'status': 'in_progress',
      'progress': total == 0 ? 0 : answered / total,
      'payload': {'type': 'motor_trolley'},
    });
  }

  /// Forgets the draft, and its entry among the dashboard's drafts.
  Future<void> clearDraft() => StorageService.deleteInspectionRecord(draftId);
}
