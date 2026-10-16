import 'dart:typed_data';
import 'dart:ui';

import 'package:face_kit/src/engine/face_engine.dart';
import 'package:face_kit/src/engine/face_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

FaceSample _sample({double? miniFas, double? printReplay}) => FaceSample(
  id: 0,
  embedding: const [1, 0],
  miniFasLive: miniFas,
  printReplayLive: printReplay,
  sharpness: 100,
  brightness: 120,
  quality: 0.7,
  elapsedMs: 0,
);

/// Synthetic upright W×H image with a distinct colour at every pixel.
(int, int, int) _pixel(int x, int y) => ((x * 3) % 256, (y * 2) % 256, 128);

void main() {
  group('evaluateLiveness', () {
    test('accepts a confidently live session', () {
      final v = evaluateLiveness([
        _sample(miniFas: 0.95, printReplay: 0.9),
        _sample(miniFas: 0.9, printReplay: 0.85),
      ]);
      expect(v.isLive, isTrue);
    });

    test('rejects a spoof session', () {
      final v = evaluateLiveness([
        _sample(miniFas: 0.02, printReplay: 0.01),
        _sample(miniFas: 0.1, printReplay: 0.05),
      ]);
      expect(v.isLive, isFalse);
    });

    test('one family confidently spoof vetoes the other', () {
      final v = evaluateLiveness([_sample(miniFas: 1.0, printReplay: 0.2)]);
      expect(v.isLive, isFalse);
    });

    test('fails closed when no anti-spoof model produced a score', () {
      expect(evaluateLiveness([_sample()]).isLive, isFalse);
    });
  });

  group('prepareFace sampler', () {
    const w = 120, h = 160;
    const box = Rect.fromLTRB(35, 40, 88, 112);

    // True-view (un-mirrored, upright) landmark positions of the test face.
    const trueView = FaceGeometry(
      box: box,
      leftEye: Offset(50, 62),
      rightEye: Offset(72, 60),
      nose: Offset(61, 76),
      leftMouth: Offset(52, 92),
      rightMouth: Offset(70, 91),
    );

    /// ML Kit reports points in the frame as delivered, so a mirrored frame
    /// comes with x-flipped geometry.
    FaceGeometry asDelivered({required bool mirrored}) {
      if (!mirrored) return trueView;
      Offset f(Offset? p) => Offset((w - 1) - p!.dx, p.dy);
      return FaceGeometry(
        box: Rect.fromLTRB(
          (w - 1) - box.right,
          box.top,
          (w - 1) - box.left,
          box.bottom,
        ),
        leftEye: f(trueView.leftEye),
        rightEye: f(trueView.rightEye),
        nose: f(trueView.nose),
        leftMouth: f(trueView.leftMouth),
        rightMouth: f(trueView.rightMouth),
      );
    }

    /// The test image delivered the way a camera would: stored with the given
    /// clockwise [rotation] still to apply, optionally mirrored (iOS front).
    FaceFrame deliver(int rotation, {bool mirrored = false}) {
      final swapped = rotation == 90 || rotation == 270;
      final rw = swapped ? h : w, rh = swapped ? w : h;
      final bytes = Uint8List(rw * rh * 4);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final ux = mirrored ? (w - 1) - x : x, uy = y;
          final (rx, ry) = switch (rotation) {
            90 => (uy, (rh - 1) - ux),
            180 => ((rw - 1) - ux, (rh - 1) - uy),
            270 => ((rw - 1) - uy, ux),
            _ => (ux, uy),
          };
          final (r, g, b) = _pixel(x, y);
          bytes.setAll((ry * rw + rx) * 4, [b, g, r, 255]);
        }
      }
      return FaceFrame(
        width: rw,
        height: rh,
        rotation: rotation,
        format: FaceFrameFormat.bgra8888,
        planes: [bytes],
        rowStrides: [rw * 4],
        pixelStrides: const [4],
        mirrored: mirrored,
      );
    }

    double maxDiff(Float32List x, Float32List y) {
      double m = 0;
      for (int i = 0; i < x.length; i++) {
        m = (x[i] - y[i]).abs() > m ? (x[i] - y[i]).abs() : m;
      }
      return m;
    }

    final reference = prepareFace(deliver(0), trueView);

    for (final rotation in [0, 90, 180, 270]) {
      for (final mirrored in [false, true]) {
        test('rotation $rotation${mirrored ? ' mirrored' : ''} gives the same '
            'upright true-view face', () {
          final p = prepareFace(
            deliver(rotation, mirrored: mirrored),
            asDelivered(mirrored: mirrored),
          );
          // Bilinear sampling differs by at most a rounding step.
          expect(maxDiff(reference.embedInput, p.embedInput), lessThan(0.02));
          expect(
            maxDiff(reference.miniFasV2Input, p.miniFasV2Input),
            lessThan(2),
          );
          expect(
            maxDiff(reference.printReplayInput, p.printReplayInput),
            lessThan(0.01),
          );
          expect(
            maxDiff(
              reference.embedInput,
              prepareAlignedInput(
                deliver(rotation, mirrored: mirrored),
                asDelivered(mirrored: mirrored),
              ),
            ),
            lessThan(0.02),
          );
        });
      }
    }

    test('a mirrored frame not flagged as mirrored would differ', () {
      // Guards the test itself: the image is asymmetric enough that a missed
      // un-mirror is detected.
      final frame = deliver(0, mirrored: true);
      final unflagged = FaceFrame(
        width: frame.width,
        height: frame.height,
        rotation: frame.rotation,
        format: frame.format,
        planes: frame.planes,
        rowStrides: frame.rowStrides,
        pixelStrides: frame.pixelStrides,
      );
      final p = prepareFace(unflagged, asDelivered(mirrored: true));
      expect(maxDiff(reference.embedInput, p.embedInput), greaterThan(0.2));
    });

    test('tensors have the shapes the models expect', () {
      final p = prepareFace(deliver(0), trueView);
      expect(p.embedInput.length, 3 * 112 * 112);
      expect(p.miniFasV2Input.length, 3 * 80 * 80);
      expect(p.miniFasV1seInput.length, 3 * 80 * 80);
      expect(p.printReplayInput.length, 3 * 128 * 128);
      final jpeg = renderUploadJpeg(deliver(0), trueView);
      expect(jpeg.length, lessThanOrEqualTo(10 * 1024));
    });
  });

  group('faceOcclusion', () {
    const n = kSegmentationInputSize;
    const background = 0, hair = 1, bodySkin = 2, faceSkin = 3, clothes = 4;
    const others = 5;

    // A face filling the middle of the 256×256 crop (crop = frame coords):
    // eyes at y=110, mouth at y=160, eye distance 40 px.
    const crop = Rect.fromLTWH(0, 0, 256, 256);
    const geometry = FaceGeometry(
      box: Rect.fromLTRB(78, 60, 178, 200),
      leftEye: Offset(108, 110),
      rightEye: Offset(148, 110),
      nose: Offset(128, 135),
      leftMouth: Offset(112, 160),
      rightMouth: Offset(144, 160),
    );
    final job = SegmentationJob(Float32List(0), crop, geometry);

    /// Segmentation output: face skin on the face, background elsewhere,
    /// then [paint] applied.
    Float32List mask(void Function(void Function(int x, int y, int l)) paint) {
      final probs = Float32List(n * n * 6);
      void set(int x, int y, int l) {
        final base = (y * n + x) * 6;
        for (int c = 0; c < 6; c++) {
          probs[base + c] = c == l ? 1 : 0;
        }
      }

      for (int y = 0; y < n; y++) {
        for (int x = 0; x < n; x++) {
          final inFace = x >= 70 && x <= 186 && y >= 50 && y <= 210;
          set(x, y, inFace ? faceSkin : background);
        }
      }
      paint(set);
      return probs;
    }

    void rect(
      void Function(int x, int y, int l) set,
      int x0,
      int y0,
      int x1,
      int y1,
      int l,
    ) {
      for (int y = y0; y <= y1; y++) {
        for (int x = x0; x <= x1; x++) {
          set(x, y, l);
        }
      }
    }

    /// A hijab/scarf: fabric framing the face from over the head down both
    /// sides to under the chin.
    void hijab(void Function(int x, int y, int l) set, int label) {
      for (int y = 0; y < n; y++) {
        for (int x = 0; x < n; x++) {
          final inner =
              ((x - 128) / 50) * ((x - 128) / 50) +
              ((y - 125) / 80) * ((y - 125) / 80);
          final outer =
              ((x - 128) / 70) * ((x - 128) / 70) +
              ((y - 125) / 100) * ((y - 125) / 100);
          if (inner > 1 && outer <= 1) set(x, y, label);
        }
      }
    }

    FaceOcclusion check(Float32List probs) => faceOcclusion(probs, job);
    bool blocked(FaceOcclusion o) =>
        o.onFace > kMaxFaceOcclusion || o.nearFace > kMaxNearFaceObject;

    test('a clear face passes', () {
      expect(blocked(check(mask((_) {}))), isFalse);
    });

    test('a hand on the chin and lip is on the face', () {
      final o = check(mask((set) => rect(set, 130, 150, 175, 200, bodySkin)));
      expect(o.onFace, greaterThan(kMaxFaceOcclusion));
    });

    test('a hand on the cheek is on the face', () {
      final o = check(mask((set) => rect(set, 150, 120, 172, 150, bodySkin)));
      expect(o.onFace, greaterThan(kMaxFaceOcclusion));
    });

    test('a hand on the forehead is on the face', () {
      final o = check(mask((set) => rect(set, 110, 70, 145, 90, bodySkin)));
      expect(o.onFace, greaterThan(kMaxFaceOcclusion));
    });

    test('an object over the mouth is on the face', () {
      final o = check(mask((set) => rect(set, 105, 150, 150, 175, others)));
      expect(o.onFace, greaterThan(kMaxFaceOcclusion));
    });

    test('a toy held against the cheek is beside the face', () {
      final o = check(mask((set) => rect(set, 162, 128, 190, 158, others)));
      expect(o.nearFace, greaterThan(kMaxNearFaceObject));
    });

    test('a hand held beside the cheek is beside the face', () {
      final o = check(mask((set) => rect(set, 162, 125, 190, 150, bodySkin)));
      expect(o.nearFace, greaterThan(kMaxNearFaceObject));
    });

    test('a toy on one side reaching above the brows is still caught', () {
      final o = check(mask((set) => rect(set, 165, 60, 200, 150, others)));
      expect(blocked(o), isTrue);
    });

    test('scattered label noise does not count', () {
      final probs = mask((set) {
        for (int i = 0; i < 40; i++) {
          set(90 + (i * 37) % 70, 100 + (i * 53) % 80, bodySkin);
        }
      });
      expect(blocked(check(probs)), isFalse);
    });

    test('a beard or fringe (hair) does not count', () {
      final probs = mask((set) {
        rect(set, 105, 165, 150, 195, hair);
        rect(set, 100, 70, 155, 92, hair);
      });
      expect(blocked(check(probs)), isFalse);
    });

    test('glasses (accessory in the eye band) do not count', () {
      final probs = mask((set) => rect(set, 88, 104, 168, 116, others));
      expect(blocked(check(probs)), isFalse);
    });

    test('thick or dark frames labelled clothing do not count', () {
      final probs = mask((set) => rect(set, 88, 98, 168, 128, clothes));
      expect(blocked(check(probs)), isFalse);
    });

    test('a cloth over the nose and mouth is still on the face', () {
      final o = check(mask((set) => rect(set, 100, 135, 156, 175, clothes)));
      expect(o.onFace, greaterThan(kMaxFaceOcclusion));
    });

    test('the neck below the chin does not count', () {
      final probs = mask((set) => rect(set, 100, 186, 156, 215, bodySkin));
      expect(blocked(check(probs)), isFalse);
    });

    test('a hijab or scarf framing the face does not count', () {
      expect(blocked(check(mask((set) => hijab(set, others)))), isFalse);
      expect(blocked(check(mask((set) => hijab(set, clothes)))), isFalse);
    });
  });
}
