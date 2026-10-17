import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// One choice of an [AppSegmentedTabs].
@immutable
class AppSegment {
  const AppSegment({required this.label, this.glyph, this.leading})
    : iconOnly = false;

  /// Just [glyph], with [label] for screen readers, for a row of many
  /// choices such as an emoji picker's groups.
  const AppSegment.icon({required this.label, required AppGlyph this.glyph})
    : leading = null,
      iconOnly = true;

  final String label;
  final AppGlyph? glyph;
  final bool iconOnly;

  /// Drawn before the label in place of a [glyph], like a small logo.
  final Widget? leading;
}

/// A segmented control: a pressed-in track with the selected choice raised
/// out of it. It drives a [TabController]; give the controller a zero
/// `animationDuration` for an instant switch.
class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.segments,
  });

  final TabController controller;
  final List<AppSegment> segments;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        // While the selection moves between choices a lens of liquid
        // glass rides over it, bending the labels it passes.
        child: AnimatedBuilder(
          animation: controller.animation ?? controller,
          builder: (context, tabs) {
            final value = controller.animation?.value ?? controller.index * 1.0;
            final between = (value - value.floorToDouble()).abs();
            final motion = math.sin(between * math.pi).clamp(0.0, 1.0);
            return AppLiquidGlass(
              amount: motion,
              lens: (size) {
                final share = size.width / math.max(1, segments.length);
                final rest = Rect.fromLTWH(
                  rtl ? size.width - (value + 1) * share : value * share,
                  0,
                  share,
                  size.height,
                );
                return liquidShape(
                  rest,
                  motion: motion * 0.7,
                  lift: motion * 0.35,
                );
              },
              child: tabs,
            );
          },
          child: TabBar(
            onTap: (_) => AppHaptics.select(),
            controller: controller,
            // Icons alone share the width without the labels' padding.
            labelPadding: segments.every((segment) => segment.iconOnly)
                ? EdgeInsets.zero
                : null,
            indicator: switch (TabBarTheme.of(context).indicator) {
              final BoxDecoration thumb => LiquidTabIndicator(
                base: thumb,
                animation: controller.animation,
                look: LiquidLook.of(context),
              ),
              final other => other,
            },
            tabs: [
              for (final segment in segments)
                Tab(
                  height: AppSizes.segmentedHeight - AppSpacing.sm,
                  // Long labels shrink to fit rather than overflow on the
                  // narrowest phones.
                  child: segment.iconOnly
                      ? Semantics(
                          label: segment.label,
                          excludeSemantics: true,
                          child: AppGlyphIcon(
                            segment.glyph!,
                            size: AppSizes.iconMd,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (segment.leading case final leading?) ...[
                                leading,
                                AppSpacing.gapSm,
                              ] else if (segment.glyph case final glyph?) ...[
                                AppGlyphIcon(glyph, size: AppSizes.iconSm),
                                AppSpacing.gapSm,
                              ],
                              Text(segment.label, maxLines: 1),
                            ],
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
