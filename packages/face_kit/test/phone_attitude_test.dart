import 'package:face_kit/src/capture/phone_attitude.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const g = 9.81;

  test('an upright phone leans neither way', () {
    expect(phoneBackTilt(0, g, 0), closeTo(0, 0.01));
  });

  test('a phone held low and turned up at the face leans back', () {
    // Screen turned 45° towards the ceiling.
    expect(phoneBackTilt(0, g * 0.707, g * 0.707), closeTo(45, 0.5));
    // Lying flat, screen up.
    expect(phoneBackTilt(0, 0, g), closeTo(90, 0.5));
  });

  test('a phone turned down leans forward', () {
    expect(phoneBackTilt(0, g * 0.866, -g * 0.5), closeTo(-30, 0.5));
  });

  test('platforms that report gravity the other way read the same', () {
    expect(phoneBackTilt(0, -g * 0.707, -g * 0.707), closeTo(45, 0.5));
  });

  test('a phone on its side has no lean to read', () {
    expect(phoneBackTilt(g, 0.5, 0.5), isNull);
  });

  test('the filter smooths jitter', () {
    final filter = GravityFilter(smoothing: 0.5)..add(0, g, 0);
    expect(filter.backTilt, closeTo(0, 0.01));
    filter.add(0, 0, g);
    // Half way between upright and flat after one reading.
    expect(filter.backTilt, closeTo(45, 0.5));
  });
}
