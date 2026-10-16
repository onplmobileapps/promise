class AttendanceRecord {
  final int? attId;
  final String? dayType;
  final int? leaveId;
  final int? empId;
  final String? firstName;
  final String? lastName;
  final String? designation;
  final String? division;
  final String? department;
  final String? location;
  final String? date;
  final String? status;
  final String? checkin;
  final String? checkout;
  final String? shift;
  final String? shiftStart;
  final String? shiftEnd;
  final String? requiredHours;
  final String? workedHours;

  /// Minutes after the shift starts that a check-in still counts as on
  /// time, as the server allows.
  final int? lateCushion;
  final AttDetail? attDetail;

  AttendanceRecord({
    this.attId,
    this.dayType,
    this.leaveId,
    this.empId,
    this.firstName,
    this.lastName,
    this.designation,
    this.division,
    this.department,
    this.location,
    this.date,
    this.status,
    this.checkin,
    this.checkout,
    this.shift,
    this.shiftStart,
    this.shiftEnd,
    this.requiredHours,
    this.workedHours,
    this.lateCushion,
    this.attDetail,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final detail = json['att_detail'];
    return AttendanceRecord(
      attId: _int(json['AttID']),
      dayType: _text(json['Daytype']),
      leaveId: _int(json['LeaveID']),
      empId: _int(json['Emp_ID']),
      firstName: _text(json['FirstName']),
      lastName: _text(json['LastName']),
      designation: _text(json['Designation']),
      division: _text(json['Division']),
      department: _text(json['Department']),
      location: _text(json['Location']),
      date: _text(json['Date']),
      status: _text(json['Status']),
      checkin: _text(json['Checkin']),
      checkout: _text(json['Checkout']),
      shift: _text(json['Shift']),
      shiftStart: _text(json['ShiftStart']),
      shiftEnd: _text(json['ShiftEnd']),
      requiredHours: _text(json['required_hours']),
      workedHours: _text(json['worked_hours']),
      lateCushion: _int(json['LateCushion']),
      attDetail: detail is Map<String, dynamic>
          ? AttDetail.fromJson(detail)
          : null,
    );
  }

  /// Records from a response body: a list, or an object wrapping one in
  /// `data` or `results`. Malformed entries are skipped.
  static List<AttendanceRecord> parseList(Object? body) {
    final list = body is List
        ? body
        : body is Map<String, dynamic>
        ? (body['data'] ?? body['results'])
        : null;
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) AttendanceRecord.fromJson(item),
    ];
  }

  /// The record for [day], if there is one.
  static AttendanceRecord? forDay(
    List<AttendanceRecord> records,
    DateTime day,
  ) {
    final key =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    for (final record in records) {
      if (record.date?.trim().startsWith(key) ?? false) return record;
    }
    return null;
  }
}

int? _int(Object? v) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v.trim()) : null);

/// Text values; numbers become text, and empty or "null" become null.
String? _text(Object? v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}

class AttDetail {
  final bool? calculateExtraHours;

  AttDetail({this.calculateExtraHours});

  factory AttDetail.fromJson(Map<String, dynamic> json) {
    return AttDetail(
      calculateExtraHours: json['calculate_extra_Hours'] == true,
    );
  }
}
