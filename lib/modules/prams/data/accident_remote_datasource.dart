import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';

abstract class AccidentRemoteDataSource {
  /// The trains an accident can be reported against.
  Future<Response> loadAccidentTrainsData();
  Future<Response> loadAccidentById(int id);
  Future<Response> loadAccidentList();
  Future<Response> submitAccident({
    required Map<String, dynamic> fields,
    required List<MapEntry<String, MultipartFile>> files,
  });
}

class AccidentRemoteDataSourceImpl implements AccidentRemoteDataSource {
  final DioClient _dioClient;
  AccidentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> loadAccidentTrainsData() =>
      _dioClient.get(ApiEndpoints.getactivetrains);

  @override
  Future<Response> submitAccident({
    required Map<String, dynamic> fields,
    required List<MapEntry<String, MultipartFile>> files,
  }) => _dioClient.postFormData(
    ApiEndpoints.reportaccident,
    fields: fields,
    files: files,
  );

  @override
  Future<Response<dynamic>> loadAccidentById(int id) =>
      _dioClient.get('${ApiEndpoints.getAccidentById}/$id');

  @override
  Future<Response<dynamic>> loadAccidentList() =>
      _dioClient.get(ApiEndpoints.getAccidentById);
}
