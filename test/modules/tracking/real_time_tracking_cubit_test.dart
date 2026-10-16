import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

class _FakeTrainRepository implements TrainRepository {
  _FakeTrainRepository(this.result, {this.stationPages = const {}});

  Either<AppException, Response> result;

  /// Station pages by URL; null for the first page.
  final Map<String?, Object> stationPages;
  final List<String?> requestedPages = [];

  @override
  Future<Either<AppException, Response>> getTrains() async => result;

  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async =>
      result;

  @override
  Future<Either<AppException, Response>> getStations({String? pageUrl}) async {
    requestedPages.add(pageUrl);
    final page = stationPages[pageUrl];
    return page == null
        ? Left(AppException('Not found'))
        : Right(_response(page));
  }
}

/// Records which devices are watched instead of opening sockets.
class _FakeFeed implements TrainFeed {
  _FakeFeed({required this.onPosition, required this.onLinkChanged});

  final void Function(TrainPosition position) onPosition;
  final void Function(int deviceId, LinkState? state) onLinkChanged;

  final Map<int, int> watchers = {};

  @override
  void watch(int deviceId) =>
      watchers[deviceId] = (watchers[deviceId] ?? 0) + 1;

  @override
  void unwatch(int deviceId) {
    final left = watchers[deviceId]! - 1;
    left == 0 ? watchers.remove(deviceId) : watchers[deviceId] = left;
  }

  @override
  void dispose() {}
}

Map<String, dynamic> _trainWithDevice(int id, int number, int device) => {
  ..._train(id, number),
  'device_id': device,
};

Response _response(Object data) => Response(
  requestOptions: RequestOptions(path: ''),
  data: data,
);

Map<String, dynamic> _train(int id, int number) => {
  'id': id,
  'train': {'name': 'Express $number', 'train_no': number, 'direction': 1},
  'device_id': null,
  'origin_station': {'id': 1, 'name': 'Lahore Jn', 'station_code': 'LHR'},
  'destination_station': {'id': 2, 'name': 'Rawalpindi', 'station_code': 'RWP'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and sorts the running trains', () async {
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(Right(_response([_train(2, 106), _train(1, 101)]))),
    );
    await cubit.loadTrains();
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.errorMessage, isNull);
    expect(cubit.state.trains.map((t) => t.number), [101, 106]);
    await cubit.close();
  });

  test('reports a failed load', () async {
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(Left(AppException('Session expired'))),
    );
    await cubit.loadTrains();
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.trains, isEmpty);
    expect(cubit.state.errorMessage, 'Session expired');
    await cubit.close();
  });

  test(
    'watches every train with a device while the fleet is on screen',
    () async {
      late _FakeFeed feed;
      final repository = _FakeTrainRepository(
        Right(
          _response([
            _trainWithDevice(1, 101, 11),
            _trainWithDevice(2, 102, 12),
            _train(3, 103),
          ]),
        ),
      );
      final cubit = RealTimeTrackingCubit(
        repository,
        feed: ({required onPosition, required onLinkChanged}) => feed =
            _FakeFeed(onPosition: onPosition, onLinkChanged: onLinkChanged),
      );
      await cubit.loadTrains();
      expect(feed.watchers, isEmpty);

      // The list and the all-trains map can both hold the fleet.
      cubit
        ..watchFleet()
        ..watchFleet();
      expect(feed.watchers, {11: 1, 12: 1});

      // Trains loaded later join it.
      repository.result = Right(
        _response([_trainWithDevice(1, 101, 11), _trainWithDevice(4, 104, 14)]),
      );
      await cubit.loadTrains();
      expect(feed.watchers, {11: 1, 14: 1});

      cubit.unwatchFleet();
      expect(feed.watchers, {11: 1, 14: 1});
      cubit.unwatchFleet();
      expect(feed.watchers, isEmpty);
      await cubit.close();
    },
  );

  test('remembers when each socket first opened, across reconnects', () async {
    late _FakeFeed feed;
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(Right(_response([_trainWithDevice(1, 101, 11)]))),
      feed: ({required onPosition, required onLinkChanged}) => feed = _FakeFeed(
        onPosition: onPosition,
        onLinkChanged: onLinkChanged,
      ),
    );
    await cubit.loadTrains();
    final train = cubit.state.trains.single;

    feed.onLinkChanged(11, LinkState.connecting);
    expect(cubit.state.listeningSinceOf(train), isNull);
    feed.onLinkChanged(11, LinkState.open);
    final opened = cubit.state.listeningSinceOf(train);
    expect(opened, isNotNull);
    expect(cubit.state.openedAtOf(train), opened);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    feed
      ..onLinkChanged(11, LinkState.retrying)
      ..onLinkChanged(11, LinkState.connecting)
      ..onLinkChanged(11, LinkState.open);
    expect(cubit.state.listeningSinceOf(train), opened);
    // But when it last came back is kept too: the server's old reports
    // come first then.
    expect(cubit.state.openedAtOf(train)!.isAfter(opened!), isTrue);

    // Dropped once nobody watches it; the next socket starts over.
    feed.onLinkChanged(11, null);
    expect(cubit.state.listeningSinceOf(train), isNull);
    expect(cubit.state.openedAtOf(train), isNull);
    expect(cubit.state.linkOf(train), isNull);
    await cubit.close();
  });

  test(
    'loads every page of stations, keeping those with coordinates',
    () async {
      const next = 'https://pakistanrailway.org/api/tracking/station/?page=2';
      final repository = _FakeTrainRepository(
        Right(_response(const [])),
        stationPages: {
          null: {
            'next': next,
            'results': [
              {
                'id': 1,
                'name': 'Lahore Jn',
                'station_code': 'LHR',
                'latitude': '31.58',
                'longitude': '74.34',
              },
              {
                'id': 2,
                'name': 'Nowhere',
                'station_code': 'ZZZ',
                'latitude': null,
                'longitude': null,
              },
            ],
          },
          next: {
            'next': null,
            'results': [
              {
                'id': 3,
                'name': 'Khanewal Jn',
                'station_code': 'KWL',
                'latitude': 30.30,
                'longitude': 71.93,
              },
            ],
          },
        },
      );
      final cubit = RealTimeTrackingCubit(repository);
      await cubit.loadStations();
      expect(repository.requestedPages, [null, next]);
      expect(cubit.state.stations.map((s) => s.code), ['LHR', 'KWL']);
      await cubit.close();
    },
  );

  test('keeps the stations as the trains API sends them', () async {
    final repository = _FakeTrainRepository(
      Right(
        _response([
          {
            ..._train(1, 101),
            'origin_station': {'id': 77, 'name': 'Abad', 'station_code': 'AAD'},
          },
        ]),
      ),
      stationPages: {
        // The station list has no codes; ids match the trains API's.
        null: [
          {'id': 77, 'name': 'Abad', 'latitude': 25.4, 'longitude': 68.9},
        ],
      },
    );
    final cubit = RealTimeTrackingCubit(repository);
    await cubit.initialize();
    final origin = cubit.state.trains.single.origin!;
    expect(origin.code, 'AAD');
    // Nothing is borrowed from the station list.
    expect(origin.position, isNull);
    await cubit.close();
  });

  test('selecting a train without a device keeps no live link', () async {
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(Right(_response([_train(1, 101)]))),
    );
    await cubit.loadTrains();
    cubit.selectTrain('1');
    expect(cubit.state.selectedTrain?.number, 101);
    expect(cubit.state.links, isEmpty);
    cubit.clearSelection();
    expect(cubit.state.selectedTrainId, isNull);
    await cubit.close();
  });
}
