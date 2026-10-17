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
import 'package:railway_hrms/modules/tracking/screens/train_tracking_view.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_filters.dart';

import '../../helpers/pump_app.dart';

class _FakeTrainRepository implements TrainRepository {
  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async =>
      Right(
        Response(
          requestOptions: RequestOptions(path: ''),
          data: const {},
        ),
      );

  @override
  Future<Either<AppException, Response>> getTrains() async => Right(
    Response(
      requestOptions: RequestOptions(path: ''),
      data: [
        for (var i = 0; i < 8; i++)
          {
            'id': i,
            'train': {
              'name': i.isEven
                  ? 'Allama Iqbal Express With A Very Long Service Name'
                  : '13$i-UP',
              'train_no': 1000 + i,
              'direction': i.isEven ? 1 : 2,
            },
            // No device: layout only, no live sockets in tests.
            'device_id': null,
            'origin_station': {
              'id': 1,
              'name': 'Karachi Cantonment Junction Station',
              'station_code': 'KC',
            },
            'destination_station': i == 3
                ? null
                : {'id': 2, 'name': 'Peshawar Cantt', 'station_code': 'PSC'},
          },
      ],
    ),
  );
}

const _sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Widget child, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (_) =>
            RealTimeTrackingCubit(_FakeTrainRepository())..initialize(),
        child: child,
      ),
    ),
  );
  // Entrance animations and the train list load.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(loadAppFonts);

  for (final size in _sizes) {
    testWidgets('Live Tracking home lays out at $size', (tester) async {
      await _pumpAt(tester, size, const LiveTrainsHomeContent());
      expect(tester.takeException(), isNull);
      expect(find.text('All trains'), findsOneWidget);
      expect(find.text('Live Trains'), findsOneWidget);
      expect(find.text('VIEW LIVE TRAINS'), findsNothing);
      expect(find.text('Quick Access'), findsNothing);
      expect(find.text('Train Updates'), findsNothing);
      expect(find.text('Train Schedule'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('train list lays out at $size', (tester) async {
      await _pumpAt(
        tester,
        size,
        const TrainTrackingView(useParentCubit: true),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Live Trains'), findsOneWidget);
      expect(find.text('Route not assigned'), findsNothing);
      for (final filter in ['All', 'Moving', 'Stopped', 'UP', 'DN']) {
        expect(
          // The bar scrolls sideways; the last chips start off screen.
          find.descendant(
            of: find.byType(TrainFilterBar),
            matching: find.text(filter, skipOffstage: false),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('home fills a tall screen without scrolling', (tester) async {
    await _pumpAt(tester, const Size(412, 915), const LiveTrainsHomeContent());
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, 0);
    await tester.pumpWidget(const SizedBox());
  });

  // Android's "Large" font size on small phones.
  for (final size in _sizes.take(2)) {
    testWidgets('home and list survive large text at $size', (tester) async {
      await _pumpAt(
        tester,
        size,
        const LiveTrainsHomeContent(),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await _pumpAt(
        tester,
        size,
        const TrainTrackingView(useParentCubit: true),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
