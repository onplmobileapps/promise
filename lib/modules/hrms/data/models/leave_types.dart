/// A leave type with the employee's balance in it. Balances can be in half
/// days, so they are [num]s.
class LeaveTypesRecord {
  final int leaveType;
  final String leaveTypeName;
  final String leaveFlag;
  final num allotted;
  final num remaining;
  final num consumed;
  final bool status;
  final int applicationPeriod;
  final String icon;

  LeaveTypesRecord({
    required this.leaveType,
    required this.leaveTypeName,
    required this.leaveFlag,
    required this.allotted,
    required this.remaining,
    required this.consumed,
    required this.status,
    required this.applicationPeriod,
    required this.icon,
  });

  factory LeaveTypesRecord.fromJson(Map<String, dynamic> json) {
    return LeaveTypesRecord(
      leaveType: _num(json['LeaveType']).toInt(),
      leaveTypeName: json['LeaveTypeName']?.toString().trim() ?? '',
      leaveFlag: json['LeaveFlag']?.toString() ?? '',
      allotted: _num(json['Allotted']),
      remaining: _num(json['Remaining']),
      consumed: _num(json['Consumed']),
      status: json['Status'] == true,
      applicationPeriod: _num(json['ApplicationPeriod']).toInt(),
      icon: json['Icon']?.toString() ?? '',
    );
  }

  /// Leave types from a response body: a list, or an object wrapping one in
  /// `data` or `results`. Malformed entries are skipped.
  static List<LeaveTypesRecord> parseLeaveTypesList(Object? body) {
    final list = body is List
        ? body
        : body is Map<String, dynamic>
        ? (body['data'] ?? body['results'])
        : null;
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) LeaveTypesRecord.fromJson(item),
    ];
  }
}

num _num(Object? v) =>
    v is num ? v : (v is String ? num.tryParse(v.trim()) ?? 0 : 0);

/// A day count without a needless ".0": 2, 1.5.
String formatDays(num days) =>
    days % 1 == 0 ? days.toInt().toString() : days.toStringAsFixed(1);
