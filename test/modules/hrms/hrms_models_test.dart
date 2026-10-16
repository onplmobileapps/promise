import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_attendance_outcome.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_types.dart';
import 'package:railway_hrms/modules/hrms/data/models/recent_employee.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_helpers.dart';

void main() {
  group('attendance records', () {
    test('parse from a list or a wrapped list, skipping junk', () {
      final record = {
        'AttID': '12',
        'Emp_ID': 65546,
        'Date': '2026-10-02',
        'Checkin': '09:05:00',
        'Checkout': null,
        'Status': 'Present',
        'att_detail': 'not a map',
      };
      expect(AttendanceRecord.parseList([record, 'junk']), hasLength(1));
      expect(
        AttendanceRecord.parseList({
          'data': [record],
        }),
        hasLength(1),
      );
      expect(AttendanceRecord.parseList({'Error': 'No data'}), isEmpty);
      final parsed = AttendanceRecord.parseList([record]).single;
      expect(parsed.attId, 12);
      expect(parsed.checkout, isNull);
      expect(parsed.attDetail, isNull);
    });

    test("finds today's record, and only today's", () {
      final records = AttendanceRecord.parseList([
        {'Date': '2026-10-01', 'Checkin': '09:00:00'},
        {'Date': '2026-10-02T00:00:00', 'Checkin': '09:05:00'},
      ]);
      expect(
        AttendanceRecord.forDay(records, DateTime(2026, 10, 2))?.checkin,
        '09:05:00',
      );
      // Nothing yet today: yesterday's times aren't today's.
      expect(AttendanceRecord.forDay(records, DateTime(2026, 10, 3)), isNull);
    });
  });

  group('attendance times', () {
    test('read full timestamps and times of day', () {
      final day = DateTime(2026, 10, 2);
      expect(
        parseAttendanceTime('09:05:30', on: day),
        DateTime(2026, 10, 2, 9, 5, 30),
      );
      expect(
        parseAttendanceTime('2026-10-02 18:10:00'),
        DateTime(2026, 10, 2, 18, 10),
      );
      for (final empty in [null, '', 'null', '--:--', '--:-- AM', 'later']) {
        expect(parseAttendanceTime(empty), isNull, reason: '$empty');
      }
    });

    test('format the same way everywhere', () {
      expect(formatAttendanceTime('09:05:00'), '09:05 AM');
      expect(formatAttendanceTime('2026-10-02T18:10:00'), '06:10 PM');
      expect(formatAttendanceTime(null), '--:--');
    });
  });

  test('leave balances can be half days, strings or missing', () {
    final types = LeaveTypesRecord.parseLeaveTypesList({
      'data': [
        {
          'LeaveType': '3',
          'LeaveTypeName': 'Casual Leave',
          'Allotted': 10,
          'Consumed': 2.5,
          'Remaining': '7.5',
        },
        {'LeaveType': 4, 'LeaveTypeName': 'Earned', 'Allotted': null},
        'junk',
      ],
    });
    expect(types, hasLength(2));
    expect(types.first.leaveType, 3);
    expect(types.first.consumed, 2.5);
    expect(types.first.remaining, 7.5);
    expect(types.last.allotted, 0);
    expect(formatDays(7.5), '7.5');
    expect(formatDays(8.0), '8');
  });

  test('recent employees survive a missing list', () {
    expect(RecentEmployee.fromJson({'Message': 'none'}).employees, isEmpty);
    expect(RecentEmployee.fromJson(null).employees, isEmpty);
    final one = RecentEmployee.fromJson({
      'Employees': [
        {'Emp_ID': '501', 'FullName': 'Ali', 'JoinDate': true},
      ],
    }).employees.single;
    expect(one.empId, 501);
    expect(one.joinDate, isNull);
  });

  test('leave history parses from a wrapped list', () {
    final history = EmpLeaveRecord.parseList({
      'data': [
        {'LeaveID': '7', 'LeaveName': 'Casual Leave', 'Status': null},
      ],
    });
    expect(history.single.leaveID, 7);
    expect(history.single.status, 'Pending');
  });

  group('face attendance outcome', () {
    test('success and matched both mark attendance', () {
      for (final status in ['success', 'matched', 'MATCHED']) {
        final outcome = FaceAttendanceOutcome.fromResponse({
          'status': status,
          'message': 'Checked in at 09:05',
        });
        expect(outcome.success, isTrue, reason: status);
        expect(outcome.message, 'Checked in at 09:05');
      }
    });

    test("failures carry the server's reason", () {
      final failed = FaceAttendanceOutcome.fromResponse({
        'status': 'attendance_failed',
        'detail': 'Outside the allowed area',
      });
      expect(failed.success, isFalse);
      expect(failed.message, 'Outside the allowed area');
      expect(
        FaceAttendanceOutcome.fromResponse({'status': 'not_matched'}).success,
        isFalse,
      );
      expect(FaceAttendanceOutcome.fromResponse('oops').success, isFalse);
    });
  });
}
