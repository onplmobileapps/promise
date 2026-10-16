import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';

/// A looping animation for decoration — a pulse, a radar's sweep, trains
/// running round a picture — that redraws a few dozen times a second
/// rather than every frame the screen can show.
///
/// An [AnimationController] that repeats asks for every frame: on a 120 Hz
/// phone, 120 drawings a second of the whole screen, frosted glass and all,
/// for a ring that looks the same at 30. These loops share one clock that
/// ticks [AppPerformance.loopFps] times a second; each reads the time when
/// it is drawn, so it never falls behind. A loop stands still while its
/// screen is covered (see [AppLoopsMixin]), while the app is away, or once
/// [stop]ped.
class AppLoop extends Animation<double>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  AppLoop({required this.period, bool running = true}) : _running = running {
    _origin = _LoopClock.nowMicros;
    _sync();
  }

  /// Once round.
  final Duration period;

  bool _running;
  bool _visible = true;
  bool _ticking = false;
  bool _disposed = false;

  /// The clock's time when the loop was at 0.
  late int _origin;

  /// Where it stopped, while it isn't ticking.
  double _held = 0;

  @override
  double get value {
    if (!_ticking) return _held;
    final span = period.inMicroseconds;
    return ((_LoopClock.nowMicros - _origin) % span) / span;
  }

  @override
  AnimationStatus get status =>
      _ticking ? AnimationStatus.forward : AnimationStatus.dismissed;

  /// Whether it goes round when it can.
  bool get isRunning => _running;

  /// Goes round from where it is.
  void start() {
    if (_running) return;
    _running = true;
    _sync();
  }

  /// Stands still where it is, or at [at].
  void stop({double? at}) {
    _running = false;
    _sync();
    if (at != null && at != _held) {
      _held = at;
      notifyListeners();
    }
  }

  /// Whether its screen shows; covered, it stands still.
  set visible(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    _sync();
  }

  void _sync() {
    final tick = _running && _visible && !_disposed;
    if (tick == _ticking) return;
    if (tick) {
      // On from where it stood.
      _origin = _LoopClock.nowMicros - (_held * period.inMicroseconds).round();
      _ticking = true;
      _LoopClock.add(this);
      notifyStatusListeners(AnimationStatus.forward);
    } else {
      _held = value;
      _ticking = false;
      _LoopClock.remove(this);
      notifyStatusListeners(AnimationStatus.dismissed);
    }
  }

  /// The clock ticked: drawn again.
  void _tick() => notifyListeners();

  // The listener mixins call these as listeners come and go; the loop
  // runs whether or not anyone listens.
  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}

  void dispose() {
    _disposed = true;
    _sync();
    clearListeners();
    clearStatusListeners();
  }
}

/// The one clock every [AppLoop] goes by: a timer that ticks while any
/// loop runs and the app is in front.
abstract final class _LoopClock {
  static final Stopwatch _watch = Stopwatch()..start();
  static final Set<AppLoop> _loops = {};
  static Timer? _timer;
  static AppLifecycleListener? _lifecycle;
  static bool _away = false;
  static int _fps = 0;

  static int get nowMicros => _watch.elapsedMicroseconds;

  static void add(AppLoop loop) {
    _loops.add(loop);
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) {
        _away = state != AppLifecycleState.resumed;
        _schedule();
      },
    );
    AppPerformance.budget.removeListener(_schedule);
    AppPerformance.budget.addListener(_schedule);
    _schedule();
  }

  static void remove(AppLoop loop) {
    _loops.remove(loop);
    _schedule();
  }

  static void _schedule() {
    final fps = AppPerformance.loopFps;
    final wanted = _loops.isNotEmpty && !_away;
    if (!wanted) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null && fps == _fps) return;
    _timer?.cancel();
    _fps = fps;
    _timer = Timer.periodic(
      Duration(microseconds: 1000000 ~/ fps),
      (_) => _tick(),
    );
  }

  static void _tick() {
    for (final loop in _loops.toList()) {
      loop._tick();
    }
  }

  /// Stops the clock, for tests that end with loops still on screen.
  @visibleForTesting
  static void reset() {
    _timer?.cancel();
    _timer = null;
    _loops.clear();
  }
}

/// Makes [AppLoop]s for a [State] with [loop], stops them while the
/// widget's screen is covered — as [TickerMode] tells, the way a ticker
/// would stop — and disposes of them with it.
mixin AppLoopsMixin<T extends StatefulWidget> on State<T> {
  final List<AppLoop> _ownLoops = [];

  /// A loop [period] long, running unless [running] is false.
  AppLoop loop(Duration period, {bool running = true}) {
    final made = AppLoop(period: period, running: running)..visible = _visible;
    _ownLoops.add(made);
    return made;
  }

  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    for (final each in _ownLoops) {
      each.visible = _visible;
    }
  }

  @override
  void dispose() {
    for (final each in _ownLoops) {
      each.dispose();
    }
    _ownLoops.clear();
    super.dispose();
  }
}

/// Lets a test end with loops still running.
@visibleForTesting
void resetAppLoops() => _LoopClock.reset();
