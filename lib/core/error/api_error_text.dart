/// What a server that refused a request said, for a person to read: its
/// message, or, when it refused field by field (as Django REST does), each
/// field and what was wrong with it.
abstract final class ApiErrorText {
  /// Keys a message is kept under, in the order they are trusted.
  static const _messageKeys = [
    'Error',
    'error',
    'message',
    'msg',
    'detail',
    'details',
    'errors',
    'non_field_errors',
  ];

  /// Keys that describe the answer rather than what went wrong.
  static const _ignored = {'status', 'success', 'code', 'status_code'};

  static String? of(Object? data) {
    switch (data) {
      case null:
        return null;
      case final String text:
        final trimmed = text.trim();
        // A web server's error page says nothing a person can act on.
        if (trimmed.isEmpty || trimmed.startsWith('<')) return null;
        return trimmed.length > 300 ? '${trimmed.substring(0, 300)}…' : trimmed;
      case final List<Object?> list:
        final lines = [for (final item in list) ?of(item)];
        return lines.isEmpty ? null : lines.join('\n');
      case final Map<Object?, Object?> map:
        for (final key in _messageKeys) {
          if (of(map[key]) case final message?) return message;
        }
        final lines = <String>[];
        for (final MapEntry(:key, :value) in map.entries) {
          if (_ignored.contains(key)) continue;
          final problem = of(value);
          if (problem != null) {
            lines.add('${label('$key')}: ${problem.split('\n').first}');
          }
        }
        return lines.isEmpty ? null : lines.join('\n');
      default:
        return null;
    }
  }

  /// A field's key as words: "old_password" as "Old password".
  static String label(String key) {
    final words = key.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (words.isEmpty) return key;
    return words[0].toUpperCase() + words.substring(1);
  }
}
