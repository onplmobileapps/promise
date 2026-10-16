import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

/// Pakistan as on its official map, Gilgit-Baltistan, Azad Kashmir and
/// Jammu & Kashmir included, from `assets/pk_outline.json`: its provinces
/// and territories merged into one simplified ring, with the borders
/// between them and a place for each one's name.
class PakistanOutline {
  PakistanOutline._(this.ring, this.borders, this.labels);

  static const String _asset = 'assets/pk_outline.json';
  static Future<PakistanOutline>? _loading;

  /// Counter-clockwise, first point repeated at the end.
  final List<LatLng> ring;

  /// Borders between provinces and territories.
  final List<List<LatLng>> borders;

  /// Province and territory names, where to write them.
  final List<(String, LatLng)> labels;

  /// The outline once it has loaded, for drawing without waiting.
  static PakistanOutline? loaded;

  static Future<PakistanOutline> load() => _loading ??= rootBundle
      .loadString(_asset)
      .then((json) => loaded = parse(json))
      .catchError((Object e) {
        _loading = null;
        throw e;
      });

  static LatLng _point(Object? p) =>
      LatLng(((p as List)[1] as num).toDouble(), (p[0] as num).toDouble());

  /// Reads the asset's FeatureCollection: an `outline` Polygon (outer ring
  /// only), a `borders` MultiLineString and `label` Points with a `name`.
  static PakistanOutline parse(String json) {
    final collection = jsonDecode(json) as Map<String, dynamic>;
    var ring = <LatLng>[];
    final borders = <List<LatLng>>[];
    final labels = <(String, LatLng)>[];
    for (final feature in collection['features'] as List) {
      final properties = (feature as Map)['properties'] as Map;
      final coordinates = (feature['geometry'] as Map)['coordinates'] as List;
      switch (properties['kind']) {
        case 'outline':
          ring = [for (final p in coordinates.first as List) _point(p)];
        case 'borders':
          borders.addAll([
            for (final line in coordinates)
              [for (final p in line as List) _point(p)],
          ]);
        case 'label':
          labels.add((properties['name'] as String, _point(coordinates)));
      }
    }
    return PakistanOutline._(ring, borders, labels);
  }

  late final LatLngBounds bounds = _bounds();

  LatLngBounds _bounds() {
    var south = ring.first.latitude, north = south;
    var west = ring.first.longitude, east = west;
    for (final p in ring) {
      if (p.latitude < south) south = p.latitude;
      if (p.latitude > north) north = p.latitude;
      if (p.longitude < west) west = p.longitude;
      if (p.longitude > east) east = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  bool contains(LatLng point) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i];
      final b = ring[j];
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
          point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }

  List<List<double>> _coordinates(Iterable<LatLng> points) => [
    for (final p in points) [p.longitude, p.latitude],
  ];

  Map<String, dynamic> get outlineGeoJson => {
    'type': 'Feature',
    'properties': <String, dynamic>{},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [_coordinates(ring)],
    },
  };

  /// The world with Pakistan cut out, for dimming everything else. The hole
  /// winds the other way from the outer ring, as MapLibre expects.
  Map<String, dynamic> get maskGeoJson => {
    'type': 'Feature',
    'properties': <String, dynamic>{},
    'geometry': {
      'type': 'Polygon',
      'coordinates': [
        [
          [-180.0, -85.0],
          [180.0, -85.0],
          [180.0, 85.0],
          [-180.0, 85.0],
          [-180.0, -85.0],
        ],
        _coordinates(ring.reversed),
      ],
    },
  };

  Map<String, dynamic> get bordersGeoJson => {
    'type': 'Feature',
    'properties': <String, dynamic>{},
    'geometry': {
      'type': 'MultiLineString',
      'coordinates': [for (final line in borders) _coordinates(line)],
    },
  };

  Map<String, dynamic> get labelsGeoJson => {
    'type': 'FeatureCollection',
    'features': [
      for (final (name, at) in labels)
        {
          'type': 'Feature',
          'properties': {'name': name},
          'geometry': {
            'type': 'Point',
            'coordinates': [at.longitude, at.latitude],
          },
        },
    ],
  };
}
