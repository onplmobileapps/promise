import 'package:flutter/widgets.dart';
import 'package:railway_hrms/app/notifications/notification_view.dart';
import 'package:railway_hrms/app/shell/promise_dashboard_view.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/auth/auth_routes.dart';
import 'package:railway_hrms/modules/hrms/hrms_routes.dart';
import 'package:railway_hrms/modules/inspection/inspection_routes.dart';
import 'package:railway_hrms/modules/prams/prams_routes.dart';
import 'package:railway_hrms/modules/tracking/tracking_routes.dart';

/// Every named route of the app: the shell's own and each module's.
class AppRouteRegistry {
  AppRouteRegistry._();

  static final Map<String, WidgetBuilder> _builders = {
    ...authRoutes,
    AppRoutes.home: (_) => const PromiseDashboardView(),
    AppRoutes.notifications: (_) => const NotificationView(),
    ...hrmsRoutes,
    ...trackingRoutes,
    ...inspectionRoutes,
    ...pramsRoutes,
  };

  static WidgetBuilder? builderFor(String? routeName) =>
      routeName == null ? null : _builders[routeName];
}
