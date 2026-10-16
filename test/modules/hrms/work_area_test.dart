import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';
import 'package:railway_hrms/modules/hrms/widgets/work_area_markers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The `getAuthArea` response as the server sends it.
final _authArea = [
  {
    'emp_id': 135390,
    'offices': [
      {
        'id': 1345,
        'unit_name': 'Islamabad',
        'location_name': 'ONE Network',
        'latitude': 33.5892,
        'longitude': 73.0465,
        'radius': 200,
        'is_primary': false,
        'is_active': true,
      },
      {
        'id': 1350,
        'unit_name': 'Islamabad',
        'location_name': 'Railway Ministry',
        'latitude': '33.73872',
        'longitude': '73.09606',
        'radius': '700',
        'is_active': true,
      },
      {
        'id': 1360,
        'location_name': 'Closed office',
        'latitude': 33.6,
        'longitude': 73.0,
        'is_active': false,
      },
    ],
  },
];

class _FakeLocation implements PositionSource {
  final positions$ = StreamController<Position>.broadcast();
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;

  @override
  Future<bool> serviceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async => permission;
  @override
  Stream<Position> positions() => positions$.stream;

  /// What a one-off fix finds; the next report otherwise.
  Position? fresh;
  int fixes = 0;

  @override
  Future<Position> current() async {
    fixes++;
    return fresh ?? await positions$.stream.first;
  }

  @override
  Stream<ServiceStatus> serviceStatus() => const Stream.empty();
  @override
  Future<void> openLocationSettings() async {}
  @override
  Future<void> openAppSettings() async {}
}

Position _at(
  double lat,
  double lng, {
  double accuracy = 10,
  bool mocked = false,
  Duration age = Duration.zero,
}) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.now().subtract(age),
  accuracy: accuracy,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  isMocked: mocked,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reads every active office from the auth area response', () {
    final offices = WorkOffice.parseAuthArea(_authArea);
    expect(offices.map((o) => o.name), ['ONE Network', 'Railway Ministry']);
    expect(offices.first.address, 'ONE Network, Islamabad');
    expect(offices.last.radiusM, 700);
    expect(WorkOffice.parseAuthArea({'data': _authArea}), hasLength(2));
    expect(WorkOffice.parseAuthArea('nothing'), isEmpty);
  });

  test('a fence contains points within its radius', () {
    final office = WorkOffice.parseAuthArea(_authArea).first;
    // 55 m from the office.
    expect(office.contains(const LatLng(33.5887359, 73.0466856)), isTrue);
    // About 1.1 km north.
    const far = LatLng(33.5992, 73.0465);
    expect(office.contains(far), isFalse);
    expect(office.distanceToEdgeM(far), closeTo(906, 15));
    final edge = office.nearestEdgePoint(far);
    expect(distanceMeters(office.center, edge), closeTo(200, 1));
    expect(formatDistance(906), '906 m');
    expect(formatDistance(1234), '1.2 km');
  });

  test('the map avatar uses initials or a full photo address', () {
    expect(initialsOf('Pervaiz Pervaiz'), 'PP');
    expect(initialsOf('  ali  '), 'A');
    expect(initialsOf('null null'), '');
    expect(initialsOf(null), '');
    expect(photoUrl(null), isNull);
    expect(photoUrl('null'), isNull);
    expect(
      photoUrl('https://cdn.example.com/a.jpg', base: 'https://x.org/api/'),
      'https://cdn.example.com/a.jpg',
    );
    expect(
      photoUrl('/media/p/1.jpg', base: 'https://x.org/api/'),
      'https://x.org/media/p/1.jpg',
    );
    expect(photoUrl('media/p/1.jpg'), isNull);
    // The server's stand-in for no photo isn't there to download.
    expect(
      photoUrl(
        'https://pakistanrailway.org/api/media/profile_images/'
        'default_profile_image.png',
      ),
      isNull,
    );
    expect(
      photoUrl(
        '/media/profile_images/default_profile_image.png',
        base: 'https://x.org/api/',
      ),
      isNull,
    );
  });

  test('a rooted phone, and an emulator in release builds, are refused', () {
    final rooted = DeviceIntegrity.fromReport({
      'rooted': true,
      'reasons': ['installed com.topjohnwu.magisk'],
    });
    expect(rooted.blockReason(), contains('rooted'));
    final emulator = DeviceIntegrity.fromReport({'emulator': true});
    expect(emulator.blockReason(allowEmulator: true), isNull);
    expect(emulator.blockReason(allowEmulator: false), contains('emulator'));
    expect(const DeviceIntegrity().blockReason(allowEmulator: false), isNull);
  });

  group('work area cubit', () {
    late _FakeLocation location;
    late WorkAreaCubit cubit;

    setUp(() {
      location = _FakeLocation();
      cubit = WorkAreaCubit(fetch: () async => _authArea, location: location);
    });

    tearDown(() => cubit.close());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('inside the nearest office, then outside every one', () async {
      await cubit.start();
      expect(cubit.state.offices, hasLength(2));
      expect(cubit.state.presence, Presence.unknown);

      location.positions$.add(_at(33.5887359, 73.0466856));
      await settle();
      expect(cubit.state.presence, Presence.inside);
      expect(cubit.state.currentOffice?.name, 'ONE Network');

      location.positions$.add(_at(33.62, 73.06));
      await settle();
      expect(cubit.state.presence, Presence.outside);
      expect(cubit.state.nearestOffice?.name, 'ONE Network');
      expect(cubit.state.distanceToEdgeM, greaterThan(3000));
    });

    test('GPS error near the edge counts in the employee\'s favour', () async {
      await cubit.start();
      // 215 m from the centre: 15 m outside, within 20 m accuracy.
      location.positions$.add(
        _at(33.5892 + 215 / 110574, 73.0465, accuracy: 20),
      );
      await settle();
      expect(cubit.state.presence, Presence.inside);
    });

    test('a fake GPS location places no one and is reported', () async {
      await cubit.start();
      location.positions$.add(_at(33.5887359, 73.0466856));
      await settle();
      expect(cubit.state.presence, Presence.inside);
      location.positions$.add(_at(33.5892, 73.0465, mocked: true));
      await settle();
      expect(cubit.state.presence, Presence.unknown);
      expect(cubit.state.spoofed, isTrue);
      // A real fix again clears it.
      location.positions$.add(_at(33.5887359, 73.0466856));
      await settle();
      expect(cubit.state.spoofed, isFalse);
      expect(cubit.state.presence, Presence.inside);
    });

    test('an old remembered fix is followed by a fresh one', () async {
      await cubit.start();
      // The phone first reports where it was ten minutes ago, far away.
      location.fresh = _at(33.5887359, 73.0466856);
      location.positions$.add(
        _at(33.62, 73.06, age: const Duration(minutes: 10)),
      );
      await settle();
      await settle();
      expect(location.fixes, 1);
      expect(cubit.state.presence, Presence.inside);
      expect(cubit.state.isStale(DateTime.now()), isFalse);
      expect(cubit.state.refreshing, isFalse);
    });

    test('the refresh key finds the location afresh', () async {
      await cubit.start();
      location.positions$.add(_at(33.62, 73.06));
      await settle();
      expect(cubit.state.presence, Presence.outside);
      location.fresh = _at(33.5887359, 73.0466856);
      await cubit.refreshLocation();
      expect(cubit.state.presence, Presence.inside);
    });

    test('location off or not allowed is reported', () async {
      location.enabled = false;
      await cubit.start();
      expect(cubit.state.access, LocationAccess.serviceOff);
      location
        ..enabled = true
        ..permission = LocationPermission.deniedForever;
      await cubit.refresh();
      expect(cubit.state.access, LocationAccess.denied);
    });

    test('offline, the offices come from the last response', () async {
      await cubit.start();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final offline = WorkAreaCubit(
        fetch: () async => throw Exception('offline'),
        location: _FakeLocation(),
      );
      await offline.loadOffices();
      expect(offline.state.offices, hasLength(2));
      expect(offline.state.officesError, isNull);
      await offline.close();
    });
  });
}
