import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/screens/live_trains_home_content.dart';

/// Live Tracking: the home page, whose cards open the train list and the
/// all-trains map. They all share one tracking cubit.
class LiveTrainsMainView extends StatelessWidget {
  const LiveTrainsMainView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RealTimeTrackingCubit>()..initialize(),
      child: const LiveTrainsHomeContent(),
    );
  }
}
