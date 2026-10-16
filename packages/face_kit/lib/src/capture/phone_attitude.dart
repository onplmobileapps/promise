import 'dart:math' as math;

/// How far the phone leans back from upright, in degrees, from a gravity
/// reading in device axes (x to the right, y up the screen, z out of the
/// screen). Positive with the screen turned up towards the ceiling, when the
/// front camera looks up at the face from below the chin; negative with it
/// turned down. Null when the phone lies on its side, where no such lean can
/// be read.
double? phoneBackTilt(double x, double y, double z) {
  if (y.abs() < 1e-6 && z.abs() < 1e-6) return null;
  if (x.abs() > y.abs() && x.abs() > z.abs()) return null;
  // Platforms differ in the sign of gravity; the lean is the same either way.
  final sign = y < 0 ? -1.0 : 1.0;
  return math.atan2(z * sign, y.abs()) * 180 / math.pi;
}

/// Gravity from the accelerometer with hand jitter smoothed out.
class GravityFilter {
  GravityFilter({this.smoothing = 0.15});

  /// Share of each new reading taken in, 0–1.
  final double smoothing;

  (double, double, double)? _value;

  (double, double, double)? get value => _value;

  void add(double x, double y, double z) {
    final v = _value;
    if (v == null) {
      _value = (x, y, z);
      return;
    }
    final a = smoothing;
    _value = (
      v.$1 + (x - v.$1) * a,
      v.$2 + (y - v.$2) * a,
      v.$3 + (z - v.$3) * a,
    );
  }

  /// [phoneBackTilt] of the smoothed reading; null until one has arrived.
  double? get backTilt {
    final v = _value;
    return v == null ? null : phoneBackTilt(v.$1, v.$2, v.$3);
  }
}
