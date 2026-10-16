import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_pressable.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// What a button does, which decides how loud it looks.
enum AppButtonVariant {
  /// The one main action of a screen: a raised jade key.
  primary,

  /// A secondary action: a raised porcelain key.
  secondary,

  /// A second way to do the main thing, beside a primary key: a plain key
  /// of pale jade, its words in deep jade.
  tonal,

  /// An action that deletes or signs out: a raised coral key.
  danger,

  /// A destructive action that isn't the screen's main one, like log out:
  /// a raised porcelain key with coral words.
  quietDanger,

  /// A quiet action in running text, underlined in jade.
  text,
}

/// How big a button is: large for a screen's main action, medium in cards
/// and dialogs, small in rows.
enum AppButtonSize {
  large(AppSizes.buttonLarge, AppRadius.buttonLarge),
  medium(AppSizes.buttonMedium, AppRadius.buttonMedium),
  small(AppSizes.buttonSmall, AppRadius.buttonSmall);

  const AppButtonSize(this.height, this.radius);

  final double height;
  final double radius;
}

/// The design's button. Keys are lit along their top and stand on a solid
/// edge; pressed, they sink onto it and darken, which is what makes them
/// read as 3D. The change is instant, with no animation.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.leadingGlyph,
    this.trailingGlyph,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = true,
    this.underlined = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final AppGlyph? leadingGlyph;
  final AppGlyph? trailingGlyph;

  /// Shows a spinner and ignores taps.
  final bool isLoading;

  /// What a screen reader says while [isLoading]; [label] by default.
  final String? loadingLabel;

  /// Fills the width it is given rather than hugging its label.
  final bool expand;

  /// Underlines a [AppButtonVariant.text] button's words in jade, as a link
  /// in running text; plain for one in a header.
  final bool underlined;

  /// The fill of a raised key: lit at the top, through its colour, into
  /// shade at the foot.
  static LinearGradient keyGradient(Color top, Color middle, Color bottom) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, middle, bottom],
        stops: const [0, 0.55, 1],
      );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return AppPressable(
      label: isLoading ? (loadingLabel ?? label) : label,
      onPressed: enabled ? onPressed : null,
      builder: (context, pressed, focused) =>
          _face(context, pressed: pressed, focused: focused),
    );
  }

  Widget _face(
    BuildContext context, {
    required bool pressed,
    required bool focused,
  }) {
    final colors = context.colors;
    final elevations = context.elevations;
    final text = context.textTheme;
    final isKey =
        variant == AppButtonVariant.primary ||
        variant == AppButtonVariant.danger;
    final disabled = onPressed == null && !isLoading;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size.radius),
    );

    final Gradient? fill;
    final Color foreground;
    List<BoxShadow> shadows = const [];
    List<BoxShadow> inset = const [];
    Border? border;
    switch (variant) {
      case AppButtonVariant.primary:
        foreground = colors.onPrimary;
        fill = pressed
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.primaryPressed, colors.primaryShade],
              )
            : keyGradient(
                colors.primaryHighlight,
                colors.primary,
                colors.primaryShade,
              );
        shadows = pressed ? elevations.keyPressed : elevations.key;
        inset = pressed ? elevations.keyPressedInset : elevations.keyInset;
      case AppButtonVariant.danger:
        foreground = colors.textPrimary;
        fill = keyGradient(
          colors.dangerHighlight,
          colors.dangerShade,
          colors.dangerShade,
        );
        shadows = pressed ? elevations.dangerKeyPressed : elevations.dangerKey;
        inset = pressed ? elevations.keyPressedInset : elevations.keyInset;
      case AppButtonVariant.secondary || AppButtonVariant.quietDanger:
        foreground = variant == AppButtonVariant.quietDanger
            ? colors.onDangerContainer
            : colors.textPrimary;
        fill = keyGradient(
          colors.surfaceRaised,
          colors.surfaceRaised,
          colors.surfaceRaisedEnd,
        );
        shadows = pressed ? const [] : elevations.raised;
        inset = pressed ? elevations.pressedInset : elevations.raisedInset;
        border = Border.all(color: colors.outline);
      case AppButtonVariant.tonal:
        // A plain key of pale jade, raised a little off the card.
        foreground = colors.onPrimaryContainer;
        fill = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: pressed
              ? [colors.primaryHighlight, colors.primaryHighlight]
              : [colors.primaryContainer, colors.primaryContainer],
        );
        shadows = pressed ? const [] : elevations.raised;
      case AppButtonVariant.text:
        foreground = colors.textPrimary;
        fill = null;
    }

    final ink = disabled ? colors.textDisabled : foreground;
    final style = switch (size) {
      AppButtonSize.large => text.titleMedium,
      AppButtonSize.medium => text.labelLarge,
      AppButtonSize.small => text.labelMedium?.copyWith(
        fontWeight: AppFonts.semiBold,
      ),
    }?.copyWith(color: ink);
    final words = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: variant == AppButtonVariant.text && underlined
          ? style?.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: colors.iconAccent,
              decorationThickness: AppFonts.linkUnderline,
            )
          : style,
    );
    Widget glyph(AppGlyph glyph) =>
        AppGlyphIcon(glyph, size: AppSizes.iconMd, color: ink);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox.square(
            dimension: AppSizes.iconSm,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: AppSizes.spinnerStroke,
              valueColor: AlwaysStoppedAnimation(ink),
            ),
          ),
          AppSpacing.gapSm,
        ] else if (leadingGlyph != null) ...[
          glyph(leadingGlyph!),
          AppSpacing.gapSm,
        ],
        Flexible(child: words),
        if (trailingGlyph != null && !isLoading) ...[
          AppSpacing.gapSm,
          glyph(trailingGlyph!),
        ],
      ],
    );

    // A key keeps room for its edge below it and moves into that room while
    // pressed, so the button never changes size.
    final sink = isKey ? AppSizes.keyEdge - AppSizes.keyEdgePressed : 0.0;
    return Padding(
      padding: EdgeInsets.only(
        top: pressed ? sink : 0,
        bottom: isKey
            ? (pressed ? AppSizes.keyEdgePressed : AppSizes.keyEdge)
            : 0,
      ),
      child: CustomPaint(
        // The focus ring rounds out with the key's corners.
        painter: focused
            ? OuterShadowPainter(
                shape: shape,
                shadows: [
                  BoxShadow(
                    color: colors.focusRing,
                    spreadRadius: AppSizes.focusRing,
                  ),
                ],
              )
            : null,
        child: LiquidPress(
          pressed: pressed && fill != null,
          radius: BorderRadius.circular(size.radius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: disabled ? null : fill,
              color: disabled && fill != null ? colors.disabledSurface : null,
              borderRadius: BorderRadius.circular(size.radius),
              border: disabled ? null : border,
              boxShadow: disabled ? null : shadows,
            ),
            child: CustomPaint(
              painter: disabled || inset.isEmpty
                  ? null
                  : InsetShadowPainter(shape: shape, shadows: inset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: variant == AppButtonVariant.text
                      ? AppSizes.minTapTarget
                      : size.height,
                  minWidth: AppSizes.minTapTarget,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: variant == AppButtonVariant.text
                        ? AppSpacing.sm
                        : AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Center(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
