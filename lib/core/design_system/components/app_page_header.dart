import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The top of a screen: a large [title], an optional small [overline] above
/// it, and an optional [action] at its end, such as "Mark all read".
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.overline,
    this.action,
  });

  final String title;
  final String? overline;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final overline = this.overline;
    final action = this.action;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (overline != null) ...[
                Text(
                  overline.toUpperCase(),
                  style: text.bodySmall?.copyWith(
                    letterSpacing: AppFonts.tagLetterSpacing,
                    fontFeatures: AppFonts.tabularFigures,
                  ),
                ),
                AppSpacing.gapXxs,
              ],
              Semantics(
                header: true,
                child: Text(title, style: text.displaySmall),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
