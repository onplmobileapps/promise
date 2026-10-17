import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';

abstract class TrainRemoteDataSource {
  /// Today's running trains.
  Future<Response> getTrains();

  /// Detail for a single train run including schedule, stops, and ETA.
  Future<Response> getTrainDetail(String trainId);
}

class TrainRemoteDataSourceImpl implements TrainRemoteDataSource {
  final DioClient _dioClient;
  TrainRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> getTrains() => _dioClient.get(ApiEndpoints.getTrainsUrl);

  @override
  Future<Response> getTrainDetail(String trainId) =>
      _dioClient.get('${ApiEndpoints.getTrainsUrl}$trainId/');
}
