import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/app_tone.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The key a ticked control shows: a raised, lit face on its edge, jade
/// unless its [tone] says trouble (coral) or caution (gold).
BoxDecoration _keyFace(
  BuildContext context,
  BoxShape shape,
  double radius, {
  AppTone tone = AppTone.brand,
}) {
  final colors = context.colors;
  final (Color highlight, Color face, Color shade, Color edge) = switch (tone) {
    AppTone.danger => (
      colors.dangerHighlight,
      colors.danger,
      colors.dangerShade,
      colors.dangerEdge,
    ),
    AppTone.warning => (
      Color.lerp(colors.gold, colors.surface, 0.3)!,
      colors.gold,
      Color.lerp(colors.gold, colors.shadow, 0.2)!,
      colors.dayLateEdge,
    ),
    _ => (
      colors.primaryHighlight,
      colors.primary,
      colors.primaryShade,
      colors.primaryEdge,
    ),
  };
  return BoxDecoration(
    shape: shape,
    borderRadius: shape == BoxShape.circle
        ? null
        : BorderRadius.circular(radius),
    gradient: AppButton.keyGradient(highlight, face, shade),
    boxShadow: [
      BoxShadow(
        color: edge,
        offset: const Offset(0, AppSizes.keyEdgePressed * 2),
      ),
    ],
  );
}

/// The well an unticked control sinks into.
class _Well extends StatelessWidget {
  const _Well({required this.shape, required this.size});

  final ShapeBorder shape;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
        ),
      ),
      child: CustomPaint(
        foregroundPainter: InsetShadowPainter(
          shape: shape,
          shadows: context.elevations.recessInset,
        ),
        child: SizedBox.square(dimension: size),
      ),
    );
  }
}

/// A box that is ticked or not: a jade key with a check, or a well.
/// Without [onChanged] it only shows; a row around it can toggle it.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = AppSizes.checkbox;
    final box = AnimatedSwitcher(
      duration: AppMotion.short,
      child: value
          ? DecoratedBox(
              key: const ValueKey(true),
              decoration: _keyFace(
                context,
                BoxShape.rectangle,
                AppRadius.checkbox,
              ),
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: AppGlyphIcon(
                    AppGlyphs.check,
                    size: AppSizes.checkboxGlyph,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            )
          : DecoratedBox(
              key: const ValueKey(false),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.checkbox),
                border: Border.all(color: colors.outlineStrong, width: 1.5),
              ),
              child: _Well(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.checkbox),
                ),
                size: size,
              ),
            ),
    );
    final onChanged = this.onChanged;
    if (onChanged == null) return ExcludeSemantics(child: box);
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.select();
          onChanged(!value);
        },
        child: SizedBox.square(
          dimension: AppSizes.minTouch,
          child: Center(child: box),
        ),
      ),
    );
  }
}

/// A round mark that is picked or not: a jade ring around a white middle,
/// or a well.
class AppRadioMark extends StatelessWidget {
  const AppRadioMark({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const size = AppSizes.checkbox;
    return ExcludeSemantics(
      child: AnimatedSwitcher(
        duration: AppMotion.short,
        child: selected
            ? DecoratedBox(
                key: const ValueKey(true),
                decoration: _keyFace(context, BoxShape.circle, 0),
                child: SizedBox.square(
                  dimension: size,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                      ),
                      child: const SizedBox.square(
                        dimension: AppSizes.radioDot,
                      ),
                    ),
                  ),
                ),
              )
            : DecoratedBox(
                key: const ValueKey(false),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outlineStrong, width: 1.5),
                ),
                child: const _Well(shape: CircleBorder(), size: size),
              ),
      ),
    );
  }
}

/// A count set a step at a time: "−", the count, "+", on a raised strip.
class AppCountStepper extends StatelessWidget {
  const AppCountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.min = 0,
    this.max = 999,
  });

  final int value;
  final ValueChanged<int> onChanged;

  /// What screen readers call the two keys.
  final String decreaseLabel;
  final String increaseLabel;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    Widget key(AppGlyph glyph, String label, int? to) => Semantics(
      button: true,
      label: label,
      enabled: to != null,
      child: InkResponse(
        onTap: to == null
            ? null
            : () {
                AppHaptics.select();
                onChanged(to);
              },
        radius: AppSizes.stepperKey / 2,
        child: SizedBox.square(
          dimension: AppSizes.stepperKey,
          child: Center(
            child: AppGlyphIcon(
              glyph,
              size: AppSizes.iconSm,
              color: to == null ? colors.textDisabled : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key(
              AppGlyphs.circleMinus,
              decreaseLabel,
              value > min ? value - 1 : null,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizes.stepperValue,
              ),
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: text.titleSmall?.copyWith(
                  fontFeatures: AppFonts.tabularFigures,
                ),
              ),
            ),
            key(AppGlyphs.plus, increaseLabel, value < max ? value + 1 : null),
          ],
        ),
      ),
    );
  }
}

/// One choice of [AppChoiceChips].
@immutable
class AppChoice<T> {
  const AppChoice(this.value, this.label, {this.tone = AppTone.brand});

  final T value;
  final String label;

  /// What picking it says: jade by default; coral for an answer that
  /// reports trouble, as "Faulty", and gold for one that asks for care.
  final AppTone tone;
}

/// One of several short choices, as chips that wrap: the picked one sinks
/// into a tint of its tone with a small check key, the rest stand raised.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  final List<AppChoice<T>> choices;
  final T? selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final choice in choices)
          _Chip(
            label: choice.label,
            tone: choice.tone,
            selected: choice.value == selected,
            onTap: () {
              AppHaptics.select();
              onSelected(choice.value);
            },
          ),
      ],
    );
  }
}

/// Several of a few short choices, as chips that wrap: each picked one
/// sinks into a tint of its tone with a small check key.
class AppMultiChoiceChips<T> extends StatelessWidget {
  const AppMultiChoiceChips({
    super.key,
    required this.choices,
    required this.selected,
    required this.onToggled,
  });

  final List<AppChoice<T>> choices;
  final Set<T> selected;

  /// A choice tapped, to be picked or let go.
  final ValueChanged<T> onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final choice in choices)
          Semantics(
            inMutuallyExclusiveGroup: false,
            child: _Chip(
              label: choice.label,
              tone: choice.tone,
              selected: selected.contains(choice.value),
              onTap: () {
                AppHaptics.select();
                onToggled(choice.value);
              },
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final (Color tint, Color edge) = switch (tone) {
      AppTone.danger => (colors.dangerContainer, colors.dangerEdge),
      AppTone.warning => (colors.dayLate, colors.dayLateEdge),
      _ => (colors.dayPresent, colors.dayPresentEdge),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: AppRadius.borderMd,
      side: selected
          ? BorderSide(color: edge, width: 1.5)
          : BorderSide(color: colors.outline),
    );
    return LiquidPop(
      selected: selected,
      radius: AppRadius.borderMd,
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: AnimatedContainer(
          duration: AppMotion.short,
          decoration: ShapeDecoration(
            shape: shape,
            color: selected ? tint : null,
            gradient: selected
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
                  ),
            shadows: selected ? null : context.elevations.raised,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.chip),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: selected ? AppSpacing.sm : AppSpacing.md,
                    end: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected) ...[
                        DecoratedBox(
                          decoration: _keyFace(
                            context,
                            BoxShape.circle,
                            0,
                            tone: tone,
                          ),
                          child: SizedBox.square(
                            dimension: AppSizes.chipCheck,
                            child: Center(
                              child: AppGlyphIcon(
                                AppGlyphs.check,
                                size: AppSizes.chipCheckGlyph,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.gapXs,
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(
                            fontWeight: AppFonts.semiBold,
                          ),
                        ),
                      ),
                    ],
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

/// The steps of a task in a row: those done and the one under way as jade
/// keys, the rest as rings, with dashed lines between them.
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({super.key, required this.steps, required this.current});

  final List<String> steps;

  /// The step under way, counted from zero.
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final labelStyle = text.labelMedium?.copyWith(
      fontWeight: AppFonts.semiBold,
    );
    return Semantics(
      label: steps[current],
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            // Every label when they all fit beside their numbers and some
            // line; on a narrow screen or with large text, only the
            // current one.
            final scaler = MediaQuery.textScalerOf(context);
            var needed = 0.0;
            for (final step in steps) {
              final painter = TextPainter(
                text: TextSpan(text: step, style: labelStyle),
                textDirection: Directionality.of(context),
                textScaler: scaler,
                maxLines: 1,
              )..layout();
              needed += AppSizes.stepNumber + AppSpacing.xs + painter.width;
              painter.dispose();
            }
            needed += (steps.length - 1) * AppSizes.stepGapMin;
            final allLabels = needed <= box.maxWidth;
            return Row(
              children: [
                for (final (i, step) in steps.indexed) ...[
                  if (i > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: CustomPaint(
                          size: const Size.fromHeight(AppSizes.stepLine),
                          painter: _DashPainter(
                            color: i <= current
                                ? colors.primaryShade
                                : colors.outlineStrong,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i <= current)
                        DecoratedBox(
                          decoration: _keyFace(context, BoxShape.circle, 0),
                          child: SizedBox.square(
                            dimension: AppSizes.stepNumber,
                            child: Center(
                              child: i < current
                                  ? AppGlyphIcon(
                                      AppGlyphs.check,
                                      size: AppSizes.chipCheckGlyph,
                                      color: colors.onPrimary,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: text.labelSmall?.copyWith(
                                        color: colors.onPrimary,
                                        letterSpacing: 0,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      else
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.outlineStrong,
                              width: 2,
                            ),
                          ),
                          child: SizedBox.square(
                            dimension: AppSizes.stepNumber,
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: text.labelSmall?.copyWith(
                                  color: colors.textTertiary,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (allLabels || i == current) ...[
                        AppSpacing.gapXs,
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: box.maxWidth * 0.5,
                          ),
                          child: Text(
                            step,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: labelStyle?.copyWith(
                              color: i <= current
                                  ? colors.textPrimary
                                  : colors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += AppSizes.dash * 1.75) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + AppSizes.dash).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
