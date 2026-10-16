import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

abstract class EmployeeAttendanceRemoteDataSource {
  /// The employee's attendance for [month], this month by default, up to
  /// today.
  Future<Response> getEmpAttendance({DateTime? month});

  /// [empId]'s days from [from] to [to], both included.
  Future<Response> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  });
  Future<Response> getRecentEmployees();
  Future<Response> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  });
  Future<Response> getCheckImage({required int attId, required int empId});
}

class EmployeeAttendanceRemoteDataSourceImpl
    implements EmployeeAttendanceRemoteDataSource {
  final DioClient _dioClient;

  EmployeeAttendanceRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> getEmpAttendance({DateTime? month}) async {
    final now = DateTime.now();
    final first = DateTime((month ?? now).year, (month ?? now).month);
    final last = DateTime(first.year, first.month + 1, 0);
    final user = await StorageService.getUser();
    return _dioClient.post(
      ApiEndpoints.employeeDetails,
      data: {
        'emp_id': user?.user?.empid ?? '',
        'status': '',
        'date_from': apiDay(first),
        'date_to': apiDay(last.isAfter(now) ? now : last),
      },
    );
  }

  @override
  Future<Response> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) => _dioClient.post(
    ApiEndpoints.employeeDetails,
    data: {
      'emp_id': empId,
      'status': '',
      'date_from': apiDay(from),
      'date_to': apiDay(to),
    },
  );

  @override
  Future<Response> getRecentEmployees() async {
    return await _dioClient.get(
      ApiEndpoints.getRecentEmployees,
      queryParameters: {
        'emp_id': (await StorageService.getUser())?.user?.empid ?? '',
      },
    );
  }

  @override
  Future<Response> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  }) async {
    return _dioClient.post(
      ApiEndpoints.applyChangeRequest,
      data: {
        'att_id': attId,
        'req_check_in': reqCheckIn,
        'req_check_out': reqCheckOut,
        'remarks': remarks,
      },
    );
  }

  @override
  Future<Response> getCheckImage({
    required int attId,
    required int empId,
  }) async {
    return _dioClient.post(
      ApiEndpoints.getCheckImage,
      data: {'attID': attId, 'empID': empId},
    );
  }
}
