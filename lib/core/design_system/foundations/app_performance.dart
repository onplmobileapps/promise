import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// How much drawing a phone keeps up with.
enum RenderBudget {
  /// Every effect — frosted glass, the liquid lens, trains in 3D — at the
  /// screen's own rate, 90 or 120 frames a second where it has them.
  full,

  /// 60 frames a second, with glass drawn flat — the blur behind it is
  /// most of what a frame costs — but maps in full: a phone that draws the
  /// app well, but not in the 8 ms a 120 Hz screen gives a frame. A steady
  /// 60 looks smoother than a stuttering 120.
  steady,

  /// Flat colour where the effects would blur or bend what is behind them,
  /// maps kept light, at 60 frames a second: what a phone short of memory,
  /// cores or graphics needs to stay smooth.
  lite,
}

/// The phone's [RenderBudget], one for every screen.
///
/// It starts from the phone itself: lite on an Android phone with four
/// cores or fewer, or the memory of a 4 GB phone or less; steady on one
/// with the memory of a 6 GB phone, the usual mid-range one, whose 90 or
/// 120 Hz screen it can't fill with frosted glass. Once [start]ed it
/// watches the frames as the phone is used, measured against its screen's
/// own rate, and steps down when they miss it — from full to steady, then
/// to lite — and stays so until the app starts again.
///
/// A widget reads it with [liteOf], to be built again if it changes,
/// under an [AppPerformanceScope]; anything else reads [lite].
abstract final class AppPerformance {
  static final ValueNotifier<RenderBudget> _budget = ValueNotifier(_forPhone());

  /// The budget now, telling its listeners when it changes.
  static ValueListenable<RenderBudget> get budget => _budget;

  /// Whether the phone is drawing as little as it can: maps light, the
  /// picture cache small, glass flat.
  static bool get lite => _budget.value == RenderBudget.lite;

  /// [lite], for a build that is to run again when it changes.
  static bool liteOf(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<_BudgetScope>()?.budget ??
          _budget.value) ==
      RenderBudget.lite;

  /// Whether glass is drawn flat: its colour without the blur or the lens
  /// behind it, on every phone not drawing in [RenderBudget.full].
  static bool get flat => _budget.value != RenderBudget.full;

  /// [flat], for a build that is to run again when it changes.
  static bool flatOf(BuildContext context) =>
      (context.dependOnInheritedWidgetOfExactType<_BudgetScope>()?.budget ??
          _budget.value) !=
      RenderBudget.full;

  /// How many times a second decoration that loops — pulses, a radar,
  /// trains running round a picture — is drawn: smooth enough on a phone
  /// with drawing to spare, and no more than it needs on the rest; a lite
  /// phone keeps its frames for what the user moves.
  static int get loopFps => switch (_budget.value) {
    RenderBudget.full => 60,
    RenderBudget.steady => 30,
    RenderBudget.lite => 24,
  };

  /// `--dart-define=RENDER_BUDGET=lite` (or `steady`, `full`) tries a
  /// budget out on any phone.
  static const String _forced = String.fromEnvironment('RENDER_BUDGET');

  /// A phone with this many cores or fewer is lite.
  static const int _fewCores = 4;

  /// A phone with no more memory than this, in kB, is lite: a 4 GB phone
  /// has about 3.7 GB of it for Android, a 6 GB one about 5.6 GB.
  static const int _littleMemoryKb = 4608 * 1024;

  /// A phone with no more memory than this, in kB, is steady: a 6 GB
  /// phone, rather than starting in full and stuttering through its first
  /// seconds until the frames show it can't keep up.
  static const int _midMemoryKb = 6656 * 1024;

  /// The picture cache on a lite phone, in bytes, less than Flutter's
  /// 100 MB so memory runs out less often.
  static const int _liteImageCacheBytes = 48 << 20;

  static RenderBudget _forPhone() {
    for (final budget in RenderBudget.values) {
      if (_forced == budget.name) return budget;
    }
    if (kIsWeb) return RenderBudget.full;
    try {
      if (Platform.isAndroid) {
        if (Platform.numberOfProcessors <= _fewCores) return RenderBudget.lite;
        final info = File('/proc/meminfo').readAsStringSync();
        final kb = int.tryParse(
          RegExp(r'MemTotal:\s+(\d+)').firstMatch(info)?.group(1) ?? '',
        );
        if (kb != null && kb <= _littleMemoryKb) return RenderBudget.lite;
        if (kb != null && kb <= _midMemoryKb) return RenderBudget.steady;
      } else if (Platform.isIOS && Platform.numberOfProcessors <= 2) {
        return RenderBudget.lite;
      }
    } catch (_) {
      // Unreadable: the phone is taken at its word, as full.
    }
    return RenderBudget.full;
  }

  /// Fits the picture cache and the screen's rate to the budget and, in
  /// profile and release builds, starts watching the frames. Once, after
  /// the binding is up.
  static void start() {
    _apply();
    _budget.addListener(_apply);
    if (kDebugMode || _forced.isNotEmpty) return;
    _frames.start();
  }

  static void _apply() {
    if (_budget.value != RenderBudget.full) _capRefreshRate();
    if (!lite) return;
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSizeBytes = math.min(
      cache.maximumSizeBytes,
      _liteImageCacheBytes,
    );
  }

  static const MethodChannel _display = MethodChannel('railway_hrms/display');
  static bool _capped = false;

  /// Asks for 60 frames a second where the screen runs faster; Android
  /// only, and only once.
  static void _capRefreshRate() {
    if (_capped || kIsWeb || !Platform.isAndroid) return;
    _capped = true;
    unawaited(
      _display
          .invokeMethod<bool>('preferRefreshRate', {'rate': 60.0})
          .catchError((Object _) => false),
    );
  }

  /// One step down from [budget]: full to steady, steady to lite.
  static void _stepDown() {
    final next = switch (_budget.value) {
      RenderBudget.full => RenderBudget.steady,
      _ => RenderBudget.lite,
    };
    if (kProfileMode) debugPrint('Frames: too slow, drawing ${next.name}');
    _budget.value = next;
    _remember?.call(next);
  }

  /// Keeps what was learned of the phone for its next start.
  static void Function(RenderBudget budget)? _remember;

  /// How long what was learned is trusted: an update can make the app
  /// lighter, so the phone is tried at its best again now and then.
  static const Duration _learnedFor = Duration(days: 14);

  /// Starts from what this phone was last seen to keep up with, read from
  /// [read] as `name@millisecondsSinceEpoch`, and keeps what it learns with
  /// [write]: so a phone that needed a lighter budget starts with it,
  /// rather than stuttering for its first seconds every time.
  static void restore({
    required String? Function() read,
    required void Function(String value) write,
  }) {
    _remember = (budget) =>
        write('${budget.name}@${DateTime.now().millisecondsSinceEpoch}');
    if (_forced.isNotEmpty) return;
    final saved = read();
    if (saved == null) return;
    final at = saved.indexOf('@');
    if (at < 0) return;
    final learned = RenderBudget.values
        .where((b) => b.name == saved.substring(0, at))
        .firstOrNull;
    final ms = int.tryParse(saved.substring(at + 1));
    if (learned == null || ms == null) return;
    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
    if (age > _learnedFor || age.isNegative) return;
    if (learned.index > _budget.value.index) _budget.value = learned;
  }

  /// The screen's refresh rate, as the engine knows it.
  static double get _screenHz {
    final views = PlatformDispatcher.instance.views;
    final hz = views.isEmpty ? 60.0 : views.first.display.refreshRate;
    return hz.isFinite && hz > 0 ? hz : 60.0;
  }

  /// The time a frame has at the budget's rate.
  static Duration get _frameBudget {
    final hz = _budget.value == RenderBudget.full
        ? _screenHz
        : math.min(_screenHz, 60.0);
    return Duration(microseconds: (1e6 / hz).round());
  }

  static final _frames = _FrameWatch(onSlow: _stepDown);

  @visibleForTesting
  static set debugBudget(RenderBudget value) => _budget.value = value;
}

/// Counts the frames that miss their time — measured against the screen's
/// rate at the current budget — by the window, and calls [onSlow] each
/// time two windows in a row miss too many, until the budget is lite.
class _FrameWatch {
  _FrameWatch({required this.onSlow});

  final VoidCallback onSlow;

  /// A frame over its time by this share has missed it, not merely
  /// brushed it.
  static const double _slack = 1.15;

  /// Frames counted at a time: a second or two of movement.
  static const int _window = 120;

  /// The share of a window's frames that, missed, counts against it: one
  /// frame in seven missed is a stutter anyone sees.
  static const double _slowShare = 0.15;

  /// Windows in a row that miss before the budget steps down.
  static const int _strikesToSlow = 2;

  /// Starting up is slow on every phone, pictures decoding and screens
  /// laid out the first time, so its frames don't count.
  static const Duration _warmUp = Duration(seconds: 6);

  bool _watching = false;
  final _sinceStart = Stopwatch();
  int _frames = 0;
  int _slow = 0;
  int _strikes = 0;
  Duration _worstBuild = Duration.zero;
  Duration _worstRaster = Duration.zero;

  void start() {
    if (_watching || AppPerformance.lite) return;
    _watching = true;
    _sinceStart.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void _stop() {
    _watching = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_sinceStart.elapsed < _warmUp) return;
    final limit = AppPerformance._frameBudget * _slack;
    for (final timing in timings) {
      final build = timing.buildDuration;
      final raster = timing.rasterDuration;
      _frames++;
      if (build > limit || raster > limit) _slow++;
      if (build > _worstBuild) _worstBuild = build;
      if (raster > _worstRaster) _worstRaster = raster;
      if (_frames < _window) continue;
      final share = _slow / _frames;
      if (kProfileMode) {
        debugPrint(
          'Frames: ${(share * 100).round()}% of $_frames over '
          '${limit.inMicroseconds / 1000} ms, worst build '
          '${_worstBuild.inMicroseconds / 1000} ms, raster '
          '${_worstRaster.inMicroseconds / 1000} ms',
        );
      }
      _strikes = share >= _slowShare ? _strikes + 1 : 0;
      _frames = 0;
      _slow = 0;
      _worstBuild = Duration.zero;
      _worstRaster = Duration.zero;
      if (_strikes >= _strikesToSlow) {
        _strikes = 0;
        onSlow();
        if (AppPerformance.lite) {
          _stop();
          return;
        }
        // The new budget gives each frame its own time: measured afresh.
        return;
      }
    }
  }
}

/// Builds what reads [AppPerformance.liteOf] or [AppPerformance.flatOf]
/// under it again when the budget changes. Once, over the whole app.
class AppPerformanceScope extends StatelessWidget {
  const AppPerformanceScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<RenderBudget>(
    valueListenable: AppPerformance.budget,
    builder: (context, budget, child) =>
        _BudgetScope(budget: budget, child: child!),
    child: child,
  );
}

class _BudgetScope extends InheritedWidget {
  const _BudgetScope({required this.budget, required super.child});

  final RenderBudget budget;

  @override
  bool updateShouldNotify(_BudgetScope old) => old.budget != budget;
}
