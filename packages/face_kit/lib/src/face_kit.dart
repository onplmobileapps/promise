import 'package:camera/camera.dart' show CameraDescription;
import 'package:flutter/foundation.dart';

import 'engine/face_engine.dart';
import 'ui/face_capture_scene.dart';

/// Whether a capture enrols a new face or checks a face against an
/// existing enrolment.
enum CaptureMode { registration, verification }

/// Receives errors that face_kit handles internally (model load failures,
/// optional models missing, …) — e.g. forward them to Crashlytics.
typedef FaceKitErrorReporter =
    void Function(Object error, StackTrace stack, String reason);

/// App-specific settings. Everything has a sensible default, so
/// [FaceKit.configure] is optional.
@immutable
class FaceKitConfig {
  /// Where to report internal errors. Defaults to `debugPrint` only.
  final FaceKitErrorReporter? onError;

  /// Shows the captured images (and their scores) in a dialog with
  /// Continue/Cancel before the result is returned. Debug builds only by
  /// default.
  final bool showPreviewDialog;

  /// Size limit of each uploaded JPEG. The highest quality that fits is used.
  final int maxUploadBytes;

  /// Images returned by a registration capture.
  final int registrationImages;

  /// Images returned by a verification capture.
  final int verificationImages;

  /// Cameras the app already enumerated (e.g. in `main`). When null,
  /// face_kit calls `availableCameras()` itself on first use.
  final List<CameraDescription>? cameras;

  /// The app's own capture screen, built around face_kit's camera and
  /// status. When null, face_kit's plain screen is used.
  final FaceCaptureLayout? layout;

  const FaceKitConfig({
    this.onError,
    this.showPreviewDialog = kDebugMode,
    this.maxUploadBytes = 10 * 1024,
    this.registrationImages = 5,
    this.verificationImages = 2,
    this.cameras,
    this.layout,
  });
}

/// Entry point for app-wide face_kit setup.
class FaceKit {
  FaceKit._();

  static FaceKitConfig _config = const FaceKitConfig();

  static FaceKitConfig get config => _config;

  /// Applies app-specific settings. Call once, e.g. in `main`.
  static void configure(FaceKitConfig config) {
    _config = config;
    _registerLicenses();
  }

  /// Loads and warms up the models in the background so the camera screen
  /// opens instantly. Call from a screen that leads to face capture.
  static void preload() {
    _registerLicenses();
    FaceEngine.instance.preload();
  }

  static bool _licensesRegistered = false;

  /// Adds the bundled models' licences to Flutter's licence page
  /// (`showLicensePage`), which CC-BY-4.0 attribution requires.
  static void _registerLicenses() {
    if (_licensesRegistered) return;
    _licensesRegistered = true;
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(
        ['face_kit: eDifFIQA face quality model'],
        'eDifFIQA(T) by Ž. Babnik, P. Peer, V. Štruc — "eDifFIQA: Towards '
        'Efficient Face Image Quality Assessment based on Denoising Diffusion '
        'Probabilistic Models", IEEE TBIOM 2024. Model from OpenCV Zoo, '
        'licensed under CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/).',
      );
      yield const LicenseEntryWithLineBreaks(
        ['face_kit: MediaPipe selfie segmentation, MiniFASNet'],
        'MediaPipe selfie multiclass segmentation (Google) and MiniFASNet '
        'anti-spoofing models (Minivision / yakhyo) are licensed under the '
        'Apache License, Version 2.0.',
      );
    });
  }

  /// Frees the models' memory; they reload automatically on next use.
  static Future<void> release() => FaceEngine.instance.shutdown();

  static void reportError(Object error, StackTrace stack, String reason) {
    debugPrint('❌ face_kit: $reason: $error');
    final onError = _config.onError;
    if (onError == null) return;
    try {
      onError(error, stack, reason);
    } catch (_) {
      // A failing reporter must never break face capture.
    }
  }
}
