import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/icons/glyph_paths.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Draws an [AppGlyph]: its lines in [color], its tinted parts in [tint],
/// and its cut-out parts in [cut]. Without them it takes the icon theme's
/// colour, the theme's soft icon fill, and the surface.
///
/// Each glyph is drawn once, at the screen's own pixels, into a picture
/// kept in memory, and after that shown as that picture — as an icon from
/// a PNG is — rather than drawn again from its lines every frame: the
/// renderer keeps no copy of drawn shapes between frames, so a long list
/// of icons, those in 3D with a blurred shadow most of all, would cost a
/// scrolling frame dearly.
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
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
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
    required this.pixelRatio,
  });

  final AppGlyph glyph;
  final Color stroke;
  final Color tint;
  final Color cut;
  final bool depth;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final picture = GlyphPictures.of(
      glyph,
      side: side,
      pixelRatio: pixelRatio,
      stroke: stroke,
      tint: tint,
      cut: cut,
      depth: depth,
    );
    if (picture == null) {
      paintGlyph(
        canvas,
        glyph,
        offset: Offset.zero,
        size: side,
        stroke: stroke,
        tint: tint,
        cut: cut,
        depth: depth,
      );
      return;
    }
    final margin = side * GlyphPictures.margin;
    final image = picture;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(-margin, -margin, side + 2 * margin, side + 2 * margin),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph ||
      old.stroke != stroke ||
      old.tint != tint ||
      old.cut != cut ||
      old.depth != depth ||
      old.pixelRatio != pixelRatio;
}

/// Glyphs drawn into pictures, kept so each is drawn once: the most
/// recently used few hundred, by glyph, colours, depth and size in pixels.
abstract final class GlyphPictures {
  /// Room round a glyph's square, as a share of its side, for what is
  /// drawn past its edge: a 3D glyph's shadow, a line's round end.
  static const double margin = 0.125;

  /// Pictures kept at most; a few hundred icons' worth, a few megabytes.
  static const int _most = 300;

  static final LinkedHashMap<_Key, ui.Image> _kept = LinkedHashMap();

  /// Off where a picture can't be made, as in some tests' renderers.
  static bool enabled = true;

  /// [glyph] as a picture [side] logical pixels across at [pixelRatio];
  /// null if one can't be made, to be drawn from its lines instead.
  static ui.Image? of(
    AppGlyph glyph, {
    required double side,
    required double pixelRatio,
    required Color stroke,
    required Color tint,
    required Color cut,
    required bool depth,
  }) {
    if (!enabled || side <= 0) return null;
    final pixels = (side * pixelRatio).round();
    if (pixels <= 0 || pixels > 1024) return null;
    final key = _Key(glyph, pixels, stroke, tint, cut, depth);
    final kept = _kept.remove(key);
    if (kept != null) {
      // Most recently used goes last.
      _kept[key] = kept;
      return kept;
    }
    final ui.Image image;
    try {
      final whole = (pixels * (1 + 2 * margin)).ceil();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final scale = pixels / side;
      canvas.scale(scale);
      final m = side * margin;
      paintGlyph(
        canvas,
        glyph,
        offset: Offset(m, m),
        size: side,
        stroke: stroke,
        tint: tint,
        cut: cut,
        depth: depth,
      );
      final picture = recorder.endRecording();
      image = picture.toImageSync(whole, whole);
      picture.dispose();
    } catch (_) {
      enabled = false;
      return null;
    }
    _kept[key] = image;
    while (_kept.length > _most) {
      final oldest = _kept.keys.first;
      _kept.remove(oldest)?.dispose();
    }
    return image;
  }

  /// Lets every picture go, as when memory runs short.
  static void clear() {
    for (final image in _kept.values) {
      image.dispose();
    }
    _kept.clear();
  }
}

@immutable
class _Key {
  const _Key(
    this.glyph,
    this.pixels,
    this.stroke,
    this.tint,
    this.cut,
    this.depth,
  );

  final AppGlyph glyph;
  final int pixels;
  final Color stroke;
  final Color tint;
  final Color cut;
  final bool depth;

  @override
  bool operator ==(Object other) =>
      other is _Key &&
      other.glyph == glyph &&
      other.pixels == pixels &&
      other.stroke == stroke &&
      other.tint == tint &&
      other.cut == cut &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(glyph, pixels, stroke, tint, cut, depth);
}
