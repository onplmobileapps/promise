import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// One of a few choices on a card, like a leave type. Raised while it is
/// not picked; picked, it sinks into a jade well inside a soft ring, with
/// a check on its corner. Screen readers hear it as one of a group.
class AppChoiceCard extends StatelessWidget {
  const AppChoiceCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderXl,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXl,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child),
              // Room for the check either way, so nothing moves.
              SizedBox.square(
                dimension: AppSizes.choiceCheck,
                child: selected ? const _Check() : null,
              ),
            ],
          ),
        ),
      ),
    );
    final card = selected
        ? CustomPaint(
            painter: OuterShadowPainter(
              shape: _shape,
              shadows: [
                BoxShadow(
                  color: colors.focusRing,
                  spreadRadius: AppSizes.fieldRing,
                ),
              ],
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.42, -0.91),
                  end: const Alignment(0.42, 0.91),
                  colors: [colors.dayPresent, colors.surfaceEnd],
                  stops: const [0, 0.75],
                ),
                borderRadius: AppRadius.borderXl,
                border: Border.all(color: colors.dayPresentEdge, width: 1.5),
              ),
              child: CustomPaint(
                foregroundPainter: InsetShadowPainter(
                  shape: _shape,
                  shadows: elevations.keyPressedInset,
                ),
                child: content,
              ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
              ),
              borderRadius: AppRadius.borderXl,
              border: Border.all(color: colors.surfaceRaised),
              boxShadow: elevations.raised,
            ),
            child: CustomPaint(
              foregroundPainter: InsetShadowPainter(
                shape: _shape,
                shadows: elevations.raisedInset,
              ),
              child: content,
            ),
          );
    return LiquidPop(
      selected: selected,
      radius: AppRadius.borderXl,
      amount: AppSizes.liquidPopCard,
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: selected,
        button: true,
        child: card,
      ),
    );
  }
}

/// The small jade key with a check on a picked card's corner.
class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppButton.keyGradient(
          colors.primaryHighlight,
          colors.primary,
          colors.primaryShade,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryEdge,
            offset: const Offset(0, AppSizes.keyEdgePressed * 2),
          ),
        ],
      ),
      child: Center(
        child: AppGlyphIcon(
          AppGlyphs.check,
          size: AppSizes.choiceCheckGlyph,
          color: colors.onPrimary,
        ),
      ),
    );
  }
}
