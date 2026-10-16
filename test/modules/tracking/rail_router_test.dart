import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/rail_router.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

// Station coordinates as the tracking API returns them.
const _rawalpindi = LatLng(33.60, 73.05);
const _lahore = LatLng(31.58, 74.34);
const _karachiCantt = LatLng(24.84, 67.04);
const _peshawarCantt = LatLng(34.00, 71.55);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<double> railKm(List<LatLng> waypoints) async {
    final route = await RailRouter.instance.route(waypoints);
    expect(route, isNotNull);
    return RoutePath(route!).lengthM / 1000;
  }

  test('Rawalpindi to Lahore follows ML-1 across the Lala Musa gap', () async {
    // The track data is missing 3.4 km between Lala Musa and Gujrat; without
    // bridging, this route is a 729 km detour.
    expect(await railKm([_rawalpindi, _lahore]), inInclusiveRange(280, 305));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Lahore to Karachi', () async {
    expect(
      await railKm([_lahore, _karachiCantt]),
      inInclusiveRange(1190, 1250),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a waypoint pulls the route through it', () async {
    // Shortest Peshawar → Karachi path skips Lahore; through Lahore it is the
    // ML-1 route the mail trains take.
    final direct = await railKm([_peshawarCantt, _karachiCantt]);
    final viaLahore = await railKm([_peshawarCantt, _lahore, _karachiCantt]);
    expect(viaLahore, greaterThan(direct));
    expect(viaLahore, inInclusiveRange(1600, 1760));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('runs on through a waypoint rather than turning back', () async {
    // Khyber Mail past Sher Shah, on its way into Multan — on the line, and
    // reported off in the yard: the shortest way on to Peshawar is back
    // through Sher Shah and up the Kot Addu line, but the train goes on
    // through Multan and Khanewal.
    const pastSherShah = LatLng(30.1587, 71.4033);
    const multanYard = LatLng(30.18, 71.45);
    const khanewal = LatLng(30.30, 71.93);
    const kotAddu = LatLng(30.47, 70.97);
    for (final at in [pastSherShah, multanYard]) {
      final route = await RailRouter.instance.route([
        _karachiCantt,
        at,
        _peshawarCantt,
      ]);
      expect(route, isNotNull);
      double nearestKm(LatLng to) =>
          route!.map((p) => haversineMeters(p, to)).reduce(math.min) / 1000;
      expect(nearestKm(khanewal), lessThan(3), reason: '$at');
      expect(nearestKm(kotAddu), greaterThan(20), reason: '$at');
      expect(
        RoutePath(route!).lengthM / 1000,
        inInclusiveRange(1640, 1760),
        reason: '$at',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('draws the network as simplified runs of track', () async {
    final lines = await RailRouter.instance.network();
    expect(lines, isNotNull);
    final points = lines!.fold<int>(0, (n, line) => n + line.length);
    // The data has 54,392 points.
    expect(points, inInclusiveRange(15000, 40000));
    expect(lines.every((line) => line.length >= 2), isTrue);
    expect(
      lines.any((line) => line.any((p) => haversineMeters(p, _lahore) < 2000)),
      isTrue,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('locates a point along the route', () {
    final path = RoutePath(const [LatLng(30, 70), LatLng(30, 71)]);
    final fix = path.locate(const LatLng(30.01, 70.5))!;
    expect(fix.alongM / path.lengthM, closeTo(0.5, 0.01));
    expect(fix.offsetM, closeTo(1105, 15));
  });

  test('walks a distance along the route and reads its bearing', () {
    // East, then north.
    final path = RoutePath(const [
      LatLng(30, 70),
      LatLng(30, 70.1),
      LatLng(30.1, 70.1),
    ]);
    final firstLeg = haversineMeters(
      const LatLng(30, 70),
      const LatLng(30, 70.1),
    );
    final mid = path.fixAt(firstLeg / 2).snapped;
    expect(mid.latitude, closeTo(30, 1e-9));
    expect(mid.longitude, closeTo(70.05, 1e-6));
    expect(path.bearingAt(firstLeg / 2), closeTo(90, 1));
    expect(path.bearingAt(firstLeg + 2000), closeTo(0, 1));
    expect(path.fixAt(-50).snapped, const LatLng(30, 70));
    expect(path.fixAt(1e9).snapped, const LatLng(30.1, 70.1));
  });
}
