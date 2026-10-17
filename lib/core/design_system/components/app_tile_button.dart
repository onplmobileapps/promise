import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A square icon button for a screen's header, raised a little off the
/// page, with an optional [count] badge on its corner.
class AppTileButton extends StatelessWidget {
  const AppTileButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
  });

  /// Drawn in the middle, about 20 across.
  final Widget icon;

  /// Shown on long press and read by screen readers.
  final String tooltip;
  final VoidCallback? onPressed;

  /// Shown on the badge when above zero.
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = Tooltip(
      message: tooltip,
      child: AppInkSurface(
        onTap: onPressed == null
            ? null
            : () {
                AppHaptics.press();
                onPressed!();
              },
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.surfaceEnd],
          ),
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: colors.outline),
          boxShadow: context.elevations.raised,
        ),
        child: SizedBox.square(
          dimension: AppSizes.headerControl,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(
                color: colors.textPrimary,
                size: AppSizes.iconMd,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
    // A 42dp face inside a full 48dp tap target.
    return SizedBox.square(
      dimension: AppSizes.minTapTarget,
      child: Center(
        child: Badge.count(
          count: count,
          isLabelVisible: count > 0,
          backgroundColor: colors.danger,
          textColor: colors.onDanger,
          child: button,
        ),
      ),
    );
  }
}
