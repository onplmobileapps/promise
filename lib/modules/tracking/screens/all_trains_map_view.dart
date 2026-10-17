import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/maps/map_loop.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/screens/train_live_map_view.dart';
import 'package:railway_hrms/modules/tracking/services/map_pacer.dart';
import 'package:railway_hrms/modules/tracking/services/pakistan_outline.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/train_motion.dart';
import 'package:railway_hrms/modules/tracking/widgets/map_cover.dart';
import 'package:railway_hrms/modules/tracking/widgets/map_layers.dart';
import 'package:railway_hrms/modules/tracking/widgets/run_picker.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_3d.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_filters.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_sprite.dart';

const LatLng _pakistanCenter = LatLng(30.2, 69.6);

List<Object> _statusColor(TrackPalette palette) => [
  Expressions.match,
  [Expressions.get, 'kind'],
  'moving',
  mapHex(palette.g2),
  'stopped',
  mapHex(palette.amber),
  mapHex(palette.grey),
];
const Map<String, dynamic> _emptyCollection = {
  'type': 'FeatureCollection',
  'features': <Object>[],
};

/// Every running train on one map of Pakistan, live. Expects the
/// [RealTimeTrackingCubit] of the screen it was opened from.
class AllTrainsMapView extends StatefulWidget {
  const AllTrainsMapView({super.key});

  @override
  State<AllTrainsMapView> createState() => _AllTrainsMapViewState();
}

/// A train on the map, with what the map and the cards show for it.
typedef _OnMap = ({LiveTrain train, TrainPosition position, LiveStatus status});

class _AllTrainsMapViewState extends State<AllTrainsMapView> {
  static const double _cardWidth = 284;

  /// From this zoom trains are drawn in 3D instead of as flat sprites.
  static const double _train3dZoom = 12;
  static const double _cardGap = 12;

  /// The search field and its gap above the filters.
  static const double _searchHeight = 58;

  late final RealTimeTrackingCubit _cubit = context
      .read<RealTimeTrackingCubit>();
  final _carousel = ScrollController();
  Timer? _clock;

  MapLibreMapController? _map;
  bool _layersReady = false;
  bool _watching = false;
  TrainFilter _filter = TrainFilter.all;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _selectedId;

  /// What moves each train between its reports, by train id, where it is
  /// drawn now and when it was last moved on.
  final Map<String, TrainMotion> _motions = {};
  final Map<String, TrainPose> _poses = {};
  final Map<String, DateTime> _posedAt = {};

  /// The fastest train in view, which sets how often the map is redrawn.
  double _fastest = 0;

  /// Keeps the map's updates within what the phone can draw.
  final _pacer = MapPacer.forPhone();

  /// Moves the trains on the map as often as they visibly move, without
  /// having Flutter redraw the screen around it.
  late final MapLoop _loop = MapLoop(_onFrame, interval: () => _pacer.gap);

  /// The trains on the map, as last worked out: their statuses age only by
  /// the second, so they aren't worked out again for every update.
  List<_OnMap>? _entries;
  DateTime _entriesAt = DateTime(0);
  final Map<String, String> _labels = {};

  /// Zoomed in this far, only the trains in and around the view are sent
  /// to the map: a handful rather than every train in the country.
  static const double _cullFromZoom = 8;

  /// What of the map the last update covered; null when it covered all.
  _View? _view;

  /// The screen's diagonal, in logical pixels.
  double _screenDiagonal = 1000;
  bool _drawBusy = false;
  bool _drawAgain = false;

  /// The next frame redraws every train, as after new reports.
  bool _drawSoon = false;
  bool _focusBusy = false;
  bool _draw3dBusy = false;
  DateTime _lastDrawAt = DateTime(0);
  DateTime _lastFocusAt = DateTime(0);

  /// The map is up with the app's layers on it; the cover has lifted.
  bool _shown = false;
  bool _slow = false;
  Timer? _slowTimer;

  /// Bumped to build the map afresh after it failed to load.
  int _mapKey = 0;
  static const Duration _slowAfter = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _feedMotions(_cubit.state);
    // Statuses age without new reports (a moving train becomes "last seen").
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      _entries = null;
      _draw();
    });
    _slowTimer = Timer(_slowAfter, () {
      if (mounted && !_shown) setState(() => _slow = true);
    });
  }

  /// The colours the map is drawn in, kept from the last build so the map's
  /// own callbacks, which can come after the page has gone, never look them
  /// up.
  late TrackPalette _palette;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _palette = TrackPalette.of(context);
    final size = MediaQuery.sizeOf(context);
    _screenDiagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    // Only while on screen, not under a train's own map.
    final shown = TickerMode.valuesOf(context).enabled;
    _setWatching(shown);
    _loop.visible = shown;
  }

  @override
  void dispose() {
    _setWatching(false);
    _clock?.cancel();
    _slowTimer?.cancel();
    _loop.dispose();
    _carousel.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _map?.onFeatureTapped.remove(_onFeatureTapped);
    super.dispose();
  }

  void _setWatching(bool on) {
    if (on == _watching) return;
    _watching = on;
    on ? _cubit.watchFleet() : _cubit.unwatchFleet();
  }

  // ─── Map ──────────────────────────────────────────────────────────────

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      await _addLayers(map);
    } catch (e) {
      debugPrint('⚠️ Fleet map layers: $e');
      return;
    }
    if (!mounted || !identical(map, _map)) return;
    _layersReady = true;
    _view = null;
    _draw();
    _drawStations();
    if (!_loop.isActive) _loop.start();
    Timer(const Duration(milliseconds: 250), () {
      if (mounted && !_shown) setState(() => _shown = true);
    });
    unawaited(
      addRailNetworkLayer(
        map,
        _palette,
        belowLayerId: 'all-stations-dot',
        track: true,
      ).catchError((Object e) => debugPrint('⚠️ Rail network: $e')),
    );
    await _fitPakistan();
  }

  Future<void> _addLayers(MapLibreMapController map) async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final palette = _palette;
    final statusColor = _statusColor(palette);
    try {
      await addPakistanLayers(map, palette);
    } catch (e) {
      debugPrint('⚠️ Pakistan boundary: $e');
    }
    await map.addImage(
      'train-live',
      await renderTrainSprite(TrainLivery.pakistanRailways, dpr),
    );
    await map.addImage(
      'train-dim',
      await renderTrainSprite(TrainLivery.faded, dpr, headlights: false),
    );

    await addStationLayers(map, palette);

    // Pulse around the selected train.
    await map.addGeoJsonSource('fleet-focus', _emptyCollection);
    await map.addCircleLayer(
      'fleet-focus',
      'fleet-focus',
      CircleLayerProperties(
        circleRadius: [Expressions.get, 'r'],
        circleOpacity: [Expressions.get, 'o'],
        circleColor: mapHex(palette.g2),
        circlePitchAlignment: 'map',
      ),
      enableInteraction: false,
    );

    await map.addGeoJsonSource('fleet', _emptyCollection);
    // A ring in the train's status colour under it, also its tap target
    // while the train is small.
    await map.addCircleLayer(
      'fleet',
      'fleet-halo',
      CircleLayerProperties(
        circleRadius: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          4,
          7,
          7,
          11,
          9,
          17,
          14,
          30,
        ],
        circleColor: statusColor,
        circleOpacity: 0.22,
        circleStrokeColor: statusColor,
        circleStrokeWidth: 1.6,
        circleStrokeOpacity: 0.7,
        circlePitchAlignment: 'map',
      ),
    );
    // The train itself, turned along its heading at every zoom.
    await map.addSymbolLayer(
      'fleet',
      'fleet-train',
      const SymbolLayerProperties(
        iconImage: [
          Expressions.match,
          [Expressions.get, 'kind'],
          'old',
          'train-dim',
          'train-live',
        ],
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          4,
          0.24,
          7,
          0.4,
          9,
          0.7,
          14,
          1.0,
          17,
          1.3,
        ],
        iconRotate: [Expressions.get, 'course'],
        iconRotationAlignment: 'map',
        iconPitchAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        symbolSortKey: [Expressions.get, 'z'],
      ),
      maxzoom: _train3dZoom,
    );
    // Zoomed in, trains near the middle of the map stand up in 3D.
    await _add3dLayer(map);
    // Flat trains close up too, shown instead of the 3D ones on a phone
    // that can't keep up with them.
    await map.addSymbolLayer(
      'fleet',
      'fleet-train-near',
      const SymbolLayerProperties(
        iconImage: [
          Expressions.match,
          [Expressions.get, 'kind'],
          'old',
          'train-dim',
          'train-live',
        ],
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          12,
          0.85,
          14,
          1.0,
          17,
          1.3,
        ],
        iconRotate: [Expressions.get, 'course'],
        iconRotationAlignment: 'map',
        iconPitchAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        symbolSortKey: [Expressions.get, 'z'],
        visibility: 'none',
      ),
      minzoom: _train3dZoom,
    );
    await map.addSymbolLayer(
      'fleet',
      'fleet-label',
      SymbolLayerProperties(
        textField: [Expressions.get, 'label'],
        textFont: ['Noto Sans Bold'],
        textSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          6,
          10.5,
          12,
          12.5,
        ],
        // Below the dot, or below the much larger train when zoomed in.
        textOffset: [
          'step',
          [Expressions.zoom],
          [
            Expressions.literal,
            [0, 1.6],
          ],
          9,
          [
            Expressions.literal,
            [0, 3.6],
          ],
        ],
        textAnchor: 'top',
        textColor: mapHex(palette.ink),
        textHaloColor: mapHex(palette.halo),
        textHaloWidth: 1.6,
        textOptional: true,
      ),
      minzoom: 5.5,
      enableInteraction: false,
    );
  }

  Future<void> _add3dLayer(MapLibreMapController map) async {
    await map.addGeoJsonSource('fleet-3d', _emptyCollection);
    await map.addFillExtrusionLayer(
      'fleet-3d',
      'fleet-3d',
      const FillExtrusionLayerProperties(
        fillExtrusionColor: [Expressions.get, 'color'],
        fillExtrusionBase: [Expressions.get, 'base'],
        fillExtrusionHeight: [Expressions.get, 'height'],
        fillExtrusionOpacity: 1.0,
      ),
      minzoom: _train3dZoom,
      enableInteraction: false,
    );
  }

  Future<void> _fitPakistan() async {
    final map = _map;
    if (map == null) return;
    final media = MediaQuery.of(context);
    final top = media.padding.top + 132 + _searchHeight;
    final bottom = media.padding.bottom + _carouselHeight(context) + 40;
    try {
      final outline = await PakistanOutline.load();
      if (!mounted) return;
      // Flat and north up, levelled as it goes rather than first.
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          flatCameraFor(
            outline.bounds,
            size: media.size,
            padding: EdgeInsets.fromLTRB(16, top, 16, bottom),
          ),
        ),
        duration: const Duration(milliseconds: 1200),
      );
    } catch (e) {
      debugPrint('⚠️ Fleet camera: $e');
    }
  }

  void _retryMap() {
    _slowTimer?.cancel();
    setState(() {
      _mapKey++;
      _map = null;
      _layersReady = false;
      _shown = false;
      _slow = false;
    });
    _slowTimer = Timer(_slowAfter, () {
      if (mounted && !_shown) setState(() => _slow = true);
    });
  }

  Future<void> _flyTo(String id) async {
    final train = _cubit.state.trainById(id);
    final point =
        _poses[id]?.point ??
        (train == null ? null : _cubit.state.positionOf(train)?.position);
    final map = _map;
    if (point == null || map == null) return;
    final camera = map.cameraPosition;
    try {
      // Close and tilted, so the train stands up in 3D.
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: point,
            zoom: math.max(camera?.zoom ?? 0, _train3dZoom + 0.8),
            tilt: 50,
            bearing: camera?.bearing ?? 0,
          ),
        ),
        duration: const Duration(milliseconds: 1200),
      );
    } catch (e) {
      debugPrint('⚠️ Fleet camera: $e');
    }
  }

  // ─── Drawing ──────────────────────────────────────────────────────────

  /// Gives each train's motion its route and newest report; the frames
  /// then move it along the track between reports.
  void _feedMotions(RealTimeTrackingState state) {
    final now = DateTime.now();
    final seen = <String>{};
    for (final train in state.trains) {
      final position = state.positionOf(train);
      if (position == null) continue;
      seen.add(train.id);
      // Off the screen a train is moved on only now and then, in longer
      // steps.
      _motions.putIfAbsent(train.id, () => TrainMotion(maxStepS: 1.5))
        ..setPath(state.pathOf(train.id))
        ..report(position, now);
    }
    _motions.removeWhere((id, _) => !seen.contains(id));
    _poses.removeWhere((id, _) => !seen.contains(id));
    _posedAt.removeWhere((id, _) => !seen.contains(id));
  }

  /// Every station, those where today's trains start and end standing out.
  void _drawStations() {
    final map = _map;
    if (map == null || !_layersReady) return;
    final state = _cubit.state;
    final major = [
      for (final train in state.trains) ...[?train.origin, ?train.destination],
    ];
    unawaited(
      map
          .setGeoJsonSource(
            'all-stations',
            stationsGeoJson(state.stations, major: major),
          )
          .catchError((Object e) => debugPrint('⚠️ Stations: $e')),
    );
  }

  void _onState(RealTimeTrackingState state) {
    _feedMotions(state);
    _entries = null;
    _drawSoon = true;
    if (_layersReady && !_loop.isActive) _loop.start();
  }

  /// Runs every tick of [_loop]: redraws the trains as often as they
  /// visibly move — every frame zoomed in on a fast train, about once a
  /// second when the whole country shows — and as the view moves.
  void _onFrame() {
    final map = _map;
    if (map == null || !_layersReady) return;
    final now = DateTime.now();
    final camera = map.cameraPosition;
    final interval = camera == null
        ? const Duration(milliseconds: 250)
        : redrawInterval(
            speedMps: _fastest,
            zoom: camera.zoom,
            latitude: camera.target.latitude,
          );
    // As often as the trains visibly move, but no more than the phone keeps
    // up with.
    if (_drawSoon ||
        _viewMoved(camera) ||
        now.difference(_lastDrawAt) >=
            (interval > _pacer.gap ? interval : _pacer.gap)) {
      _drawSoon = false;
      _draw(now);
    }
    if (_selectedId != null &&
        !_focusBusy &&
        now.difference(_lastFocusAt) >= const Duration(milliseconds: 33)) {
      _drawFocus(now);
    }
  }

  /// What of the map [camera] shows, and around it; null when the whole
  /// country does.
  _View? _viewOf(CameraPosition? camera) {
    if (camera == null || camera.zoom < _cullFromZoom) return null;
    final metersPerPx = metersPerPixel(camera.zoom, camera.target.latitude);
    // Tilted, the map shows far further towards the horizon.
    final reach = _screenDiagonal * (camera.tilt > 10 ? 2.6 : 0.8);
    return _View(camera.target, camera.zoom, metersPerPx * reach);
  }

  /// Whether the view has moved far enough from what the last update
  /// covered that trains coming into it must be sent.
  bool _viewMoved(CameraPosition? camera) {
    final last = _view;
    final culls = camera != null && camera.zoom >= _cullFromZoom;
    if (last == null) return culls;
    if (!culls) return true;
    return (camera.zoom - last.zoom).abs() > 0.4 ||
        haversineMeters(camera.target, last.center) > last.reachM * 0.25;
  }

  /// Moves every train on to [now]: those in [view] each time, the rest
  /// about once a second, which is all a train off the screen needs.
  void _step(DateTime now, _View? view) {
    var fastest = 0.0;
    for (final MapEntry(key: id, value: motion) in _motions.entries) {
      final last = _poses[id];
      final at = _posedAt[id];
      if (view != null &&
          last != null &&
          at != null &&
          !view.holds(last.point) &&
          now.difference(at) < const Duration(seconds: 1)) {
        continue;
      }
      final pose = motion.poseAt(now);
      if (pose == null) continue;
      _poses[id] = pose;
      _posedAt[id] = now;
      if (pose.speedMps > fastest && (view == null || view.holds(pose.point))) {
        fastest = pose.speedMps;
      }
    }
    _fastest = fastest;
  }

  /// [_onMap] as last worked out, again once it is a few seconds old.
  List<_OnMap> _onMapNow(DateTime now) {
    final entries = _entries;
    if (entries != null &&
        now.difference(_entriesAt) < const Duration(seconds: 5)) {
      return entries;
    }
    _labels.clear();
    _entriesAt = now;
    return _entries = _onMap(_cubit.state, now);
  }

  void _draw([DateTime? at]) {
    final map = _map;
    if (map == null || !_layersReady || !mounted) return;
    if (_drawBusy) {
      _drawAgain = true;
      return;
    }
    final now = at ?? DateTime.now();
    final view = _viewOf(map.cameraPosition);
    _step(now, view);
    _view = view;
    _lastDrawAt = now;
    _drawBusy = true;
    final sent = DateTime.now();
    map
        .setGeoJsonSource('fleet', _fleetCollection(now, view))
        .catchError((Object e) => debugPrint('⚠️ Fleet markers: $e'))
        .whenComplete(() {
          _drawBusy = false;
          if (_pacer.took(DateTime.now().difference(sent))) _applyTier();
          if (_drawAgain && mounted) {
            _drawAgain = false;
            _draw();
          }
        });
    _draw3d(now);
  }

  /// The 3D trains, for those near the middle of the map once zoomed in.
  /// On a phone that can't keep up, the 3D trains give way to flat ones
  /// close up; they come back when it can.
  void _applyTier() {
    final map = _map;
    if (map == null || !_layersReady) return;
    final flat = !_pacer.draws3d;
    unawaited(
      Future.wait([
        map.setLayerVisibility('fleet-3d', !flat),
        map.setLayerVisibility('fleet-train-near', flat),
      ]).catchError((Object e) {
        debugPrint('⚠️ Fleet layers: $e');
        return <void>[];
      }),
    );
  }

  void _draw3d(DateTime now) {
    final map = _map;
    final camera = map?.cameraPosition;
    if (map == null || camera == null || _draw3dBusy || !_pacer.draws3d) {
      return;
    }
    if (camera.zoom < _train3dZoom - 0.5) return;
    final metersPerPx = metersPerPixel(camera.zoom, camera.target.latitude);
    final reachM = metersPerPx * 1500;
    final state = _cubit.state;
    final near = [
      for (final e in _onMapNow(now))
        if (haversineMeters(
              _poses[e.train.id]?.point ?? e.position.position,
              camera.target,
            ) <=
            reachM)
          e,
    ];
    // A few trains close up in every detail; more, or a phone with less to
    // spare, in less.
    final scene = Train3dScene(
      metersPerPx: metersPerPx,
      detail: near.length <= 3 && _pacer.tier == MapTier.smooth
          ? Train3dDetail.full
          : Train3dDetail.low,
    );
    for (final e in near) {
      final pose = _poses[e.train.id];
      scene.add(
        head: pose?.point ?? e.position.position,
        heading: pose?.heading ?? e.position.course,
        path: pose?.along == null ? null : state.pathOf(e.train.id),
        headAlong: pose?.along,
        reversed: pose?.reversed ?? false,
        coaches: 2,
        palette: _kindOf(e.status) == 'old'
            ? Train3dPalette.faded
            : Train3dPalette.pakistanRailways,
      );
    }
    _draw3dBusy = true;
    map
        .setGeoJsonSource('fleet-3d', scene.toGeoJson())
        .catchError((Object e) => debugPrint('⚠️ Fleet 3D: $e'))
        .whenComplete(() => _draw3dBusy = false);
  }

  void _drawFocus(DateTime now) {
    final map = _map;
    if (map == null || !_layersReady) return;
    _lastFocusAt = now;
    final id = _selectedId;
    final point = id == null ? null : _poses[id]?.point;
    final pulse = (now.millisecondsSinceEpoch % 1800) / 1800;
    _focusBusy = true;
    map
        .setGeoJsonSource(
          'fleet-focus',
          point == null
              ? _emptyCollection
              : {
                  'type': 'FeatureCollection',
                  'features': [
                    {
                      'type': 'Feature',
                      'id': 'focus',
                      'properties': {
                        'r': 16 + 30 * pulse,
                        'o': 0.5 * (1 - pulse),
                      },
                      'geometry': {
                        'type': 'Point',
                        'coordinates': [point.longitude, point.latitude],
                      },
                    },
                  ],
                },
        )
        .catchError((Object e) => debugPrint('⚠️ Fleet focus: $e'))
        .whenComplete(() => _focusBusy = false);
  }

  /// Trains with a position that pass the filter: moving first, then
  /// stopped, then the rest, each by number.
  List<_OnMap> _onMap(RealTimeTrackingState state, DateTime now) {
    final list = <_OnMap>[];
    for (final train in state.trains) {
      final position = state.positionOf(train);
      if (position == null) continue;
      final status = liveStatusOf(
        train,
        position,
        state.linkOf(train),
        now: now,
        palette: _palette,
        listeningSince: state.listeningSinceOf(train),
        openedAt: state.openedAtOf(train),
      );
      if (!_filter.passes(train, status) || !train.matches(_query)) continue;
      list.add((train: train, position: position, status: status));
    }
    int rank(_OnMap e) => switch (_kindOf(e.status)) {
      'moving' => 0,
      'stopped' => 1,
      _ => 2,
    };
    list.sort((a, b) {
      final byKind = rank(a).compareTo(rank(b));
      if (byKind != 0) return byKind;
      return (a.train.number ?? 1 << 30).compareTo(b.train.number ?? 1 << 30);
    });
    return list;
  }

  static String _kindOf(LiveStatus status) => switch (status.kind) {
    TrainLiveStatus.moving => 'moving',
    TrainLiveStatus.stopped => 'stopped',
    _ => 'old',
  };

  /// The trains for the map's `fleet` source: those in [view], or every
  /// one when it is null.
  Map<String, dynamic> _fleetCollection(DateTime now, _View? view) {
    final state = _cubit.state;
    String label(LiveTrain train) => _labels[train.id] ??= () {
      final code = train.code.isEmpty ? train.displayName : train.code;
      // Two runs of one train: each says its day.
      return state.hasOtherRuns(train)
          ? '$code · ${runDayLabel(train, now)}'
          : code;
    }();

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final e in _onMapNow(now))
          if ((_poses[e.train.id]?.point ?? e.position.position)
              case final point when view == null || view.holds(point))
            {
              'type': 'Feature',
              'id': e.train.id,
              'properties': {
                'kind': _kindOf(e.status),
                'course': _round(
                  _poses[e.train.id]?.heading ?? e.position.course,
                  10,
                ),
                'label': label(e.train),
                'z':
                    switch (_kindOf(e.status)) {
                      'moving' => 3,
                      'stopped' => 2,
                      _ => 1,
                    } +
                    (e.train.id == _selectedId ? 10 : 0),
              },
              'geometry': {
                'type': 'Point',
                // To about ten centimetres, which is all a marker needs.
                'coordinates': [
                  _round(point.longitude, 1e6),
                  _round(point.latitude, 1e6),
                ],
              },
            },
      ],
    };
  }

  static double _round(double value, double per) =>
      (value * per).roundToDouble() / per;

  // ─── Selection ────────────────────────────────────────────────────────

  void _onFeatureTapped(
    math.Point<double> point,
    LatLng coordinates,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    const tappable = {'fleet-halo', 'fleet-train', 'fleet-train-near'};
    if (!tappable.contains(layerId)) return;
    _select(id);
  }

  void _select(String? id, {bool fly = false}) {
    if (!mounted) return;
    if (id != _selectedId) {
      setState(() => _selectedId = id);
      _entries = null;
      _draw();
      if (id == null) {
        _drawFocus(DateTime.now());
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showCard(id));
      }
    }
    if (fly && id != null) unawaited(_flyTo(id));
  }

  void _showCard(String id) {
    if (!_carousel.hasClients) return;
    final index = _onMap(
      _cubit.state,
      DateTime.now(),
    ).indexWhere((e) => e.train.id == id);
    if (index < 0) return;
    final offset = (index * (_cardWidth + _cardGap)).clamp(
      0.0,
      _carousel.position.maxScrollExtent,
    );
    unawaited(
      _carousel.animateTo(
        offset,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _setFilter(TrainFilter filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    _entries = null;
    final selected = _selectedId;
    if (selected != null &&
        !_onMap(
          _cubit.state,
          DateTime.now(),
        ).any((e) => e.train.id == selected)) {
      _select(null);
    }
    _draw();
  }

  void _setQuery(String query) {
    if (query == _query) return;
    setState(() => _query = query);
    _entries = null;
    final selected = _selectedId;
    final found = _onMap(_cubit.state, DateTime.now());
    if (selected != null && !found.any((e) => e.train.id == selected)) {
      _select(null);
    }
    _draw();
    // One train found: go to it.
    if (query.trim().isNotEmpty && found.length == 1) {
      _select(found.single.train.id, fly: true);
    }
  }

  /// The keyboard's search key: go to the first train found.
  void _submitQuery(String query) {
    final found = _onMap(_cubit.state, DateTime.now());
    if (query.trim().isEmpty || found.isEmpty) return;
    _select(found.first.train.id, fly: true);
  }

  /// A suggestion picked: the search names the train, and the map goes to
  /// it.
  void _pickSuggestion(LiveTrain train) {
    final name = train.name.trim().isNotEmpty
        ? train.name.trim()
        : '${train.number ?? ''}';
    _search.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    _searchFocus.unfocus();
    _setQuery(name);
    _select(train.id, fly: true);
  }

  void _openTrain(LiveTrain train) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: TrainLiveMapView(train: train),
        ),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────

  double _carouselHeight(BuildContext context) =>
      128 + 30 * (MediaQuery.textScalerOf(context).scale(1) - 1);

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final media = MediaQuery.of(context);
    return MultiBlocListener(
      listeners: [
        BlocListener<RealTimeTrackingCubit, RealTimeTrackingState>(
          listenWhen: (a, b) =>
              !identical(a.positions, b.positions) ||
              !identical(a.trains, b.trains) ||
              !identical(a.links, b.links),
          listener: (_, state) => _onState(state),
        ),
        BlocListener<RealTimeTrackingCubit, RealTimeTrackingState>(
          listenWhen: (a, b) =>
              !identical(a.stations, b.stations) ||
              !identical(a.trains, b.trains),
          listener: (_, _) => _drawStations(),
        ),
      ],
      child: Scaffold(
        backgroundColor: palette.bg,
        // Resizing the map's platform view while a route animates crashes
        // the Android embedder.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: MapLibreMap(
                key: ValueKey(_mapKey),
                styleString: mapStyleOf(palette),
                initialCameraPosition: const CameraPosition(
                  target: _pakistanCenter,
                  zoom: 3.6,
                ),
                minMaxZoomPreference: const MinMaxZoomPreference(3.5, 18),
                trackCameraPosition: true,
                compassEnabled: true,
                compassViewPosition: CompassViewPosition.topRight,
                compassViewMargins: math.Point(
                  20,
                  media.padding.top + 214 + _searchHeight,
                ),
                attributionButtonPosition: AttributionButtonPosition.bottomLeft,
                attributionButtonMargins: math.Point(
                  10,
                  media.padding.bottom + _carouselHeight(context) + 52,
                ),
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                onMapCreated: (c) {
                  _map = c;
                  c.onFeatureTapped.add(_onFeatureTapped);
                },
                onStyleLoadedCallback: _onStyleLoaded,
                onMapClick: (_, _) => _select(null),
                // The 3D trains are sized for the zoom they were drawn at,
                // and the trains in view are those around where it stopped.
                onCameraIdle: () => _drawSoon = true,
              ),
            ),
            Positioned.fill(
              child: MapCover(
                visible: !_shown,
                slow: _slow,
                onRetry: _retryMap,
              ),
            ),
            BlocBuilder<RealTimeTrackingCubit, RealTimeTrackingState>(
              buildWhen: (a, b) =>
                  !identical(a.positions, b.positions) ||
                  !identical(a.trains, b.trains) ||
                  !identical(a.links, b.links) ||
                  !identical(a.listeningSince, b.listeningSince),
              builder: (context, state) => TimeTicker(
                every: const Duration(seconds: 15),
                builder: (context, now) => _overlays(context, state, now),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlays(
    BuildContext context,
    RealTimeTrackingState state,
    DateTime now,
  ) {
    final media = MediaQuery.of(context);
    final statuses = liveStatuses(state, now, TrackPalette.of(context));
    final onMap = _onMap(state, now);
    final withDevice = state.trains.where((t) => t.hasDevice).toList();
    final located = withDevice.where((t) => state.positionOf(t) != null).length;
    final moving = statuses.values
        .where((s) => s.kind == TrainLiveStatus.moving)
        .length;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: _Header(
                    located: located,
                    moving: moving,
                    waiting: withDevice.length - located,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: _MapSearchField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: _setQuery,
                    onSubmitted: _submitQuery,
                  ),
                ),
                // While typing: the trains that match, to pick from.
                ListenableBuilder(
                  listenable: _searchFocus,
                  builder: (context, _) => AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _searchFocus.hasFocus && _query.trim().isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                            child: _Suggestions(
                              query: _query,
                              trains: [
                                for (final t in state.trains)
                                  if (state.positionOf(t) != null) t,
                              ],
                              statuses: statuses,
                              onPick: _pickSuggestion,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ),
                TrainFilterBar(
                  selected: _filter,
                  counts: filterCounts([
                    for (final t in state.trains)
                      if (state.positionOf(t) != null && t.matches(_query)) t,
                  ], statuses),
                  onSelected: _setFilter,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 14,
          // Clear of the filters, which grow with the text size.
          top:
              media.padding.top +
              150 +
              _searchHeight +
              14 * (MediaQuery.textScalerOf(context).scale(1) - 1),
          child: MapIconButton(
            icon: Icons.zoom_out_map_rounded,
            tooltip: 'Whole country',
            onTap: () {
              _select(null);
              unawaited(_fitPakistan());
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.padding.bottom + 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: _Legend(),
                ),
                SizedBox(
                  height: _carouselHeight(context),
                  child: onMap.isEmpty
                      ? _EmptyCarousel(
                          waiting: withDevice.length - located,
                          filtered: located > 0,
                        )
                      : ListView.separated(
                          controller: _carousel,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          clipBehavior: Clip.none,
                          itemCount: onMap.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: _cardGap),
                          itemBuilder: (context, i) => _FleetCard(
                            key: ValueKey(onMap[i].train.id),
                            entry: onMap[i],
                            now: now,
                            width: _cardWidth,
                            selected: onMap[i].train.id == _selectedId,
                            onTap: () => _select(onMap[i].train.id, fly: true),
                            onOpen: () => _openTrain(onMap[i].train),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Moves a drawn train smoothly to each new report.
class _Header extends StatelessWidget {
  final int located;
  final int moving;
  final int waiting;

  const _Header({
    required this.located,
    required this.moving,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final subtitle = [
      '$located on map',
      if (moving > 0) '$moving moving',
      if (waiting > 0) '$waiting waiting',
    ].join(' · ');
    return Row(
      children: [
        const AppBackButton(),
        const SizedBox(width: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: palette.shadow(1.4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              // A solid panel: on iOS a blur over the map's native view is redone
              // every frame, which is slow and has crashed.
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                decoration: BoxDecoration(
                  color: palette.card.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: palette.card.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.map_rounded,
                        color: palette.g2,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All trains',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: palette.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LiveDot(
                      color: palette.g2,
                      // Still over the map on iOS: an animation above it
                      // makes the map recomposite every frame.
                      pulsing: moving > 0 && !lightMaps,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: palette.halo, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: palette.ink,
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        boxShadow: palette.shadow(0.8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          item(palette.g2, 'Moving'),
          item(palette.amber, 'Stopped'),
          item(palette.grey, 'Offline'),
        ],
      ),
    );
  }
}

class _FleetCard extends StatelessWidget {
  final _OnMap entry;
  final DateTime now;
  final double width;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpen;

  const _FleetCard({
    super.key,
    required this.entry,
    required this.now,
    required this.width,
    required this.selected,
    required this.onTap,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final train = entry.train;
    final position = entry.position;
    final route = [
      train.origin?.code ?? train.origin?.name,
      train.destination?.code ?? train.destination?.name,
    ].whereType<String>().join(' → ');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? palette.g2 : palette.card,
          width: 2,
        ),
        boxShadow: palette.shadow(selected ? 2.4 : 1.4),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrainNumberBadge(train: train, size: 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            train.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: palette.ink,
                            ),
                          ),
                          Row(
                            children: [
                              if (route.isNotEmpty)
                                Flexible(
                                  child: Text(
                                    route,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: palette.mute,
                                    ),
                                  ),
                                ),
                              // Another day's run is on the map too.
                              if (context.select(
                                (RealTimeTrackingCubit c) =>
                                    c.state.hasOtherRuns(train),
                              )) ...[
                                const SizedBox(width: 6),
                                RunDateChip(run: train),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Track this train',
                      child: Material(
                        color: palette.g2,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onOpen,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: palette.onAccent,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                StatusPill(status: entry.status, dense: true),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 13, color: palette.mute),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        position.shortAddress ?? 'Location received',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: palette.mute,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCarousel extends StatelessWidget {
  final int waiting;

  /// Trains are on the map, but none passes the filter.
  final bool filtered;

  const _EmptyCarousel({required this.waiting, required this.filtered});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: palette.shadow(1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.soft,
                shape: BoxShape.circle,
              ),
              child: filtered
                  ? Icon(Icons.filter_alt_off_rounded, color: palette.g2)
                  : Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: palette.g2,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filtered ? 'No trains match' : 'Finding the trains…',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    filtered
                        ? 'Try another search or filter to see more trains.'
                        : 'Waiting for the first reports from $waiting GPS '
                              'devices.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: palette.mute,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Finds trains on the map by name, number or station, frosted like the
/// header above it.
class _MapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _MapSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: palette.shadow(1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: palette.card.withValues(alpha: 0.97),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search train, number or station',
                hintStyle: TextStyle(color: palette.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: palette.mute),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: palette.mute),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                          FocusScope.of(context).unfocus();
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The trains on the map that match [query], best first: those whose
/// number or name starts with it, then the rest. The part that matches is
/// bold.
class _Suggestions extends StatelessWidget {
  final String query;
  final List<LiveTrain> trains;
  final Map<String, LiveStatus> statuses;
  final ValueChanged<LiveTrain> onPick;

  const _Suggestions({
    required this.query,
    required this.trains,
    required this.statuses,
    required this.onPick,
  });

  /// The most suggestions shown.
  static const int _shown = 5;

  static int _rank(LiveTrain train, String q) {
    final number = '${train.number ?? ''}';
    final name = train.name.toLowerCase();
    if (number == q) return 0;
    if (number.startsWith(q)) return 1;
    if (name.startsWith(q)) return 2;
    if (name.split(' ').any((word) => word.startsWith(q))) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final q = query.trim().toLowerCase();
    final found = trains.where((t) => t.matches(q)).toList()
      ..sort((a, b) => _rank(a, q).compareTo(_rank(b, q)));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: palette.shadow(1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: found.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No train on the map matches',
                    style: TextStyle(
                      color: palette.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, train) in found.take(_shown).indexed) ...[
                      if (i > 0) Divider(height: 1, color: palette.line),
                      _Suggestion(
                        train: train,
                        query: q,
                        status: statuses[train.id],
                        onTap: () => onPick(train),
                      ),
                    ],
                    if (found.length > _shown)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Text(
                          '${found.length - _shown} more on the map',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.mute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  final LiveTrain train;
  final String query;
  final LiveStatus? status;
  final VoidCallback onTap;

  const _Suggestion({
    required this.train,
    required this.query,
    required this.status,
    required this.onTap,
  });

  /// [text] with the first [query] in it bold.
  List<TextSpan> _marked(String text, TextStyle bold) {
    final at = query.isEmpty ? -1 : text.toLowerCase().indexOf(query);
    if (at < 0) return [TextSpan(text: text)];
    return [
      TextSpan(text: text.substring(0, at)),
      TextSpan(text: text.substring(at, at + query.length), style: bold),
      TextSpan(text: text.substring(at + query.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final status = this.status;
    final bold = TextStyle(fontWeight: FontWeight.w900, color: palette.g1);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            TrainNumberBadge(train: train, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(children: _marked(train.name, bold)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ),
                      // Two runs of the train out at once: say which day's.
                      if (context.select(
                        (RealTimeTrackingCubit c) =>
                            c.state.hasOtherRuns(train),
                      )) ...[
                        const SizedBox(width: 6),
                        RunDateChip(run: train),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: _marked(train.routeLabel, bold)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: palette.mute,
                    ),
                  ),
                ],
              ),
            ),
            if (status != null) ...[
              const SizedBox(width: 8),
              StatusPill(status: status, dense: true),
            ],
          ],
        ),
      ),
    );
  }
}

/// What of the map an update covers: [reachM] around [center], at [zoom].
class _View {
  _View(this.center, this.zoom, this.reachM)
    : _perLng = 111320 * math.cos(center.latitude * math.pi / 180);

  final LatLng center;
  final double zoom;
  final double reachM;
  final double _perLng;

  /// Whether [point] is within reach; quickly, on a flat map, which at
  /// these distances is near enough.
  bool holds(LatLng point) {
    final dy = (point.latitude - center.latitude) * 110574;
    final dx = (point.longitude - center.longitude) * _perLng;
    return dx * dx + dy * dy <= reachM * reachM;
  }
}
