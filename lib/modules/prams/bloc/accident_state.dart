import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_model.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_reference.dart';

enum AccidentStatus {
  accidentloading,
  accidentloaded,
  accidentError,
  initial,
  loadingReference,
  referenceLoaded,
  referenceError,
  submitting,
  submitted,
  submitError,
  loadingList,
  listLoaded,
  listError,
  approving,
  approved,
  approveError,
  rejecting,
  rejected,
  rejectError,
}

const Object _unset = Object();

class AccidentState {
  final AccidentStatus status;
  final AccidentReferenceData? referenceData;
  final ActiveTrain? selectedTrain;
  final AccidentClass? selectedAccidentClass;
  final DateTime? accidentDateTime;
  final String severity; // pre-filled from the class, editable
  final double? reportedLat;
  final double? reportedLon;
  final double? locoLat;
  final double? locoLong;
  final double? kilometerOverride; // pre-filled from train, editable
  final String? locomotiveOverride; // pre-filled from train, editable
  final bool trainDerailed;
  final bool hasFire;
  final bool peopleInjured;
  final int injuredCount;
  final bool dangerousGoods;
  final String description;
  final int? divisionId;
  final int? sectionId;
  final String? blockSectionId; // UUID
  final String caption; // Single caption for the uploaded images
  final String? errorMessage;
  final Map<String, dynamic>? lastSubmissionResponse;
  final List<Accidents>? accident;
  final Accident? accidentDetails;

  const AccidentState({
    this.status = AccidentStatus.initial,
    this.referenceData,
    this.selectedTrain,
    this.selectedAccidentClass,
    this.accidentDateTime,
    this.severity = '',
    this.reportedLat,
    this.reportedLon,
    this.locoLat,
    this.locoLong,
    this.kilometerOverride,
    this.locomotiveOverride,
    this.trainDerailed = false,
    this.hasFire = false,
    this.peopleInjured = false,
    this.injuredCount = 0,
    this.dangerousGoods = false,
    this.description = '',
    this.divisionId,
    this.sectionId,
    this.blockSectionId,
    this.caption = '',
    this.errorMessage,
    this.lastSubmissionResponse,
    this.accident,
    this.accidentDetails,
  });

  List<ActiveTrain> get trains => referenceData?.activeTrains ?? const [];
  List<AccidentClass> get accidentClasses =>
      referenceData?.accidentClasses ?? const [];
  List<RefDivision> get divisions => referenceData?.divisions ?? const [];

  RefDivision? get selectedDivision =>
      divisions.where((d) => d.id == divisionId).firstOrNull;

  List<RefSection> get availableSections =>
      selectedDivision?.sections ?? const [];

  List<RefBlockSection> get availableBlockSections =>
      selectedDivision?.blockSections ?? const [];

  bool get canSubmit =>
      selectedTrain != null &&
      selectedAccidentClass != null &&
      accidentDateTime != null;

  AccidentState copyWith({
    AccidentStatus? status,
    AccidentReferenceData? referenceData,
    ActiveTrain? selectedTrain,
    bool clearSelectedTrain = false,
    Object? selectedAccidentClass = _unset,
    Object? accidentDateTime = _unset,
    Object? severity = _unset,
    Object? reportedLat = _unset,
    Object? reportedLon = _unset,
    Object? locoLat = _unset,
    Object? locoLong = _unset,
    Object? kilometerOverride = _unset,
    Object? locomotiveOverride = _unset,
    bool? trainDerailed,
    bool? hasFire,
    bool? peopleInjured,
    int? injuredCount,
    bool? dangerousGoods,
    String? description,
    Object? divisionId = _unset,
    Object? sectionId = _unset,
    Object? blockSectionId = _unset,
    String? caption,
    Object? errorMessage = _unset,
    List<Accidents>? accident,
    Object? accidentDetails = _unset,
    Map<String, dynamic>? lastSubmissionResponse,
  }) {
    return AccidentState(
      status: status ?? this.status,
      referenceData: referenceData ?? this.referenceData,
      selectedTrain: clearSelectedTrain
          ? null
          : (selectedTrain ?? this.selectedTrain),

      selectedAccidentClass: identical(selectedAccidentClass, _unset)
          ? this.selectedAccidentClass
          : selectedAccidentClass as AccidentClass?,

      accidentDateTime: identical(accidentDateTime, _unset)
          ? this.accidentDateTime
          : accidentDateTime as DateTime?,

      severity: identical(severity, _unset)
          ? this.severity
          : severity as String,

      reportedLat: identical(reportedLat, _unset)
          ? this.reportedLat
          : reportedLat as double?,

      reportedLon: identical(reportedLon, _unset)
          ? this.reportedLon
          : reportedLon as double?,

      locoLat: identical(locoLat, _unset) ? this.locoLat : locoLat as double?,

      locoLong: identical(locoLong, _unset)
          ? this.locoLong
          : locoLong as double?,

      kilometerOverride: identical(kilometerOverride, _unset)
          ? this.kilometerOverride
          : kilometerOverride as double?,

      locomotiveOverride: identical(locomotiveOverride, _unset)
          ? this.locomotiveOverride
          : locomotiveOverride as String?,

      trainDerailed: trainDerailed ?? this.trainDerailed,
      hasFire: hasFire ?? this.hasFire,
      peopleInjured: peopleInjured ?? this.peopleInjured,
      injuredCount: injuredCount ?? this.injuredCount,
      dangerousGoods: dangerousGoods ?? this.dangerousGoods,
      description: description ?? this.description,

      divisionId: identical(divisionId, _unset)
          ? this.divisionId
          : divisionId as int?,

      sectionId: identical(sectionId, _unset)
          ? this.sectionId
          : sectionId as int?,

      blockSectionId: identical(blockSectionId, _unset)
          ? this.blockSectionId
          : blockSectionId as String?,

      caption: caption ?? this.caption,

      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,

      lastSubmissionResponse:
          lastSubmissionResponse ?? this.lastSubmissionResponse,

      accident: accident ?? this.accident,

      accidentDetails: identical(accidentDetails, _unset)
          ? this.accidentDetails
          : accidentDetails as Accident?,
    );
  }
}
