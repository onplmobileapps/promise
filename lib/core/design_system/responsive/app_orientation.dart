import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/foundations/app_breakpoints.dart';

/// Which ways up the app turns: a phone stays upright, a tablet turns with
/// the device. Android opens upright from its manifest, so a phone held on
/// its side never flashes a landscape first frame; [apply] frees a tablet
/// from there.
abstract final class AppOrientation {
  /// Whether this device is a phone: narrower than a small tablet on its
  /// shorter side.
  static bool get isPhone {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return true;
    final view = views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    // Not laid out yet: taken as a phone, the common case.
    if (size.isEmpty) return true;
    return size.shortestSide < AppBreakpoints.medium;
  }

  /// The app's own orientations: upright on a phone, any on a tablet. At
  /// start, and after a screen that held the device upright for itself.
  static Future<void> apply() => SystemChrome.setPreferredOrientations(
    isPhone ? const [DeviceOrientation.portraitUp] : const [],
  );

  /// Upright on any device, for a screen that needs it, such as a camera
  /// framing a card; [apply] lets go.
  static Future<void> holdUpright() => SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );
}
