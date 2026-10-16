import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';

/// Finds paths along the railway network in `assets/rail_tracks.json`.
///
/// The 7.7 MB network is parsed once by a background isolate, which then
/// answers route requests, so the UI thread never parses it or searches it.
class RailRouter {
  RailRouter._();
  static final RailRouter instance = RailRouter._();

  static const String _asset = 'assets/rail_tracks.json';

  Future<SendPort>? _worker;

  Future<SendPort> _start() async {
    final data = await rootBundle.load(_asset);
    final bytes = TransferableTypedData.fromList([
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ]);
    final handshake = ReceivePort();
    await Isolate.spawn(_routerMain, [
      handshake.sendPort,
      bytes,
    ], debugName: 'RailRouter');
    final reply = await handshake.first;
    if (reply is SendPort) return reply;
    throw StateError('Rail network failed to load: $reply');
  }

  /// Loads the network in the background ahead of the first [route].
  void warmUp() => unawaited(_port().then((_) {}, onError: (_) {}));

  Future<SendPort> _port() => _worker ??= _start().catchError((Object e) {
    _worker = null;
    throw e;
  });

  /// The rail path through [waypoints] in order. A leg with no rail
  /// connection is drawn as a straight line. Null when the network could
  /// not be loaded.
  Future<List<LatLng>?> route(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    final SendPort port;
    try {
      port = await _port();
    } catch (e) {
      debugPrint('⚠️ RailRouter: $e');
      return null;
    }
    final reply = ReceivePort();
    port.send([
      reply.sendPort,
      Float64List.fromList([
        for (final p in waypoints) ...[p.latitude, p.longitude],
      ]),
    ]);
    final result = await reply.first;
    reply.close();
    if (result is! Float64List) {
      debugPrint('⚠️ RailRouter: $result');
      return null;
    }
    return [
      for (var i = 0; i + 1 < result.length; i += 2)
        LatLng(result[i], result[i + 1]),
    ];
  }

  final Map<int, Future<List<List<LatLng>>?>> _networks = {};

  /// Every track of the network, each from one junction or line end to the
  /// next, simplified so no point strays more than [toleranceM] from the
  /// track. Null when the network could not be loaded.
  Future<List<List<LatLng>>?> network({double toleranceM = 15}) {
    final key = toleranceM.round();
    return _networks[key] ??= _network(toleranceM).then((lines) {
      if (lines == null) {
        _networks.remove(key);
      } else {
        _loadedNetworks[key] = lines;
      }
      return lines;
    });
  }

  final Map<int, List<List<LatLng>>> _loadedNetworks = {};

  /// [network] at [toleranceM] if it has already loaded, for drawing it
  /// without waiting; null until then.
  List<List<LatLng>>? loadedNetwork({double toleranceM = 15}) =>
      _loadedNetworks[toleranceM.round()];

  Future<List<List<LatLng>>?> _network(double toleranceM) async {
    final SendPort port;
    try {
      port = await _port();
    } catch (e) {
      debugPrint('⚠️ RailRouter: $e');
      return null;
    }
    final reply = ReceivePort();
    port.send([reply.sendPort, toleranceM]);
    final result = await reply.first;
    reply.close();
    if (result is! Float64List) {
      debugPrint('⚠️ RailRouter: $result');
      return null;
    }
    final lines = <List<LatLng>>[];
    var line = <LatLng>[];
    for (var i = 0; i + 1 < result.length; i += 2) {
      if (result[i].isNaN) {
        if (line.length >= 2) lines.add(line);
        line = <LatLng>[];
      } else {
        line.add(LatLng(result[i], result[i + 1]));
      }
    }
    if (line.length >= 2) lines.add(line);
    return lines;
  }
}

void _routerMain(List<Object?> args) {
  final handshake = args[0] as SendPort;
  final _RailGraph graph;
  try {
    final bytes = (args[1] as TransferableTypedData)
        .materialize()
        .asUint8List();
    graph = _RailGraph.parse(bytes);
  } catch (e) {
    handshake.send('$e');
    return;
  }
  final port = ReceivePort();
  handshake.send(port.sendPort);
  port.listen((message) {
    final request = message as List<Object?>;
    final reply = request[0] as SendPort;
    final query = request[1];
    try {
      reply.send(
        query is Float64List
            ? graph.route(query)
            : graph.network(query as double),
      );
    } catch (e) {
      reply.send('$e');
    }
  });
}

double _haversineM(double lat1, double lng1, double lat2, double lng2) {
  const d2r = math.pi / 180;
  final sLat = math.sin((lat2 - lat1) * d2r / 2);
  final sLng = math.sin((lng2 - lng1) * d2r / 2);
  final a =
      sLat * sLat + math.cos(lat1 * d2r) * math.cos(lat2 * d2r) * sLng * sLng;
  return 2 * 6371000.0 * math.asin(math.min(1.0, math.sqrt(a)));
}

/// Track nodes and the connections between them.
class _RailGraph {
  _RailGraph._(
    this._lat,
    this._lng,
    this._next,
    this._cost,
    this._grid,
    this._first,
    this._from,
    this._to,
    this._hx,
    this._hy,
    this._carries,
  );

  final Float64List _lat;
  final Float64List _lng;
  final List<List<int>> _next;
  final List<List<double>> _cost;
  final Map<int, List<int>> _grid;

  // The connections one way each, for following the track as a train
  // does: node u's run from _first[u] up to _first[u + 1], each from
  // _from to _to, heading the way _hx, _hy point (east, north; a unit
  // vector). A link that carries a line on from its end to another line
  // (_carries) heads the way that line runs, so the turn onto the other
  // line is the real one.
  final Int32List _first;
  final Int32List _from;
  final Int32List _to;
  final Float32List _hx;
  final Float32List _hy;
  final Uint8List _carries;

  /// Where lines meet, a train turns no sharper than this, in degrees:
  /// it can't go back the way it came, round the sharp side of a
  /// junction, or through a yard's crossovers to turn about. Every line
  /// carries on through each junction within 60° (and most within 15°).
  static const double _maxTurn = 100;
  static final double _minTurnCos = math.cos(_maxTurn * math.pi / 180);

  /// Grid cell size in degrees.
  static const double _cell = 0.01;

  /// Shortest side of a cell in metres anywhere in Pakistan (0.01° of
  /// longitude at 37° N), for turning distances into cell counts.
  static const double _cellMinM = 850;

  /// A line ending this close to another line is joined to it.
  static const double _joinM = 60;

  /// The track data has gaps — ML-1 between Lala Musa and Gujrat is missing
  /// 3.4 km, which otherwise turns Rawalpindi → Lahore into a 729 km detour.
  /// A line that ends abruptly is continued, in its own direction, to track
  /// up to this far ahead…
  static const double _bridgeM = 4000;

  /// …within this many degrees of the direction it was heading…
  static const double _bridgeMaxAngle = 35;

  /// …at a higher cost, so a bridge is only taken to avoid a long detour.
  static const double _bridgePenalty = 2;

  static int _cellKey(int y, int x) => (y + 10000) * 40000 + (x + 20000);

  factory _RailGraph.parse(Uint8List bytes) {
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final ids = <int, int>{};
    final lat = <double>[];
    final lng = <double>[];
    final owner = <int>[];
    final next = <List<int>>[];
    final cost = <List<double>>[];
    // Each line's ends, with the point next to each on the line.
    final ends = <(int, int?)>[];
    // Links that carry a line on from its end (at the first), from the
    // point before it (the last).
    final carried = <(int, int, int)>[];

    void link(int a, int b, double w) {
      next[a].add(b);
      cost[a].add(w);
      next[b].add(a);
      cost[b].add(w);
    }

    var line = 0;
    for (final feature in (json['features'] as List? ?? const [])) {
      final geometry = (feature as Map)['geometry'] as Map?;
      final type = geometry?['type'];
      final coordinates = geometry?['coordinates'] as List?;
      if (coordinates == null) continue;
      final List parts;
      if (type == 'LineString') {
        parts = [coordinates];
      } else if (type == 'MultiLineString') {
        parts = coordinates;
      } else {
        continue;
      }
      for (final part in parts) {
        int? first;
        int? second;
        int? prev;
        int? beforePrev;
        for (final point in part as List) {
          final p = point as List;
          final x = (p[0] as num).toDouble();
          final y = (p[1] as num).toDouble();
          // Points shared by two lines (junctions) become one node.
          final key =
              ((y * 1e6).round() + 90000000) * 400000000 +
              ((x * 1e6).round() + 180000000);
          var id = ids[key];
          if (id == null) {
            id = lat.length;
            ids[key] = id;
            lat.add(y);
            lng.add(x);
            owner.add(line);
            next.add(<int>[]);
            cost.add(<double>[]);
          }
          first ??= id;
          if (prev != null && prev != id) {
            link(prev, id, _haversineM(lat[prev], lng[prev], y, x));
            second ??= id;
            beforePrev = prev;
          }
          prev = id;
        }
        if (first != null) ends.addAll([(first, second), (prev!, beforePrev)]);
        line++;
      }
    }

    final grid = <int, List<int>>{};
    for (var i = 0; i < lat.length; i++) {
      grid
          .putIfAbsent(
            _cellKey((lat[i] / _cell).floor(), (lng[i] / _cell).floor()),
            () => <int>[],
          )
          .add(i);
    }

    Iterable<int> around(int node, int radiusCells) sync* {
      final cy = (lat[node] / _cell).floor();
      final cx = (lng[node] / _cell).floor();
      for (var dy = -radiusCells; dy <= radiusCells; dy++) {
        for (var dx = -radiusCells; dx <= radiusCells; dx++) {
          final bucket = grid[_cellKey(cy + dy, cx + dx)];
          if (bucket != null) yield* bucket;
        }
      }
    }

    // Join each line that ends short to the nearest point of another line
    // nearby. Most lines run on into the next where they end; linking
    // those too would lay crossovers between tracks side by side that no
    // train can take.
    for (final (end, inner) in ends) {
      if (next[end].length != 1) continue;
      var best = -1;
      var bestM = _joinM;
      for (final j in around(end, 1)) {
        if (owner[j] == owner[end]) continue;
        final m = _haversineM(lat[end], lng[end], lat[j], lng[j]);
        if (m < bestM) {
          best = j;
          bestM = m;
        }
      }
      if (best >= 0 && !next[end].contains(best)) {
        link(end, best, bestM);
        if (inner != null) carried.add((end, best, inner));
      }
    }

    // Bridge gaps after dead ends (see [_bridgeM]).
    final minCos = math.cos(_bridgeMaxAngle * math.pi / 180);
    final radiusCells = (_bridgeM / _cellMinM).ceil() + 1;
    final deadEnds = [
      for (var i = 0; i < lat.length; i++)
        if (next[i].length == 1) i,
    ];
    for (final end in deadEnds) {
      final from = next[end].first;
      final scale = math.cos(lat[end] * math.pi / 180);
      final ox = (lng[end] - lng[from]) * scale;
      final oy = lat[end] - lat[from];
      final on = math.sqrt(ox * ox + oy * oy);
      if (on == 0) continue;
      var best = -1;
      var bestM = _bridgeM;
      for (final j in around(end, radiusCells)) {
        if (j == end || j == from) continue;
        final m = _haversineM(lat[end], lng[end], lat[j], lng[j]);
        if (m >= bestM || m < 1) continue;
        final vx = (lng[j] - lng[end]) * scale;
        final vy = lat[j] - lat[end];
        final vn = math.sqrt(vx * vx + vy * vy);
        if ((ox * vx + oy * vy) / (on * vn) < minCos) continue;
        best = j;
        bestM = m;
      }
      if (best >= 0) {
        link(end, best, bestM * _bridgePenalty);
        carried.add((end, best, from));
      }
    }

    // The connections one way each, with the way each heads.
    final n = lat.length;
    (double, double) heading(int a, int b) {
      final x = (lng[b] - lng[a]) * math.cos(lat[a] * math.pi / 180);
      final y = lat[b] - lat[a];
      final length = math.sqrt(x * x + y * y);
      return length == 0 ? (0.0, 0.0) : (x / length, y / length);
    }

    final carriedHeading = <int, (double, double)>{
      for (final (end, to, inner) in carried) ...{
        end * n + to: heading(inner, end),
        to * n + end: heading(end, inner),
      },
    };
    final first = Int32List(n + 1);
    for (var u = 0; u < n; u++) {
      first[u + 1] = first[u] + next[u].length;
    }
    final from = Int32List(first[n]);
    final to = Int32List(first[n]);
    final hx = Float32List(first[n]);
    final hy = Float32List(first[n]);
    final carries = Uint8List(first[n]);
    for (var u = 0; u < n; u++) {
      for (var i = 0; i < next[u].length; i++) {
        final e = first[u] + i;
        final v = next[u][i];
        final link = carriedHeading[u * n + v];
        final (x, y) = link ?? heading(u, v);
        from[e] = u;
        to[e] = v;
        hx[e] = x;
        hy[e] = y;
        if (link != null) carries[e] = 1;
      }
    }

    return _RailGraph._(
      Float64List.fromList(lat),
      Float64List.fromList(lng),
      next,
      cost,
      grid,
      first,
      from,
      to,
      hx,
      hy,
      carries,
    );
  }

  /// Nearest node to a point, within [maxM].
  int? _nearest(double y, double x, double maxM) {
    final cy = (y / _cell).floor();
    final cx = (x / _cell).floor();
    final radius = (maxM / _cellMinM).ceil() + 1;
    int? best;
    var bestM = maxM;
    for (var r = 0; r <= radius; r++) {
      // Every cell at ring r is at least (r - 1) cells away.
      if (best != null && (r - 1) * _cellMinM > bestM) break;
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          if (dy.abs() != r && dx.abs() != r) continue;
          final bucket = _grid[_cellKey(cy + dy, cx + dx)];
          if (bucket == null) continue;
          for (final i in bucket) {
            final m = _haversineM(y, x, _lat[i], _lng[i]);
            if (m < bestM) {
              best = i;
              bestM = m;
            }
          }
        }
      }
    }
    return best;
  }

  /// Flat `[lat, lng, …]` path through flat `[lat, lng, …]` [waypoints].
  Float64List route(Float64List waypoints) {
    final out = <double>[];
    int? from;
    // The way the route came into the waypoint it goes on from.
    (double, double)? approach;
    for (var w = 0; w + 3 < waypoints.length; w += 2) {
      final a = from ?? _nearest(waypoints[w], waypoints[w + 1], 25000);
      final b = _nearest(waypoints[w + 2], waypoints[w + 3], 25000);
      final path = a != null && b != null ? _leg(a, b, approach) : null;
      if (path == null) {
        if (out.isEmpty) out.addAll([waypoints[w], waypoints[w + 1]]);
        out.addAll([waypoints[w + 2], waypoints[w + 3]]);
        from = null;
        approach = null;
        continue;
      }
      for (var k = out.isEmpty ? 0 : 1; k < path.length; k++) {
        out.addAll([_lat[path[k]], _lng[path[k]]]);
      }
      from = b;
      approach = _approach(path);
    }
    return Float64List.fromList(out);
  }

  /// A path that turns about is taken over the way a train runs only when
  /// that is this much longer: a train that does reverse somewhere,
  /// rather than one sent round half the country.
  static const double _turnAboutRatio = 1.5;
  static const double _turnAboutM = 50000;

  /// The path of a leg from [a] to [b] as a train runs it (see
  /// [_trainPath]), going on from [a] the way the last leg [approach]ed
  /// it rather than back. [a] is most often the train's own position, and
  /// the shortest path from a train just past a junction turns back
  /// through it whenever the line the train didn't take is the shorter
  /// way on.
  List<int>? _leg(int a, int b, (double, double)? approach) {
    final free = _shortestPath(a, b);
    final run =
        _trainPath(a, b, approach: approach) ??
        (approach == null ? null : _trainPath(a, b));
    if (run == null || free == null) return run ?? free;
    return _lengthM(run) <= _lengthM(free) * _turnAboutRatio + _turnAboutM
        ? run
        : free;
  }

  /// A waypoint's nearest point of track can be any of a yard's sidings —
  /// one a train only reaches or leaves by shunting. Within this far of
  /// where a leg starts and ends, a path may turn about as a shunting
  /// train does.
  static const double _yardM = 2000;

  /// Where [b] lies from [a], as a vector east and north (not to scale).
  (double, double) _towards(int a, int b) => (
    (_lng[b] - _lng[a]) * math.cos(_lat[a] * math.pi / 180),
    _lat[b] - _lat[a],
  );

  /// The way [path] came into its end from outside the yard there (see
  /// [_yardM]), as a vector east and north; null for a path that never
  /// leaves it.
  (double, double)? _approach(List<int> path) {
    final end = path.last;
    for (var k = path.length - 2; k >= 0; k--) {
      final p = path[k];
      if (_haversineM(_lat[p], _lng[p], _lat[end], _lng[end]) >= _yardM) {
        return _towards(p, end);
      }
    }
    return null;
  }

  /// Like [_shortestPath], but turning as a train does: never back where
  /// it came from, nor more than [_maxTurn] where lines meet, but in the
  /// yards where it starts and ends (see [_yardM]). Given the way the
  /// last leg came in, it leaves its first yard going on, not back. Null
  /// when no such path reaches [target].
  List<int>? _trainPath(int source, int target, {(double, double)? approach}) {
    if (source == target) return [source];
    bool atStart(int at) =>
        _haversineM(_lat[at], _lng[at], _lat[source], _lng[source]) < _yardM;
    bool atEnd(int at) =>
        _haversineM(_lat[at], _lng[at], _lat[target], _lng[target]) < _yardM;
    bool goesOn(int at) {
      if (approach == null) return true;
      final (x, y) = _towards(source, at);
      return x * approach.$1 + y * approach.$2 > 0;
    }

    final m = _to.length;
    final g = Float64List(m)..fillRange(0, m, double.infinity);
    final prev = Int32List(m)..fillRange(0, m, -1);
    final closed = Uint8List(m);
    final heap = _MinHeap();
    final ty = _lat[target];
    final tx = _lng[target];
    for (var e = _first[source]; e < _first[source + 1]; e++) {
      final v = _to[e];
      if (!atStart(v) && !goesOn(v)) continue;
      final ge = _cost[source][e - _first[source]];
      if (ge < g[e]) {
        g[e] = ge;
        heap.push(e, ge + _haversineM(_lat[v], _lng[v], ty, tx));
      }
    }
    var reached = -1;
    while (heap.isNotEmpty) {
      final e = heap.pop();
      if (closed[e] == 1) continue;
      closed[e] = 1;
      final u = _to[e];
      if (u == target) {
        reached = e;
        break;
      }
      final back = _from[e];
      final cost = _cost[u];
      final inStartYard = atStart(u);
      final inYard = inStartYard || atEnd(u);
      for (var f = _first[u]; f < _first[u + 1]; f++) {
        final w = _to[f];
        if (w == back || closed[f] == 1) continue;
        if (!inYard && !_turns(e, f, u)) continue;
        if (inStartYard && !atStart(w) && !goesOn(w)) continue;
        final gf = g[e] + cost[f - _first[u]];
        if (gf < g[f]) {
          g[f] = gf;
          prev[f] = e;
          heap.push(f, gf + _haversineM(_lat[w], _lng[w], ty, tx));
        }
      }
    }
    if (reached < 0) return null;
    final edges = <int>[reached];
    while (prev[edges.last] >= 0) {
      edges.add(prev[edges.last]);
    }
    return [_from[edges.last], for (final e in edges.reversed) _to[e]];
  }

  /// Whether a train can go from connection [inward] on to [outward] at
  /// node [at]: anywhere a line simply runs on, however it bends, and
  /// where lines meet — or one is carried on to another — when the turn
  /// is no sharper than [_maxTurn]. (Two yard tracks ending side by side
  /// are linked end to end, and a train must not turn about through it.)
  bool _turns(int inward, int outward, int at) =>
      (_first[at + 1] - _first[at] <= 2 &&
          _carries[inward] == 0 &&
          _carries[outward] == 0) ||
      _hx[inward] * _hx[outward] + _hy[inward] * _hy[outward] >= _minTurnCos;

  double _lengthM(List<int> path) {
    var m = 0.0;
    for (var i = 1; i < path.length; i++) {
      final p = path[i - 1];
      final q = path[i];
      m += _haversineM(_lat[p], _lng[p], _lat[q], _lng[q]);
    }
    return m;
  }

  /// Flat `[lat, lng, …]` runs of track separated by a NaN pair; see
  /// [RailRouter.network].
  Float64List network(double toleranceM) {
    final n = _lat.length;
    final out = <double>[];
    final done = <int>{};
    int edge(int a, int b) => a < b ? a * n + b : b * n + a;

    void walk(int from, int first) {
      final run = <int>[from];
      var prev = from;
      var cur = first;
      done.add(edge(from, first));
      while (true) {
        run.add(cur);
        final next = _next[cur];
        if (next.length != 2) break;
        final ahead = next[0] == prev ? next[1] : next[0];
        if (!done.add(edge(cur, ahead))) break;
        prev = cur;
        cur = ahead;
      }
      for (final i in _simplify(run, toleranceM)) {
        out
          ..add(_lat[i])
          ..add(_lng[i]);
      }
      out
        ..add(double.nan)
        ..add(double.nan);
    }

    for (var v = 0; v < n; v++) {
      if (_next[v].length == 2) continue;
      for (final w in _next[v]) {
        if (!done.contains(edge(v, w))) walk(v, w);
      }
    }
    // Loops with no junction on them.
    for (var v = 0; v < n; v++) {
      for (final w in _next[v]) {
        if (!done.contains(edge(v, w))) walk(v, w);
      }
    }
    return Float64List.fromList(out);
  }

  /// Douglas–Peucker over the nodes of [run], in a local flat projection.
  List<int> _simplify(List<int> run, double toleranceM) {
    if (run.length <= 2) return run;
    const mPerDegLat = 110574.0;
    final mPerDegLng = 111320.0 * math.cos(_lat[run.first] * math.pi / 180);
    double x(int i) => _lng[run[i]] * mPerDegLng;
    double y(int i) => _lat[run[i]] * mPerDegLat;
    final keep = Uint8List(run.length)
      ..[0] = 1
      ..[run.length - 1] = 1;
    final stack = <int>[0, run.length - 1];
    while (stack.isNotEmpty) {
      final last = stack.removeLast();
      final first = stack.removeLast();
      final ax = x(first);
      final ay = y(first);
      final dx = x(last) - ax;
      final dy = y(last) - ay;
      final len2 = dx * dx + dy * dy;
      var worst = -1;
      var worstM = toleranceM;
      for (var i = first + 1; i < last; i++) {
        final px = x(i) - ax;
        final py = y(i) - ay;
        final t = len2 == 0
            ? 0.0
            : ((px * dx + py * dy) / len2).clamp(0.0, 1.0).toDouble();
        final ex = px - dx * t;
        final ey = py - dy * t;
        final m = math.sqrt(ex * ex + ey * ey);
        if (m > worstM) {
          worst = i;
          worstM = m;
        }
      }
      if (worst >= 0) {
        keep[worst] = 1;
        stack.addAll([first, worst, worst, last]);
      }
    }
    return [
      for (var i = 0; i < run.length; i++)
        if (keep[i] == 1) run[i],
    ];
  }

  /// A* with straight-line distance as the (admissible) estimate.
  List<int>? _shortestPath(int source, int target) {
    if (source == target) return [source];
    final n = _lat.length;
    final g = Float64List(n)..fillRange(0, n, double.infinity);
    final prev = Int32List(n)..fillRange(0, n, -1);
    final closed = Uint8List(n);
    final heap = _MinHeap();
    final ty = _lat[target];
    final tx = _lng[target];
    g[source] = 0;
    heap.push(source, _haversineM(_lat[source], _lng[source], ty, tx));
    while (heap.isNotEmpty) {
      final u = heap.pop();
      if (closed[u] == 1) continue;
      closed[u] = 1;
      if (u == target) break;
      final next = _next[u];
      final cost = _cost[u];
      for (var i = 0; i < next.length; i++) {
        final v = next[i];
        if (closed[v] == 1) continue;
        final gv = g[u] + cost[i];
        if (gv < g[v]) {
          g[v] = gv;
          prev[v] = u;
          heap.push(v, gv + _haversineM(_lat[v], _lng[v], ty, tx));
        }
      }
    }
    if (prev[target] == -1) return null;
    final path = <int>[target];
    while (path.last != source) {
      path.add(prev[path.last]);
    }
    return path.reversed.toList();
  }
}

class _MinHeap {
  final List<int> _nodes = [];
  final List<double> _keys = [];

  bool get isNotEmpty => _nodes.isNotEmpty;

  void push(int node, double key) {
    _nodes.add(node);
    _keys.add(key);
    var i = _nodes.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_keys[parent] <= key) break;
      _nodes[i] = _nodes[parent];
      _keys[i] = _keys[parent];
      i = parent;
    }
    _nodes[i] = node;
    _keys[i] = key;
  }

  int pop() {
    final top = _nodes.first;
    final lastNode = _nodes.removeLast();
    final lastKey = _keys.removeLast();
    if (_nodes.isNotEmpty) {
      var i = 0;
      final n = _nodes.length;
      while (true) {
        final l = 2 * i + 1;
        if (l >= n) break;
        final r = l + 1;
        final c = r < n && _keys[r] < _keys[l] ? r : l;
        if (_keys[c] >= lastKey) break;
        _nodes[i] = _nodes[c];
        _keys[i] = _keys[c];
        i = c;
      }
      _nodes[i] = lastNode;
      _keys[i] = lastKey;
    }
    return top;
  }
}
