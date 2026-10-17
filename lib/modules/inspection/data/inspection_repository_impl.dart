import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_remote_datasource.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';

class InspectionRepositoryImpl implements InspectionRepository {
  InspectionRepositoryImpl(this._remote);

  final InspectionRemoteDataSource _remote;

  @override
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  }) async {
    try {
      final response = await _remote.getUserStations(section: section);
      return Right(stationsFrom(response.data));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  @override
  Future<Either<AppException, InspectionSubmission>> submitStationInspection(
    Map<String, dynamic> payload,
  ) => _submit(() => _remote.submitStationInspection(payload));

  @override
  Future<Either<AppException, InspectionSubmission>>
  submitMotorTrolleyInspection(Map<String, dynamic> payload) =>
      _submit(() => _remote.submitMotorTrolleyInspection(payload));

  Future<Either<AppException, InspectionSubmission>> _submit(
    Future<dynamic> Function() send,
  ) async {
    try {
      final response = await send();
      return Right(InspectionSubmission.fromResponse(response.data));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }

  /// The stations in the user-stations answer, which comes as a list or
  /// wrapped in one of a few keys, each a record or just a name.
  static List<StationItem> stationsFrom(Object? data) {
    final list = switch (data) {
      final List<Object?> list => list,
      final Map<Object?, Object?> map =>
        map['stations'] ??
            map['data'] ??
            map['results'] ??
            map['user_stations'],
      _ => null,
    };
    if (list is! List) return const [];
    return [
      for (final item in list)
        if (item is Map)
          StationItem.fromJson(Map<String, dynamic>.from(item))
        else if (item != null && item.toString().trim().isNotEmpty)
          StationItem(id: 0, name: item.toString().trim(), code: ''),
    ];
  }
}
