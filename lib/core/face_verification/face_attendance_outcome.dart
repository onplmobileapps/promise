/// What the face verification API said about an attendance attempt, for
/// one's own check-in and for marking someone else's.
class FaceAttendanceOutcome {
  final bool success;
  final String message;

  /// The employee has no face on record to check against.
  final bool notRegistered;

  const FaceAttendanceOutcome._(
    this.success,
    this.message, {
    this.notRegistered = false,
  });

  /// A check the server refused, saying [message].
  const FaceAttendanceOutcome.failed(this.message, {this.notRegistered = false})
    : success = false;

  /// Whether the server's [status] or [message] says there is no face on
  /// record, as "not_registered" or "Face not registered for this
  /// employee" or "No face embeddings found".
  static bool saysNotRegistered(String? status, String? message) {
    final words = '${status ?? ''} ${message ?? ''}'.toLowerCase();
    return words.contains('regist') ||
        RegExp(r'\bno (registered )?(face|embedding)').hasMatch(words) ||
        RegExp(r'(face|embedding)s? (data )?not found').hasMatch(words);
  }

  factory FaceAttendanceOutcome.fromResponse(Object? body) {
    if (body is! Map) {
      return const FaceAttendanceOutcome._(
        false,
        'Could not confirm the attendance. Please try again.',
      );
    }
    String? text(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty || s == 'null' ? null : s;
    }

    final detail = text(body['detail']);
    final message = text(body['message']);
    switch (text(body['status'])?.toLowerCase()) {
      case 'success':
      case 'matched':
        return FaceAttendanceOutcome._(
          true,
          message ?? 'Attendance marked successfully.',
        );
      case 'not_matched':
        return const FaceAttendanceOutcome._(
          false,
          'Face verification failed. Profile does not match.',
        );
      case final status:
        final said = detail ?? message;
        return FaceAttendanceOutcome._(
          false,
          said ?? 'Verification failed. Please try again.',
          notRegistered: saysNotRegistered(status, said),
        );
    }
  }
}
