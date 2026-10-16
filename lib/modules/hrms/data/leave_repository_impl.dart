import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/data/leave_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';

class LeaveRepositoryImpl implements LeaveRepository {
  final LeaveRemoteDataSource _remoteDataSource;

  LeaveRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> getEmpLeaveLedger() async {
    try {
      final response = await _remoteDataSource.getEmpLeaveLedger();
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response<dynamic>>> applyLeave(
    LeaveRequest request,
  ) async {
    try {
      final response = await _remoteDataSource.applyLeave(request);
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getLeaveHistory() async {
    try {
      return Right(await _remoteDataSource.getLeaveHistory());
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getLeaveList({
    required String empId,
  }) async {
    try {
      return Right(await _remoteDataSource.getLeaveList(empId: empId));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
