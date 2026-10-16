import 'dart:math' as math;
import 'dart:ui' show Color, Size;

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform;
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/pakistan_outline.dart';
import 'package:railway_hrms/modules/tracking/services/rail_router.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';

/// The base map in dark mode.
const String _darkStyle = 'https://tiles.openfreemap.org/styles/dark';

/// The base map for [palette]'s mode.
String mapStyleOf(TrackPalette palette) =>
    palette.isDark ? _darkStyle : MapLibreStyles.openfreemapLiberty;

/// Base-map layers that [addPakistanLayers] replaces: their "disputed"
/// boundaries cut Gilgit-Baltistan and Kashmir off from Pakistan, and their
/// province lines and names follow the same claims. The dark map draws
/// every border in one layer, so there all of them go.
const List<String> _replacedLayers = [
  'boundary_disputed',
  'boundary_3',
  'label_state',
  'boundary_state',
  'boundary_country_z0-4',
  'boundary_country_z5-',
  'place_state',
];

/// Each base map's first place-name layer; Pakistan's shading and borders
/// go under it so names stay readable.
const List<String> _firstLabelLayers = ['label_other', 'highway_name_other'];

/// iOS updates map sources more slowly than Android, so there moving
/// markers are redrawn less often and nothing pulses over a map; and a map
/// must open flat there (see `TrainLiveMapView._initialCamera`).
bool get lightMaps => defaultTargetPlatform == TargetPlatform.iOS;

/// How often moving markers need redrawing so they glide: often enough
/// that each redraw moves them by under half a pixel, every frame when
/// zoomed in on a fast train, once a second when the whole country shows
/// and a train crawls a fraction of a pixel a second.
Duration redrawInterval({
  required double speedMps,
  required double zoom,
  required double latitude,
}) {
  final metersPerPx =
      40075016.686 *
      math.cos(latitude * math.pi / 180) /
      (512 * math.pow(2, zoom));
  final pxPerSecond = speedMps / metersPerPx;
  if (pxPerSecond <= 0.05) return const Duration(seconds: 1);
  final seconds = (0.45 / pxPerSecond).clamp(0.0, 1.0);
  return Duration(microseconds: (seconds * 1e6).round());
}

/// A flat, north-up camera that shows all of [bounds] on a map [size]
/// across, clear of [padding] on each side. The map's content [insets]
/// come on top of [padding]; they already move the point a camera aims
/// at into the middle of what they leave. (`CameraUpdate.newLatLngBounds`
/// keeps the camera's tilt and turn, and a tilted fit of a long journey
/// lands far off it.)
CameraPosition flatCameraFor(
  LatLngBounds bounds, {
  required Size size,
  EdgeInsets insets = EdgeInsets.zero,
  EdgeInsets padding = EdgeInsets.zero,
  double maxZoom = 16,
}) {
  // Web Mercator, the world 0…1 across and down.
  double x(double lng) => (lng + 180) / 360;
  double y(double lat) {
    final s = math.sin(lat.clamp(-85.0, 85.0) * math.pi / 180);
    return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
  }

  final west = x(bounds.southwest.longitude);
  final east = x(bounds.northeast.longitude);
  final north = y(bounds.northeast.latitude);
  final south = y(bounds.southwest.latitude);
  final width = math.max(
    1.0,
    size.width - insets.horizontal - padding.horizontal,
  );
  final height = math.max(
    1.0,
    size.height - insets.vertical - padding.vertical,
  );
  // A map is 512 pixels across at zoom 0.
  double fit(double pixels, double span) =>
      math.log(pixels / (512 * math.max(span, 1e-9))) / math.ln2;
  final zoom = math
      .min(fit(width, east - west), fit(height, south - north))
      .clamp(0.0, maxZoom)
      .toDouble();
  // The bounds' middle goes in the middle of what the padding leaves.
  final scale = 512 * math.pow(2, zoom);
  final cx = (west + east) / 2 - (padding.left - padding.right) / 2 / scale;
  final cy = (north + south) / 2 - (padding.top - padding.bottom) / 2 / scale;
  final lat = math.atan(_sinh(math.pi * (1 - 2 * cy))) * 180 / math.pi;
  return CameraPosition(target: LatLng(lat, cx * 360 - 180), zoom: zoom);
}

double _sinh(double v) => (math.exp(v) - math.exp(-v)) / 2;

Map<String, dynamic> _collection(Map<String, dynamic> feature) => {
  'type': 'FeatureCollection',
  'features': [feature],
};

/// Draws Pakistan as on its official map — Gilgit-Baltistan, Azad Kashmir
/// and Jammu & Kashmir included — tinted green with its provinces and their
/// names, and dims the rest of the world. Call before adding the layers
/// that go on top.
Future<void> addPakistanLayers(
  MapLibreMapController map,
  TrackPalette palette,
) async {
  String? below;
  try {
    final ids = await map.getLayerIds();
    for (final id in _replacedLayers) {
      if (ids.contains(id)) await map.setLayerVisibility(id, false);
    }
    below = _firstLabelLayers.where(ids.contains).firstOrNull;
  } catch (e) {
    debugPrint('⚠️ Base map layers: $e');
  }
  final outline = await PakistanOutline.load();
  await map.addGeoJsonSource('pk-mask', _collection(outline.maskGeoJson));
  await map.addFillLayer(
    'pk-mask',
    'pk-mask',
    FillLayerProperties(
      fillColor: mapHex(palette.mask),
      fillOpacity: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        0.2,
        10,
        0.1,
      ],
    ),
    belowLayerId: below,
    enableInteraction: false,
  );
  await map.addGeoJsonSource('pk-outline', _collection(outline.outlineGeoJson));
  // Green land, fading out as the map zooms in to the tracks.
  await map.addFillLayer(
    'pk-outline',
    'pk-land',
    FillLayerProperties(
      fillColor: mapHex(palette.g2),
      fillOpacity: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        0.2,
        8,
        0.08,
        11,
        0,
      ],
    ),
    belowLayerId: below,
    enableInteraction: false,
  );
  await map.addGeoJsonSource('pk-borders', _collection(outline.bordersGeoJson));
  await map.addLineLayer(
    'pk-borders',
    'pk-borders',
    LineLayerProperties(
      lineColor: mapHex(palette.g1),
      lineOpacity: 0.75,
      lineWidth: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        1,
        10,
        2,
      ],
      lineDasharray: [3, 2],
    ),
    belowLayerId: below,
    enableInteraction: false,
  );
  await map.addLineLayer(
    'pk-outline',
    'pk-outline-glow',
    LineLayerProperties(
      lineColor: mapHex(palette.g2),
      lineOpacity: 0.35,
      lineWidth: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        6,
        10,
        12,
      ],
      lineBlur: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        4,
        10,
        8,
      ],
      lineJoin: 'round',
    ),
    belowLayerId: below,
    enableInteraction: false,
  );
  await map.addLineLayer(
    'pk-outline',
    'pk-outline',
    LineLayerProperties(
      lineColor: mapHex(palette.g1),
      lineWidth: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        1.6,
        10,
        3,
      ],
      lineJoin: 'round',
    ),
    belowLayerId: below,
    enableInteraction: false,
  );
  await map.addGeoJsonSource('pk-labels', outline.labelsGeoJson);
  await map.addSymbolLayer(
    'pk-labels',
    'pk-labels',
    SymbolLayerProperties(
      textField: [Expressions.get, 'name'],
      textFont: ['Noto Sans Bold'],
      textSize: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        10.5,
        7,
        14,
      ],
      textColor: mapHex(palette.g1),
      textHaloColor: mapHex(palette.halo),
      textHaloWidth: 1.8,
      textLetterSpacing: 0.04,
      textMaxWidth: 7,
    ),
    maxzoom: 8,
    enableInteraction: false,
  );
}

Future<Map<String, dynamic>?>? _network;

Future<Map<String, dynamic>?> _networkCollection() =>
    _network ??= RailRouter.instance.network().then((lines) {
      if (lines == null) {
        _network = null;
        return null;
      }
      return _collection({
        'type': 'Feature',
        'properties': <String, dynamic>{},
        'geometry': {
          'type': 'MultiLineString',
          'coordinates': [
            for (final line in lines)
              [
                for (final p in line) [p.longitude, p.latitude],
              ],
          ],
        },
      });
    });

/// From about this zoom a railway is drawn as a track — sleepers under two
/// rails — rather than a line.
const double trackZoom = 9;

/// A railway track's sleepers: one wide line dashed across the rails.
LineLayerProperties trackSleepers(Color color, {Object opacity = 0.6}) =>
    LineLayerProperties(
      lineColor: mapHex(color),
      lineWidth: const [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        9,
        8,
        14,
        11,
      ],
      lineDasharray: const [0.28, 0.62],
      lineOpacity: opacity,
    );

/// A railway track's two rails: one line drawn either side of a gap.
LineLayerProperties trackRails(Color color, {Object opacity = 1.0}) =>
    LineLayerProperties(
      lineColor: mapHex(color),
      lineWidth: 1.6,
      lineGapWidth: const [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        9,
        4,
        14,
        6,
      ],
      lineJoin: 'round',
      lineOpacity: opacity,
    );

/// [opacity] faded in over the zoom a line turns into a track, or out
/// when [out].
List<Object> _aroundTrackZoom(double opacity, {bool out = false}) => [
  Expressions.interpolate,
  ['linear'],
  [Expressions.zoom],
  trackZoom - 0.6,
  out ? opacity : 0,
  trackZoom + 0.4,
  out ? 0 : opacity,
];

/// Every railway in the country under [belowLayerId]: a thin line, which
/// with [track] turns into a railway track as the map zooms in. The
/// network loads in the background, so this can finish well after the map
/// is up.
Future<void> addRailNetworkLayer(
  MapLibreMapController map,
  TrackPalette palette, {
  required String belowLayerId,
  double opacity = 0.55,
  double? maxzoom,
  bool track = false,
}) async {
  final network = await _networkCollection();
  if (network == null) return;
  await map.addGeoJsonSource('rail-network', network);
  await map.addLineLayer(
    'rail-network',
    'rail-network',
    LineLayerProperties(
      lineColor: mapHex(palette.g1),
      lineOpacity: track ? _aroundTrackZoom(opacity, out: true) : opacity,
      lineWidth: const [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        4,
        0.7,
        8,
        1.3,
        12,
        2.2,
      ],
      lineJoin: 'round',
      lineCap: 'round',
    ),
    belowLayerId: belowLayerId,
    maxzoom: track ? trackZoom + 0.4 : maxzoom,
    enableInteraction: false,
  );
  if (!track) return;
  // The two cross-fade, so the line never jumps into a track.
  await map.addLineLayer(
    'rail-network',
    'rail-network-sleepers',
    trackSleepers(palette.g2, opacity: _aroundTrackZoom(0.55)),
    belowLayerId: belowLayerId,
    minzoom: trackZoom - 0.6,
    enableInteraction: false,
  );
  await map.addLineLayer(
    'rail-network',
    'rail-network-rails',
    trackRails(palette.g1, opacity: _aroundTrackZoom(1)),
    belowLayerId: belowLayerId,
    minzoom: trackZoom - 0.6,
    enableInteraction: false,
  );
}

/// Stations for [addStationLayers]'s source. [major] stations stand out:
/// where today's trains start and end.
Map<String, dynamic> stationsGeoJson(
  List<TrainStation> stations, {
  List<TrainStation> major = const [],
}) => {
  'type': 'FeatureCollection',
  'features': [
    for (final station in stations)
      if (station.position case final p?)
        {
          'type': 'Feature',
          'properties': {
            'name': station.name,
            'major': major.any(station.isSameStation) ? 1 : 0,
          },
          'geometry': {
            'type': 'Point',
            'coordinates': [p.longitude, p.latitude],
          },
        },
  ],
};

const _isMajor = [
  Expressions.equal,
  [Expressions.get, 'major'],
  1,
];

/// Every station of the railway as a dot at every zoom, named as the map
/// zooms in — the major ones first. Fill the `all-stations` source with [stationsGeoJson].
Future<void> addStationLayers(
  MapLibreMapController map,
  TrackPalette palette,
) async {
  await map.addGeoJsonSource('all-stations', const {
    'type': 'FeatureCollection',
    'features': <Object>[],
  });
  await map.addCircleLayer(
    'all-stations',
    'all-stations-dot',
    CircleLayerProperties(
      circleRadius: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        3.5,
        [Expressions.caseExpression, _isMajor, 2.4, 1.3],
        9,
        [Expressions.caseExpression, _isMajor, 5, 3.2],
        14,
        [Expressions.caseExpression, _isMajor, 7, 5.5],
      ],
      circleColor: mapHex(palette.card),
      circleStrokeColor: [
        Expressions.caseExpression,
        _isMajor,
        mapHex(palette.g1),
        mapHex(palette.g2),
      ],
      circleStrokeWidth: [
        Expressions.interpolate,
        ['linear'],
        [Expressions.zoom],
        3.5,
        0.8,
        10,
        2.2,
      ],
      circlePitchAlignment: 'map',
    ),
    enableInteraction: false,
  );
  for (final (id, major, from) in [
    ('all-stations-major', 1, 5.5),
    ('all-stations-label', 0, 8.0),
  ]) {
    await map.addSymbolLayer(
      'all-stations',
      id,
      SymbolLayerProperties(
        textField: const [Expressions.get, 'name'],
        textFont: [major == 1 ? 'Noto Sans Bold' : 'Noto Sans Regular'],
        textSize: const [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          5,
          10,
          12,
          12.5,
        ],
        textOffset: const [0, 0.8],
        textAnchor: 'top',
        textColor: major == 1 ? mapHex(palette.g1) : mapHex(palette.ink),
        textHaloColor: mapHex(palette.halo),
        textHaloWidth: 1.5,
        textOptional: true,
      ),
      filter: [
        Expressions.equal,
        [Expressions.get, 'major'],
        major,
      ],
      minzoom: from,
      enableInteraction: false,
    );
  }
}

/// A train's route cut into numbered pieces, so the part it has covered
/// can be drawn in another colour without sending the whole route to the
/// map again as the train moves: the pieces go once, two layers filtered
/// on the piece number split them into done and to go, and only the
/// covered part of the piece the train is on is sent as it moves.
class RoutePieces {
  RoutePieces(this.path, {this.pieceM = 5000})
    : count = path.isEmpty
          ? 0
          : (path.lengthM / pieceM).ceil().clamp(1, 100000);

  final RoutePath path;
  final double pieceM;
  final int count;

  /// The piece the point [alongM] metres along the route is in.
  int pieceAt(double alongM) =>
      (alongM / pieceM).floor().clamp(0, count == 0 ? 0 : count - 1);

  /// Every piece, numbered by its `i` property.
  Map<String, dynamic> get geoJson => {
    'type': 'FeatureCollection',
    'features': [
      for (var i = 0; i < count; i++)
        _line(path.slice(i * pieceM, (i + 1) * pieceM), {'i': i}),
    ],
  };

  /// The covered part of the piece the train is on: from the piece's start
  /// to [alongM].
  Map<String, dynamic> headGeoJson(double alongM) {
    final start = pieceAt(alongM) * pieceM;
    if (alongM - start < 1) {
      return const {'type': 'FeatureCollection', 'features': <Object>[]};
    }
    return _collection(_line(path.slice(start, alongM), const {}));
  }

  /// A filter for the pieces before [piece] (done) or from it on.
  static String filter(int piece, {required bool done}) =>
      '["${done ? '<' : '>='}",["get","i"],$piece]';

  static Map<String, dynamic> _line(
    List<LatLng> points,
    Map<String, Object> properties,
  ) => {
    'type': 'Feature',
    'properties': properties,
    'geometry': {
      'type': 'LineString',
      'coordinates': [
        for (final p in points) [p.longitude, p.latitude],
      ],
    },
  };
}
