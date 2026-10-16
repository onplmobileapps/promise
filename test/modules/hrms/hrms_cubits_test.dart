import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_state.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';

Response<dynamic> _ok(Object? data) => Response(
  requestOptions: RequestOptions(path: ''),
  data: data,
);

typedef _Reply = Future<Either<AppException, Response>> Function();

class _FakeLeaves implements LeaveRepository {
  @override
  Future<Either<AppException, Response>> getLeaveList({
    required String empId,
  }) async => Left(AppException('none'));

  _FakeLeaves({required this.ledger, _Reply? apply, _Reply? history})
    : apply = apply ?? (() async => Right(_ok({'Success': 'Applied'}))),
      history = history ?? (() async => Right(_ok(const <Object>[])));

  _Reply ledger;
  _Reply apply;
  _Reply history;
  int ledgerCalls = 0;
  int historyCalls = 0;

  @override
  Future<Either<AppException, Response>> getLeaveHistory() {
    historyCalls++;
    return history();
  }

  @override
  Future<Either<AppException, Response>> getEmpLeaveLedger() {
    ledgerCalls++;
    return ledger();
  }

  @override
  Future<Either<AppException, Response>> applyLeave(LeaveRequest request) =>
      apply();
}

class _FakeAttendance implements EmployeeAttendanceRepository {
  @override
  Future<Either<AppException, Response>> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  }) async => Left(AppException('offline'));

  @override
  Future<Either<AppException, Response>> getCheckImage({
    required int attId,
    required int empId,
  }) async => Left(AppException('offline'));

  _FakeAttendance(this.reply);

  _Reply reply;

  DateTime? month;

  @override
  Future<Either<AppException, Response>> getEmpAttendance({DateTime? month}) {
    this.month = month;
    return reply();
  }

  @override
  Future<Either<AppException, Response>> getRecentEmployees() =>
      throw UnimplementedError();
}

final _balances = [
  {'LeaveType': 1, 'LeaveTypeName': 'Casual', 'Allotted': 10, 'Consumed': 2},
];

final _request = LeaveRequest(
  leaveTypeID: 1,
  from: '2026-10-05',
  to: '2026-10-05',
  remarks: 'Family function in the village',
);

void main() {
  group('leave cubit', () {
    test('a failed load is an error, not an endless skeleton', () async {
      final cubit = LeaveCubit(
        _FakeLeaves(ledger: () async => Left(AppException('Offline'))),
      );
      await cubit.fetchLeaveLeadger();
      expect(cubit.state.fetchStatus, LeaveStatus.error);
      expect(cubit.state.fetchErrorMessage, 'Offline');
      await cubit.close();
    });

    test('a thrown error is caught too', () async {
      final cubit = LeaveCubit(
        _FakeLeaves(ledger: () async => throw StateError('boom')),
      );
      await cubit.fetchLeaveLeadger();
      expect(cubit.state.fetchStatus, LeaveStatus.error);
      await cubit.close();
    });

    test('a silent refresh keeps the balances when it fails', () async {
      final repo = _FakeLeaves(ledger: () async => Right(_ok(_balances)));
      final cubit = LeaveCubit(repo);
      await cubit.fetchLeaveLeadger();
      repo.ledger = () async => Left(AppException('Offline'));
      await cubit.fetchLeaveLeadger(silent: true);
      expect(cubit.state.fetchStatus, LeaveStatus.loaded);
      expect(cubit.state.records, hasLength(1));
      await cubit.close();
    });

    test('applying refreshes the balances', () async {
      final repo = _FakeLeaves(ledger: () async => Right(_ok(_balances)));
      final cubit = LeaveCubit(repo);
      await cubit.fetchLeaveLeadger();
      await cubit.applyLeave(_request);
      expect(cubit.state.applyStatus, ApplyStatus.success);
      expect(cubit.state.applyMessage, 'Applied');
      expect(repo.ledgerCalls, 2);
      await cubit.close();
    });

    test('a refusal sent with status 200 is an error', () async {
      final repo = _FakeLeaves(
        ledger: () async => Right(_ok(_balances)),
        apply: () async => Right(_ok({'Error': 'Insufficient balance'})),
      );
      final cubit = LeaveCubit(repo);
      await cubit.applyLeave(_request);
      expect(cubit.state.applyStatus, ApplyStatus.error);
      expect(cubit.state.applyMessage, 'Insufficient balance');
      expect(repo.ledgerCalls, 0);
      await cubit.close();
    });

    test('a reply that is not a map still finishes the request', () async {
      final cubit = LeaveCubit(
        _FakeLeaves(
          ledger: () async => Right(_ok(_balances)),
          apply: () async => Right(_ok('OK')),
        ),
      );
      await cubit.applyLeave(_request);
      expect(cubit.state.applyStatus, ApplyStatus.success);
      await cubit.close();
    });
  });

  group('attendance cubit', () {
    test('a thrown error becomes an error state', () async {
      final cubit = AttendanceCubit(
        _FakeAttendance(() async => throw StateError('boom')),
      );
      await cubit.fetchAttendance();
      expect(cubit.state, isA<AttendanceError>());
      await cubit.close();
    });

    test('a silent refresh keeps the records when it fails', () async {
      final repo = _FakeAttendance(
        () async => Right(
          _ok({
            'data': [
              {'Date': '2026-10-02', 'Checkin': '09:05:00'},
            ],
          }),
        ),
      );
      final cubit = AttendanceCubit(repo);
      await cubit.fetchAttendance();
      expect((cubit.state as AttendanceLoaded).records, hasLength(1));
      repo.reply = () async => Left(AppException('Offline'));
      await cubit.fetchAttendance(silent: true);
      expect((cubit.state as AttendanceLoaded).records, hasLength(1));
      await cubit.close();
    });

    test('pull to refresh shows the skeleton, and keeps the records when '
        'it fails', () async {
      final repo = _FakeAttendance(
        () async => Right(
          _ok({
            'data': [
              {'Date': '2026-10-02', 'Checkin': '09:05:00'},
            ],
          }),
        ),
      );
      final cubit = AttendanceCubit(repo);
      await cubit.fetchAttendance();
      repo.reply = () async => Left(AppException('Offline'));
      final seen = <Object>[];
      final sub = cubit.stream.listen(seen.add);
      await cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(seen.first, isA<AttendanceLoading>());
      expect((cubit.state as AttendanceLoaded).records, hasLength(1));
      await sub.cancel();
      await cubit.close();
    });
  });

  test('leave refresh shows the skeleton and keeps the balances when it '
      'fails', () async {
    final repo = _FakeLeaves(ledger: () async => Right(_ok(_balances)));
    final cubit = LeaveCubit(repo);
    await cubit.fetchLeaveLeadger();
    repo.ledger = () async => Left(AppException('Offline'));
    final seen = <LeaveStatus>[];
    final sub = cubit.stream.listen((s) => seen.add(s.fetchStatus));
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    expect(seen.first, LeaveStatus.loading);
    expect(cubit.state.fetchStatus, LeaveStatus.loaded);
    expect(cubit.state.records, hasLength(1));
    await sub.cancel();
    await cubit.close();
  });
}
