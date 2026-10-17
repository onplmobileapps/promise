import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_3d.dart';

/// Every ring of every box in [collection], with the feature it is in.
Iterable<(Map<dynamic, dynamic>, List<dynamic>)> _rings(
  Map<String, dynamic> collection,
) sync* {
  for (final feature in collection['features'] as List) {
    final geometry = (feature as Map)['geometry'] as Map;
    expect(geometry['type'], 'MultiPolygon');
    for (final polygon in geometry['coordinates'] as List) {
      yield (feature, (polygon as List).first as List);
    }
  }
}

void main() {
  test('stands the train up behind its head, along its route', () {
    // A route heading east, the train 5 km along it.
    final path = RoutePath(const [LatLng(30, 70), LatLng(30, 70.1)]);
    final head = path.fixAt(5000).snapped;
    final train = train3dCollection(
      head: head,
      heading: 90,
      metersPerPx: 2,
      path: path,
      headAlong: 5000,
      coaches: 2,
    );

    final longitudes = <double>[];
    var boxes = 0;
    for (final (feature, ring) in _rings(train)) {
      boxes++;
      final properties = feature['properties'] as Map;
      expect(
        properties['base'] as double,
        lessThan(properties['height'] as double),
      );
      expect(ring, hasLength(5));
      expect(ring.first, ring.last);
      for (final point in ring) {
        final [lng, lat] = point as List<double>;
        longitudes.add(lng);
        expect(lat, closeTo(30, 0.001));
      }
    }
    // Detailed, but every box of one look on every car is one feature.
    expect(boxes, greaterThan(30));
    expect(train['features'] as List, hasLength(lessThan(20)));

    // Nothing ahead of the head; the tail 46 + 2 × 50 + 2 × 3 px back.
    expect(
      longitudes.reduce(math.max),
      lessThanOrEqualTo(head.longitude + 1e-7),
    );
    final tailM =
        (head.longitude - longitudes.reduce(math.min)) *
        111320 *
        math.cos(30 * math.pi / 180);
    expect(tailM, closeTo(152 * 2, 3));
  });

  test('draws a fleet in as few features as one train', () {
    final scene = Train3dScene(metersPerPx: 2, detail: Train3dDetail.low);
    for (var i = 0; i < 40; i++) {
      scene.add(head: LatLng(30, 70 + i * 0.01), heading: 90);
    }
    final fleet = scene.toGeoJson();
    final one = train3dCollection(
      head: const LatLng(30, 70),
      heading: 90,
      metersPerPx: 2,
      detail: Train3dDetail.low,
    );
    expect(
      (fleet['features'] as List).length,
      (one['features'] as List).length,
    );
    expect(_rings(fleet).length, 40 * _rings(one).length);
    // Fewer boxes than the full train.
    final full = train3dCollection(
      head: const LatLng(30, 70),
      heading: 90,
      metersPerPx: 2,
    );
    expect(_rings(one).length, lessThan(_rings(full).length));
  });

  test('sizes the train for the zoom', () {
    expect(metersPerPixel(15, 0), closeTo(2.39, 0.01));
    expect(metersPerPixel(16, 60), closeTo(metersPerPixel(15, 60) / 2, 1e-9));
  });
}
