import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

/// How long after a shift starts a check-in still counts as on time, when
/// the server doesn't say.
const lateAfter = Duration(minutes: 15);

/// How a day went, as the attendance calendar colours it.
enum AttendanceMark { onTime, late, leave, absent, weekend, none }

/// One day of attendance, read from its record: the times and how the day
/// went.
@immutable
class AttendanceDay {
  const AttendanceDay({
    required this.day,
    required this.mark,
    this.checkIn,
    this.checkOut,
    this.shiftStart,
    this.shiftEnd,
    this.record,
  });

  /// [day] read from [record], which may be missing.
  factory AttendanceDay.of(DateTime day, AttendanceRecord? record) {
    final checkIn = parseAttendanceTime(record?.checkin, on: day);
    final checkOut = parseAttendanceTime(record?.checkout, on: day);
    final shiftStart = parseAttendanceTime(record?.shiftStart, on: day);
    final shiftEnd = parseAttendanceTime(record?.shiftEnd, on: day);
    return AttendanceDay(
      day: day,
      mark: _markOf(day, record, checkIn, shiftStart),
      checkIn: checkIn,
      checkOut: checkOut,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      record: record,
    );
  }

  final DateTime day;
  final AttendanceMark mark;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? shiftStart;
  final DateTime? shiftEnd;
  final AttendanceRecord? record;

  /// The time between checking in and out, or until [now] while still in.
  Duration? workedUntil(DateTime now) {
    final checkIn = this.checkIn;
    if (checkIn == null) return null;
    final until = checkOut ?? (now.isAfter(checkIn) ? now : checkIn);
    return until.difference(checkIn);
  }

  static AttendanceMark _markOf(
    DateTime day,
    AttendanceRecord? record,
    DateTime? checkIn,
    DateTime? shiftStart,
  ) {
    final status = record?.status?.toLowerCase() ?? '';
    final dayType = record?.dayType?.toLowerCase() ?? '';
    if (record?.leaveId != null ||
        status.contains('leave') ||
        dayType.contains('leave')) {
      return AttendanceMark.leave;
    }
    if (status.contains('absent')) return AttendanceMark.absent;
    // The server's word decides, with its own grace; the times only when
    // it says nothing.
    if (status.contains('late')) return AttendanceMark.late;
    if (status.contains('present')) return AttendanceMark.onTime;
    if (checkIn != null) {
      final cushion = record?.lateCushion;
      final grace = cushion == null ? lateAfter : Duration(minutes: cushion);
      return shiftStart != null &&
              _minute(checkIn).isAfter(_minute(shiftStart).add(grace))
          ? AttendanceMark.late
          : AttendanceMark.onTime;
    }
    if (const ['off', 'weekend', 'holiday', 'rest'].any(dayType.contains)) {
      return AttendanceMark.weekend;
    }
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return AttendanceMark.weekend;
    }
    return AttendanceMark.none;
  }

  static DateTime _minute(DateTime time) =>
      DateTime(time.year, time.month, time.day, time.hour, time.minute);
}

/// Every day of [month] that has happened, read from [records].
List<AttendanceDay> attendanceDaysOf(
  DateTime month,
  List<AttendanceRecord> records, {
  required DateTime today,
}) {
  final last = DateTime(month.year, month.month + 1, 0);
  final days = <AttendanceDay>[];
  for (
    var day = DateTime(month.year, month.month);
    !day.isAfter(last) && !day.isAfter(today);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    days.add(AttendanceDay.of(day, AttendanceRecord.forDay(records, day)));
  }
  return days;
}
