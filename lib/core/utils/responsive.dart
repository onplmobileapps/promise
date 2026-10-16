import 'package:flutter/material.dart';

enum DeviceType { mobile, tablet, desktop }

/// Central place for breakpoints so every widget agrees on what counts
/// as "mobile" vs "tablet" vs "desktop".
class Responsive {
  Responsive._();

  static const double mobileMax = 700;
  static const double tabletMax = 1100;

  static DeviceType deviceTypeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMax) return DeviceType.mobile;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isMobile(BuildContext context) =>
      deviceTypeOf(context) == DeviceType.mobile;
  static double contentPadding(BuildContext context) {
    switch (deviceTypeOf(context)) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 32;
    }
  }
}
