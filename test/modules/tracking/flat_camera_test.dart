import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/widgets/map_layers.dart';

/// Where [point] shows on a flat, north-up map [size] across, looking at
/// [camera] with content [insets].
Offset _onScreen(
  LatLng point,
  CameraPosition camera,
  Size size,
  EdgeInsets insets,
) {
  double x(double lng) => (lng + 180) / 360;
  double y(double lat) {
    final s = math.sin(lat * math.pi / 180);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  final scale = 512 * math.pow(2, camera.zoom);
  final middle = Offset(
    insets.left + (size.width - insets.horizontal) / 2,
    insets.top + (size.height - insets.vertical) / 2,
  );
  return middle +
      Offset(
        (x(point.longitude) - x(camera.target.longitude)) * scale,
        (y(point.latitude) - y(camera.target.latitude)) * scale,
      );
}

void main() {
  const size = Size(411, 891);

  void expectFits(
    LatLngBounds bounds, {
    EdgeInsets insets = EdgeInsets.zero,
    required EdgeInsets padding,
  }) {
    final camera = flatCameraFor(
      bounds,
      size: size,
      insets: insets,
      padding: padding,
    );
    expect(camera.tilt, 0);
    expect(camera.bearing, 0);
    final sw = _onScreen(bounds.southwest, camera, size, insets);
    final ne = _onScreen(bounds.northeast, camera, size, insets);
    final left = insets.left + padding.left;
    final right = size.width - insets.right - padding.right;
    final top = insets.top + padding.top;
    final bottom = size.height - insets.bottom - padding.bottom;
    expect(sw.dx, greaterThanOrEqualTo(left - 0.5));
    expect(ne.dx, lessThanOrEqualTo(right + 0.5));
    expect(ne.dy, greaterThanOrEqualTo(top - 0.5));
    expect(sw.dy, lessThanOrEqualTo(bottom + 0.5));
    // As close as fits: filling the width or the height.
    final fillsWidth =
        (sw.dx - left).abs() < 0.5 && (ne.dx - right).abs() < 0.5;
    final fillsHeight =
        (ne.dy - top).abs() < 0.5 && (sw.dy - bottom).abs() < 0.5;
    expect(fillsWidth || fillsHeight, isTrue);
  }

  test('frames a whole journey between the bar and the sheet', () {
    // Khyber Mail, Karachi to Peshawar.
    expectFits(
      LatLngBounds(
        southwest: const LatLng(24.84, 67.04),
        northeast: const LatLng(34.0, 71.55),
      ),
      insets: const EdgeInsets.only(top: 112, bottom: 310),
      padding: const EdgeInsets.fromLTRB(48, 24, 72, 24),
    );
  });

  test('frames a wide stretch by its width', () {
    expectFits(
      LatLngBounds(
        southwest: const LatLng(30.0, 66.0),
        northeast: const LatLng(30.5, 74.0),
      ),
      padding: const EdgeInsets.fromLTRB(16, 200, 16, 180),
    );
  });

  test('comes no closer than its zoom limit', () {
    final camera = flatCameraFor(
      LatLngBounds(
        southwest: const LatLng(31.5800, 74.3400),
        northeast: const LatLng(31.5801, 74.3401),
      ),
      size: size,
      maxZoom: 12,
    );
    expect(camera.zoom, 12);
    expect(camera.target.latitude, closeTo(31.58005, 1e-4));
    expect(camera.target.longitude, closeTo(74.34005, 1e-4));
  });
}
