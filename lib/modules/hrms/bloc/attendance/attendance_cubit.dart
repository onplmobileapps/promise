import 'package:flutter/foundation.dart' show debugPrint;
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/hrms/bloc/attendance/attendance_state.dart';
import 'package:railway_hrms/modules/hrms/data/employee_attendance_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/attendance_record.dart';

class AttendanceCubit extends SafeCubit<AttendanceState> {
  final EmployeeAttendanceRepository _attendnaceRepository;

  /// The month shown; this month when null.
  final DateTime? month;

  AttendanceCubit(this._attendnaceRepository, {this.month})
    : super(AttendanceInitial());

  /// Loads [month]'s attendance. A [silent] refresh keeps the records on
  /// screen while it loads, and keeps them if it fails.
  Future<void> fetchAttendance({bool silent = false}) {
    final shown = state is AttendanceLoaded ? state as AttendanceLoaded : null;
    final keepShown = silent && shown != null;
    return _load(showLoading: !keepShown, onFailure: keepShown ? shown : null);
  }

  /// Pull to refresh: the skeleton shows while it reloads, so the refresh
  /// is seen, and the records stay if the reload fails.
  Future<void> refresh() {
    final shown = state is AttendanceLoaded ? state as AttendanceLoaded : null;
    return _load(showLoading: true, onFailure: shown);
  }

  Future<void> _load({
    required bool showLoading,
    AttendanceLoaded? onFailure,
  }) async {
    if (showLoading) emit(AttendanceLoading());
    try {
      final response = await _attendnaceRepository.getEmpAttendance(
        month: month,
      );
      response.fold(
        (failure) => emit(onFailure ?? AttendanceError(failure.message)),
        (data) => emit(AttendanceLoaded(AttendanceRecord.parseList(data.data))),
      );
    } catch (e) {
      debugPrint('Loading attendance failed: $e');
      emit(
        onFailure ??
            AttendanceError("Couldn't load attendance. Please try again."),
      );
    }
  }

  /// Submits an attendance change request.
  Future<bool> applyChangeRequest({
    required int attId,
    required String reqCheckIn,
    required String reqCheckOut,
    required String remarks,
  }) async {
    final result = await _attendnaceRepository.applyChangeRequest(
      attId: attId,
      reqCheckIn: reqCheckIn,
      reqCheckOut: reqCheckOut,
      remarks: remarks,
    );
    return result.fold((failure) => false, (data) {
      fetchAttendance(silent: true);
      return true;
    });
  }
}
