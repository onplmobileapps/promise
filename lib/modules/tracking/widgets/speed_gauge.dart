import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';

/// Speed ring: an arc that fills with the speed, the number in its middle.
class SpeedGauge extends StatelessWidget {
  final double speedKmh;
  final bool active;
  final double size;

  /// A full ring; Pakistan Railways trains run below this.
  static const double maxKmh = 140;

  const SpeedGauge({
    super.key,
    required this.speedKmh,
    this.active = true,
    this.size = 118,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: speedKmh.clamp(0, maxKmh).toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, kmh, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(kmh / maxKmh, active, palette),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${kmh.round()}',
                  style: TextStyle(
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w900,
                    color: active ? palette.ink : palette.mute,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'km/h',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: palette.mute,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final bool active;
  final TrackPalette palette;

  _RingPainter(this.fraction, this.active, this.palette);

  /// The ring opens at the bottom: it starts at 135° (bottom left, clockwise
  /// from 3 o'clock) and runs 270°.
  static const double _start = 3 * math.pi / 4;
  static const double _sweep = 3 * math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke;
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint arc() => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    // Soft disc behind the number.
    canvas.drawCircle(
      c,
      r - stroke * 1.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (active ? palette.soft : palette.line).withValues(alpha: 0.9),
            palette.card.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    canvas.drawArc(rect, _start, _sweep, false, arc()..color = palette.rail);

    final f = fraction.clamp(0.0, 1.0);
    if (f <= 0.002) return;
    // Rotated so the gradient runs along the ring, not across 0°.
    final shader = SweepGradient(
      endAngle: _sweep,
      colors: [palette.g3, palette.g2, palette.g1, palette.g1],
      stops: const [0, 0.5, 0.8, 1],
      transform: const GradientRotation(_start),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      _start,
      _sweep * f,
      false,
      arc()
        ..strokeCap = StrokeCap.butt
        ..shader = shader
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = palette.g2.withValues(alpha: 0.5),
    );
    canvas.drawArc(
      rect,
      _start,
      _sweep * f,
      false,
      arc()
        ..strokeCap = StrokeCap.butt
        ..shader = shader
        ..color = palette.g2,
    );
    final start = c + Offset(math.cos(_start), math.sin(_start)) * r;
    canvas.drawCircle(start, stroke / 2, Paint()..color = palette.g3);

    // Knob at the tip.
    final a = _start + _sweep * f;
    final tip = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(tip, stroke / 2 + 2, Paint()..color = palette.halo);
    canvas.drawCircle(tip, stroke / 2 - 1, Paint()..color = palette.g1);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.active != active ||
      old.palette != palette;
}

/// A number that counts to each new [value].
class CountUpText extends StatelessWidget {
  final double value;
  final String Function(double value) format;
  final TextStyle style;

  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}
