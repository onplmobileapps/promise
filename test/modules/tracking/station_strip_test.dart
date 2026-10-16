import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/widgets/station_strip.dart';

const _stops = [
  RouteStop(TrainStation(name: 'Karachi Cantt'), 0, scheduled: true),
  RouteStop(TrainStation(name: 'Landhi Jn'), 24),
  RouteStop(TrainStation(name: 'Jungshahi'), 72),
  RouteStop(TrainStation(name: 'Kotri Jn'), 140),
  RouteStop(TrainStation(name: 'Hyderabad Jn'), 160, scheduled: true),
];

TrainPosition _position({required double kmh, Duration? stoppedFor}) =>
    TrainPosition(
      deviceId: 1,
      position: const LatLng(25, 67.5),
      speedKmh: kmh,
      course: 60,
      moving: kmh >= 3,
      validFix: true,
      fixTime: DateTime.now(),
      stoppedFor: stoppedFor,
    );

Future<void> _pump(
  WidgetTester tester, {
  double? coveredKm,
  TrainPosition? position,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StationStrip(
            stops: _stops,
            coveredKm: coveredKm,
            position: position,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('calls out the next station with its distance', (tester) async {
    await _pump(tester, coveredKm: 30, position: _position(kmh: 84));
    expect(tester.takeException(), isNull);
    expect(find.text('NEXT STATION'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('42 km away · after Landhi Jn'), findsOneWidget);
    // No arrival guessed by the app.
    expect(find.textContaining('expected at'), findsNothing);
    expect(find.text('Passed'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('says a train standing between stations has stopped', (
    tester,
  ) async {
    await _pump(tester, coveredKm: 30, position: _position(kmh: 0));
    expect(tester.takeException(), isNull);
    expect(
      find.text('42 km away · train stopped · after Landhi Jn'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('says where a standing train is', (tester) async {
    await _pump(
      tester,
      coveredKm: 71.5,
      position: _position(kmh: 0, stoppedFor: const Duration(minutes: 12)),
    );
    expect(find.text('STOPPED AT'), findsOneWidget);
    expect(find.text('HERE'), findsOneWidget);
    expect(find.text('Standing for 12 min · Next: Kotri Jn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('lists the stations by distance while the train is unknown', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('NEXT STATION'), findsNothing);
    expect(find.text('FROM'), findsOneWidget);
    expect(find.text('24 km'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fits large text', (tester) async {
    await _pump(
      tester,
      coveredKm: 30,
      position: _position(kmh: 84),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
