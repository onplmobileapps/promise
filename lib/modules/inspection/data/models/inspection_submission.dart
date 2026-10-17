/// What the server said of an inspection it took.
class InspectionSubmission {
  const InspectionSubmission({required this.message, this.reference});

  /// Its own words, or a plain "submitted".
  final String message;

  /// The report's number on the server, when it gives one.
  final String? reference;

  static const _submitted = 'Inspection submitted.';

  factory InspectionSubmission.fromResponse(Object? body) {
    if (body is! Map) return const InspectionSubmission(message: _submitted);
    String? text(Object? value) {
      final s = value?.toString().trim();
      return s == null || s.isEmpty || s == 'null' ? null : s;
    }

    final data = body['data'];
    return InspectionSubmission(
      message:
          text(body['message']) ??
          text(body['detail']) ??
          text(body['Success']) ??
          _submitted,
      reference:
          text(body['id']) ??
          text(body['inspection_id']) ??
          (data is Map ? text(data['id']) : null),
    );
  }
}
