import 'package:flutter/services.dart';

/// The app's settings for where it runs, read from a `.env` asset of
/// `KEY=value` lines: blank lines and `#` comments are skipped, and a
/// value may be wrapped in quotes.
abstract final class AppEnv {
  static final Map<String, String> _values = {};

  /// Reads [asset], such as `.env.prod`.
  static Future<void> load(String asset) async =>
      loadFromString(await rootBundle.loadString(asset));

  /// Reads settings from [text], over any read before.
  static void loadFromString(String text) {
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final split = line.indexOf('=');
      if (split <= 0) continue;
      final key = line.substring(0, split).trim();
      var value = line.substring(split + 1).trim();
      final quoted =
          value.length >= 2 &&
          (value.startsWith('"') && value.endsWith('"') ||
              value.startsWith("'") && value.endsWith("'"));
      if (quoted) value = value.substring(1, value.length - 1);
      _values[key] = value;
    }
  }

  /// The setting [key]; it must have been read.
  static String get(String key) =>
      _values[key] ?? (throw StateError('$key is not set in the .env file'));
}
