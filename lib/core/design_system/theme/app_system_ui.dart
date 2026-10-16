import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';

/// How the status and navigation bars sit over the app.
///
/// The app draws edge to edge, so both bars are clear and only their icons
/// change: dark over the light theme, light over the dark one.
abstract final class AppSystemUi {
  static const SystemUiOverlayStyle lightTheme = SystemUiOverlayStyle(
    statusBarColor: AppPalette.transparent,
    // Android reads the icons' brightness, iOS the bar's.
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppPalette.transparent,
    systemNavigationBarDividerColor: AppPalette.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static const SystemUiOverlayStyle darkTheme = SystemUiOverlayStyle(
    statusBarColor: AppPalette.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: AppPalette.transparent,
    systemNavigationBarDividerColor: AppPalette.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// The style for a theme of [brightness].
  static SystemUiOverlayStyle of(Brightness brightness) =>
      brightness == Brightness.dark ? darkTheme : lightTheme;
}
