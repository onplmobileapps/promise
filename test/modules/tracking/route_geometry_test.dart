import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

/// The nearest point of [points] to [p] by looking at every segment, as
/// [RoutePath.locate] did before it skipped the far ones.
(int, double) _plainNearest(List<LatLng> points, LatLng p) {
  const mPerDegLat = 110574.0;
  final mPerDegLng = 111320.0 * math.cos(p.latitude * math.pi / 180);
  var best = -1;
  var bestOffset = double.infinity;
  for (var i = 0; i + 1 < points.length; i++) {
    final a = points[i];
    final b = points[i + 1];
    final ax = (a.longitude - p.longitude) * mPerDegLng;
    final ay = (a.latitude - p.latitude) * mPerDegLat;
    final dx = (b.longitude - p.longitude) * mPerDegLng - ax;
    final dy = (b.latitude - p.latitude) * mPerDegLat - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0
        ? 0.0
        : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0).toDouble();
    final offset = math.sqrt(
      math.pow(ax + dx * t, 2) + math.pow(ay + dy * t, 2),
    );
    if (offset < bestOffset) {
      bestOffset = offset;
      best = i;
    }
  }
  return (best, bestOffset);
}

void main() {
  test('finds the same nearest point as looking at every segment', () {
    final random = math.Random(7);
    // A winding line of a few thousand points, as a long route is.
    final points = <LatLng>[];
    var lat = 24.8, lng = 67.0, heading = 0.6;
    for (var i = 0; i < 4000; i++) {
      heading += (random.nextDouble() - 0.5) * 0.3;
      lat += math.cos(heading) * 0.002;
      lng += math.sin(heading) * 0.002;
      points.add(LatLng(lat, lng));
    }
    final path = RoutePath(points);
    for (var k = 0; k < 300; k++) {
      final near = points[random.nextInt(points.length)];
      final p = LatLng(
        near.latitude + (random.nextDouble() - 0.5) * 0.2,
        near.longitude + (random.nextDouble() - 0.5) * 0.2,
      );
      final (segment, offset) = _plainNearest(points, p);
      final fix = path.locate(p)!;
      expect(fix.segment, segment);
      expect(fix.offsetM, closeTo(offset, 1e-6));
    }
  });

  test('takes the earlier of two equally near stretches', () {
    // Out and back along the same track, as a train reversing does.
    final out = [for (var i = 0; i < 100; i++) LatLng(30, 70 + i * 0.001)];
    final path = RoutePath([...out, ...out.reversed.skip(1)]);
    final fix = path.locate(const LatLng(30.0001, 70.0505))!;
    expect(fix.segment, lessThan(99));
  });
}
