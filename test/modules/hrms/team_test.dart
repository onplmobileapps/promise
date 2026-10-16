import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_counts.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_status.dart';
import 'package:railway_hrms/modules/hrms/data/team_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Response<dynamic> _ok(Object? data) => Response(
  requestOptions: RequestOptions(path: ''),
  data: data,
);

/// The board as `adminDashCounts` sends it.
const _board = {
  'active': 3,
  'present': 1,
  'absent': 2,
  'leave': 0,
  'OnRestDay': 0,
  'lateCheckin': 0,
  'LeaversThisMonth': 0,
  'JoinersThisMonth': 0,
  'MobileAttendanceAllowedEmployees': 3,
};

/// One row as `getActiveList` sends it.
Map<String, dynamic> _row({
  int id = 112326,
  String name = 'Muhammad Khalid Shahzad',
  String attendance = 'Absent',
}) => {
  'Shift': 'Morning',
  'Gender': 0,
  'Emp_ID': id,
  'SAPID': id,
  'RoleID': 19,
  'RoleName': 'End User',
  'Rank': null,
  'FullName': name,
  'Department': 'Carriage Shop',
  'Division': 'Islamabad',
  'Location': 'ONE Network',
  'JoinDate': '2026-09-01',
  'Designation': 'XEST/Testing',
  'Status': 'Active',
  'AttStatus': attendance,
  'Profile_Picture_Path': 'data:image/png;base64,${'A' * 2000}',
  'level_one_tier': 99,
  'TierName': 'SulemanQutb',
  'TierPicture': null,
  'TierDesignation': 'Admin',
  'reporting_level': 1,
  'SubSection': 'Carriage Shop',
};

typedef _Reply = Future<Either<AppException, Response>> Function();

class _Team implements TeamRepository {
  @override
  Future<Either<AppException, Response>> getAllRequests({
    DateTime? day,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  }) async => Left(AppException('none'));

  @override
  Future<Either<AppException, Response>> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  }) async => Left(AppException('none'));

  _Team({required this.counts, required this.members});

  _Reply counts;
  _Reply members;

  @override
  Future<Either<AppException, Response>> getCounts(DateTime day) => counts();

  @override
  Future<Either<AppException, Response>> getMembers(DateTime day) => members();
}

void main() {
  group('the board', () {
    test('reads the counts adminDashCounts sends', () {
      final counts = TeamCounts.parse(_board);
      expect(counts.total, 3);
      expect(counts.of(TeamStatus.present), 1);
      expect(counts.of(TeamStatus.absent), 2);
      expect(counts.of(TeamStatus.leave), 0);
      expect(counts.isEmpty, isFalse);
    });

    test('counts the late apart from those in on time', () {
      final counts = TeamCounts.parse({
        ..._board,
        'present': 5,
        'lateCheckin': 2,
      });
      expect(counts.of(TeamStatus.present), 3);
      expect(counts.of(TeamStatus.late), 2);
    });

    test('is empty when the server refuses or sends nothing', () {
      expect(
        TeamCounts.parse({
          'detail': 'You do not have permission to perform this action.',
        }).isEmpty,
        isTrue,
      );
      expect(TeamCounts.parse(null).isEmpty, isTrue);
    });
  });

  group('the members', () {
    test('come from the Employees list, read field by field', () {
      final members = TeamMember.parseList({
        'Employees': [_row(), _row(id: 112555, name: 'Arslan Akbar')],
      });
      expect(members, hasLength(2));
      final first = members.first;
      expect(first.name, 'Muhammad Khalid Shahzad');
      expect(first.employeeId, '112326');
      expect(first.designation, 'XEST/Testing');
      expect(first.reportsTo, 'SulemanQutb');
      expect(first.joinedOn, DateTime(2026, 9));
      expect(first.status, TeamStatus.absent);
    });

    test('being employed is not being at work', () {
      final member = TeamMember.fromJson(_row(attendance: ''));
      expect(member.employment, 'Active');
      expect(member.status, TeamStatus.other);
    });

    test('rows are found wherever the list sits', () {
      expect(apiRows([_row()]), hasLength(1));
      expect(
        apiRows({
          'data': [_row()],
        }),
        hasLength(1),
      );
      expect(
        apiRows({
          'Employees': [_row()],
        }),
        hasLength(1),
      );
      expect(
        apiRows({
          'whatever': [_row()],
        }),
        hasLength(1),
      );
      expect(apiRows({'detail': 'nope'}), isEmpty);
    });
  });

  group('the team cubit', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('an admin with people has a team', () async {
      final cubit = TeamCubit(
        _Team(
          counts: () async => Right(_ok(_board)),
          members: () async => Right(
            _ok({
              'Employees': [_row()],
            }),
          ),
        ),
      );
      await cubit.load();
      expect(cubit.state.load, TeamLoad.ready);
      expect(cubit.state.hasTeam, isTrue);
      expect(cubit.state.size, 3);
    });

    test('someone refused the board has no team, and costs one call', () async {
      var asked = 0;
      final cubit = TeamCubit(
        _Team(
          counts: () async => Left(ServerException('Not allowed')),
          members: () async {
            asked++;
            return Right(_ok({'Employees': <Object>[]}));
          },
        ),
      );
      await cubit.load();
      expect(cubit.state.hasTeam, isFalse);
      expect(cubit.state.failed, isFalse);
      // Nobody reports to them: the list isn't asked for.
      expect(asked, 0);
    });

    test('a board not reached is a failure to try again', () async {
      var asked = 0;
      final cubit = TeamCubit(
        _Team(
          counts: () async => Left(AppException('offline')),
          members: () async {
            asked++;
            return Left(AppException('offline'));
          },
        ),
      );
      await cubit.load();
      expect(cubit.state.failed, isTrue);
      expect(asked, 0);
    });

    test('a quiet reload that fails keeps what was shown', () async {
      final team = _Team(
        counts: () async => Right(_ok(_board)),
        members: () async => Right(
          _ok({
            'Employees': [_row()],
          }),
        ),
      );
      final cubit = TeamCubit(team);
      await cubit.load();
      team.counts = () async => Left(AppException('offline'));
      team.members = () async => Left(AppException('offline'));
      await cubit.load(silent: true);
      expect(cubit.state.hasTeam, isTrue);
      expect(cubit.state.members, hasLength(1));
      expect(cubit.state.failed, isTrue);
    });
  });
}
