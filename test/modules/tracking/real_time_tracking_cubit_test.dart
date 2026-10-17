import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/services/tracking_cache.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

class _FakeTrainRepository implements TrainRepository {
  _FakeTrainRepository(this.result);

  Either<AppException, Response> result;

  /// Each call made, as the API it asks: the trains, or one train's detail.
  final List<String> calls = [];

  @override
  Future<Either<AppException, Response>> getTrains() async {
    calls.add('tracking/mobile');
    return result;
  }

  @override
  Future<Either<AppException, Response>> getTrainDetail(String trainId) async {
    calls.add('tracking/mobile/$trainId');
    // As the API: the one train, by its id.
    return result.fold(Left.new, (response) {
      final data = response.data;
      final one = data is List
          ? data.whereType<Map<String, dynamic>>().where(
              (t) => '${t['id']}' == trainId,
            )
          : const <Map<String, dynamic>>[];
      return one.isEmpty
          ? Left(AppException('Not found'))
          : Right(_response(one.first));
    });
  }
}

/// Records which devices are watched instead of opening sockets.
class _FakeFeed implements TrainFeed {
  _FakeFeed({required this.onPosition, required this.onLinkChanged});

  final void Function(TrainPosition position) onPosition;
  final void Function(Iterable<int> deviceIds, LinkState? state) onLinkChanged;

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
  void follow(int? deviceId) {}

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

    feed.onLinkChanged([11], LinkState.connecting);
    expect(cubit.state.listeningSinceOf(train), isNull);
    feed.onLinkChanged([11], LinkState.open);
    final opened = cubit.state.listeningSinceOf(train);
    expect(opened, isNotNull);
    expect(cubit.state.openedAtOf(train), opened);

    await Future<void>.delayed(const Duration(milliseconds: 5));
    feed
      ..onLinkChanged([11], LinkState.retrying)
      ..onLinkChanged([11], LinkState.connecting)
      ..onLinkChanged([11], LinkState.open);
    expect(cubit.state.listeningSinceOf(train), opened);
    // But when it last came back is kept too: the server's old reports
    // come first then.
    expect(cubit.state.openedAtOf(train)!.isAfter(opened!), isTrue);

    // Dropped once nobody watches it; the next socket starts over.
    feed.onLinkChanged([11], null);
    expect(cubit.state.listeningSinceOf(train), isNull);
    expect(cubit.state.openedAtOf(train), isNull);
    expect(cubit.state.linkOf(train), isNull);
    await cubit.close();
  });

  test('the map\'s stations are the trains\' own, each once, from the trains '
      'API alone', () async {
    final repository = _FakeTrainRepository(
      Right(
        _response([
          {
            ..._train(1, 101),
            'origin_station': {
              'id': 1,
              'name': 'Lahore Jn',
              'station_code': 'LHR',
              'latitude': '31.58',
              'longitude': '74.34',
            },
          },
          {
            ..._train(2, 102),
            'origin_station': {
              'id': 1,
              'name': 'Lahore Jn',
              'station_code': 'LHR',
              'latitude': '31.58',
              'longitude': '74.34',
            },
            'destination_station': {
              'id': 3,
              'name': 'Khanewal Jn',
              'station_code': 'KWL',
              'latitude': 30.30,
              'longitude': 71.93,
            },
          },
        ]),
      ),
    );
    final cubit = RealTimeTrackingCubit(repository);
    await cubit.initialize();
    // Rawalpindi has no place on the map; Lahore is marked once.
    expect(cubit.state.stations.map((s) => s.code), ['LHR', 'KWL']);
    expect(repository.calls, ['tracking/mobile']);
    await cubit.close();
  });

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
    );
    final cubit = RealTimeTrackingCubit(repository);
    await cubit.initialize();
    final origin = cubit.state.trains.single.origin!;
    expect(origin.code, 'AAD');
    // No place is made up for a station the API has none for.
    expect(origin.position, isNull);
    expect(cubit.state.stations, isEmpty);
    await cubit.close();
  });

  test('tracking opened again starts from what it last knew', () async {
    final cache = TrackingCache();
    late _FakeFeed feed;
    RealTimeTrackingCubit open(_FakeTrainRepository repository) =>
        RealTimeTrackingCubit(
          repository,
          cache: cache,
          feed: ({required onPosition, required onLinkChanged}) => feed =
              _FakeFeed(onPosition: onPosition, onLinkChanged: onLinkChanged),
        );
    final repository = _FakeTrainRepository(
      Right(
        _response([
          {
            ..._trainWithDevice(1, 101, 11),
            'origin_station': {
              'id': 1,
              'name': 'Lahore Jn',
              'latitude': 31.58,
              'longitude': 74.34,
            },
          },
        ]),
      ),
    );
    final first = open(repository);
    await first.initialize();
    first.watchFleet();
    feed.onLinkChanged([11], LinkState.open);
    final report = TrainPosition(
      deviceId: 11,
      position: const LatLng(31.5, 74.3),
      speedKmh: 80,
      course: 0,
      moving: true,
      validFix: true,
      fixTime: DateTime.now(),
    );
    feed.onPosition(report);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final openedAt = first.state.openedAt[11];
    await first.close();

    final second = open(repository);
    // At once, before anything loads.
    expect(second.state.isLoading, isFalse);
    expect(second.state.trains.single.number, 101);
    expect(second.state.positions[11], report);
    expect(second.state.stations, isNotEmpty);
    repository.calls.clear();
    await second.initialize();
    // Refreshed from the trains API alone.
    expect(repository.calls, ['tracking/mobile']);

    // The feed was open just now: in touch since then, not only now.
    second.watchFleet();
    feed.onLinkChanged([11], LinkState.open);
    expect(second.state.openedAt[11], openedAt);
    await second.close();
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

  test('a map closing after another run took its place keeps the new '
      'selection', () async {
    late _FakeFeed feed;
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(
        Right(
          _response([
            _trainWithDevice(1, 101, 11),
            _trainWithDevice(2, 102, 12),
          ]),
        ),
      ),
      feed: ({required onPosition, required onLinkChanged}) => feed = _FakeFeed(
        onPosition: onPosition,
        onLinkChanged: onLinkChanged,
      ),
      route: (_) async => null,
    );
    await cubit.loadTrains();
    // The run picker opens the other run's map in place of this one; the
    // first map goes once the second is up.
    cubit
      ..selectTrain('1')
      ..selectTrain('2')
      ..clearSelection(trainId: '1');
    expect(cubit.state.selectedTrainId, '2');
    expect(feed.watchers, {12: 1});

    cubit.clearSelection(trainId: '2');
    expect(cubit.state.selectedTrainId, isNull);
    expect(feed.watchers, isEmpty);
    await cubit.close();
  });

  test('a burst of every train\'s report gets each its route, a few at a '
      'time', () async {
    late _FakeFeed feed;
    var routed = 0;
    final cubit = RealTimeTrackingCubit(
      _FakeTrainRepository(
        Right(
          _response([
            for (var i = 1; i <= 120; i++)
              {
                ..._trainWithDevice(i, 100 + i, i),
                'origin_station': {
                  'id': 1,
                  'name': 'Lahore Jn',
                  'latitude': 31.0,
                  'longitude': 74.0,
                },
                'destination_station': {
                  'id': 2,
                  'name': 'Shahdara',
                  'latitude': 32.0,
                  'longitude': 75.0,
                },
              },
          ]),
        ),
      ),
      feed: ({required onPosition, required onLinkChanged}) => feed = _FakeFeed(
        onPosition: onPosition,
        onLinkChanged: onLinkChanged,
      ),
      route: (points) async {
        routed++;
        return [
          for (var k = 0; k < 2000; k++)
            LatLng(31 + k * 0.0005, 74 + k * 0.0005),
        ];
      },
    );
    await cubit.loadTrains();
    cubit.watchFleet();
    final now = DateTime.now();
    for (var i = 1; i <= 120; i++) {
      feed.onPosition(
        TrainPosition(
          deviceId: i,
          position: LatLng(31 + i * 0.005, 74 + i * 0.005),
          speedKmh: 60,
          course: 45,
          moving: true,
          validFix: true,
          fixTime: now,
        ),
      );
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(routed, 120);
    expect(cubit.state.paths, hasLength(120));
    await cubit.close();
  });
}
