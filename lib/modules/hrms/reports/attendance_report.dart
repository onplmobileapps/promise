import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';

/// Someone a report is made for: the signed-in employee, or a member of
/// their team.
@immutable
class ReportSubject {
  const ReportSubject({
    required this.employeeId,
    required this.name,
    this.designation = '',
    this.department = '',
    this.division = '',
    this.location = '',
    this.shift = '',
  });

  /// The `Emp_ID` the server knows them by.
  final String employeeId;
  final String name;
  final String designation;
  final String department;
  final String division;
  final String location;
  final String shift;
}

/// One person's attendance over the report's days, and their leaves.
@immutable
class PersonReport {
  const PersonReport({
    required this.subject,
    required this.days,
    required this.leaves,
    this.failed = false,
  });

  final ReportSubject subject;

  /// Every day of the period that has come, oldest first.
  final List<AttendanceDay> days;

  /// The leaves that touch the period.
  final List<EmpLeaveRecord> leaves;

  /// Their attendance couldn't be loaded; the report says so.
  final bool failed;

  int count(AttendanceMark mark) => days.where((d) => d.mark == mark).length;

  int get present => count(AttendanceMark.onTime) + count(AttendanceMark.late);

  /// Days that were meant to be worked: all but the days off.
  int get workingDays => days.length - count(AttendanceMark.weekend);

  /// Share of working days marked present, from 0 to 1.
  double get rate => workingDays == 0 ? 0 : present / workingDays;

  /// The time worked over the period, from check-in to check-out.
  Duration get worked => days.fold(
    Duration.zero,
    (sum, day) => day.checkIn != null && day.checkOut != null
        ? sum + day.checkOut!.difference(day.checkIn!)
        : sum,
  );

  /// The leave days that fall inside the report, counted once each.
  int leaveDaysWithin(DateTime from, DateTime to) {
    final days = <DateTime>{};
    for (final leave in leaves) {
      final (start, end) = leaveSpan(leave);
      if (start == null || end == null) continue;
      for (
        var day = start.isBefore(from) ? from : start;
        !day.isAfter(end) && !day.isAfter(to);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        days.add(day);
      }
    }
    return days.length;
  }
}

/// The first and last day of [leave], if the server sent them.
(DateTime?, DateTime?) leaveSpan(EmpLeaveRecord leave) {
  final from = DateTime.tryParse(leave.fromDate);
  final to = DateTime.tryParse(leave.toDate) ?? from;
  return (
    from == null ? null : DateTime(from.year, from.month, from.day),
    to == null ? null : DateTime(to.year, to.month, to.day),
  );
}

/// An attendance report: who, over which days, and when it was made.
@immutable
class AttendanceReport {
  const AttendanceReport({
    required this.from,
    required this.to,
    required this.made,
    required this.people,
    required this.monthly,
    this.madeBy = '',
  });

  final DateTime from;
  final DateTime to;
  final DateTime made;
  final List<PersonReport> people;

  /// A calendar month, rather than days picked.
  final bool monthly;

  /// Who downloaded it, for its footer.
  final String madeBy;

  /// More than one person: it opens with the team's summary.
  bool get isTeam => people.length > 1;
}

/// Loads what an [AttendanceReport] needs from the server: each person's
/// days and leaves, a few people at a time.
class AttendanceReportLoader {
  AttendanceReportLoader(
    this._attendance,
    this._leaves, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final EmployeeAttendanceRepository _attendance;
  final LeaveRepository _leaves;
  final DateTime Function() _now;

  /// How many people are loaded at once.
  static const _together = 4;

  /// Loads [subjects] from [from] to [to], telling [onProgress] how many
  /// are done.
  Future<AttendanceReport> load({
    required List<ReportSubject> subjects,
    required DateTime from,
    required DateTime to,
    required bool monthly,
    String madeBy = '',
    void Function(int done, int total)? onProgress,
  }) async {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(from.year, from.month, from.day);
    var last = DateTime(to.year, to.month, to.day);
    if (last.isAfter(today)) last = today;
    final people = List<PersonReport?>.filled(subjects.length, null);
    var done = 0;
    onProgress?.call(0, subjects.length);
    for (var start = 0; start < subjects.length; start += _together) {
      final batch = [
        for (var i = start; i < subjects.length && i < start + _together; i++)
          i,
      ];
      await Future.wait([
        for (final i in batch)
          _person(subjects[i], first, last).then((person) {
            people[i] = person;
            onProgress?.call(++done, subjects.length);
          }),
      ]);
    }
    return AttendanceReport(
      from: first,
      to: last,
      made: now,
      people: [for (final person in people) person!],
      monthly: monthly,
      madeBy: madeBy,
    );
  }

  Future<PersonReport> _person(
    ReportSubject subject,
    DateTime from,
    DateTime to,
  ) async {
    final (attendance, leaves) = await (
      _attendance.getAttendance(empId: subject.employeeId, from: from, to: to),
      _leaves.getLeaveList(empId: subject.employeeId),
    ).wait;
    final records = attendance.fold<List<AttendanceRecord>?>(
      (_) => null,
      (response) => AttendanceRecord.parseList(response.data),
    );
    final touching = leaves.fold<List<EmpLeaveRecord>>(
      (_) => const [],
      (response) => [
        for (final leave in EmpLeaveRecord.parseList(response.data))
          if (_touches(leave, from, to)) leave,
      ],
    );
    return PersonReport(
      subject: _filledIn(subject, records),
      days: [
        for (
          var day = from;
          !day.isAfter(to);
          day = DateTime(day.year, day.month, day.day + 1)
        )
          AttendanceDay.of(
            day,
            AttendanceRecord.forDay(records ?? const [], day),
          ),
      ],
      leaves: touching,
      failed: records == null,
    );
  }

  static bool _touches(EmpLeaveRecord leave, DateTime from, DateTime to) {
    final (start, end) = leaveSpan(leave);
    return start != null &&
        end != null &&
        !start.isAfter(to) &&
        !end.isBefore(from);
  }

  /// [subject] with what their records say where it knew nothing.
  static ReportSubject _filledIn(
    ReportSubject subject,
    List<AttendanceRecord>? records,
  ) {
    final record = records?.firstOrNull;
    if (record == null) return subject;
    String pick(String known, String? sent) =>
        known.isNotEmpty ? known : (sent ?? '').trim();
    final sentName = '${record.firstName ?? ''} ${record.lastName ?? ''}'
        .trim();
    return ReportSubject(
      employeeId: subject.employeeId,
      name: pick(subject.name, sentName),
      designation: pick(subject.designation, record.designation),
      department: pick(subject.department, record.department),
      division: pick(subject.division, record.division),
      location: pick(subject.location, record.location),
      shift: pick(subject.shift, record.shift),
    );
  }
}
