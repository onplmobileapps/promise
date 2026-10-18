import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_icon_tile.dart';
import 'package:railway_hrms/core/design_system/components/app_reveal.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_draw.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// What a list shows when it has nothing in it: a glyph on a 3D tile, a
/// [title], and a line saying what will appear.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.glyph,
    required this.title,
    this.message,
  });

  final AppGlyph glyph;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final message = this.message;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The tile rises in and its mark draws itself; the words follow.
          AppReveal(
            child: AppIconTile(
              size: AppSizes.emptyTile,
              child: AppGlyphDraw(
                glyph,
                size: AppSizes.iconXl,
                color: context.colors.iconAccent,
                delay: AppMotion.revealStagger * 2,
              ),
            ),
          ),
          AppSpacing.gapLg,
          AppReveal(
            index: 1,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapXs,
            AppReveal(
              index: 2,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
