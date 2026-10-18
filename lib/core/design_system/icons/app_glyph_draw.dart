import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/icons/glyph_paths.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// [glyph] drawing itself, once, as it first appears: its lines traced from
/// their start as a pen would, then its tinted parts filling in — as an
/// [AppLottieMark] draws, for any glyph and in the theme's colours.
///
/// Drawn, it is the glyph as [AppGlyphIcon] shows it; and that, at once,
/// for those who ask for less motion and on a phone drawing lite.
class AppGlyphDraw extends StatefulWidget {
  const AppGlyphDraw(
    this.glyph, {
    super.key,
    this.size = AppSizes.iconXl,
    this.color,
    this.tint,
    this.delay = Duration.zero,
  });

  final AppGlyph glyph;
  final double size;
  final Color? color;
  final Color? tint;

  /// How long it waits before it starts.
  final Duration delay;

  @override
  State<AppGlyphDraw> createState() => _AppGlyphDrawState();
}

class _AppGlyphDrawState extends State<AppGlyphDraw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: AppMotion.glyphDraw,
  );
  bool _still = false;
  bool _started = false;
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _still =
        MediaQuery.disableAnimationsOf(context) ||
        AppPerformance.liteOf(context);
    if (_still) return;
    _wait = Timer(widget.delay, _draw.forward);
  }

  @override
  void dispose() {
    _wait?.cancel();
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stroke = widget.color ?? colors.iconAccent;
    final tint = widget.tint ?? colors.iconFill;
    final still = AppGlyphIcon(
      widget.glyph,
      size: widget.size,
      color: stroke,
      tint: tint,
    );
    if (_still) return still;
    return AnimatedBuilder(
      animation: _draw,
      builder: (context, _) => _draw.isCompleted
          ? still
          : CustomPaint(
              size: Size.square(widget.size),
              painter: _DrawPainter(
                glyph: widget.glyph,
                progress: Curves.easeInOutCubic.transform(_draw.value),
                stroke: stroke,
                tint: tint,
                cut: colors.surface,
              ),
            ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  _DrawPainter({
    required this.glyph,
    required this.progress,
    required this.stroke,
    required this.tint,
    required this.cut,
  });

  final AppGlyph glyph;
  final double progress;
  final Color stroke;
  final Color tint;
  final Color cut;

  /// The lines take this share of the time; the fills come in after.
  static const double _linesShare = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas
      ..save()
      ..scale(scale);
    final shapes = glyphShapes(glyph);
    final fillIn = ((progress - _linesShare * 0.6) / (1 - _linesShare * 0.6))
        .clamp(0.0, 1.0);
    for (final shape in shapes) {
      final fill = switch (shape.fill) {
        GlyphFill.none => null,
        GlyphFill.tint => tint,
        GlyphFill.cut => cut,
        GlyphFill.ink => stroke,
      };
      if (fill != null && fill.a > 0 && fillIn > 0) {
        canvas.drawPath(
          shape.path,
          Paint()..color = fill.withValues(alpha: fill.a * fillIn),
        );
      }
    }
    if (glyph.strokeWidth > 0) {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = glyph.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = stroke;
      final drawn = (progress / _linesShare).clamp(0.0, 1.0);
      for (final shape in shapes) {
        for (final metric in shape.path.computeMetrics()) {
          canvas.drawPath(metric.extractPath(0, metric.length * drawn), line);
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DrawPainter old) =>
      old.progress != progress ||
      old.glyph != glyph ||
      old.stroke != stroke ||
      old.tint != tint ||
      old.cut != cut;
}
