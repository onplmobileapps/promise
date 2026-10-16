import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A groove sunk into a card, filled between [from] and [to] (shares of
/// its length, 0 to 1), such as how much of a shift has gone. [marks] are
/// thin ticks standing across it, like a break.
///
/// The fill runs jade by default; [fill] gives it another gradient, laid
/// across the filled part.
class AppProgressTrack extends StatelessWidget {
  const AppProgressTrack({
    super.key,
    required this.to,
    this.from = 0,
    this.marks = const [],
    this.fill,
    this.height = AppSizes.progressTrack,
    this.semanticLabel,
  });

  final double from;
  final double to;
  final List<double> marks;
  final Gradient? fill;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(height / 2);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    return Semantics(
      label: semanticLabel,
      child: CustomPaint(
        // Ticks stand out of the groove, over everything.
        foregroundPainter: marks.isEmpty
            ? null
            : _MarksPainter(
                marks: marks,
                color: colors.textTertiary.withValues(alpha: 0.4),
              ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
            ),
            borderRadius: radius,
          ),
          child: CustomPaint(
            foregroundPainter: InsetShadowPainter(
              shape: shape,
              shadows: context.elevations.recessInset,
            ),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _FillPainter(
                  from: from.clamp(0, 1).toDouble(),
                  to: to.clamp(0, 1).toDouble(),
                  gradient:
                      fill ??
                      LinearGradient(
                        colors: [colors.iconFillActive, colors.success],
                      ),
                  highlight: colors.surfaceRaised.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FillPainter extends CustomPainter {
  const _FillPainter({
    required this.from,
    required this.to,
    required this.gradient,
    required this.highlight,
  });

  final double from;
  final double to;
  final Gradient gradient;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    if (to <= from) return;
    final rect = Rect.fromLTRB(
      size.width * from,
      0,
      size.width * to,
      size.height,
    );
    final pill = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );
    canvas
      ..drawRRect(pill, Paint()..shader = gradient.createShader(rect))
      ..save()
      ..clipRRect(pill)
      // The lit top edge of the fill.
      ..drawRect(
        Rect.fromLTWH(rect.left, 0, rect.width, 1),
        Paint()..color = highlight,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_FillPainter old) =>
      old.from != from ||
      old.to != to ||
      old.gradient != gradient ||
      old.highlight != highlight;
}

class _MarksPainter extends CustomPainter {
  const _MarksPainter({required this.marks, required this.color});

  final List<double> marks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final overhang = (AppSizes.progressMark - size.height) / 2;
    for (final mark in marks) {
      final x = size.width * mark.clamp(0, 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - AppSizes.progressMarkWidth / 2,
            -overhang,
            AppSizes.progressMarkWidth,
            AppSizes.progressMark,
          ),
          const Radius.circular(AppSizes.progressMarkWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarksPainter old) =>
      old.color != color || old.marks != marks;
}

/// Shares of a whole side by side in one bar, like a team's day: each
/// segment as long as its value, in its colour, with a hairline gap
/// between them and round outer ends.
class AppStackedBar extends StatelessWidget {
  const AppStackedBar({
    super.key,
    required this.segments,
    this.height = AppSizes.stackedBar,
    this.semanticLabel,
  });

  final List<({int value, Color color})> segments;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final segment in segments)
        if (segment.value > 0) segment,
    ];
    if (shown.isEmpty) return SizedBox(height: height);
    final end = Radius.circular(height / 2);
    const inner = Radius.circular(1);
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSizes.stackedBarGap),
              Expanded(
                flex: shown[i].value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: shown[i].color,
                    borderRadius: BorderRadius.horizontal(
                      left: i == 0 ? end : inner,
                      right: i == shown.length - 1 ? end : inner,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
