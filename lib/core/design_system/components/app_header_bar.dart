import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_back_button.dart';
import 'package:railway_hrms/core/design_system/components/app_tile_button.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A screen's top bar: a tile that goes [onBack], the [title] with a
/// [subtitle] under it, and [actions] at its end, such as more tiles.
///
/// [large] sets the title as the page's heading; otherwise it is the bar's
/// name, with the subtitle saying what the screen holds.
class AppHeaderBar extends StatelessWidget {
  const AppHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.backTooltip,
    this.backGlyph = AppGlyphs.chevronLeft,
    this.actions = const [],
    this.large = false,
  });

  final String title;
  final String? subtitle;

  /// Without it there is no back tile.
  final VoidCallback? onBack;

  /// Read by screen readers; "Back" by default.
  final String? backTooltip;
  final AppGlyph backGlyph;
  final List<Widget> actions;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final onBack = this.onBack;
    final subtitle = this.subtitle;
    return Row(
      children: [
        if (onBack != null) ...[
          if (backGlyph == AppGlyphs.chevronLeft)
            AppBackButton(onPressed: onBack, tooltip: backTooltip)
          else
            AppTileButton(
              icon: AppGlyphIcon(backGlyph),
              tooltip:
                  backTooltip ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
            ),
          AppSpacing.gapSm,
        ],
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: large ? text.headlineMedium : text.titleLarge,
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        for (final action in actions) ...[AppSpacing.gapXs, action],
      ],
    );
  }
}
