import 'package:flutter/material.dart';

const double kFaceOverlayWidthRatio = 0.75;
const double kFaceOverlayHeightRatio = 0.50;
const double kFaceOverlayCenterYOffsetRatio = -0.017;

class BinanceScannerPainter extends CustomPainter {
  final double progress;
  BinanceScannerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2 + (kFaceOverlayCenterYOffsetRatio * size.height),
    );

    final frameRect = Rect.fromCenter(
      center: center,
      width: size.width * kFaceOverlayWidthRatio,
      height: size.height * kFaceOverlayHeightRatio,
    );

    final radius = Radius.circular(frameRect.width * 0.47);
    final capsule = RRect.fromRectAndRadius(frameRect, radius);

    // 1. Draw Static Frames (Mint and Orange)
    final mintPaint = Paint()
      ..color = const Color(0xFF8AB5A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawRRect(capsule, mintPaint);

    final innerOrange = capsule.deflate(10);

    // 2. Prepare the Progress Path
    final dashedGuide = innerOrange.deflate(8);
    final Path path = Path()..addRRect(dashedGuide);

    // 3. Draw Dashed Guide
    _drawDashedRRect(
      canvas,
      dashedGuide,
      const Color(0xCCFFFFFF),
      strokeWidth: 2,
      dashLength: 10,
      gapLength: 8,
    );

    // 4. Draw Path-Based Progress
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress > 0) {
      // Get the metric to calculate partial length
      final metrics = path.computeMetrics().first;
      final extractPath = metrics.extractPath(
        0.0,
        metrics.length * clampedProgress,
      );

      canvas.drawPath(
        extractPath,
        Paint()
          ..color = const Color(0xFFF28A00)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BinanceScannerPainter oldDelegate) =>
      oldDelegate.progress != progress;

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Color color, {
    required double strokeWidth,
    required double dashLength,
    required double gapLength,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength)
            .clamp(0.0, metric.length)
            .toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }
}
