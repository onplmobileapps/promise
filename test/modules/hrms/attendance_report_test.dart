import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/files/app_downloads.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/reports/attendance_pdf.dart';
import 'package:railway_hrms/modules/hrms/reports/attendance_report.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_download_sheet.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

Response<dynamic> _ok(Object? data) =>
    Response(requestOptions: RequestOptions(), data: data);

/// A month of days for [empId]: on time, late, a leave and an absence,
/// in that turn, with weekends off.
List<Map<String, Object?>> _month(String empId, DateTime from, DateTime to) {
  final rows = <Map<String, Object?>>[];
  var i = 0;
  for (
    var day = from;
    !day.isAfter(to);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    if (day.weekday >= DateTime.saturday) continue;
    final date =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final status = switch (i++ % 6) {
      0 || 1 || 2 => 'Present',
      3 => 'Late',
      4 => 'Leave',
      _ => 'Absent',
    };
    final worked = status == 'Present' || status == 'Late';
    rows.add({
      'AttID': i,
      'Emp_ID': empId,
      'FirstName': 'Ahmed',
      'LastName': 'Raza $empId',
      'Designation': 'Assistant Engineer',
      'Department': 'Mechanical',
      'Division': 'Lahore',
      'Location': 'Lahore Junction',
      'Date': date,
      'Status': status,
      'Shift': 'Morning',
      'ShiftStart': '09:00:00',
      'ShiftEnd': '17:00:00',
      'Checkin': worked ? (status == 'Late' ? '09:42:00' : '08:55:00') : null,
      'Checkout': worked ? '17:10:00' : null,
    });
  }
  return rows;
}

class _Attendance implements EmployeeAttendanceRepository {
  final asked = <String>[];
  Set<String> failing = {};

  @override
  Future<Either<AppException, Response>> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async {
    asked.add(empId);
    if (failing.contains(empId)) return Left(AppException('offline'));
    return Right(_ok({'data': _month(empId, from, to)}));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Leaves implements LeaveRepository {
  @override
  Future<Either<AppException, Response>> getLeaveList({
    required String empId,
  }) async => Right(
    _ok([
      {
        'LeaveID': 1,
        'EmpID': empId,
        'LeaveName': 'Casual leave',
        'FromDate': '2026-09-08',
        'ToDate': '2026-09-09',
        'Status': 'Approved',
        'AppliedDate': '2026-09-01',
        'Remarks': 'Family wedding',
      },
      {
        'LeaveID': 2,
        'EmpID': empId,
        'LeaveName': 'Sick leave',
        'FromDate': '2026-09-29',
        'ToDate': '2026-10-02',
        'Status': 'Pending',
        'AppliedDate': '2026-09-28',
        'Remarks': 'Fever',
      },
      // Long before the report: left out.
      {
        'LeaveID': 3,
        'EmpID': empId,
        'LeaveName': 'Annual leave',
        'FromDate': '2026-03-01',
        'ToDate': '2026-03-05',
        'Status': 'Rejected',
      },
    ]),
  );

  @override
  Future<Either<AppException, Response>> applyLeave(LeaveRequest request) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 10, 10, 15, 30);

  group('the report loader', () {
    test(
      'reads each day, counts it, and keeps the leaves it touches',
      () async {
        final loader = AttendanceReportLoader(
          _Attendance(),
          _Leaves(),
          now: () => now,
        );
        final report = await loader.load(
          subjects: const [ReportSubject(employeeId: '101', name: '')],
          from: DateTime(2026, 9),
          to: DateTime(2026, 9, 30),
          monthly: true,
        );
        final person = report.people.single;
        expect(person.days, hasLength(30));
        // Filled in from the records where nothing was known.
        expect(person.subject.name, 'Ahmed Raza 101');
        expect(person.subject.department, 'Mechanical');
        expect(person.count(AttendanceMark.weekend), 8);
        expect(person.present, greaterThan(0));
        expect(person.count(AttendanceMark.late), greaterThan(0));
        expect(person.worked, greaterThan(Duration.zero));
        expect(person.leaves.map((leave) => leave.leaveID), [1, 2]);
        expect(person.leaveDaysWithin(report.from, report.to), 4);
      },
    );

    test('a range ends today, and a person who fails is marked so', () async {
      final attendance = _Attendance()..failing = {'102'};
      final progress = <int>[];
      final report =
          await AttendanceReportLoader(
            attendance,
            _Leaves(),
            now: () => now,
          ).load(
            subjects: const [
              ReportSubject(employeeId: '101', name: 'A'),
              ReportSubject(employeeId: '102', name: 'B'),
              ReportSubject(employeeId: '103', name: 'C'),
            ],
            from: DateTime(2026, 10),
            to: DateTime(2026, 10, 31),
            monthly: false,
            onProgress: (done, _) => progress.add(done),
          );
      expect(report.to, DateTime(2026, 10, 10));
      expect(report.isTeam, isTrue);
      expect(report.people.map((p) => p.failed), [false, true, false]);
      expect(progress.last, 3);
      expect(attendance.asked.toSet(), {'101', '102', '103'});
    });
  });

  group('the PDF', () {
    late ReportAssets assets;
    late AppLocalizations l10n;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting('en');
      assets = await ReportAssets.load();
      l10n = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('draws one person and a team', () async {
      final loader = AttendanceReportLoader(
        _Attendance()..failing = {'105'},
        _Leaves(),
        now: () => now,
      );
      for (final (name, ids) in [
        ('one', ['101']),
        ('team', ['101', '102', '103', '104', '105']),
      ]) {
        final report = await loader.load(
          subjects: [
            for (final id in ids) ReportSubject(employeeId: id, name: ''),
          ],
          from: DateTime(2026, 9),
          to: DateTime(2026, 9, 30),
          monthly: true,
          madeBy: 'Ahmed Raza',
        );
        final bytes = await AttendancePdf(
          report,
          l10n,
          assets,
          locale: 'en',
        ).build();
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(20000));
        // REPORT_OUT keeps a copy to look at.
        final out = Platform.environment['REPORT_OUT'];
        if (out != null) File('$out/$name.pdf').writeAsBytesSync(bytes);
      }
    });
  });

  group('the download sheet', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    TeamMember member(String id, String name) => TeamMember.parseList({
      'Employees': [
        {'Emp_ID': id, 'FullName': name, 'Designation': 'Driver'},
      ],
    }).single;

    testWidgets('a picked few of the team are saved as one PDF', (
      tester,
    ) async {
      final attendance = _Attendance();
      String? savedAs;
      await pumpScreen(
        tester,
        Scaffold(
          body: AttendanceDownloadSheet(
            loader: AttendanceReportLoader(
              attendance,
              _Leaves(),
              now: () => now,
            ),
            team: [
              member('201', 'Bilal Khan'),
              member('202', 'Sana Iqbal'),
              member('203', 'Usman Ali'),
            ],
            now: () => now,
            save: (bytes, {required name, required mime}) async {
              savedAs = name;
              return SavedFile(uri: 'content://x', name: name, mime: mime);
            },
          ),
        ),
      );
      await tester.tap(find.text('My team'));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);
      // Leave one out.
      await tester.tap(find.text('Sana Iqbal'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 3 selected'), findsOneWidget);

      await tester.ensureVisible(find.text('Download PDF'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Download PDF'));
        for (var i = 0; i < 100 && savedAs == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      expect(attendance.asked.toSet(), {'201', '203'});
      expect(savedAs, 'Team_Attendance_October_2026.pdf');

      // Sharing keeps the dialog, so the file can still be opened after.
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AppDownloads.channel,
        (call) async {
          calls.add(call.method);
          return true;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AppDownloads.channel,
          null,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(calls, ['share']);
      expect(find.text('Share'), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(calls, ['share', 'open']);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsNothing);
    });
  });
}
