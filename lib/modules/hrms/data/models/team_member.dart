import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_status.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

/// Someone on the admin's team, as `getActiveList` gives them:
///
/// ```json
/// {"Emp_ID": 112326, "SAPID": 112326, "FullName": "…", "Designation": "…",
///  "Rank": "BPS-01", "Department": "…", "SubSection": "…", "Division": "…",
///  "Location": "…", "Shift": "Morning", "RoleName": "End User",
///  "JoinDate": "2026-09-01", "Status": "Active", "AttStatus": "Absent",
///  "TierName": "…", "TierDesignation": "Admin", "Profile_Picture_Path": …}
/// ```
///
/// Pictures are never read: the server sends them as very long text that
/// nothing here needs.
@immutable
class TeamMember {
  const TeamMember({
    required this.name,
    this.employeeId = '',
    this.sapId = '',
    this.designation = '',
    this.rank = '',
    this.department = '',
    this.subSection = '',
    this.division = '',
    this.location = '',
    this.shift = '',
    this.role = '',
    this.employment = '',
    this.reportsTo = '',
    this.reportsToDesignation = '',
    this.joinedOn,
    this.statusText = '',
    this.status = TeamStatus.other,
    this.checkIn,
    this.checkOut,
  });

  /// A member from one row of the list, their times read [on] that day.
  factory TeamMember.fromJson(Map<String, dynamic> json, {DateTime? on}) {
    final row = ApiRow(json);
    final first = row.text(['FirstName', 'first_name']);
    final last = row.text(['LastName', 'last_name']);
    final full = row.text(['FullName', 'Full_name', 'EmpName', 'Name']);
    final statusText = row.text(['AttStatus', 'AttendanceStatus']);
    final checkIn = parseAttendanceTime(
      row.text(['Checkin', 'CheckInTime', 'InTime']),
      on: on,
    );
    var status = TeamStatus.of(statusText);
    if (status == TeamStatus.other && checkIn != null) {
      status = TeamStatus.present;
    }
    return TeamMember(
      name: full.isNotEmpty ? full : '$first $last'.trim(),
      employeeId: row.text(['Emp_ID', 'EmpID', 'EmployeeID']),
      sapId: row.text(['SAPID', 'SAP_ID']),
      designation: row.text(['Designation', 'DesignationName']),
      rank: row.text(['Rank']),
      department: row.text(['Department', 'DepartmentName']),
      subSection: row.text(['SubSection', 'Section']),
      division: row.text(['Division', 'DivisionName']),
      location: row.text(['Location', 'LocationName']),
      shift: row.text(['Shift', 'ShiftName']),
      role: row.text(['RoleName', 'Role']),
      employment: row.text(['Status']),
      reportsTo: row.text(['TierName']),
      reportsToDesignation: row.text(['TierDesignation']),
      joinedOn: DateTime.tryParse(row.text(['JoinDate', 'Joining_date'])),
      statusText: statusText,
      status: status,
      checkIn: checkIn,
      checkOut: parseAttendanceTime(
        row.text(['Checkout', 'CheckOutTime', 'OutTime']),
        on: on,
      ),
    );
  }

  /// The members in the server's answer, read [on] that day.
  static List<TeamMember> parseList(Object? body, {DateTime? on}) => [
    for (final row in apiRows(body))
      if (TeamMember.fromJson(row, on: on) case final member
          when member.name.isNotEmpty || member.employeeId.isNotEmpty)
        member,
  ];

  final String name;
  final String employeeId;
  final String sapId;
  final String designation;

  /// The pay scale, like "BPS-01".
  final String rank;
  final String department;
  final String subSection;
  final String division;
  final String location;
  final String shift;
  final String role;

  /// Whether they are still employed, like "Active".
  final String employment;

  /// Who they report to, and as what.
  final String reportsTo;
  final String reportsToDesignation;
  final DateTime? joinedOn;

  /// Their attendance today as the server words it, like "Absent".
  final String statusText;
  final TeamStatus status;
  final DateTime? checkIn;
  final DateTime? checkOut;

  @override
  bool operator ==(Object other) =>
      other is TeamMember &&
      other.employeeId == employeeId &&
      other.name == name &&
      other.statusText == statusText &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut;

  @override
  int get hashCode =>
      Object.hash(employeeId, name, statusText, checkIn, checkOut);
}
