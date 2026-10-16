import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';

class EmployeeAttendanceRepositoryImpl implements EmployeeAttendanceRepository {
  final EmployeeAttendanceRemoteDataSource _remoteDataSource;

  EmployeeAttendanceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> getEmpAttendance({
    DateTime? month,
  }) async {
    try {
      final response = await _remoteDataSource.getEmpAttendance(month: month);
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getAttendance({
    required String empId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      return Right(
        await _remoteDataSource.getAttendance(empId: empId, from: from, to: to),
      );
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response<dynamic>>> getRecentEmployees() async {
    try {
      final response = await _remoteDataSource.getRecentEmployees();
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  }) async {
    try {
      final response = await _remoteDataSource.applyChangeRequest(
        attId: attId,
        reqCheckIn: reqCheckIn,
        reqCheckOut: reqCheckOut,
        remarks: remarks,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getCheckImage({
    required int attId,
    required int empId,
  }) async {
    try {
      final response = await _remoteDataSource.getCheckImage(
        attId: attId,
        empId: empId,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
