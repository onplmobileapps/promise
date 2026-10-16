import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/track_history_store.dart';

void main() {
  late Directory folder;
  late TrackHistoryStore store;
  final now = DateTime(2026, 10, 11, 13);

  setUp(() {
    folder = Directory.systemTemp.createTempSync('history');
    store = TrackHistoryStore(directory: () async => folder);
  });
  tearDown(() => folder.deleteSync(recursive: true));

  test('keeps the day\'s reports between visits', () async {
    await store.save({
      2719: [
        (now.subtract(const Duration(hours: 2)), const LatLng(28.42, 70.30)),
        (now.subtract(const Duration(hours: 1)), const LatLng(28.55, 70.45)),
      ],
      2634: [(now, const LatLng(31.09, 73.97))],
    }, now: now);
    final kept = await store.load(now: now);
    expect(kept.keys.toSet(), {2719, 2634});
    expect(kept[2719]!.map((f) => f.$2), const [
      LatLng(28.42, 70.30),
      LatLng(28.55, 70.45),
    ]);
    expect(kept[2634]!.single.$1, now);
  });

  test('drops reports older than a day and a bit', () async {
    await store.save({
      1: [(now.subtract(const Duration(hours: 40)), const LatLng(30, 70))],
      2: [
        (now.subtract(const Duration(hours: 40)), const LatLng(30, 70)),
        (now.subtract(const Duration(hours: 3)), const LatLng(30, 71)),
      ],
    }, now: now);
    final kept = await store.load(now: now);
    expect(kept.containsKey(1), isFalse);
    expect(kept[2]!.single.$2, const LatLng(30, 71));
  });

  test('a missing or broken file is no history, not an error', () async {
    expect(await store.load(now: now), isEmpty);
    File('${folder.path}/train_history.json').writeAsStringSync('{broken');
    expect(await store.load(now: now), isEmpty);
  });
}
