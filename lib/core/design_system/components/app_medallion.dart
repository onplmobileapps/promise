import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_dome.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/app_elevations.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// [child] on an [AppDome] set in a ring of frosted glass, circled by a
/// dashed orbit with a gold marker over a warm glow: a screen's hero mark,
/// like the emblem on the sign-in screen. Nothing in it moves.
///
/// The orbit and the glow can each be left out. The glow reaches past the
/// medallion's box, under whatever follows it.
class AppMedallion extends StatelessWidget {
  const AppMedallion({
    super.key,
    required this.diameter,
    required this.child,
    this.showOrbit = true,
    this.showGlow = true,
  });

  /// A glass ring diameter that suits a screen whose shorter side is
  /// [shortestSide].
  static double diameterFor(double shortestSide) =>
      (shortestSide * AppSizes.medallionShare).clamp(
        AppSizes.medallionMin,
        AppSizes.medallionMax,
      );

  /// Across the glass ring; every other part scales with it.
  final double diameter;
  final Widget child;
  final bool showOrbit;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = diameter / AppSizes.medallionDesign;
    // Where the phone can't spare the blur, the glass is solid.
    final lite = AppPerformance.flatOf(context);
    final pane = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lite
            ? Color.alphaBlend(colors.glass, colors.surface)
            : colors.glass,
        border: Border.all(color: colors.surfaceRaised),
      ),
      child: SizedBox.square(
        dimension: diameter,
        child: Center(
          child: AppDome(diameter: diameter * _Geometry.dome, child: child),
        ),
      ),
    );
    // Off rather than left out, so what is inside keeps its place in the
    // tree when the phone's budget changes.
    final frosted = BackdropFilter(
      enabled: !lite,
      filter: ImageFilter.blur(
        sigmaX: _Geometry.frost * scale,
        sigmaY: _Geometry.frost * scale,
      ),
      child: pane,
    );
    // The glass casts its shadow only outside itself, so the shadow never
    // shows through it.
    final ring = CustomPaint(
      painter: OuterShadowPainter(
        shadows: context.elevations.glass.scaled(scale),
        knockout: true,
      ),
      child: ClipOval(child: frosted),
    );
    if (!showOrbit && !showGlow) return ring;
    return CustomPaint(
      painter: _OrbitPainter(
        glow: showGlow ? colors.glow : null,
        orbit: showOrbit ? colors.ornament : null,
        marker: colors.ornamentAccent,
        scale: scale,
      ),
      child: SizedBox.square(
        dimension: showOrbit ? diameter * _Geometry.orbit : diameter,
        child: Center(child: ring),
      ),
    );
  }
}

/// The medallion's parts, as shares of the glass ring or at its drawn size
/// of [AppSizes.medallionDesign].
abstract final class _Geometry {
  static const double dome = 112 / 150;
  static const double orbit = 170 / 150;

  /// How much the glass blurs what is behind it.
  static const double frost = 16;

  static const double dash = 3;
  static const double orbitStroke = 1;

  /// The marker sits on the orbit, up and to the right.
  static const double markerAngle = -math.pi / 4;
  static const double marker = 11;
  static const double markerHalo = 5;
  static const double markerHaloOpacity = 0.25;

  /// The glow pools under the dome, wider than it is tall.
  static const Size glow = Size(400, 220);
  static const double glowDrop = 61;
}

/// The glow, and the dashed orbit with its gold marker. Either may be off.
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({
    required this.glow,
    required this.orbit,
    required this.marker,
    required this.scale,
  });

  final Color? glow;
  final Color? orbit;
  final Color marker;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final glow = this.glow;
    if (glow != null) {
      // A circle stretched into an ellipse, fading to nothing at its edge.
      final glowSize = _Geometry.glow * scale;
      final radius = glowSize.height / 2;
      canvas
        ..save()
        ..translate(centre.dx, centre.dy + _Geometry.glowDrop * scale)
        ..scale(glowSize.width / glowSize.height, 1)
        ..drawCircle(
          Offset.zero,
          radius,
          Paint()
            ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
                .createShader(
                  Rect.fromCircle(center: Offset.zero, radius: radius),
                ),
        )
        ..restore();
    }

    final orbit = this.orbit;
    if (orbit == null) return;
    final radius = (size.shortestSide - _Geometry.orbitStroke) / 2;
    final circle = Path()
      ..addOval(Rect.fromCircle(center: centre, radius: radius));
    final dashes = Path();
    final dash = _Geometry.dash * scale;
    for (final metric in circle.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += dash * 2) {
        dashes.addPath(metric.extractPath(at, at + dash), Offset.zero);
      }
    }
    final at = centre + Offset.fromDirection(_Geometry.markerAngle, radius);
    final markerRadius = _Geometry.marker / 2 * scale;
    canvas
      ..drawPath(
        dashes,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _Geometry.orbitStroke
          ..color = orbit,
      )
      ..drawCircle(
        at,
        markerRadius + _Geometry.markerHalo * scale,
        Paint()..color = marker.withValues(alpha: _Geometry.markerHaloOpacity),
      )
      ..drawCircle(at, markerRadius, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.glow != glow ||
      old.orbit != orbit ||
      old.marker != marker ||
      old.scale != scale;
}
