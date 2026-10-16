import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_3d.dart';

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
    final boxes = train['features'] as List;
    // A locomotive of 9 boxes and coaches of 7.
    expect(boxes, hasLength(9 + 2 * 7));

    final longitudes = <double>[];
    for (final box in boxes) {
      final properties = (box as Map)['properties'] as Map;
      expect(
        properties['base'] as double,
        lessThan(properties['height'] as double),
      );
      final ring =
          ((box['geometry'] as Map)['coordinates'] as List).first as List;
      for (final point in ring) {
        final [lng, lat] = point as List<double>;
        longitudes.add(lng);
        expect(lat, closeTo(30, 0.001));
      }
    }
    // Nothing ahead of the head; the tail 46 + 2 × 50 + 2 × 3 px back.
    expect(
      longitudes.reduce(math.max),
      lessThanOrEqualTo(head.longitude + 1e-9),
    );
    final tailM =
        (head.longitude - longitudes.reduce(math.min)) *
        111320 *
        math.cos(30 * math.pi / 180);
    expect(tailM, closeTo(152 * 2, 3));
  });

  test('sizes the train for the zoom', () {
    expect(metersPerPixel(15, 0), closeTo(2.39, 0.01));
    expect(metersPerPixel(16, 60), closeTo(metersPerPixel(15, 60) / 2, 1e-9));
  });
}
