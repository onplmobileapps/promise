import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_icon_tile.dart';
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A card that opens a part of the app: its 3D icon on a tile at the top,
/// and at the foot its [title], a line about it, and an arrow that says it
/// opens.
///
/// It is at least [AppSizes.moduleCardMinHeight] tall. Given more height,
/// as by an `AppGrid` row, the icon stays at the top and the text at the
/// foot.
class AppModuleCard extends StatelessWidget {
  const AppModuleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleSpan,
  });

  /// The title styled in parts, like an italic "e"; [title] by default.
  final InlineSpan? titleSpan;

  /// Shown on an [AppIconTile], [AppSizes.moduleIcon] across.
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      button: true,
      container: true,
      child: AppInkSurface(
        onTap: onTap,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.surfaceEnd],
          ),
          borderRadius: AppRadius.borderModule,
          border: Border.all(color: colors.outline),
          boxShadow: context.elevations.card,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // The words sit right under the icon however tall the card is
            // drawn beside a longer one; the arrow keeps the top corner.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // On a very narrow card, as a folding phone's cover screen,
                // the arrow shrinks so the icon keeps its size.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconTile(
                      size: AppSizes.moduleTile,
                      child: SizedBox.square(
                        dimension: AppSizes.moduleIcon,
                        child: icon,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [colors.tile, colors.tileEnd],
                                ),
                              ),
                              child: SizedBox.square(
                                dimension: AppSizes.moduleArrow,
                                child: Center(
                                  child: AppGlyphIcon(
                                    AppGlyphs.arrowUpRight,
                                    size: AppSizes.moduleArrowIcon,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapMd,
                Text.rich(
                  titleSpan ?? TextSpan(text: title),
                  style: text.titleLarge,
                ),
                AppSpacing.gapXxs,
                Text(
                  subtitle,
                  style: text.labelMedium?.copyWith(
                    fontWeight: AppFonts.regular,
                    height: AppFonts.cardLineHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
