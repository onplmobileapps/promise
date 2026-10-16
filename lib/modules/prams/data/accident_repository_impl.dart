import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/prams/data/accident_remote_datasource.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';

class AccidentRepositoryImpl implements AccidentRepository {
  final AccidentRemoteDataSource _remoteDataSource;

  AccidentRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> loadAccidentTrainsData() async {
    try {
      final response = await _remoteDataSource.loadAccidentTrainsData();
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> submitAccident({
    required Map<String, dynamic> fields,
    required List<MapEntry<String, MultipartFile>> files,
  }) async {
    try {
      final response = await _remoteDataSource.submitAccident(
        fields: fields,
        files: files,
      );
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> loadAccidentById(int id) async {
    try {
      final response = await _remoteDataSource.loadAccidentById(id);
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response<dynamic>>> loadAccidentList() async {
    try {
      final response = await _remoteDataSource.loadAccidentList();
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
