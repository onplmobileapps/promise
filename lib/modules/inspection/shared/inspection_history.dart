import 'package:railway_hrms/core/storage/storage_service.dart';

/// Keeps a finished inspection of [type] among those done, as the
/// dashboard's monthly plan counts them.
Future<void> keepFinishedInspection({
  required String type,
  required String title,
  DateTime? at,
}) {
  final finished = at ?? DateTime.now();
  return StorageService.saveInspectionRecord({
    'id': '${type}_${finished.millisecondsSinceEpoch}',
    'status': 'completed',
    'train': title,
    'date': finished.toIso8601String(),
    'payload': {'type': type},
  });
}
