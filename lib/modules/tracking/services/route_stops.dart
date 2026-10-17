import 'dart:math' as math;

import 'package:railway_hrms/core/utils/equatable.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/track_history_store.dart';

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

/// Each stop's timetable time, from the day the journey began, each on the
/// first day that keeps them in order (a journey runs past midnight).
List<DateTime?> timetableOf(List<RouteStop> stops, DateTime? day) {
  final due = <DateTime?>[];
  DateTime? last;
  for (final stop in stops) {
    final at = scheduledAt(stop, day, after: last);
    due.add(at);
    if (at != null) last = at;
  }
  return due;
}

/// A train this close to a station has reached it.
const double reachedWithinKm = 1.5;

/// When the train reached each stop: the time of its first GPS report
/// within [reachedWithinKm] of it after the stop before it was reached,
/// counting only reports from [since] on (this journey's). Null where it
/// hasn't been seen there — not yet, or while no one watched. (A
/// dispatch's time is when it was entered, not when the train left, so it
/// isn't taken as one.)
List<DateTime?> reachedAt(
  List<RouteStop> stops,
  List<TrackFix> fixes, {
  DateTime? since,
}) {
  final reached = List<DateTime?>.filled(stops.length, null);
  if (stops.isEmpty) return reached;
  final mine = [
    for (final fix in fixes)
      if (since == null || !fix.$1.isBefore(since)) fix,
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  var from = 0;
  for (var i = 0; i < stops.length; i++) {
    final at = stops[i].station.position;
    if (at == null) continue;
    for (var k = from; k < mine.length; k++) {
      if (haversineMeters(mine[k].$2, at) <= reachedWithinKm * 1000) {
        reached[i] = mine[k].$1;
        from = k;
        break;
      }
    }
  }
  return reached;
}

/// How late the train is running, at the last stop it reached that has a
/// timetable time; negative when early, null when nothing says.
Duration? delayNow(List<DateTime?> due, List<DateTime?> reached) {
  for (var i = math.min(due.length, reached.length) - 1; i >= 0; i--) {
    final d = due[i];
    final r = reached[i];
    if (d != null && r != null) return r.difference(d);
  }
  return null;
}

/// How late the train is where it is: when its report put it [coveredKm]
/// along the route, against when the timetable has it there — between the
/// two timetabled stops either side, in proportion to the distance. Null
/// off the timetable.
Duration? delayAtPosition(
  List<RouteStop> stops,
  List<DateTime?> due,
  double coveredKm,
  DateTime reportedAt,
) {
  int? before;
  for (var i = 0; i < stops.length && i < due.length; i++) {
    if (due[i] == null) continue;
    if (stops[i].km <= coveredKm) {
      before = i;
      continue;
    }
    final b = before;
    if (b == null) return null;
    final span = stops[i].km - stops[b].km;
    final share = span <= 0 ? 1.0 : (coveredKm - stops[b].km) / span;
    final gap = due[i]!.difference(due[b]!);
    final dueHere = due[b]!.add(gap * share);
    return reportedAt.difference(dueHere);
  }
  // Past the last timetabled stop: as late as there.
  final b = before;
  return b == null ? null : reportedAt.difference(due[b]!);
}

/// [delay] in words: "On time" within two minutes, else "12 min late",
/// "6 h 54 min late" or "5 min early".
String delayLabel(Duration delay) {
  final minutes = delay.inMinutes;
  if (minutes.abs() <= 2) return 'On time';
  final size = minutes.abs();
  final text = size < 60
      ? '$size min'
      : size % 60 == 0
      ? '${size ~/ 60} h'
      : '${size ~/ 60} h ${size % 60} min';
  return minutes > 0 ? '$text late' : '$text early';
}
