import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// How much of something is left, as a ring filling clockwise from the
/// top in [color], with [child], such as the number, in its middle. The
/// ring sits in a groove with a soft shade under it.
class AppRingGauge extends StatelessWidget {
  const AppRingGauge({
    super.key,
    required this.fraction,
    required this.color,
    required this.child,
    this.size = AppSizes.ringGauge,
    this.stroke = AppSizes.ringGaugeStroke,
    this.semanticLabel,
  });

  /// From 0 (empty) to 1 (full).
  final double fraction;
  final Color color;
  final Widget child;
  final double size;
  final double stroke;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction.clamp(0, 1).toDouble(),
          color: color,
          groove: colors.surfaceMuted,
          shade: colors.shadow.withValues(alpha: 0.06),
          stroke: stroke,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.groove,
    required this.shade,
    required this.stroke,
  });

  final double fraction;
  final Color color;
  final Color groove;
  final Color shade;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    Paint line(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    // The shade under the groove, a little lower, lifts the ring.
    canvas
      ..drawCircle(
        center.translate(0, AppSizes.ringGaugeDrop),
        radius,
        line(shade),
      )
      ..drawCircle(center, radius, line(groove));
    if (fraction <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      line(color)..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.groove != groove ||
      old.shade != shade ||
      old.stroke != stroke;
}
