import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_attendance_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_counts.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/data/team_repository.dart';

/// The admin's team for today: the board of counts, the members, and requests.
class TeamCubit extends SafeCubit<TeamState> {
  TeamCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const TeamState());

  final TeamRepository _repository;
  final DateTime Function() _now;

  /// Employees found to have no team this session, so their board isn't
  /// asked for again until the app restarts.
  static final Set<String> _teamless = {};

  /// Loads the board, then, only for someone with a team, its members and
  /// requests: an employee with nobody reporting to them costs the server
  /// one call, once. A [silent] reload keeps what is shown while it runs,
  /// and keeps it if a part fails.
  Future<void> load({bool silent = false}) async {
    if (state.load == TeamLoad.loading) return;
    final me = (await StorageService.getUser())?.user?.empid?.toString() ?? '';
    if (me.isNotEmpty && _teamless.contains(me)) {
      if (state.load != TeamLoad.ready) {
        emit(const TeamState(load: TeamLoad.ready));
      }
      return;
    }
    if (!silent) emit(state.copyWith(load: TeamLoad.loading));
    final day = _now();
    final counts = await _repository.getCounts(day);
    // The server answering no, rather than not answering, means this
    // employee has no team to see.
    final refused = counts.fold(
      (error) => error is ServerException,
      (_) => false,
    );
    final board = counts.fold<TeamCounts?>(
      (_) => null,
      (response) => TeamCounts.parse(response.data),
    );
    final keep = silent && state.load == TeamLoad.ready;
    if (refused || (board != null && board.isEmpty)) {
      if (me.isNotEmpty) _teamless.add(me);
      emit(TeamState(load: TeamLoad.ready, updatedAt: day));
      return;
    }
    if (board == null) {
      // Not reached: the rest would fail too, so it isn't asked for.
      emit(
        keep
            ? state.copyWith(boardFailed: true)
            : const TeamState(load: TeamLoad.ready, boardFailed: true),
      );
      return;
    }
    final (members, requests) = await (
      _repository.getMembers(day),
      _repository.getAllRequests(day: day),
    ).wait;
    final list = members.fold<List<TeamMember>?>(
      (_) => null,
      (response) => TeamMember.parseList(response.data, on: day),
    );
    final reqs = requests.fold<List<TeamAttendanceRequest>?>(
      (_) => null,
      (response) => TeamAttendanceRequest.parseList(response.data),
    );
    emit(
      TeamState(
        load: TeamLoad.ready,
        counts: board,
        members: list ?? (keep ? state.members : const []),
        requests: reqs ?? (keep ? state.requests : const []),
        membersFailed: list == null,
        requestsFailed: reqs == null,
        updatedAt: day,
      ),
    );
  }

  /// Forgets who had no team, as when someone else signs in.
  static void forgetTeamless() => _teamless.clear();

  /// Approves or rejects a team request and reloads the list.
  Future<bool> approveLeave({
    required int leaveId,
    required dynamic empId,
    required String action,
  }) async {
    final result = await _repository.approveLeave(
      leaveId: leaveId,
      empId: empId,
      action: action,
    );
    return result.fold((failure) => false, (response) {
      load(silent: true);
      return true;
    });
  }

  /// Approves or rejects an attendance change request and reloads the list.
  Future<bool> approveChangeRequest({
    required int crId,
    required String requestType,
  }) async {
    final user = await StorageService.getUser();
    final reviewerId = user?.user?.empid ?? 0;

    final result = await _repository.approveChangeRequest(
      crId: crId,
      reviewerId: reviewerId,
      requestType: requestType,
    );
    return result.fold((failure) => false, (response) {
      load(silent: true);
      return true;
    });
  }
}
