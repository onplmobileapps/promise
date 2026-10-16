import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/app_tone.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// An icon on a small tile tinted by [tone]: the mark at the start of a
/// list row.
class AppToneIcon extends StatelessWidget {
  const AppToneIcon({
    super.key,
    required this.glyph,
    this.tone = AppTone.neutral,
    this.size = AppSizes.toneTile,
  });

  final AppGlyph glyph;
  final AppTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tone.colorsIn(context.colors);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.borderMd,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: AppGlyphIcon(glyph, size: AppSizes.iconMd, color: foreground),
        ),
      ),
    );
  }
}
