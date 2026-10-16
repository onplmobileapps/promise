import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../engine/face_engine.dart';
import '../engine/face_pipeline.dart';
import '../face_kit.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FaceCaptureSession
//
//  The camera screen only *collects* frames — it closes the moment it has
//  enough. Everything slow (recognition, passive liveness, JPEG encoding)
//  happens here, in the FaceEngine worker, while the caller shows its own
//  "Verifying…" state. The user never waits on the camera screen.
// ─────────────────────────────────────────────────────────────────────────────

/// When choosing which frames to send, frames within this many degrees of
/// the most frontal one count as equally frontal and the sharpest win.
const double _kPoseTieDegrees = 6;

/// Registration images must all be the same person.
const double _kMinSelfSimilarity = 0.45;

/// Returned when registration completes.
class FaceRegistrationResult {
  final List<XFile> images;
  final List<List<double>> embeddings;

  /// Session liveness score (0..1), for diagnostics.
  final double? livenessScore;

  /// Average face-image quality of the sent images (0..1), for diagnostics.
  final double? faceQuality;

  /// Average sharpness of the sent images (see [FacePrep.sharpness]).
  final double? sharpness;

  const FaceRegistrationResult({
    required this.images,
    required this.embeddings,
    this.livenessScore,
    this.faceQuality,
    this.sharpness,
  });
}

/// Returned when verification completes.
class FaceVerificationResult {
  final List<XFile> images;
  final List<List<double>> embeddings;

  /// Session liveness score (0..1), for diagnostics.
  final double? livenessScore;

  /// Average face-image quality of the sent images (0..1), for diagnostics.
  final double? faceQuality;

  /// Average sharpness of the sent images (see [FacePrep.sharpness]).
  final double? sharpness;

  const FaceVerificationResult({
    required this.images,
    required this.embeddings,
    this.livenessScore,
    this.faceQuality,
    this.sharpness,
  });
}

/// Returned when the captured frames were not a usable live face.
class FaceCaptureFailedResult {
  final String message;

  /// True when liveness rejected the face (photo / screen / video).
  final bool spoof;

  /// Frames that were captured, for diagnostics. Only populated when
  /// [FaceKitConfig.showPreviewDialog] is on; never sent to the server.
  final List<XFile> images;
  final double? livenessScore;
  final double? faceQuality;
  final double? sharpness;

  const FaceCaptureFailedResult(
    this.message, {
    this.spoof = false,
    this.images = const [],
    this.livenessScore,
    this.faceQuality,
    this.sharpness,
  });
}

class FaceCaptureSession {
  final CaptureMode mode;
  final FaceEngine _engine;
  final List<(FaceFrame, FaceGeometry, double?)> _frames = [];

  FaceCaptureSession(this.mode, {FaceEngine? engine})
    : _engine = engine ?? FaceEngine.instance;

  bool get isRegistration => mode == CaptureMode.registration;

  /// Frames to collect before the camera closes. A few extra over what is
  /// uploaded so blurry / badly-lit frames can be dropped without a retake.
  int get targetFrames => isRegistration
      ? FaceKit.config.registrationImages + 3
      : math.max(
              FaceKit.config.verificationImages,
              _engine.config.verificationFrames,
            ) +
            1;

  int get frameCount => _frames.length;
  bool get isComplete => _frames.length >= targetFrames;

  /// Adds a frame that passed the live gates. [quality] is the face-image
  /// quality measured by that gate, reused so it isn't computed again.
  ///
  /// Nothing heavy runs here: while the camera is open the worker only does
  /// the quick quality gate, so capture never waits behind analysis.
  void add(FaceFrame frame, FaceGeometry geometry, {double? quality}) {
    if (isComplete) return;
    _frames.add((frame, geometry, quality));
  }

  void clear() => _frames.clear();

  /// Runs the background decision once the camera has closed. Returns a
  /// [FaceRegistrationResult], [FaceVerificationResult] or
  /// [FaceCaptureFailedResult].
  Future<Object> finish() async {
    final sw = Stopwatch()..start();
    final samples = (await Future.wait([
      for (final (frame, geometry, quality) in _frames)
        _engine
            .analyze(frame, geometry, quality: quality)
            .then<FaceSample?>(
              (s) => s,
              onError: (Object e) {
                debugPrint('⚠️ Face analysis failed: $e');
                return null;
              },
            ),
    ])).whereType<FaceSample>().toList();

    final usable = samples
        .where(
          (s) =>
              s.isClearFace &&
              s.sharpness >= kMinFaceSharpness &&
              s.brightness >= kMinFaceBrightness &&
              s.brightness <= kMaxFaceBrightness,
        )
        .toList();
    if (usable.isEmpty) {
      return _failed(
        'Face not clear, blurry or covered. Hold the phone steady, uncover '
        'your face and try again in good light.',
        samples,
      );
    }

    final verdict = evaluateLiveness(usable);
    debugPrint(
      '🛡️ $verdict — ${usable.length}/${samples.length} usable frames, '
      '${sw.elapsedMilliseconds} ms after capture',
    );
    if (!verdict.isLive) {
      return _failed(
        'Live face not detected. Use your real face — photos, screens and '
        'videos are not accepted.',
        samples,
        spoof: true,
        livenessScore: verdict.score,
      );
    }

    final required = isRegistration
        ? FaceKit.config.registrationImages
        : FaceKit.config.verificationImages;
    if (usable.length < required) {
      return _failed(
        'Could not capture a clear face. Please try again.',
        samples,
        livenessScore: verdict.score,
      );
    }
    final chosen = _pickForUpload(usable, required);
    if (isRegistration && !_isSamePerson(chosen)) {
      return _failed(
        'Only one person should be in front of the camera.',
        samples,
        livenessScore: verdict.score,
      );
    }

    final images = await _writeImages(chosen);
    // Exactly as many as asked for, never fewer: 5 to register, 2 to verify
    // by default.
    if (images.length != required || chosen.length != required) {
      return _failed(
        'Could not capture a clear face. Please try again.',
        samples,
        livenessScore: verdict.score,
      );
    }
    final embeddings = [for (final s in chosen) s.embedding];
    final faceQuality = _meanQuality(chosen);
    final sharpness = _meanSharpness(chosen);
    return isRegistration
        ? FaceRegistrationResult(
            images: images,
            embeddings: embeddings,
            livenessScore: verdict.score,
            faceQuality: faceQuality,
            sharpness: sharpness,
          )
        : FaceVerificationResult(
            images: images,
            embeddings: embeddings,
            livenessScore: verdict.score,
            faceQuality: faceQuality,
            sharpness: sharpness,
          );
  }

  /// Failure result; attaches the captured frames only for the debug preview
  /// so production never pays for encoding images it won't use.
  Future<FaceCaptureFailedResult> _failed(
    String message,
    List<FaceSample> samples, {
    bool spoof = false,
    double? livenessScore,
  }) async {
    var images = const <XFile>[];
    if (FaceKit.config.showPreviewDialog && samples.isNotEmpty) {
      try {
        images = await _writeImages(samples);
      } catch (e) {
        debugPrint('⚠️ Could not render preview images: $e');
      }
    }
    return FaceCaptureFailedResult(
      message,
      spoof: spoof,
      images: images,
      livenessScore: livenessScore,
      faceQuality: _meanQuality(samples),
      sharpness: _meanSharpness(samples),
    );
  }

  static double? _meanSharpness(List<FaceSample> samples) => samples.isEmpty
      ? null
      : samples.map((s) => s.sharpness).reduce((a, b) => a + b) /
            samples.length;

  static double? _meanQuality(List<FaceSample> samples) {
    final q = samples.map((s) => s.quality).whereType<double>().toList();
    return q.isEmpty ? null : q.reduce((a, b) => a + b) / q.length;
  }

  /// The server compares these images with the registered ones, so send the
  /// sharpest of the most frontal frames: frames within [_kPoseTieDegrees] of
  /// the most frontal count as frontal and are ranked by sharpness, the rest
  /// only fill in if needed.
  static List<FaceSample> _pickForUpload(List<FaceSample> usable, int count) {
    final mostFrontal = usable
        .map((s) => s.poseDeviation)
        .reduce((a, b) => a < b ? a : b);
    bool frontal(FaceSample s) =>
        s.poseDeviation <= mostFrontal + _kPoseTieDegrees;
    final ranked = [
      ...usable.where(frontal).toList()
        ..sort((a, b) => b.sharpness.compareTo(a.sharpness)),
      ...usable.where((s) => !frontal(s)).toList()
        ..sort((a, b) => a.poseDeviation.compareTo(b.poseDeviation)),
    ];
    return ranked.take(count).toList();
  }

  bool _isSamePerson(List<FaceSample> samples) {
    for (int i = 0; i < samples.length; i++) {
      for (int j = i + 1; j < samples.length; j++) {
        if (cosineSimilarity(samples[i].embedding, samples[j].embedding) <
            _kMinSelfSimilarity) {
          return false;
        }
      }
    }
    return true;
  }

  Future<List<XFile>> _writeImages(List<FaceSample> samples) async {
    final jpegs = await _engine.uploadImages([for (final s in samples) s.id]);
    final dir = (await getTemporaryDirectory()).path;
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return Future.wait([
      for (int i = 0; i < jpegs.length; i++)
        () async {
          final path = '$dir/face_${stamp}_$i.jpg';
          await File(path).writeAsBytes(jpegs[i]);
          return XFile(path);
        }(),
    ]);
  }
}
