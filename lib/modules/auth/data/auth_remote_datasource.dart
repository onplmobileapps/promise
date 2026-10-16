import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';

abstract class AuthRemoteDataSource {
  Future<Response> login(String employeeId, String password, String fcmToken);
  Future<Response> forgotPassword(String email);
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  });
  Future<Response> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> login(
    String employeeId,
    String password,
    String fcmToken,
  ) async {
    final formData = FormData.fromMap({
      "username": employeeId,
      "password": password,
      "fcm_token": fcmToken,
    });
    return await _dioClient.post(ApiEndpoints.login, data: formData);
  }

  @override
  Future<Response> forgotPassword(String email) async {
    return await _dioClient.post(
      ApiEndpoints.forgotPassword,
      data: {"email": email},
    );
  }

  @override
  Future<Response> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    return await _dioClient.post(
      ApiEndpoints.changePassword,
      data: {
        "old_password": oldPassword,
        "new_password": newPassword,
        "confirm_new_password": confirmNewPassword,
      },
    );
  }

  @override
  Future<Response> markAttendance(
    String checkin,
    double latitude,
    double longitude,
    List<MultipartFile> images,
  ) async {
    final formData = FormData.fromMap({
      "att_check": checkin,
      "latitude": latitude,
      "longitude": longitude,
      "images": images,
    });
    return await _dioClient.post(ApiEndpoints.markAttendance, data: formData);
  }
}
