import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Rows of a list on one card, with a hairline between them.
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.outline),
        boxShadow: context.elevations.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderXl,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            // As tall as its rows, even in a sheet.
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.outline),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of a list: a [leading] mark; its [title], with a [meta] such as
/// a time beside it and a [subtitle] under it; and a [trailing] value or
/// control. With [onTap] it is a button, and [showChevron] says it opens
/// something. A [selected] row is washed in the brand's tint.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.meta,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final String? meta;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final subtitle = this.subtitle;
    final meta = this.meta;
    final leading = this.leading;
    final trailing = this.trailing;
    // Read as one: the title, what it says, and the control at its end.
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        selected: selected,
        // The tint is the row's own surface, so a press still shows on it.
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: selected
                ? colors.primaryContainer
                : colors.primaryContainer.withValues(alpha: 0),
          ),
          duration: AppMotion.short,
          builder: (context, tint, child) => Material(
            type: MaterialType.transparency,
            child: Ink(color: tint, child: child),
          ),
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    AppHaptics.select();
                    onTap!();
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.listRowMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + AppSpacing.xxs,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: subtitle == null
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[leading, AppSpacing.gapMd],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: text.labelLarge?.copyWith(
                                    fontWeight: subtitle == null
                                        ? AppFonts.medium
                                        : AppFonts.semiBold,
                                  ),
                                ),
                              ),
                              if (meta != null) ...[
                                AppSpacing.gapSm,
                                Text(
                                  meta,
                                  style: text.bodySmall?.copyWith(
                                    fontFeatures: AppFonts.tabularFigures,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (subtitle != null) ...[
                            AppSpacing.gapXxs,
                            Text(
                              subtitle,
                              style: text.labelMedium?.copyWith(
                                fontWeight: AppFonts.regular,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[AppSpacing.gapSm, trailing],
                    if (showChevron) ...[
                      AppSpacing.gapXs,
                      AppGlyphIcon(
                        AppGlyphs.chevronRight,
                        size: AppSizes.iconSm,
                        color: colors.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
