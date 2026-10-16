import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';

abstract class LeaveRemoteDataSource {
  Future<Response> getEmpLeaveLedger();
  Future<Response> applyLeave(LeaveRequest request);

  /// The employee's own requests, newest first or as the server orders
  /// them.
  Future<Response> getLeaveHistory();

  /// [empId]'s requests, as a manager sees a team member's.
  Future<Response> getLeaveList({required String empId});
}

class LeaveRemoteDataSourceImpl implements LeaveRemoteDataSource {
  final DioClient _dioClient;

  LeaveRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> getEmpLeaveLedger() async {
    var data = await StorageService.getUser();
    final empId = data?.user?.empid ?? '';
    return await _dioClient.post(
      ApiEndpoints.getEmpLeaveLedger,
      data: {"emp_id": empId},
    );
  }

  @override
  Future<Response<dynamic>> applyLeave(LeaveRequest request) async {
    var data = await StorageService.getUser();
    final empId = data?.user?.empid ?? '';
    return await _dioClient.post(
      ApiEndpoints.applyLeave,
      data: {
        "emp_id": empId,
        "leaveTypeID": request.leaveTypeID,
        "from": request.from,
        "to": request.to,
        "remarks": request.remarks,
      },
    );
  }

  @override
  Future<Response> getLeaveList({required String empId}) =>
      _dioClient.post(ApiEndpoints.getEmpLeaveList, data: {'emp_id': empId});

  @override
  Future<Response> getLeaveHistory() async {
    final user = await StorageService.getUser();
    return _dioClient.post(
      ApiEndpoints.getEmpLeaveList,
      data: {'emp_id': user?.user?.empid ?? ''},
    );
  }
}
