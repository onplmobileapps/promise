import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';

/// The inspection API. The signed-in employee's token is added by
/// [DioClient] itself.
abstract class InspectionRemoteDataSource {
  /// The stations of [section] the employee inspects.
  Future<Response> getUserStations({int? section});

  /// A finished inspection of the kind [api] takes.
  Future<Response> submit(InspectionApi api, Map<String, dynamic> payload);
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
  Future<Response> submit(InspectionApi api, Map<String, dynamic> payload) =>
      _dioClient.post(api.path, data: payload, options: _submitting);
}
