import 'package:flutter/widgets.dart';

/// The spacing scale, on a 4-point grid. Layouts use these steps and
/// nothing in between.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;

  /// Between [sm] and [md]: the gap between a header's brand and buttons.
  static const double smd = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  /// Side margins of a screen's content, by window width.
  static const double gutterCompact = xl;

  /// The home screen's tighter side margin on a phone.
  static const double gutterHome = lg;
  static const double gutterMedium = xxxl;
  static const double gutterExpanded = huge;

  static const SizedBox gapXxs = SizedBox.square(dimension: xxs);
  static const SizedBox gapXs = SizedBox.square(dimension: xs);
  static const SizedBox gapSm = SizedBox.square(dimension: sm);
  static const SizedBox gapSmd = SizedBox.square(dimension: smd);
  static const SizedBox gapMd = SizedBox.square(dimension: md);
  static const SizedBox gapLg = SizedBox.square(dimension: lg);
  static const SizedBox gapXl = SizedBox.square(dimension: xl);
  static const SizedBox gapXxl = SizedBox.square(dimension: xxl);
  static const SizedBox gapXxxl = SizedBox.square(dimension: xxxl);
}
