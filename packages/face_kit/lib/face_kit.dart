/// Plug-and-play face capture: Face-ID-style capture, passive liveness,
/// occlusion/blur/pose gates and on-device face embeddings.
///
/// ```dart
/// final result = await FaceCapture.open(context, mode: CaptureMode.verification);
/// if (result is FaceVerificationResult) upload(result.images, result.embeddings);
/// ```
library;

export 'src/capture/camera_health.dart'
    show CameraFault, CameraHealth, CameraWatchdog;
export 'src/capture/face_capture_session.dart'
    show
        FaceCaptureFailedResult,
        FaceRegistrationResult,
        FaceVerificationResult;
export 'src/face_kit.dart'
    show CaptureMode, FaceKit, FaceKitConfig, FaceKitErrorReporter;
export 'src/ui/face_capture_scene.dart'
    show
        FaceCaptureHint,
        FaceCaptureLayout,
        FaceCaptureScene,
        FaceCaptureStatus;
export 'src/ui/face_capture_view.dart' show FaceCapture, FaceCaptureView;
