import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether this phone can be trusted to report where its user is: not
/// rooted, and not an emulator. Checked natively on Android; elsewhere the
/// phone counts as clean.
class DeviceIntegrity {
  final bool rooted;
  final bool emulator;

  /// What gave the phone away, for the logs.
  final List<String> reasons;

  const DeviceIntegrity({
    this.rooted = false,
    this.emulator = false,
    this.reasons = const [],
  });

  static const MethodChannel _channel = MethodChannel(
    'railway_hrms/device_integrity',
  );

  static Future<DeviceIntegrity>? _checked;

  /// Checked once a run; the phone doesn't change underneath the app.
  static Future<DeviceIntegrity> check() => _checked ??= _check();

  static Future<DeviceIntegrity> _check() async {
    try {
      final report = await _channel.invokeMapMethod<String, Object?>('check');
      final integrity = DeviceIntegrity.fromReport(report ?? const {});
      if (integrity.reasons.isNotEmpty) {
        debugPrint('Device integrity: ${integrity.reasons.join(', ')}');
      }
      return integrity;
    } on MissingPluginException {
      return const DeviceIntegrity();
    } catch (e) {
      debugPrint('Device integrity check failed: $e');
      _checked = null;
      return const DeviceIntegrity();
    }
  }

  factory DeviceIntegrity.fromReport(Map<String, Object?> report) =>
      DeviceIntegrity(
        rooted: report['rooted'] == true,
        emulator: report['emulator'] == true,
        reasons: [
          for (final r in (report['reasons'] as List?) ?? const []) '$r',
        ],
      );

  /// Why attendance can't be marked from this phone, or null when it can.
  /// Emulators are let through in debug builds, for testing.
  String? blockReason({bool allowEmulator = !kReleaseMode}) {
    if (rooted) {
      return "Attendance can't be marked on a rooted phone. Please use a "
          'phone that has not been rooted.';
    }
    if (emulator && !allowEmulator) {
      return "Attendance can't be marked from an emulator. Please use your "
          'phone.';
    }
    return null;
  }
}

/// The phone's location came from a fake GPS app.
class LocationSpoofedException implements Exception {
  const LocationSpoofedException();

  String get message =>
      'Fake location detected. Turn off any fake GPS app and mock location '
      'in Developer options, then try again.';

  @override
  String toString() => message;
}
