import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/icons/glyph_paths.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Draws an [AppGlyph]: its lines in [color], its tinted parts in [tint],
/// and its cut-out parts in [cut]. Without them it takes the icon theme's
/// colour, the theme's soft icon fill, and the surface.
class AppGlyphIcon extends StatelessWidget {
  const AppGlyphIcon(
    this.glyph, {
    super.key,
    this.size = AppSizes.iconMd,
    this.color,
    this.tint,
    this.cut,
    this.semanticLabel,
    this.depth = false,
  });

  final AppGlyph glyph;
  final double size;
  final Color? color;
  final Color? tint;
  final Color? cut;
  final String? semanticLabel;

  /// Drawn in 3D: lit from above, glossed and on a soft shadow.
  final bool depth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final glyph = CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(
        glyph: this.glyph,
        stroke: color ?? IconTheme.of(context).color ?? colors.textPrimary,
        tint: tint ?? colors.iconFill,
        cut: cut ?? colors.surface,
        depth: depth,
      ),
    );
    final label = semanticLabel;
    if (label == null) return ExcludeSemantics(child: glyph);
    return Semantics(label: label, image: true, child: glyph);
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.stroke,
    required this.tint,
    required this.cut,
    required this.depth,
  });

  final AppGlyph glyph;
  final Color stroke;
  final Color tint;
  final Color cut;
  final bool depth;

  @override
  void paint(Canvas canvas, Size size) => paintGlyph(
    canvas,
    glyph,
    offset: Offset.zero,
    size: size.shortestSide,
    stroke: stroke,
    tint: tint,
    cut: cut,
    depth: depth,
  );

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.stroke != stroke ||
      old.tint != tint ||
      old.cut != cut ||
      old.depth != depth;
}
