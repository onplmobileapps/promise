import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/motor_trolley_inspection_model.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';

class MotorTrolleyInspectionCubit extends Cubit<MotorTrolleyInspectionState> {
  final DioClient _dioClient;

  MotorTrolleyInspectionCubit({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient(),
      super(const MotorTrolleyInspectionState());

  /// Updates any of the explicitly-typed fields. Pass only the
  /// parameter(s) that changed.
  void updateField({
    String? inspectingOfficer,
    DateTime? inspectionDate,
    String? betweenStation,
    String? sectionFrom,
    String? sectionTo,
    String? kmFrom,
    String? kmTo,
    String? alignmentReading,
    String? alignmentOutOfLimit,
    String? alignmentReason,
    String? gaugeSpeedCategory,
    String? gaugeReading,
    String? gaugeOutOfLimit,
    String? gaugeReason,
    String? crossLevelReading,
    String? crossLevelOutOfLimit,
    String? crossLevelReason,
    String? railType,
    String? railRemarks,
    String? curveNo,
    String? degreeOfCurve,
    String? curveSpeed,
    String? curveGaugeReading,
    String? curveGaugeOutOfLimit,
    String? curveGaugeAction,
    String? curveGaugeReason,
    String? superElevationReading,
    String? superElevationAction,
    String? curvePostAvailable,
    String? checkRailClearanceCurveReading,
    String? checkRailClearanceCurveStatus,
    String? pcGauge,
    String? pcCrossLevel,
    String? pcFittingsPercentage,
    String? pcSwitchWearAction,
    String? pcSwitchWearReason,
    String? pcCrossingWearAction,
    String? pcCrossingWearReason,
    String? pcCheckRailsClearance,
    String? pcWingRailClearance,
    String? pcCrossingTimbersPercentage,
    String? pcCrossingTimbersAction,
    String? pcCrossingTimbersReason,
    String? lcMannedKmFrom,
    String? lcMannedKmTo,
    String? lcUnmannedKmFrom,
    String? lcUnmannedKmTo,
    String? sbName,
    String? sbKm,
    String? sbSection,
    String? inspectedBy,
    String? designation,
    String? pwiIncharge,
    String? verifiedBy,
  }) {
    emit(
      state.copyWith(
        inspectingOfficer: inspectingOfficer,
        inspectionDate: inspectionDate,
        betweenStation: betweenStation,
        sectionFrom: sectionFrom,
        sectionTo: sectionTo,
        kmFrom: kmFrom,
        kmTo: kmTo,
        alignmentReading: alignmentReading,
        alignmentOutOfLimit: alignmentOutOfLimit,
        alignmentReason: alignmentReason,
        gaugeSpeedCategory: gaugeSpeedCategory,
        gaugeReading: gaugeReading,
        gaugeOutOfLimit: gaugeOutOfLimit,
        gaugeReason: gaugeReason,
        crossLevelReading: crossLevelReading,
        crossLevelOutOfLimit: crossLevelOutOfLimit,
        crossLevelReason: crossLevelReason,
        railType: railType,
        railRemarks: railRemarks,
        curveNo: curveNo,
        degreeOfCurve: degreeOfCurve,
        curveSpeed: curveSpeed,
        curveGaugeReading: curveGaugeReading,
        curveGaugeOutOfLimit: curveGaugeOutOfLimit,
        curveGaugeAction: curveGaugeAction,
        curveGaugeReason: curveGaugeReason,
        superElevationReading: superElevationReading,
        superElevationAction: superElevationAction,
        curvePostAvailable: curvePostAvailable,
        checkRailClearanceCurveReading: checkRailClearanceCurveReading,
        checkRailClearanceCurveStatus: checkRailClearanceCurveStatus,
        pcGauge: pcGauge,
        pcCrossLevel: pcCrossLevel,
        pcFittingsPercentage: pcFittingsPercentage,
        pcSwitchWearAction: pcSwitchWearAction,
        pcSwitchWearReason: pcSwitchWearReason,
        pcCrossingWearAction: pcCrossingWearAction,
        pcCrossingWearReason: pcCrossingWearReason,
        pcCheckRailsClearance: pcCheckRailsClearance,
        pcWingRailClearance: pcWingRailClearance,
        pcCrossingTimbersPercentage: pcCrossingTimbersPercentage,
        pcCrossingTimbersAction: pcCrossingTimbersAction,
        pcCrossingTimbersReason: pcCrossingTimbersReason,
        lcMannedKmFrom: lcMannedKmFrom,
        lcMannedKmTo: lcMannedKmTo,
        lcUnmannedKmFrom: lcUnmannedKmFrom,
        lcUnmannedKmTo: lcUnmannedKmTo,
        sbName: sbName,
        sbKm: sbKm,
        sbSection: sbSection,
        inspectedBy: inspectedBy,
        designation: designation,
        pwiIncharge: pwiIncharge,
        verifiedBy: verifiedBy,
        clearError: true,
      ),
    );
  }

  /// Updates a single config-driven field by its ParamField.key.
  void updateValue(String key, String value) {
    final updated = Map<String, String>.from(state.values);
    updated[key] = value;
    emit(state.copyWith(values: updated, clearError: true));
  }

  void reset() {
    emit(const MotorTrolleyInspectionState());
  }

  Future<void> submit() async {
    emit(
      state.copyWith(isSubmitting: true, clearError: true, isSuccess: false),
    );
    try {
      final token = await StorageService.getAccessToken();
      final submitModel = MotorTrolleyInspectionSubmitModel.fromState(state);
      final payload = submitModel.toJson();

      final response = await _dioClient.post(
        ApiEndpoints.submitMotorTrolleyComplete,
        data: payload,
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      } else {
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: false,
            errorMessage:
                'Failed to submit inspection report. Status: ${response.statusCode}',
          ),
        );
      }
    } on NetworkException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      debugPrint('Motor Trolley Submission Exception: $e');
      emit(
        state.copyWith(
          isSubmitting: false,
          isSuccess: false,
          errorMessage: 'Failed to save inspection report: $e',
        ),
      );
    }
  }
}
