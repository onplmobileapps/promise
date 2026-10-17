import 'dart:async';

import 'package:flutter/widgets.dart';

/// Runs a live map's updates every [interval], while [start]ed, its screen
/// shows ([visible]) and the app is in front.
///
/// The map is a native view that draws itself; what moves on it moves by
/// the updates the app sends, not by Flutter's frames. A [Ticker] would
/// have Flutter build and composite the whole screen at the display's rate,
/// 90 or 120 times a second, for nothing that changes on the Flutter side;
/// this sends the same updates on a timer and leaves the frames to what
/// really moves, which on a low-end phone is the difference between a map
/// that glides and one that stutters.
class MapLoop {
  MapLoop(this._onTick, {required Duration Function() interval})
    : _interval = interval;

  final void Function() _onTick;
  final Duration Function() _interval;

  bool _running = false;
  bool _visible = true;
  bool _away = false;
  bool _disposed = false;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  final Stopwatch _since = Stopwatch();

  /// Whether it has been started and not stopped.
  bool get isActive => _running;

  void start() {
    if (_running || _disposed) return;
    _running = true;
    _lifecycle ??= AppLifecycleListener(onStateChange: _onAppState);
    _schedule(Duration.zero);
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the map's screen shows; covered by another, it waits.
  set visible(bool visible) {
    if (visible == _visible) return;
    _visible = visible;
    _timer?.cancel();
    _timer = null;
    if (visible) _schedule(Duration.zero);
  }

  void _onAppState(AppLifecycleState state) {
    final away =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (away == _away) return;
    _away = away;
    _timer?.cancel();
    _timer = null;
    if (!away) _schedule(Duration.zero);
  }

  void _schedule(Duration after) {
    if (!_running || !_visible || _away || _disposed || _timer != null) return;
    _timer = Timer(after, _tick);
  }

  void _tick() {
    _timer = null;
    if (!_running || !_visible || _away || _disposed) return;
    _since
      ..reset()
      ..start();
    try {
      _onTick();
    } finally {
      // The next one an interval after this one began, not after it ended,
      // with a moment between for everything else the app does.
      final wait = _interval() - _since.elapsed;
      _schedule(wait < _breather ? _breather : wait);
    }
  }

  static const Duration _breather = Duration(milliseconds: 4);

  void dispose() {
    _disposed = true;
    stop();
    _lifecycle?.dispose();
    _lifecycle = null;
  }
}
