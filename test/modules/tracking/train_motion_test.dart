import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/train_motion.dart';

/// A straight stretch of track running east for [km] kilometres.
RoutePath _line(double km) {
  const start = LatLng(30, 70);
  final end = LatLng(
    30,
    70 + km * 1000 / (111320 * math.cos(30 * math.pi / 180)),
  );
  return RoutePath([
    for (var i = 0; i <= 100; i++)
      LatLng(30, start.longitude + (end.longitude - start.longitude) * i / 100),
  ]);
}

/// The point [m] metres along [path], nudged [sideM] metres north.
LatLng _at(RoutePath path, double m, {double sideM = 0}) {
  final p = path.fixAt(m).snapped;
  return LatLng(p.latitude + sideM / 110574, p.longitude);
}

TrainPosition _report(
  LatLng at,
  DateTime time, {
  double kmh = 72,
  double course = 90,
}) => TrainPosition(
  deviceId: 1,
  position: at,
  speedKmh: kmh,
  course: course,
  moving: kmh >= 3,
  validFix: true,
  fixTime: time,
);

/// Runs [motion] frame by frame at 60 fps from [from] for [seconds],
/// returning each frame's pose.
List<TrainPose> _frames(TrainMotion motion, DateTime from, double seconds) {
  final poses = <TrainPose>[];
  for (var ms = 0.0; ms <= seconds * 1000; ms += 1000 / 60) {
    final pose = motion.poseAt(
      from.add(Duration(microseconds: (ms * 1000).round())),
    );
    if (pose != null) poses.add(pose);
  }
  return poses;
}

void main() {
  final t0 = DateTime(2026, 10, 11, 12);

  test('rolls on smoothly between reports, never backwards', () {
    final path = _line(40);
    final motion = TrainMotion()..setPath(path);
    final random = math.Random(7);
    const speed = 20.0; // 72 km/h
    var last = double.negativeInfinity;
    var lastSpeed = -1.0;
    var worstJerk = 0.0;
    var worstGap = 0.0;
    for (var i = 0; i < 30; i++) {
      final time = t0.add(Duration(seconds: i * 10));
      // GPS scatter of ±25 m along and beside the track.
      final truth = 1000 + speed * i * 10;
      motion.report(
        _report(
          _at(
            path,
            truth + (random.nextDouble() - 0.5) * 50,
            sideM: (random.nextDouble() - 0.5) * 30,
          ),
          time,
        ),
        // Reports arrive a few seconds after their fix.
        time.add(const Duration(seconds: 3)),
      );
      final poses = _frames(motion, time.add(const Duration(seconds: 3)), 10);
      for (final (k, pose) in poses.indexed) {
        expect(pose.along, isNotNull);
        expect(pose.along!, greaterThanOrEqualTo(last - 1e-6));
        last = pose.along!;
        if (lastSpeed >= 0) {
          worstJerk = math.max(worstJerk, (pose.speedMps - lastSpeed).abs());
        }
        lastSpeed = pose.speedMps;
        if (i > 3) {
          final now = 3 + k / 60;
          worstGap = math.max(
            worstGap,
            (pose.along! - (truth + speed * now)).abs(),
          );
        }
      }
    }
    // No lurch from one frame to the next…
    expect(worstJerk, lessThan(1.5));
    // …and always close to where the train really is.
    expect(worstGap, lessThan(120));
  });

  test('rides out reports a minute or more apart without stopping', () {
    // As measured on Khyber Mail: 100 km/h, fixes 8 s to 96 s apart, some
    // reaching the phone 50 s late, even after the next one.
    final path = _line(80);
    final motion = TrainMotion()..setPath(path);
    const speed = 28.0;
    const gaps = [8, 66, 96, 8, 8, 70, 90, 8, 60, 96, 8, 8, 66, 90, 8, 96];
    final reports = <(double, double)>[]; // (fix s, arrives s)
    var fix = 0.0;
    for (final (i, gap) in gaps.indexed) {
      reports.add((fix, fix + (i.isEven ? 3 : 50)));
      fix += gap;
    }
    reports.sort((a, b) => a.$2.compareTo(b.$2));
    var next = 0;
    var last = double.negativeInfinity;
    var standing = 0.0;
    var fastest = 0.0;
    var worstGap = 0.0;
    for (var ms = 0.0; ms <= (fix - 30) * 1000; ms += 1000 / 60) {
      final clock = ms / 1000;
      while (next < reports.length && reports[next].$2 <= clock) {
        final (at, arrives) = reports[next++];
        motion.report(
          _report(
            _at(path, 2000 + speed * at),
            t0.add(Duration(milliseconds: (at * 1000).round())),
            kmh: speed * 3.6,
          ),
          t0.add(Duration(milliseconds: (arrives * 1000).round())),
        );
      }
      final pose = motion.poseAt(
        t0.add(Duration(microseconds: (ms * 1000).round())),
      );
      if (pose == null) continue;
      expect(pose.along!, greaterThanOrEqualTo(last - 1e-6));
      last = pose.along!;
      fastest = math.max(fastest, pose.speedMps);
      // Once it has caught up with the first reports.
      if (clock > 120) {
        if (pose.speedMps < 1) standing += 1 / 60;
        worstGap = math.max(
          worstGap,
          (pose.along! - (2000 + speed * clock)).abs(),
        );
      }
    }
    // It never stands still waiting for a late report…
    expect(standing, lessThan(1));
    // …never races far faster than the train…
    expect(fastest, lessThan(speed * 1.5 + 10));
    // …and stays near where the train really is.
    expect(worstGap, lessThan(700));
  });

  test('a train running its route the other way still moves', () {
    // The route runs east; the train goes west, as when a route is drawn
    // the wrong way round.
    final path = _line(30);
    final motion = TrainMotion()..setPath(path);
    double? last;
    TrainPose? end;
    for (var i = 0; i < 8; i++) {
      final time = t0.add(Duration(seconds: i * 10));
      motion.report(
        _report(_at(path, 20000 - 200.0 * i), time, course: 270),
        time,
      );
      for (final pose in _frames(motion, time, 10)) {
        // Once it has the direction, west only.
        if (i >= 3 && last != null) {
          expect(pose.along!, lessThanOrEqualTo(last + 1e-6));
        }
        last = pose.along;
        end = pose;
      }
    }
    // It kept up with the train and faces the way it goes.
    expect(end!.along, closeTo(20000 - 200.0 * 8, 300));
    expect(end.reversed, isTrue);
    expect((end.heading - 270).abs(), lessThan(10));
  });

  test('a report behind the last one is held, not followed back', () {
    final path = _line(10);
    final motion = TrainMotion()..setPath(path);
    motion.report(_report(_at(path, 5000), t0), t0);
    final before = _frames(motion, t0, 5).last.along!;
    // A report 300 m back: scatter, or a wrong snap.
    motion.report(
      _report(_at(path, 4700), t0.add(const Duration(seconds: 5))),
      t0.add(const Duration(seconds: 5)),
    );
    final after = _frames(motion, t0.add(const Duration(seconds: 5)), 5);
    expect(after.every((pose) => pose.along! >= before - 1e-6), isTrue);
  });

  test('comes gently to rest when reports stop', () {
    final path = _line(20);
    final motion = TrainMotion()..setPath(path);
    motion.report(_report(_at(path, 2000), t0), t0);
    final poses = _frames(motion, t0, 300);
    final end = poses.last;
    expect(end.speedMps, closeTo(0, 0.1));
    // It coasts on for about as long as reports may take, then stops: well
    // short of where it would be had it kept going all along.
    expect(end.along! - 2000, inInclusiveRange(20 * 60, 20 * 180));
    // Slowing down, never lurching to a stop.
    for (var i = 1; i < poses.length; i++) {
      expect((poses[i].speedMps - poses[i - 1].speedMps).abs(), lessThan(0.5));
    }
  });

  test('a stopped train stays where it stands', () {
    final path = _line(10);
    final motion = TrainMotion()..setPath(path);
    motion.report(_report(_at(path, 3000), t0, kmh: 0), t0);
    final poses = _frames(motion, t0, 30);
    expect(poses.last.along, closeTo(3000, 1));
    expect(poses.last.speedMps, 0);
  });

  test('jumps to a report far from where it is drawn', () {
    final path = _line(30);
    final motion = TrainMotion()..setPath(path);
    motion.report(_report(_at(path, 1000), t0), t0);
    _frames(motion, t0, 2);
    final later = t0.add(const Duration(minutes: 20));
    motion.report(_report(_at(path, 15000), later, kmh: 0), later);
    // 14 km behind: it fast-forwards there, smoothly.
    final poses = _frames(motion, later, 40);
    for (var i = 1; i < poses.length; i++) {
      expect(poses[i].along!, greaterThanOrEqualTo(poses[i - 1].along!));
    }
    expect(poses.last.along, closeTo(15000, 60));
    // Much further, after a long silence, it is moved there at once.
    final much = later.add(const Duration(hours: 1));
    motion.report(_report(_at(path, 29000), much, kmh: 0), much);
    expect(motion.poseAt(much)!.along, closeTo(29000, 60));
  });

  test('keeps its place when given a route later', () {
    final path = _line(20);
    final motion = TrainMotion();
    motion.report(_report(_at(path, 4000), t0), t0);
    final free = _frames(motion, t0, 2).last;
    expect(free.along, isNull);
    motion.setPath(path);
    final onRoute = motion.poseAt(t0.add(const Duration(milliseconds: 2016)))!;
    expect(onRoute.along, isNotNull);
    expect(haversineMeters(onRoute.point, free.point), lessThan(60));
  });

  test('slides onto a route found later rather than jumping to it', () {
    final path = _line(20);
    final motion = TrainMotion();
    // 200 m off the track, as a raw GPS fix can be.
    motion.report(_report(_at(path, 4000, sideM: 200), t0, kmh: 0), t0);
    final free = _frames(motion, t0, 1).last;
    motion.setPath(path);
    final first = motion.poseAt(t0.add(const Duration(milliseconds: 1016)))!;
    expect(haversineMeters(first.point, free.point), lessThan(20));
    final settled = _frames(
      motion,
      t0.add(const Duration(milliseconds: 1016)),
      1.5,
    ).last;
    expect(haversineMeters(settled.point, _at(path, 4000)), lessThan(5));
  });

  test('without a route it glides to each report, never backwards', () {
    final path = _line(20);
    final motion = TrainMotion();
    LatLng? last;
    for (var i = 0; i < 8; i++) {
      final time = t0.add(Duration(seconds: i * 10));
      motion.report(_report(_at(path, 2000 + 200.0 * i), time), time);
      for (final pose in _frames(motion, time, 10)) {
        if (last != null) {
          // Eastward only: longitude never falls back.
          expect(
            pose.point.longitude,
            greaterThanOrEqualTo(last.longitude - 1e-9),
          );
        }
        last = pose.point;
      }
    }
  });

  test('turns smoothly rather than snapping to a new heading', () {
    final motion = TrainMotion();
    motion.report(_report(const LatLng(30, 70), t0, course: 0), t0);
    _frames(motion, t0, 1);
    motion.report(
      _report(
        const LatLng(30.002, 70.002),
        t0.add(const Duration(seconds: 1)),
        course: 90,
      ),
      t0.add(const Duration(seconds: 1)),
    );
    final first = motion.poseAt(t0.add(const Duration(milliseconds: 1016)))!;
    // One frame on, it has only begun to turn towards the new heading.
    expect(first.heading, lessThan(30));
  });
}
