import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/maps/map_loop.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/map_pacer.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';
import 'package:railway_hrms/modules/tracking/services/train_motion.dart';
import 'package:railway_hrms/modules/tracking/widgets/map_cover.dart';
import 'package:railway_hrms/modules/tracking/widgets/map_layers.dart';
import 'package:railway_hrms/modules/tracking/widgets/run_picker.dart';
import 'package:railway_hrms/modules/tracking/widgets/speed_gauge.dart';
import 'package:railway_hrms/modules/tracking/widgets/station_strip.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_3d.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_sprite.dart';

const LatLng _pakistanCenter = LatLng(30.3753, 69.3451);
const Map<String, dynamic> _emptyCollection = {
  'type': 'FeatureCollection',
  'features': <Object>[],
};

/// One train on the map — live position, rail route and stations — with a
/// draggable sheet of journey details. Expects the [RealTimeTrackingCubit]
/// of the list it was opened from.
class TrainLiveMapView extends StatefulWidget {
  final LiveTrain train;

  const TrainLiveMapView({super.key, required this.train});

  @override
  State<TrainLiveMapView> createState() => _TrainLiveMapViewState();
}

class _TrainLiveMapViewState extends State<TrainLiveMapView> {
  static const double _sheetInitial = 0.38;
  static const double _sheetMin = 0.17;

  /// The chase camera that follows the train: close, tilted and turned to
  /// the train's heading, so the 3D buildings show.
  static const double _chaseZoom = 15.4;
  static const double _chaseTilt = 55;

  /// The chase camera looks this far off the train's heading, so the 3D
  /// train shows its side rather than just its roofs — the side MapLibre's
  /// default light (from the lower left of the screen) falls on.
  static const double _chaseAngle = 30;

  /// From this zoom the train is drawn in 3D instead of as a flat sprite.
  static const double _train3dZoom = 0;

  /// How long the map may take to load before the cover says so.
  static const Duration _slowAfter = Duration(seconds: 12);

  late final RealTimeTrackingCubit _cubit = context
      .read<RealTimeTrackingCubit>();
  final _sheet = DraggableScrollableController();
  final _motion = TrainMotion();

  /// Keeps the map's updates within what the phone can draw.
  final _pacer = MapPacer.forPhone();

  /// Moves the train on the map as often as the pacer allows, without
  /// having Flutter redraw the screen around it.
  late final MapLoop _loop = MapLoop(_onFrame, interval: () => _pacer.gap);

  MapLibreMapController? _map;
  bool _layersReady = false;

  /// The map is up with the app's layers on it; the cover has lifted.
  bool _shown = false;
  bool _slow = false;
  Timer? _slowTimer;

  /// Bumped to build the map afresh after it failed to load.
  int _mapKey = 0;

  /// Camera follows the train.
  bool _follow = false;

  /// Until the user moves the map, the camera frames the whole journey
  /// while the train's position is unknown, then swoops down to follow it.
  bool _auto = true;

  /// The camera is swooping onto the train; the frame loop leaves it be.
  bool _swooping = false;

  /// A touch on the map let go of the train; once the hand has been off
  /// the map for [_refollowAfter], the camera goes back to the train, so it
  /// never drives off an empty map. Following turned off on purpose, as by
  /// the follow key or the whole-journey view, stays off.
  bool _refollow = false;
  Timer? _refollowTimer;

  /// A finger is on the map.
  bool _touching = false;

  /// Checks in a row that found the train off the screen.
  int _offScreen = 0;
  bool _checkingView = false;
  static const Duration _refollowAfter = Duration(seconds: 6);

  /// The chase camera's turn, eased more slowly than the train's own so
  /// small kinks in the track don't swing the whole map.
  double? _cameraBearing;

  RoutePath? _drawnPath;
  RoutePieces? _pieces;
  int _donePiece = -1;
  double _headAt = -1;
  DateTime _lastHeadAt = DateTime(0);
  List<double?>? _drawnStationKm;
  List<RouteStop>? _drawnRouteStops;
  RouteFix? _drawnStationFix;
  TrainPosition? _drawnPosition;

  // One update of each kind on its way to the map at a time: the map takes
  // them as fast as it can, and a frame finding one still going skips it.
  bool _trainBusy = false;
  bool _train3dBusy = false;
  bool _cameraBusy = false;
  bool _headBusy = false;
  bool _piecesBusy = false;
  bool _drew3d = false;
  DateTime? _lastFrame;
  DateTime _lastStatusAt = DateTime(0);

  // What was last sent of each, so an update that would change nothing on
  // the map — a standing train, a camera already where it should be — is
  // not sent at all.
  LatLng? _sentTrainAt;
  double _sentTrainHeading = double.nan;
  bool? _sentLive;
  DateTime _sentTrainTime = DateTime(0);
  LatLng? _sent3dAt;
  double _sent3dHeading = double.nan;
  double _sent3dZoom = double.nan;
  bool? _sent3dLive;
  Train3dDetail? _sent3dDetail;
  LatLng? _sentCameraAt;
  double _sentCameraBearing = double.nan;
  bool _live = true;
  Timer? _insetsTimer;
  double _insetBottom = -1;

  LiveTrain get _train => widget.train;

  /// The colours the map is drawn in, kept from the last build so the map's
  /// own callbacks, which can come after the page has gone, never look them
  /// up.
  late TrackPalette _palette;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _palette = TrackPalette.of(context);
    // Covered by another screen, the map waits.
    _loop.visible = TickerMode.valuesOf(context).enabled;
  }

  @override
  void initState() {
    super.initState();
    _cubit.selectTrain(_train.id);
    // Followed from its first report, the last known one if the feed has
    // it already; till then the map shows the route.
    _follow = _cubit.state.positionOf(_train) != null;
    _slowTimer = Timer(_slowAfter, () {
      if (mounted && !_shown) setState(() => _slow = true);
    });
    _sheet.addListener(_onSheetMoved);
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _refollowTimer?.cancel();
    _insetsTimer?.cancel();
    _loop.dispose();
    _sheet.dispose();
    // Another run's map may have taken this one's place, and selected its
    // own train already.
    _cubit.clearSelection(trainId: _train.id);
    super.dispose();
  }

  // ─── Map setup ────────────────────────────────────────────────────────

  CameraPosition get _initialCamera {
    final known = _cubit.state.positionOf(_train);
    if (known != null) {
      return CameraPosition(
        target: known.position,
        zoom: _chaseZoom,
        // On iOS the plugin re-applies an initial tilt when the style
        // finishes loading, before the map view is laid out, and MapLibre
        // aborts the app. There the map opens flat and the chase camera
        // (started once the style loads) tilts it.
        tilt: lightMaps ? 0 : _chaseTilt,
        bearing: known.course + _chaseAngle,
      );
    }
    return CameraPosition(
      target: _train.origin?.position ?? _pakistanCenter,
      zoom: 5.2,
    );
  }

  void _retryMap() {
    _slowTimer?.cancel();
    _loop.stop();
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

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    try {
      await _addLayers(map);
    } catch (e) {
      debugPrint('⚠️ Tracking map layers: $e');
      return;
    }
    if (!mounted || !identical(map, _map)) return;
    _layersReady = true;
    _drawnPath = null;
    _pieces = null;
    _donePiece = -1;
    _headAt = -1;
    _drawnStationKm = null;
    _drawnRouteStops = null;
    _drawnStationFix = null;
    _drawnPosition = null;
    _insetBottom = -1;
    _forgetSent();
    // The rest of the network, faintly, around the train's own line.
    unawaited(
      addRailNetworkLayer(
        map,
        _palette,
        belowLayerId: 'route-casing',
        opacity: 0.3,
        maxzoom: 12,
      ).catchError((Object e) => debugPrint('⚠️ Rail network: $e')),
    );
    _applyInsets();
    await _sync(_cubit.state);
    if (!mounted) return;
    // The first frames draw the train; then the cover lifts off a map
    // that already has everything on it.
    if (!_loop.isActive && _cubit.state.positionOf(_train) != null) {
      _loop.start();
    }
    Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_shown) setState(() => _shown = true);
    });
  }

  Future<void> _addLayers(MapLibreMapController map) async {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final palette = _palette;
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
      await renderTrainSprite(TrainLivery.offline, dpr, headlights: false),
    );

    await map.addGeoJsonSource('route', _emptyCollection);
    await map.addGeoJsonSource('route-head', _emptyCollection);
    await map.addLineLayer(
      'route',
      'route-casing',
      LineLayerProperties(
        lineColor: mapHex(palette.halo),
        lineWidth: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          5,
          8,
          9,
          10,
          14,
          14,
        ],
        lineJoin: 'round',
        lineCap: 'round',
      ),
      enableInteraction: false,
    );
    // Zoomed out: one clean route line in official green across the entire track.
    await map.addLineLayer(
      'route',
      'route-line',
      LineLayerProperties(
        lineColor: mapHex(palette.g2),
        lineWidth: 5.0,
        lineJoin: 'round',
        lineCap: 'round',
      ),
      maxzoom: trackZoom,
      enableInteraction: false,
    );

    // Zoomed in: railway track (sleepers and rails) in official green.
    await map.addLineLayer(
      'route',
      'route-sleepers',
      trackSleepers(palette.g2),
      minzoom: trackZoom,
      enableInteraction: false,
    );
    await map.addLineLayer(
      'route',
      'route-rails',
      trackRails(palette.g1),
      minzoom: trackZoom,
      enableInteraction: false,
    );

    await map.addGeoJsonSource('stations', _emptyCollection);
    await map.addCircleLayer(
      'stations',
      'station-dot',
      CircleLayerProperties(
        circleRadius: [Expressions.get, 'radius'],
        circleColor: mapHex(palette.card),
        circleStrokeWidth: [Expressions.get, 'stroke'],
        circleStrokeColor: [Expressions.get, 'color'],
      ),
      enableInteraction: false,
    );
    await map.addSymbolLayer(
      'stations',
      'station-label',
      SymbolLayerProperties(
        textField: [Expressions.get, 'label'],
        textFont: ['Noto Sans Bold'],
        textSize: 12.0,
        textOffset: [0, 1.1],
        textAnchor: 'top',
        textColor: mapHex(palette.ink),
        textHaloColor: mapHex(palette.halo),
        textHaloWidth: 1.6,
        textOptional: true,
      ),
      enableInteraction: false,
    );

    await map.addGeoJsonSource('train', _emptyCollection);
    // Pulse spreading on the ground under a live train.
    await map.addCircleLayer(
      'train',
      'train-pulse',
      CircleLayerProperties(
        circleRadius: [Expressions.get, 'r'],
        circleOpacity: [Expressions.get, 'o'],
        circleColor: [
          Expressions.match,
          [Expressions.get, 'live'],
          1,
          mapHex(palette.g2),
          mapHex(palette.offline),
        ],
        circlePitchAlignment: 'map',
      ),
      enableInteraction: false,
    );
    // The train lies on the map, so a tilted camera shows it in perspective.
    await map.addSymbolLayer(
      'train',
      'train-icon',
      const SymbolLayerProperties(
        iconImage: [
          Expressions.match,
          [Expressions.get, 'live'],
          1,
          'train-live',
          'train-dim',
        ],
        iconSize: [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          4,
          0.55,
          9,
          0.75,
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
      ),
      maxzoom: _train3dZoom,
      enableInteraction: false,
    );
    // The flat train close up too, shown instead of the 3D one on a phone
    // that can't keep up with it.
    await map.addSymbolLayer(
      'train',
      'train-icon-near',
      const SymbolLayerProperties(
        iconImage: [
          Expressions.match,
          [Expressions.get, 'live'],
          1,
          'train-live',
          'train-dim',
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
        visibility: 'none',
      ),
      minzoom: _train3dZoom,
      enableInteraction: false,
    );
    // Zoomed in, the train stands up off the map in 3D.
    await map.addGeoJsonSource('train-3d', _emptyCollection);
    await map.addFillExtrusionLayer(
      'train-3d',
      'train-3d',
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

  // ─── Drawing state ────────────────────────────────────────────────────

  /// Brings the map up to [state]: the route when it changes, and each new
  /// report to the motion that moves the train between them. The train
  /// itself is drawn every frame by [_onFrame].
  Future<void> _sync(RealTimeTrackingState state) async {
    final map = _map;
    if (map == null || !_layersReady || !mounted) return;
    final path = state.path;
    final pathChanged = !identical(path, _drawnPath);
    if (pathChanged) {
      _drawnPath = path;
      _motion.setPath(path);
      _pieces = path == null || path.isEmpty ? null : RoutePieces(path);
      _donePiece = -1;
      _headAt = -1;
    }

    final position = state.positionOf(_train);
    final firstPosition = _drawnPosition == null && position != null;
    // Only what the train reported moves it: where, how fast and whether
    // it is standing, as the device said.
    if (position != null && position != _drawnPosition) {
      _drawnPosition = position;
      _motion.report(position, DateTime.now());
      if (!_loop.isActive) _loop.start();
      if (firstPosition && !_follow) setState(() => _follow = true);
    }

    try {
      if (pathChanged) {
        await map.setGeoJsonSource(
          'route',
          _pieces?.geoJson ?? _emptyCollection,
        );
        await map.setGeoJsonSource('route-head', _emptyCollection);
      }
      final fix = state.fix;
      if (pathChanged ||
          !identical(state.stationKm, _drawnStationKm) ||
          !identical(state.routeStops, _drawnRouteStops) ||
          !identical(fix, _drawnStationFix)) {
        _drawnStationKm = state.stationKm;
        _drawnRouteStops = state.routeStops;
        _drawnStationFix = fix;
        await map.setGeoJsonSource('stations', _stationCollection(state));
      }
    } catch (e) {
      debugPrint('⚠️ Tracking map update: $e');
    }

    if (!_auto || !mounted) return;
    if (firstPosition) {
      await _startFollow();
    } else if (pathChanged && !_follow) {
      await _frameJourney();
    }
  }

  /// Runs every tick of [_loop] while the train has a place: moves it,
  /// pulses the ring under it, keeps the chase camera on it and greys the
  /// route behind it. Each is one small update to the map, sent no faster
  /// than the map takes them, and only when it would change what shows.
  void _onFrame() {
    final map = _map;
    if (map == null || !_layersReady) return;
    final now = DateTime.now();
    final last = _lastFrame;
    final dt = last == null
        ? 0.0
        : (now.difference(last).inMicroseconds / 1e6).clamp(0.0, 0.25);
    _lastFrame = now;

    if (now.difference(_lastStatusAt) > const Duration(seconds: 1)) {
      _lastStatusAt = now;
      final s = _cubit.state;
      _live = liveStatusOf(
        _train,
        s.positionOf(_train),
        s.linkOf(_train),
        now: now,
        palette: _palette,
      ).isLive;
    }

    final pose = _motion.poseAt(now);
    if (pose == null) return;
    if (now.difference(_lastViewCheck) > const Duration(seconds: 1)) {
      _lastViewCheck = now;
      _keepInView(map, pose);
    }
    final zoom = map.cameraPosition?.zoom ?? _chaseZoom;
    // Moves smaller than a fraction of a pixel don't show.
    final stillM = metersPerPixel(zoom, pose.point.latitude) * 0.15;
    _drawTrain(map, pose, now, stillM);
    _drawTrain3d(map, pose, zoom, stillM);
    _chase(map, pose, dt.toDouble(), stillM);
    _drawProgress(map, pose, now);
  }

  DateTime _lastViewCheck = DateTime(0);

  /// The map moves with the train: one that has run off the screen, with
  /// no hand on the map, is followed again — the map never loses it.
  void _keepInView(MapLibreMapController map, TrainPose pose) {
    if (_follow || _swooping || _touching || _checkingView) {
      _offScreen = 0;
      return;
    }
    _checkingView = true;
    map
        .getVisibleRegion()
        .then((view) {
          if (!mounted) return;
          final p = pose.point;
          final inside =
              p.latitude >= view.southwest.latitude &&
              p.latitude <= view.northeast.latitude &&
              p.longitude >= view.southwest.longitude &&
              p.longitude <= view.northeast.longitude;
          _offScreen = inside ? 0 : _offScreen + 1;
          // Off it for two checks running: a moment, not a flicker.
          if (_offScreen >= 2 && !_follow && !_touching) {
            _offScreen = 0;
            _refollow = false;
            _refollowTimer?.cancel();
            unawaited(_startFollow());
          }
        })
        .catchError((Object e) => debugPrint('⚠️ Map view: $e'))
        .whenComplete(() => _checkingView = false);
  }

  /// Everything is sent afresh, as onto a map just loaded.
  void _forgetSent() {
    _sentTrainAt = null;
    _sent3dAt = null;
    _sent3dZoom = double.nan;
    _sentCameraAt = null;
    _drew3d = false;
  }

  static bool _near(LatLng? a, LatLng b, double meters) =>
      a != null && haversineMeters(a, b) <= meters;

  static bool _sameAngle(double a, double b, double degrees) =>
      !a.isNaN && _turn(a - b).abs() <= degrees;

  /// The pulse is a decoration: drawn as often as the app's other loops,
  /// fewer times a second on a phone that draws lite.
  static Duration get _pulseGap => AppPerformance.lite
      ? const Duration(milliseconds: 50)
      : Duration(microseconds: 1000000 ~/ AppPerformance.loopFps);

  void _drawTrain(
    MapLibreMapController map,
    TrainPose pose,
    DateTime now,
    double stillM,
  ) {
    if (_trainBusy) return;
    final moved =
        !_near(_sentTrainAt, pose.point, stillM) ||
        !_sameAngle(_sentTrainHeading, pose.heading, 0.3) ||
        _sentLive != _live;
    if (!moved && now.difference(_sentTrainTime) < _pulseGap) return;
    _trainBusy = true;
    _sentTrainAt = pose.point;
    _sentTrainHeading = pose.heading;
    _sentLive = _live;
    _sentTrainTime = now;
    final pulse = (now.millisecondsSinceEpoch % 2200) / 2200;
    final sent = DateTime.now();
    map
        .setGeoJsonSource('train', _trainCollection(pose, pulse))
        .catchError((Object e) => debugPrint('⚠️ Train marker: $e'))
        .whenComplete(() {
          _trainBusy = false;
          if (_pacer.took(DateTime.now().difference(sent))) _applyTier();
        });
  }

  /// The train stays in 3D whatever the phone: only its detail follows
  /// the pace the map keeps (see [_drawTrain3d]).
  void _applyTier() {}

  void _drawTrain3d(
    MapLibreMapController map,
    TrainPose pose,
    double zoom,
    double stillM,
  ) {
    // Always in 3D, on every phone: one short of frames gets a simpler
    // model, never a flat one.
    if (_train3dBusy) return;
    final near = zoom >= _train3dZoom - 0.5;
    // Zoomed out the layer hides; it is emptied once, not every frame.
    if (!near && !_drew3d) return;
    // A phone with frames to spare gets every detail of the train.
    final detail = _pacer.tier == MapTier.smooth
        ? Train3dDetail.full
        : Train3dDetail.low;
    // Sized for the zoom, so drawn again as it changes; otherwise only
    // when the train moves or turns.
    if (near &&
        _drew3d &&
        _near(_sent3dAt, pose.point, stillM) &&
        _sameAngle(_sent3dHeading, pose.heading, 0.2) &&
        (zoom - _sent3dZoom).abs() < 0.01 &&
        _sent3dLive == _live &&
        _sent3dDetail == detail) {
      return;
    }
    _train3dBusy = true;
    _drew3d = near;
    _sent3dAt = pose.point;
    _sent3dHeading = pose.heading;
    _sent3dZoom = zoom;
    _sent3dLive = _live;
    _sent3dDetail = detail;
    map
        .setGeoJsonSource(
          'train-3d',
          near
              ? train3dCollection(
                  head: pose.point,
                  heading: pose.heading,
                  metersPerPx: metersPerPixel(zoom, pose.point.latitude),
                  path: _drawnPath,
                  headAlong: pose.along,
                  reversed: pose.reversed,
                  palette: _live
                      ? Train3dPalette.pakistanRailways
                      : Train3dPalette.offline,
                  detail: detail,
                )
              : _emptyCollection,
        )
        .catchError((Object e) => debugPrint('⚠️ 3D train: $e'))
        .whenComplete(() => _train3dBusy = false);
  }

  /// Keeps the chase camera on the train, moved with it every tick rather
  /// than eased after it once a second, so neither ever jerks; a camera
  /// already on a standing train is left be.
  void _chase(
    MapLibreMapController map,
    TrainPose pose,
    double dt,
    double stillM,
  ) {
    if (!_follow || _swooping || _cameraBusy) return;
    final target = pose.heading + _chaseAngle;
    final bearing = _cameraBearing;
    _cameraBearing = bearing == null || dt == 0
        ? target
        : bearing + _turn(target - bearing) * (1 - math.exp(-dt / 1.2));
    if (_near(_sentCameraAt, pose.point, stillM) &&
        _sameAngle(_sentCameraBearing, _cameraBearing!, 0.05)) {
      return;
    }
    _sentCameraAt = pose.point;
    _sentCameraBearing = _cameraBearing!;
    _cameraBusy = true;
    map
        .moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: pose.point,
              zoom: _chaseZoom,
              tilt: _chaseTilt,
              bearing: _cameraBearing!,
            ),
          ),
        )
        .catchError((Object e) {
          debugPrint('⚠️ Chase camera: $e');
          return null;
        })
        .whenComplete(() => _cameraBusy = false);
  }

  /// [degrees] folded into -180…180.
  static double _turn(double degrees) => (degrees + 540) % 360 - 180;

  /// Greys the route behind the train: the pieces it has passed by their
  /// layers' filters when it reaches another, the piece it is on by a short
  /// line of its own.
  void _drawProgress(MapLibreMapController map, TrainPose pose, DateTime now) {
    final pieces = _pieces;
    final along = pose.along;
    if (pieces == null || along == null) return;
    final piece = pieces.pieceAt(along);
    if (piece != _donePiece && !_piecesBusy) {
      _piecesBusy = true;
      Future.wait([
            for (final (id, done) in const [
              ('route-line-done', true),
              ('route-line', false),
              ('route-rails-done', true),
              ('route-rails', false),
            ])
              map.setLayerFilter(id, RoutePieces.filter(piece, done: done)),
          ])
          .then((_) => _donePiece = piece)
          .catchError((Object e) {
            debugPrint('⚠️ Route progress: $e');
            return piece;
          })
          .whenComplete(() => _piecesBusy = false);
    }
    if (_headBusy ||
        (along - _headAt).abs() < 1 ||
        now.difference(_lastHeadAt) < const Duration(milliseconds: 90)) {
      return;
    }
    _headBusy = true;
    _headAt = along;
    _lastHeadAt = now;
    map
        .setGeoJsonSource('route-head', pieces.headGeoJson(along))
        .catchError((Object e) => debugPrint('⚠️ Route head: $e'))
        .whenComplete(() => _headBusy = false);
  }

  Map<String, dynamic> _trainCollection(TrainPose pose, double pulse) => {
    'type': 'FeatureCollection',
    'features': [
      {
        'type': 'Feature',
        'id': 'train',
        'properties': {
          'course': pose.heading,
          'live': _live ? 1 : 0,
          'r': 14 + 34 * pulse,
          'o': (_live ? 0.42 : 0.2) * (1 - pulse),
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [pose.point.longitude, pose.point.latitude],
        },
      },
    ],
  };

  Map<String, dynamic> _stationCollection(RealTimeTrackingState state) {
    final journey = _train.journey;
    final passed = _passedFlags(_train, state);
    final next = _nextStop(state);
    final palette = _palette;
    final features = <Map<String, dynamic>>[];
    Map<String, dynamic> feature(
      String id,
      LatLng at, {
      required String label,
      required String color,
      required double radius,
      required double stroke,
    }) => {
      'type': 'Feature',
      'id': id,
      'properties': {
        'label': label,
        'color': color,
        'radius': radius,
        'stroke': stroke,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [at.longitude, at.latitude],
      },
    };
    var nextShown = false;
    for (var i = 0; i < journey.length; i++) {
      final station = journey[i];
      final position = station.position;
      if (position == null) continue;
      if (next != null && next.station.isSameStation(station)) {
        nextShown = true;
        features.add(
          feature(
            's$i',
            position,
            label: 'Next · ${station.name}',
            color: mapHex(palette.g1),
            radius: 8,
            stroke: 4,
          ),
        );
        continue;
      }
      final isEnd = i == 0 || i == journey.length - 1;
      features.add(
        feature(
          's$i',
          position,
          label: station.name,
          color: mapHex(
            passed[i]
                ? palette.grey
                : i == 0
                ? palette.g1
                : i == journey.length - 1
                ? palette.red
                : palette.g2,
          ),
          radius: isEnd ? 8 : 5,
          stroke: isEnd ? 3.5 : 2.5,
        ),
      );
    }
    // The next station is often one the train only passes.
    final nextAt = next?.station.position;
    if (next != null && !nextShown && nextAt != null) {
      features.add(
        feature(
          'next',
          nextAt,
          label: 'Next · ${next.station.name}',
          color: mapHex(palette.g1),
          radius: 7,
          stroke: 4,
        ),
      );
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// The next station ahead of the train, once its place on the route is
  /// known.
  RouteStop? _nextStop(RealTimeTrackingState state) {
    final fix = state.fix;
    if (fix == null || state.positionOf(_train) == null) return null;
    final stops = _stripStops(_train, state);
    final i = nextStopIndex(stops, fix.alongM / 1000);
    return i == null ? null : stops[i];
  }

  // ─── Camera ───────────────────────────────────────────────────────────

  double get _sheetFraction => _sheet.isAttached ? _sheet.size : _sheetInitial;

  void _onSheetMoved() {
    // Once the sheet comes to rest, the map's middle moves above it.
    _insetsTimer?.cancel();
    _insetsTimer = Timer(const Duration(milliseconds: 160), _applyInsets);
  }

  /// Keeps the camera's middle in the part of the map the sheet leaves
  /// clear, so the followed train is centred where it can be seen.
  /// What of the map the top bar and the sheet at rest cover.
  EdgeInsets get _mapInsets {
    final media = MediaQuery.of(context);
    return EdgeInsets.only(
      top: media.padding.top + 72,
      bottom: (media.size.height * _sheetFraction - 28)
          .clamp(0.0, media.size.height * 0.6)
          .toDouble(),
    );
  }

  void _applyInsets() {
    final map = _map;
    if (map == null || !_layersReady || !mounted) return;
    final insets = _mapInsets;
    if ((insets.bottom - _insetBottom).abs() < 6) return;
    _insetBottom = insets.bottom;
    unawaited(
      map
          .updateContentInsets(insets, false)
          .catchError((Object e) => debugPrint('⚠️ Map insets: $e')),
    );
  }

  Future<void> _frameJourney() async {
    final map = _map;
    if (map == null || !mounted) return;
    final state = _cubit.state;
    final path = state.path?.points ?? const <LatLng>[];
    final step = math.max(1, path.length ~/ 200);
    final points = <LatLng>[
      for (var i = 0; i < path.length; i += step) path[i],
      for (final s in _train.journey)
        if (s.position != null) s.position!,
      if (state.positionOf(_train) case final p?) p.position,
    ];
    if (points.isEmpty) return;
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    // Flat and north up, levelled as it goes: off the chase camera's tilt
    // and turn, in one move.
    final camera = flatCameraFor(
      LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      ),
      size: MediaQuery.sizeOf(context),
      // As the map has them.
      insets: _insetBottom < 0
          ? EdgeInsets.zero
          : _mapInsets.copyWith(bottom: _insetBottom),
      padding: const EdgeInsets.fromLTRB(48, 24, 72, 24),
      maxZoom: 12,
    );
    try {
      await map.animateCamera(
        CameraUpdate.newCameraPosition(camera),
        duration: const Duration(milliseconds: 800),
      );
    } catch (e) {
      debugPrint('⚠️ Tracking camera: $e');
    }
  }

  /// Swoops down onto the train, close and tilted along the track, and
  /// keeps following it.
  Future<void> _startFollow() async {
    final pose = _motion.poseAt(DateTime.now());
    final map = _map;
    if (pose == null || map == null || !mounted) return;
    setState(() => _follow = true);
    _swooping = true;
    _cameraBearing = pose.heading + _chaseAngle;
    try {
      // Aimed a little ahead, where the train will be when the swoop ends.
      final ahead = _motion.path != null && pose.along != null
          ? _motion.path!.fixAt(pose.along! + pose.speedMps * 1.4).snapped
          : pose.point;
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: ahead,
            zoom: _chaseZoom,
            tilt: _chaseTilt,
            bearing: _cameraBearing!,
          ),
        ),
        duration: const Duration(milliseconds: 1400),
      );
    } catch (e) {
      debugPrint('⚠️ Tracking camera: $e');
    } finally {
      _swooping = false;
      // The swoop moved the camera: the chase takes over from where it is.
      _sentCameraAt = null;
    }
  }

  Future<void> _toggleFollow() async {
    _auto = false;
    _refollow = false;
    _refollowTimer?.cancel();
    if (!_follow) return _startFollow();
    setState(() => _follow = false);
    final map = _map;
    final camera = map?.cameraPosition;
    if (map == null || camera == null) return;
    try {
      // Back to a flat, north-up map.
      await map.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: camera.target,
            zoom: math.min(camera.zoom, 12),
          ),
        ),
        duration: const Duration(milliseconds: 800),
      );
    } catch (e) {
      debugPrint('⚠️ Tracking camera: $e');
    }
  }

  void _showJourney() {
    _refollow = false;
    _refollowTimer?.cancel();
    setState(() {
      _follow = false;
      _auto = false;
    });
    unawaited(_frameJourney());
  }

  void _onUserTouch() {
    _touching = true;
    _refollowTimer?.cancel();
    if (!_follow && !_auto) return;
    _refollow = _follow;
    setState(() {
      _follow = false;
      _auto = false;
    });
  }

  /// The hand is off the map: back to the train in a while, if a touch
  /// took the camera off it.
  void _onUserRelease() {
    _touching = false;
    if (!_refollow) return;
    _refollowTimer?.cancel();
    _refollowTimer = Timer(_refollowAfter, () {
      if (!mounted || _follow || !_refollow) return;
      _refollow = false;
      unawaited(_startFollow());
    });
  }

  void _openRun(LiveTrain run) {
    if (run.id == _train.id) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: TrainLiveMapView(train: run),
        ),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final media = MediaQuery.of(context);
    return BlocListener<RealTimeTrackingCubit, RealTimeTrackingState>(
      listenWhen: (a, b) =>
          !identical(a.path, b.path) ||
          !identical(a.fix, b.fix) ||
          !identical(a.stationKm, b.stationKm) ||
          !identical(a.routeStops, b.routeStops) ||
          a.positionOf(_train) != b.positionOf(_train),
      listener: (_, state) => unawaited(_sync(state)),
      child: Scaffold(
        backgroundColor: palette.bg,
        // Resizing the map's platform view while the route is closing (e.g.
        // the list's keyboard animating in) crashes the Android embedder.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _onUserTouch(),
                onPointerUp: (_) => _onUserRelease(),
                onPointerCancel: (_) => _onUserRelease(),
                child: MapLibreMap(
                  key: ValueKey(_mapKey),
                  styleString: mapStyleOf(palette),
                  initialCameraPosition: _initialCamera,
                  trackCameraPosition: true,
                  compassEnabled: true,
                  compassViewPosition: CompassViewPosition.topLeft,
                  compassViewMargins: math.Point(16, media.padding.top + 84),
                  attributionButtonPosition: AttributionButtonPosition.topRight,
                  attributionButtonMargins: math.Point(
                    12,
                    media.padding.top + 196,
                  ),
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onMapCreated: (c) => _map = c,
                  onStyleLoadedCallback: _onStyleLoaded,
                ),
              ),
            ),
            Positioned.fill(
              child: MapCover(
                visible: !_shown,
                slow: _slow,
                onRetry: _retryMap,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(train: _train, onPickRun: _openRun),
            ),
            Positioned(
              top: media.padding.top + 80,
              left: 76,
              right: 76,
              child: Center(child: _ConnectionBanner(train: _train)),
            ),
            Positioned(
              right: 14,
              top: media.padding.top + 84,
              child: Column(
                children: [
                  MapIconButton(
                    icon: _follow
                        ? Icons.navigation_rounded
                        : Icons.navigation_outlined,
                    active: _follow,
                    tooltip: 'Follow train',
                    onTap: _toggleFollow,
                  ),
                  const SizedBox(height: 10),
                  MapIconButton(
                    icon: Icons.route_rounded,
                    tooltip: 'Whole journey',
                    onTap: _showJourney,
                  ),
                ],
              ),
            ),
            DraggableScrollableSheet(
              controller: _sheet,
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              // Fully open, the sheet stops just below the top bar.
              maxChildSize: (1 - (media.padding.top + 84) / media.size.height)
                  .clamp(0.6, 0.92),
              snap: true,
              snapSizes: const [_sheetInitial],
              builder: (context, scroll) =>
                  _JourneySheet(train: _train, scroll: scroll),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the live feed for the train is reconnecting.
class _ConnectionBanner extends StatelessWidget {
  final LiveTrain train;

  const _ConnectionBanner({required this.train});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return BlocBuilder<RealTimeTrackingCubit, RealTimeTrackingState>(
      buildWhen: (a, b) =>
          a.linkOf(train) != b.linkOf(train) ||
          (a.positionOf(train) == null) != (b.positionOf(train) == null),
      builder: (context, state) {
        final link = state.linkOf(train);
        final reconnecting =
            train.hasDevice &&
            (link == LinkState.retrying ||
                (link == LinkState.connecting &&
                    state.positionOf(train) != null));
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(sizeFactor: animation, child: child),
          ),
          child: !reconnecting
              ? const SizedBox.shrink()
              : Container(
                  key: const ValueKey('reconnecting'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: palette.amberSoft,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: palette.amber.withValues(alpha: 0.3),
                    ),
                    boxShadow: palette.shadow(1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.amber,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Reconnecting to live feed…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: palette.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// Every station along the route once it is known; until then the
/// journey's own stations that could be placed on it.
List<RouteStop> _stripStops(LiveTrain train, RealTimeTrackingState state) {
  if (state.routeStops.isNotEmpty) return state.routeStops;
  final journey = train.journey;
  return [
    for (var i = 0; i < journey.length && i < state.stationKm.length; i++)
      if (state.stationKm[i] case final km?)
        RouteStop(journey[i], km, scheduled: true),
  ];
}

/// Which stations of the selected train's journey are behind it.
List<bool> _passedFlags(LiveTrain train, RealTimeTrackingState state) {
  final journey = train.journey;
  final covered = state.fix == null ? null : state.fix!.alongM / 1000;
  return [
    for (var i = 0; i < journey.length; i++)
      covered != null &&
          i < state.stationKm.length &&
          state.stationKm[i] != null &&
          state.stationKm[i]! <= covered + 0.5,
  ];
}

class _TopBar extends StatelessWidget {
  final LiveTrain train;

  /// Shows another day's run of this train.
  final ValueChanged<LiveTrain> onPickRun;

  const _TopBar({required this.train, required this.onPickRun});

  Future<void> _pickRun(BuildContext context) async {
    final state = context.read<RealTimeTrackingCubit>().state;
    final run = await showRunPicker(
      context,
      runs: state.runsOf(train),
      state: state,
      currentId: train.id,
    );
    if (run != null) onPickRun(run);
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(
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
                        TrainNumberBadge(train: train, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      train.code.isNotEmpty
                                          ? '${train.displayName} ${train.code}'
                                          : train.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ),
                                  if (train.isUp || train.isDown) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      train.isUp
                                          ? Icons.north_rounded
                                          : Icons.south_rounded,
                                      size: 14,
                                      color: trainDirectionColor(
                                        train,
                                        palette,
                                      ),
                                    ),
                                  ],
                                  // Another day's run is out too: say which
                                  // this is, and offer the other.
                                  BlocSelector<
                                    RealTimeTrackingCubit,
                                    RealTimeTrackingState,
                                    bool
                                  >(
                                    selector: (s) => s.hasOtherRuns(train),
                                    builder: (context, others) => others
                                        ? Padding(
                                            padding: const EdgeInsets.only(
                                              left: 6,
                                            ),
                                            child: RunDateChip(
                                              run: train,
                                              onTap: () => _pickRun(context),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                train.routeLabel,
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
                        BlocBuilder<
                          RealTimeTrackingCubit,
                          RealTimeTrackingState
                        >(
                          buildWhen: (a, b) =>
                              a.positionOf(train) != b.positionOf(train) ||
                              a.linkOf(train) != b.linkOf(train),
                          builder: (context, state) => TimeTicker(
                            builder: (context, now) {
                              final status = liveStatusOf(
                                train,
                                state.positionOf(train),
                                state.linkOf(train),
                                now: now,
                                palette: TrackPalette.of(context),
                                listeningSince: state.listeningSinceOf(train),
                                openedAt: state.openedAtOf(train),
                              );
                              return LiveDot(
                                color: status.color,
                                pulsing: status.isLive && !lightMaps,
                                size: 10,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet ────────────────────────────────────────────────────────────────

class _JourneySheet extends StatelessWidget {
  final LiveTrain train;
  final ScrollController scroll;

  const _JourneySheet({required this.train, required this.scroll});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: palette.shadowInk.withValues(
              alpha: palette.isDark ? 0.5 : 0.12,
            ),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: BlocBuilder<RealTimeTrackingCubit, RealTimeTrackingState>(
        buildWhen: (a, b) =>
            a.positionOf(train) != b.positionOf(train) ||
            a.linkOf(train) != b.linkOf(train) ||
            !identical(a.path, b.path) ||
            !identical(a.fix, b.fix) ||
            a.routeLoading != b.routeLoading ||
            !identical(a.stationKm, b.stationKm) ||
            !identical(a.routeStops, b.routeStops) ||
            !identical(a.reached, b.reached) ||
            a.trainById(train.id) != b.trainById(train.id) ||
            a.listeningSinceOf(train) != b.listeningSinceOf(train),
        builder: (context, state) => TimeTicker(
          builder: (context, now) {
            final position = state.positionOf(train);
            final status = liveStatusOf(
              train,
              position,
              state.linkOf(train),
              now: now,
              palette: TrackPalette.of(context),
              listeningSince: state.listeningSinceOf(train),
              openedAt: state.openedAtOf(train),
            );
            return ListView(
              controller: scroll,
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: palette.line,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
                if (position == null)
                  _NoLocation(status: status)
                else
                  _LiveSummary(position: position, status: status, now: now),
                const SizedBox(height: 16),
                _JourneyCard(train: train, state: state),
                if (_stripStops(train, state) case final stops
                    when stops.length >= 2) ...[
                  if (journeyTiming(
                        stops: stops,
                        day: (state.trainById(train.id) ?? train).departureDay,
                        reached: state.reached,
                        coveredKm: position == null || state.fix == null
                            ? null
                            : state.fix!.alongM / 1000,
                        reportedAt: position?.fixTime,
                      )
                      case final timing
                      when timing.scheduledLength != null) ...[
                    const SizedBox(height: 12),
                    _JourneyTime(
                      timing: timing,
                      to: stops.last.station.name,
                      now: now,
                    ),
                  ],
                  const SizedBox(height: 22),
                  StationStrip(
                    stops: stops,
                    coveredKm: position == null || state.fix == null
                        ? null
                        : state.fix!.alongM / 1000,
                    position: position,
                    runDate: (state.trainById(train.id) ?? train).departureDay,
                    reached: state.reached,
                  ),
                ],
                const SizedBox(height: 22),
                _TrainDetails(train: train),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LiveSummary extends StatelessWidget {
  final TrainPosition position;
  final LiveStatus status;
  final DateTime now;

  const _LiveSummary({
    required this.position,
    required this.status,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final place = position.shortAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SpeedGauge(
              speedKmh: position.moving ? position.speedKmh : 0,
              active: status.isLive,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusPill(status: status),
                  if (status.kind != TrainLiveStatus.stale) ...[
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: Icons.schedule_rounded,
                      text: 'Updated ${formatAgo(position.fixTime, now)}',
                    ),
                  ],
                  if (place != null) ...[
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.place_rounded,
                      text: 'Near $place',
                      strong: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        // Between reports the map runs the train on at its last speed; say
        // so once the last report is old enough to notice.
        if (position.validFix &&
            position.moving &&
            now.difference(position.fixTime) > const Duration(seconds: 45)) ...[
          const SizedBox(height: 10),
          _Note(
            icon: Icons.timelapse_rounded,
            color: palette.mute,
            text:
                'GPS updates are slow here. The train is shown moving at its '
                'last reported speed until the next one.',
          ),
        ],
        if (!position.validFix) ...[
          const SizedBox(height: 10),
          _Note(
            icon: Icons.info_outline_rounded,
            color: palette.amber,
            text:
                'The GPS device has no satellite fix right now. Showing the '
                'last location it reported.',
          ),
        ],
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool strong;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 16,
            color: strong ? palette.g2 : palette.mute,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color: strong ? palette.ink : palette.mute,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoLocation extends StatelessWidget {
  final LiveStatus status;

  const _NoLocation({required this.status});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final (title, message) = switch (status.kind) {
      TrainLiveStatus.noDevice => (
        'No GPS device on this train',
        "Live location isn't available. The route and stations are shown "
            'on the map.',
      ),
      TrainLiveStatus.silent => (
        'No signal from the train yet',
        "The train's GPS device hasn't reported. It may be switched off or "
            'out of network coverage.',
      ),
      _ => (
        "Getting the train's location…",
        'Positions arrive every few seconds while the train is moving.',
      ),
    };
    final busy =
        status.kind == TrainLiveStatus.connecting ||
        status.kind == TrainLiveStatus.waiting;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: busy
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: status.color,
                    ),
                  )
                : Icon(status.icon, color: status.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.mute,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final LiveTrain train;
  final RealTimeTrackingState state;

  const _JourneyCard({required this.train, required this.state});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final path = state.path;
    final totalKm = path == null ? null : path.lengthM / 1000;
    final coveredKm = state.fix == null ? null : state.fix!.alongM / 1000;
    final fraction = totalKm != null && totalKm > 0 && coveredKm != null
        ? (coveredKm / totalKm).clamp(0.0, 1.0)
        : null;

    if (!train.hasRoute) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: _Note(
          icon: Icons.alt_route_rounded,
          color: palette.mute,
          text:
              "No route is assigned to this train today, so only its live "
              'position is shown.',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.soft, palette.soft.withValues(alpha: 0.35)],
        ),
        border: Border.all(color: palette.g2.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Endpoint(
                  station: train.origin,
                  label: 'FROM',
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: palette.g2,
                  size: 20,
                ),
              ),
              Expanded(
                child: _Endpoint(
                  station: train.destination,
                  label: 'TO',
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fraction != null) ...[
            _ProgressTrack(fraction: fraction),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    value: coveredKm!,
                    format: formatKm,
                    label: 'covered',
                  ),
                ),
                _Figure(
                  value: fraction * 100,
                  format: (v) => '${v.round()}%',
                  label: 'of the way',
                  center: true,
                ),
                Expanded(
                  child: _Figure(
                    value: math.max(0, totalKm! - coveredKm),
                    format: formatKm,
                    label: 'to go',
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ] else if (totalKm != null)
            Row(
              children: [
                Icon(Icons.straighten_rounded, size: 18, color: palette.g2),
                const SizedBox(width: 8),
                Text(
                  'Route length ${formatKm(totalKm)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: palette.ink,
                  ),
                ),
              ],
            )
          else if (state.routeLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.g2,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Finding the route…',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.mute,
                  ),
                ),
              ],
            )
          else
            _Note(
              icon: Icons.info_outline_rounded,
              color: palette.mute,
              text:
                  "The route can't be drawn because station locations are "
                  'missing.',
            ),
          if (path != null) ...[
            const SizedBox(height: 10),
            Text(
              'Route estimated along the rail network',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: palette.mute,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Endpoint extends StatelessWidget {
  final TrainStation? station;
  final String label;
  final bool alignEnd;

  const _Endpoint({
    required this.station,
    required this.label,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: palette.g1,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          station?.code ?? '—',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: palette.ink,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          station?.name ?? 'Unknown',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.mute,
          ),
        ),
      ],
    );
  }
}

/// The journey as a short stretch of track with the train on it.
class _ProgressTrack extends StatelessWidget {
  final double fraction;

  const _ProgressTrack({required this.fraction});

  static const double _trainLength = 54;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, f, _) => SizedBox(
        height: 30,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final x = (constraints.maxWidth - _trainLength) * f;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MiniTrackPainter(
                      x + _trainLength / 2,
                      TrackPalette.of(context),
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  child: const Center(
                    child: TrainGlyph(length: _trainLength, headlights: true),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MiniTrackPainter extends CustomPainter {
  /// Where the covered (green) part of the track ends.
  final double coveredTo;
  final TrackPalette palette;

  _MiniTrackPainter(this.coveredTo, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    void track(double from, double to, Color color) {
      if (to <= from) return;
      final sleeper = Paint()
        ..color = color.withValues(alpha: 0.45)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var x = from + 3; x < to; x += 7) {
        canvas.drawLine(Offset(x, cy - 5.5), Offset(x, cy + 5.5), sleeper);
      }
      final rail = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(from, cy - 3), Offset(to, cy - 3), rail);
      canvas.drawLine(Offset(from, cy + 3), Offset(to, cy + 3), rail);
    }

    final split = coveredTo.clamp(0.0, size.width).toDouble();
    track(0, split, palette.g1);
    track(split, size.width, palette.grey.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(_MiniTrackPainter old) =>
      old.coveredTo != coveredTo || old.palette != palette;
}

class _Figure extends StatelessWidget {
  final double value;
  final String Function(double value) format;
  final String label;
  final bool alignEnd;
  final bool center;

  const _Figure({
    required this.value,
    required this.format,
    required this.label,
    this.alignEnd = false,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : (alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start),
      children: [
        CountUpText(
          value: value,
          format: format,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: center ? palette.g1 : palette.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: palette.mute,
          ),
        ),
      ],
    );
  }
}

class _TrainDetails extends StatelessWidget {
  final LiveTrain train;

  const _TrainDetails({required this.train});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    // For the "Running on" tile below, while it is off:
    // final date = DateTime.tryParse(train.date ?? '');
    final tiles = [
      ('Train', train.code.isEmpty ? '—' : train.code, Icons.tag_rounded),
      (
        'Direction',
        train.isUp ? 'Up' : (train.isDown ? 'Down' : '—'),
        Icons.swap_vert_rounded,
      ),
      // From the run's detail, as the railway entered it.
      if (train.dispatchedAt case final at?)
        (
          'Departed',
          DateFormat('h:mm a, d MMM').format(at),
          Icons.schedule_send_rounded,
        ),
      if (train.locomotives.isNotEmpty)
        ('Locomotive', train.locomotives.join(', '), Icons.train_rounded),
      // (
      //   'GPS device',
      //   train.hasDevice ? '#${train.deviceId}' : 'Not installed',
      //   Icons.sensors_rounded,
      // ),
      // (
      //   'Running on',
      //   date == null ? '—' : DateFormat('d MMM yyyy').format(date),
      //   Icons.event_rounded,
      // ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Train details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          // Otherwise it pads itself by the status bar once the sheet is up.
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final (label, value, icon) in tiles)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: palette.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: palette.g2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: palette.mute,
                            ),
                          ),
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: palette.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Note({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// The whole journey's time: what the timetable gives it, what it is
/// taking at the delay the train runs at, how late it is overall, and
/// when it is expected at its last stop.
class _JourneyTime extends StatelessWidget {
  const _JourneyTime({
    required this.timing,
    required this.to,
    required this.now,
  });

  final JourneyTiming timing;
  final String to;
  final DateTime now;

  static final DateFormat _at = DateFormat('EEE h:mm a');

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final scheduled = timing.scheduledLength!;
    final expected = timing.expectedLength;
    final delay = timing.delay;
    final arrival = timing.expectedArrival;
    final late = delay != null && delay.inMinutes > 2;
    final early = delay != null && delay.inMinutes < -2;
    final tone = late ? palette.red : palette.g1;
    final onTheWay = timing.onTheWay(now);
    TextStyle label() => TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: palette.mute,
    );
    TextStyle value(Color color) => TextStyle(
      fontSize: 19,
      fontWeight: FontWeight.w900,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: late ? palette.redSoft : palette.line),
        boxShadow: palette.shadow(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: tone),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Journey time',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
              ),
              if (delay != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: late ? palette.redSoft : palette.soft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    delayLabel(delay),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: tone,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIMETABLE', style: label()),
                    const SizedBox(height: 2),
                    Text(durationLabel(scheduled), style: value(palette.ink)),
                  ],
                ),
              ),
              if (expected != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        late || early ? 'TAKING' : 'ON TIME',
                        style: label(),
                      ),
                      const SizedBox(height: 2),
                      Text(durationLabel(expected), style: value(tone)),
                    ],
                  ),
                ),
            ],
          ),
          if (late && expected != null) ...[
            const SizedBox(height: 8),
            Text(
              'Due to take ${durationLabel(scheduled)}, now taking '
              '${durationLabel(expected)}: ${delayLabel(delay)} overall.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: palette.ink,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: palette.line),
          const SizedBox(height: 10),
          if (arrival != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Expected at $to  ',
                    style: TextStyle(color: palette.mute),
                  ),
                  TextSpan(
                    text: _at.format(arrival),
                    style: TextStyle(color: palette.ink),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (onTheWay != null) ...[
            const SizedBox(height: 3),
            Text(
              'On its way for ${durationLabel(onTheWay)}'
              '${timing.departureDelay == null ? ' (from its due departure)' : ''}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: palette.mute,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
