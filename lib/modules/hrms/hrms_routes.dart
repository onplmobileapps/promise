import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/hrms/screens/apply_leave_view.dart';
import 'package:railway_hrms/modules/hrms/screens/attendance_history_view.dart';
import 'package:railway_hrms/modules/hrms/screens/hrms_dashboard_view.dart';
import 'package:railway_hrms/modules/hrms/screens/others_attendance_view.dart';

/// HRMS screens, by route name.
final Map<String, WidgetBuilder> hrmsRoutes = {
  AppRoutes.hrms: (_) => const HrmsDashboardView(),
  AppRoutes.othersAttendance: (_) => const OthersAttendanceView(),
  AppRoutes.applyLeave: (context) =>
      ApplyLeaveView(onBack: () => Navigator.of(context).maybePop()),
  AppRoutes.attendanceHistory: (context) =>
      AttendanceHistoryView(onBack: () => Navigator.of(context).maybePop()),
};
