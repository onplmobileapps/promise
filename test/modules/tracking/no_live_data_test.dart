import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/screens/live_trains_home_content.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

import '../../helpers/pump_app.dart';

class _Trains implements TrainRepository {
  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async =>
      Left(AppException('Not found'));

  @override
  Future<Either<AppException, Response>> getTrains() async => Right(
    Response(
      requestOptions: RequestOptions(path: ''),
      data: [
        for (var i = 0; i < 3; i++)
          {
            'id': i,
            'train': {'name': 'Express $i', 'train_no': i + 1, 'direction': 1},
            'device_id': 100 + i,
          },
      ],
    ),
  );
}

/// A feed that opens and never hears from any device.
class _SilentFeed implements TrainFeed {
  _SilentFeed(this.onLinkChanged);

  final void Function(Iterable<int> deviceIds, LinkState? state) onLinkChanged;

  @override
  void watch(int deviceId) => onLinkChanged([deviceId], LinkState.open);

  @override
  void unwatch(int deviceId) {}

  @override
  void follow(int? deviceId) {}

  @override
  void dispose() {}
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('with no live locations coming, the counts shimmer, then the '
      'user is told why', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlocProvider(
          create: (_) => RealTimeTrackingCubit(
            _Trains(),
            feed: ({required onPosition, required onLinkChanged}) =>
                _SilentFeed(onLinkChanged),
          )..initialize(),
          child: const LiveTrainsHomeContent(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    // Live on GPS is still being waited for: a shimmering placeholder.
    expect(find.text('00'), findsOneWidget);
    expect(find.text('No live locations yet'), findsNothing);

    await tester.pump(const Duration(seconds: 45));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No live locations yet'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
