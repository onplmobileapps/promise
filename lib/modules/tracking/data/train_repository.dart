import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';

abstract class TrainRepository {
  Future<Either<AppException, Response>> getTrains();

  /// Detail for a single train run including schedule, stops, and ETA.
  Future<Either<AppException, Response>> getTrainDetail(String trainId);

  /// The railway's stations; [pageUrl] for a page after the first.
  Future<Either<AppException, Response>> getStations({String? pageUrl});
}
