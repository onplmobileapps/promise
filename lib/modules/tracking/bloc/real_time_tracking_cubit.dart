import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, listEquals;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/data/train_repository.dart';
import 'package:railway_hrms/modules/tracking/services/rail_router.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/services/track_history_store.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';
import 'package:railway_hrms/modules/tracking/services/train_motion.dart';

/// Finds the rail path through waypoints; the network's, unless a test
/// stands in.
typedef RailRoute = Future<List<LatLng>?> Function(List<LatLng> waypoints);

class RealTimeTrackingCubit extends SafeCubit<RealTimeTrackingState> {
  RealTimeTrackingCubit(
    this._trainRepository, {
    LiveFeedFactory feed = TrainProxyFeed.new,
    RailRoute? route,
    TrackHistoryStore? history,
  }) : _route = route ?? RailRouter.instance.route,
       _store = history,
       super(const RealTimeTrackingState()) {
    _feed = feed(onPosition: _onPosition, onLinkChanged: _onLinkChanged);
    // Parse the rail network while the list is on screen.
    if (route == null) RailRouter.instance.warmUp();
    _loadHistory();
  }

  final TrainRepository _trainRepository;
  final RailRoute _route;
  late final TrainFeed _feed;

  /// Where the day's reports are kept between visits; none in tests.
  final TrackHistoryStore? _store;

  /// A report further than this from the train's route is not placed
  /// along it.
  static const double _offRouteM = 1500;

  /// A train further than this from its route gets a new route: as far as
  /// the map keeps a train on its route (see [TrainMotion.onRouteM]), so a
  /// train that has taken another line soon has its track under it again.
  static const double _rerouteM = TrainMotion.onRouteM;

  /// A route drawn before the train's position was known is kept once the
  /// train turns out to be this close to it.
  static const double _onRouteM = 300;

  /// Least time between two re-routes of the selected train, and of any
  /// other train.
  static const Duration _rerouteGap = Duration(seconds: 30);
  static const Duration _fleetRerouteGap = Duration(seconds: 90);

  Future<void> initialize() async {
    await Future.wait([loadTrains(), loadStations()]);
  }

  /// The most pages of stations read, in case `next` never runs out.
  static const int _maxStationPages = 30;

  Future<void> loadStations() async {
    final found = <String, TrainStation>{};
    String? page;
    try {
      for (var i = 0; i < _maxStationPages; i++) {
        final result = await _trainRepository.getStations(pageUrl: page);
        final data = result.fold((_) => null, (response) => response.data);
        if (data == null) break;
        final (stations, next) = TrainStation.parsePage(data);
        for (final station in stations) {
          if (station.position == null) continue;
          found['${station.id ?? station.code ?? station.name}'] = station;
        }
        if (next == null || next == page) break;
        page = next;
      }
    } catch (e) {
      debugPrint('Loading stations failed: $e');
    }
    if (found.isNotEmpty) {
      // Only for the all-trains map's stations; a train's own stations
      // and stops come from its detail alone.
      emit(state.copyWith(stations: found.values.toList()));
    }
  }

  Future<void> loadTrains() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final result = await _trainRepository.getTrains();
      result.fold(
        (error) =>
            emit(state.copyWith(isLoading: false, errorMessage: error.message)),
        (response) {
          emit(
            state.copyWith(
              isLoading: false,
              trains: LiveTrain.parseList(response.data),
              errorMessage: null,
            ),
          );
          _syncFleet();
          // Trains whose position is already known get their routes.
          for (final train in state.trains) {
            final position = state.positionOf(train);
            if (position != null) _checkRoute(train, position);
          }
        },
      );
    } catch (e) {
      debugPrint('Loading trains failed: $e');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage:
              'Could not load trains. Check your connection and try '
              'again.',
        ),
      );
    }
  }

  // ─── Live positions ───────────────────────────────────────────────────

  /// Start receiving [train]'s live position (no-op without a GPS device).
  void watch(LiveTrain train) {
    if (train.hasDevice) _feed.watch(train.deviceId!);
  }

  void unwatch(LiveTrain train) {
    if (train.hasDevice) _feed.unwatch(train.deviceId!);
  }

  /// Screens showing every train at once, each holding [watchFleet].
  int _fleetViewers = 0;
  final Map<int, LiveTrain> _fleet = {};

  /// Watch every train with a GPS device, including trains loaded later,
  /// until the matching [unwatchFleet].
  void watchFleet() {
    _fleetViewers++;
    _syncFleet();
  }

  void unwatchFleet() {
    if (_fleetViewers == 0) return;
    _fleetViewers--;
    _syncFleet();
  }

  void _syncFleet() {
    final wanted = <int, LiveTrain>{
      if (_fleetViewers > 0)
        for (final train in state.trains)
          if (train.hasDevice) train.deviceId!: train,
    };
    for (final id in _fleet.keys.toList()) {
      if (!wanted.containsKey(id)) unwatch(_fleet.remove(id)!);
    }
    for (final MapEntry(key: id, value: train) in wanted.entries) {
      if (_fleet.containsKey(id)) continue;
      _fleet[id] = train;
      watch(train);
    }
  }

  void _onLinkChanged(int deviceId, LinkState? link) {
    final links = Map<int, LinkState>.of(state.links);
    final since = Map<int, DateTime>.of(state.listeningSince);
    final opened = Map<int, DateTime>.of(state.openedAt);
    final was = links[deviceId];
    if (link == null) {
      links.remove(deviceId);
      since.remove(deviceId);
      opened.remove(deviceId);
    } else {
      links[deviceId] = link;
      if (link == LinkState.open) {
        final now = DateTime.now();
        since.putIfAbsent(deviceId, () => now);
        if (was != LinkState.open) opened[deviceId] = now;
      }
    }
    emit(state.copyWith(links: links, listeningSince: since, openedAt: opened));
  }

  /// Reports not yet shown. The server pushes every device's reports in one
  /// burst every 10 s; they are shown together, so a burst rebuilds the
  /// screens once rather than once per train.
  final Map<int, TrainPosition> _pendingPositions = {};
  Timer? _flushTimer;
  static const Duration _batchWindow = Duration(milliseconds: 400);

  void _onPosition(TrainPosition position) {
    // After a reconnect a report can arrive twice or late; keep the newest.
    // Each report is its own device's: every train's comes over the one
    // socket.
    final previous =
        _pendingPositions[position.deviceId] ??
        state.positions[position.deviceId];
    if (previous != null && !position.fixTime.isAfter(previous.fixTime)) {
      return;
    }
    _pendingPositions[position.deviceId] = position;
    // The train being followed on its map moves at once.
    if (state.selectedTrain?.deviceId == position.deviceId) {
      _flushPositions();
    } else {
      _flushTimer ??= Timer(_batchWindow, _flushPositions);
    }
  }

  void _flushPositions() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingPositions.isEmpty || isClosed) return;
    final arrived = Map<int, TrainPosition>.of(_pendingPositions);
    _pendingPositions.clear();
    arrived.values.forEach(_remember);
    final positions = Map<int, TrainPosition>.of(state.positions)
      ..addAll(arrived);
    final selected = state.selectedTrain;
    final selectedReport = selected?.deviceId == null
        ? null
        : arrived[selected!.deviceId];
    if (selected == null || selectedReport == null) {
      emit(state.copyWith(positions: positions));
    } else {
      emit(
        state.copyWith(
          positions: positions,
          fix: _fixOf(selected, selectedReport),
        ),
      );
    }
    for (final train in state.trains) {
      final report = train.hasDevice ? arrived[train.deviceId] : null;
      if (report != null) _checkRoute(train, report);
    }
  }

  // ─── Selected train ───────────────────────────────────────────────────

  Future<void> loadTrainDetail(String trainId) async {
    try {
      final result = await _trainRepository.getTrainDetail(trainId);
      result.fold((_) => null, (response) {
        if (response.data is Map<String, dynamic>) {
          final updated = LiveTrain.fromJson(
            response.data as Map<String, dynamic>,
          );
          final trains = [
            for (final t in state.trains) t.id == updated.id ? updated : t,
          ];
          final path = state.pathOf(updated.id);
          final stops = path == null
              ? const <RouteStop>[]
              : stopsAlong(path, updated.journey);
          emit(state.copyWith(trains: trains, routeStops: stops));
        }
      });
    } catch (e) {
      debugPrint('Loading train detail $trainId failed: $e');
    }
  }

  void selectTrain(String trainId) {
    if (state.selectedTrainId == trainId) return;
    final train = state.trainById(trainId);
    if (train == null) return;
    _releaseSelection();
    final path = state.pathOf(train.id);
    final position = state.positionOf(train);
    final stops = path == null
        ? const <RouteStop>[]
        : stopsAlong(path, train.journey);
    emit(
      state.copyWith(
        selectedTrainId: train.id,
        fix: path == null || position == null
            ? null
            : _locate(path, position.position, null),
        stationKm: _stationKm(train, path),
        routeStops: stops,
        routeLoading: path == null,
      ),
    );
    watch(train);
    unawaited(loadTrainDetail(trainId));
    if (path == null) {
      _wantRoute(train, first: true);
    } else if (position != null) {
      _checkRoute(train, position);
    }
  }

  void clearSelection() {
    _releaseSelection();
    emit(
      state.copyWith(
        selectedTrainId: null,
        fix: null,
        stationKm: const [],
        routeStops: const [],
        routeLoading: false,
      ),
    );
  }

  void _releaseSelection() {
    final current = state.selectedTrain;
    if (current != null) unwatch(current);
  }

  /// Where [report] puts [train] along its route: near where it was last,
  /// and never back by a little, which is GPS scatter rather than travel.
  RouteFix? _fixOf(LiveTrain train, TrainPosition report) {
    final path = state.pathOf(train.id);
    if (path == null) return null;
    final previous = state.fix;
    final fix = _locate(path, report.position, previous?.alongM);
    if (fix == null || previous == null) return fix;
    final back = previous.alongM - fix.alongM;
    if (back > 0 && back < 1500) {
      return RouteFix(
        previous.segment,
        previous.snapped,
        previous.alongM,
        fix.offsetM,
      );
    }
    return fix;
  }

  static RouteFix? _locate(RoutePath path, LatLng point, double? near) {
    final fix = near == null
        ? null
        : path.locateNear(point, near, windowM: 20000);
    if (fix != null && fix.offsetM <= _offRouteM) return fix;
    return path.locate(point);
  }

  // ─── History and speed ────────────────────────────────────────────────

  /// Every good report of each device today, oldest first, as when and
  /// where: when the selected train passed its stations is read from it.
  /// Kept between visits by [_store].
  final Map<int, List<TrackFix>> _history = {};
  static const int _historyMax = 3000;
  bool _historyChanged = false;
  Timer? _saveTimer;

  /// How often the day's reports are put away while tracking is open.
  static const Duration _saveEvery = Duration(minutes: 2);

  Future<void> _loadHistory() async {
    final store = _store;
    if (store == null) return;
    final kept = await store.load();
    if (isClosed || kept.isEmpty) return;
    for (final MapEntry(key: device, value: fixes) in kept.entries) {
      final list = _history.putIfAbsent(device, () => []);
      // Reports already in this visit come after the kept ones.
      final before = list.isEmpty ? null : list.first.$1;
      list.insertAll(0, [
        for (final fix in fixes)
          if (before == null || fix.$1.isBefore(before)) fix,
      ]);
    }
  }

  void _remember(TrainPosition report) {
    if (!report.validFix) return;
    final list = _history.putIfAbsent(report.deviceId, () => []);
    if (list.isNotEmpty && !report.fixTime.isAfter(list.last.$1)) return;
    list.add((report.fixTime, report.position));
    if (list.length > _historyMax) {
      list.removeRange(0, list.length - _historyMax);
    }
    _historyChanged = true;
    _saveTimer ??= _store == null ? null : Timer(_saveEvery, _saveHistory);
  }

  Future<void> _saveHistory() async {
    _saveTimer = null;
    final store = _store;
    if (store == null || !_historyChanged) return;
    _historyChanged = false;
    await store.save({
      for (final MapEntry(key: device, value: fixes) in _history.entries)
        device: List.of(fixes),
    });
  }

  // ─── Routes ───────────────────────────────────────────────────────────

  final Map<String, _Routing> _routing = {};
  final List<String> _routeQueue = [];
  bool _routingBusy = false;

  /// Routes found for trains other than the selected one, shown together.
  final Map<String, RoutePath?> _foundPaths = {};
  Timer? _pathsTimer;

  /// Checks [train]'s route against its new [report]: finds one if it has
  /// none, and a new one when the train has left it.
  void _checkRoute(LiveTrain train, TrainPosition report) {
    if (!report.validFix) return;
    final routing = _routing.putIfAbsent(train.id, _Routing.new);
    if (routing.queued) return;
    final path = _foundPaths[train.id] ?? state.pathOf(train.id);
    final selected = train.id == state.selectedTrainId;
    final last = routing.lastAt;
    final gap = selected ? _rerouteGap : _fleetRerouteGap;
    final due = last == null || DateTime.now().difference(last) >= gap;
    if (path == null) {
      // None found yet, or none could be: try again now and then.
      if (due) _wantRoute(train, first: selected);
      return;
    }
    final fix = _locate(path, report.position, routing.along);
    if (fix != null && fix.offsetM <= _offRouteM) routing.along = fix.alongM;
    final off = fix == null || fix.offsetM > _rerouteM;
    if (!off) {
      routing.offReports = 0;
      // A route through the train's own position is kept while it stays
      // on it; one drawn without it, once the train turns out to be on it.
      if (routing.throughTrain) return;
      if (fix.offsetM <= _onRouteM) {
        routing.throughTrain = true;
        return;
      }
    } else if (++routing.offReports < 2 &&
        fix != null &&
        fix.offsetM <= _offRouteM) {
      // One report a little off can be a stray fix; two in a row, or one
      // far off, and the train has left its route.
      return;
    }
    if (due) _wantRoute(train, first: selected);
  }

  void _wantRoute(LiveTrain train, {bool first = false}) {
    final routing = _routing.putIfAbsent(train.id, _Routing.new);
    if (routing.queued) {
      if (first) {
        _routeQueue
          ..remove(train.id)
          ..insert(0, train.id);
      }
      return;
    }
    routing.queued = true;
    first ? _routeQueue.insert(0, train.id) : _routeQueue.add(train.id);
    unawaited(_pumpRoutes());
  }

  Future<void> _pumpRoutes() async {
    if (_routingBusy) return;
    _routingBusy = true;
    try {
      while (_routeQueue.isNotEmpty && !isClosed) {
        final id = _routeQueue.removeAt(0);
        final routing = _routing[id];
        final train = state.trainById(id);
        if (routing == null || train == null) continue;
        routing.queued = false;
        final position = state.positionOf(train);
        final live = position != null && position.validFix
            ? position.position
            : null;
        final waypoints = _waypoints(train, live);
        routing.lastAt = DateTime.now();
        if (waypoints.length < 2) {
          if (id == state.selectedTrainId) {
            emit(state.copyWith(routeLoading: false));
          }
          continue;
        }
        if (id == state.selectedTrainId && !state.routeLoading) {
          emit(state.copyWith(routeLoading: true));
        }
        final points = await _route(waypoints);
        if (isClosed) return;
        routing.throughTrain = live != null;
        routing.along = null;
        routing.offReports = 0;
        final shown = _foundPaths[id] ?? state.pathOf(id);
        // The same route found again stays as it is, not drawn afresh.
        if (shown != null &&
            points != null &&
            listEquals(points, shown.points)) {
          if (id == state.selectedTrainId && state.routeLoading) {
            emit(state.copyWith(routeLoading: false));
          }
          continue;
        }
        // No rail route found: the train is drawn where it reports, not
        // along straight lines between its stations, which run off the
        // track.
        final path = points != null && points.length >= 2
            ? RoutePath(points)
            : null;
        _foundPaths[id] = path;
        if (id == state.selectedTrainId) {
          _showPaths();
        } else {
          _pathsTimer ??= Timer(const Duration(milliseconds: 300), _showPaths);
        }
      }
    } finally {
      _routingBusy = false;
    }
  }

  /// Puts the routes found so far into the state, and lays the selected
  /// train's stations along its route.
  void _showPaths() {
    _pathsTimer?.cancel();
    _pathsTimer = null;
    if (_foundPaths.isEmpty || isClosed) return;
    final paths = Map<String, RoutePath>.of(state.paths);
    for (final MapEntry(key: id, value: path) in _foundPaths.entries) {
      path == null ? paths.remove(id) : paths[id] = path;
    }
    final selected = state.selectedTrain;
    final selectedChanged =
        selected != null && _foundPaths.containsKey(selected.id);
    _foundPaths.clear();
    if (!selectedChanged) {
      emit(state.copyWith(paths: paths));
      return;
    }
    final path = paths[selected.id];
    final position = state.positionOf(selected);
    final stops = path == null
        ? const <RouteStop>[]
        : stopsAlong(path, selected.journey);
    emit(
      state.copyWith(
        paths: paths,
        routeLoading: false,
        fix: path == null || position == null
            ? null
            : _locate(path, position.position, null),
        stationKm: _stationKm(selected, path),
        routeStops: stops,
      ),
    );
  }

  List<double?> _stationKm(LiveTrain train, RoutePath? path) => [
    for (final station in train.journey) _kmAlong(path, station.position),
  ];

  /// The route between the train's stations is the shortest rail path,
  /// which isn't always the line a train takes (Peshawar → Karachi mail
  /// trains run via Lahore, not the shorter Kundian line). Once the train's
  /// position is known the route is drawn through it, and redrawn whenever
  /// the train leaves it.
  ///
  /// Stations with coordinates, in order, with the live position inserted
  /// where it lengthens the trip the least.
  List<LatLng> _waypoints(LiveTrain train, LatLng? live) {
    final stops = [
      for (final s in train.journey)
        if (s.position != null) s.position!,
    ];
    if (live == null) return stops;
    if (stops.isEmpty) return const [];
    if (stops.length == 1) {
      return train.origin?.position != null
          ? [stops.first, live]
          : [live, stops.first];
    }
    var bestIndex = 1;
    var bestExtra = double.infinity;
    for (var i = 1; i < stops.length; i++) {
      final extra =
          haversineMeters(stops[i - 1], live) +
          haversineMeters(live, stops[i]) -
          haversineMeters(stops[i - 1], stops[i]);
      if (extra < bestExtra) {
        bestExtra = extra;
        bestIndex = i;
      }
    }
    return [...stops]..insert(bestIndex, live);
  }

  static double? _kmAlong(RoutePath? path, LatLng? point) {
    if (path == null || point == null) return null;
    final fix = path.locate(point);
    // Station coordinates from the API are rounded to ~1 km.
    if (fix == null || fix.offsetM > 5000) return null;
    return fix.alongM / 1000;
  }

  @override
  Future<void> close() async {
    _flushTimer?.cancel();
    _pathsTimer?.cancel();
    _saveTimer?.cancel();
    _feed.dispose();
    // The day's reports are put away for the next visit.
    unawaited(_saveHistory());
    return super.close();
  }
}

/// Where finding a train's route stands.
class _Routing {
  /// Waiting its turn to be routed.
  bool queued = false;

  /// When it was last routed.
  DateTime? lastAt;

  /// Its route was drawn through its own position.
  bool throughTrain = false;

  /// Its reports in a row too far from its route.
  int offReports = 0;

  /// Where it last was along its route, to place the next report near.
  double? along;
}
