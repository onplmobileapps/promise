import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Paints [shadows] inside [shape], the way CSS draws `inset` box shadows:
/// each falls inward from the shape's edge, moved by its offset and drawn
/// in by its spread.
///
/// Use it as the `painter` of a [CustomPaint] wrapped around the shape's
/// content, so the shadows land over the shape's fill and under what sits
/// on it. A light shadow offset downwards reads as a lit top rim; a dark one
/// offset upwards, as shade gathering at the foot.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter({
    required this.shadows,
    this.shape = const CircleBorder(),
    this.textDirection,
  });

  final List<BoxShadow> shadows;
  final ShapeBorder shape;

  /// For shapes whose outline depends on direction.
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas
      ..save()
      ..clipPath(shape.getOuterPath(bounds, textDirection: textDirection));
    for (final shadow in shadows) {
      // Everything outside the moved, shrunken shape casts into the real one.
      final lit = shape
          .getOuterPath(
            bounds.deflate(shadow.spreadRadius),
            textDirection: textDirection,
          )
          .shift(shadow.offset);
      final reach =
          shadow.blurRadius * 2 +
          shadow.spreadRadius.abs() +
          shadow.offset.distance;
      final caster = Path.combine(
        PathOperation.difference,
        Path()..addRect(bounds.inflate(reach)),
        lit,
      );
      canvas.drawPath(caster, shadow.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter old) =>
      !listEquals(old.shadows, shadows) ||
      old.shape != shape ||
      old.textDirection != textDirection;
}
