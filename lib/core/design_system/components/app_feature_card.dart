import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_tag.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/app_tone.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A card that says plainly what a feature does and has the key that does
/// it: a jade key with its [glyph], a [title] and a line of [message],
/// small [tags] for what it covers, and a full-width [actionLabel] key.
/// For things people might not find from an icon alone, like downloading
/// their attendance.
class AppFeatureCard extends StatelessWidget {
  const AppFeatureCard({
    super.key,
    required this.glyph,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.actionGlyph,
    this.tags = const [],
  });

  final AppGlyph glyph;
  final String title;
  final String message;
  final List<String> tags;
  final String actionLabel;
  final AppGlyph? actionGlyph;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.dayPresent, colors.surface, colors.surfaceEnd],
          stops: const [0, 0.55, 1],
        ),
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.dayPresentEdge),
        boxShadow: context.elevations.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppButton.keyGradient(
                        colors.primaryHighlight,
                        colors.primary,
                        colors.primaryShade,
                      ),
                      borderRadius: AppRadius.borderLg,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primaryEdge,
                          offset: const Offset(0, AppSizes.keyEdgePressed * 2),
                        ),
                      ],
                    ),
                    child: SizedBox.square(
                      dimension: AppSizes.featureKey,
                      child: Center(
                        child: AppGlyphIcon(
                          glyph,
                          size: AppSizes.featureGlyph,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: text.titleMedium),
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        message,
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tags.isNotEmpty) ...[
              AppSpacing.gapSm,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in tags) AppTag(tag, tone: AppTone.brand),
                ],
              ),
            ],
            AppSpacing.gapMd,
            AppButton(
              label: actionLabel,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
              leadingGlyph: actionGlyph,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
