import 'dart:math' as math;
import 'dart:typed_data';

import 'package:maplibre_gl/maplibre_gl.dart';

double haversineMeters(LatLng a, LatLng b) {
  const d2r = math.pi / 180;
  final sLat = math.sin((b.latitude - a.latitude) * d2r / 2);
  final sLng = math.sin((b.longitude - a.longitude) * d2r / 2);
  final h =
      sLat * sLat +
      math.cos(a.latitude * d2r) * math.cos(b.latitude * d2r) * sLng * sLng;
  return 2 * 6371000.0 * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Where a point lies along a [RoutePath].
class RouteFix {
  /// Index of the route segment (from point [segment] to [segment] + 1).
  final int segment;

  /// The point moved onto the route.
  final LatLng snapped;

  /// Distance from the start of the route to [snapped].
  final double alongM;

  /// Distance from the point to the route.
  final double offsetM;

  const RouteFix(this.segment, this.snapped, this.alongM, this.offsetM);
}

/// A polyline with precomputed distances, for locating points along it.
class RoutePath {
  RoutePath(this.points) : _cumulative = _cumulativeMeters(points);

  final List<LatLng> points;
  final Float64List _cumulative;

  double get lengthM => _cumulative.isEmpty ? 0 : _cumulative.last;
  bool get isEmpty => points.length < 2;

  static Float64List _cumulativeMeters(List<LatLng> points) {
    final out = Float64List(points.length);
    for (var i = 1; i < points.length; i++) {
      out[i] = out[i - 1] + haversineMeters(points[i - 1], points[i]);
    }
    return out;
  }

  /// Closest point of the route to [p].
  RouteFix? locate(LatLng p) =>
      isEmpty ? null : _locateIn(p, 0, points.length - 2);

  /// Closest point to [p] on the stretch of route within [windowM] of
  /// [nearM] along it. Where the line passes close to itself, as it does
  /// around junctions and loops, a point is then placed where the train
  /// was, not on a far part of the route that happens to lie nearer.
  RouteFix? locateNear(LatLng p, double nearM, {double windowM = 20000}) {
    if (isEmpty) return null;
    return _locateIn(
      p,
      _segmentAt((nearM - windowM).clamp(0.0, lengthM).toDouble()),
      _segmentAt((nearM + windowM).clamp(0.0, lengthM).toDouble()),
    );
  }

  RouteFix? _locateIn(LatLng p, int first, int last) {
    // Local flat projection around p, in metres; accurate at these scales.
    const mPerDegLat = 110574.0;
    final mPerDegLng = 111320.0 * math.cos(p.latitude * math.pi / 180);
    RouteFix? best;
    for (var i = first; i <= last; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ax = (a.longitude - p.longitude) * mPerDegLng;
      final ay = (a.latitude - p.latitude) * mPerDegLat;
      final bx = (b.longitude - p.longitude) * mPerDegLng;
      final by = (b.latitude - p.latitude) * mPerDegLat;
      final dx = bx - ax;
      final dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0
          ? 0.0
          : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0).toDouble();
      final cx = ax + dx * t;
      final cy = ay + dy * t;
      final offset = math.sqrt(cx * cx + cy * cy);
      if (best == null || offset < best.offsetM) {
        best = RouteFix(
          i,
          LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          ),
          _cumulative[i] + (_cumulative[i + 1] - _cumulative[i]) * t,
          offset,
        );
      }
    }
    return best;
  }

  /// The route up to [fix] and from [fix] on.
  (List<LatLng>, List<LatLng>) splitAt(RouteFix fix) => (
    [...points.sublist(0, fix.segment + 1), fix.snapped],
    [fix.snapped, ...points.sublist(fix.segment + 1)],
  );

  /// Index of the segment containing the point [alongM] from the start.
  int _segmentAt(double alongM) {
    var lo = 0;
    var hi = points.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_cumulative[mid] <= alongM) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// The point [alongM] metres from the start, clamped to the route.
  RouteFix fixAt(double alongM) {
    final d = alongM.clamp(0.0, lengthM).toDouble();
    final i = _segmentAt(d);
    final len = _cumulative[i + 1] - _cumulative[i];
    final t = len == 0 ? 0.0 : (d - _cumulative[i]) / len;
    final a = points[i];
    final b = points[i + 1];
    return RouteFix(
      i,
      LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ),
      d,
      0,
    );
  }

  /// The stretch of route from [fromM] to [toM] metres along it.
  List<LatLng> slice(double fromM, double toM) {
    if (isEmpty) return const [];
    final from = fromM.clamp(0.0, lengthM).toDouble();
    final to = toM.clamp(from, lengthM).toDouble();
    final first = fixAt(from);
    final last = fixAt(to);
    return [
      first.snapped,
      for (var i = first.segment + 1; i <= last.segment; i++) points[i],
      last.snapped,
    ];
  }

  /// Distance along the route in Web Mercator units, which is what a map
  /// measures a line's progress in (`line-progress`); built on first use.
  late final Float64List _mercator = _cumulativeMercator(points);

  static Float64List _cumulativeMercator(List<LatLng> points) {
    double y(LatLng p) {
      final lat = p.latitude.clamp(-85.0, 85.0) * math.pi / 180;
      return math.log(math.tan(math.pi / 4 + lat / 2));
    }

    final out = Float64List(points.length);
    for (var i = 1; i < points.length; i++) {
      final dx =
          (points[i].longitude - points[i - 1].longitude) * math.pi / 180;
      final dy = y(points[i]) - y(points[i - 1]);
      out[i] = out[i - 1] + math.sqrt(dx * dx + dy * dy);
    }
    return out;
  }

  /// How far along the route [alongM] metres is, from 0 to 1, as the map
  /// measures it: the stop to colour a `line-gradient` at.
  double progressAt(double alongM) {
    if (isEmpty || _mercator.last == 0) return 0;
    final d = alongM.clamp(0.0, lengthM).toDouble();
    final i = _segmentAt(d);
    final len = _cumulative[i + 1] - _cumulative[i];
    final t = len == 0 ? 0.0 : (d - _cumulative[i]) / len;
    final m = _mercator[i] + (_mercator[i + 1] - _mercator[i]) * t;
    return (m / _mercator.last).clamp(0.0, 1.0).toDouble();
  }

  /// Compass bearing of the route at [alongM], averaged over [spanM] ahead
  /// so small kinks in the track don't twitch a marker.
  double bearingAt(
    double alongM, {
    double spanM = 120,
    bool backwards = false,
  }) {
    if (backwards) {
      // Facing the route's start, as a train running it the other way.
      return bearingBetween(
        fixAt(alongM + spanM / 4).snapped,
        fixAt(alongM - spanM).snapped,
      );
    }
    final from = fixAt(alongM - spanM / 4).snapped;
    final to = fixAt(alongM + spanM).snapped;
    return bearingBetween(from, to);
  }
}

/// Compass bearing from [a] to [b], in degrees clockwise from north.
double bearingBetween(LatLng a, LatLng b) {
  const d2r = math.pi / 180;
  final lat1 = a.latitude * d2r;
  final lat2 = b.latitude * d2r;
  final dLng = (b.longitude - a.longitude) * d2r;
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) / d2r + 360) % 360;
}
