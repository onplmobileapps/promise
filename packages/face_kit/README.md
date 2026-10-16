# face_kit

Plug-and-play face capture for Flutter apps (Android + iOS):

- **Face-ID-style capture** — no challenges or "hold still"; the camera closes
  a fraction of a second after a usable face is seen.
- **Passive liveness** — rejects printed photos, screens and videos.
- **Clean, frontal images only** — blocks: more than one person, turned or
  tilted heads, closed/covered eyes, hands or objects on or beside the face,
  blur, poor light.
- **Same images on every platform** — upright, eye-aligned, never mirrored.
- **On-device face embeddings** (512-d) for the server's similarity check.
- **Smooth on 2 GB phones** — all ML runs in background isolates via FFI.

## 1. Add the package

```yaml
dependencies:
  face_kit:
    path: packages/face_kit   # or a git dependency
```

Copy this folder into the new project (or reference it from git). The models
(~21 MB) are bundled with the package — nothing else to download.

## 2. Platform setup

**Android** — `android/app/src/main/AndroidManifest.xml` needs
`<uses-permission android:name="android.permission.CAMERA"/>`, and `minSdk`
must be at least 24. Copy [`proguard-rules.pro`](proguard-rules.pro) into
`android/app/` (or merge its rules); Flutter picks it up automatically for
release builds.

**iOS** — in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>The camera is used to verify your identity.</string>
```

In Xcode → Runner → Build Settings, set **Strip Style** to
**Non-Global Symbols** (release). The ONNX runtime is called through FFI and
its symbols must survive stripping. Then run `cd ios && pod install`.

## 3. Use it

```dart
import 'package:face_kit/face_kit.dart';

// Optional, once (e.g. in main):
FaceKit.configure(FaceKitConfig(
  onError: (e, st, reason) => FirebaseCrashlytics.instance
      .recordError(e, st, reason: reason),
));

// Optional: load the models early (e.g. when the dashboard opens).
FaceKit.preload();

// Capture:
final result = await FaceCapture.open(context, mode: CaptureMode.verification);
switch (result) {
  case FaceVerificationResult r:   // r.images (XFile JPEGs), r.embeddings
  case FaceRegistrationResult r:   // registration mode
  case FaceCaptureFailedResult r:  // r.message for the user; r.spoof if a photo/screen
  case null:                       // user backed out or cancelled
}
```

Show your own "Verifying…" loader while `FaceCapture.open` runs: the camera
closes almost immediately and recognition/liveness finish in the background.

## Configuration

| `FaceKitConfig` field | Default | Meaning |
|---|---|---|
| `onError` | debugPrint only | Receives internal errors (e.g. for Crashlytics) |
| `showPreviewDialog` | debug builds | Shows captured images + scores with Continue/Cancel |
| `maxUploadBytes` | 10 KB | Size limit per uploaded JPEG (highest quality that fits) |
| `registrationImages` | 5 | Images returned for registration |
| `verificationImages` | 2 | Images returned for verification |
| `cameras` | auto | Pass the app's `availableCameras()` list to skip a lookup |

Detection thresholds (quality, sharpness, occlusion, liveness) are constants
at the top of `lib/src/engine/face_engine.dart`, each documented with the
values measured during tuning.

## Server-side similarity

Compare a verification against the **average** of the registration
embeddings (and average the verification embeddings too) rather than single
pairs — measured +0.12 cosine similarity on real data. See the project notes
for a ready-made snippet.

## Models and licences

| Model | Purpose | Licence |
|---|---|---|
| `mbf.onnx` (InsightFace buffalo_sc) | Face embedding | **Non-commercial research only** — get a licence from InsightFace or swap in a commercially licensed model before production |
| `fas_minifas_v2/v1se.onnx` (MiniFASNet) | Liveness | Apache-2.0 |
| `fas_print_replay.onnx` | Liveness (print/replay) | Unclear — verify before commercial use |
| `face_quality.onnx` (eDifFIQA) | Face quality / occlusion | CC-BY-4.0 (attribution added to Flutter's licence page automatically) |
| `face_segmentation.onnx` (MediaPipe) | Hands/objects on the face | Apache-2.0 |

Model weights are stored as fp16 and cast to fp32 at load
(`tool/pack_onnx_weights.py`), halving the size without changing results.

## Tests

`flutter test` runs the unit tests. The end-to-end test with the real models
needs `FACE_E2E_FRAMES` pointing at prepared frames and the host ONNX Runtime
library next to the package; it is skipped otherwise.
