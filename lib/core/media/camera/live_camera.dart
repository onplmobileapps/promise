import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

/// Where a [LiveCamera] stands.
enum LiveCameraStatus {
  /// Opening, or opening again after the app was away.
  starting,

  /// Open, its preview showing.
  ready,

  /// It couldn't be opened, or stopped working; [LiveCamera.fault] says
  /// why and [LiveCamera.retry] tries again.
  failed,

  /// The user didn't allow the camera.
  denied,
}

/// The phone's back camera for a scanner that looks at what it sees as it
/// sees it: opened once its use is explained and allowed, its frames handed
/// to [onFrame] one at a time, let go while the app is away and taken back
/// after, with its light, its zoom and a photo.
///
/// It has been through the edge cases a camera meets: only one opening at
/// a time, a new camera only once the last is let go, never opened while
/// the app is still coming back from the permission prompt, and work begun
/// on a camera dropped when that camera is gone ([session]).
class LiveCamera extends ChangeNotifier with WidgetsBindingObserver {
  LiveCamera({
    required this.onFrame,
    this.frameEvery = const Duration(milliseconds: 200),
    // 720p, as the face camera: some phones can't stream frames at 1080p
    // beside the preview and the photo.
    this.resolution = ResolutionPreset.high,
    this.focusPoint = const Offset(0.5, 0.5),
  }) {
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _awake = state == null || state == AppLifecycleState.resumed;
  }

  /// Given a frame of the stream; the next waits till it is done, and
  /// comes [frameEvery] after the last at the soonest.
  final Future<void> Function(CameraImage image) onFrame;
  final Duration frameEvery;
  final ResolutionPreset resolution;

  /// Where focus and exposure are set, from the preview's top left (0, 0)
  /// to its bottom right (1, 1).
  final Offset focusPoint;

  CameraController? _controller;
  LiveCameraStatus _status = LiveCameraStatus.starting;
  CameraFault? _fault;
  late final CameraWatchdog _watchdog = CameraWatchdog(onFault: _failWith);
  int _session = 0;
  bool _torch = false;
  bool _hasTorch = true;
  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;

  /// [open] was called and the camera allowed: it is to be open.
  bool _opened = false;
  bool _framesWanted = false;
  bool _reading = false;
  DateTime _lastFrame = DateTime(0);
  bool _awake = true;
  bool _disposed = false;

  /// An opening under way: there is only ever one.
  Future<void>? _opening;

  /// The last camera being let go; a new one opens only once it has.
  Future<void> _releasing = Future.value();

  /// The camera while it is open; its preview, for [CameraPreview].
  CameraController? get controller => _controller;
  LiveCameraStatus get status => _status;

  /// What is wrong with the phone's camera while [status] is failed.
  CameraFault? get fault => _fault;
  bool get isReady =>
      _status == LiveCameraStatus.ready &&
      (_controller?.value.isInitialized ?? false);

  /// Counts each opening of the camera. Work begun while it was one value
  /// is dropped once it is another: that camera is gone.
  int get session => _session;

  /// Whether the light is on, and whether the camera has one.
  bool get torch => _torch;
  bool get hasTorch => _hasTorch;

  /// The zoom now, and the least and the most the camera can.
  double get zoom => _zoom;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;

  /// The clockwise turn that stands a frame of the stream upright. iOS
  /// sends them upright; Android as the sensor sits, with the screen held
  /// upright.
  int get rotation =>
      Platform.isIOS ? 0 : _controller?.description.sensorOrientation ?? 0;

  /// Opens the camera, its use explained before the system asks, and
  /// starts its frames; false when it isn't allowed.
  Future<bool> open(BuildContext context) async {
    if (!_opened) {
      final allowed = await sl<PermissionGate>().request(
        AppPermission.camera,
        context: context,
      );
      if (_disposed) return false;
      if (!allowed) {
        _setStatus(LiveCameraStatus.denied);
        return false;
      }
      _opened = true;
    }
    _framesWanted = true;
    // Otherwise it opens when the app is back in front.
    if (_awake) _start();
    return true;
  }

  /// Opens the camera again after it failed.
  void retry() {
    if (_opened) _start();
  }

  /// Stops the frames, as while a dialog is up; the preview goes on.
  Future<void> pauseFrames() async {
    _framesWanted = false;
    final camera = _controller;
    _watchdog.stop();
    if (camera == null || !camera.value.isStreamingImages) return;
    try {
      await camera.stopImageStream();
    } catch (error) {
      debugPrint('The camera failed to pause: $error');
    }
  }

  /// Starts the frames again; opens the camera again if it was let go
  /// meanwhile.
  Future<void> resumeFrames() async {
    _framesWanted = true;
    final camera = _controller;
    if (camera == null) {
      if (_opened && _awake) _start();
      return;
    }
    if (!camera.value.isInitialized || camera.value.isStreamingImages) return;
    try {
      _watchdog.start();
      await camera.startImageStream(_frame);
    } catch (error) {
      debugPrint('The camera failed to resume: $error');
      _failWith(CameraHealth.faultOf(error) ?? CameraFault.broken);
    }
  }

  /// Takes a photo, the frames stopped first; they stay stopped till
  /// [resumeFrames].
  Future<XFile> takePicture() async {
    final camera = _controller;
    if (camera == null || !camera.value.isInitialized) {
      throw CameraException('closed', 'The camera is closed');
    }
    _framesWanted = false;
    _watchdog.stop();
    if (camera.value.isStreamingImages) await camera.stopImageStream();
    return camera.takePicture();
  }

  /// Turns the light [on] or off. It starts off.
  Future<void> setTorch(bool on) async {
    final camera = _controller;
    if (camera == null || on == _torch) return;
    try {
      await camera.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      _torch = on;
    } catch (error) {
      debugPrint('The camera light failed: $error');
      _hasTorch = false;
    }
    if (!_disposed) notifyListeners();
  }

  /// Zooms to [zoom], within what the camera can.
  void setZoom(double zoom) {
    final camera = _controller;
    if (camera == null) return;
    _zoom = zoom.clamp(_minZoom, _maxZoom);
    camera.setZoomLevel(_zoom).catchError((Object error) {
      debugPrint('The camera failed to zoom: $error');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera is let go while the app is away, and taken back after.
    if (state == AppLifecycleState.resumed) {
      _awake = true;
      if (_opened && _controller == null && _opening == null) _start();
      return;
    }
    if (state != AppLifecycleState.inactive &&
        state != AppLifecycleState.paused) {
      return;
    }
    _awake = false;
    _watchdog.stop();
    // An opening under way sees the app is away once the camera opens.
    if (_controller == null) return;
    _session++;
    _release();
    _torch = false;
    _setStatus(LiveCameraStatus.starting);
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog.stop();
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _release();
    super.dispose();
  }

  void _start() {
    if (_disposed) return;
    _opening ??= _openNow().whenComplete(() => _opening = null);
  }

  Future<void> _openNow() async {
    final session = ++_session;
    // A camera left from an opening that failed halfway.
    _release();
    _torch = false;
    _fault = null;
    _setStatus(LiveCameraStatus.starting);
    CameraController? camera;
    try {
      await _releasing;
      final cameras = await availableCameras().timeout(CameraHealth.openWithin);
      if (cameras.isEmpty) throw CameraException('none', 'No camera');
      final back = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      camera = CameraController(
        back,
        resolution,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      // A broken camera can hang here for good; it is given a while.
      await camera.initialize().timeout(CameraHealth.openWithin);
      if (_disposed || session != _session || !_awake) {
        await camera.dispose();
        return;
      }
      _controller = camera;
      camera.addListener(_onCameraValue);
      _minZoom = _maxZoom = _zoom = 1;
      if (_framesWanted) {
        // Watched from here: a broken camera can hang starting its
        // pictures, or never send one.
        _watchdog.start();
        await camera.startImageStream(_frame);
      }
      if (_disposed || session != _session) return;
      _setStatus(LiveCameraStatus.ready);
      // Set up while the camera already looks, so it opens without wait.
      unawaited(_aim(camera));
    } catch (error) {
      debugPrint('The camera failed to open: $error');
      if (identical(_controller, camera)) {
        _controller = null;
        camera?.removeListener(_onCameraValue);
      }
      unawaited(camera?.dispose().catchError((Object _) {}));
      if (!_disposed && session == _session) {
        _fault = CameraHealth.faultOf(error) ?? CameraFault.broken;
        _setStatus(LiveCameraStatus.failed);
      }
    }
  }

  /// A camera that reports an error while running, as one that fails or
  /// is taken by another app does.
  void _onCameraValue() {
    final error = _controller?.value.errorDescription;
    if (error == null) return;
    final fault = CameraHealth.faultOfText(error);
    if (fault != null) _failWith(fault);
  }

  /// The camera stopped working with [fault]: it is let go, to be opened
  /// again by [retry].
  void _failWith(CameraFault fault) {
    if (_disposed || _status == LiveCameraStatus.failed) return;
    debugPrint('The camera is at fault: ${fault.name}');
    _watchdog.stop();
    _session++;
    _release();
    _torch = false;
    _fault = fault;
    _setStatus(LiveCameraStatus.failed);
  }

  /// How far the camera can zoom; no flash, which would glare; focus and
  /// exposure on [focusPoint]. Not every camera can do each; those that
  /// can't are left be.
  Future<void> _aim(CameraController camera) async {
    Future<void> attempt(Future<void> Function() action) async {
      try {
        // A setting a broken camera never answers is given up on.
        await action().timeout(const Duration(seconds: 2));
      } catch (error) {
        debugPrint('A camera setting failed: $error');
      }
    }

    await attempt(() async {
      _minZoom = await camera.getMinZoomLevel();
      _maxZoom = await camera.getMaxZoomLevel();
      _zoom = _minZoom;
    });
    await attempt(() => camera.setFlashMode(FlashMode.off));
    await attempt(() => camera.setFocusMode(FocusMode.auto));
    if (camera.value.focusPointSupported) {
      await attempt(() => camera.setFocusPoint(focusPoint));
    }
    if (camera.value.exposurePointSupported) {
      await attempt(() => camera.setExposurePoint(focusPoint));
    }
  }

  void _frame(CameraImage image) {
    _watchdog.look(image);
    if (_reading || !_framesWanted || _disposed) return;
    final now = DateTime.now();
    if (now.difference(_lastFrame) < frameEvery) return;
    _lastFrame = now;
    _reading = true;
    unawaited(
      onFrame(image)
          .catchError((Object error) => debugPrint('A frame failed: $error'))
          .whenComplete(() => _reading = false),
    );
  }

  /// Lets the camera go, stopping its stream first. Cameras are let go one
  /// after another, and a new one waits for them.
  void _release() {
    final camera = _controller;
    _controller = null;
    if (camera == null) return;
    camera.removeListener(_onCameraValue);
    _releasing = _releasing
        .then((_) async {
          try {
            if (camera.value.isStreamingImages) await camera.stopImageStream();
          } catch (error) {
            debugPrint('The camera failed to stop streaming: $error');
          }
          await camera.dispose();
        })
        .catchError((Object error) {
          debugPrint('The camera failed to close: $error');
        });
  }

  void _setStatus(LiveCameraStatus status) {
    _status = status;
    if (!_disposed) notifyListeners();
  }
}
