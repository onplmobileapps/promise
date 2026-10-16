import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/widgets/station_strip.dart';

RouteStop _stop(String name, double km, {String? due}) => RouteStop(
  TrainStation(name: name, arrivalTime: due),
  km,
  scheduled: due != null,
);

TrainPosition _at(DateTime time, {double kmh = 60}) => TrainPosition(
  deviceId: 1,
  position: const LatLng(30, 70),
  speedKmh: kmh,
  course: 90,
  moving: kmh >= 3,
  validFix: true,
  fixTime: time,
);

void main() {
  final t0 = DateTime(2026, 10, 11, 12);

  test('places timetable times past midnight on the next day', () {
    final day = DateTime(2026, 10, 10);
    final first = scheduledAt(_stop('A', 0, due: '22:15:00'), day)!;
    final second = scheduledAt(
      _stop('B', 100, due: '01:40:00'),
      day,
      after: first,
    )!;
    expect(first, DateTime(2026, 10, 10, 22, 15));
    expect(second, DateTime(2026, 10, 11, 1, 40));
    expect(scheduledAt(_stop('C', 0), day), isNull);
  });

  testWidgets('shows each station\'s timetable times as the API gives them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final stops = [
      _stop('Karachi', 0, due: '11:00:00'),
      _stop('Landhi', 20, due: '11:15:00'),
      _stop('Jungshahi', 60, due: '12:10:00'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StationStrip(
            stops: stops,
            coveredKm: 30,
            position: _at(t0),
            runDate: DateTime(2026, 10, 11),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // The timetable's own times, not estimates of the app's.
    expect(find.textContaining('11:15 AM'), findsOneWidget);
    expect(find.textContaining('12:10 PM'), findsOneWidget);
    expect(find.textContaining('Delay'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
