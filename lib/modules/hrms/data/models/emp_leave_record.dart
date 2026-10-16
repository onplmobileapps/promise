class EmpLeaveRecord {
  final int leaveID;
  final int empID;
  final int sapID;
  final String firstName;
  final String lastName;
  final String department;
  final String division;
  final String location;
  final String designation;
  final int leaveTypeID;
  final String leaveName;
  final String remarks;
  final String appliedDate;
  final String fromDate;
  final String toDate;
  final String status;
  final String appliedBy;
  final String? attachmentPath;
  final String? appliedByPhoto;

  EmpLeaveRecord({
    required this.leaveID,
    required this.empID,
    required this.sapID,
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.division,
    required this.location,
    required this.designation,
    required this.leaveTypeID,
    required this.leaveName,
    required this.remarks,
    required this.appliedDate,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.appliedBy,
    this.attachmentPath,
    this.appliedByPhoto,
  });

  factory EmpLeaveRecord.fromJson(Map<String, dynamic> json) {
    int number(Object? v) =>
        v is num ? v.toInt() : (v is String ? int.tryParse(v.trim()) ?? 0 : 0);
    String text(Object? v, [String fallback = '']) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty || s == 'null' ? fallback : s;
    }

    return EmpLeaveRecord(
      leaveID: number(json['LeaveID']),
      empID: number(json['EmpID']),
      sapID: number(json['SAPID']),
      firstName: text(json['FirstName']),
      lastName: text(json['LastName']),
      department: text(json['Department']),
      division: text(json['Division']),
      location: text(json['Location']),
      designation: text(json['Designation']),
      leaveTypeID: number(json['LeaveTypeID']),
      leaveName: text(json['LeaveName']),
      remarks: text(json['Remarks']),
      appliedDate: text(json['AppliedDate']),
      fromDate: text(json['FromDate']),
      toDate: text(json['ToDate']),
      status: text(json['Status'], 'Pending'),
      appliedBy: text(json['AppliedBy']),
      attachmentPath: json['AttachmentPath']?.toString(),
      appliedByPhoto: json['AppliedByPhoto']?.toString(),
    );
  }

  /// Requests from a response body: a list, or an object wrapping one in
  /// `data` or `results`. Malformed entries are skipped.
  static List<EmpLeaveRecord> parseList(Object? body) {
    final list = body is List
        ? body
        : body is Map<String, dynamic>
        ? (body['data'] ?? body['results'])
        : null;
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) EmpLeaveRecord.fromJson(item),
    ];
  }
}
