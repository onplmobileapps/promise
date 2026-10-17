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

  test('the proxy\'s device list says, as it is, whether a device is '
      'online', () {
    final reports = ProxyReports()..watch({2562});
    final report = _report(2562, fix: '2026-10-16T09:55:02Z');
    (report['attributes']! as Map<String, Object?>).remove('deviceStatus');
    final first = reports.read(_message([report]));
    // Nothing said yet.
    expect(first.single.online, isNull);

    final offline = reports.read(
      jsonEncode({
        'devices': [
          {'id': 2562, 'status': 'offline'},
          {'id': 2723, 'status': 'online'},
        ],
      }),
    );
    // The same report, now offline.
    expect(offline.single.online, isFalse);
    expect(offline.single.fixTime, first.single.fixTime);

    // Said again: nothing new.
    expect(
      reports.read(
        jsonEncode({
          'devices': [
            {'id': 2562, 'status': 'offline'},
          ],
        }),
      ),
      isEmpty,
    );

    // A new report carries the device's last status.
    (report['attributes']! as Map<String, Object?>).remove('deviceStatus');
    report['fixTime'] = '2026-10-16T09:55:20Z';
    report['serverTime'] = '2026-10-16T09:55:20Z';
    expect(reports.read(_message([report])).single.online, isFalse);
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

  testWidgets('a whole fleet is watched and let go of in one change each', (
    tester,
  ) async {
    final changes = <(List<int>, LinkState?)>[];
    final feed = TrainProxyFeed(
      onPosition: (_) {},
      onLinkChanged: (ids, link) => changes.add((ids.toList(), link)),
    );
    for (var id = 1; id <= 300; id++) {
      feed.watch(id);
    }
    await tester.pump();
    expect(changes, hasLength(1));
    expect(changes.single.$1, hasLength(300));
    expect(changes.single.$2, LinkState.connecting);

    // Let go of over a moment, as a list scrolling away does.
    for (var id = 1; id <= 300; id++) {
      feed.unwatch(id);
      if (id == 150) await tester.pump(const Duration(milliseconds: 500));
    }
    // One comes back before its linger runs out.
    feed.watch(42);
    await tester.pump(const Duration(seconds: 19));
    expect(changes, hasLength(1));
    await tester.pump(const Duration(seconds: 2));
    expect(changes, hasLength(2));
    expect(changes.last.$2, isNull);
    expect(changes.last.$1, hasLength(299));
    expect(changes.last.$1, isNot(contains(42)));
    feed.dispose();
  });
}
