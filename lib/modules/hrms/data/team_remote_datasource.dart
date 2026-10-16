import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

/// The admin's team, from the attendance API.
abstract class TeamRemoteDataSource {
  /// How many of the team are in, late, on leave and absent on [day].
  Future<Response> getCounts(DateTime day);

  /// Who is on the team, and where each of them is on [day].
  Future<Response> getMembers(DateTime day);

  /// All attendance and leave change requests for the team.
  Future<Response> getAllRequests({DateTime? day});

  /// Approves or rejects a team member's leave request.
  Future<Response> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  });

  /// Approves or rejects a team member's attendance change request.
  Future<Response> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  });
}

class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  TeamRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<Response> getCounts(DateTime day) =>
      _client.post(ApiEndpoints.adminDashCounts, data: {'date': apiDay(day)});

  @override
  Future<Response> getMembers(DateTime day) =>
      _client.post(ApiEndpoints.getActiveList, data: {'date': apiDay(day)});

  @override
  Future<Response> getAllRequests({DateTime? day}) async {
    try {
      return await _client.get(ApiEndpoints.getAllRequests);
    } catch (_) {
      return await _client.post(ApiEndpoints.getAllRequests);
    }
  }

  @override
  Future<Response> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  }) async {
    final parsedEmpId = empId is int
        ? empId
        : (int.tryParse(empId.toString().trim()) ?? empId);
    return _client.post(
      ApiEndpoints.approveLeave,
      data: {'leaveID': leaveId, 'emp_id': parsedEmpId, 'action': action},
    );
  }

  @override
  Future<Response> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  }) async {
    final parsedReviewerId = reviewerId is int
        ? reviewerId
        : (int.tryParse(reviewerId.toString().trim()) ?? reviewerId);
    return _client.post(
      ApiEndpoints.approveChangeRequest,
      data: {
        'cr_id': crId,
        'reviewer_id': parsedReviewerId,
        'request_type': requestType,
      },
    );
  }
}
