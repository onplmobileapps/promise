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

  /// A train gone offline: grey-blue, its band dulled and its lamp out.
  static const offline = Train3dPalette(
    frame: '#263241',
    lowerBody: '#3E4E63',
    band: '#B8C4D3',
    body: '#566A82',
    coachBody: '#5E728B',
    glass: '#18212C',
    locoRoof: '#7F93AB',
    coachRoof: '#C9D1DB',
    lamp: '#D6DCE4',
  );
}

/// How much of the train is modelled.
enum Train3dDetail {
  /// Bogies, windows, roof units, gangways and lamps: one train close up.
  full,

  /// The body, band, cab and roofs only: many trains at once, or a phone
  /// that draws lite.
  low,
}

/// One box of a car: from [from] to [to] back from the car's front, [width]
/// as a share of the car's, standing from [base] to [top], its middle
/// [side] of the car's width to the right of the car's; all lengths in
/// screen pixels. Low-detail trains leave out the [fine] ones.
typedef _Box = ({
  double from,
  double to,
  double width,
  double base,
  double top,
  String Function(Train3dPalette) color,
  double side,
  bool fine,
});

_Box _box(
  double from,
  double to,
  double width,
  double base,
  double top,
  String Function(Train3dPalette) color, {
  double side = 0,
  bool fine = false,
}) => (
  from: from,
  to: to,
  width: width,
  base: base,
  top: top,
  color: color,
  side: side,
  fine: fine,
);

/// The car's width, in screen pixels.
const double _carWidth = 16;
const double _locoLength = 46;
const double _coachLength = 50;
const double _carGap = 3;

String _frame(Train3dPalette p) => p.frame;
String _lowerBody(Train3dPalette p) => p.lowerBody;
String _band(Train3dPalette p) => p.band;
String _body(Train3dPalette p) => p.body;
String _coachBody(Train3dPalette p) => p.coachBody;
String _glass(Train3dPalette p) => p.glass;
String _locoRoof(Train3dPalette p) => p.locoRoof;
String _coachRoof(Train3dPalette p) => p.coachRoof;
String _lamp(Train3dPalette p) => p.lamp;

/// A diesel-electric locomotive, cab first: bogies and a fuel tank under
/// a green skirt with the yellow band, the cab with its windscreen and
/// headlights, and the narrower long hood behind it with its radiator.
/// No two boxes share a face that shows, so nothing flickers.
final List<_Box> _loco = [
  _box(5, 15, 0.72, 0, 4.5, _frame),
  _box(31, 41, 0.72, 0, 4.5, _frame),
  _box(16, 30, 0.6, 1.5, 5, _frame, fine: true),
  _box(0.5, 45.5, 1, 4.5, 14, _lowerBody),
  _box(0.5, 45.5, 1.03, 14, 16.5, _band),
  // The cab: below the windscreen, the windscreen, its roof.
  _box(0.6, 9, 1, 16.5, 18.5, _body),
  _box(0.6, 9, 1.02, 18.5, 22.5, _glass),
  _box(0.6, 9, 1, 22.5, 26, _body),
  // The long hood, its roof and the radiator fans at the back.
  _box(9, 45.5, 0.86, 16.5, 25, _body),
  _box(11, 44, 0.7, 25, 26.5, _locoRoof),
  _box(33, 41, 0.42, 26.5, 27.8, _frame, fine: true),
  // A headlight over the windscreen and two low ditch lights.
  _box(0, 1.2, 0.3, 23, 25, _lamp),
  _box(0, 1, 0.14, 7, 9, _lamp, side: -0.32, fine: true),
  _box(0, 1, 0.14, 7, 9, _lamp, side: 0.32, fine: true),
];

/// A passenger coach: bogies and the underframe, the green skirt and the
/// band, the body with a row of windows set in it, and the roof with its
/// air-conditioning units.
final List<_Box> _coach = [
  _box(5, 14, 0.72, 0, 4.5, _frame),
  _box(36, 45, 0.72, 0, 4.5, _frame),
  _box(16, 34, 0.6, 2, 5, _frame, fine: true),
  _box(0.5, 49.5, 1, 4.5, 14, _lowerBody),
  _box(0.5, 49.5, 1.03, 14, 16.5, _band),
  _box(0.5, 49.5, 1, 16.5, 25.5, _coachBody),
  // Six windows between the doors at the ends; low detail runs one strip
  // of glass instead.
  for (var i = 0; i < 6; i++)
    _box(5 + i * 6.9, 5 + i * 6.9 + 5.5, 1.03, 19, 22, _glass, fine: true),
  _box(1, 49, 0.88, 25.5, 27, _coachRoof),
  _box(10, 18, 0.5, 27, 28.2, _coachRoof, fine: true),
  _box(32, 40, 0.5, 27, 28.2, _coachRoof, fine: true),
];

/// The window strip of a low-detail coach.
final _Box _coachWindowStrip = _box(4, 46, 1.03, 19, 22, _glass);

/// The dark bellows joining a car to the next, out over the gap and a
/// little into both, so its ends never lie on a car's face.
final _Box _gangway = _box(-1.2, _carGap + 1.2, 0.55, 6, 22, _frame);

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
  Train3dDetail detail = Train3dDetail.full,
}) =>
    (Train3dScene(metersPerPx: metersPerPx, detail: detail)..add(
          head: head,
          heading: heading,
          path: path,
          headAlong: headAlong,
          reversed: reversed,
          coaches: coaches,
          palette: palette,
        ))
        .toGeoJson();

/// 3D trains for one fill-extrusion source, as few features as can be.
///
/// The map takes a source as a JSON string, and a collection of a hundred
/// features or more is encoded on an isolate made for it, every update; so
/// boxes of one colour and height, on every car of every train, go in one
/// feature together, which keeps a train to about a dozen features and a
/// whole fleet of them to a couple of dozen. Coordinates are kept to the
/// centimetre, which halves the text sent.
class Train3dScene {
  Train3dScene({required this.metersPerPx, this.detail = Train3dDetail.full});

  final double metersPerPx;
  final Train3dDetail detail;

  /// Rings of boxes, by colour, base and top.
  final Map<(String, double, double), List<List<List<List<double>>>>> _groups =
      {};

  bool get isEmpty => _groups.isEmpty;

  /// Adds a train; see [train3dCollection].
  void add({
    required LatLng head,
    required double heading,
    RoutePath? path,
    double? headAlong,
    bool reversed = false,
    int coaches = 2,
    Train3dPalette palette = Train3dPalette.pakistanRailways,
  }) {
    final fine = detail == Train3dDetail.full;
    var back = 0.0;
    for (var car = 0; car <= coaches; car++) {
      final isLoco = car == 0;
      final length = isLoco ? _locoLength : _coachLength;
      final centerBackM = (back + length / 2) * metersPerPx;
      final (center, bearing) = _placeBehind(
        head,
        heading,
        path,
        headAlong,
        centerBackM,
        reversed: reversed,
      );
      final frame = _CarFrame(center, bearing);
      void place(_Box box, {double offset = 0}) {
        // Along the car, forward from its centre.
        final front = (length / 2 - box.from - offset) * metersPerPx;
        final rear = (length / 2 - box.to - offset) * metersPerPx;
        final half = _carWidth * box.width / 2 * metersPerPx;
        final mid = _carWidth * box.side * metersPerPx;
        final key = (
          box.color(palette),
          _cm(box.base * metersPerPx),
          _cm(box.top * metersPerPx),
        );
        (_groups[key] ??= []).add([
          [
            frame.at(front, mid - half),
            frame.at(front, mid + half),
            frame.at(rear, mid + half),
            frame.at(rear, mid - half),
            frame.at(front, mid - half),
          ],
        ]);
      }

      for (final box in isLoco ? _loco : _coach) {
        if (fine || !box.fine) place(box);
      }
      if (!isLoco && !fine) place(_coachWindowStrip);
      // Joined to the car behind it.
      if (fine && car < coaches) place(_gangway, offset: length);
      back += length + _carGap;
    }
  }

  Map<String, dynamic> toGeoJson() => {
    'type': 'FeatureCollection',
    'features': [
      for (final MapEntry(key: (color, base, top), value: polygons)
          in _groups.entries)
        {
          'type': 'Feature',
          'properties': {'color': color, 'base': base, 'height': top},
          'geometry': {'type': 'MultiPolygon', 'coordinates': polygons},
        },
    ],
  };

  static double _cm(double meters) => (meters * 100).roundToDouble() / 100;
}

/// A car's place and heading, to put its boxes around: `[lng, lat]` of
/// points ahead of and to the right of its middle.
class _CarFrame {
  _CarFrame(this.center, double bearing)
    : _sin = math.sin(bearing * math.pi / 180),
      _cos = math.cos(bearing * math.pi / 180),
      _perLng = 1 / (111320 * math.cos(center.latitude * math.pi / 180));

  final LatLng center;
  final double _sin;
  final double _cos;
  final double _perLng;

  static const double _perLat = 1 / 111320;

  /// `[lng, lat]` of the point [forward] metres ahead and [right] metres
  /// to the right, to about a centimetre.
  List<double> at(double forward, double right) {
    final east = forward * _sin + right * _cos;
    final north = forward * _cos - right * _sin;
    return [
      _round(center.longitude + east * _perLng),
      _round(center.latitude + north * _perLat),
    ];
  }

  static double _round(double degrees) => (degrees * 1e7).roundToDouble() / 1e7;
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
