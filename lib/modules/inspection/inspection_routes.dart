import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_inspection_home_screen.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/sleepers_rails_sidings_screen.dart';
import 'package:railway_hrms/modules/inspection/dashboard/inspection_dashboard_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_inspection_home_screen.dart';

/// e-Inspection screens, by route name.
final Map<String, WidgetBuilder> inspectionRoutes = {
  AppRoutes.inspection: (_) => const InspectionDashboardScreen(),
  AppRoutes.civilInspectionHome: (_) => const CivilInspectionHomeScreen(),
  AppRoutes.civilInspectionSleepersRails: (_) =>
      const SleepersRailsSidingsScreen(),
  AppRoutes.electricalInspectionHome: (_) =>
      const ElectricalInspectionHomeScreen(),
};
