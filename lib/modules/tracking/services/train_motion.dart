import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

/// Where a train is drawn at a moment.
class TrainPose {
  const TrainPose({
    required this.point,
    required this.heading,
    required this.speedMps,
    this.along,
    this.reversed = false,
  });

  final LatLng point;

  /// Degrees clockwise from north.
  final double heading;

  /// How fast the drawn train is going, in metres a second.
  final double speedMps;

  /// Metres along the train's route, while it is on one.
  final double? along;

  /// The train runs its route from the end towards the start.
  final bool reversed;
}

/// Moves a train smoothly between its GPS reports, the way a navigation
/// app moves its car. Reports come in irregularly: a train at speed may
/// report every 8 s for a while, then go quiet for a minute or more.
///
/// Each report says where the train was and how fast it went; from it the
/// train's place now is predicted. The drawn train follows that prediction
/// like a weight on a spring: it speeds up or eases off to close the gap,
/// so it never jumps between reports nor stops and starts with each one.
/// On a route it runs along the track; it never runs backwards for GPS
/// scatter, it waits instead. Without new reports it carries on at the
/// last speed for about as long as the device usually takes to report
/// again, then comes gently to rest; a train far behind a late report
/// fast-forwards to it.
class TrainMotion {
  /// [maxStepS] is the longest step taken at once: a train stepped every
  /// frame keeps the default, one stepped only now and then, as off the
  /// screen, takes longer steps.
  TrainMotion({this.maxStepS = 0.25});

  /// The longest step taken at once, so a frame after a pause doesn't
  /// throw the train ahead.
  final double maxStepS;

  RoutePath? _path;
  _Report? _report;

  // What is drawn.
  double? _along;
  LatLng? _point;
  double _speed = 0;
  double? _heading;
  DateTime? _lastStep;

  /// How long after a fix the next one usually reaches the phone, learnt
  /// as reports come in: the time between fixes plus the delay in getting
  /// them here.
  double _silenceS = 120;

  /// Fast-forwarding to a report far ahead.
  bool _rush = false;

  /// Which way along its route the train runs: +1 from start to end, as
  /// it should, or -1 when its reports keep going the other way, as when a
  /// route is drawn the wrong way round. A train never "goes back" for
  /// scatter, so without this one running the other way would stand still.
  int _dir = 1;

  /// Reports in a row against [_dir]; two turn it round.
  int _against = 0;

  /// A move along the route at least this long counts for its direction;
  /// shorter is scatter.
  static const double _directionM = 300;

  /// The next pose is placed at the prediction outright, as after a long
  /// silence, when animating across the gap would mean nothing.
  bool _snap = false;

  /// A report this long after the previous one is shown where it is.
  static const Duration _snapAfter = Duration(minutes: 10);

  /// Where the train was drawn when it was put on a route, from which it
  /// slides onto the track rather than jumping there.
  LatLng? _slideFrom;
  DateTime? _slideStart;
  static const Duration _slide = Duration(milliseconds: 800);

  /// A report further than this from the route is off it.
  static const double onRouteM = 400;

  /// A report this far behind the previous one is a real move, as after a
  /// wrong snap or a shunt, not GPS scatter to hold against.
  static const double _backtrackM = 1500;

  /// Further than this from the prediction, the train is moved there at
  /// once rather than driven across the gap, as after a long silence.
  static const double _jumpM = 40000;

  /// Further behind the prediction than this, or than half a minute at
  /// its speed, the train fast-forwards.
  static const double _rushM = 1500;

  /// How quickly its speed follows a change, so it accelerates rather than
  /// lurching.
  static const double _speedEaseS = 0.6;

  /// How quickly it turns to a new heading.
  static const double _turnEaseS = 0.35;

  RoutePath? get path => _path;

  /// Whether a report has come in yet.
  bool get hasReport => _report != null;

  /// The train's route, or null while it has none. The drawn train and the
  /// last report are carried over to it.
  void setPath(RoutePath? path) {
    if (identical(path, _path)) return;
    final drawn = _drawnPoint;
    final hint = _along;
    _path = path;
    _along = null;
    if (path == null || path.isEmpty) {
      _path = null;
      _point = drawn;
      _report = _report?.offRoute();
      return;
    }
    if (drawn != null) {
      final fix = _place(path, drawn, hint);
      if (fix != null) {
        _along = fix.alongM;
        if (fix.offsetM > 1) {
          _slideFrom = drawn;
          _slideStart = null;
        }
      } else {
        _point = drawn;
      }
    }
    final report = _report;
    if (report != null) {
      final fix = _place(path, report.point, _along ?? hint);
      _report = report.withAlong(fix?.alongM);
    }
  }

  /// A new GPS report, received at [now].
  void report(TrainPosition position, DateTime now) {
    final previous = _report;
    if (previous != null && !position.fixTime.isAfter(previous.fixTime)) {
      return;
    }
    if (previous != null &&
        position.fixTime.difference(previous.fixTime) > _snapAfter) {
      _snap = true;
    }
    if (previous != null) {
      final silence = now.difference(previous.fixTime).inMilliseconds / 1000;
      if (silence > 0 && silence < 900) {
        // The longest lately, fading: a burst of quick reports mustn't stop
        // the train in the next long lull.
        _silenceS = math
            .max(silence.clamp(5.0, 240.0).toDouble(), _silenceS * 0.9)
            .clamp(8.0, 240.0)
            .toDouble();
      }
    }
    final speed = position.validFix && position.moving
        ? position.speedKmh / 3.6
        : 0.0;
    double? along;
    final path = _path;
    if (path != null) {
      along = _place(
        path,
        position.position,
        previous?.along ?? _along,
      )?.alongM;
    }
    final last = previous?.along;
    if (along != null && last != null) {
      final moved = along - last;
      if (moved.abs() >= _directionM) {
        if (moved.sign.toInt() == _dir) {
          _against = 0;
        } else if (++_against >= 2) {
          _dir = -_dir;
          _against = 0;
          _rush = false;
        }
      }
      final back = (last - along) * _dir;
      if (back > 0 && back < _backtrackM) {
        // Scatter: the train hasn't gone back, it's where it was.
        along = last;
      }
    }
    _report = _Report(
      point: position.position,
      along: along,
      speed: speed,
      course: position.course,
      moving: speed > 0,
      fixTime: position.fixTime,
      // A device clock ahead of the phone's would predict the future.
      time: position.fixTime.isAfter(now) ? now : position.fixTime,
    );
  }

  /// Where to draw the train at [now]; null before the first report.
  TrainPose? poseAt(DateTime now) {
    final report = _report;
    if (report == null) return null;
    final last = _lastStep;
    _lastStep = now;
    final dt = last == null
        ? 0.0
        : (now.difference(last).inMicroseconds / 1e6).clamp(0.0, maxStepS);
    final elapsed = (now.difference(report.time).inMicroseconds / 1e6).clamp(
      0.0,
      600.0,
    );
    final path = _path;
    final along = report.along;
    if (path != null && along != null) {
      return _alongRoute(path, report, along, elapsed.toDouble(), dt);
    }
    return _freely(report, elapsed.toDouble(), dt);
  }

  TrainPose _alongRoute(
    RoutePath path,
    _Report report,
    double reportAlong,
    double elapsed,
    double dt,
  ) {
    final dir = _dir.toDouble();
    final predicted = (reportAlong + dir * report.speed * _coast(elapsed))
        .clamp(0.0, path.lengthM)
        .toDouble();
    var drawn = _along;
    if (drawn == null || _snap || (predicted - drawn).abs() > _jumpM) {
      _snap = false;
      _rush = false;
      drawn = predicted;
      _speed = report.speed * _coastRate(elapsed);
    } else {
      // The gap ahead, in the train's own direction.
      final gap = (predicted - drawn) * dir;
      final rush = _rushing(gap, report.speed);
      final desired =
          (report.speed * _coastRate(elapsed) +
                  gap / _catchUp(rush, report.speed))
              .clamp(0.0, rush ? double.infinity : _maxSpeed(report.speed, gap))
              .toDouble();
      _speed += (desired - _speed) * _ease(dt, _speedEaseS);
      if (_speed < 0.05 && desired == 0) _speed = 0;
      drawn += dir * _speed * dt;
      // Never far ahead of where the train should be; never backwards.
      final lead = 10 + report.speed * 0.8;
      if ((drawn - predicted) * dir > lead) {
        final cap = predicted + dir * lead;
        drawn = dir > 0 ? math.max(_along!, cap) : math.min(_along!, cap);
      }
      drawn = drawn.clamp(0.0, path.lengthM).toDouble();
    }
    _along = drawn;
    final fix = path.fixAt(drawn);
    _point = fix.snapped;
    _turnTo(path.bearingAt(drawn, backwards: dir < 0), dt);
    return TrainPose(
      point: _slid(fix.snapped),
      heading: _heading!,
      speedMps: _speed,
      along: drawn,
      reversed: dir < 0,
    );
  }

  TrainPose _freely(_Report report, double elapsed, double dt) {
    final predicted = report.moving
        ? _move(report.point, report.course, report.speed * _coast(elapsed))
        : report.point;
    var drawn = _point;
    final gap = drawn == null ? 0.0 : haversineMeters(drawn, predicted);
    if (drawn == null || _snap || gap > _jumpM) {
      _snap = false;
      _rush = false;
      drawn = predicted;
      _speed = report.speed * _coastRate(elapsed);
      _heading ??= report.course;
    } else if (gap > 0.5) {
      final toward = bearingBetween(drawn, predicted);
      // A prediction behind the drawn train is scatter: wait for it.
      final behind = _heading != null && _angle(toward - _heading!).abs() > 100;
      final rush = _rushing(gap, report.speed);
      final desired = behind
          ? 0.0
          : (report.speed * _coastRate(elapsed) +
                    gap / _catchUp(rush, report.speed))
                .clamp(
                  0.0,
                  rush ? double.infinity : _maxSpeed(report.speed, gap),
                )
                .toDouble();
      _speed += (desired - _speed) * _ease(dt, _speedEaseS);
      final step = math.min(_speed * dt, gap);
      if (step > 0) drawn = _move(drawn, toward, step);
      if (!behind && step > 0.2) _turnTo(toward, dt);
    } else {
      _speed = 0;
    }
    if (report.moving && _heading == null) _heading = report.course;
    _heading ??= 0;
    _point = drawn;
    return TrainPose(point: drawn, heading: _heading!, speedMps: _speed);
  }

  /// [onTrack], or a point on the way to it while the train slides onto a
  /// route it has just been given.
  LatLng _slid(LatLng onTrack) {
    final from = _slideFrom;
    if (from == null) return onTrack;
    final now = _lastStep ?? DateTime.now();
    final start = _slideStart ??= now;
    final t = now.difference(start).inMicroseconds / _slide.inMicroseconds;
    if (t >= 1) {
      _slideFrom = null;
      return onTrack;
    }
    // Eased out: quick at first, settling onto the track.
    final k = 1 - math.pow(1 - t, 3).toDouble();
    return LatLng(
      from.latitude + (onTrack.latitude - from.latitude) * k,
      from.longitude + (onTrack.longitude - from.longitude) * k,
    );
  }

  LatLng? get _drawnPoint {
    final path = _path;
    final along = _along;
    if (path != null && along != null) return path.fixAt(along).snapped;
    return _point;
  }

  static RouteFix? _place(RoutePath path, LatLng point, double? near) {
    var fix = near == null
        ? null
        : path.locateNear(point, near, windowM: 15000);
    if (fix == null || fix.offsetM > onRouteM) fix = path.locate(point);
    return fix != null && fix.offsetM <= onRouteM ? fix : null;
  }

  void _turnTo(double target, double dt) {
    final heading = _heading;
    if (heading == null || dt == 0) {
      _heading = (target + 360) % 360;
      return;
    }
    _heading =
        (heading + _angle(target - heading) * _ease(dt, _turnEaseS)) % 360;
    if (_heading! < 0) _heading = _heading! + 360;
  }

  /// After a report the train keeps going at its speed for about as long
  /// as its device usually takes to report again…
  double get _coastFullS => _silenceS.clamp(20.0, 180.0).toDouble();

  /// …then slows to a stop over this long.
  double get _coastFadeS => (_silenceS * 0.5).clamp(15.0, 90.0).toDouble();

  /// How far, in seconds at the reported speed, the train is predicted to
  /// have gone [elapsed] seconds after a report: all of it at first, then
  /// less and less, so a silent train comes to rest.
  double _coast(double elapsed) {
    final full = _coastFullS;
    if (elapsed <= full) return elapsed;
    final fade = _coastFadeS;
    final over = math.min(elapsed - full, fade);
    return full + over - over * over / (2 * fade);
  }

  /// The rate [_coast] grows at: 1 while coasting, falling to 0.
  double _coastRate(double elapsed) {
    final full = _coastFullS;
    if (elapsed <= full) return 1;
    final over = elapsed - full;
    final fade = _coastFadeS;
    return over >= fade ? 0 : 1 - over / fade;
  }

  /// Whether the drawn train should fast-forward over [gap]: once far
  /// behind, until it is nearly there, so it doesn't crawl the last stretch.
  bool _rushing(double gap, double speed) {
    if (gap > math.max(_rushM, speed * 30)) {
      _rush = true;
    } else if (gap < 30 + speed * 2) {
      _rush = false;
    }
    return _rush;
  }

  /// How quickly the drawn train closes a gap to the prediction: gently,
  /// over a few seconds, or quickly when it is far behind a late report.
  double _catchUp(bool rush, double speed) => rush
      ? 2.0
      : speed == 0
      // A standing train is simply gone to.
      ? 3.0
      : (_silenceS / 12).clamp(3.0, 8.0).toDouble();

  /// The fastest the drawn train may go to catch up [gap] metres, short of
  /// rushing: a little faster than the train, more when further behind.
  static double _maxSpeed(double reported, double gap) =>
      reported * 1.3 + 6 + math.max(0.0, gap) / 30;

  static double _ease(double dt, double seconds) =>
      dt <= 0 ? 0 : 1 - math.exp(-dt / seconds);

  /// [degrees] folded into -180…180.
  static double _angle(double degrees) => (degrees + 540) % 360 - 180;

  /// [from] moved [meters] along [bearing].
  static LatLng _move(LatLng from, double bearing, double meters) {
    if (meters == 0) return from;
    final b = bearing * math.pi / 180;
    return LatLng(
      from.latitude + meters * math.cos(b) / 111320,
      from.longitude +
          meters *
              math.sin(b) /
              (111320 * math.cos(from.latitude * math.pi / 180)),
    );
  }
}

class _Report {
  const _Report({
    required this.point,
    required this.along,
    required this.speed,
    required this.course,
    required this.moving,
    required this.fixTime,
    required this.time,
  });

  final LatLng point;
  final double? along;

  /// Metres a second.
  final double speed;
  final double course;
  final bool moving;

  /// As the device reported it, for ordering reports.
  final DateTime fixTime;

  /// When the report holds, no later than when it arrived.
  final DateTime time;

  _Report offRoute() => withAlong(null);

  _Report withAlong(double? along) => _Report(
    point: point,
    along: along,
    speed: speed,
    course: course,
    moving: moving,
    fixTime: fixTime,
    time: time,
  );
}
