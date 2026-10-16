import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';

abstract class EmployeeAttendanceRepository {
  Future<Either<AppException, Response>> getEmpAttendance({DateTime? month});

  /// [empId]'s days from [from] to [to], both included.
  Future<Either<AppException, Response>> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  });
  Future<Either<AppException, Response>> getRecentEmployees();
  Future<Either<AppException, Response>> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  });
  Future<Either<AppException, Response>> getCheckImage({
    required int attId,
    required int empId,
  });
}
