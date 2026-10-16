import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';

abstract class FaceRemoteDataSource {
  /// Registers [employeeId]'s face, with a photo of the front of their
  /// CNIC when there is one.
  Future<Response> registerFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude, {
    MultipartFile? cnicImage,
  });
  Future<Response> verifyFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude,
  );
}

class FaceRemoteDataSourceImpl implements FaceRemoteDataSource {
  final DioClient _dioClient;

  /// The form field the CNIC photo is sent in.
  static const cnicImageField = 'cnic_image';

  FaceRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Response> registerFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude, {
    MultipartFile? cnicImage,
  }) async {
    final user = await StorageService.getUser();
    final attCheckBy = user?.user?.empid.toString() ?? '';

    final formData = FormData.fromMap({
      'employee_id': employeeId,
      'images': images,
      'embeddings': jsonEncode(embeddings),
      'att_check_by': attCheckBy,
      cnicImageField: ?cnicImage,
    });

    return await _dioClient.post(ApiEndpoints.faceRegister, data: formData);
  }

  @override
  Future<Response> verifyFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude,
  ) async {
    final user = await StorageService.getUser();
    final attCheckBy = user?.user?.empid.toString() ?? '';

    final formData = FormData.fromMap({
      'employee_id': employeeId,
      'images': images,
      'embeddings': jsonEncode(embeddings),
      'latitude': latitude,
      'longitude': longitude,
      'att_check_by': attCheckBy,
    });
    return await _dioClient.post(ApiEndpoints.faceVerify, data: formData);
  }
}
