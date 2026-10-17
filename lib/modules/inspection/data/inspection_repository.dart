import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';

/// Inspections on the server: what the employee inspects, and their
/// finished reports. Failures come back as an [AppException] whose message
/// can be shown as it is.
abstract class InspectionRepository {
  /// The stations of [section] the employee inspects.
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  });

  Future<Either<AppException, InspectionSubmission>> submitStationInspection(
    Map<String, dynamic> payload,
  );

  Future<Either<AppException, InspectionSubmission>>
  submitMotorTrolleyInspection(Map<String, dynamic> payload);
}
