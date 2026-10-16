import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';
import 'package:railway_hrms/core/design_system/theme/app_theme_data.dart';

/// The app's themes, built by the design system.
///
/// The colour constants below are for screens still being moved onto the
/// design system; they point at the same palette, so those screens already
/// wear the new colours. New code reads `context.colors` instead.
abstract final class AppTheme {
  static ThemeData get lightTheme => AppThemeData.light;
  static ThemeData get darkTheme => AppThemeData.dark;

  static const Color primary = AppPalette.jade700;
  static const Color primaryLight = AppPalette.jade100;
  static const Color primaryDark = AppPalette.jade800;
  static const Color secondary = AppPalette.ink900;
  static const Color accent = AppPalette.gold300;
  static const Color background = AppPalette.ivory100;
  static const Color surface = AppPalette.white;
  static const Color surfaceAlt = AppPalette.ivory300;
  static const Color border = AppPalette.sand200;
  static const Color borderStrong = AppPalette.sand400;
  static const Color textPrimary = AppPalette.ink900;
  static const Color textSecondary = AppPalette.ink700;
  static const Color textMuted = AppPalette.ink500;
  static const Color success = AppPalette.jade900;
  static const Color warning = AppPalette.gold800;
  static const Color danger = AppPalette.coral800;
}
