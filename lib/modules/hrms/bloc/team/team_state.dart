import 'package:railway_hrms/core/utils/equatable.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_attendance_request.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_counts.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';

enum TeamLoad { idle, loading, ready }

class TeamState extends Equatable {
  const TeamState({
    this.load = TeamLoad.idle,
    this.counts = const TeamCounts(),
    this.members = const [],
    this.requests = const [],
    this.boardFailed = false,
    this.membersFailed = false,
    this.requestsFailed = false,
    this.updatedAt,
  });

  final TeamLoad load;
  final TeamCounts counts;
  final List<TeamMember> members;
  final List<TeamAttendanceRequest> requests;

  /// The board couldn't be reached, so nothing else was asked for.
  final bool boardFailed;

  /// Something couldn't be loaded, to be tried again.
  bool get failed => boardFailed || membersFailed || requestsFailed;

  /// The list couldn't be loaded, though the board may have been.
  final bool membersFailed;

  /// The requests couldn't be loaded.
  final bool requestsFailed;

  /// When the team was last loaded.
  final DateTime? updatedAt;

  /// Someone reports to the signed-in user, so they see the team. Nobody
  /// does for an employee, whose board comes back empty or is refused.
  bool get hasTeam =>
      members.isNotEmpty || requests.isNotEmpty || !counts.isEmpty;

  /// The team's size: the board's total, or else the list's length.
  int get size => counts.total ?? members.length;

  TeamState copyWith({
    TeamLoad? load,
    TeamCounts? counts,
    List<TeamMember>? members,
    List<TeamAttendanceRequest>? requests,
    bool? boardFailed,
    bool? membersFailed,
    bool? requestsFailed,
    DateTime? updatedAt,
  }) => TeamState(
    load: load ?? this.load,
    counts: counts ?? this.counts,
    members: members ?? this.members,
    requests: requests ?? this.requests,
    boardFailed: boardFailed ?? this.boardFailed,
    membersFailed: membersFailed ?? this.membersFailed,
    requestsFailed: requestsFailed ?? this.requestsFailed,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    load,
    counts,
    members,
    requests,
    boardFailed,
    membersFailed,
    requestsFailed,
    updatedAt,
  ];
}
