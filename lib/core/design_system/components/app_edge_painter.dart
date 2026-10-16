import 'package:flutter/rendering.dart';

/// An even coloured edge round [shape], [width] wide. Painted over a
/// surface's inner light ([InsetShadowPainter]), it shows as strongly along
/// the top as round the rest, which a border under that light doesn't.
class AppEdgePainter extends CustomPainter {
  const AppEdgePainter({
    required this.colour,
    required this.shape,
    this.width = 1.5,
  });

  final Color colour;
  final ShapeBorder shape;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    canvas.drawPath(
      shape.getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = colour,
    );
  }

  @override
  bool shouldRepaint(AppEdgePainter old) =>
      old.colour != colour || old.shape != shape || old.width != width;
}
