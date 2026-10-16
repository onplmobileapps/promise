import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';

abstract class FaceRepository {
  Future<Either<AppException, Response>> registerFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude, {
    MultipartFile? cnicImage,
  });
  Future<Either<AppException, Response>> verifyFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude,
  );
}
