import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's look as the user picks it on the profile: light, dark, or the
/// phone's own setting. The pick is remembered across launches.
class AppearanceController extends ValueNotifier<ThemeMode> {
  AppearanceController({this.fallback = ThemeMode.light}) : super(fallback);

  /// The look until the user picks one.
  final ThemeMode fallback;

  static const _key = 'appearance';

  /// Reads the remembered pick, if there is one.
  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      value = ThemeMode.values.asNameMap()[saved] ?? fallback;
    } catch (error) {
      debugPrint('Reading the appearance failed: $error');
    }
  }

  /// Shows [mode] and remembers it.
  Future<void> pick(ThemeMode mode) async {
    value = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (error) {
      debugPrint('Saving the appearance failed: $error');
    }
  }
}
