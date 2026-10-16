import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_tile_button.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The way back off a screen: the design's raised tile with a chevron.
/// It goes back a page unless [onPressed] says otherwise.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.tooltip});

  final VoidCallback? onPressed;

  /// Read by screen readers; "Back" by default.
  final String? tooltip;

  @override
  Widget build(BuildContext context) => AppTileButton(
    icon: const AppGlyphIcon(AppGlyphs.chevronLeft, size: AppSizes.iconMd),
    tooltip: tooltip ?? MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
  );
}

/// The back tile's face alone, for a button that takes the tap itself,
/// like the one an `AppBar` puts at its start.
class AppBackFace extends StatelessWidget {
  const AppBackFace({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
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
          child: AppGlyphIcon(
            AppGlyphs.chevronLeft,
            size: AppSizes.iconMd,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
