import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/tracking/data/train_remote_datasource.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';

class TrainRepositoryImpl implements TrainRepository {
  final TrainRemoteDataSource _remoteDataSource;

  TrainRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppException, Response>> getTrains() async {
    try {
      final response = await _remoteDataSource.getTrains();
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async {
    try {
      final response = await _remoteDataSource.getTrainDetail(trainId);
      return Right(response);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, Response>> getStations({String? pageUrl}) async {
    try {
      return Right(await _remoteDataSource.getStations(pageUrl: pageUrl));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
