import 'package:dio/dio.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';

abstract class AccidentRepository {
  Future<Either<AppException, Response>> loadAccidentTrainsData();
  Future<Either<AppException, Response>> submitAccident({
    required Map<String, dynamic> fields,
    required List<MapEntry<String, MultipartFile>> files,
  });
  Future<Either<AppException, Response>> loadAccidentById(int id);
  Future<Either<AppException, Response>> loadAccidentList();
}
