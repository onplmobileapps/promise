import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_icon_tile.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// How a field looks at the moment.
enum AppFieldState { idle, focused, error, readOnly, disabled }

/// The design's field. It is a well pressed into the page, with a line
/// [glyph], its [label] inside above the value, and an optional [trailing]
/// action. Focused, it lifts to the surface inside a jade ring. In error,
/// the ring, border and label turn coral and the [error] shows below.
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
    final raised =
        state == AppFieldState.focused || state == AppFieldState.error;
    final (Color border, double width) = switch (state) {
      AppFieldState.focused => (colors.focus, 1.5),
      AppFieldState.error => (colors.danger, 1.5),
      AppFieldState.readOnly => (colors.outlineStrong, 1.0),
      AppFieldState.idle || AppFieldState.disabled => (colors.outline, 1.0),
    };
    final ring = switch (state) {
      AppFieldState.focused => BoxShadow(
        color: colors.focusRing,
        spreadRadius: AppSizes.fieldRing,
      ),
      AppFieldState.error => BoxShadow(
        color: colors.dangerRing,
        spreadRadius: AppSizes.fieldRing,
      ),
      _ => null,
    };
    final glyph = this.glyph;
    final trailing = this.trailing;
    final error = this.error;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomPaint(
          // The ring rounds out with the field's corners.
          painter: ring == null
              ? null
              : OuterShadowPainter(shape: _shape, shadows: [ring]),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: switch (state) {
                AppFieldState.focused || AppFieldState.error => colors.surface,
                AppFieldState.readOnly => colors.surfaceRaisedEnd,
                AppFieldState.disabled => colors.surfaceMuted,
                AppFieldState.idle => null,
              },
              gradient: state == AppFieldState.idle
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
                    )
                  : null,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: border, width: width),
            ),
            child: CustomPaint(
              painter: state == AppFieldState.readOnly
                  ? null
                  : InsetShadowPainter(
                      shape: _shape,
                      shadows: context.elevations.recessInset,
                    ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizes.fieldHeight,
                ),
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
                              child: Text(
                                label,
                                style: text.labelSmall?.copyWith(
                                  letterSpacing: 0,
                                  color: state == AppFieldState.error
                                      ? colors.onDangerContainer
                                      : colors.textTertiary,
                                ),
                              ),
                            ),
                            AppSpacing.gapXxs,
                            DefaultTextStyle.merge(
                              style: text.labelLarge?.copyWith(
                                color: raised || state == AppFieldState.idle
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
