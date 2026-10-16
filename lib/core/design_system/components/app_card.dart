import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_edge_painter.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A card floating above the page, with a soft top-to-bottom shading and a
/// hairline edge. [AppCard.glass] is frosted glass instead, for a form laid
/// over the page's pattern, like sign-in.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  }) : _glass = false,
       edge = null;

  const AppCard.glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg + AppSpacing.xxs),
    this.edge,
  }) : _glass = true;

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// A coloured edge round the glass, such as the brand's jade, for a card
  /// that stands for the screen; its own pale edge by default.
  final Color? edge;
  final bool _glass;

  /// How much the glass blurs what is behind it.
  static const double _frost = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    if (!_glass) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surface, colors.surfaceEnd],
          ),
          borderRadius: AppRadius.borderXxl,
          border: Border.all(color: colors.outline),
          boxShadow: elevations.card,
        ),
        child: Padding(padding: padding, child: child),
      );
    }
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.borderSheet);
    // Where the phone can't spare the blur, the glass is the frost's colour
    // over the card's, solid.
    final lite = AppPerformance.flatOf(context);
    final pane = DecoratedBox(
      decoration: BoxDecoration(
        color: lite
            ? Color.alphaBlend(colors.glassStrong, colors.surface)
            : colors.glassStrong,
        borderRadius: AppRadius.borderSheet,
        border: edge == null ? Border.all(color: colors.surfaceRaised) : null,
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(
          shape: shape,
          shadows: elevations.raisedInset,
        ),
        // A coloured edge is drawn over the inner light, so it shows as
        // strongly along the top as round the rest.
        foregroundPainter: edge == null
            ? null
            : AppEdgePainter(colour: edge!, shape: shape),
        child: Padding(padding: padding, child: child),
      ),
    );
    // The shadow falls outside the clip that keeps the frost inside the
    // card, and only outside the card, so it never shows through the glass.
    return CustomPaint(
      painter: OuterShadowPainter(
        shape: shape,
        shadows: elevations.card,
        knockout: true,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderSheet,
        // Off rather than left out: a form on the card keeps its fields,
        // their focus and what is typed when the phone's budget changes.
        child: BackdropFilter(
          enabled: !lite,
          filter: ImageFilter.blur(sigmaX: _frost, sigmaY: _frost),
          child: pane,
        ),
      ),
    );
  }
}
