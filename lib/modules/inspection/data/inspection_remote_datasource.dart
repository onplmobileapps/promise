import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';

/// The inspection API. The signed-in employee's token is added by
/// [DioClient] itself.
abstract class InspectionRemoteDataSource {
  /// The stations of [section] the employee inspects.
  Future<Response> getUserStations({int? section});

  /// A finished signalling and telecom station inspection.
  Future<Response> submitStationInspection(Map<String, dynamic> payload);

  /// A finished motor trolley inspection.
  Future<Response> submitMotorTrolleyInspection(Map<String, dynamic> payload);
}

class InspectionRemoteDataSourceImpl implements InspectionRemoteDataSource {
  InspectionRemoteDataSourceImpl(this._dioClient);

  final DioClient _dioClient;

  /// An inspection carries photos and many answers: it is given longer to
  /// go up than an ordinary request on a slow connection.
  static final Options _submitting = Options(
    sendTimeout: const Duration(minutes: 2),
    receiveTimeout: const Duration(minutes: 2),
  );

  @override
  Future<Response> getUserStations({int? section}) => _dioClient.get(
    ApiEndpoints.userStations,
    queryParameters: {'section': ?section},
  );

  @override
  Future<Response> submitStationInspection(Map<String, dynamic> payload) =>
      _dioClient.post(
        ApiEndpoints.submitStationInspectionComplete,
        data: payload,
        options: _submitting,
      );

  @override
  Future<Response> submitMotorTrolleyInspection(Map<String, dynamic> payload) =>
      _dioClient.post(
        ApiEndpoints.submitMotorTrolleyComplete,
        data: payload,
        options: _submitting,
      );
}
