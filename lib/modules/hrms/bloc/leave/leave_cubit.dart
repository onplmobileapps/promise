import 'package:flutter/foundation.dart' show debugPrint;
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/hrms/bloc/leave/leave_state.dart';
import 'package:railway_hrms/modules/hrms/data/leave_repository.dart';
import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_types.dart';

class LeaveCubit extends SafeCubit<LeaveState> {
  final LeaveRepository _leaveRepository;
  LeaveCubit(this._leaveRepository) : super(const LeaveState());

  /// Loads the leave balances. A [silent] refresh keeps the balances on
  /// screen while it loads, and keeps them if it fails.
  Future<void> fetchLeaveLeadger({bool silent = false}) {
    final keepShown = silent && state.fetchStatus == LeaveStatus.loaded;
    return _loadLedger(showLoading: !keepShown, keepOnFailure: keepShown);
  }

  /// Pull to refresh: the skeleton shows while it reloads, so the refresh
  /// is seen, and the balances come back if the reload fails.
  Future<void> refresh() => _loadLedger(
    showLoading: true,
    keepOnFailure: state.fetchStatus == LeaveStatus.loaded,
  );

  Future<void> _loadLedger({
    required bool showLoading,
    required bool keepOnFailure,
  }) async {
    if (showLoading) emit(state.copyWith(fetchStatus: LeaveStatus.loading));
    void failed(String message) => emit(
      keepOnFailure
          ? state.copyWith(fetchStatus: LeaveStatus.loaded)
          : state.copyWith(
              fetchStatus: LeaveStatus.error,
              fetchErrorMessage: message,
            ),
    );
    try {
      final response = await _leaveRepository.getEmpLeaveLedger();
      response.fold(
        (failure) => failed(failure.message),
        (data) => emit(
          state.copyWith(
            fetchStatus: LeaveStatus.loaded,
            records: LeaveTypesRecord.parseLeaveTypesList(data.data),
            fetchErrorMessage: null,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Loading leave balances failed: $e');
      failed("Couldn't load leave balances. Please try again.");
    }
  }

  Future<void> applyLeave(LeaveRequest request) async {
    if (state.applyStatus == ApplyStatus.applying) return;
    emit(state.copyWith(applyStatus: ApplyStatus.applying, applyMessage: null));
    try {
      final response = await _leaveRepository.applyLeave(request);
      response.fold(
        (failure) => emit(
          state.copyWith(
            applyStatus: ApplyStatus.error,
            applyMessage: failure.message,
          ),
        ),
        (data) {
          final body = data.data;
          final (ok, message) = _applyOutcome(body);
          emit(
            state.copyWith(
              applyStatus: ok ? ApplyStatus.success : ApplyStatus.error,
              applyMessage: message,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Applying leave failed: $e');
      emit(
        state.copyWith(
          applyStatus: ApplyStatus.error,
          applyMessage: "Couldn't submit the leave request. Please try again.",
        ),
      );
    }
    // The balance changes once a request is in, and the request shows.
    if (state.applyStatus == ApplyStatus.success) {
      await Future.wait([fetchLeaveLeadger(silent: true), fetchHistory()]);
    }
  }

  /// Loads the employee's own requests. The ones shown stay while they
  /// reload, and if the reload fails.
  Future<void> fetchHistory() async {
    final shown = state.historyStatus == LeaveStatus.loaded;
    if (!shown) emit(state.copyWith(historyStatus: LeaveStatus.loading));
    try {
      final response = await _leaveRepository.getLeaveHistory();
      response.fold(
        (_) => emit(
          state.copyWith(
            historyStatus: shown ? LeaveStatus.loaded : LeaveStatus.error,
          ),
        ),
        (data) => emit(
          state.copyWith(
            historyStatus: LeaveStatus.loaded,
            history: EmpLeaveRecord.parseList(data.data),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Loading leave requests failed: $e');
      emit(
        state.copyWith(
          historyStatus: shown ? LeaveStatus.loaded : LeaveStatus.error,
        ),
      );
    }
  }

  /// The server answers 200 even when it refuses a request, with the reason
  /// under `Error`.
  static (bool, String) _applyOutcome(Object? body) {
    String? text(Object? v) {
      final s = v?.toString().trim();
      return s == null || s.isEmpty || s == 'null' ? null : s;
    }

    if (body is Map) {
      final error = text(body['Error']);
      final success = text(body['Success']) ?? text(body['message']);
      if (error != null && success == null) return (false, error);
      return (true, success ?? 'Leave applied successfully');
    }
    return (true, text(body) ?? 'Leave applied successfully');
  }
}
