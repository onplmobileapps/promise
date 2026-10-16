import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/hrms/data/team_remote_datasource.dart';

/// The admin's team: the day's board and who is on it.
abstract class TeamRepository {
  Future<Either<AppException, Response>> getCounts(DateTime day);
  Future<Either<AppException, Response>> getMembers(DateTime day);
  Future<Either<AppException, Response>> getAllRequests({DateTime? day});
  Future<Either<AppException, Response>> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  });
  Future<Either<AppException, Response>> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  });
}

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl(this._remote);

  final TeamRemoteDataSource _remote;

  @override
  Future<Either<AppException, Response>> getCounts(DateTime day) =>
      _guard(() => _remote.getCounts(day));

  @override
  Future<Either<AppException, Response>> getMembers(DateTime day) =>
      _guard(() => _remote.getMembers(day));

  @override
  Future<Either<AppException, Response>> getAllRequests({DateTime? day}) =>
      _guard(() => _remote.getAllRequests(day: day));

  @override
  Future<Either<AppException, Response>> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  }) => _guard(
    () => _remote.approveLeave(leaveId: leaveId, empId: empId, action: action),
  );

  @override
  Future<Either<AppException, Response>> approveChangeRequest({
    required int crId,
    required dynamic reviewerId,
    required String requestType,
  }) => _guard(
    () => _remote.approveChangeRequest(
      crId: crId,
      reviewerId: reviewerId,
      requestType: requestType,
    ),
  );

  Future<Either<AppException, Response>> _guard(
    Future<Response> Function() call,
  ) async {
    try {
      return Right(await call());
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}
