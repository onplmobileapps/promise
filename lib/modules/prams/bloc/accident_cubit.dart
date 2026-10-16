// accident_cubit.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_state.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_list_item.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_model.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_reference.dart';
import 'package:railway_hrms/modules/prams/services/location_tracking_service.dart';

class AccidentCubit extends SafeCubit<AccidentState> {
  AccidentCubit({required AccidentRepository repository})
    : _repository = repository,
      super(const AccidentState());
  final AccidentRepository _repository;
  Future<void> bootstrap({required int accidentId}) async {
    await loadActiveTrains();
    if (isClosed) return;
    if (state.status == AccidentStatus.referenceError) return;
    await loadAccidentById(accidentId);
  }

  Future<void> loadActiveTrains() async {
    emit(
      state.copyWith(
        status: AccidentStatus.loadingReference,
        errorMessage: null,
      ),
    );
    final result = await _repository.loadAccidentTrainsData();
    if (isClosed) return;
    result.fold(
      (exception) => emit(
        state.copyWith(
          status: AccidentStatus.referenceError,
          errorMessage: exception.message,
        ),
      ),
      (response) {
        final data = AccidentReferenceData.fromJson(
          response.data as Map<String, dynamic>,
        );
        emit(
          state.copyWith(
            status: AccidentStatus.referenceLoaded,
            referenceData: data,
          ),
        );
      },
    );
  }

  Future<void> loadAccidentList() async {
    emit(
      state.copyWith(status: AccidentStatus.loadingList, errorMessage: null),
    );

    final result = await _repository.loadAccidentList();
    if (isClosed) return;

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: AccidentStatus.listError,
          errorMessage: exception.message,
        ),
      ),
      (response) {
        try {
          final listItem = AccidentListItem.fromJson(
            response.data as Map<String, dynamic>,
          );
          final rows = listItem.accidents ?? const <Accidents>[];

          final sorted = List<Accidents>.from(rows)
            ..sort((a, b) {
              final aTime = DateTime.tryParse(a.accidentDateTime ?? '');
              final bTime = DateTime.tryParse(b.accidentDateTime ?? '');
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1; // unparsable dates sink to the end
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // newest first
            });

          emit(
            state.copyWith(status: AccidentStatus.listLoaded, accident: sorted),
          );
        } catch (e) {
          log('error:$e');
          emit(
            state.copyWith(
              status: AccidentStatus.listError,
              errorMessage: 'Unexpected response from server.',
            ),
          );
        }
      },
    );
  }

  Future<void> loadAccidentById(int id) async {
    emit(
      state.copyWith(
        status: AccidentStatus.loadingReference,
        errorMessage: null,
      ),
    );

    final result = await _repository.loadAccidentById(id);
    if (isClosed) return;

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: AccidentStatus.referenceError,
          errorMessage: exception.message,
        ),
      ),
      (response) {
        final mapData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};

        final accidentModel = AccidentModel.fromJson(mapData);
        final accident = accidentModel.accident;

        if (accident == null) {
          emit(
            state.copyWith(
              status: AccidentStatus.referenceError,
              errorMessage: 'Accident data not found in response',
            ),
          );
          return;
        }

        final accidentDateTime = accident.accidentDateTime != null
            ? DateTime.tryParse(accident.accidentDateTime!)
            : null;

        final kilometer = accident.kilometerNumber != null
            ? double.tryParse(accident.kilometerNumber!)
            : null;

        final reportedLat = accident.reportedLat != null
            ? double.tryParse(accident.reportedLat!)
            : null;

        final reportedLon = accident.reportedLog != null
            ? double.tryParse(accident.reportedLog!)
            : null;

        final locoLat = accident.locoLat != null
            ? double.tryParse(accident.locoLat!)
            : null;

        final locoLong = accident.locoLon != null
            ? double.tryParse(accident.locoLon!)
            : null;
        AccidentClass? matchedClass;
        if (state.referenceData != null && accident.accidentClass != null) {
          try {
            matchedClass = state.referenceData!.accidentClasses.firstWhere(
              (c) => c.id == accident.accidentClass,
            );
          } catch (_) {
            matchedClass = null;
          }
        }
        ActiveTrain? matchedTrain;
        if (state.referenceData != null) {
          try {
            matchedTrain = state.referenceData!.activeTrains.firstWhere(
              (t) => t.trainNumber == accident.trainNumber,
            );
          } catch (_) {
            matchedTrain = null;
          }
        }

        emit(
          state.copyWith(
            status: AccidentStatus.referenceLoaded,
            selectedTrain: matchedTrain,
            selectedAccidentClass: matchedClass ?? state.selectedAccidentClass,
            severity: accident.severity ?? '',
            accidentDateTime: accidentDateTime,
            kilometerOverride: kilometer,
            locomotiveOverride: accident.locomotiveNumber,
            reportedLat: reportedLat,
            reportedLon: reportedLon,
            locoLat: locoLat,
            locoLong: locoLong,
            divisionId: accident.division,
            sectionId: accident.section,
            blockSectionId: accident.blockSection,
            trainDerailed: _asBool(accident.trainDerailed),
            hasFire: _asBool(accident.hasFire),
            peopleInjured: _asBool(accident.peopleInjured),
            injuredCount: accident.injuredCount ?? 0,
            dangerousGoods: _asBool(accident.dangerousGoods),
            description: accident.description ?? '',
            lastSubmissionResponse: mapData,
            accidentDetails: accident,
          ),
        );
      },
    );
  }

  void selectTrain(ActiveTrain train) async {
    final latlong = await LocationTrackingService().getCurrentPosition();
    emit(
      state.copyWith(
        selectedTrain: train,
        kilometerOverride: train.kilometerNumber,
        locomotiveOverride: train.locomotiveNumber,
        reportedLat: state.reportedLat ?? train.latitude,
        reportedLon: state.reportedLon ?? train.longitude,
        locoLat: latlong?.latitude,
        locoLong: latlong?.longitude,
        trainDerailed: state.trainDerailed,
        divisionId: train.division?.id,
        sectionId: train.section?.id,
        blockSectionId: train.blockSection?.id,
      ),
    );
  }

  void clearTrain() => emit(
    state.copyWith(
      clearSelectedTrain: true,
      divisionId: null,
      sectionId: null,
      blockSectionId: null,
      caption: '',
      // Reset matched accident-derived fields too, so the form truly clears.
      selectedAccidentClass: null,
      accidentDateTime: null,
      severity: '',
      kilometerOverride: null,
      locomotiveOverride: null,
      trainDerailed: false,
      hasFire: false,
      peopleInjured: false,
      injuredCount: 0,
      dangerousGoods: false,
      description: '',
      errorMessage: null,
      accidentDetails: null,
    ),
  );

  void selectAccidentClass(AccidentClass accidentClass) {
    emit(
      state.copyWith(
        selectedAccidentClass: accidentClass,
        // Pre-fill severity from the class default; operator can still edit it.
        severity: accidentClass.defaultSeverity,
      ),
    );
  }

  void setAccidentDateTime(DateTime dateTime) =>
      emit(state.copyWith(accidentDateTime: dateTime));

  void setKilometer(double? km) => emit(state.copyWith(kilometerOverride: km));

  void setLocomotive(String? locoNumber) =>
      emit(state.copyWith(locomotiveOverride: locoNumber));

  void setTrainDerailed(bool v) => emit(state.copyWith(trainDerailed: v));

  void setHasFire(bool v) => emit(state.copyWith(hasFire: v));

  void setPeopleInjured(bool v) => emit(state.copyWith(peopleInjured: v));

  void setInjuredCount(int v) => emit(state.copyWith(injuredCount: v));

  void setDangerousGoods(bool v) => emit(state.copyWith(dangerousGoods: v));

  void setDescription(String v) => emit(state.copyWith(description: v));

  // ── Division / Section / Block section ─────────────────────────────

  void selectDivision(int? id) => emit(
    state.copyWith(
      divisionId: id,
      sectionId: null, // children belong to the previous division
      blockSectionId: null,
    ),
  );

  void selectSection(int? id) => emit(state.copyWith(sectionId: id));

  void selectBlockSection(String? id) =>
      emit(state.copyWith(blockSectionId: id));

  void setCaption(String v) => emit(state.copyWith(caption: v));

  /// Where the one reporting stands, sent with the report.
  void setReportedLocation(double latitude, double longitude) =>
      emit(state.copyWith(reportedLat: latitude, reportedLon: longitude));

  // ── Build & submit the accident report ─────────────────────────────

  Map<String, dynamic> _buildSubmissionBody() {
    final train = state.selectedTrain;
    if (train == null) {
      throw StateError('No train selected');
    }
    final accidentClass = state.selectedAccidentClass;
    if (accidentClass == null) {
      throw StateError('No accident class selected');
    }
    final dateTime = state.accidentDateTime;
    if (dateTime == null) {
      throw StateError('No accident date/time set');
    }

    return {
      'accident_date_time': dateTime.toUtc().toIso8601String(),
      'accident_class': accidentClass.id,
      'severity': state.severity.isNotEmpty
          ? state.severity
          : accidentClass.defaultSeverity,
      'status': 'REPORTED',
      'train': train.trainId,
      'train_number': train.trainNumber,
      'train_name': train.trainName,
      'train_direction': train.direction,
      'train_type': train.trainType,
      'train_effective_date': train.effectiveDate,
      'locomotive_number': state.locomotiveOverride ?? train.locomotiveNumber,
      'loco_lat': train.latitude,
      'loco_lon': train.longitude,
      'reported_lat': state.reportedLat,
      'reported_log': state.reportedLon, // API field name, not a typo
      'kilometer_number': state.kilometerOverride ?? train.kilometerNumber,
      'division': state.divisionId,
      'section': state.sectionId,
      'block_section': state.blockSectionId,
      'line': train.line?.id,
      'nearest_station': train.nearestStation?.id,
      'last_crossed_station': train.lastCrossedStation?.id,
      'origin_station': train.originStation?.id,
      'destination_station': train.destinationStation?.id,
      'train_derailed': state.trainDerailed,
      'has_fire': state.hasFire,
      'people_injured': state.peopleInjured ? 'YES' : 'NO',
      'injured_count': state.injuredCount,
      'dangerous_goods': state.dangerousGoods ? 'YES' : 'NO',
      'description': state.description,
      'coaches_wagons': train.attachedRollingStock
          .map((e) => e.toJson())
          .toList(),
    };
  }

  Future<
    ({Map<String, dynamic> fields, List<MapEntry<String, MultipartFile>> files})
  >
  _buildMultipartPayload(List<File> photos) async {
    final fields = <String, dynamic>{};

    _buildSubmissionBody().forEach((key, value) {
      if (value == null) return;
      fields[key] = key == 'coaches_wagons' ? jsonEncode(value) : value;
    });

    if (state.caption.trim().isNotEmpty) {
      fields['caption'] = state.caption.trim();
    }
    final files = <MapEntry<String, MultipartFile>>[];
    for (final file in photos) {
      files.add(
        MapEntry(
          'images', // repeated key, one entry per file
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }
    return (fields: fields, files: files);
  }

  Future<bool> submitAccident({List<File> photos = const []}) async {
    if (!state.canSubmit) {
      emit(
        state.copyWith(
          status: AccidentStatus.submitError,
          errorMessage:
              'Select a train, classification, and date/time before submitting.',
        ),
      );
      return false;
    }

    emit(state.copyWith(status: AccidentStatus.submitting, errorMessage: null));
    final payload = await _buildMultipartPayload(photos);
    final result = await _repository.submitAccident(
      fields: payload.fields,
      files: payload.files,
    );

    return result.fold(
      (exception) {
        emit(
          state.copyWith(
            status: AccidentStatus.submitError,
            errorMessage: exception.message,
          ),
        );
        return false;
      },
      (response) {
        final decoded = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
        emit(
          state.copyWith(
            status: AccidentStatus.submitted,
            lastSubmissionResponse: decoded,
          ),
        );
        return true;
      },
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  static bool _asBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toUpperCase();
      return s == 'YES' || s == 'TRUE' || s == '1';
    }
    return false;
  }
}
