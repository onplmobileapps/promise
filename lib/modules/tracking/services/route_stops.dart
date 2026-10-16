import 'dart:math' as math;

import 'package:railway_hrms/core/utils/equatable.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

/// A station on a train's route and how far along the route it is.
class RouteStop extends Equatable {
  final TrainStation station;
  final double km;

  /// One of the train's own stations (origin, a scheduled stop or the
  /// destination), rather than one it only passes.
  final bool scheduled;

  const RouteStop(this.station, this.km, {this.scheduled = false});

  @override
  List<Object?> get props => [station, km, scheduled];
}

/// The train's own stations, from its detail (`tracking/mobile/<id>/`),
/// in the order the API gives them, each with how far along [path] it is.
/// Nothing is added: no station the train only passes, no coordinates of
/// the app's own. A station the API sends without coordinates keeps its
/// place in the order, as far along as the one before it.
List<RouteStop> stopsAlong(RoutePath path, List<TrainStation> journey) {
  final stops = <RouteStop>[];
  var km = 0.0;
  for (final station in journey) {
    final at = station.position;
    final fix = at == null || path.isEmpty ? null : path.locate(at);
    if (fix != null) km = math.max(km, fix.alongM / 1000);
    stops.add(RouteStop(station, km, scheduled: true));
  }
  return stops;
}

/// The first of [stops] still ahead of a train [coveredKm] along the route;
/// null once it has passed them all. A stop less than [atStationKm] ahead
/// counts as reached.
int? nextStopIndex(
  List<RouteStop> stops,
  double coveredKm, {
  double atStationKm = 0.3,
}) {
  for (var i = 0; i < stops.length; i++) {
    if (stops[i].km > coveredKm + atStationKm) return i;
  }
  return null;
}

/// When [stop] is due by the timetable, on the journey that began on
/// [runDate], or null without one. Times run past midnight on a long
/// journey, so each stop is placed on the first day after [after] (the
/// previous stop's time) that keeps them in order.
DateTime? scheduledAt(RouteStop stop, DateTime? runDate, {DateTime? after}) {
  final raw = stop.station.arrivalTime ?? stop.station.departureTime;
  if (raw == null || runDate == null) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  var at = DateTime(runDate.year, runDate.month, runDate.day, h, m);
  while (after != null && at.isBefore(after)) {
    at = at.add(const Duration(days: 1));
  }
  return at;
}
