import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Paint scheme of a train.
class TrainLivery {
  final Color bodyDark;
  final Color body;
  final Color bodyLight;
  final Color band;
  final Color roof;
  final Color glass;

  const TrainLivery({
    required this.bodyDark,
    required this.body,
    required this.bodyLight,
    required this.band,
    required this.roof,
    required this.glass,
  });

  /// Pakistan Railways: green locomotive and coaches with a yellow band.
  static const pakistanRailways = TrainLivery(
    bodyDark: Color(0xFF0A4A2A),
    body: Color(0xFF167340),
    bodyLight: Color(0xFF3DB46D),
    band: Color(0xFFF7C948),
    roof: Color(0xFFEDE6CF),
    glass: Color(0xFF13222E),
  );

  /// For all trains: official green locomotive and coaches.
  static const faded = TrainLivery(
    bodyDark: Color(0xFF0A4A2A),
    body: Color(0xFF167340),
    bodyLight: Color(0xFF3DB46D),
    band: Color(0xFFF7C948),
    roof: Color(0xFFEDE6CF),
    glass: Color(0xFF13222E),
  );
}

/// Logical size of the train drawing. The train points up (north); the
/// headlight beams take the top [_beam] pixels.
const Size kTrainSpriteSize = Size(32, 104);
const double _beam = 18;

/// Draws a locomotive with one coach behind it, seen from above and shaded
/// to look solid, into the [kTrainSpriteSize] box.
void paintTrain(Canvas canvas, TrainLivery l, {bool headlights = true}) {
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.34)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6);

  // Headlight beams.
  if (headlights) {
    for (final x in [11.5, 20.5]) {
      final beam = Path()
        ..moveTo(x, _beam + 1.5)
        ..lineTo(x - 8, 0)
        ..lineTo(x + 8, 0)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = ui.Gradient.linear(Offset(x, _beam), Offset(x, 0), [
            const Color(0x80FFF3B0),
            const Color(0x00FFF3B0),
          ]),
      );
    }
  }

  // Coach.
  final coach = RRect.fromLTRBR(6.5, 63, 25.5, 98, const Radius.circular(3.6));
  canvas.drawRRect(coach.shift(const Offset(1.4, 2.6)), shadow);
  canvas.drawRRect(coach, Paint()..shader = _cylinder(coach.outerRect, l));
  final roof = RRect.fromLTRBR(12, 65, 20, 96, const Radius.circular(2.4));
  canvas.drawRRect(
    roof,
    Paint()
      ..shader = ui.Gradient.linear(
        roof.outerRect.centerLeft,
        roof.outerRect.centerRight,
        [
          l.roof.withValues(alpha: 0.75),
          l.roof,
          l.roof.withValues(alpha: 0.75),
        ],
        [0, 0.5, 1],
      ),
  );
  final window = Paint()..color = l.glass.withValues(alpha: 0.85);
  for (var y = 67.0; y < 95; y += 4.6) {
    canvas.drawRRect(
      RRect.fromLTRBR(7.3, y, 9.0, y + 2.6, const Radius.circular(0.6)),
      window,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(23.0, y, 24.7, y + 2.6, const Radius.circular(0.6)),
      window,
    );
  }

  // Coupler.
  canvas.drawRect(
    const Rect.fromLTRB(14, 59.5, 18, 63.5),
    Paint()..color = const Color(0xFF1F2933),
  );

  // Locomotive body, rounded at the nose.
  final loco = RRect.fromLTRBAndCorners(
    6,
    _beam,
    26,
    60,
    topLeft: const Radius.circular(9),
    topRight: const Radius.circular(9),
    bottomLeft: const Radius.circular(3),
    bottomRight: const Radius.circular(3),
  );
  canvas.drawRRect(loco.shift(const Offset(1.4, 2.6)), shadow);
  canvas.drawRRect(loco, Paint()..shader = _cylinder(loco.outerRect, l));

  // Yellow bands along the sides and a chevron on the nose.
  final band = Paint()
    ..color = l.band
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawLine(const Offset(7.7, 33), const Offset(7.7, 58), band);
  canvas.drawLine(const Offset(24.3, 33), const Offset(24.3, 58), band);
  canvas.drawPath(
    Path()
      ..moveTo(8.2, _beam + 6.5)
      ..quadraticBezierTo(16, _beam + 1.2, 23.8, _beam + 6.5),
    band..strokeWidth = 2.0,
  );

  // Cab windscreen with a glint.
  final glass = Path()
    ..moveTo(9.4, _beam + 9.5)
    ..quadraticBezierTo(16, _beam + 5.6, 22.6, _beam + 9.5)
    ..lineTo(21.6, _beam + 13.4)
    ..lineTo(10.4, _beam + 13.4)
    ..close();
  canvas.drawPath(
    glass,
    Paint()
      ..shader = ui.Gradient.linear(
        const Offset(16, _beam + 6),
        const Offset(16, _beam + 13.4),
        [Color.lerp(l.glass, Colors.white, 0.35)!, l.glass],
      ),
  );
  canvas.drawLine(
    const Offset(11.6, _beam + 9.6),
    const Offset(14.8, _beam + 7.7),
    Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round,
  );

  // Cab roof, exhaust and radiator grilles.
  canvas.drawRRect(
    RRect.fromLTRBR(
      9.5,
      _beam + 15,
      22.5,
      _beam + 19.5,
      const Radius.circular(1.6),
    ),
    Paint()..color = l.bodyLight.withValues(alpha: 0.55),
  );
  canvas.drawCircle(
    const Offset(16, 41),
    2.3,
    Paint()..color = const Color(0xFF1F2933),
  );
  canvas.drawCircle(
    const Offset(16, 41),
    2.3,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = l.bodyLight,
  );
  final grille = RRect.fromLTRBR(10, 45, 22, 57.5, const Radius.circular(1.8));
  canvas.drawRRect(grille, Paint()..color = l.bodyDark.withValues(alpha: 0.9));
  final slat = Paint()
    ..color = Colors.white.withValues(alpha: 0.16)
    ..strokeWidth = 0.7;
  for (var y = 47.0; y < 57; y += 2.1) {
    canvas.drawLine(Offset(11, y), Offset(21, y), slat);
  }

  // Headlamps.
  if (headlights) {
    for (final x in [11.5, 20.5]) {
      canvas.drawCircle(
        Offset(x, _beam + 2.2),
        2.4,
        Paint()..color = const Color(0x66FFF3B0),
      );
      canvas.drawCircle(
        Offset(x, _beam + 2.2),
        1.2,
        Paint()..color = const Color(0xFFFFFBEA),
      );
    }
  }
}

/// Side-to-side shading that makes a flat box read as a rounded roof.
Shader _cylinder(Rect r, TrainLivery l) => ui.Gradient.linear(
  r.centerLeft,
  r.centerRight,
  [l.bodyDark, l.body, l.bodyLight, l.body, l.bodyDark],
  [0, 0.22, 0.5, 0.78, 1],
);

/// PNG of the train at [pixelRatio], for a map icon image.
Future<Uint8List> renderTrainSprite(
  TrainLivery livery,
  double pixelRatio, {
  bool headlights = true,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  paintTrain(canvas, livery, headlights: headlights);
  final image = await recorder.endRecording().toImage(
    (kTrainSpriteSize.width * pixelRatio).ceil(),
    (kTrainSpriteSize.height * pixelRatio).ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

/// The train drawing as a widget, turned to [direction] (radians clockwise
/// from pointing up) and scaled to [length] along its axis.
class TrainGlyph extends StatelessWidget {
  final double length;
  final double direction;
  final TrainLivery livery;
  final bool headlights;

  const TrainGlyph({
    super.key,
    this.length = 52,
    this.direction = math.pi / 2,
    this.livery = TrainLivery.pakistanRailways,
    this.headlights = false,
  });

  @override
  Widget build(BuildContext context) {
    final scale = length / kTrainSpriteSize.height;
    final w = kTrainSpriteSize.width * scale;
    final h = kTrainSpriteSize.height * scale;
    final horizontal = (direction / (math.pi / 2)).round().isOdd;
    return SizedBox(
      width: horizontal ? h : w,
      height: horizontal ? w : h,
      child: CustomPaint(
        painter: _GlyphPainter(scale, direction, livery, headlights),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  final double scale;
  final double direction;
  final TrainLivery livery;
  final bool headlights;

  _GlyphPainter(this.scale, this.direction, this.livery, this.headlights);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(direction);
    canvas.scale(scale);
    canvas.translate(-kTrainSpriteSize.width / 2, -kTrainSpriteSize.height / 2);
    paintTrain(canvas, livery, headlights: headlights);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.scale != scale ||
      old.direction != direction ||
      old.livery != livery ||
      old.headlights != headlights;
}
