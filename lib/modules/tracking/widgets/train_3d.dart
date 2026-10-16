import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

/// Metres per logical pixel at [zoom] and [latitude] (MapLibre's 512-px
/// tiles).
double metersPerPixel(double zoom, double latitude) =>
    40075016.686 *
    math.cos(latitude * math.pi / 180) /
    (512 * math.pow(2, zoom));

/// Colours of the 3D train.
class Train3dPalette {
  final String frame;
  final String lowerBody;
  final String band;
  final String body;
  final String coachBody;
  final String glass;
  final String locoRoof;
  final String coachRoof;
  final String lamp;

  const Train3dPalette({
    required this.frame,
    required this.lowerBody,
    required this.band,
    required this.body,
    required this.coachBody,
    required this.glass,
    required this.locoRoof,
    required this.coachRoof,
    required this.lamp,
  });

  /// Pakistan Railways: green with a yellow band.
  static const pakistanRailways = Train3dPalette(
    frame: '#1F2933',
    lowerBody: '#0F5A33',
    band: '#F7C948',
    body: '#167340',
    coachBody: '#1B7A46',
    glass: '#13222E',
    locoRoof: '#2FA36B',
    coachRoof: '#C3CEC8',
    lamp: '#FFF3B0',
  );

  /// For all trains: green palette.
  static const faded = pakistanRailways;
}

/// One box of a car: from [from] to [to] back from the car's front, [width]
/// as a share of the car's, standing from [base] to [top]; all lengths in
/// screen pixels.
typedef _Box = (
  double from,
  double to,
  double width,
  double base,
  double top,
  String color,
);

/// The train as boxes for a fill-extrusion layer: a locomotive and
/// [coaches] behind it. The cars follow [path] back from [headAlong] when
/// the train is on its route, or run straight back from [head] against
/// [heading]. Sizes are in screen pixels turned into metres with
/// [metersPerPx], so the train reads the same at every zoom.
Map<String, dynamic> train3dCollection({
  required LatLng head,
  required double heading,
  required double metersPerPx,
  RoutePath? path,
  double? headAlong,
  bool reversed = false,
  int coaches = 2,
  Train3dPalette palette = Train3dPalette.pakistanRailways,
}) {
  const width = 16.0;
  const locoLength = 46.0;
  const coachLength = 50.0;
  const gap = 3.0;
  final p = palette;

  final loco = <_Box>[
    (3, locoLength - 3, 0.8, 0, 5, p.frame),
    (0, locoLength, 1, 5, 14, p.lowerBody),
    (0, locoLength, 1.02, 14, 17, p.band),
    // Cab at the front: windscreen band between green.
    (0, 8, 1, 17, 18.5, p.body),
    (0, 8, 1.02, 18.5, 22.5, p.glass),
    (0, 8, 1, 22.5, 26, p.body),
    (8, locoLength, 1, 17, 26, p.body),
    (2.6, locoLength - 2, 0.8, 26, 27.5, p.locoRoof),
    (0.3, 2.2, 0.3, 26, 28.5, p.lamp),
  ];
  final coach = <_Box>[
    (3, coachLength - 3, 0.8, 0, 5, p.frame),
    (0, coachLength, 1, 5, 14, p.lowerBody),
    (0, coachLength, 1.02, 14, 17, p.band),
    (0, coachLength, 1, 17, 18.5, p.coachBody),
    (0, coachLength, 1.02, 18.5, 22, p.glass),
    (0, coachLength, 1, 22, 26, p.coachBody),
    (1, coachLength - 1, 0.86, 26, 27.5, p.coachRoof),
  ];

  final features = <Map<String, dynamic>>[];
  var back = 0.0;
  for (var car = 0; car <= coaches; car++) {
    final length = car == 0 ? locoLength : coachLength;
    final boxes = car == 0 ? loco : coach;
    final centerBackM = (back + length / 2) * metersPerPx;
    final (center, bearing) = _placeBehind(
      head,
      heading,
      path,
      headAlong,
      centerBackM,
      reversed: reversed,
    );
    for (final (from, to, share, base, top, color) in boxes) {
      // Along the car, forward from its centre.
      final front = (length / 2 - from) * metersPerPx;
      final rear = (length / 2 - to) * metersPerPx;
      final half = width * share / 2 * metersPerPx;
      features.add({
        'type': 'Feature',
        'properties': {
          'color': color,
          'base': base * metersPerPx,
          'height': top * metersPerPx,
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              _offset(center, bearing, front, -half),
              _offset(center, bearing, front, half),
              _offset(center, bearing, rear, half),
              _offset(center, bearing, rear, -half),
              _offset(center, bearing, front, -half),
            ],
          ],
        },
      });
    }
    back += length + gap;
  }
  return {'type': 'FeatureCollection', 'features': features};
}

/// The point [backM] behind the train's head, and the bearing there. A
/// [reversed] train runs its route towards the start, so its cars trail
/// further along it.
(LatLng, double) _placeBehind(
  LatLng head,
  double heading,
  RoutePath? path,
  double? headAlong,
  double backM, {
  bool reversed = false,
}) {
  if (path == null || headAlong == null || path.isEmpty) {
    return (_move(head, heading, -backM), heading);
  }
  if (reversed) {
    final along = headAlong + backM;
    if (along <= path.lengthM) {
      return (
        path.fixAt(along).snapped,
        path.bearingAt(along, spanM: 40, backwards: true),
      );
    }
    return (_move(head, heading, -backM), heading);
  }
  final along = headAlong - backM;
  if (along >= 0) {
    return (path.fixAt(along).snapped, path.bearingAt(along, spanM: 40));
  }
  // Behind the start of the route: carry on straight back from it.
  final startBearing = path.bearingAt(0, spanM: 40);
  return (_move(path.points.first, startBearing, along), startBearing);
}

/// [from] moved [meters] along [bearing] (negative: backwards).
LatLng _move(LatLng from, double bearing, double meters) {
  final b = bearing * math.pi / 180;
  return LatLng(
    from.latitude + meters * math.cos(b) / 111320,
    from.longitude +
        meters *
            math.sin(b) /
            (111320 * math.cos(from.latitude * math.pi / 180)),
  );
}

/// `[lng, lat]` of the point [forward] metres ahead of [center] along
/// [bearing] and [right] metres to its right.
List<double> _offset(
  LatLng center,
  double bearing,
  double forward,
  double right,
) {
  final b = bearing * math.pi / 180;
  final east = forward * math.sin(b) + right * math.cos(b);
  final north = forward * math.cos(b) - right * math.sin(b);
  return [
    center.longitude +
        east / (111320 * math.cos(center.latitude * math.pi / 180)),
    center.latitude + north / 111320,
  ];
}
