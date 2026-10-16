import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';

abstract class LeaveRepository {
  Future<Either<AppException, Response>> getEmpLeaveLedger();
  Future<Either<AppException, Response>> applyLeave(LeaveRequest request);
  Future<Either<AppException, Response>> getLeaveHistory();

  /// [empId]'s requests, as a manager sees a team member's.
  Future<Either<AppException, Response>> getLeaveList({required String empId});
}
