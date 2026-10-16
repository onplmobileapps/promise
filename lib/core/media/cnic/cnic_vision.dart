import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:railway_hrms/core/media/cnic/cnic_check.dart';

/// How a frame looks: its light, from 0 to 255, and its sharpness.
typedef FrameLook = ({double brightness, double sharpness});

/// How a frame's pixels are laid out: one luma plane then interleaved
/// chroma (NV21, Android's camera), or four bytes a pixel.
enum PixelLayout { nv21, bgra, rgba }

/// What the camera's AI found in a picture: the faces in it, in pixels of
/// the picture stood upright, and the text read on it.
@immutable
class CnicSight {
  const CnicSight({required this.faces, required this.lines});

  final List<Rect> faces;
  final List<OcrLine> lines;
}

/// The on-device AI that looks at a CNIC: ML Kit's face detection finds
/// the holder's photo on the card, and its text recognition reads what is
/// printed only to turn away look-alike cards; the text is never shown.
/// The card's colour, light and sharpness are measured from its pixels.
/// Nothing leaves the phone. [CnicCheck] judges what they found.
class CnicVision {
  final _text = TextRecognizer();
  FaceDetector? _faces;
  FaceDetector? _quickFaces;
  bool _closed = false;

  /// For photos: careful, as the card's photo is small.
  FaceDetector get _faceDetector => _faces ??= FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.03,
    ),
  );

  /// For the live frames, which must keep up with the camera.
  FaceDetector get _quickFaceDetector => _quickFaces ??= FaceDetector(
    options: FaceDetectorOptions(minFaceSize: 0.03),
  );

  /// What is in a frame of the camera's stream, turned [rotation] degrees
  /// clockwise to stand upright; null when the frame can't be read.
  Future<CnicSight?> readFrame(CameraImage image, int rotation) async {
    if (_closed) return null;
    final input = _inputOf(image, rotation);
    if (input == null) return null;
    return _look(input, _quickFaceDetector);
  }

  /// What is in a photo of a card, cropped to it, as RGBA [pixels] [width]
  /// by [height].
  Future<CnicSight> readPixels(Uint8List pixels, int width, int height) =>
      _look(
        InputImage.fromBitmap(bitmap: pixels, width: width, height: height),
        _faceDetector,
      );

  Future<CnicSight> _look(InputImage input, FaceDetector faces) async {
    if (_closed) return const CnicSight(faces: [], lines: []);
    final (text, found) = await (
      _text.processImage(input),
      faces.processImage(input),
    ).wait;
    return CnicSight(
      faces: [for (final face in found) face.boundingBox],
      lines: linesOf(text),
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _text.close();
    await _faces?.close();
    await _quickFaces?.close();
  }

  /// The runs of [text]: each line, split where its words stand far apart,
  /// as a card's two columns do.
  @visibleForTesting
  static List<OcrLine> linesOf(RecognizedText text) {
    final lines = <OcrLine>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final words = [...line.elements]
          ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        if (words.isEmpty) {
          lines.add(OcrLine(line.text, line.boundingBox));
          continue;
        }
        final height = words
            .map((word) => word.boundingBox.height)
            .reduce(math.max);
        var run = [words.first];
        for (final word in words.skip(1)) {
          final gap = word.boundingBox.left - run.last.boundingBox.right;
          if (gap > height * 1.5) {
            lines.add(_join(run));
            run = [word];
          } else {
            run.add(word);
          }
        }
        lines.add(_join(run));
      }
    }
    return lines;
  }

  static OcrLine _join(List<TextElement> words) => OcrLine(
    words.map((word) => word.text).join(' '),
    words
        .map((word) => word.boundingBox)
        .reduce((box, next) => box.expandToInclude(next)),
  );

  /// How [image] looks inside [window], a part of the frame stood upright
  /// by turning it [rotation] degrees clockwise: its light and its
  /// sharpness. Null when the window is off the frame.
  static FrameLook? lookOf(CameraImage image, int rotation, Rect window) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    return lookOfPixels(
      plane.bytes,
      stride: plane.bytesPerRow,
      width: image.width,
      height: image.height,
      bgra: image.format.group == ImageFormatGroup.bgra8888,
      rotation: rotation,
      window: window,
    );
  }

  /// The share of [window] in [image] that is a CNIC's green; see
  /// [lookOf].
  static double greenOf(CameraImage image, int rotation, Rect window) {
    if (image.planes.isEmpty) return 0;
    final bgra = image.format.group == ImageFormatGroup.bgra8888;
    // NV21 comes as one plane, its chroma after its luma.
    if (!bgra && image.planes.length != 1) return 0;
    final plane = image.planes.first;
    return greenOfPixels(
      plane.bytes,
      stride: plane.bytesPerRow,
      width: image.width,
      height: image.height,
      layout: bgra ? PixelLayout.bgra : PixelLayout.nv21,
      rotation: rotation,
      window: window,
    );
  }

  /// [lookOf] for the pixels themselves: [bytes] of a frame [width] by
  /// [height], [stride] bytes a row, its luma first (NV21) or its pixels
  /// as BGRA when [bgra].
  @visibleForTesting
  static FrameLook? lookOfPixels(
    Uint8List bytes, {
    required int stride,
    required int width,
    required int height,
    required bool bgra,
    required int rotation,
    required Rect window,
  }) {
    final area = _sensorArea(width, height, rotation, window);
    if (area == null || bytes.length < stride * height) return null;
    int luma(int x, int y) {
      if (!bgra) return bytes[y * stride + x];
      final i = y * stride + x * 4;
      return (bytes[i] * 29 + bytes[i + 1] * 150 + bytes[i + 2] * 77) >> 8;
    }

    // About 120 samples across: enough to judge, quick to count.
    final step = math.max(2, area.width ~/ 120);
    var count = 0;
    var sum = 0;
    var edges = 0.0;
    var edgesSquared = 0.0;
    for (var y = area.top; y <= area.bottom; y += step) {
      for (var x = area.left; x <= area.right; x += step) {
        final here = luma(x, y);
        final edge =
            4 * here -
            luma(x - 1, y) -
            luma(x + 1, y) -
            luma(x, y - 1) -
            luma(x, y + 1);
        sum += here;
        edges += edge;
        edgesSquared += edge * edge;
        count++;
      }
    }
    final meanEdge = edges / count;
    return (
      brightness: sum / count,
      sharpness: edgesSquared / count - meanEdge * meanEdge,
    );
  }

  /// The share of [window] that is a CNIC's green, in [bytes] of a picture
  /// [width] by [height], [stride] bytes a row, laid out as [layout] and
  /// stood upright by turning it [rotation] degrees clockwise.
  static double greenOfPixels(
    Uint8List bytes, {
    required int stride,
    required int width,
    required int height,
    required PixelLayout layout,
    int rotation = 0,
    required Rect window,
  }) {
    final area = _sensorArea(width, height, rotation, window);
    if (area == null) return 0;
    final chroma = stride * height;
    final needed = layout == PixelLayout.nv21
        ? chroma + stride * (height ~/ 2)
        : stride * height;
    if (bytes.length < needed) return 0;
    // About 80 samples across: colour is judged over the whole card.
    final step = math.max(2, area.width ~/ 80);
    var count = 0;
    var green = 0;
    for (var y = area.top; y <= area.bottom; y += step) {
      for (var x = area.left; x <= area.right; x += step) {
        final int r;
        final int g;
        final int b;
        switch (layout) {
          case PixelLayout.nv21:
            final luma = bytes[y * stride + x];
            final i = chroma + (y ~/ 2) * stride + (x & ~1);
            final v = bytes[i] - 128;
            final u = bytes[i + 1] - 128;
            r = (luma + 1.402 * v).round().clamp(0, 255);
            g = (luma - 0.344 * u - 0.714 * v).round().clamp(0, 255);
            b = (luma + 1.772 * u).round().clamp(0, 255);
          case PixelLayout.bgra:
            final i = y * stride + x * 4;
            b = bytes[i];
            g = bytes[i + 1];
            r = bytes[i + 2];
          case PixelLayout.rgba:
            final i = y * stride + x * 4;
            r = bytes[i];
            g = bytes[i + 1];
            b = bytes[i + 2];
        }
        count++;
        if (CnicCheck.isCardGreen(r, g, b)) green++;
      }
    }
    return count == 0 ? 0 : green / count;
  }

  /// Where [window], in a picture stood upright by turning it [rotation]
  /// degrees clockwise, falls in the picture as the sensor sends it,
  /// [width] by [height]; kept a pixel inside its edges. Null when it is
  /// off the picture.
  static ({int left, int top, int right, int bottom, int width})? _sensorArea(
    int width,
    int height,
    int rotation,
    Rect window,
  ) {
    Offset sensor(Offset point) => switch (rotation) {
      90 => Offset(point.dy, height - 1 - point.dx),
      180 => Offset(width - 1 - point.dx, height - 1 - point.dy),
      270 => Offset(width - 1 - point.dy, point.dx),
      _ => point,
    };
    final a = sensor(window.topLeft);
    final b = sensor(window.bottomRight);
    final left = math.max(1, math.min(a.dx, b.dx).floor());
    final right = math.min(width - 2, math.max(a.dx, b.dx).ceil());
    final top = math.max(1, math.min(a.dy, b.dy).floor());
    final bottom = math.min(height - 2, math.max(a.dy, b.dy).ceil());
    if (right - left < 16 || bottom - top < 16) return null;
    return (
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: right - left,
    );
  }

  /// A frame of the stream as ML Kit takes it: one NV21 plane on Android,
  /// BGRA on iOS.
  static InputImage? _inputOf(CameraImage image, int rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final turn = InputImageRotationValue.fromRawValue(rotation);
    if (format == null || turn == null || image.planes.isEmpty) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final buffer = WriteBuffer();
      for (final plane in image.planes) {
        buffer.putUint8List(plane.bytes);
      }
      bytes = buffer.done().buffer.asUint8List();
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: turn,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }
}
