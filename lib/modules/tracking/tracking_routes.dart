import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/tracking/screens/live_trains_main_view.dart';
import 'package:railway_hrms/modules/tracking/screens/train_tracking_view.dart';

/// Train tracking screens, by route name.
final Map<String, WidgetBuilder> trackingRoutes = {
  AppRoutes.liveTracking: (_) => const LiveTrainsMainView(),
  AppRoutes.trainList: (_) => const TrainTrackingView(),
};
