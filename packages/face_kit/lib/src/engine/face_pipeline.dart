import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:image/image.dart' as img;

// ─────────────────────────────────────────────────────────────────────────────
//  Face preprocessing
//
//  Pure functions (run inside the FaceEngine worker isolate) that turn one
//  raw camera frame + ML Kit geometry into every tensor the models need. The
//  face is sampled straight out of the NV21 / YUV420 / BGRA planes — the full
//  frame is never converted to RGB or rotated.
// ─────────────────────────────────────────────────────────────────────────────

const int kEmbedInputSize = 112;
const int kMiniFasInputSize = 80;
const int kPrintReplayInputSize = 128;
const int kUploadSize = 224;
const int kSegmentationInputSize = 256;

// MediaPipe selfie-multiclass labels (background, hair, body skin, face skin,
// clothes, others/accessories).
const int _kSegClasses = 6;
const int _kSegBodySkin = 2;
const int _kSegClothes = 4;
const int _kSegOthers = 5;

/// ArcFace reference landmarks for a 112×112 aligned face.
const List<Offset> _kRefLandmarks112 = [
  Offset(38.2946, 51.6963), // left eye
  Offset(73.5318, 51.5014), // right eye
  Offset(56.0252, 71.7366), // nose base
  Offset(41.5493, 92.3655), // left mouth corner
  Offset(70.7299, 92.2041), // right mouth corner
];

Rect buildFaceCropRectForFrame(Rect faceBox, Size frameSize) {
  final double chinPadding = faceBox.height * 0.10;
  final double maxWidth = frameSize.width * 0.82;
  final double maxHeight = frameSize.height * 0.72;
  final double cropWidth = (faceBox.width * 1.18).clamp(
    math.min(120.0, maxWidth),
    maxWidth,
  );
  final double cropHeight = (faceBox.height * 0.92 + chinPadding).clamp(
    math.min(120.0, maxHeight),
    maxHeight,
  );

  final double centerX = faceBox.center.dx.clamp(
    cropWidth / 2,
    frameSize.width - cropWidth / 2,
  );
  final double centerY = (faceBox.top + faceBox.height * 0.32 + chinPadding / 2)
      .clamp(cropHeight / 2, frameSize.height - cropHeight / 2);

  return Rect.fromCenter(
    center: Offset(centerX, centerY),
    width: cropWidth,
    height: cropHeight,
  );
}

enum FaceFrameFormat { nv21, yuv420, bgra8888 }

/// Raw camera frame plus the clockwise rotation (0/90/180/270) that makes it
/// upright — the same rotation handed to ML Kit.
class FaceFrame {
  final int width;
  final int height;
  final int rotation;
  final FaceFrameFormat format;
  final List<Uint8List> planes;
  final List<int> rowStrides;
  final List<int> pixelStrides;

  /// True when the camera delivers a horizontally mirrored image (the iOS
  /// front camera does; Android's does not). Output images are always
  /// un-mirrored — the true view, as someone else would photograph the face —
  /// so every platform sends identical-looking images to the server.
  final bool mirrored;

  const FaceFrame({
    required this.width,
    required this.height,
    required this.rotation,
    required this.format,
    required this.planes,
    required this.rowStrides,
    required this.pixelStrides,
    this.mirrored = false,
  });

  bool get _swapped => rotation == 90 || rotation == 270;
  int get uprightWidth => _swapped ? height : width;
  int get uprightHeight => _swapped ? width : height;
}

/// Face geometry in upright-frame coordinates, as reported by ML Kit.
class FaceGeometry {
  final Rect box;
  final Offset? leftEye;
  final Offset? rightEye;
  final Offset? nose;
  final Offset? leftMouth;
  final Offset? rightMouth;

  /// Head pose in degrees (ML Kit Euler angles): left/right turn, up/down
  /// tilt and sideways roll.
  final double yaw;
  final double pitch;
  final double roll;

  const FaceGeometry({
    required this.box,
    this.leftEye,
    this.rightEye,
    this.nose,
    this.leftMouth,
    this.rightMouth,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
  });

  /// How far the head is from looking straight at the camera (0 = frontal).
  double get poseDeviation => yaw.abs() + pitch.abs() + roll.abs() * 0.5;
}

/// Everything derived from one frame, ready for inference.
class FacePrep {
  /// NCHW RGB in [-1, 1] — mbf (buffalo_sc) recognition input.
  final Float32List embedInput;

  /// NCHW BGR raw 0..255 — MiniFASNetV2 (crop scale 2.7).
  final Float32List miniFasV2Input;

  /// NCHW BGR raw 0..255 — MiniFASNetV1SE (crop scale 4.0).
  final Float32List miniFasV1seInput;

  /// NCHW RGB in [0, 1] — print/replay model (square crop ×1.5, black pad).
  final Float32List printReplayInput;

  /// Variance of the Laplacian over the centre of the face (eyes, nose,
  /// mouth) at upload resolution. Sharp faces measure ~120–1300; focus or
  /// motion blur drops it below ~60.
  final double sharpness;
  final double brightness;

  const FacePrep({
    required this.embedInput,
    required this.miniFasV2Input,
    required this.miniFasV1seInput,
    required this.printReplayInput,
    required this.sharpness,
    required this.brightness,
  });
}

/// Geometry in true-view (un-mirrored) upright coordinates. ML Kit reports
/// points in the frame as delivered, so mirrored frames are flipped here and
/// [_FrameSampler] flips its reads to match.
FaceGeometry _trueView(FaceFrame frame, FaceGeometry g) {
  if (!frame.mirrored) return g;
  final double maxX = frame.uprightWidth - 1.0;
  Offset? flip(Offset? p) => p == null ? null : Offset(maxX - p.dx, p.dy);
  return FaceGeometry(
    box: Rect.fromLTRB(
      maxX - g.box.right,
      g.box.top,
      maxX - g.box.left,
      g.box.bottom,
    ),
    leftEye: flip(g.leftEye),
    rightEye: flip(g.rightEye),
    nose: flip(g.nose),
    leftMouth: flip(g.leftMouth),
    rightMouth: flip(g.rightMouth),
    yaw: -g.yaw,
    pitch: g.pitch,
    roll: -g.roll,
  );
}

FacePrep prepareFace(FaceFrame frame, FaceGeometry g) {
  g = _trueView(frame, g);
  final s = _FrameSampler(frame);
  final box = g.box;

  final aligned = _renderAligned(s, g, kEmbedInputSize);
  final upload = _measureUpload(s, g);

  return FacePrep(
    embedInput: _toNchw(aligned, kEmbedInputSize, (v) => (v - 127.5) / 127.5),
    miniFasV2Input: _toNchw(
      _renderRect(s, _miniFasCrop(box, 2.7, s), kMiniFasInputSize),
      kMiniFasInputSize,
      (v) => v.toDouble(),
      bgr: true,
    ),
    miniFasV1seInput: _toNchw(
      _renderRect(s, _miniFasCrop(box, 4.0, s), kMiniFasInputSize),
      kMiniFasInputSize,
      (v) => v.toDouble(),
      bgr: true,
    ),
    printReplayInput: _toNchw(
      _renderRect(s, _squareCrop(box, 1.5), kPrintReplayInputSize),
      kPrintReplayInputSize,
      (v) => v / 255.0,
    ),
    sharpness: upload.sharpness,
    brightness: upload.brightness,
  );
}

/// What the live capture gate needs from one frame, all from a single render
/// of the face exactly as it would be uploaded.
class FaceGateInput {
  /// NCHW RGB in [-1, 1], 112×112 — the face-quality model input.
  final Float32List qualityInput;

  /// See [FacePrep.sharpness].
  final double sharpness;

  /// Mean face brightness, 0..255.
  final double brightness;

  const FaceGateInput(this.qualityInput, this.sharpness, this.brightness);
}

FaceGateInput prepareGate(FaceFrame frame, FaceGeometry g) {
  final upload = _measureUpload(_FrameSampler(frame), _trueView(frame, g));
  final half = _downsample2x(upload.rgb, kUploadSize);
  return FaceGateInput(
    _toNchw(half, kUploadSize ~/ 2, (v) => (v - 127.5) / 127.5),
    upload.sharpness,
    upload.brightness,
  );
}

/// Only the aligned recognition/quality input — the cheap subset of
/// [prepareFace] used for the live quality gate while capturing.
Float32List prepareAlignedInput(FaceFrame frame, FaceGeometry g) {
  final aligned = _renderAligned(
    _FrameSampler(frame),
    _trueView(frame, g),
    kEmbedInputSize,
  );
  return _toNchw(aligned, kEmbedInputSize, (v) => (v - 127.5) / 127.5);
}

/// Input for the occlusion (segmentation) model plus what is needed to read
/// its output back in face coordinates.
class SegmentationJob {
  /// NHWC RGB in [0, 1], [1, 256, 256, 3].
  final Float32List input;

  /// Square region of the upright true-view frame the input was taken from.
  final Rect crop;

  /// Face geometry in the same true-view coordinates as [crop].
  final FaceGeometry geometry;

  const SegmentationJob(this.input, this.crop, this.geometry);
}

SegmentationJob prepareSegmentation(FaceFrame frame, FaceGeometry g) {
  g = _trueView(frame, g);
  final side = math.max(g.box.width, g.box.height) * 1.6;
  final crop = Rect.fromCenter(center: g.box.center, width: side, height: side);
  final rgb = _renderRect(_FrameSampler(frame), crop, kSegmentationInputSize);
  final input = Float32List(rgb.length);
  for (int i = 0; i < rgb.length; i++) {
    input[i] = rgb[i] / 255.0;
  }
  return SegmentationJob(input, crop, g);
}

/// What the segmentation found on and around the face.
class FaceOcclusion {
  /// Largest blob of a hand, clothing or object ON the face, as a fraction
  /// of the face (eyes-to-chin core plus forehead).
  final double onFace;

  /// Largest blob of an object or hand right BESIDE the face (next to the
  /// cheeks, jaw and chin), as a fraction of the face core.
  final double nearFace;

  const FaceOcclusion(this.onFace, this.nearFace);

  static const clear = FaceOcclusion(0, 0);

  @override
  String toString() =>
      'FaceOcclusion(onFace=${onFace.toStringAsFixed(3)}, '
      'nearFace=${nearFace.toStringAsFixed(3)})';
}

/// Finds hands or objects on the face and right next to it.
///
/// On the face: body skin (a hand), clothing or an accessory anywhere from
/// the eyebrows to the chin, and a hand on the forehead. Beside the face: an
/// accessory/object, or a hand level with the eyes-to-mouth band, next to
/// the cheeks, jaw or chin. Never counted: hair (fringe, beard), background,
/// glasses (accessory or clothing labels in the eye band — thick or dark
/// frames are often labelled clothing), the neck, and headwear — a hijab,
/// cap or turban is recognised as clothing/accessory that spreads over the
/// head above the brows on both sides of the face. Only the largest
/// connected blob counts, so scattered label noise at the edges is ignored.
///
/// [probs] is the segmentation output, NHWC [1, 256, 256, 6].
FaceOcclusion faceOcclusion(Float32List probs, SegmentationJob job) {
  final g = job.geometry;
  final leftEye = g.leftEye, rightEye = g.rightEye;
  final leftMouth = g.leftMouth, rightMouth = g.rightMouth;
  if (leftEye == null ||
      rightEye == null ||
      leftMouth == null ||
      rightMouth == null) {
    return FaceOcclusion.clear;
  }

  const int n = kSegmentationInputSize;
  final double scale = n / job.crop.width;
  Offset toCrop(Offset p) =>
      Offset((p.dx - job.crop.left) * scale, (p.dy - job.crop.top) * scale);
  final eyes = toCrop((leftEye + rightEye) / 2);
  final mouth = toCrop((leftMouth + rightMouth) / 2);
  final double d = (leftEye - rightEye).distance * scale;
  if (d < 1) return FaceOcclusion.clear;

  // Core: cheek to cheek, from just above the eyes to the chin.
  final double top = eyes.dy - 0.35 * d;
  final double bottom = mouth.dy + 0.6 * d;
  final double centerX = (eyes.dx + mouth.dx) / 2;
  final double coreCy = (top + bottom) / 2;
  final double coreAx = 0.8 * d;
  final double coreAy = (bottom - top) / 2;
  // Forehead: only a hand counts here, so caps and fringes never block.
  final double foreCx = eyes.dx;
  final double foreCy = eyes.dy - 0.55 * d;
  final double foreAx = 0.8 * d;
  final double foreAy = 0.55 * d;
  // Ring around the face: beside the cheeks and jaw, down past the chin.
  final double ringBottom = mouth.dy + 1.0 * d;
  final double ringCy = (top + ringBottom) / 2;
  final double ringAx = 1.5 * d;
  final double ringAy = (ringBottom - top) / 2;
  // Tall enough for thick frames and lenses that sit below the eyes, while
  // still ending above the nose base (~0.6 d below the eyes).
  final double eyeBand = 0.5 * d;

  final labels = Uint8List(n * n);
  for (int p = 0, base = 0; p < labels.length; p++, base += _kSegClasses) {
    int label = 0;
    for (int c = 1; c < _kSegClasses; c++) {
      if (probs[base + c] > probs[base + label]) label = c;
    }
    labels[p] = label;
  }

  final headwear = _headwear(labels, n, top - 0.1 * d, centerX, 0.3 * d);

  final onFace = Uint8List(n * n);
  final nearFace = Uint8List(n * n);
  int coreArea = 0, foreheadArea = 0;
  final int y0 = math.max(0, (foreCy - foreAy).floor());
  final int y1 = math.min(n - 1, ringBottom.ceil());
  for (int y = y0; y <= y1; y++) {
    final bool inEyeBand = (y - eyes.dy).abs() <= eyeBand;
    for (int x = 0; x < n; x++) {
      final int p = y * n + x;
      final int label = labels[p];
      final double cx = (x - centerX) / coreAx, cy = (y - coreCy) / coreAy;
      final bool inCore = cx * cx + cy * cy <= 1;
      if (inCore) {
        coreArea++;
        if (headwear[p] == 0 &&
            (label == _kSegBodySkin ||
                ((label == _kSegClothes || label == _kSegOthers) &&
                    !inEyeBand))) {
          onFace[p] = 1;
        }
        continue;
      }
      if (y < top) {
        final double fx = (x - foreCx) / foreAx, fy = (y - foreCy) / foreAy;
        if (fx * fx + fy * fy <= 1) {
          foreheadArea++;
          if (label == _kSegBodySkin) onFace[p] = 1;
        }
        continue;
      }
      final double rx = (x - centerX) / ringAx, ry = (y - ringCy) / ringAy;
      if (rx * rx + ry * ry > 1 || headwear[p] != 0) continue;
      if ((label == _kSegOthers && !inEyeBand) ||
          (label == _kSegBodySkin && y < mouth.dy)) {
        nearFace[p] = 1;
      }
    }
  }
  if (coreArea == 0) return FaceOcclusion.clear;
  return FaceOcclusion(
    _largestBlob(onFace, n) / (coreArea + foreheadArea),
    _largestBlob(nearFace, n) / coreArea,
  );
}

/// Marks clothing/accessory blobs that spread over the head above
/// [aboveY] on both sides of [centerX] (± [sideMargin]): headwear such as a
/// hijab, cap or turban, which frames the face rather than covering it.
Uint8List _headwear(
  Uint8List labels,
  int n,
  double aboveY,
  double centerX,
  double sideMargin,
) {
  final out = Uint8List(n * n);
  final seen = Uint8List(n * n);
  final stack = Int32List(n * n);
  final members = Int32List(n * n);
  bool fabric(int p) => labels[p] == _kSegOthers || labels[p] == _kSegClothes;

  for (int start = 0; start < labels.length; start++) {
    if (seen[start] != 0 || !fabric(start)) continue;
    int top = 0, count = 0;
    bool left = false, right = false;
    stack[top++] = start;
    seen[start] = 1;
    while (top > 0) {
      final int p = stack[--top];
      members[count++] = p;
      final int x = p % n, y = p ~/ n;
      if (y < aboveY) {
        if (x < centerX - sideMargin) left = true;
        if (x > centerX + sideMargin) right = true;
      }
      for (int dy = -1; dy <= 1; dy++) {
        final int ny = y + dy;
        if (ny < 0 || ny >= n) continue;
        for (int dx = -1; dx <= 1; dx++) {
          final int nx = x + dx;
          if (nx < 0 || nx >= n) continue;
          final int q = ny * n + nx;
          if (seen[q] == 0 && fabric(q)) {
            seen[q] = 1;
            stack[top++] = q;
          }
        }
      }
    }
    if (left && right) {
      for (int i = 0; i < count; i++) {
        out[members[i]] = 1;
      }
    }
  }
  return out;
}

/// Size of the largest 8-connected component of 1s in an n×n mask.
int _largestBlob(Uint8List mask, int n) {
  final stack = Int32List(n * n);
  int best = 0;
  for (int start = 0; start < mask.length; start++) {
    if (mask[start] != 1) continue;
    int size = 0, top = 0;
    stack[top++] = start;
    mask[start] = 2;
    while (top > 0) {
      final int i = stack[--top];
      size++;
      final int x = i % n, y = i ~/ n;
      for (int dy = -1; dy <= 1; dy++) {
        final int ny = y + dy;
        if (ny < 0 || ny >= n) continue;
        for (int dx = -1; dx <= 1; dx++) {
          final int nx = x + dx;
          if (nx < 0 || nx >= n) continue;
          final int j = ny * n + nx;
          if (mask[j] == 1) {
            mask[j] = 2;
            stack[top++] = j;
          }
        }
      }
    }
    if (size > best) best = size;
  }
  return best;
}

/// Aligned face JPEG (at most [maxBytes]) for upload. Only called for the
/// frames that are actually sent, so rejected frames never pay for encoding.
Uint8List renderUploadJpeg(
  FaceFrame frame,
  FaceGeometry g, {
  int maxBytes = 10 * 1024,
}) {
  final rgb = _renderAligned(
    _FrameSampler(frame),
    _trueView(frame, g),
    kUploadSize,
  );
  return _encodeUnderLimit(
    img.Image.fromBytes(
      width: kUploadSize,
      height: kUploadSize,
      bytes: rgb.buffer,
      numChannels: 3,
    ),
    maxBytes,
  );
}

/// MiniFASNet crop: box scaled around its centre, scale reduced so the crop
/// fits inside the frame (matches the reference Silent-Face implementation).
Rect _miniFasCrop(Rect box, double scale, _FrameSampler s) {
  final double w = s.uprightW.toDouble();
  final double h = s.uprightH.toDouble();
  final double k = math.min(
    scale,
    math.min((h - 1) / box.height, (w - 1) / box.width),
  );
  final crop = Rect.fromCenter(
    center: box.center,
    width: box.width * k,
    height: box.height * k,
  );
  return Rect.fromLTRB(
    math.max(0, crop.left),
    math.max(0, crop.top),
    math.min(w - 1, crop.right),
    math.min(h - 1, crop.bottom),
  );
}

/// Square crop of side max(w,h)×inc; out-of-frame area is rendered black.
Rect _squareCrop(Rect box, double inc) {
  final double side = math.max(box.width, box.height) * inc;
  return Rect.fromCenter(center: box.center, width: side, height: side);
}

/// 5-point similarity alignment to the ArcFace template, falling back to
/// eyes-only and then to a tight box crop when landmarks are missing.
Uint8List _renderAligned(_FrameSampler s, FaceGeometry g, int outSize) {
  final eyes = _leftRight(g.leftEye, g.rightEye);
  final mouth = _leftRight(g.leftMouth, g.rightMouth);
  final nose = g.nose;

  if (eyes != null && mouth != null && nose != null) {
    final out = _renderFivePoint(s, [
      eyes.$1,
      eyes.$2,
      nose,
      mouth.$1,
      mouth.$2,
    ], outSize);
    if (out != null) return out;
  }
  if (eyes != null) {
    final out = _renderFromEyes(s, eyes.$1, eyes.$2, outSize);
    if (out != null) return out;
  }
  final crop = buildFaceCropRectForFrame(
    g.box,
    Size(s.uprightW.toDouble(), s.uprightH.toDouble()),
  );
  return _renderRect(s, crop, outSize);
}

/// Orders a landmark pair by image x so the aligned face is never flipped,
/// regardless of how the detector labels subject-left vs image-left.
(Offset, Offset)? _leftRight(Offset? a, Offset? b) {
  if (a == null || b == null) return null;
  return a.dx <= b.dx ? (a, b) : (b, a);
}

Uint8List? _renderFivePoint(_FrameSampler s, List<Offset> src, int outSize) {
  final double t = outSize / 112.0;
  final dst = [for (final p in _kRefLandmarks112) p * t];

  double srcCx = 0, srcCy = 0, dstCx = 0, dstCy = 0;
  for (int i = 0; i < 5; i++) {
    srcCx += src[i].dx;
    srcCy += src[i].dy;
    dstCx += dst[i].dx;
    dstCy += dst[i].dy;
  }
  srcCx /= 5;
  srcCy /= 5;
  dstCx /= 5;
  dstCy /= 5;

  double numR = 0, numI = 0, den = 0;
  for (int i = 0; i < 5; i++) {
    final double sx = src[i].dx - srcCx;
    final double sy = src[i].dy - srcCy;
    final double dx = dst[i].dx - dstCx;
    final double dy = dst[i].dy - dstCy;
    numR += sx * dx + sy * dy;
    numI += sx * dy - sy * dx;
    den += sx * sx + sy * sy;
  }
  if (den < 1e-6) return null;

  final double cR = numR / den;
  final double cI = numI / den;
  final double cMagSq = cR * cR + cI * cI;
  if (cMagSq < 1e-9) return null;

  final double transX = dstCx - (cR * srcCx - cI * srcCy);
  final double transY = dstCy - (cI * srcCx + cR * srcCy);

  final out = Uint8List(outSize * outSize * 3);
  int o = 0;
  for (int oy = 0; oy < outSize; oy++) {
    for (int ox = 0; ox < outSize; ox++) {
      final double rx = ox - transX;
      final double ry = oy - transY;
      s.sample(
        (rx * cR + ry * cI) / cMagSq,
        (ry * cR - rx * cI) / cMagSq,
        out,
        o,
      );
      o += 3;
    }
  }
  return out;
}

Uint8List? _renderFromEyes(
  _FrameSampler s,
  Offset leftEye,
  Offset rightEye,
  int outSize,
) {
  final double t = outSize / 112.0;
  final double chinPadding = outSize * 0.06;
  final Offset refLeft =
      const Offset(38.2946, 51.6963) * t - Offset(0, chinPadding);
  final Offset refRight =
      const Offset(73.5318, 51.5014) * t - Offset(0, chinPadding);

  final Offset dSrc = rightEye - leftEye;
  final Offset dDst = refRight - refLeft;
  if (dSrc.distance < 1e-3) return null;

  final double invScale = dSrc.distance / dDst.distance;
  final double angle =
      math.atan2(dDst.dy, dDst.dx) - math.atan2(dSrc.dy, dSrc.dx);
  final double cosInv = math.cos(-angle);
  final double sinInv = math.sin(-angle);

  final out = Uint8List(outSize * outSize * 3);
  int o = 0;
  for (int oy = 0; oy < outSize; oy++) {
    for (int ox = 0; ox < outSize; ox++) {
      final double rx = (ox - refLeft.dx) * invScale;
      final double ry = (oy - refLeft.dy) * invScale;
      s.sample(
        rx * cosInv - ry * sinInv + leftEye.dx,
        rx * sinInv + ry * cosInv + leftEye.dy,
        out,
        o,
      );
      o += 3;
    }
  }
  return out;
}

/// Axis-aligned crop of [rect] (upright coords) stretched to outSize².
Uint8List _renderRect(_FrameSampler s, Rect rect, int outSize) {
  final out = Uint8List(outSize * outSize * 3);
  final double sx = rect.width / outSize;
  final double sy = rect.height / outSize;
  int o = 0;
  for (int oy = 0; oy < outSize; oy++) {
    final double uy = rect.top + (oy + 0.5) * sy;
    for (int ox = 0; ox < outSize; ox++) {
      s.sample(rect.left + (ox + 0.5) * sx, uy, out, o);
      o += 3;
    }
  }
  return out;
}

Float32List _toNchw(
  Uint8List rgb,
  int size,
  double Function(int) normalize, {
  bool bgr = false,
}) {
  final int plane = size * size;
  final out = Float32List(3 * plane);
  final int c0 = bgr ? 2 : 0;
  final int c2 = bgr ? 0 : 2;
  for (int i = 0, p = 0; p < plane; i += 3, p++) {
    out[p] = normalize(rgb[i + c0]);
    out[plane + p] = normalize(rgb[i + 1]);
    out[2 * plane + p] = normalize(rgb[i + c2]);
  }
  return out;
}

/// Reads RGB at upright coordinates straight from the raw frame. Luma (or
/// BGRA) is bilinear, chroma nearest-neighbour. Outside the frame → black.
class _FrameSampler {
  final FaceFrame f;
  final int uprightW;
  final int uprightH;

  _FrameSampler(this.f) : uprightW = f.uprightWidth, uprightH = f.uprightHeight;

  /// [ux], [uy] are true-view upright coordinates (see [_trueView]).
  void sample(double ux, double uy, Uint8List out, int o) {
    if (f.mirrored) ux = (uprightW - 1) - ux;
    final int w = f.width;
    final int h = f.height;
    double rx, ry;
    switch (f.rotation) {
      case 90:
        rx = uy;
        ry = (h - 1) - ux;
        break;
      case 180:
        rx = (w - 1) - ux;
        ry = (h - 1) - uy;
        break;
      case 270:
        rx = (w - 1) - uy;
        ry = ux;
        break;
      default:
        rx = ux;
        ry = uy;
    }

    if (rx < 0 || ry < 0 || rx >= w - 1 || ry >= h - 1) {
      out[o] = 0;
      out[o + 1] = 0;
      out[o + 2] = 0;
      return;
    }

    final int x0 = rx.toInt();
    final int y0 = ry.toInt();
    final double fx = rx - x0;
    final double fy = ry - y0;

    if (f.format == FaceFrameFormat.bgra8888) {
      final p = f.planes[0];
      final int stride = f.rowStrides[0];
      final int i00 = y0 * stride + x0 * 4;
      final int i01 = i00 + stride;
      for (int c = 0; c < 3; c++) {
        final int ch = 2 - c; // BGRA → RGB
        final double top = p[i00 + ch] + (p[i00 + 4 + ch] - p[i00 + ch]) * fx;
        final double bot = p[i01 + ch] + (p[i01 + 4 + ch] - p[i01 + ch]) * fx;
        out[o + c] = (top + (bot - top) * fy).round().clamp(0, 255);
      }
      return;
    }

    final yp = f.planes[0];
    final int yStride = f.rowStrides[0];
    final int i00 = y0 * yStride + x0;
    final int i01 = i00 + yStride;
    final double top = yp[i00] + (yp[i00 + 1] - yp[i00]) * fx;
    final double bot = yp[i01] + (yp[i01 + 1] - yp[i01]) * fx;
    final double y = top + (bot - top) * fy;

    final int cx = (rx + 0.5).toInt();
    final int cy = (ry + 0.5).toInt();
    int u, v;
    if (f.format == FaceFrameFormat.nv21) {
      final int uv = yStride * h + (cy >> 1) * yStride + (cx & ~1);
      v = yp[uv];
      u = yp[uv + 1];
    } else {
      u =
          f.planes[1][(cy >> 1) * f.rowStrides[1] +
              (cx >> 1) * f.pixelStrides[1]];
      v =
          f.planes[2][(cy >> 1) * f.rowStrides[2] +
              (cx >> 1) * f.pixelStrides[2]];
    }

    out[o] = (y + 1.402 * (v - 128)).round().clamp(0, 255);
    out[o + 1] = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
        .round()
        .clamp(0, 255);
    out[o + 2] = (y + 1.772 * (u - 128)).round().clamp(0, 255);
  }
}

double _luma(Uint8List rgb, int i) =>
    0.299 * rgb[i] + 0.587 * rgb[i + 1] + 0.114 * rgb[i + 2];

class _UploadMeasure {
  final Uint8List rgb;
  final double sharpness;
  final double brightness;
  const _UploadMeasure(this.rgb, this.sharpness, this.brightness);
}

/// Renders the face at upload resolution and measures it there, so the
/// sharpness/brightness gates judge exactly the pixels the server receives.
_UploadMeasure _measureUpload(_FrameSampler s, FaceGeometry trueView) {
  final rgb = _renderAligned(s, trueView, kUploadSize);
  const int n = kUploadSize;
  final luma = Float32List(n * n);
  for (int p = 0, i = 0; p < luma.length; p++, i += 3) {
    luma[p] = _luma(rgb, i);
  }

  // Face centre only (template eyes→chin, cheek to cheek): background and
  // hair edges must not make a blurred face look sharp.
  const int x0 = n * 32 ~/ 224, x1 = n * 192 ~/ 224;
  const int y0 = n * 48 ~/ 224, y1 = n * 208 ~/ 224;
  double sum = 0, sumSq = 0, bright = 0;
  int count = 0;
  for (int y = y0; y < y1; y++) {
    for (int x = x0; x < x1; x++) {
      final int p = y * n + x;
      final double lap =
          luma[p - n] + luma[p + n] + luma[p - 1] + luma[p + 1] - 4 * luma[p];
      sum += lap;
      sumSq += lap * lap;
      bright += luma[p];
      count++;
    }
  }
  final double mean = sum / count;
  return _UploadMeasure(rgb, sumSq / count - mean * mean, bright / count);
}

/// Halves an RGB image by averaging 2×2 blocks.
Uint8List _downsample2x(Uint8List rgb, int size) {
  final int half = size ~/ 2;
  final out = Uint8List(half * half * 3);
  for (int y = 0; y < half; y++) {
    for (int x = 0; x < half; x++) {
      final int a = ((2 * y) * size + 2 * x) * 3;
      final int b = a + size * 3;
      final int o = (y * half + x) * 3;
      for (int c = 0; c < 3; c++) {
        out[o + c] =
            (rgb[a + c] + rgb[a + 3 + c] + rgb[b + c] + rgb[b + 3 + c] + 2) >>
            2;
      }
    }
  }
  return out;
}

/// Highest-quality JPEG under [maxBytes]. 4:2:0 chroma (standard for photos)
/// fits ~35% more quality into the same size than the encoder's 4:4:4
/// default, so faces stay free of compression artefacts.
Uint8List _encodeUnderLimit(img.Image src, int maxBytes) {
  Uint8List encode(img.Image image, int quality) =>
      img.encodeJpg(image, quality: quality, chroma: img.JpegChroma.yuv420);

  // Binary search for the highest quality in [60, 92] that fits.
  Uint8List? best;
  int lo = 60, hi = 92;
  while (lo <= hi) {
    final int q = (lo + hi) ~/ 2;
    final bytes = encode(src, q);
    if (bytes.length <= maxBytes) {
      best = bytes;
      lo = q + 1;
    } else {
      hi = q - 1;
    }
  }
  if (best != null) return best;

  // Even quality 60 is too big: shrink instead of degrading further.
  Uint8List smaller = encode(src, 60);
  int size = src.width;
  while (size > 96) {
    size = (size * 0.85).round();
    smaller = encode(img.copyResize(src, width: size, height: size), 60);
    if (smaller.length <= maxBytes) return smaller;
  }
  return smaller;
}
