import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';

void main() {
  // A route running east along 30° N.
  final path = RoutePath(const [
    LatLng(30, 70),
    LatLng(30, 70.5),
    LatLng(30, 71),
  ]);
  const origin = TrainStation(id: 1, name: 'Origin', position: LatLng(30, 70));
  const destination = TrainStation(
    id: 2,
    name: 'Terminus',
    position: LatLng(30, 71),
  );
  double kmTo(double lng) =>
      haversineMeters(const LatLng(30, 70), LatLng(30, lng)) / 1000;

  test(
    'lists only the journey\'s own stations, at their place on the route',
    () {
      final stops = stopsAlong(path, const [
        origin,
        TrainStation(id: 3, name: 'Halfway Halt', position: LatLng(30, 70.5)),
        // Its coordinates are unknown: it keeps the distance before it.
        TrainStation(id: 4, name: 'Unplaced'),
        destination,
      ]);
      expect(stops.map((s) => s.station.name), [
        'Origin',
        'Halfway Halt',
        'Unplaced',
        'Terminus',
      ]);
      expect(stops.every((s) => s.scheduled), isTrue);
      expect(stops[1].km, closeTo(kmTo(70.5), 0.5));
      expect(stops[2].km, stops[1].km);
      expect(stops.last.km, closeTo(kmTo(71), 0.5));
    },
  );

  test('finds the next stop ahead of the train', () {
    final stops = [
      const RouteStop(origin, 0, scheduled: true),
      const RouteStop(TrainStation(name: 'A'), 24),
      const RouteStop(TrainStation(name: 'B'), 72),
      const RouteStop(destination, 96, scheduled: true),
    ];
    expect(nextStopIndex(stops, 0), 1);
    expect(nextStopIndex(stops, 30), 2);
    // Almost at A counts as there.
    expect(nextStopIndex(stops, 23.8), 2);
    expect(nextStopIndex(stops, 96), isNull);
  });
}
