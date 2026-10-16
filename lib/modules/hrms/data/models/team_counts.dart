import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_status.dart';

/// The admin's board for a day, as `adminDashCounts` gives it:
///
/// ```json
/// {"active": 3, "present": 1, "absent": 2, "leave": 0, "OnRestDay": 0,
///  "lateCheckin": 0, "LeaversThisMonth": 0, "JoinersThisMonth": 0,
///  "MobileAttendanceAllowedEmployees": 3}
/// ```
@immutable
class TeamCounts {
  const TeamCounts({
    this.active = 0,
    this.present = 0,
    this.late = 0,
    this.leave = 0,
    this.absent = 0,
    this.restDay = 0,
    this.joiners = 0,
    this.leavers = 0,
    this.mobileAllowed = 0,
  });

  /// The board from the server's answer, which may be wrapped in `data`.
  factory TeamCounts.parse(Object? body) {
    var data = body;
    for (var depth = 0; depth < 2 && data is Map; depth++) {
      final inner = data['data'] ?? data['results'];
      if (inner is! Map && inner is! List) break;
      data = inner;
    }
    if (data is List) {
      data = data.whereType<Map<dynamic, dynamic>>().firstOrNull;
    }
    if (data is! Map) return const TeamCounts();
    final row = ApiRow(data.cast<String, dynamic>());
    int count(List<String> names) => math.max(0, row.number(names) ?? 0);
    return TeamCounts(
      active: count(['active', 'total', 'totalEmployees']),
      present: count(['present']),
      late: count(['lateCheckin', 'late']),
      leave: count(['leave', 'onLeave']),
      absent: count(['absent']),
      restDay: count(['OnRestDay', 'restDay']),
      joiners: count(['JoinersThisMonth']),
      leavers: count(['LeaversThisMonth']),
      mobileAllowed: count(['MobileAttendanceAllowedEmployees']),
    );
  }

  /// Everyone on the team who is employed.
  final int active;

  /// Those who checked in, late or not.
  final int present;

  /// Those of [present] who checked in late.
  final int late;
  final int leave;
  final int absent;

  /// Those whose day off it is.
  final int restDay;

  /// Who joined and who left the team this month.
  final int joiners;
  final int leavers;

  /// Those allowed to mark attendance from the app.
  final int mobileAllowed;

  /// The team's size, when the board gives it.
  int? get total => active > 0 ? active : null;

  /// How many are in [status]. "In" counts those on time, so that the
  /// four statuses add up to the team.
  int of(TeamStatus status) => switch (status) {
    TeamStatus.present => math.max(0, present - late),
    TeamStatus.late => late,
    TeamStatus.leave => leave,
    TeamStatus.absent => absent,
    TeamStatus.other => restDay,
  };

  /// Nobody is on the board.
  bool get isEmpty => active == 0 && present + leave + absent + restDay == 0;

  @override
  bool operator ==(Object other) =>
      other is TeamCounts &&
      other.active == active &&
      other.present == present &&
      other.late == late &&
      other.leave == leave &&
      other.absent == absent &&
      other.restDay == restDay &&
      other.joiners == joiners &&
      other.leavers == leavers &&
      other.mobileAllowed == mobileAllowed;

  @override
  int get hashCode => Object.hash(
    active,
    present,
    late,
    leave,
    absent,
    restDay,
    joiners,
    leavers,
    mobileAllowed,
  );
}
