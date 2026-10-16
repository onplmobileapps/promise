import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

/// A position in the proxy socket's own form (Traccar).
Map<String, Object?> _report(
  int device, {
  required String fix,
  String? server,
  double lat = 29.2,
  double knots = 20,
  bool motion = true,
}) => {
  'id': device * 1000,
  'deviceId': device,
  'attributes': {'motion': motion, 'deviceStatus': 'online'},
  'serverTime': server ?? fix,
  'deviceTime': fix,
  'fixTime': fix,
  'outdated': false,
  'valid': true,
  'latitude': lat,
  'longitude': 67.9,
  'speed': knots,
  'course': 162.0,
  'address': 'Dhadar Tehsil, Kachhi District, Balochistan',
};

String _message(List<Map<String, Object?>> reports) =>
    jsonEncode({'positions': reports});

void main() {
  test('only watched devices\' reports come through, each once', () {
    final reports = ProxyReports()..watch({2562});
    final first = reports.read(
      _message([
        _report(2562, fix: '2026-10-16T09:55:02Z'),
        // Not a train being shown.
        _report(2723, fix: '2026-10-16T09:55:03Z'),
      ]),
    );
    expect(first.map((r) => r.deviceId), [2562]);
    expect(first.single.speedKmh, closeTo(37.04, 0.01));

    // The proxy sends the same report again: it isn't passed on twice.
    expect(
      reports.read(_message([_report(2562, fix: '2026-10-16T09:55:02Z')])),
      isEmpty,
    );
    // An older one, as after a reconnect, isn't either.
    expect(
      reports.read(_message([_report(2562, fix: '2026-10-16T09:54:50Z')])),
      isEmpty,
    );
    final next = reports.read(
      _message([_report(2562, fix: '2026-10-16T09:55:12Z', lat: 29.21)]),
    );
    expect(next.single.position.latitude, 29.21);
  });

  test('a device watched later gets its last known report at once', () {
    final reports = ProxyReports()..watch(const {});
    reports.read(_message([_report(2641, fix: '2026-10-16T09:50:00Z')]));
    final known = reports.watch({2641});
    expect(known.map((r) => r.deviceId), [2641]);
    // Already passed on: not again.
    expect(reports.watch({2641}), isEmpty);
  });

  test('a device whose clock runs ahead is timed by the server', () {
    final reports = ProxyReports()..watch({2525});
    final report = reports
        .read(
          _message([
            _report(
              2525,
              fix: '2026-10-18T08:00:00Z',
              server: '2026-10-16T09:55:00Z',
            ),
          ]),
        )
        .single;
    expect(report.fixTime.toUtc(), DateTime.utc(2026, 10, 16, 9, 55));
  });

  test('messages it can\'t read are let go', () {
    final reports = ProxyReports()..watch({1});
    expect(reports.read('not json'), isEmpty);
    expect(reports.read(jsonEncode({'events': []})), isEmpty);
  });
}
