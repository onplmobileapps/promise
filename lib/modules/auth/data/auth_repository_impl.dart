import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/api_error_text.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/auth/data/auth_remote_datasource.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> login(
    String employeeId,
    String password,
    String fcmToken,
  ) async {
    try {
      final response = await _remoteDataSource.login(
        employeeId,
        password,
        fcmToken,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> forgotPassword(String email) async {
    try {
      final response = await _remoteDataSource.forgotPassword(email);
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _remoteDataSource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      // Some answers say "no" with a 200: a false success or status.
      final data = response.data;
      if (data is Map &&
          (data['success'] == false ||
              data['status'] == false ||
              '${data['status']}'.toLowerCase() == 'error' ||
              '${data['status']}'.toLowerCase() == 'failed')) {
        return Left(
          ServerException(
            ApiErrorText.of(data) ?? 'Password was not changed',
            '${response.statusCode}',
            Map<String, dynamic>.from(data),
          ),
        );
      }
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  ) async {
    try {
      final response = await _remoteDataSource.markAttendance(
        checkin,
        latitude,
        longitude,
        images,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
