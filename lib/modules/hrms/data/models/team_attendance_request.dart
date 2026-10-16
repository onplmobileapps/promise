import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';

/// A leave or attendance change request for a team member.
///
/// Note: [Profile_Picture_Path] is intentionally not parsed or stored.
@immutable
class TeamAttendanceRequest {
  const TeamAttendanceRequest({
    required this.requestId,
    this.crId,
    this.source = '',
    this.hasLeaveId = false,
    required this.empId,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.requestType,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.remarks,
    required this.appliedDate,
  });

  factory TeamAttendanceRequest.fromJson(Map<String, dynamic> json) {
    // Profile_Picture_Path is ignored as instructed.
    final row = ApiRow(json);
    final first = row.text(['FirstName', 'first_name']);
    final last = row.text(['LastName', 'last_name']);
    final full = row.text(['FullName', 'Full_name', 'EmpName', 'Name']);
    final name = full.isNotEmpty ? full : '$first $last'.trim();

    final status = row.text(['Status', 'RequestStatus', 'State']);

    final crMap = json['change_requests'] ?? json['change_request'];
    final crRow = crMap is Map<String, dynamic> ? ApiRow(crMap) : null;
    final parsedCrId =
        row.number(['cr_id', 'CR_ID', 'crId', 'CRID', 'change_request_id']) ??
        crRow?.number(['cr_id', 'CR_ID', 'crId', 'CRID', 'change_request_id']);

    return TeamAttendanceRequest(
      source: json[requestSourceKey]?.toString() ?? '',
      hasLeaveId: row.number(['LeaveID', 'leave_id', 'LeaveId']) != null,
      requestId:
          row.number(['RequestID', 'LeaveID', 'ID', 'Id', 'id']) ??
          (parsedCrId ?? 0),
      crId: parsedCrId,
      empId: row.text(['EmpID', 'Emp_ID', 'SAPID', 'EmployeeID', 'emp_id']),
      employeeName: name,
      designation: row.text(['Designation', 'DesignationName']),
      department: row.text(['Department', 'DepartmentName', 'Division']),
      requestType: row.text([
        'LeaveTypeName',
        'LeaveName',
        'LeaveType',
        'RequestType',
        'Type',
        'Category',
        'Request_Type',
      ]),
      fromDate: row.text([
        'FromDate',
        'From_Date',
        'StartDate',
        'Date',
        'req_check_in',
        'check_in',
      ]),
      toDate: row.text([
        'ToDate',
        'To_Date',
        'EndDate',
        'req_check_out',
        'check_out',
      ]),
      status: status.isNotEmpty ? status : 'Pending',
      remarks: row.text(['Remarks', 'Reason', 'Comments', 'Description']),
      appliedDate: row.text(['AppliedDate', 'AppliedOn', 'CreatedOn']),
    );
  }

  static List<TeamAttendanceRequest> parseList(Object? body) => [
    for (final row in requestRows(body))
      if (TeamAttendanceRequest.fromJson(row) case final req
          when req.employeeName.isNotEmpty ||
              req.empId.isNotEmpty ||
              req.requestId != 0 ||
              (req.crId != null && req.crId != 0) ||
              req.requestType.isNotEmpty)
        req,
  ];

  final int requestId;
  final int? crId;

  /// The list it came in, such as `leaves` or `change_requests`.
  final String source;

  /// It carries a leave's ID, so it is a leave request.
  final bool hasLeaveId;
  final String empId;
  final String employeeName;
  final String designation;
  final String department;
  final String requestType;
  final String fromDate;
  final String toDate;
  final String status;
  final String remarks;
  final String appliedDate;

  /// Whether this is an attendance change request rather than a leave:
  /// it has a change request's ID, or came in the change requests' list.
  /// A leave's type is often just "Casual" or "Sick", so the type alone
  /// never makes it one.
  bool get isChangeRequest {
    if (crId != null && crId != 0) return true;
    final from = source.toLowerCase();
    if (from.contains('change')) return true;
    if (from.contains('leave') || hasLeaveId) return false;
    return requestType.toLowerCase().contains('change');
  }

  @override
  bool operator ==(Object other) =>
      other is TeamAttendanceRequest &&
      other.requestId == requestId &&
      other.empId == empId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(requestId, empId, status);
}
