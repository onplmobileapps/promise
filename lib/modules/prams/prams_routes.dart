import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/prams/screens/accident_timeline_screen.dart';
import 'package:railway_hrms/modules/prams/screens/prams_dashboard_screen.dart';

/// PRAMS (accident management) screens, by route name.
final Map<String, WidgetBuilder> pramsRoutes = {
  AppRoutes.prams: (_) => PramsDashboardScreen(),
  AppRoutes.accidentTimeline: (_) => AccidentTimelineScreen(),
};
