import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../capture/camera_health.dart';
import '../capture/face_capture_session.dart';
import '../capture/phone_attitude.dart';
import '../engine/face_engine.dart';
import '../engine/face_pipeline.dart';
import '../face_kit.dart';
import 'captured_faces_dialog.dart';
import 'face_capture_scene.dart';
import 'face_overlay.dart';

export '../capture/face_capture_session.dart'
    show
        FaceCaptureFailedResult,
        FaceRegistrationResult,
        FaceVerificationResult;
export '../engine/face_pipeline.dart' show buildFaceCropRectForFrame;

// Face must fill enough of the 720p frame to give the 224 px upload image
// real detail (no upscaling); the oval guides users to this naturally.
const double _kMinFaceRatio = 0.28;
const double _kMaxFaceRatio = 0.90;
// Motion blur guards. Phone rotation above this (rad/s, gyroscope) within
// the last [_kShakeWindow], or the face moving faster than this many face
// widths per second, smears the image — such frames are skipped.
const double _kMaxPhoneRotation = 0.35;
const Duration _kShakeWindow = Duration(milliseconds: 150);
const double _kMaxFaceSpeed = 0.6;
// Head must face the camera: the server's similarity check compares these
// images with the registered ones, and turned or tilted faces score lower.
const double _kMaxYaw = 12;
const double _kMaxPitch = 12;
const double _kMaxRoll = 12;
// The phone must be held upright, at eye level. Held low and turned up at
// the face, the camera sees it from below the chin, foreshortened and with
// the ceiling lights behind it, and the liveness check takes it for a spoof.
// Degrees the phone may lean back (screen up) or forward (screen down).
const double _kMaxBackTilt = 30;
const double _kMaxForwardTilt = 25;
// A face seen from below looks up at the camera (positive ML Kit pitch);
// that side is held tighter than looking down.
const double _kMaxChinUp = 8;
// After a hand or object is found on the face, keep telling the user for
// this long so the message doesn't flicker while they move their hand away.
const Duration _kCoveredHintHold = Duration(milliseconds: 1200);
// Eyes count as closed only when both are below this (ML Kit
// classification). Closed eyes score ~0.0–0.1; open eyes behind glasses
// often score 0.2–0.5 per eye because of lens glare, so a stricter or
// per-eye check rejects people wearing glasses.
const double _kMinEyeOpen = 0.2;
// Brief detector dropouts shorter than this don't restart the capture.
const Duration _kFaceLostTolerance = Duration(milliseconds: 400);

/// Entry point for face capture.
///
/// Opens the camera, which closes by itself a fraction of a second after a
/// face is in view. Recognition and liveness then run in the background while
/// the caller shows its loading state. Returns a [FaceRegistrationResult],
/// [FaceVerificationResult], [FaceCaptureFailedResult], or null if the user
/// backed out.
///
/// When [FaceKitConfig.showPreviewDialog] is on, the captured images are shown in a
/// dialog before the result is returned (i.e. before anything is uploaded);
/// tapping Cancel there returns null, so no verify/register request is made.
class FaceCapture {
  FaceCapture._();

  /// [layout] builds this capture's screen; [FaceKitConfig.layout] by
  /// default.
  static Future<Object?> open(
    BuildContext context, {
    required CaptureMode mode,
    bool rootNavigator = true,
    FaceCaptureLayout? layout,
  }) async {
    final session = await Navigator.of(context, rootNavigator: rootNavigator)
        .push<FaceCaptureSession>(
          MaterialPageRoute(
            builder: (_) => FaceCaptureView(
              mode: mode,
              layout: layout ?? FaceKit.config.layout,
            ),
          ),
        );
    if (session == null) return null;
    final result = await session.finish();
    if (FaceKit.config.showPreviewDialog && context.mounted) {
      final proceed = await showCapturedFacesDialog(context, result);
      // Cancel → behave exactly like backing out: nothing is sent.
      if (!proceed && result is! FaceCaptureFailedResult) return null;
    }
    return result;
  }
}

enum _Hint {
  none,
  noFace,
  multipleFaces,
  tooFar,
  tooClose,
  lookAtCamera,
  eyeLevel,
  eyesClosed,
  faceCovered,
  holdSteady,
  lowLight,
  tooBright,
  objectNearFace,
}

extension on _Hint {
  /// The hint as the app's layout is told it.
  FaceCaptureHint get public => switch (this) {
    _Hint.none => FaceCaptureHint.lookAtCamera,
    _Hint.lookAtCamera => FaceCaptureHint.lookStraight,
    _Hint.eyeLevel => FaceCaptureHint.eyeLevel,
    _Hint.noFace => FaceCaptureHint.noFace,
    _Hint.multipleFaces => FaceCaptureHint.multipleFaces,
    _Hint.eyesClosed => FaceCaptureHint.eyesClosed,
    _Hint.faceCovered => FaceCaptureHint.faceCovered,
    _Hint.tooFar => FaceCaptureHint.tooFar,
    _Hint.tooClose => FaceCaptureHint.tooClose,
    _Hint.holdSteady => FaceCaptureHint.holdSteady,
    _Hint.lowLight => FaceCaptureHint.lowLight,
    _Hint.tooBright => FaceCaptureHint.tooBright,
    _Hint.objectNearFace => FaceCaptureHint.objectNearFace,
  };

  String get message {
    switch (this) {
      case _Hint.none:
        return 'Look at the camera';
      case _Hint.lookAtCamera:
        return 'Look straight at the camera';
      case _Hint.eyeLevel:
        return 'Hold the phone at eye level, in front of your face';
      case _Hint.noFace:
        return 'Position your face in the frame';
      case _Hint.multipleFaces:
        return 'Only one person should be in the frame';
      case _Hint.eyesClosed:
        return 'Open your eyes and look at the camera';
      case _Hint.faceCovered:
        return 'Uncover your face — remove hands or objects';
      case _Hint.tooFar:
        return 'Move closer';
      case _Hint.tooClose:
        return 'Move back a little';
      case _Hint.holdSteady:
        return 'Hold the phone steady';
      case _Hint.lowLight:
        return 'Move to better light';
      case _Hint.tooBright:
        return 'Too much light on your face';
      case _Hint.objectNearFace:
        return 'Keep objects away from your face';
    }
  }

  /// How long a problem must persist before its hint is shown. Blocking
  /// problems (covered face, closed eyes, extra person) are shown quickly;
  /// positioning hints wait longer so brief movement never nags the user.
  Duration get delay => switch (this) {
    _Hint.multipleFaces ||
    _Hint.lookAtCamera ||
    _Hint.eyeLevel ||
    _Hint.eyesClosed ||
    _Hint.faceCovered => const Duration(milliseconds: 250),
    _ => const Duration(milliseconds: 700),
  };
}

/// Everything the overlay shows. Pushed through a ValueNotifier so status
/// changes never rebuild the camera preview.
@immutable
class _Status {
  final String text;
  final bool positive;
  final double progress;

  const _Status(this.text, {this.positive = false, this.progress = 0});

  @override
  bool operator ==(Object other) =>
      other is _Status &&
      other.text == text &&
      other.positive == positive &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(text, positive, progress);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FaceCaptureView
//
//  Face-ID style capture: no challenges, no "hold still". As soon as a usable
//  face is in view, consecutive frames are collected and the screen pops with
//  a [FaceCaptureSession]. Use [FaceCapture.open] rather than pushing this
//  directly.
// ─────────────────────────────────────────────────────────────────────────────
class FaceCaptureView extends StatefulWidget {
  final CaptureMode? mode;

  /// The app's screen around the camera; face_kit's own when null.
  final FaceCaptureLayout? layout;

  const FaceCaptureView({super.key, this.mode, this.layout});

  @override
  State<FaceCaptureView> createState() => _FaceCaptureViewState();
}

class _FaceCaptureViewState extends State<FaceCaptureView> {
  final FaceEngine _engine = FaceEngine.instance;
  late final FaceCaptureSession _session = FaceCaptureSession(
    widget.mode ?? CaptureMode.verification,
    engine: _engine,
  );
  CameraController? _controller;

  bool _detecting = false;
  bool _checkingQuality = false;

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  DateTime? _lastShakeAt;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  final GravityFilter _gravity = GravityFilter();
  Offset? _lastFaceCenter;
  DateTime? _lastFaceCenterAt;

  // Occlusion (hand/object on the face) is checked by segmentation on the
  // first accepted frame of each capture, in parallel with collecting the
  // rest; the capture only completes once it has passed.
  int _captureGeneration = 0;
  bool _occlusionChecking = false;
  bool _occlusionPassed = false;
  DateTime? _coveredUntil;
  _Hint _coveredHint = _Hint.faceCovered;
  Timer? _coveredTimer;
  bool _done = false;
  DateTime _lastDetectAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastFaceAt;
  int? _trackingId;

  _Hint _pendingHint = _Hint.none;
  DateTime? _pendingHintSince;
  _Hint _hint = _Hint.none;

  /// Fatal error (no camera) shown instead of the preview.
  String? _errorMessage;

  /// What is wrong with the camera, once something is; the app tells the
  /// person, so the phone's camera isn't mistaken for the app.
  CameraFault? _fault;
  late final CameraWatchdog _watchdog = CameraWatchdog(onFault: _fail);

  final ValueNotifier<_Status> _status = ValueNotifier(
    _Status(_Hint.none.message),
  );

  /// The same status, for the app's layout.
  final ValueNotifier<FaceCaptureStatus> _scene = ValueNotifier(
    const FaceCaptureStatus(hint: FaceCaptureHint.lookAtCamera),
  );

  bool get _isRegistration => _session.isRegistration;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    // Full screen brightness lights the face from the front: less noise,
    // shorter exposure (less motion blur) and a clearer image indoors.
    unawaited(
      ScreenBrightness.instance
          .setApplicationScreenBrightness(1.0)
          .catchError((Object e) => debugPrint('⚠️ Brightness: $e')),
    );
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((e) {
          if (e.x * e.x + e.y * e.y + e.z * e.z >
              _kMaxPhoneRotation * _kMaxPhoneRotation) {
            _lastShakeAt = DateTime.now();
          }
        }, onError: (Object _) {});
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((e) => _gravity.add(e.x, e.y, e.z), onError: (Object _) {});
    _engine.acquire();
    unawaited(_engine.warmUp().catchError((_) {}));
    _initCamera();
  }

  @override
  void dispose() {
    _done = true;
    _watchdog.stop();
    _coveredTimer?.cancel();
    _gyroSub?.cancel();
    _accelSub?.cancel();
    unawaited(
      ScreenBrightness.instance.resetApplicationScreenBrightness().catchError(
        (Object e) => debugPrint('⚠️ Brightness reset: $e'),
      ),
    );
    _releaseCamera();
    _engine.release();
    _status.dispose();
    _scene.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  // ─── Camera ───────────────────────────────────────────────────────────────
  Future<void> _initCamera() async {
    final sw = Stopwatch()..start();
    CameraController? controller;
    try {
      final configured = FaceKit.config.cameras;
      final available = configured != null && configured.isNotEmpty
          ? configured
          : await availableCameras().timeout(CameraHealth.openWithin);
      if (available.isEmpty) return _fail(CameraFault.missing);

      final front = available.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => available.first,
      );
      controller = CameraController(
        front,
        // 720p: the face covers ~250+ px, so the 224 px upload image is a
        // downscale with real detail instead of a blurry upscale.
        ResolutionPreset.high,
        fps: _engine.config.cameraFps,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      // A broken camera can hang here for good; it is given a while.
      await controller.initialize().timeout(CameraHealth.openWithin);
      if (!mounted || _fault != null) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      controller.addListener(_onCameraValue);
      await _meterOnFace(controller);
      await controller.startImageStream(_onFrame);
      _watchdog.start();
      debugPrint(
        '📷 Camera streaming after ${sw.elapsedMilliseconds} ms '
        '(engine ready: ${_engine.isReady})',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Camera init error: $e');
      if (controller != null && !identical(controller, _controller)) {
        unawaited(controller.dispose().catchError((Object _) {}));
      }
      _fail(CameraHealth.faultOf(e) ?? CameraFault.broken);
    }
  }

  /// A camera that reports an error while running, as a phone's camera
  /// that fails or is taken by another app does.
  void _onCameraValue() {
    final controller = _controller;
    final error = controller?.value.errorDescription;
    if (error == null) return;
    final fault = CameraHealth.faultOfText(error);
    if (fault != null) _fail(fault);
  }

  /// Lets the camera go, its stream stopped first.
  void _releaseCamera() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onCameraValue);
    final stopped = controller.value.isStreamingImages
        ? controller.stopImageStream().catchError((Object _) {})
        : Future<void>.value();
    unawaited(
      stopped
          .then((_) => controller.dispose())
          .catchError((Object e) => debugPrint('⚠️ Camera close: $e')),
    );
  }

  /// Opens the camera again after a fault.
  void _retry() {
    if (_fault == null || !mounted) return;
    setState(() {
      _fault = null;
      _errorMessage = null;
    });
    _initCamera();
  }

  /// Points auto-exposure and autofocus at the middle of the frame, where
  /// the oval puts the face, so a bright window or wall behind the user
  /// doesn't leave the face dark or out of focus. Unsupported on some
  /// front cameras (fixed focus); failures are harmless.
  Future<void> _meterOnFace(CameraController controller) async {
    const faceCenter = Offset(0.5, 0.5);
    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        debugPrint('⚠️ Camera metering: $e');
      }
    }

    await attempt(() => controller.setExposureMode(ExposureMode.auto));
    if (controller.value.exposurePointSupported) {
      await attempt(() => controller.setExposurePoint(faceCenter));
    }
    await attempt(() => controller.setFocusMode(FocusMode.auto));
    if (controller.value.focusPointSupported) {
      await attempt(() => controller.setFocusPoint(faceCenter));
    }
  }

  int get _rotationDegrees {
    if (Platform.isIOS) return 0;
    return _controller?.description.sensorOrientation ?? 0;
  }

  // ─── Frame loop ───────────────────────────────────────────────────────────
  Future<void> _onFrame(CameraImage image) async {
    _watchdog.look(image);
    if (_detecting || _done || _controller == null) return;
    final now = DateTime.now();
    if (now.difference(_lastDetectAt) < _engine.config.detectInterval) return;
    _lastDetectAt = now;

    _detecting = true;
    try {
      final rotation = _rotationDegrees;
      final input = _toInputImage(image, rotation);
      if (input == null) return;
      final faces = await _engine.detector.processImage(input);
      if (!_done) _handleFaces(image, faces, rotation);
    } catch (e) {
      debugPrint('❌ Frame error: $e');
    } finally {
      _detecting = false;
    }
  }

  void _handleFaces(CameraImage image, List<Face> faces, int rotation) {
    final now = DateTime.now();
    if (faces.isEmpty) {
      final lastSeen = _lastFaceAt;
      if (lastSeen == null || now.difference(lastSeen) > _kFaceLostTolerance) {
        _restart();
      }
      return _suggest(_Hint.noFace);
    }
    _lastFaceAt = now;

    // Exactly one person: any second face, however small, blocks capture.
    if (faces.length > 1) {
      _restart();
      return _suggest(_Hint.multipleFaces);
    }
    final face = faces.first;

    // Every frame in one capture must be the same tracked face.
    final id = face.trackingId;
    if (id != null && _trackingId != null && id != _trackingId) _restart();

    final bool swapped = rotation == 90 || rotation == 270;
    final double frameW = (swapped ? image.height : image.width).toDouble();
    final double frameH = (swapped ? image.width : image.height).toDouble();
    final box = face.boundingBox;
    final ratio = box.width / frameW;

    if (ratio < _kMinFaceRatio) return _suggest(_Hint.tooFar);
    if (ratio > _kMaxFaceRatio) return _suggest(_Hint.tooClose);
    if (box.left < -box.width * 0.1 ||
        box.top < -box.height * 0.1 ||
        box.right > frameW + box.width * 0.1 ||
        box.bottom > frameH + box.height * 0.1) {
      return _suggest(_Hint.noFace);
    }
    // Scan only from in front of the face: the phone upright at eye level,
    // not low and turned up at the chin.
    final tilt = _gravity.backTilt;
    if (tilt != null && (tilt > _kMaxBackTilt || tilt < -_kMaxForwardTilt)) {
      return _suggest(_Hint.eyeLevel);
    }
    final pitch = face.headEulerAngleX ?? 0;
    if (pitch > _kMaxChinUp) return _suggest(_Hint.eyeLevel);
    if ((face.headEulerAngleY ?? 0).abs() > _kMaxYaw ||
        pitch.abs() > _kMaxPitch ||
        (face.headEulerAngleZ ?? 0).abs() > _kMaxRoll) {
      return _suggest(_Hint.lookAtCamera);
    }

    // Motion blur: skip frames while the phone shakes or the head moves.
    final center = box.center;
    final lastCenter = _lastFaceCenter, lastAt = _lastFaceCenterAt;
    _lastFaceCenter = center;
    _lastFaceCenterAt = now;
    final shakeAt = _lastShakeAt;
    if (shakeAt != null && now.difference(shakeAt) < _kShakeWindow) {
      return _suggest(_Hint.holdSteady);
    }
    if (lastCenter != null && lastAt != null) {
      final seconds = now.difference(lastAt).inMicroseconds / 1e6;
      if (seconds > 0 &&
          (center - lastCenter).distance / box.width / seconds >
              _kMaxFaceSpeed) {
        return _suggest(_Hint.holdSteady);
      }
    }

    final leftEyeOpen = face.leftEyeOpenProbability;
    final rightEyeOpen = face.rightEyeOpenProbability;
    if (leftEyeOpen != null &&
        rightEyeOpen != null &&
        leftEyeOpen < _kMinEyeOpen &&
        rightEyeOpen < _kMinEyeOpen) {
      return _suggest(_Hint.eyesClosed);
    }

    final geometry = _toGeometry(face);
    if (geometry.leftEye == null ||
        geometry.rightEye == null ||
        geometry.nose == null ||
        geometry.leftMouth == null ||
        geometry.rightMouth == null) {
      return _suggest(_Hint.faceCovered);
    }

    // Final gate on the image itself: light, blur, and face-image quality
    // (which also catches hands or objects the detector still reports).
    if (_checkingQuality) return;
    _checkingQuality = true;
    unawaited(_checkQuality(_toFaceFrame(image, rotation), geometry, id));
  }

  Future<void> _checkQuality(
    FaceFrame frame,
    FaceGeometry geometry,
    int? trackingId,
  ) async {
    try {
      final gate = await _engine.faceGate(frame, geometry);
      if (_done || !mounted) return;
      if (gate.brightness < kMinFaceBrightness) {
        return _suggest(_Hint.lowLight);
      }
      if (gate.brightness > kMaxFaceBrightness) {
        return _suggest(_Hint.tooBright);
      }
      // Blurry frames are skipped silently; the hint only appears if the
      // image stays blurry (see _Hint.delay).
      if (gate.sharpness < kMinFaceSharpness) {
        return _suggest(_Hint.holdSteady);
      }
      final quality = gate.quality;
      if (quality != null && quality < kMinFaceQuality) {
        debugPrint('🔎 Low face quality: ${quality.toStringAsFixed(2)}');
        return _suggest(_Hint.faceCovered);
      }
      if (trackingId != null &&
          _trackingId != null &&
          trackingId != _trackingId) {
        return;
      }
      if (_session.isComplete) return; // waiting for the occlusion check
      _suggest(_Hint.none);
      _trackingId ??= trackingId;
      _session.add(frame, geometry, quality: quality);
      debugPrint(
        '✅ Frame accepted ${_session.frameCount}/${_session.targetFrames}',
      );
      if (!_occlusionChecking && !_occlusionPassed) {
        unawaited(_checkOcclusion(frame, geometry));
      }
      _refresh();
      _completeIfReady();
    } catch (e) {
      debugPrint('❌ Face quality error: $e');
    } finally {
      _checkingQuality = false;
    }
  }

  /// Segmentation check for a hand or object anywhere on the face (chin,
  /// cheek, lips, forehead…), which the per-frame gates can miss.
  Future<void> _checkOcclusion(FaceFrame frame, FaceGeometry geometry) async {
    final generation = _captureGeneration;
    _occlusionChecking = true;
    FaceOcclusion? occlusion;
    try {
      occlusion = await _engine.faceOcclusion(frame, geometry);
    } catch (e) {
      debugPrint('❌ Face occlusion error: $e');
    }
    if (_done || !mounted || generation != _captureGeneration) return;
    _occlusionChecking = false;
    if (occlusion != null) {
      final onFace = occlusion.onFace > kMaxFaceOcclusion;
      final nearFace = occlusion.nearFace > kMaxNearFaceObject;
      if (onFace || nearFace) {
        debugPrint('✋ Blocked: $occlusion');
        _restart();
        _showCoveredHint(onFace ? _Hint.faceCovered : _Hint.objectNearFace);
        return;
      }
    }
    _occlusionPassed = true;
    debugPrint('🧩 Occlusion check passed');
    _completeIfReady();
  }

  void _completeIfReady() {
    if (_session.isComplete && _occlusionPassed) _complete();
  }

  void _complete() {
    _done = true;
    HapticFeedback.lightImpact();
    unawaited(_controller?.stopImageStream());
    if (mounted) Navigator.pop(context, _session);
  }

  void _restart() {
    _captureGeneration++;
    _occlusionChecking = false;
    _occlusionPassed = false;
    if (_session.frameCount == 0 && _trackingId == null) return;
    _session.clear();
    _trackingId = null;
    _refresh();
  }

  void _showCoveredHint(_Hint hint) {
    HapticFeedback.heavyImpact();
    _coveredHint = hint;
    _coveredUntil = DateTime.now().add(_kCoveredHintHold);
    _coveredTimer?.cancel();
    _coveredTimer = Timer(_kCoveredHintHold, _refresh);
    _refresh();
  }

  void _fail(CameraFault fault) {
    if (!mounted || _fault != null) return;
    debugPrint('❌ Camera fault: ${fault.name}');
    _watchdog.stop();
    _releaseCamera();
    setState(() {
      _fault = fault;
      _errorMessage = switch (fault) {
        CameraFault.denied => 'The camera is not allowed for this app',
        CameraFault.missing => 'No camera found on this phone',
        CameraFault.busy => 'Another app is using the camera',
        CameraFault.disabled => 'The camera is turned off on this phone',
        CameraFault.doNotDisturb => 'Turn off Do Not Disturb to use the camera',
        CameraFault.broken ||
        CameraFault.noPicture ||
        CameraFault.black ||
        CameraFault.frozen => "The phone's camera isn't working",
      };
    });
  }

  /// Shows a hint only after the same condition has persisted for
  /// [_Hint.delay], so brief glitches never flash instructions at the user.
  void _suggest(_Hint hint) {
    final now = DateTime.now();
    if (hint != _pendingHint) {
      _pendingHint = hint;
      _pendingHintSince = now;
    }
    final settled =
        hint == _Hint.none ||
        now.difference(_pendingHintSince ?? now) >= hint.delay;
    if (!settled || hint == _hint) return;
    _hint = hint;
    debugPrint('🎯 Face hint: ${hint.name}');
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    final count = _session.frameCount;
    final coveredUntil = _coveredUntil;
    final hint = coveredUntil != null && DateTime.now().isBefore(coveredUntil)
        ? _coveredHint
        : _hint;
    final capturing = count > 0 && hint == _Hint.none;
    final progress = count / _session.targetFrames;
    _status.value = _Status(
      capturing ? 'Hold on…' : hint.message,
      positive: capturing,
      progress: progress,
    );
    _scene.value = FaceCaptureStatus(
      hint: capturing ? FaceCaptureHint.capturing : hint.public,
      progress: progress,
    );
  }

  // ─── Conversions ──────────────────────────────────────────────────────────
  InputImage? _toInputImage(CameraImage image, int rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final imageRotation = InputImageRotationValue.fromRawValue(rotation);
    if (format == null || imageRotation == null) return null;

    final Uint8List bytes;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else {
      final buf = WriteBuffer();
      for (final plane in image.planes) {
        buf.putUint8List(plane.bytes);
      }
      bytes = buf.done().buffer.asUint8List();
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  FaceFrame _toFaceFrame(CameraImage image, int rotation) {
    final FaceFrameFormat format;
    if (image.format.group == ImageFormatGroup.bgra8888) {
      format = FaceFrameFormat.bgra8888;
    } else if (image.planes.length == 1) {
      format = FaceFrameFormat.nv21;
    } else {
      format = FaceFrameFormat.yuv420;
    }
    return FaceFrame(
      width: image.width,
      height: image.height,
      rotation: rotation,
      format: format,
      planes: [for (final p in image.planes) p.bytes],
      rowStrides: [for (final p in image.planes) p.bytesPerRow],
      pixelStrides: [for (final p in image.planes) p.bytesPerPixel ?? 1],
      // The iOS plugin mirrors front-camera frames; Android's does not.
      mirrored:
          Platform.isIOS &&
          _controller?.description.lensDirection == CameraLensDirection.front,
    );
  }

  FaceGeometry _toGeometry(Face face) {
    Offset? point(FaceLandmarkType type) {
      final p = face.landmarks[type]?.position;
      return p == null ? null : Offset(p.x.toDouble(), p.y.toDouble());
    }

    return FaceGeometry(
      box: face.boundingBox,
      leftEye: point(FaceLandmarkType.leftEye),
      rightEye: point(FaceLandmarkType.rightEye),
      nose: point(FaceLandmarkType.noseBase),
      leftMouth: point(FaceLandmarkType.leftMouth),
      rightMouth: point(FaceLandmarkType.rightMouth),
      yaw: face.headEulerAngleY ?? 0,
      pitch: face.headEulerAngleX ?? 0,
      roll: face.headEulerAngleZ ?? 0,
    );
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    if (layout != null) return layout(context, _sceneOf(context));
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return CustomPaint(
        painter: WavesBackgroundPainter(),
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _retry,
                        child: const Text('Try again'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    final screen = MediaQuery.sizeOf(context);
    final capsuleW = screen.width * kFaceOverlayWidthRatio;
    final capsuleH = screen.height * kFaceOverlayHeightRatio;
    final capsuleCy =
        screen.height / 2 + kFaceOverlayCenterYOffsetRatio * screen.height;
    final capsuleRect = Rect.fromCenter(
      center: Offset(screen.width / 2, capsuleCy),
      width: capsuleW,
      height: capsuleH,
    );
    final previewSize = controller.value.previewSize;

    return CustomPaint(
      painter: WavesBackgroundPainter(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: capsuleRect,
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(capsuleW * 0.47),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: previewSize?.height,
                      height: previewSize?.width,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),
            RepaintBoundary(
              child: ValueListenableBuilder<_Status>(
                valueListenable: _status,
                builder: (_, status, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: status.progress),
                  duration: const Duration(milliseconds: 120),
                  builder: (_, value, _) => CustomPaint(
                    painter: BinanceScannerPainter(progress: value),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  _isRegistration
                      ? 'Face Registration'
                      : 'Identity Verification',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: ValueListenableBuilder<_Status>(
                valueListenable: _status,
                builder: (_, status, _) =>
                    _StatusText(text: status.text, positive: status.positive),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The camera and status handed to the app's layout.
  FaceCaptureScene _sceneOf(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final previewSize = controller?.value.previewSize;
    return FaceCaptureScene(
      mode: _session.mode,
      fault: _fault,
      retry: _retry,
      status: _scene,
      close: () => Navigator.of(context).pop(),
      camera: !ready
          ? const Center(child: CircularProgressIndicator())
          : RepaintBoundary(
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize?.height,
                    height: previewSize?.width,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final String text;
  final bool positive;

  const _StatusText({required this.text, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: Text(
          text,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: positive ? const Color(0xFF16A34A) : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            height: 1.35,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class WavesBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final Rect rect = Offset.zero & size;

    // 1. Soft Base Gradient (Light Mint/Green to Pale Tint)
    final Paint basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F5E9), // Soft light green at top
          Color(0xFFF1F8E9), // Smooth mid transition
          Color(0xFFF9FBE7), // Pure soft tint at bottom
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    // 2. Primary Swoosh/Wave Path (Top Right downwards)
    final Path topWavePath = Path()
      ..moveTo(width * 0.42, 0)
      ..cubicTo(
        width * 0.60,
        height * 0.12,
        width * 0.82,
        height * 0.22,
        width,
        height * 0.26,
      )
      ..lineTo(width, 0)
      ..close();

    final Paint topWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFC8E6C9).withValues(alpha: 0.70),
          const Color(0xFFE8F5E9).withValues(alpha: 0.35),
          const Color(0xFFF1F8E9).withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    canvas.drawPath(topWavePath, topWavePaint);

    // 3. Secondary Flowing Wave (Sweeps under the first curve)
    final Path secondaryWavePath = Path()
      ..moveTo(width * 0.58, 0)
      ..cubicTo(
        width * 0.75,
        height * 0.16,
        width * 0.88,
        height * 0.28,
        width,
        height * 0.32,
      )
      ..lineTo(width, 0)
      ..close();

    final Paint secondaryWavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFA5D6A7).withValues(alpha: 0.45),
          const Color(0xFFE8F5E9).withValues(alpha: 0.10),
        ],
      ).createShader(rect);

    canvas.drawPath(secondaryWavePath, secondaryWavePaint);

    // 4. Subtle Radial Highlight in Top-Right Corner
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.9, -0.9),
        radius: 0.8,
        colors: [
          const Color(0xFFC8E6C9).withValues(alpha: 0.5),
          const Color(0xFFE8F5E9).withValues(alpha: 0.0),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
