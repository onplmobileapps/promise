import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';

/// How much drawing a phone can keep up with on a live map.
enum MapTier {
  /// Every frame, up to 60 a second, trains in 3D close up.
  smooth,

  /// About 30 updates a second, still in 3D.
  steady,

  /// About 20 a second, and flat trains close up instead of 3D ones.
  light,
}

/// Paces a live map's updates to the phone it runs on. Every update the
/// map takes (moving a train, the camera) is timed from sending to the map
/// saying it is done; while those round trips stay short the map is fed
/// every frame, up to 60 a second even on a 120 Hz screen, and when they
/// grow, as on a low-end phone or one that is busy, it is fed less often
/// and given less to draw, so it never falls behind and stutters. Trains
/// move by the clock, not by frames, so fewer updates mean fewer steps,
/// never a slower or jerkier train.
class MapPacer {
  MapPacer({MapTier start = MapTier.smooth, this.flat = false}) : _tier = start;

  /// For this phone: on one drawing lite, the map starts at 30 updates a
  /// second and its trains are always flat.
  factory MapPacer.forPhone() => AppPerformance.lite
      ? MapPacer(start: MapTier.steady, flat: true)
      : MapPacer();

  /// Trains are never drawn in 3D.
  final bool flat;

  MapTier _tier;

  /// The average round trip of an update, in milliseconds.
  double _tripMs = 0;
  int _trips = 0;

  /// When the tier last changed, so it doesn't flicker between two.
  DateTime _changedAt = DateTime(0);

  /// Round trips longer than these, on average, step the map down; shorter
  /// than the step-up marks, back up.
  static const double _steadyAboveMs = 14;
  static const double _lightAboveMs = 26;
  static const double _smoothBelowMs = 9;
  static const double _steadyBelowMs = 18;

  /// Least time between two tier changes.
  static const Duration _settle = Duration(seconds: 3);

  MapTier get tier => _tier;

  /// The least time between two updates of the map.
  Duration get gap => switch (_tier) {
    MapTier.smooth => const Duration(microseconds: 16000),
    MapTier.steady => const Duration(milliseconds: 33),
    MapTier.light => const Duration(milliseconds: 50),
  };

  /// Trains may be drawn in 3D close up.
  bool get draws3d => !flat && _tier != MapTier.light;

  /// The average round trip so far, in milliseconds.
  double get tripMs => _tripMs;

  /// One update took [trip] from sending to done. Returns whether the tier
  /// changed.
  bool took(Duration trip, {DateTime? now}) {
    final ms = trip.inMicroseconds / 1000;
    // Quick to learn at first, then a steady average.
    final weight = _trips < 10 ? 0.3 : 0.08;
    _tripMs = _trips == 0 ? ms : _tripMs * (1 - weight) + ms * weight;
    _trips++;
    if (_trips < 8) return false;
    final at = now ?? DateTime.now();
    if (at.difference(_changedAt) < _settle) return false;
    final next = switch (_tier) {
      MapTier.smooth when _tripMs > _steadyAboveMs => MapTier.steady,
      MapTier.steady when _tripMs > _lightAboveMs => MapTier.light,
      MapTier.steady when _tripMs < _smoothBelowMs => MapTier.smooth,
      MapTier.light when _tripMs < _steadyBelowMs => MapTier.steady,
      _ => _tier,
    };
    if (next == _tier) return false;
    _tier = next;
    _changedAt = at;
    return true;
  }
}
