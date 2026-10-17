import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_pressable.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// One tile of an [AppStatFilter]: the [value] it filters by, its [label]
/// and [count], marked in [color] on a [tint].
@immutable
class AppStatOption<T> {
  const AppStatOption({
    required this.value,
    required this.label,
    required this.count,
    required this.color,
    required this.tint,
  });

  final T value;
  final String label;
  final int count;
  final Color color;
  final Color tint;
}

/// Counts on tinted tiles, side by side, that filter a list. Tapping one
/// shows only its kind, ringed in its colour while the others dim; tapping
/// it again shows everything.
class AppStatFilter<T> extends StatelessWidget {
  const AppStatFilter({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<AppStatOption<T>> options;

  /// The kind shown; null for everything.
  final T? selected;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    // As tall as the tallest, so the tiles line up.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, option) in options.indexed) ...[
            if (index > 0) AppSpacing.gapSm,
            Expanded(
              child: _StatTile(
                option: option,
                selected: option.value == selected,
                dimmed: selected != null && option.value != selected,
                onTap: () =>
                    onSelected(option.value == selected ? null : option.value),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile<T> extends StatelessWidget {
  const _StatTile({
    required this.option,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final AppStatOption<T> option;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return LiquidPop(
      selected: selected,
      radius: AppRadius.borderTile,
      child: Semantics(
        selected: selected,
        child: AppPressable(
          label: '${option.label} ${option.count}',
          onPressed: onTap,
          haptic: AppHaptic.select,
          builder: (context, pressed, focused) => AnimatedOpacity(
            duration: AppMotion.short,
            opacity: dimmed ? 0.5 : 1,
            child: AnimatedContainer(
              duration: AppMotion.short,
              curve: AppMotion.enter,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.smd,
                vertical: AppSpacing.smd,
              ),
              decoration: BoxDecoration(
                color: option.tint,
                borderRadius: AppRadius.borderTile,
                border: Border.all(
                  color: selected || focused
                      ? option.color
                      : option.color.withValues(alpha: 0),
                  width: AppSizes.todayRing,
                ),
                boxShadow: selected ? context.elevations.raised : null,
              ),
              transform: pressed
                  ? Matrix4.translationValues(0, AppSizes.keyEdgePressed, 0)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${option.count}',
                    style: text.headlineMedium?.copyWith(
                      fontFeatures: AppFonts.tabularFigures,
                    ),
                  ),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: option.color,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(
                          dimension: AppSizes.statusDot,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Flexible(
                        child: Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            letterSpacing: 0,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
