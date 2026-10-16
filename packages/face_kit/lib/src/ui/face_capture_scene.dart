import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../face_kit.dart';

/// What the camera needs from the person right now. The app words it.
enum FaceCaptureHint {
  /// Nothing is wrong yet: look at the camera.
  lookAtCamera,
  lookStraight,
  eyeLevel,
  noFace,
  multipleFaces,
  eyesClosed,
  faceCovered,
  tooFar,
  tooClose,
  holdSteady,
  lowLight,
  tooBright,
  objectNearFace,

  /// A good face is in view and its photos are being taken.
  capturing,
}

/// Where a capture stands: what to tell the person, and how many of the
/// photos it needs are taken, from 0 to 1.
@immutable
class FaceCaptureStatus {
  const FaceCaptureStatus({required this.hint, this.progress = 0});

  final FaceCaptureHint hint;
  final double progress;

  /// The face is good and the photos are being taken.
  bool get capturing => hint == FaceCaptureHint.capturing;

  @override
  bool operator ==(Object other) =>
      other is FaceCaptureStatus &&
      other.hint == hint &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(hint, progress);
}

/// The parts of the capture screen face_kit runs, handed to the app's
/// layout to place: the live [camera], the capture's [status], and a way to
/// [close] it.
@immutable
class FaceCaptureScene {
  const FaceCaptureScene({
    required this.mode,
    required this.camera,
    required this.status,
    required this.close,
    this.failed = false,
  });

  final CaptureMode mode;

  /// The camera's view, filling whatever box it is given (cropped to fit),
  /// or a spinner while the camera starts.
  final Widget camera;
  final ValueListenable<FaceCaptureStatus> status;
  final VoidCallback close;

  /// The camera couldn't be opened.
  final bool failed;
}

/// Builds the capture screen around a [FaceCaptureScene].
typedef FaceCaptureLayout =
    Widget Function(BuildContext context, FaceCaptureScene scene);
