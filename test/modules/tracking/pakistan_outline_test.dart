import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/services/pakistan_outline.dart';

double _signedArea(List ring) {
  var area = 0.0;
  for (var i = 0; i + 1 < ring.length; i++) {
    final a = ring[i] as List;
    final b = ring[i + 1] as List;
    area += (a[0] as num) * (b[1] as num) - (b[0] as num) * (a[1] as num);
  }
  return area / 2;
}

void main() {
  final outline = PakistanOutline.parse(
    File('assets/pk_outline.json').readAsStringSync(),
  );

  test('includes Gilgit-Baltistan, Azad Kashmir and Jammu & Kashmir', () {
    for (final (name, point) in const [
      ('Gilgit', LatLng(35.9208, 74.3080)),
      ('Srinagar', LatLng(34.0837, 74.7973)),
      ('Jammu', LatLng(32.7266, 74.8570)),
      ('Leh', LatLng(34.1526, 77.5771)),
      ('Skardu', LatLng(35.2971, 75.6333)),
      ('Khunjerab Pass', LatLng(36.85, 75.42)),
      ('Muzaffarabad', LatLng(34.37, 73.47)),
      ('Lahore', LatLng(31.5204, 74.3587)),
      ('Karachi', LatLng(24.8607, 67.0011)),
      ('Gwadar', LatLng(25.12, 62.32)),
    ]) {
      expect(outline.contains(point), isTrue, reason: name);
    }
  });

  test('leaves out its neighbours', () {
    for (final (name, point) in const [
      ('Amritsar', LatLng(31.63, 74.87)),
      ('Delhi', LatLng(28.61, 77.21)),
      ('Kabul', LatLng(34.53, 69.17)),
      ('Zahedan', LatLng(29.49, 60.86)),
    ]) {
      expect(outline.contains(point), isFalse, reason: name);
    }
  });

  test('names each province inside the map, with borders between them', () {
    expect(
      outline.labels.map((l) => l.$1),
      containsAll(['Punjab', 'Sindh', 'Gilgit-Baltistan', 'Azad Kashmir']),
    );
    for (final (name, at) in outline.labels) {
      expect(outline.contains(at), isTrue, reason: name);
    }
    expect(outline.borders, isNotEmpty);
  });

  test('cuts Pakistan out of the dimmed world', () {
    final geometry = outline.maskGeoJson['geometry'] as Map;
    final rings = geometry['coordinates'] as List;
    expect(rings, hasLength(2));
    // MapLibre tells a hole by its winding: opposite to the outer ring.
    expect(_signedArea(rings[0] as List), greaterThan(0));
    expect(_signedArea(rings[1] as List), lessThan(0));
  });
}
