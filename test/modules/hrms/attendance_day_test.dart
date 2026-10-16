import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

AttendanceRecord _record({
  String? checkin,
  String? status,
  int? leaveId,
  String? dayType,
  int? lateCushion,
}) => AttendanceRecord(
  date: '2026-10-05',
  checkin: checkin,
  status: status,
  leaveId: leaveId,
  dayType: dayType,
  lateCushion: lateCushion,
  shiftStart: '09:00:00',
  shiftEnd: '18:00:00',
);

void main() {
  final monday = DateTime(2026, 10, 5);

  test('a check-in within the grace is on time', () {
    expect(
      AttendanceDay.of(monday, _record(checkin: '09:14:00')).mark,
      AttendanceMark.onTime,
    );
  });

  test('a check-in after the grace is late', () {
    expect(
      AttendanceDay.of(monday, _record(checkin: '09:16:00')).mark,
      AttendanceMark.late,
    );
  });

  test("the server's grace replaces the guess", () {
    expect(
      AttendanceDay.of(
        monday,
        _record(checkin: '09:05:00', lateCushion: 0),
      ).mark,
      AttendanceMark.late,
    );
    expect(
      AttendanceDay.of(
        monday,
        _record(checkin: '09:40:00', status: 'Present'),
      ).mark,
      AttendanceMark.onTime,
    );
  });

  test("the server's own word wins", () {
    expect(
      AttendanceDay.of(
        monday,
        _record(checkin: '09:00:00', status: 'Late'),
      ).mark,
      AttendanceMark.late,
    );
    expect(
      AttendanceDay.of(monday, _record(status: 'Absent')).mark,
      AttendanceMark.absent,
    );
    expect(
      AttendanceDay.of(monday, _record(leaveId: 7)).mark,
      AttendanceMark.leave,
    );
  });

  test('weekends and days off are weekends', () {
    expect(
      AttendanceDay.of(DateTime(2026, 10, 3), null).mark,
      AttendanceMark.weekend,
    );
    expect(
      AttendanceDay.of(monday, _record(dayType: 'Off Day')).mark,
      AttendanceMark.weekend,
    );
    expect(AttendanceDay.of(monday, null).mark, AttendanceMark.none);
  });

  test('every day of the month so far is read', () {
    final days = attendanceDaysOf(DateTime(2026, 10), [
      _record(checkin: '09:00:00'),
    ], today: DateTime(2026, 10, 5));
    expect(days, hasLength(5));
    expect(days.last.mark, AttendanceMark.onTime);
  });

  test('afternoon times read as such', () {
    expect(
      parseAttendanceTime('02:15 PM', on: monday),
      DateTime(2026, 10, 5, 14, 15),
    );
    expect(
      parseAttendanceTime('12:05 AM', on: monday),
      DateTime(2026, 10, 5, 0, 5),
    );
    expect(apiDay(monday), '2026-10-05');
  });
}
