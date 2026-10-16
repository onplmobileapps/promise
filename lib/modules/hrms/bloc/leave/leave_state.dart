import 'package:railway_hrms/modules/hrms/data/models/emp_leave_record.dart';
import 'package:railway_hrms/modules/hrms/data/models/leave_types.dart';

enum LeaveStatus { initial, loading, loaded, error }

enum ApplyStatus { initial, applying, success, error }

class LeaveState {
  final List<LeaveTypesRecord> records;
  final LeaveStatus fetchStatus;
  final String? fetchErrorMessage;

  final ApplyStatus applyStatus;
  final String? applyMessage;

  /// The employee's own requests.
  final List<EmpLeaveRecord> history;
  final LeaveStatus historyStatus;

  const LeaveState({
    this.records = const [],
    this.fetchStatus = LeaveStatus.initial,
    this.fetchErrorMessage,
    this.applyStatus = ApplyStatus.initial,
    this.applyMessage,
    this.history = const [],
    this.historyStatus = LeaveStatus.initial,
  });

  static const Object _keep = Object();

  /// Pass null to [fetchErrorMessage] or [applyMessage] to clear it.
  LeaveState copyWith({
    List<LeaveTypesRecord>? records,
    LeaveStatus? fetchStatus,
    Object? fetchErrorMessage = _keep,
    ApplyStatus? applyStatus,
    Object? applyMessage = _keep,
    List<EmpLeaveRecord>? history,
    LeaveStatus? historyStatus,
  }) {
    return LeaveState(
      records: records ?? this.records,
      fetchStatus: fetchStatus ?? this.fetchStatus,
      fetchErrorMessage: identical(fetchErrorMessage, _keep)
          ? this.fetchErrorMessage
          : fetchErrorMessage as String?,
      applyStatus: applyStatus ?? this.applyStatus,
      applyMessage: identical(applyMessage, _keep)
          ? this.applyMessage
          : applyMessage as String?,
      history: history ?? this.history,
      historyStatus: historyStatus ?? this.historyStatus,
    );
  }
}
