import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/face_verification/face_remote_datasource.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/utils/either.dart';

class FaceRepositoryImpl implements FaceRepository {
  final FaceRemoteDataSource _remoteDataSource;

  FaceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> registerFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude, {
    MultipartFile? cnicImage,
  }) async {
    try {
      final response = await _remoteDataSource.registerFace(
        employeeId,
        images,
        embeddings,
        latitude,
        longitude,
        cnicImage: cnicImage,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> verifyFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _remoteDataSource.verifyFace(
        employeeId,
        images,
        embeddings,
        latitude,
        longitude,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
