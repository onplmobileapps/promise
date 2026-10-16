import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The face every card of a screen shares: white shading into ivory, a
/// hairline edge and a soft shadow, with corners of [radius].
BoxDecoration appCardDecoration(
  BuildContext context, {
  BorderRadius radius = AppRadius.borderXl,
}) {
  final colors = context.colors;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [colors.surface, colors.surfaceEnd],
    ),
    borderRadius: radius,
    border: Border.all(color: colors.outline),
    boxShadow: context.elevations.card,
  );
}

/// A card that does one thing: its 3D [icon] at the top, then its [title]
/// and a line of [subtitle], like "Apply leave · 8 casual days left".
class AppActionCard extends StatelessWidget {
  const AppActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  /// Drawn [AppSizes.actionIcon] across.
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      child: AppInkSurface(
        onTap: onTap,
        decoration: appCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: AppSizes.actionIcon,
                  child: icon,
                ),
              ),
              AppSpacing.gapXs,
              Text(title, style: text.labelLarge),
              AppSpacing.gapXxs,
              Text(
                subtitle,
                style: text.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that opens something, set out as a row: a [leading] picture,
/// its [title] with a [subtitle] under it, and a chevron.
class AppLinkCard extends StatelessWidget {
  const AppLinkCard({
    super.key,
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// A control at the end, before the chevron, such as a refresh key.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final subtitle = this.subtitle;
    return Semantics(
      button: onTap != null,
      child: AppInkSurface(
        onTap: onTap,
        decoration: appCardDecoration(
          context,
          radius: AppRadius.borderLinkCard,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.smd,
            AppSpacing.smd,
            AppSpacing.md + AppSpacing.xxs,
            AppSpacing.smd,
          ),
          child: Row(
            children: [
              ExcludeSemantics(child: leading),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.labelLarge),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing case final trailing?) ...[
                AppSpacing.gapXs,
                trailing,
              ],
              if (onTap != null) ...[
                AppSpacing.gapSm,
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
    );
  }
}

/// A section's heading on a screen, like "Leave balance", with an
/// optional [badge] beside it and [trailing], such as a link, at its end.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key, this.badge, this.trailing});

  final String title;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    final trailing = this.trailing;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.textTheme.titleLarge),
                ),
              ),
              if (badge != null) ...[AppSpacing.gapSm, badge],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
