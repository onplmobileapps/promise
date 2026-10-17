import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Switches for features that are turned on or off for a build, in one
/// place.
abstract final class AppFlags {
  /// Whether the switches for testing show on the profile: in debug and
  /// profile builds, never in a release.
  static bool get testingTools => !kReleaseMode;

  /// Whether an inspection checks the inspector — their face, and that the
  /// phone is at their workplace — as it starts and before its report is
  /// sent. The face server does both: it is sent the face with where the
  /// phone is, and turns away a phone away from the office.
  ///
  /// Off, an inspection opens straight away and is sent with no check: for
  /// testing away from the office, as at home. Turn it off with the switch
  /// on the profile (outside a release), or for one run:
  ///
  ///     flutter run --dart-define=INSPECTION_CHECKS=false
  ///
  /// A release always checks, whatever was switched before.
  static bool inspectionFaceCheck = _inspectionChecksByDefault;

  static const bool _inspectionChecksByDefault = bool.fromEnvironment(
    'INSPECTION_CHECKS',
    defaultValue: true,
  );

  static const String _inspectionChecksKey = 'testing_inspection_checks';

  /// Turns the inspection checks off ([inspectionFaceCheck]), or on again.
  static void bypassInspectionChecks({bool bypass = true}) =>
      inspectionFaceCheck = !bypass;

  /// Takes up the switches as last left, outside a release.
  static void restore(SharedPreferences prefs) {
    if (!testingTools) {
      inspectionFaceCheck = true;
      return;
    }
    inspectionFaceCheck =
        prefs.getBool(_inspectionChecksKey) ?? _inspectionChecksByDefault;
  }

  /// Switches the inspection checks [on] or off, and keeps it so.
  static Future<void> setInspectionChecks(
    bool on,
    SharedPreferences prefs,
  ) async {
    inspectionFaceCheck = on;
    await prefs.setBool(_inspectionChecksKey, on);
  }
}
