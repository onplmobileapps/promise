import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/app_tone.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A short label on a tint, like an employee number or a status.
class AppTag extends StatelessWidget {
  const AppTag(this.label, {super.key, this.tone = AppTone.neutral});

  final String label;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = tone.colorsIn(context.colors);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.borderXs,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: foreground,
            letterSpacing: AppFonts.tagLetterSpacing,
            fontFeatures: AppFonts.tabularFigures,
          ),
        ),
      ),
    );
  }
}
