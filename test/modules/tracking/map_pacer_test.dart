import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/modules/tracking/services/map_pacer.dart';

void main() {
  final t0 = DateTime(2026, 10, 11, 12);

  void feed(MapPacer pacer, int ms, int count, DateTime from) {
    for (var i = 0; i < count; i++) {
      pacer.took(
        Duration(milliseconds: ms),
        now: from.add(Duration(milliseconds: i * 50)),
      );
    }
  }

  test('a phone that keeps up gets every frame, up to 60 a second', () {
    final pacer = MapPacer();
    feed(pacer, 4, 60, t0);
    expect(pacer.tier, MapTier.smooth);
    expect(pacer.gap.inMicroseconds, 16000);
    expect(pacer.draws3d, isTrue);
  });

  test('a slow phone is fed less, then given flat trains', () {
    final pacer = MapPacer();
    feed(pacer, 20, 40, t0);
    expect(pacer.tier, MapTier.steady);
    expect(pacer.gap, const Duration(milliseconds: 33));
    // Slower still, after the tier has had time to settle.
    feed(pacer, 40, 80, t0.add(const Duration(seconds: 5)));
    expect(pacer.tier, MapTier.light);
    expect(pacer.draws3d, isFalse);
  });

  test('steps back up once the phone keeps up again, without flickering', () {
    final pacer = MapPacer(start: MapTier.light);
    feed(pacer, 5, 20, t0);
    // One step at a time, and not twice within a few seconds.
    expect(pacer.tier, MapTier.steady);
    feed(pacer, 5, 20, t0.add(const Duration(seconds: 1)));
    expect(pacer.tier, MapTier.steady);
    feed(pacer, 5, 40, t0.add(const Duration(seconds: 5)));
    expect(pacer.tier, MapTier.smooth);
  });
}
