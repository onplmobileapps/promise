import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Paints the khatam, the eight-pointed star of Mughal tile work, as a faint
/// texture that fades out down the page. Static: it never animates.
class KhatamPatternPainter extends CustomPainter {
  const KhatamPatternPainter({
    required this.color,
    this.tileSize = 48,
    this.fadeHeight = 320,
    this.strokeWidth = 0.8,
  });

  final Color color;
  final double tileSize;

  /// The pattern is gone by this distance from the top.
  final double fadeHeight;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final height = math.min(size.height, fadeHeight);
    if (height <= 0 || size.width <= 0) return;
    final baseAlpha = color.a;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final t = tileSize;
    final square = t * 19 / 48;
    final arm = t * 10.6 / 48;
    for (var y = 0.0; y < height; y += t) {
      // Each row a little fainter than the one above it.
      final fade = 1 - (y + t / 2) / fadeHeight;
      if (fade <= 0) break;
      paint.color = color.withValues(alpha: baseAlpha * fade);
      for (var x = 0.0; x < size.width; x += t) {
        final c = Offset(x + t / 2, y + t / 2);
        final rect = Rect.fromCenter(center: c, width: square, height: square);
        canvas.drawRect(rect, paint);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: square, height: square),
          paint,
        );
        canvas.restore();
        canvas.drawCircle(c, t * 3 / 48, paint);
        canvas.drawLine(Offset(c.dx, y), Offset(c.dx, y + arm), paint);
        canvas.drawLine(Offset(c.dx, y + t - arm), Offset(c.dx, y + t), paint);
        canvas.drawLine(Offset(x, c.dy), Offset(x + arm, c.dy), paint);
        canvas.drawLine(Offset(x + t - arm, c.dy), Offset(x + t, c.dy), paint);
      }
    }
  }

  @override
  bool shouldRepaint(KhatamPatternPainter old) =>
      old.color != color ||
      old.tileSize != tileSize ||
      old.fadeHeight != fadeHeight ||
      old.strokeWidth != strokeWidth;
}
