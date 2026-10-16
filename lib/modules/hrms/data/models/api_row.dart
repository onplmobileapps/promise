import 'package:flutter/foundation.dart';

/// One row of an API's JSON, read by field name however the server spells
/// it: "Emp_ID", "empId" and "emp_id" are the same field here.
@immutable
class ApiRow {
  ApiRow(Map<String, dynamic> json)
    : _values = {
        for (final entry in json.entries) normalize(entry.key): entry.value,
      },
      names = [for (final key in json.keys) key];

  final Map<String, Object?> _values;

  /// The field names as the server sent them, in order.
  final List<String> names;

  /// [name] in lower case without spaces, underscores or other marks.
  static String normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// The value under the first of [names] that has one; empty text and
  /// "null" count as none.
  Object? value(List<String> names) {
    for (final name in names) {
      final value = _values[normalize(name)];
      if (value == null) continue;
      if (value is String) {
        final text = value.trim();
        if (text.isEmpty || text.toLowerCase() == 'null') continue;
      }
      return value;
    }
    return null;
  }

  /// The value as trimmed text, or empty.
  String text(List<String> names) => value(names)?.toString().trim() ?? '';

  /// The value as a whole number, from a number or numeric text.
  int? number(List<String> names) => asCount(value(names));

  /// [value] as a whole number, from a number or numeric text.
  static int? asCount(Object? value) => switch (value) {
    final num number => number.toInt(),
    final String text => num.tryParse(text.trim())?.toInt(),
    _ => null,
  };
}

/// [body]'s rows: the body itself when it is a list, or the list it wraps,
/// under `data`, `results` or `Employees`, or as its only list. Entries
/// that aren't objects are skipped.
List<Map<String, dynamic>> apiRows(Object? body) {
  var list = body;
  for (var depth = 0; depth < 2 && list is Map; depth++) {
    final map = list;
    list =
        map['data'] ??
        map['results'] ??
        map['Data'] ??
        map['Employees'] ??
        map['employees'] ??
        map.values.whereType<List<dynamic>>().firstOrNull;
  }
  if (list is! List) return const [];
  return [
    for (final item in list)
      if (item is Map) item.cast<String, dynamic>(),
  ];
}

/// The key a row of [requestRows] came under, such as `leaves` or
/// `change_requests`; empty for a plain list.
const requestSourceKey = '__source';

/// Every row of every list in [body], as the team's requests come: leave
/// and attendance change requests in lists of their own. Each row carries
/// the key it came under as [requestSourceKey]; a lone request object
/// counts as a row too.
List<Map<String, dynamic>> requestRows(Object? body) {
  Map<String, dynamic> tagged(Map<dynamic, dynamic> row, String source) => {
    ...row.cast<String, dynamic>(),
    requestSourceKey: source,
  };
  if (body is List) {
    return [
      for (final item in body)
        if (item is Map) tagged(item, ''),
    ];
  }
  if (body is! Map) return const [];
  final rows = <Map<String, dynamic>>[];
  for (final MapEntry(:key, :value) in body.entries) {
    final source = key.toString();
    if (value is List) {
      for (final item in value) {
        if (item is Map) rows.add(tagged(item, source));
      }
    } else if (value is Map) {
      // A wrapper such as `data`, or a lone request.
      final inner = requestRows(value);
      if (inner.isNotEmpty) {
        rows.addAll(inner);
      } else if (const [
        'request',
        'change_request',
        'leave',
      ].any(source.toLowerCase().contains)) {
        rows.add(tagged(value, source));
      }
    }
  }
  return rows;
}
