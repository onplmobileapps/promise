import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';

abstract class AuthRepository {
  Future<Either<AppException, Response>> login(
    String employeeId,
    String password,
    String fcmToken,
  );
  Future<Either<AppException, Response>> forgotPassword(String email);
  Future<Either<AppException, Response>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
  Future<Either<AppException, Response>> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  );
}
