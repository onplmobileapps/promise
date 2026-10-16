import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/app_elevations.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A raised dome, lit from the upper left and standing on a solid rim: the
/// 3D base for an emblem, an avatar or an icon.
///
/// [child] sits centred in the middle of the dome, in a square
/// [AppSizes.domeContent] of its [diameter] across; a child that fills its
/// space, like `AppEmblem()`, fills that square.
class AppDome extends StatelessWidget {
  const AppDome({super.key, required this.diameter, required this.child});

  final double diameter;
  final Widget child;

  /// Where the light comes from, how far it reaches, and where it fades.
  static const Alignment _light = Alignment(-0.3, -0.5);
  static const double _lightReach = 0.99;
  static const List<double> _lightStops = [0, 0.55, 1];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final scale = diameter / AppSizes.domeDesign;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: _light,
          radius: _lightReach,
          colors: [
            colors.surfaceRaised,
            colors.surfaceRaisedEnd,
            colors.domeShade,
          ],
          stops: _lightStops,
        ),
        boxShadow: elevations.dome.scaled(scale),
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(
          shadows: elevations.domeInset.scaled(scale),
        ),
        child: SizedBox.square(
          dimension: diameter,
          child: Center(
            child: SizedBox.square(
              dimension: diameter * AppSizes.domeContent,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
