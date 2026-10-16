import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/media/cnic/cnic_vision.dart';

/// An NV21 frame [width] by [height] as the sensor sends it, its luma from
/// [luma] at each pixel; the colour plane after it is grey.
Uint8List frame(int width, int height, int Function(int x, int y) luma) {
  final bytes = Uint8List(width * height * 3 ~/ 2)..fillRange(0, 0);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      bytes[y * width + x] = luma(x, y);
    }
  }
  bytes.fillRange(width * height, bytes.length, 128);
  return bytes;
}

FrameLook? look(
  Uint8List bytes, {
  int width = 320,
  int height = 240,
  int rotation = 0,
  Rect window = const Rect.fromLTWH(40, 40, 200, 140),
}) => CnicVision.lookOfPixels(
  bytes,
  stride: width,
  width: width,
  height: height,
  bgra: false,
  rotation: rotation,
  window: window,
);

void main() {
  test('a dark, even frame is dark and soft', () {
    final result = look(frame(320, 240, (_, _) => 20))!;
    expect(result.brightness, closeTo(20, 0.01));
    expect(result.sharpness, closeTo(0, 0.01));
  });

  test('sharp print on a light card is bright and sharp', () {
    // Thin dark strokes every few pixels, as text is.
    final result = look(
      frame(320, 240, (x, y) => x % 6 == 0 || y % 9 == 0 ? 30 : 220),
    )!;
    expect(result.brightness, greaterThan(120));
    expect(result.sharpness, greaterThan(1000));
  });

  test('a smooth blur of the same card is soft', () {
    final result = look(
      frame(320, 240, (x, y) => (150 + 40 * (x / 320)).round()),
    )!;
    expect(result.sharpness, lessThan(5));
  });

  test('only the window counts, wherever the sensor turns it', () {
    // Bright in the sensor's left half only.
    final bytes = frame(320, 240, (x, _) => x < 160 ? 230 : 10);
    // Turned 90°, the upright frame is 240 by 320, and the sensor's left
    // half is the upright frame's top.
    expect(
      look(
        bytes,
        rotation: 90,
        window: const Rect.fromLTWH(20, 20, 200, 120),
      )!.brightness,
      greaterThan(200),
    );
    expect(
      look(
        bytes,
        rotation: 90,
        window: const Rect.fromLTWH(20, 180, 200, 120),
      )!.brightness,
      lessThan(30),
    );
  });

  test('a window off the frame has no look', () {
    expect(
      look(
        frame(320, 240, (_, _) => 100),
        window: const Rect.fromLTWH(400, 400, 50, 50),
      ),
      isNull,
    );
  });

  group("a CNIC's green", () {
    /// An NV21 frame [width] by [height]: a CNIC's pale green left of
    /// [split], grey right of it.
    Uint8List nv21({int width = 320, int height = 240, int split = 160}) {
      final bytes = Uint8List(width * height * 3 ~/ 2);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          bytes[y * width + x] = x < split ? 220 : 128;
        }
      }
      for (var y = 0; y < height ~/ 2; y++) {
        for (var x = 0; x < width; x += 2) {
          final i = width * height + y * width + x;
          final green = x < split;
          bytes[i] = green ? 117 : 128; // V
          bytes[i + 1] = green ? 116 : 128; // U
        }
      }
      return bytes;
    }

    test('fills a frame from the Android camera', () {
      expect(
        CnicVision.greenOfPixels(
          nv21(split: 320),
          stride: 320,
          width: 320,
          height: 240,
          layout: PixelLayout.nv21,
          window: const Rect.fromLTWH(20, 20, 280, 200),
        ),
        greaterThan(0.95),
      );
    });

    test('is measured only inside the window, turned as the sensor is', () {
      // Turned 90°, the sensor's left half is the upright frame's top.
      double share(Rect window) => CnicVision.greenOfPixels(
        nv21(),
        stride: 320,
        width: 320,
        height: 240,
        layout: PixelLayout.nv21,
        rotation: 90,
        window: window,
      );
      expect(share(const Rect.fromLTWH(20, 20, 200, 120)), greaterThan(0.95));
      expect(share(const Rect.fromLTWH(20, 180, 200, 120)), lessThan(0.05));
    });

    test('is read from four-byte pixels, BGRA and RGBA', () {
      Uint8List pixels(List<int> pixel) =>
          Uint8List.fromList([for (var i = 0; i < 64 * 48; i++) ...pixel]);
      expect(
        CnicVision.greenOfPixels(
          pixels([200, 232, 205, 255]),
          stride: 64 * 4,
          width: 64,
          height: 48,
          layout: PixelLayout.bgra,
          window: const Rect.fromLTWH(0, 0, 64, 48),
        ),
        greaterThan(0.95),
      );
      expect(
        CnicVision.greenOfPixels(
          pixels([40, 80, 200, 255]),
          stride: 64 * 4,
          width: 64,
          height: 48,
          layout: PixelLayout.rgba,
          window: const Rect.fromLTWH(0, 0, 64, 48),
        ),
        lessThan(0.05),
      );
    });
  });
}
