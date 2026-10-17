import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// What is wrong with the phone's camera, as far as the app can tell. The
/// app words it; most mean the phone, not the app, is at fault.
enum CameraFault {
  /// The camera isn't allowed for the app.
  denied,

  /// The phone reports no camera at all.
  missing,

  /// Another app, or the system, holds the camera.
  busy,

  /// The camera is turned off on the phone, by its settings or a policy.
  disabled,

  /// The phone's "Do Not Disturb" mode keeps the camera shut.
  doNotDisturb,

  /// The camera didn't open, or stopped with an error: most likely broken.
  broken,

  /// It opened, but no picture comes from it.
  noPicture,

  /// Pictures come, but every one is flat black: the sensor gives nothing.
  black,

  /// Pictures come, but never change: the sensor is stuck.
  frozen,
}

/// Tells camera faults apart, from the errors the camera plugins raise and
/// from what the camera sends.
abstract final class CameraHealth {
  /// How long a camera may take to open before it is taken as broken.
  static const Duration openWithin = Duration(seconds: 12);

  /// The fault behind [error], raised while finding, opening or running a
  /// camera; null for an error the camera recovers from by itself.
  static CameraFault? faultOf(Object error) {
    if (error is TimeoutException) return CameraFault.broken;
    final text = switch (error) {
      CameraException(:final code, :final description) =>
        '$code ${description ?? ''}',
      PlatformException(:final code, :final message) =>
        '$code ${message ?? ''}',
      _ => '$error',
    }.toLowerCase();
    return faultOfText(text);
  }

  /// The fault an error's [text] describes, as the camera plugins word it
  /// (CameraX's states, Camera2's access errors, AVFoundation's codes).
  static CameraFault? faultOfText(String text) {
    final t = text.toLowerCase();
    if (t.contains('recoverable error')) return null;
    if (t.contains('accessdenied') ||
        t.contains('accessrestricted') ||
        t.contains('access_denied') ||
        t.contains('permission')) {
      return CameraFault.denied;
    }
    if (t.contains('do not disturb')) return CameraFault.doNotDisturb;
    if (t.contains('in use') ||
        t.contains('in_use') ||
        t.contains('max_cameras') ||
        t.contains('limit number of open cameras')) {
      return CameraFault.busy;
    }
    if (t.contains('policy') || t.contains('camera_disabled')) {
      return CameraFault.disabled;
    }
    if (t.contains('no camera') ||
        t.contains('no_available_camera') ||
        t.contains('nocamera')) {
      return CameraFault.missing;
    }
    return CameraFault.broken;
  }
}

/// Watches a running camera for the faults it shows only by what it sends:
/// no pictures at all, pictures all black, or the same picture over and
/// over. A working sensor always shows some noise, so a picture that is
/// flat or never changes is the hardware's fault, not the scene's.
///
/// [start] it as the stream starts, show it every frame with [look], and
/// [stop] it when the stream stops. It reports a fault once to [onFault],
/// and after a few seconds of good pictures stops looking.
class CameraWatchdog {
  CameraWatchdog({
    required this.onFault,
    this.firstFrameWithin = const Duration(seconds: 6),
    this.stillFor = const Duration(seconds: 4),
    this.healthyAfter = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final void Function(CameraFault fault) onFault;

  /// How long the first picture may take once the stream starts.
  final Duration firstFrameWithin;

  /// How long the pictures must stay black, or unchanged, to be a fault.
  final Duration stillFor;

  /// How long the pictures must look alive for the camera to be trusted.
  final Duration healthyAfter;

  /// The time, for tests to set.
  final DateTime Function() _now;

  /// Points sampled across a picture: few enough to cost nothing a frame.
  static const int _columns = 16;
  static const int _rows = 12;

  /// The most a black picture's samples may differ, and their brightest
  /// mean, out of 255.
  static const int _flatSpread = 2;
  static const int _blackMean = 24;

  Timer? _firstFrame;
  bool _done = false;
  DateTime? _aliveSince;
  DateTime? _blackSince;
  DateTime? _sameSince;
  int? _lastSignature;

  /// Starts watching a stream that has just started.
  void start() {
    _firstFrame?.cancel();
    _done = false;
    _aliveSince = _blackSince = _sameSince = null;
    _lastSignature = null;
    _firstFrame = Timer(firstFrameWithin, () => _report(CameraFault.noPicture));
  }

  /// Stops watching, as the stream stops or the camera closes.
  void stop() {
    _firstFrame?.cancel();
    _firstFrame = null;
    _done = true;
  }

  /// Looks at one frame of the stream.
  void look(CameraImage image) {
    if (_done) return;
    _firstFrame?.cancel();
    _firstFrame = null;
    final sample = _sample(image);
    if (sample == null) return;
    final (mean, spread, signature) = sample;
    final now = _now();
    final black = mean <= _blackMean && spread <= _flatSpread;
    final same = signature == _lastSignature;
    _lastSignature = signature;
    _blackSince = black ? (_blackSince ?? now) : null;
    _sameSince = same ? (_sameSince ?? now) : null;
    if (_blackSince case final since? when now.difference(since) >= stillFor) {
      return _report(CameraFault.black);
    }
    if (_sameSince case final since? when now.difference(since) >= stillFor) {
      return _report(CameraFault.frozen);
    }
    if (black || same) {
      _aliveSince = null;
      return;
    }
    final alive = _aliveSince ??= now;
    if (now.difference(alive) >= healthyAfter) stop();
  }

  void _report(CameraFault fault) {
    if (_done) return;
    stop();
    onFault(fault);
  }

  /// The brightness of a grid of points across [image]: their mean, their
  /// spread, and a signature that changes whenever any of them does. The
  /// first plane is the brightness on Android (NV21/YUV) and blue, green,
  /// red and alpha on iOS (BGRA), read by its green.
  static (int, int, int)? _sample(CameraImage image) {
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;
    final Uint8List bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    if (width <= 0 || height <= 0 || bytes.isEmpty) return null;
    final bgra = image.format.group == ImageFormatGroup.bgra8888;
    final pixel = bgra ? 4 : (plane.bytesPerPixel ?? 1);
    final row = plane.bytesPerRow;
    var low = 255;
    var high = 0;
    var sum = 0;
    var count = 0;
    var signature = 0x811c9dc5;
    for (var r = 0; r < _rows; r++) {
      final y = ((r * 2 + 1) * height) ~/ (_rows * 2);
      for (var c = 0; c < _columns; c++) {
        final x = ((c * 2 + 1) * width) ~/ (_columns * 2);
        final i = y * row + x * pixel + (bgra ? 1 : 0);
        if (i >= bytes.length) continue;
        final v = bytes[i];
        if (v < low) low = v;
        if (v > high) high = v;
        sum += v;
        count++;
        signature = ((signature ^ v) * 0x01000193) & 0xffffffff;
      }
    }
    if (count == 0) return null;
    return (sum ~/ count, high - low, signature);
  }
}
