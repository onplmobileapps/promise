import 'dart:convert';

import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_inspection_screen.dart';

/// Keeps an inspection that has no server yet on the phone: its draft, an
/// entry among the dashboard's drafts while it is under way, and the
/// signed inspection once it is finished.
class LocalSpecStore implements SpecFormStore {
  const LocalSpecStore({
    required this.id,
    required this.type,
    required this.title,
  });

  /// Where its draft is kept, and its entry on the dashboard.
  final String id;

  /// The kind the dashboard opens it as, as "locomotive".
  final String type;

  /// What the dashboard calls it.
  final String title;

  @override
  Future<SpecDraft?> load() async {
    final raw = await StorageService.getInspectionDraft(id);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      return (
        answers: _decode(Map<String, dynamic>.from(saved['answers'] as Map)),
        startedAt:
            DateTime.tryParse('${saved['startedAt'] ?? ''}') ?? DateTime.now(),
        step: (saved['step'] as num?)?.toInt() ?? 0,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> saveDraft(
    Map<String, dynamic> answers,
    DateTime startedAt, {
    int step = 0,
  }) async {
    await StorageService.saveInspectionDraft(
      id,
      jsonEncode({
        'answers': _encode(answers),
        'startedAt': startedAt.toIso8601String(),
        'step': step,
      }),
    );
    await StorageService.saveInspectionRecord({
      'id': id,
      'status': 'in_progress',
      'train': title,
      'date': DateTime.now().toIso8601String(),
      'payload': {'type': type},
    });
  }

  @override
  Future<void> complete(
    Map<String, dynamic> answers,
    DateTime startedAt,
    InspectionSignatures signatures,
  ) async {
    final finishedAt = DateTime.now();
    await StorageService.clearInspectionDraft(id);
    await StorageService.saveInspectionRecord({
      // A record of its own, so the next inspection starts afresh.
      'id': '${id}_${finishedAt.millisecondsSinceEpoch}',
      'status': 'completed',
      'train': title,
      'date': finishedAt.toIso8601String(),
      'payload': {
        'type': type,
        'answers': _encode(answers),
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        ...signatures.toJson(),
      },
    });
    await StorageService.deleteInspectionRecord(id);
  }

  static Map<String, dynamic> _encode(Map<String, dynamic> answers) => {
    for (final MapEntry(:key, :value) in answers.entries)
      key: value is DateTime ? {'__date': value.toIso8601String()} : value,
  };

  static Map<String, dynamic> _decode(Map<String, dynamic> answers) => {
    for (final MapEntry(:key, :value) in answers.entries)
      key: value is Map && value['__date'] is String
          ? DateTime.tryParse(value['__date'] as String)
          : value,
  };
}
