import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/app_tone.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A status in a rounded pill, like "Approved" or "Late 09:31", tinted by
/// its [tone]. A [dot] in front says the status is live, like "Present".
class AppPill extends StatelessWidget {
  const AppPill(this.label, {super.key, this.tone = AppTone.brand, this.dot});

  final String label;
  final AppTone tone;

  /// The colour of a dot before the label; none without it.
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, toneInk) = tone.colorsIn(colors);
    // The jade tint carries plain ink; the others their own.
    final ink = tone == AppTone.brand ? colors.textPrimary : toneInk;
    final dot = this.dot;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.borderPill,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dot == null ? AppSpacing.sm : AppSpacing.smd,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: AppSizes.statusDot),
              ),
              AppSpacing.gapXs,
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: ink,
                  fontWeight: AppFonts.semiBold,
                  fontFeatures: AppFonts.tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
