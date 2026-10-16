import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_breakpoints.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';

/// How much room a layout has across, after Material's window size classes.
enum WindowSizeClass {
  /// Phones in portrait.
  compact,

  /// Small tablets, unfolded foldables, phones in landscape.
  medium,

  /// Large tablets.
  expanded;

  static WindowSizeClass fromWidth(double width) {
    if (width >= AppBreakpoints.expanded) return expanded;
    if (width >= AppBreakpoints.medium) return medium;
    return compact;
  }

  /// Side margin of content in this size class.
  double get gutter => switch (this) {
    compact => AppSpacing.gutterCompact,
    medium => AppSpacing.gutterMedium,
    expanded => AppSpacing.gutterExpanded,
  };
}

/// The space a layout was given, as `ResponsiveBuilder` reports it.
@immutable
class LayoutInfo {
  const LayoutInfo(this.constraints);

  final BoxConstraints constraints;

  double get width => constraints.maxWidth;
  double get height => constraints.maxHeight;

  WindowSizeClass get sizeClass => WindowSizeClass.fromWidth(width);

  /// A phone on its side, or the keyboard taking half the screen.
  bool get isShort => height.isFinite && height < AppBreakpoints.shortHeight;

  bool get isCompact => sizeClass == WindowSizeClass.compact;

  double get gutter => sizeClass.gutter;
}
