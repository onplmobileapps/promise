// Runs the CNIC AI on a phone: cards are drawn, photographed as files, and
// looked at by ML Kit's face detection and text recognition, and their
// colour measured, as a scan's photo is.
// `flutter test integration_test/cnic_vision_test.dart -d <device>`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';
import 'package:railway_hrms/core/media/cnic/cnic_check.dart';
import 'package:railway_hrms/core/media/cnic/cnic_crop.dart';
import 'package:railway_hrms/core/media/cnic/cnic_vision.dart';

/// Print on a card: [text] at [x], [y], [size] high.
typedef Print = (String text, double x, double y, double size);

/// A card 1000 × 630, as a scan crops it, with [prints] on [paper] in
/// [ink], saved as a PNG; its path.
Future<String> drawCard(
  List<Print> prints, {
  Color paper = const Color(0xFFD6EDD2),
  Color ink = const Color(0xFF1B2A22),
  bool pattern = true,
}) async {
  const size = Size(1000, 630);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Offset.zero & size, Paint()..color = paper);
  if (pattern) {
    // A faint guilloche, as on a real card.
    final lines = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ink.withValues(alpha: 0.06);
    for (var r = 40.0; r < 900; r += 18) {
      canvas.drawCircle(const Offset(820, 330), r, lines);
    }
  }
  for (final (text, x, y, height) in prints) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: height,
          fontWeight: AppFonts.semiBold,
          color: ink,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final folder = await getTemporaryDirectory();
  final file = File(
    '${folder.path}/card_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
  return file.path;
}

/// A photo 1080 × 1920, as the camera takes one, of a dark table with
/// [prints] on a card at [card], saved as a PNG; its path.
Future<String> drawPhoto(List<Print> prints, Rect card) async {
  const size = Size(1080, 1920);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2A2A2A))
    ..drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(18)),
      Paint()..color = const Color(0xFFE8F2E6),
    )
    ..save()
    ..translate(card.left, card.top)
    ..scale(card.width / 1000);
  for (final (text, x, y, height) in prints) {
    (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppFonts.text,
          fontSize: height,
          fontWeight: AppFonts.semiBold,
          color: const Color(0xFF1B2A22),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(canvas, Offset(x, y));
  }
  canvas.restore();
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final folder = await getTemporaryDirectory();
  final file = File(
    '${folder.path}/photo_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
  return file.path;
}

/// What the AI makes of the picture at [path]: the problem with it as a
/// photo of a CNIC, or null when it is one.
Future<CnicProblem?> check(CnicVision vision, String path) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  final size = Size(image.width.toDouble(), image.height.toDouble());
  final sight = await vision.readPixels(rgba, image.width, image.height);
  final green = CnicVision.greenOfPixels(
    rgba,
    stride: image.width * 4,
    width: image.width,
    height: image.height,
    layout: PixelLayout.rgba,
    window: Offset.zero & size,
  );
  image.dispose();
  debugPrint(
    'Check: ${sight.faces.length} face(s), green ${green.toStringAsFixed(2)}, '
    '${sight.lines.map((line) => line.text).join(' | ')}',
  );
  return CnicCheck.photo(
    lines: sight.lines,
    faces: sight.faces,
    green: green,
    size: size,
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late CnicVision vision;
  setUp(() => vision = CnicVision());
  tearDown(() => vision.close());

  testWidgets("a CNIC's pale green is measured as such", (tester) async {
    final path = await drawCard(const [('PAKISTAN', 40, 24, 44)]);
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final image = (await codec.getNextFrame()).image;
    final rgba = (await image.toByteData())!.buffer.asUint8List();
    final green = CnicVision.greenOfPixels(
      rgba,
      stride: image.width * 4,
      width: image.width,
      height: image.height,
      layout: PixelLayout.rgba,
      window: Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
    );
    expect(green, greaterThan(CnicCheck.greenCard));
  });

  testWidgets('a credit card is turned away', (tester) async {
    final path = await drawCard(
      [
        ('HBL', 40, 30, 44),
        ('4111 1111 1111 1111', 60, 300, 52),
        ('VALID THRU 12/28', 300, 400, 26),
        ('MUHAMMAD ALI', 60, 500, 32),
        ('VISA', 800, 520, 52),
      ],
      paper: const Color(0xFF1C2E5A),
      ink: const Color(0xFFF2F2F2),
    );
    expect(await check(vision, path), CnicProblem.bankCard);
  });

  testWidgets('a green driving licence is turned away', (tester) async {
    final path = await drawCard([
      ('GOVERNMENT OF THE PUNJAB', 40, 24, 30),
      ('DRIVING LICENCE', 40, 70, 36),
      ('Name', 40, 140, 20),
      ('Ali Raza', 40, 166, 30),
      ('CNIC No 35202-1234567-1', 40, 230, 30),
    ]);
    expect(await check(vision, path), CnicProblem.otherCard);
  });

  testWidgets('a green card without a photo on it is not taken', (
    tester,
  ) async {
    final path = await drawCard([
      ('PAKISTAN', 40, 24, 44),
      ('National Identity Card', 560, 30, 28),
    ]);
    expect(await check(vision, path), CnicProblem.nothing);
  });

  testWidgets('a photo is cropped to the card frame the user saw', (
    tester,
  ) async {
    // The camera window and its frame, as the scanner lays them out.
    const viewport = Size(350, 280);
    final frame = cardFrameIn(viewport);
    // The frame in the photo: the preview covered the window.
    const scale = 350 / 1080;
    const dy = (280 - 1920 * scale) / 2;
    final framed = Rect.fromLTWH(
      frame.left / scale,
      (frame.top - dy) / scale,
      frame.width / scale,
      frame.height / scale,
    );
    final path = await drawPhoto(const [('PAKISTAN', 40, 24, 44)], framed);
    final cut = (await cropCnic(XFile(path), frame, viewport))!;
    expect(cut.width, closeTo(framed.width, 2));
    expect(cut.width / cut.height, closeTo(idCardAspectRatio, 0.02));
    final photo = await cut.file;
    expect(File(photo.path).lengthSync(), greaterThan(10000));
  });
}
