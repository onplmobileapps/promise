// End-to-end check of FaceEngine with the real ONNX runtime and models.
//
// Needs the host ONNX Runtime library and prepared frames, so it only runs
// when FACE_E2E_FRAMES points at a directory containing, per sample:
//   <name>_nv21.raw (rotation 270), <name>_bgra.raw (rotation 0)
// plus meta.json with each sample's size, face box and 5 landmarks.
//   image_T*  real face         image_F*  printed photo / screen replay
//   occ_*     real face with a hand over the eyes or mouth
import 'dart:convert';
import 'dart:io';

import 'package:face_kit/src/capture/face_capture_session.dart';
import 'package:face_kit/src/engine/face_engine.dart';
import 'package:face_kit/src/engine/face_pipeline.dart';
import 'package:face_kit/src/face_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Platform.environment['FACE_E2E_FRAMES'];

  testWidgets('real models: liveness, occlusion gate and capture sessions', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await tester.runAsync(() async {
      final engine = FaceEngine.instance;
      await engine.warmUp();

      final meta = {
        for (final m
            in jsonDecode(File('$dir/meta.json').readAsStringSync()) as List)
          m['name'] as String: m as Map<String, dynamic>,
      };

      FaceGeometry geometryOf(String name) {
        final m = meta[name]!;
        final b = [for (final v in m['box'] as List) (v as num).toDouble()];
        final l = [for (final v in m['lm'] as List) (v as num).toDouble()];
        return FaceGeometry(
          box: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
          leftEye: Offset(l[0], l[1]),
          rightEye: Offset(l[2], l[3]),
          nose: Offset(l[4], l[5]),
          leftMouth: Offset(l[6], l[7]),
          rightMouth: Offset(l[8], l[9]),
        );
      }

      FaceFrame nv21(String name) {
        final m = meta[name]!;
        return FaceFrame(
          width: m['rw'],
          height: m['rh'],
          rotation: 270,
          format: FaceFrameFormat.nv21,
          planes: [File('$dir/${name}_nv21.raw').readAsBytesSync()],
          rowStrides: [m['rw']],
          pixelStrides: const [1],
        );
      }

      FaceFrame bgra(String name) {
        final m = meta[name]!;
        return FaceFrame(
          width: m['W'],
          height: m['H'],
          rotation: 0,
          format: FaceFrameFormat.bgra8888,
          planes: [File('$dir/${name}_bgra.raw').readAsBytesSync()],
          rowStrides: [m['W'] * 4],
          pixelStrides: const [4],
        );
      }

      // Liveness: photo and replay are spoof, the real face is live — on
      // both the Android (NV21, rotated) and iOS (BGRA) paths.
      final embeddings = <String, List<double>>{};
      for (final name in ['image_F1', 'image_F2', 'image_T1']) {
        for (final (path, frame) in [
          ('nv21', nv21(name)),
          ('bgra', bgra(name)),
        ]) {
          final sample = await engine.analyze(frame, geometryOf(name));
          final verdict = evaluateLiveness([sample]);
          // ignore: avoid_print
          print(
            '$name $path: $verdict quality=${sample.quality} '
            '${sample.elapsedMs} ms',
          );
          expect(verdict.isLive, name == 'image_T1', reason: '$name $path');
          embeddings['${name}_$path'] = sample.embedding;
        }
        expect(
          cosineSimilarity(
            embeddings['${name}_nv21']!,
            embeddings['${name}_bgra']!,
          ),
          greaterThan(0.95),
          reason: name,
        );
      }

      // iOS delivers front-camera frames mirrored. The same face must give
      // the same recognition result and upload image as on Android.
      FaceFrame iosMirrored(String name) {
        final m = meta[name]!;
        final w = m['W'] as int, h = m['H'] as int;
        final src = File('$dir/${name}_bgra.raw').readAsBytesSync();
        final out = Uint8List(src.length);
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final s = (y * w + x) * 4, d = (y * w + (w - 1 - x)) * 4;
            out.setRange(d, d + 4, src, s);
          }
        }
        return FaceFrame(
          width: w,
          height: h,
          rotation: 0,
          format: FaceFrameFormat.bgra8888,
          planes: [out],
          rowStrides: [w * 4],
          pixelStrides: const [4],
          mirrored: true,
        );
      }

      FaceGeometry mirroredGeometry(String name) {
        final g = geometryOf(name);
        final maxX = (meta[name]!['W'] as int) - 1.0;
        Offset f(Offset? p) => Offset(maxX - p!.dx, p.dy);
        return FaceGeometry(
          box: Rect.fromLTRB(
            maxX - g.box.right,
            g.box.top,
            maxX - g.box.left,
            g.box.bottom,
          ),
          leftEye: f(g.leftEye),
          rightEye: f(g.rightEye),
          nose: f(g.nose),
          leftMouth: f(g.leftMouth),
          rightMouth: f(g.rightMouth),
        );
      }

      final android = await engine.analyze(
        nv21('image_T1'),
        geometryOf('image_T1'),
      );
      final ios = await engine.analyze(
        iosMirrored('image_T1'),
        mirroredGeometry('image_T1'),
      );
      final crossPlatform = cosineSimilarity(android.embedding, ios.embedding);
      // ignore: avoid_print
      print('image_T1 android-vs-ios(mirrored) similarity=$crossPlatform');
      expect(crossPlatform, greaterThan(0.95));
      final uploads = await engine.uploadImages([android.id, ios.id]);
      final previewDir = Platform.environment['FACE_E2E_OUT'];
      if (previewDir != null) {
        File('$previewDir/upload_android.jpg').writeAsBytesSync(uploads[0]);
        File('$previewDir/upload_ios.jpg').writeAsBytesSync(uploads[1]);
      }

      // Occlusion gate: a clear face passes, hands over the eyes or mouth
      // are rejected.
      Future<double?> quality(String name) async =>
          (await engine.faceGate(nv21(name), geometryOf(name))).quality;

      final clear = await quality('image_T1');
      // ignore: avoid_print
      print('image_T1 quality=$clear');
      expect(clear, greaterThanOrEqualTo(kMinFaceQuality));

      // Blur gate: the sharp face passes, focus and motion blur are rejected.
      final sharpGate = await engine.faceGate(
        nv21('image_T1'),
        geometryOf('image_T1'),
      );
      // ignore: avoid_print
      print(
        'image_T1 sharpness=${sharpGate.sharpness.toStringAsFixed(1)} '
        'brightness=${sharpGate.brightness.toStringAsFixed(0)}',
      );
      expect(sharpGate.sharpness, greaterThanOrEqualTo(kMinFaceSharpness));
      expect(
        sharpGate.brightness,
        inInclusiveRange(kMinFaceBrightness, kMaxFaceBrightness),
      );
      for (final name in ['blur_gauss_T1', 'blur_motion_T1']) {
        final gate = await engine.faceGate(nv21(name), geometryOf(name));
        // ignore: avoid_print
        print('$name sharpness=${gate.sharpness.toStringAsFixed(1)}');
        expect(gate.sharpness, lessThan(kMinFaceSharpness), reason: name);
      }
      for (final name in [
        'occ_fist_eyes',
        'occ_victory_eyes',
        'occ_fist_mouth',
        'occ_victory_mouth',
        'occ_pointing_mouth',
      ]) {
        final q = await quality(name);
        // ignore: avoid_print
        print('$name quality=$q');
        expect(q, lessThan(kMinFaceQuality), reason: name);
      }

      // Occlusion (segmentation): a clear face passes; a hand anywhere on it —
      // half on the lips and chin, on the chin, on the cheek — is found.
      final clearOcclusion = await engine.faceOcclusion(
        nv21('image_T1'),
        geometryOf('image_T1'),
      );
      // ignore: avoid_print
      print('image_T1 occlusion=$clearOcclusion');
      final timer = Stopwatch()..start();
      for (int i = 0; i < 5; i++) {
        await engine.faceOcclusion(nv21('image_T1'), geometryOf('image_T1'));
      }
      // ignore: avoid_print
      print('occlusion check: ${timer.elapsedMilliseconds / 5} ms per frame');
      timer
        ..reset()
        ..start();
      for (int i = 0; i < 5; i++) {
        await engine.faceGate(nv21('image_T1'), geometryOf('image_T1'));
      }
      // ignore: avoid_print
      print('live gate: ${timer.elapsedMilliseconds / 5} ms per frame');
      expect(clearOcclusion!.onFace, lessThanOrEqualTo(kMaxFaceOcclusion));
      expect(clearOcclusion.nearFace, lessThanOrEqualTo(kMaxNearFaceObject));
      for (final name in [
        'hand_fist_halfLipChin',
        'hand_victory_halfLipChin',
        'hand_thumb_chin',
        'hand_fist_cheek',
        'hand_victory_chin',
      ]) {
        final covered = await engine.faceOcclusion(
          nv21(name),
          geometryOf(name),
        );
        // ignore: avoid_print
        print('$name occlusion=$covered');
        expect(covered!.onFace, greaterThan(kMaxFaceOcclusion), reason: name);
      }

      // Other clear faces (both camera formats) stay well under the limits.
      for (final name in ['image_F1', 'image_F2', 'image_T1']) {
        for (final frame in [nv21(name), bgra(name)]) {
          final o = await engine.faceOcclusion(frame, geometryOf(name));
          // ignore: avoid_print
          print('clear $name ${frame.format.name} $o');
          expect(o!.onFace, lessThanOrEqualTo(kMaxFaceOcclusion), reason: name);
          expect(
            o.nearFace,
            lessThanOrEqualTo(kMaxNearFaceObject),
            reason: name,
          );
        }
      }

      // A stuffed toy or pet held against or right next to the face.
      for (final name in [
        'obj_teddy_touch',
        'obj_teddy_cheek',
        'obj_dog_beside',
      ]) {
        final o = await engine.faceOcclusion(nv21(name), geometryOf(name));
        // ignore: avoid_print
        print('$name $o');
        expect(
          o!.onFace > kMaxFaceOcclusion || o.nearFace > kMaxNearFaceObject,
          isTrue,
          reason: name,
        );
      }

      // Full background flow, as run after the camera screen closes.
      Future<Object> run(CaptureMode mode, String name) {
        final session = FaceCaptureSession(mode, engine: engine);
        while (!session.isComplete) {
          session.add(nv21(name), geometryOf(name));
        }
        return session.finish();
      }

      final verified = await run(CaptureMode.verification, 'image_T1');
      expect(verified, isA<FaceVerificationResult>());
      expect(
        (verified as FaceVerificationResult).images,
        hasLength(FaceKit.config.verificationImages),
      );

      final registered = await run(CaptureMode.registration, 'image_T1');
      expect(registered, isA<FaceRegistrationResult>());
      expect(
        (registered as FaceRegistrationResult).images,
        hasLength(FaceKit.config.registrationImages),
      );

      for (final spoof in ['image_F1', 'image_F2']) {
        final result = await run(CaptureMode.verification, spoof);
        expect(result, isA<FaceCaptureFailedResult>(), reason: spoof);
        expect((result as FaceCaptureFailedResult).spoof, isTrue);
        // Debug preview gets the captured frames; they are never uploaded.
        expect(result.images, isNotEmpty);
      }

      // A covered face never produces images to upload.
      final covered = await run(CaptureMode.verification, 'occ_fist_mouth');
      expect(covered, isA<FaceCaptureFailedResult>());

      await engine.shutdown();
    });
  }, skip: dir == null);
}
