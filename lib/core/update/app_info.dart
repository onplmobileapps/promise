import 'package:flutter/services.dart';

/// The installed app's version, build and store ID, from the platform.
class AppInfo {
  const AppInfo({required this.version, required this.build, required this.id});

  static const _channel = MethodChannel('railway_hrms/app_info');
  static AppInfo? _info;

  /// Like "1.0.9".
  final String version;

  /// Like "10".
  final String build;

  /// The bundle ID on iOS, the package name on Android.
  final String id;

  /// Read once; null where the platform can't say, as in tests, and then
  /// asked again next time.
  static Future<AppInfo?> load() async => _info ??= await _load();

  static Future<AppInfo?> _load() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      if (info == null) return null;
      return AppInfo(
        version: info['version']?.toString() ?? '',
        build: info['build']?.toString() ?? '',
        id: info['id']?.toString() ?? '',
      );
    } on Exception {
      return null;
    }
  }

  /// Opens [url] in its store, or on Android the app's Play page when no
  /// [url] is given. False when nothing could be opened.
  static Future<bool> openStore([String? url]) async {
    try {
      return await _channel.invokeMethod<bool>('openStore', {'url': url}) ??
          false;
    } on Exception {
      return false;
    }
  }

  /// Whether [other] is a later version than [version], part by part:
  /// "1.0.10" is later than "1.0.9".
  bool isOlderThan(String other) {
    List<int> parts(String v) => [
      for (final part in v.split('.'))
        int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
    ];
    final mine = parts(version);
    final theirs = parts(other);
    for (var i = 0; i < theirs.length || i < mine.length; i++) {
      final a = i < mine.length ? mine[i] : 0;
      final b = i < theirs.length ? theirs[i] : 0;
      if (a != b) return a < b;
    }
    return false;
  }
}
