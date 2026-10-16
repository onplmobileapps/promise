/// Every named route in the app. Each module's screens are registered in
/// its own `*_routes.dart`; `app/routes` puts them together.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String notifications = '/notifications';

  // HRMS
  static const String hrms = '/hrms';
  static const String othersAttendance = '/hrms/others-attendance';
  static const String applyLeave = '/hrms/apply-leave';
  static const String attendanceHistory = '/hrms/attendance-history';

  // Tracking
  static const String liveTracking = '/tracking';
  static const String trainList = '/tracking/trains';

  // Inspection
  static const String inspection = '/inspection';
  static const String civilInspectionHome = '/inspection/civil';
  static const String civilInspectionSleepersRails =
      '/inspection/civil/sleepers-rails';
  static const String electricalInspectionHome = '/inspection/electrical';

  // PRAMS
  static const String prams = '/prams';
  static const String accidentTimeline = '/prams/timeline';
}
