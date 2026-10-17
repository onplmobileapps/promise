import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_icon_tile.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// How a field looks at the moment.
enum AppFieldState { idle, focused, error, readOnly, disabled }

/// The design's field. It is a well pressed into the page, its edge drawn
/// all the way round, with a line [glyph], its [label] inside above the
/// value, and an optional [trailing] action. Focused, it eases up to the
/// surface inside a jade ring. In error, the ring, border and label turn
/// coral and the [error] shows below.
///
/// [child] is the value: a text input, or the chosen option's name.
class AppFieldFrame extends StatelessWidget {
  const AppFieldFrame({
    super.key,
    required this.label,
    required this.child,
    this.glyph,
    this.trailing,
    this.state = AppFieldState.idle,
    this.error,
  });

  final String label;
  final Widget child;
  final AppGlyph? glyph;
  final Widget? trailing;
  final AppFieldState state;
  final String? error;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLg,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final active =
        state == AppFieldState.focused || state == AppFieldState.error;
    final accent = state == AppFieldState.error ? colors.danger : colors.focus;
    final halo = state == AppFieldState.error
        ? colors.dangerRing
        : colors.focusRing;
    // The well's edge, a touch firmer than a card's hairline, so the field
    // reads whole on any surface, its foot as much as its top.
    final edge = switch (state) {
      AppFieldState.readOnly => colors.outlineStrong,
      _ => Color.lerp(colors.outline, colors.outlineStrong, 0.6)!,
    };
    // Pressed in: an even tint, a shade deeper at the top than the foot.
    final (Color top, Color foot) = switch (state) {
      AppFieldState.readOnly => (
        colors.surfaceRaisedEnd,
        colors.surfaceRaisedEnd,
      ),
      AppFieldState.disabled => (colors.surfaceMuted, colors.surfaceMuted),
      _ => (
        colors.surfaceSunken,
        Color.lerp(colors.surfaceSunken, colors.surfaceSunkenEnd, 0.35)!,
      ),
    };
    final shade = context.elevations.recessInset.first;
    final glyph = this.glyph;
    final trailing = this.trailing;
    final error = this.error;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.fieldHeight),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: AppSpacing.md + AppSpacing.xxs,
          end: trailing == null
              ? AppSpacing.md + AppSpacing.xxs
              : AppSpacing.xs,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (glyph != null) ...[
              // On a small raised tile, in 3D.
              AppIconTile(
                size: AppSizes.fieldIconTile,
                child: AppGlyphIcon(
                  glyph,
                  depth: true,
                  color: colors.iconAccent,
                  size: AppSizes.iconMd,
                ),
              ),
              AppSpacing.gapMd,
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The value carries the label for screen readers.
                  ExcludeSemantics(
                    child: AnimatedDefaultTextStyle(
                      duration: AppMotion.short,
                      style: text.labelSmall!.copyWith(
                        letterSpacing: 0,
                        color: switch (state) {
                          AppFieldState.error => colors.onDangerContainer,
                          AppFieldState.focused => colors.textSecondary,
                          _ => colors.textTertiary,
                        },
                      ),
                      child: Text(label),
                    ),
                  ),
                  AppSpacing.gapXxs,
                  DefaultTextStyle.merge(
                    style: text.labelLarge?.copyWith(
                      color: active || state == AppFieldState.idle
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Focus comes and goes as a short ease, not a jump.
        TweenAnimationBuilder<double>(
          tween: Tween(end: active ? 1 : 0),
          duration: AppMotion.short,
          curve: AppMotion.enter,
          child: content,
          builder: (context, t, content) => CustomPaint(
            // The ring rounds out with the field's corners.
            painter: t == 0
                ? null
                : OuterShadowPainter(
                    shape: _shape,
                    shadows: [
                      BoxShadow(
                        color: halo.withValues(alpha: halo.a * t),
                        spreadRadius: AppSizes.fieldRing * t,
                      ),
                    ],
                  ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(top, colors.surface, t)!,
                    Color.lerp(foot, colors.surface, t)!,
                  ],
                ),
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: Color.lerp(edge, accent, t)!,
                  width: 1 + 0.5 * t,
                ),
              ),
              child: CustomPaint(
                // A soft shade under the top rim, gone once it lifts.
                painter: state == AppFieldState.readOnly || t == 1
                    ? null
                    : InsetShadowPainter(
                        shape: _shape,
                        shadows: [
                          BoxShadow(
                            color: shade.color.withValues(
                              alpha: shade.color.a * (1 - t),
                            ),
                            offset: shade.offset,
                            blurRadius: shade.blurRadius,
                            spreadRadius: shade.spreadRadius,
                          ),
                        ],
                      ),
                child: content,
              ),
            ),
          ),
        ),
        if (error != null) AppFieldError(error),
      ],
    );
  }
}

/// What is wrong with a field, under it in coral.
class AppFieldError extends StatelessWidget {
  const AppFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.xs + AppSpacing.xxs,
      left: AppSpacing.xxs,
    ),
    child: Text(
      message,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.onDangerContainer,
        fontWeight: AppFonts.semiBold,
      ),
    ),
  );
}
