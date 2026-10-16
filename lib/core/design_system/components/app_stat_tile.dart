import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_ink_surface.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// How an [AppStatTile] stands on the page.
enum AppStatTileStyle {
  /// Sunk into a card, like a check-in time.
  recessed,

  /// Lifted off the page, like a count over a calendar.
  raised,
}

/// A number or a time with what it is: "Check-in 09:02", or "18 ▪ In".
///
/// With [labelFirst] the small label sits over the value; otherwise the
/// value leads, with its [mark] colour as a square before the label, as
/// in a board of counts. [onTap] makes it a button.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.value,
    required this.label,
    this.mark,
    this.labelFirst = false,
    this.style = AppStatTileStyle.recessed,
    this.valueStyle,
    this.muted = false,
    this.onTap,
  });

  final String value;
  final String label;
  final Color? mark;
  final bool labelFirst;
  final AppStatTileStyle style;

  /// The value's type; a large display number by default.
  final TextStyle? valueStyle;

  /// The value is a placeholder, like "Not yet", and reads quieter.
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final mark = this.mark;
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (valueStyle ?? text.titleLarge)?.copyWith(
        color: muted ? colors.textTertiary : colors.textPrimary,
        fontFeatures: AppFonts.tabularFigures,
      ),
    );
    final labelText = Row(
      children: [
        if (mark != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: mark,
              borderRadius: BorderRadius.circular(AppSizes.statMarkRadius),
            ),
            child: const SizedBox.square(dimension: AppSizes.statMark),
          ),
          AppSpacing.gapXs,
        ],
        // A narrow tile shrinks its label a little rather than cut it.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              maxLines: 1,
              style: text.labelSmall?.copyWith(
                letterSpacing: 0,
                color: labelFirst ? colors.textTertiary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: labelFirst ? AppSpacing.md : AppSpacing.smd,
        vertical: AppSpacing.smd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: labelFirst ? [labelText, valueText] : [valueText, labelText],
      ),
    );
    final semantic = MergeSemantics(
      child: Semantics(button: onTap != null, child: content),
    );
    return switch (style) {
      AppStatTileStyle.recessed => _Recessed(onTap: onTap, child: semantic),
      AppStatTileStyle.raised => AppInkSurface(
        onTap: onTap,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
          ),
          borderRadius: AppRadius.borderLinkCard,
          border: Border.all(color: colors.surfaceRaised),
          boxShadow: context.elevations.raised,
        ),
        child: semantic,
      ),
    };
  }
}

class _Recessed extends StatelessWidget {
  const _Recessed({required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderTile,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
        ),
        borderRadius: AppRadius.borderTile,
      ),
      child: CustomPaint(
        foregroundPainter: InsetShadowPainter(
          shape: _shape,
          shadows: context.elevations.recessInset,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderTile,
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
