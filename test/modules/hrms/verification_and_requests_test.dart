import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_attendance_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';

User _user(Map<String, dynamic> json) => User.fromJson(json);

void main() {
  group('face verification status', () {
    test('a bare "status" in the login reply is not the verification', () {
      final user = _user({'status': 'success', 'face_registered': true});
      expect(user.verificationStatus, isNull);
      expect(user.isApproved, isTrue);
      expect(user.isInProgress, isFalse);
    });

    test('reads the status the server names', () {
      expect(_user({'verification_status': 'Verified'}).isApproved, isTrue);
      expect(
        _user({'verification_status': 'In Progress'}).isInProgress,
        isTrue,
      );
      expect(_user({'Verification_Status': 'Rejected'}).isRejected, isTrue);
      expect(_user({'verification_status': 'Pending'}).isPending, isTrue);
    });

    test('a status it does not know never blocks attendance', () {
      final registered = _user({
        'verification_status': 'Active',
        'face_registered': true,
      });
      expect(registered.isInProgress, isFalse);
      expect(registered.isApproved, isTrue);
      final unregistered = _user({'verification_status': 'Active'});
      expect(unregistered.isInProgress, isFalse);
      expect(unregistered.isPending, isTrue);
    });
  });

  group('team requests', () {
    test('a leave whose type is just "Casual" is a leave, not a change', () {
      final requests = TeamAttendanceRequest.parseList({
        'leaves': [
          {'LeaveID': 7, 'EmpID': 10, 'LeaveTypeName': 'Casual'},
        ],
        'change_requests': [
          {'cr_id': 3, 'EmpID': 11, 'RequestType': 'Check in'},
        ],
      });
      expect(requests, hasLength(2));
      expect(requests[0].isChangeRequest, isFalse);
      expect(requests[0].requestId, 7);
      expect(requests[1].isChangeRequest, isTrue);
      expect(requests[1].crId, 3);
    });

    test('rows in a "data" wrapper are found too', () {
      final requests = TeamAttendanceRequest.parseList({
        'data': {
          'leaves': [
            {'LeaveID': 1, 'EmpID': 10, 'LeaveTypeName': 'Sick'},
          ],
        },
      });
      expect(requests.single.isChangeRequest, isFalse);
    });
  });

  test('team members come from their list alone', () {
    final rows = apiRows({
      'status': 'ok',
      'summary': [
        {'x': 1},
      ],
      'Employees': [
        {'Emp_ID': 1, 'FullName': 'Ali'},
      ],
    });
    expect(rows.single['FullName'], 'Ali');
    expect(
      TeamMember.parseList({
        'data': {
          'Employees': [
            {'Emp_ID': 2, 'FullName': 'Sara'},
          ],
        },
      }).single.name,
      'Sara',
    );
  });
}
