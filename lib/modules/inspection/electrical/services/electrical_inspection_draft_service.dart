import 'dart:convert';

import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implements the generic BRD requirements shared by every Electrical
/// inspection form (page 4):
///  - load in online mode, save in offline mode if there's no internet
///  - user can save as draft and resume later
///  - total time spent on inspection is tracked
///  - GPS coordinates captured on submission (one draft save per location)
///
/// This mirrors the pattern used in CivilInspectionDraftService and
/// FootplateWizardScreen for consistency across the inspection system.
class ElectricalInspectionDraftService {
  static const _draftPrefix = 'electrical_inspection_draft_';
  static const _submittedKey = 'electrical_inspection_submitted';

  /// One draft per (department, subDepartment, asset, assetInstanceId)
  /// combination so multiple in-progress inspections don't clobber
  /// each other.
  static String _draftKey(String formId) => '$_draftPrefix$formId';

  static Future<void> saveDraft({
    required String formId,
    required Map<String, dynamic> answers,
    required DateTime startedAt,
    double? latitude,
    double? longitude,
    String? department,
    String? subDepartment,
    String? asset,
    Map<String, dynamic>? assetData,
    int step = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'step': step,
      'formId': formId,
      'answers': _encodeAnswers(answers),
      'startedAt': startedAt.toIso8601String(),
      'lastSavedAt': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'status': 'draft',
      'department': ?department,
      'subDepartment': ?subDepartment,
      'asset': ?asset,
      'assetData': ?assetData,
    };
    await prefs.setString(_draftKey(formId), jsonEncode(payload));

    // Notify dashboard
    await StorageService.saveInspectionRecord({
      'id': formId,
      'status': 'in_progress',
      'train': asset != null
          ? '$asset (Electrical)'
          : '${formId.replaceAll('electrical_', '').replaceAll('_', ' ').toUpperCase()} (Electrical)',
      'date': DateTime.now().toIso8601String(),
      'payload': {
        'type': 'electrical',
        'formId': formId,
        'department': department,
        'subDepartment': subDepartment,
        'asset': asset,
      },
    });
  }

  static Future<Map<String, dynamic>?> loadDraft(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(formId));
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    decoded['answers'] = _decodeAnswers(
      Map<String, dynamic>.from(decoded['answers'] as Map),
    );
    return decoded;
  }

  static Future<void> clearDraft(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(formId));
  }

  /// Finalizes the inspection: records total time spent, captures
  /// coordinates, marks it submitted, and clears the draft. In a real
  /// deployment this is also where you'd attempt an online upload and
  /// fall back to an offline outbox on failure.
  static Future<Map<String, dynamic>> submit({
    required String formId,
    required Map<String, dynamic> answers,
    required DateTime startedAt,
    double? latitude,
    double? longitude,
    String? department,
    String? subDepartment,
    String? asset,
    Map<String, dynamic>? assetData,

    /// The face checks the inspection was started and signed with.
    Map<String, dynamic>? verification,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final finishedAt = DateTime.now();
    final record = {
      'formId': formId,
      'answers': _encodeAnswers(answers),
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt.toIso8601String(),
      'timeSpentSeconds': finishedAt.difference(startedAt).inSeconds,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'submitted',
      'verification': ?verification,
      'department': ?department,
      'subDepartment': ?subDepartment,
      'asset': ?asset,
      'assetData': ?assetData,
    };

    final existingRaw = prefs.getStringList(_submittedKey) ?? [];
    existingRaw.add(jsonEncode(record));
    await prefs.setStringList(_submittedKey, existingRaw);
    await clearDraft(formId);

    // Notify dashboard
    await StorageService.saveInspectionRecord({
      'id': formId,
      'status': 'pending',
      'train': asset != null
          ? '$asset (Electrical)'
          : '${formId.replaceAll('electrical_', '').replaceAll('_', ' ').toUpperCase()} (Electrical)',
      'date': DateTime.now().toIso8601String(),
      'payload': {
        'type': 'electrical',
        'formId': formId,
        'department': department,
        'subDepartment': subDepartment,
        'asset': asset,
      },
    });

    return record;
  }

  static Future<List<Map<String, dynamic>>> getSubmittedRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_submittedKey) ?? [];
    return raw.map((r) => jsonDecode(r) as Map<String, dynamic>).toList();
  }

  /// DateTime values in the answers map need string encoding for JSON.
  static Map<String, dynamic> _encodeAnswers(Map<String, dynamic> answers) {
    return answers.map((k, v) {
      if (v is DateTime) {
        return MapEntry(k, {
          '__type': 'datetime',
          'value': v.toIso8601String(),
        });
      }
      return MapEntry(k, v);
    });
  }

  static Map<String, dynamic> _decodeAnswers(Map<String, dynamic> answers) {
    return answers.map((k, v) {
      if (v is Map && v['__type'] == 'datetime') {
        return MapEntry(k, DateTime.parse(v['value'] as String));
      }
      return MapEntry(k, v);
    });
  }
}
