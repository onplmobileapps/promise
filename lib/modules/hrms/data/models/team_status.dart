import 'package:railway_hrms/modules/hrms/data/models/api_row.dart';

/// Where a member of the team is today.
enum TeamStatus {
  present,
  late,
  leave,
  absent,

  /// Anything the board names that isn't one of the above.
  other;

  /// The status a name such as "TotalPresent", "Late" or "On Leave" stands
  /// for.
  static TeamStatus of(String name) {
    final key = ApiRow.normalize(name);
    if (key.contains('late')) return late;
    if (key.contains('leave')) return leave;
    if (key.contains('absent') ||
        key.contains('notmarked') ||
        key.contains('notpresent') ||
        key.contains('missing')) {
      return absent;
    }
    if (key.contains('present') ||
        key == 'in' ||
        key.contains('checkedin') ||
        key.contains('checkin') ||
        key.contains('ontime')) {
      return present;
    }
    return other;
  }
}
