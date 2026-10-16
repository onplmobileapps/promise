import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';

/// Signs nobody in: every attempt fails with [message].
class FailingAuthRepository implements AuthRepository {
  FailingAuthRepository([this.message = 'Invalid employee ID or password']);

  final String message;
  int attempts = 0;

  @override
  Future<Either<AppException, Response>> login(
    String employeeId,
    String password,
    String fcmToken,
  ) async {
    attempts++;
    return Left(AppException(message));
  }

  @override
  Future<Either<AppException, Response>> forgotPassword(String email) async =>
      Left(AppException(message));

  @override
  Future<Either<AppException, Response>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async => Left(AppException(message));

  @override
  Future<Either<AppException, Response>> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  ) async => Left(AppException(message));
}

/// Biometrics that are present or not, and pass or not, as told.
class FakeBiometrics implements BiometricAuthenticator {
  FakeBiometrics({
    this.available = true,
    this.passes = true,
    this.kind = BiometricKind.fingerprint,
  });

  final bool available;
  final bool passes;
  final BiometricKind kind;

  @override
  Future<BiometricKind?> enrolled() async => available ? kind : null;

  @override
  Future<bool> authenticate({required String reason}) async => passes;
}
