import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_pressable.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// One choice in [AppFilterChips]: the [value] it filters by, its [label],
/// and how many things it holds, if any. An [urgent] count, like unread
/// alerts, is set in coral; a plain one, like people, in quiet ink.
@immutable
class AppFilterOption<T> {
  const AppFilterOption({
    required this.value,
    required this.label,
    this.count = 0,
    this.urgent = true,
    this.mark,
  });

  final T value;
  final String label;
  final int count;
  final bool urgent;

  /// A dot before the label in this colour, like a status's.
  final Color? mark;
}

/// A row of filter chips with one chosen: that one pressed into the page in
/// ink, the rest raised. It scrolls sideways when they don't all fit.
class AppFilterChips<T> extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.bleed = 0,
  });

  final List<AppFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// How far the row may scroll out past its sides, into the padding of
  /// what holds it, so chips slide in from the edge instead of being cut.
  final double bleed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: bleed > 0 ? Clip.none : Clip.hardEdge,
      padding: EdgeInsetsDirectional.only(end: bleed),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) AppSpacing.gapSm,
            _KeepInView(
              shown: options[i].value == selected,
              child: _FilterChip(
                option: options[i],
                selected: options[i].value == selected,
                onTap: () => onSelected(options[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scrolls the chosen chip into view when it is chosen, as when a step is
/// moved on to from elsewhere.
class _KeepInView extends StatefulWidget {
  const _KeepInView({required this.shown, required this.child});

  final bool shown;
  final Widget child;

  @override
  State<_KeepInView> createState() => _KeepInViewState();
}

class _KeepInViewState extends State<_KeepInView> {
  @override
  void didUpdateWidget(_KeepInView old) {
    super.didUpdateWidget(old);
    if (widget.shown && !old.shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final chip = context.findRenderObject();
        if (chip == null) return;
        // Only the row slides; the page around it stays where it is.
        Scrollable.maybeOf(
          context,
          axis: Axis.horizontal,
        )?.position.ensureVisible(
          chip,
          alignment: 0.5,
          duration: AppMotion.medium,
          curve: AppMotion.enter,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppFilterOption<Object?> option;
  final bool selected;
  final VoidCallback onTap;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderSm,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final label = option.count > 0
        ? '${option.label}, ${option.count}'
        : option.label;
    return LiquidPop(
      selected: selected,
      radius: AppRadius.borderSm,

      child: Semantics(
        selected: selected,
        child: AppPressable(
          label: label,
          onPressed: onTap,
          haptic: AppHaptic.select,
          builder: (context, pressed, focused) => Padding(
            // A full tap target around the chip's face.
            padding: const EdgeInsets.symmetric(
              vertical: (AppSizes.minTapTarget - AppSizes.chipHeight) / 2,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? colors.textPrimary : null,
                gradient: selected
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
                      ),
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: selected ? colors.textPrimary : colors.outline,
                ),
                boxShadow: [
                  if (focused)
                    BoxShadow(color: colors.focusRing, spreadRadius: 3),
                  if (!selected && !pressed) ...context.elevations.raised,
                ],
              ),
              child: CustomPaint(
                painter: selected || pressed
                    ? InsetShadowPainter(
                        shape: _shape,
                        shadows: context.elevations.pressedInset,
                      )
                    : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.chipHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (option.mark case final mark?) ...[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: mark,
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox.square(
                              dimension: AppSizes.statusDot,
                            ),
                          ),
                          AppSpacing.gapXs,
                        ],
                        Text(
                          option.label,
                          style: text.labelMedium?.copyWith(
                            color: selected
                                ? colors.background
                                : colors.textPrimary,
                            fontWeight: selected
                                ? AppFonts.semiBold
                                : AppFonts.medium,
                          ),
                        ),
                        if (option.count > 0) ...[
                          AppSpacing.gapXs,
                          Text(
                            '${option.count}',
                            style: text.labelSmall?.copyWith(
                              color: selected
                                  ? colors.background
                                  : option.urgent
                                  ? colors.danger
                                  : colors.textTertiary,
                              letterSpacing: 0,
                              fontFeatures: AppFonts.tabularFigures,
                            ),
                          ),
                        ],
                      ],
                    ),
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
