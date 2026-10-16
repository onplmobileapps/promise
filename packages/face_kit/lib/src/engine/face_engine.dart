import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' show calloc;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:onnxruntime_v2/onnxruntime_v2.dart';
// ignore: implementation_imports
import 'package:onnxruntime_v2/src/bindings/onnxruntime_bindings_generated.dart'
    as bg;

import '../face_kit.dart';
import 'device_tier.dart';
import 'face_pipeline.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FaceEngine
//
//  Background worker isolates own every ONNX session (via FFI) and do all
//  preprocessing. The UI isolate and the platform thread never run model
//  code, so the preview stays smooth even on 2 GB phones:
//    - main worker: recognition, anti-spoofing, quality gate, upload JPEGs
//    - occlusion worker: face segmentation (the heaviest model), so it never
//      delays the per-frame quality gate
//
//  Every model's large weights are stored as fp16 and cast to fp32 once at
//  load (tool/pack_onnx_weights.py): half the download, fp32 compute on
//  every CPU including 32-bit ARM.
//
//  Models (assets/models/):
//    mbf.onnx               buffalo_sc recognition, [1,3,112,112] → 512-d
//    fas_minifas_v2.onnx    MiniFASNetV2,   [1,3,80,80]   → 3 logits (1 = real)
//    fas_minifas_v1se.onnx  MiniFASNetV1SE, [1,3,80,80]   → 3 logits (1 = real)
//    fas_print_replay.onnx  CelebA-Spoof,   [1,3,128,128] → (real, print, replay)
//    face_quality.onnx      eDifFIQA(T),    [1,3,112,112] → quality (0..1)
//                           (OpenCV Zoo, CC-BY-4.0: Babnik et al., eDifFIQA)
//    face_segmentation.onnx MediaPipe selfie multiclass (Apache-2.0),
//                           [1,256,256,3] → 6-class mask; finds hands or
//                           objects anywhere on the face
//
//  Passive liveness = average real-probability of the two model families,
//  averaged over every frame in the session. No user challenge.
// ─────────────────────────────────────────────────────────────────────────────

const String _kEmbedModel = 'assets/models/mbf.onnx';
const String _kMiniFasV2Model = 'assets/models/fas_minifas_v2.onnx';
const String _kMiniFasV1seModel = 'assets/models/fas_minifas_v1se.onnx';
const String _kPrintReplayModel = 'assets/models/fas_print_replay.onnx';
const String _kQualityModel = 'assets/models/face_quality.onnx';
const String _kSegmentationModel = 'assets/models/face_segmentation.onnx';

/// Largest share of the face that may be covered by a hand or object
/// ([FaceOcclusion.onFace]). Clear faces measure ~0.000–0.003.
const double kMaxFaceOcclusion = 0.005;

/// Largest object/hand blob allowed right beside the face, relative to the
/// face ([FaceOcclusion.nearFace]). Clear faces measure ~0.000–0.006; a toy
/// or pet held against the face ~0.02–0.2.
const double kMaxNearFaceObject = 0.015;

/// Minimum sharpness (see [FacePrep.sharpness]) for a frame to be captured.
/// Sharp faces measure ~120–1300; focus or motion blur drops below ~60–85.
const double kMinFaceSharpness = 80;

/// Acceptable mean face brightness (0..255).
const double kMinFaceBrightness = 45;
const double kMaxFaceBrightness = 235;

/// Minimum face-image quality (eDifFIQA, 0..1) for a frame to be captured.
/// Faces partly covered by hands or objects, or with covered/closed eyes,
/// score below this; clear frontal faces score above it.
const double kMinFaceQuality = 0.55;

/// Session-level live score must reach this to pass.
const double kLiveThreshold = 0.60;

/// Any single model family averaging below this vetoes the session, even if
/// the other family is confident. Catches attacks one family misses.
const double kLiveVetoThreshold = 0.30;

/// Per-tier knobs. Low tier trades a little latency for zero UI contention.
class FaceEngineConfig {
  final DeviceTier tier;
  const FaceEngineConfig(this.tier);

  bool get isLow => tier == DeviceTier.low;

  int get embedThreads => isLow ? 2 : 4;
  int get antiSpoofThreads => isLow ? 1 : 2;
  int get segmentationThreads => 2;

  /// Frames analysed per verification (liveness is averaged over them).
  int get verificationFrames => isLow ? 2 : 3;

  /// Camera stream rate. Lower fps halves the per-frame copy + conversion
  /// work the camera plugin does on low-end devices.
  int? get cameraFps => isLow ? 15 : null;

  /// Minimum gap between face detections.
  Duration get detectInterval =>
      isLow ? const Duration(milliseconds: 90) : Duration.zero;

  /// Delay before preloading models from the dashboard, so loading never
  /// competes with the dashboard's own first frames on slow devices.
  Duration get preloadDelay =>
      isLow ? const Duration(milliseconds: 1500) : Duration.zero;
}

class FaceSample {
  /// Handle for fetching this frame's upload JPEG later.
  final int id;
  final List<double> embedding;

  /// Real-face probability per model family for this frame (0..1).
  final double? miniFasLive;
  final double? printReplayLive;

  final double sharpness;
  final double brightness;

  /// Face-image quality (0..1); null when the quality model is unavailable.
  final double? quality;

  /// Head-pose deviation from frontal (see [FaceGeometry.poseDeviation]).
  final double poseDeviation;
  final int elapsedMs;

  const FaceSample({
    required this.id,
    required this.embedding,
    required this.miniFasLive,
    required this.printReplayLive,
    required this.sharpness,
    required this.brightness,
    required this.quality,
    this.poseDeviation = 0,
    required this.elapsedMs,
  });

  bool get isClearFace => quality == null || quality! >= kMinFaceQuality;
}

/// Live capture gate result for one frame.
class FaceGateResult {
  /// Face-image quality (0..1); null when the quality model is unavailable.
  final double? quality;
  final double sharpness;
  final double brightness;

  const FaceGateResult({
    required this.quality,
    required this.sharpness,
    required this.brightness,
  });
}

class LivenessVerdict {
  final bool isLive;
  final double score;
  final double? miniFas;
  final double? printReplay;

  const LivenessVerdict({
    required this.isLive,
    required this.score,
    this.miniFas,
    this.printReplay,
  });

  @override
  String toString() =>
      'LivenessVerdict(live=$isLive, score=${score.toStringAsFixed(3)}, '
      'miniFas=${miniFas?.toStringAsFixed(3)}, '
      'printReplay=${printReplay?.toStringAsFixed(3)})';
}

/// Aggregates per-frame scores into one decision. Fails closed when no
/// anti-spoof model produced a score.
LivenessVerdict evaluateLiveness(List<FaceSample> samples) {
  double? mean(Iterable<double?> values) {
    final v = values.whereType<double>().toList();
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }

  final miniFas = mean(samples.map((s) => s.miniFasLive));
  final printReplay = mean(samples.map((s) => s.printReplayLive));
  final families = [miniFas, printReplay].whereType<double>().toList();
  if (families.isEmpty) {
    return const LivenessVerdict(isLive: false, score: 0);
  }

  final score = families.reduce((a, b) => a + b) / families.length;
  final vetoed = families.any((f) => f < kLiveVetoThreshold);
  return LivenessVerdict(
    isLive: score >= kLiveThreshold && !vetoed,
    score: score,
    miniFas: miniFas,
    printReplay: printReplay,
  );
}

double cosineSimilarity(List<double> a, List<double> b) {
  double dot = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}

class FaceEngine with WidgetsBindingObserver {
  FaceEngine._();
  static final FaceEngine instance = FaceEngine._();

  final FaceEngineConfig config = FaceEngineConfig(DeviceTierDetector.tier);

  SendPort? _port;
  SendPort? _occlusionPort;
  Future<void>? _starting;
  FaceDetector? _detector;
  int _users = 0;
  int _nextId = 0;
  bool _observing = false;

  bool get isReady => _port != null;

  /// Shared ML Kit detector — creating one per screen costs a model load.
  FaceDetector get detector => _detector ??= FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableTracking: true,
      // Eye-open probabilities: closed or covered eyes block capture.
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
      // Small enough to notice a second person further back in the frame.
      minFaceSize: 0.1,
    ),
  );

  /// Preload from screens that lead to face capture (dashboard). Deferred on
  /// low-end devices so it never competes with that screen's first frames.
  void preload() {
    Future.delayed(config.preloadDelay, () => warmUp().catchError((_) {}));
  }

  /// Idempotent; resolves once every model is loaded and warmed up.
  Future<void> warmUp() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    return _starting ??= _start().catchError((Object e, StackTrace st) {
      _starting = null;
      _report(e, st, 'FaceEngine warm-up failed');
      throw e;
    });
  }

  /// Marks the engine as in use so memory pressure never unloads it mid-scan.
  void acquire() => _users++;
  void release() => _users = math.max(0, _users - 1);

  Future<void> _start() async {
    final sw = Stopwatch()..start();
    Future<TransferableTypedData?> load(String asset) async {
      // Package assets are keyed 'packages/face_kit/…' in a host app and
      // plain 'assets/…' when face_kit itself is the root (its own tests).
      for (final key in ['packages/face_kit/$asset', asset]) {
        try {
          final data = await rootBundle.load(key);
          return TransferableTypedData.fromList([data.buffer.asUint8List()]);
        } catch (_) {}
      }
      debugPrint('⚠️ FaceEngine: missing $asset');
      return null;
    }

    final models = await Future.wait([
      load(_kEmbedModel),
      load(_kMiniFasV2Model),
      load(_kMiniFasV1seModel),
      load(_kPrintReplayModel),
      load(_kQualityModel),
      load(_kSegmentationModel),
    ]);
    if (models[0] == null) throw StateError('Recognition model missing');

    Future<SendPort> spawn(String name) async {
      final handshake = ReceivePort();
      await Isolate.spawn(_workerMain, handshake.sendPort, debugName: name);
      return await handshake.first as SendPort;
    }

    final ports = await Future.wait([
      spawn('FaceEngine'),
      if (models[5] != null) spawn('FaceOcclusion'),
    ]);
    final results = await Future.wait([
      _call(
        ports[0],
        (reply) => _InitMsg(
          reply,
          embed: models[0],
          miniFasV2: models[1],
          miniFasV1se: models[2],
          printReplay: models[3],
          quality: models[4],
          embedThreads: config.embedThreads,
          antiSpoofThreads: config.antiSpoofThreads,
        ),
      ),
      if (ports.length > 1)
        _call(
          ports[1],
          (reply) => _InitMsg(
            reply,
            segmentation: models[5],
            antiSpoofThreads: config.segmentationThreads,
          ),
        ),
    ]);
    if (results[0] is! Map) {
      throw StateError('FaceEngine init failed: ${results[0]}');
    }
    _port = ports[0];
    if (results.length > 1) {
      if (results[1] is Map) {
        _occlusionPort = ports[1];
      } else {
        _report(
          StateError('${results[1]}'),
          StackTrace.current,
          'FaceEngine: occlusion model unavailable',
        );
      }
    }
    debugPrint(
      '✅ FaceEngine ready in ${sw.elapsedMilliseconds} ms '
      '(tier=${config.tier.name}, antiSpoof=${(results[0] as Map)['antiSpoof']}, '
      'occlusion=${_occlusionPort != null})',
    );
  }

  /// Full analysis (recognition + anti-spoofing) of one frame. Pass the
  /// [quality] already measured by [faceQuality] to avoid computing it twice.
  Future<FaceSample> analyze(
    FaceFrame frame,
    FaceGeometry geometry, {
    double? quality,
  }) async {
    await warmUp();
    final id = _nextId++;
    final result = await _call(
      _port!,
      (reply) => _AnalyzeMsg(reply, id, frame, geometry, quality),
    );
    if (result is FaceSample) return result;
    throw StateError('Face analysis failed: $result');
  }

  /// Quality, sharpness and brightness of one frame, used to accept or
  /// reject frames while the camera is open (~10–40 ms).
  Future<FaceGateResult> faceGate(
    FaceFrame frame,
    FaceGeometry geometry,
  ) async {
    await warmUp();
    final result = await _call(
      _port!,
      (reply) => _QualityMsg(reply, frame, geometry),
    );
    if (result is FaceGateResult) return result;
    throw StateError('Face gate failed: $result');
  }

  /// Hands or objects on and beside the face, from the segmentation worker.
  /// Null when the occlusion model is unavailable.
  Future<FaceOcclusion?> faceOcclusion(
    FaceFrame frame,
    FaceGeometry geometry,
  ) async {
    await warmUp();
    final port = _occlusionPort;
    if (port == null) return null;
    final result = await _call(
      port,
      (reply) => _OcclusionMsg(reply, frame, geometry),
    );
    if (result is FaceOcclusion) return result;
    throw StateError('Face occlusion failed: $result');
  }

  /// Upload JPEGs for previously analysed frames, in the order given.
  Future<List<Uint8List>> uploadImages(List<int> ids) async {
    final result = await _call(
      _port!,
      (reply) => _UploadMsg(reply, ids, FaceKit.config.maxUploadBytes),
    );
    if (result is List<Uint8List>) return result;
    throw StateError('Upload encoding failed: $result');
  }

  /// Frees native model memory. Reloaded automatically on next use.
  Future<void> shutdown() async {
    final ports = [_port, _occlusionPort];
    _port = null;
    _occlusionPort = null;
    _starting = null;
    await _detector?.close();
    _detector = null;
    for (final port in ports) {
      if (port != null) await _call(port, (reply) => _DisposeMsg(reply));
    }
  }

  @override
  void didHaveMemoryPressure() {
    if (_users == 0 && _port != null) {
      debugPrint('🧹 FaceEngine: releasing models under memory pressure');
      unawaited(shutdown());
    }
  }

  static void _report(Object e, StackTrace st, String reason) =>
      FaceKit.reportError(e, st, reason);

  static Future<Object?> _call(
    SendPort port,
    Object Function(SendPort reply) build,
  ) async {
    final reply = ReceivePort();
    port.send(build(reply.sendPort));
    final result = await reply.first;
    reply.close();
    return result;
  }
}

// ─── Worker messages ─────────────────────────────────────────────────────────

/// Which models a worker loads; each worker gets only the ones it runs.
class _InitMsg {
  final SendPort reply;
  final TransferableTypedData? embed;
  final TransferableTypedData? miniFasV2;
  final TransferableTypedData? miniFasV1se;
  final TransferableTypedData? printReplay;
  final TransferableTypedData? quality;
  final TransferableTypedData? segmentation;
  final int embedThreads;

  /// Threads for every model other than recognition.
  final int antiSpoofThreads;

  const _InitMsg(
    this.reply, {
    this.embed,
    this.miniFasV2,
    this.miniFasV1se,
    this.printReplay,
    this.quality,
    this.segmentation,
    this.embedThreads = 1,
    required this.antiSpoofThreads,
  });
}

class _AnalyzeMsg {
  final SendPort reply;
  final int id;
  final FaceFrame frame;
  final FaceGeometry geometry;
  final double? quality;
  const _AnalyzeMsg(
    this.reply,
    this.id,
    this.frame,
    this.geometry,
    this.quality,
  );
}

class _QualityMsg {
  final SendPort reply;
  final FaceFrame frame;
  final FaceGeometry geometry;
  const _QualityMsg(this.reply, this.frame, this.geometry);
}

class _OcclusionMsg {
  final SendPort reply;
  final FaceFrame frame;
  final FaceGeometry geometry;
  const _OcclusionMsg(this.reply, this.frame, this.geometry);
}

class _UploadMsg {
  final SendPort reply;
  final List<int> ids;
  final int maxBytes;
  const _UploadMsg(this.reply, this.ids, this.maxBytes);
}

class _DisposeMsg {
  final SendPort reply;
  const _DisposeMsg(this.reply);
}

// ─── Worker isolate ──────────────────────────────────────────────────────────

/// Frames kept for lazy upload encoding (enough for one registration).
const int _kFrameCacheSize = 12;

void _workerMain(SendPort mainPort) {
  final port = ReceivePort();
  mainPort.send(port.sendPort);

  _Models? models;
  final frames = <int, (FaceFrame, FaceGeometry)>{};

  port.listen((msg) {
    try {
      if (msg is _InitMsg) {
        models ??= _Models.load(msg);
        msg.reply.send({'antiSpoof': models!.hasAntiSpoof});
      } else if (msg is _AnalyzeMsg) {
        frames[msg.id] = (msg.frame, msg.geometry);
        while (frames.length > _kFrameCacheSize) {
          frames.remove(frames.keys.first);
        }
        msg.reply.send(
          models!.analyze(msg.id, msg.frame, msg.geometry, msg.quality),
        );
      } else if (msg is _QualityMsg) {
        msg.reply.send(models!.gate(msg.frame, msg.geometry));
      } else if (msg is _OcclusionMsg) {
        msg.reply.send(models!.occlusion(msg.frame, msg.geometry));
      } else if (msg is _UploadMsg) {
        msg.reply.send(<Uint8List>[
          for (final id in msg.ids)
            if (frames[id] case (final frame, final geometry))
              renderUploadJpeg(frame, geometry, maxBytes: msg.maxBytes),
        ]);
      } else if (msg is _DisposeMsg) {
        models?.release();
        models = null;
        frames.clear();
        msg.reply.send(true);
        port.close();
        Isolate.exit();
      }
    } catch (e, st) {
      final reply = switch (msg) {
        _InitMsg(:final reply) => reply,
        _AnalyzeMsg(:final reply) => reply,
        _QualityMsg(:final reply) => reply,
        _OcclusionMsg(:final reply) => reply,
        _UploadMsg(:final reply) => reply,
        _DisposeMsg(:final reply) => reply,
        _ => null,
      };
      reply?.send('$e\n$st');
    }
  });
}

class _Models {
  final OrtSession? embed;
  final OrtSession? miniFasV2;
  final OrtSession? miniFasV1se;
  final OrtSession? printReplay;
  final OrtSession? faceQualityModel;
  final OrtSession? segmentation;
  final OrtRunOptions runOptions = OrtRunOptions();

  _Models._(
    this.embed,
    this.miniFasV2,
    this.miniFasV1se,
    this.printReplay,
    this.faceQualityModel,
    this.segmentation,
  );

  bool get hasAntiSpoof =>
      (miniFasV2 != null && miniFasV1se != null) || printReplay != null;

  static _Models load(_InitMsg msg) {
    OrtEnv.instance.init();

    OrtSession open(TransferableTypedData bytes, int threads) {
      final options = OrtSessionOptions()
        ..setIntraOpNumThreads(threads)
        ..setInterOpNumThreads(1)
        ..setSessionExecutionMode(OrtSessionExecutionMode.ortSequential)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      try {
        return OrtSession.fromBuffer(
          bytes.materialize().asUint8List(),
          options,
        );
      } finally {
        options.release();
      }
    }

    OrtSession? openOptional(TransferableTypedData? bytes) {
      if (bytes == null) return null;
      try {
        return open(bytes, msg.antiSpoofThreads);
      } catch (e) {
        debugPrint('⚠️ FaceEngine: optional model failed to load: $e');
        return null;
      }
    }

    final embed = msg.embed;
    final segmentation = msg.segmentation;
    final models = _Models._(
      embed == null ? null : open(embed, msg.embedThreads),
      openOptional(msg.miniFasV2),
      openOptional(msg.miniFasV1se),
      openOptional(msg.printReplay),
      openOptional(msg.quality),
      // Required in the occlusion worker: failing here reports the model
      // as unavailable instead of silently skipping the check.
      segmentation == null ? null : open(segmentation, msg.antiSpoofThreads),
    );
    models._warmUp();
    return models;
  }

  /// First inference allocates arenas — do it now, not on the user's face.
  void _warmUp() {
    _runOptional(embed, Float32List(3 * 112 * 112), const [1, 3, 112, 112]);
    _runOptional(
      segmentation,
      Float32List(kSegmentationInputSize * kSegmentationInputSize * 3),
      const [1, kSegmentationInputSize, kSegmentationInputSize, 3],
    );
    _runOptional(faceQualityModel, Float32List(3 * 112 * 112), const [
      1,
      3,
      112,
      112,
    ]);
    _runOptional(miniFasV2, Float32List(3 * 80 * 80), const [1, 3, 80, 80]);
    _runOptional(miniFasV1se, Float32List(3 * 80 * 80), const [1, 3, 80, 80]);
    _runOptional(printReplay, Float32List(3 * 128 * 128), const [
      1,
      3,
      128,
      128,
    ]);
  }

  FaceOcclusion occlusion(FaceFrame frame, FaceGeometry geometry) {
    final job = prepareSegmentation(frame, geometry);
    final probs = _run(segmentation!, job.input, const [
      1,
      kSegmentationInputSize,
      kSegmentationInputSize,
      3,
    ]);
    return faceOcclusion(probs, job);
  }

  FaceGateResult gate(FaceFrame frame, FaceGeometry geometry) {
    final input = prepareGate(frame, geometry);
    return FaceGateResult(
      quality: _qualityOf(input.qualityInput),
      sharpness: input.sharpness,
      brightness: input.brightness,
    );
  }

  double? _qualityOf(Float32List alignedInput) {
    final out = _runOptional(faceQualityModel, alignedInput, const [
      1,
      3,
      112,
      112,
    ]);
    return out?.first;
  }

  FaceSample analyze(
    int id,
    FaceFrame frame,
    FaceGeometry geometry,
    double? knownQuality,
  ) {
    final sw = Stopwatch()..start();
    final prep = prepareFace(frame, geometry);

    final v2 = _runOptional(miniFasV2, prep.miniFasV2Input, const [
      1,
      3,
      80,
      80,
    ]);
    final v1se = _runOptional(miniFasV1se, prep.miniFasV1seInput, const [
      1,
      3,
      80,
      80,
    ]);
    final pr = _runOptional(printReplay, prep.printReplayInput, const [
      1,
      3,
      128,
      128,
    ]);
    final miniFasParts = [
      if (v2 != null) _softmax(v2)[1],
      if (v1se != null) _softmax(v1se)[1],
    ];

    return FaceSample(
      id: id,
      embedding: _l2Normalize(
        _run(embed!, prep.embedInput, const [1, 3, 112, 112]),
      ),
      miniFasLive: miniFasParts.isEmpty
          ? null
          : miniFasParts.reduce((a, b) => a + b) / miniFasParts.length,
      printReplayLive: pr == null ? null : _softmax(pr)[0],
      sharpness: prep.sharpness,
      brightness: prep.brightness,
      quality: knownQuality ?? _qualityOf(prep.embedInput),
      poseDeviation: geometry.poseDeviation,
      elapsedMs: sw.elapsedMilliseconds,
    );
  }

  Float32List? _runOptional(
    OrtSession? session,
    Float32List input,
    List<int> shape,
  ) {
    if (session == null) return null;
    try {
      return _run(session, input, shape);
    } catch (e) {
      debugPrint('⚠️ Optional model inference failed: $e');
      return null;
    }
  }

  /// Runs [session] on one float tensor and returns its first output. Data
  /// moves in and out of native memory as bulk copies, never element by
  /// element, which matters for the 196k-value segmentation input.
  Float32List _run(OrtSession session, Float32List input, List<int> shape) {
    final tensor = _floatTensor(input, shape);
    try {
      final outputs = session.run(
        runOptions,
        {session.inputNames.first: tensor},
        [session.outputNames.first],
      );
      try {
        return _readFloats(outputs.first!);
      } finally {
        for (final o in outputs) {
          o?.release();
        }
      }
    } finally {
      tensor.release();
    }
  }

  void release() {
    for (final s in [
      embed,
      miniFasV2,
      miniFasV1se,
      printReplay,
      faceQualityModel,
      segmentation,
    ]) {
      s?.release();
    }
    runOptions.release();
    OrtEnv.instance.release();
  }

  static List<double> _softmax(List<double> logits) {
    final double maxLogit = logits.reduce(math.max);
    final exps = [for (final l in logits) math.exp(l - maxLogit)];
    final double sum = exps.reduce((a, b) => a + b);
    return [for (final e in exps) e / sum];
  }

  static List<double> _l2Normalize(List<double> v) {
    double sum = 0;
    for (final x in v) {
      sum += x * x;
    }
    final norm = math.sqrt(sum);
    if (norm < 1e-10) throw StateError('Invalid face embedding: zero vector');
    return [for (final x in v) x / norm];
  }
}

// ─── Native tensor I/O ───────────────────────────────────────────────────────

/// Float tensor backed by native memory holding a bulk copy of [data]. The
/// memory is freed by [OrtValueTensor.release].
OrtValueTensor _floatTensor(Float32List data, List<int> shape) {
  final api = OrtEnv.instance.ortApiPtr.ref;
  final dataPtr = calloc<ffi.Float>(data.length);
  dataPtr.asTypedList(data.length).setAll(0, data);
  final shapePtr = calloc<ffi.Int64>(shape.length);
  shapePtr.asTypedList(shape.length).setAll(0, shape);
  final infoPtr = calloc<ffi.Pointer<bg.OrtMemoryInfo>>();
  final valuePtr = calloc<ffi.Pointer<bg.OrtValue>>();
  try {
    OrtStatus.checkOrtStatus(
      api.AllocatorGetInfo.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<bg.OrtAllocator>,
          ffi.Pointer<ffi.Pointer<bg.OrtMemoryInfo>>,
        )
      >()(OrtAllocator.instance.ptr, infoPtr),
    );
    OrtStatus.checkOrtStatus(
      api.CreateTensorWithDataAsOrtValue.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<bg.OrtMemoryInfo>,
          ffi.Pointer<ffi.Void>,
          int,
          ffi.Pointer<ffi.Int64>,
          int,
          int,
          ffi.Pointer<ffi.Pointer<bg.OrtValue>>,
        )
      >()(
        infoPtr.value,
        dataPtr.cast(),
        data.length * 4,
        shapePtr,
        shape.length,
        ONNXTensorElementDataType.float.value,
        valuePtr,
      ),
    );
    return OrtValueTensor(valuePtr.value, dataPtr.cast());
  } catch (_) {
    calloc.free(dataPtr);
    rethrow;
  } finally {
    calloc.free(shapePtr);
    calloc.free(infoPtr);
    calloc.free(valuePtr);
  }
}

/// Copies a float output tensor out of native memory in one go.
Float32List _readFloats(OrtValue value) {
  final api = OrtEnv.instance.ortApiPtr.ref;
  final infoPtr = calloc<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>();
  final countPtr = calloc<ffi.Size>();
  final dataPtr = calloc<ffi.Pointer<ffi.Void>>();
  try {
    OrtStatus.checkOrtStatus(
      api.GetTensorTypeAndShape.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<bg.OrtValue>,
          ffi.Pointer<ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>>,
        )
      >()(value.ptr, infoPtr),
    );
    try {
      OrtStatus.checkOrtStatus(
        api.GetTensorShapeElementCount.asFunction<
          bg.OrtStatusPtr Function(
            ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>,
            ffi.Pointer<ffi.Size>,
          )
        >()(infoPtr.value, countPtr),
      );
    } finally {
      api.ReleaseTensorTypeAndShapeInfo.asFunction<
        void Function(ffi.Pointer<bg.OrtTensorTypeAndShapeInfo>)
      >()(infoPtr.value);
    }
    OrtStatus.checkOrtStatus(
      api.GetTensorMutableData.asFunction<
        bg.OrtStatusPtr Function(
          ffi.Pointer<bg.OrtValue>,
          ffi.Pointer<ffi.Pointer<ffi.Void>>,
        )
      >()(value.ptr, dataPtr),
    );
    return Float32List.fromList(
      dataPtr.value.cast<ffi.Float>().asTypedList(countPtr.value),
    );
  } finally {
    calloc.free(infoPtr);
    calloc.free(countPtr);
    calloc.free(dataPtr);
  }
}
