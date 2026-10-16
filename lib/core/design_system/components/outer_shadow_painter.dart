import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Paints [shadows] around [shape] the way CSS draws `box-shadow`.
///
/// A shadow that spreads rounds its corners out with it. A [BoxDecoration]
/// keeps the box's own radius on the bigger shadow instead, which makes a
/// focus ring look square at its corners.
///
/// With [knockout] nothing is painted inside the shape, so a see-through
/// face such as frosted glass never shows its own shadow through itself.
/// Leave it off for opaque faces: they hide what is under them anyway, and
/// clipping along their edge would leave a faint seam.
///
/// Use it as the `painter` of a [CustomPaint] around the face, so the
/// shadows land beneath it.
class OuterShadowPainter extends CustomPainter {
  const OuterShadowPainter({
    required this.shadows,
    this.shape = const CircleBorder(),
    this.knockout = false,
    this.textDirection,
  });

  final List<BoxShadow> shadows;
  final ShapeBorder shape;
  final bool knockout;

  /// For shapes whose outline depends on direction.
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;
    final bounds = Offset.zero & size;
    if (knockout) {
      final reach = shadows.fold<double>(
        0,
        (most, shadow) => math.max(
          most,
          shadow.blurRadius * 2 +
              shadow.spreadRadius.abs() +
              shadow.offset.distance,
        ),
      );
      canvas
        ..save()
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(bounds.inflate(reach)),
            shape.getOuterPath(bounds, textDirection: textDirection),
          ),
        );
    }
    for (final shadow in shadows) {
      canvas.drawPath(_castBy(shadow, bounds), shadow.toPaint());
    }
    if (knockout) canvas.restore();
  }

  /// The outline [shadow] falls in: the shape moved by its offset and grown
  /// by its spread, its corners growing with it. A shrinking shadow keeps
  /// the shape's corners, so it stays round.
  Path _castBy(BoxShadow shadow, Rect bounds) {
    final rect = bounds.shift(shadow.offset);
    final spread = shadow.spreadRadius;
    final shape = this.shape;
    if (spread > 0 && shape is RoundedRectangleBorder) {
      final face = shape.borderRadius.resolve(textDirection).toRRect(rect);
      return Path()..addRRect(face.inflate(spread));
    }
    return shape.getOuterPath(
      rect.inflate(spread),
      textDirection: textDirection,
    );
  }

  @override
  bool shouldRepaint(OuterShadowPainter old) =>
      !listEquals(old.shadows, shadows) ||
      old.shape != shape ||
      old.knockout != knockout ||
      old.textDirection != textDirection;
}
