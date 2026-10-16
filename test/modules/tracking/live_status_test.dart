import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';

void main() {
  const train = LiveTrain(
    id: '1',
    name: 'Tezgam',
    number: 7,
    direction: 1,
    deviceId: 2553,
  );
  final now = DateTime(2026, 10, 1, 21);

  TrainLiveStatus statusOf(
    LinkState? link, {
    Duration? openFor,
    TrainPosition? position,
  }) => liveStatusOf(
    train,
    position,
    link,
    now: now,
    palette: TrackPalette.light,
    listeningSince: openFor == null ? null : now.subtract(openFor),
  ).kind;

  test('a device is silent only after its socket has been open a while', () {
    expect(statusOf(LinkState.connecting), TrainLiveStatus.connecting);
    expect(
      statusOf(LinkState.open, openFor: const Duration(seconds: 20)),
      TrainLiveStatus.waiting,
    );
    expect(
      statusOf(
        LinkState.open,
        openFor: kSilentAfter + const Duration(seconds: 1),
      ),
      TrainLiveStatus.silent,
    );
    // A reconnect keeps counting from when the socket first opened.
    expect(
      statusOf(LinkState.retrying, openFor: const Duration(minutes: 5)),
      TrainLiveStatus.silent,
    );
  });

  test('a report ends the silence', () {
    final position = TrainPosition(
      deviceId: 2553,
      position: const LatLng(24.86, 67.0),
      speedKmh: 60,
      course: 30,
      moving: true,
      validFix: true,
      fixTime: now.subtract(const Duration(seconds: 8)),
    );
    expect(
      statusOf(
        LinkState.open,
        openFor: const Duration(minutes: 5),
        position: position,
      ),
      TrainLiveStatus.moving,
    );
  });

  group('an old report', () {
    TrainPosition reportAgo(Duration age, {bool moving = false}) =>
        TrainPosition(
          deviceId: 2553,
          position: const LatLng(24.86, 67.0),
          speedKmh: moving ? 60 : 0,
          course: 30,
          moving: moving,
          validFix: true,
          fixTime: now.subtract(age),
        );

    LiveStatus status(
      TrainPosition position,
      LinkState link, {
      required Duration reopened,
    }) => liveStatusOf(
      train,
      position,
      link,
      now: now,
      palette: TrackPalette.light,
      listeningSince: now.subtract(const Duration(hours: 1)),
      openedAt: now.subtract(reopened),
    );

    test('is offline once the device has had time to report again', () {
      final s = status(
        reportAgo(const Duration(hours: 6)),
        LinkState.open,
        reopened: kConfirmOfflineAfter + const Duration(seconds: 1),
      );
      expect(s.kind, TrainLiveStatus.stale);
      expect(s.label, 'Offline');
    });

    test('just after the feed reconnects is still being updated', () {
      // The server's own last report, kept for hours, comes first.
      final s = status(
        reportAgo(const Duration(hours: 6)),
        LinkState.open,
        reopened: const Duration(seconds: 20),
      );
      expect(s.kind, TrainLiveStatus.waiting);
      expect(s.label, 'Updating…');
    });

    test('with the phone out of touch says so, not that the train is '
        'offline', () {
      final s = status(
        reportAgo(const Duration(minutes: 30)),
        LinkState.retrying,
        reopened: const Duration(minutes: 20),
      );
      expect(s.kind, TrainLiveStatus.connecting);
      expect(s.label, 'Reconnecting…');
    });

    test('of a moving train lasts the gaps between its reports', () {
      // Two and a half minutes between reports has been seen.
      final s = status(
        reportAgo(const Duration(seconds: 160), moving: true),
        LinkState.open,
        reopened: const Duration(minutes: 20),
      );
      expect(s.kind, TrainLiveStatus.moving);
    });
  });

  test('tracking has its own colours in dark mode', () {
    expect(TrackPalette.dark.isDark, isTrue);
    expect(TrackPalette.light.isDark, isFalse);
    expect(TrackPalette.dark.card, isNot(TrackPalette.light.card));
    expect(TrackPalette.dark.ink, isNot(TrackPalette.light.ink));
    expect(mapHex(const Color(0xFF2F9A72)), '#2F9A72');
  });
}
