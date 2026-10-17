import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/screens/train_tracking_view.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

class _Trains implements TrainRepository {
  _Trains(this.records);

  final List<Map<String, dynamic>> records;

  @override
  Future<Either<AppException, Response>> getTrains() async =>
      Right(Response(requestOptions: RequestOptions(), data: records));

  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async =>
      Right(
        Response(
          requestOptions: RequestOptions(),
          data: records.firstWhere(
            (r) => '${r['id']}' == trainId,
            orElse: () => records.first,
          ),
        ),
      );

  @override
  Future<Either<AppException, Response>> getStations({String? pageUrl}) async =>
      Left(AppException('none'));
}

class _Feed implements TrainFeed {
  _Feed({required this.onPosition, required this.onLinkChanged});

  final void Function(TrainPosition position) onPosition;
  final void Function(Iterable<int> deviceIds, LinkState? state) onLinkChanged;
  @override
  void watch(int deviceId) {}
  @override
  void unwatch(int deviceId) {}
  @override
  void dispose() {}
}

Map<String, dynamic> _run(int id, String date, {int? device}) => {
  'id': id,
  'train': {'name': 'Khyber Mail', 'train_no': 1, 'direction': 1},
  'effective_date': date,
  'device_id': device,
  'origin_station': {
    'id': 1,
    'name': 'Karachi City',
    'station_code': 'KYC',
    'latitude': '24.85',
    'longitude': '67.00',
  },
  'destination_station': {
    'id': 2,
    'name': 'Peshawar Cantt',
    'station_code': 'PSC',
    'latitude': '34.00',
    'longitude': '71.55',
  },
};

void main() {
  testWidgets('a train on the line twice is one card that asks which day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    String day(int back) {
      final d = now.subtract(Duration(days: back));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    final cubit = RealTimeTrackingCubit(
      _Trains([_run(1, day(1), device: 11), _run(2, day(0), device: 12)]),
      feed: _Feed.new,
      route: (_) async => const [LatLng(24.85, 67.0), LatLng(34.0, 71.55)],
    );
    await cubit.loadTrains();
    expect(cubit.state.runsOf(cubit.state.trains.first), hasLength(2));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const TrainTrackingView(useParentCubit: true),
        ),
      ),
    );
    await tester.pump();
    // One card for the train, saying it runs twice and on which days.
    expect(find.textContaining('Khyber Mail'), findsOneWidget);
    expect(find.text('2 trains · Today, Yesterday'), findsOneWidget);

    await tester.tap(find.textContaining('Khyber Mail'));
    // The cards shimmer until the trains report, so wait for the sheet
    // rather than for everything to settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("Which day's train?"), findsOneWidget);
    expect(find.text("Today's train"), findsOneWidget);
    expect(find.text("Yesterday's train"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
