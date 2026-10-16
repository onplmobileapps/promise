import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/app_elevations.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A rounded 3D tile for an icon or a small picture: its face shades from
/// warm ivory into a jade tint, lit along its top edge and shaded at its
/// foot. [child] sits in the middle.
class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.size, required this.child});

  final double size;
  final Widget child;

  /// Its corners, as a share of its size.
  static const double _cornerShare = 24 / 74;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size * _cornerShare),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.tile, colors.tileEnd],
        ),
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(
          shape: shape,
          shadows: context.elevations.tileInset.scaled(
            size / AppSizes.moduleTile,
          ),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
