import 'dart:io';

enum DeviceTier { low, high }

/// Coarse device class used to scale ML work so capture stays smooth on
/// 2–3 GB phones and fast on flagships.
///
/// Android: RAM from /proc/meminfo (no plugin, no permission).
/// iOS: every iPhone on iOS 15+ is capable; only 2-core A9-era devices are
/// treated as low.
class DeviceTierDetector {
  DeviceTierDetector._();

  static DeviceTier? _cached;

  /// A "3 GB" phone reports ~2.7–2.9 GB MemTotal.
  static const int _lowRamKb = 3200 * 1024;

  static DeviceTier get tier => _cached ??= _detect();

  static DeviceTier _detect() {
    final cores = Platform.numberOfProcessors;
    if (Platform.isIOS) return cores <= 2 ? DeviceTier.low : DeviceTier.high;
    if (!Platform.isAndroid) return DeviceTier.high;

    if (cores <= 4) return DeviceTier.low;
    try {
      final memTotal = File(
        '/proc/meminfo',
      ).readAsLinesSync().firstWhere((l) => l.startsWith('MemTotal:'));
      final kb = int.parse(RegExp(r'\d+').firstMatch(memTotal)!.group(0)!);
      return kb <= _lowRamKb ? DeviceTier.low : DeviceTier.high;
    } catch (_) {
      return DeviceTier.low;
    }
  }
}
