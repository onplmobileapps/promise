import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/face_verification/face_attendance_outcome.dart';

void main() {
  test('a matched face marks the attendance', () {
    final outcome = FaceAttendanceOutcome.fromResponse({
      'status': 'success',
      'message': 'Checked in',
    });
    expect(outcome.success, isTrue);
    expect(outcome.notRegistered, isFalse);
  });

  test('says when there is no face on record', () {
    for (final body in [
      {'status': 'not_registered'},
      {'status': 'error', 'detail': 'Face not registered for this employee'},
      {'status': 'error', 'message': 'No face embeddings found'},
      {'detail': 'Face data not found'},
    ]) {
      final outcome = FaceAttendanceOutcome.fromResponse(body);
      expect(outcome.success, isFalse, reason: '$body');
      expect(outcome.notRegistered, isTrue, reason: '$body');
    }
  });

  test('a face that does not match is not taken for a missing one', () {
    for (final body in [
      {'status': 'not_matched'},
      {'status': 'error', 'detail': 'Outside the work area'},
    ]) {
      expect(FaceAttendanceOutcome.fromResponse(body).notRegistered, isFalse);
    }
  });
}
