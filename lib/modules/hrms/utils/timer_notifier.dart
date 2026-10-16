import 'dart:async';
import 'package:flutter/material.dart';

/// Where the current attendance session stands, for UI to react to.
enum SessionStatus { notCheckedIn, running, completed }

class TimerNotifier extends ChangeNotifier {
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  SessionStatus get status {
    if (_checkInTime == null) return SessionStatus.notCheckedIn;
    if (_checkOutTime != null) return SessionStatus.completed;
    return SessionStatus.running;
  }

  Duration get elapsed => _elapsed;

  /// Starts, or silently resumes, a live-ticking session anchored at the
  /// real check-in time (not "now") — so re-opening the app mid-day shows
  /// elapsed time since the actual check-in, not from zero.
  ///
  /// Safe to call every time attendance data reloads: it's a no-op if
  /// already ticking for this exact check-in time.
  void start(DateTime checkIn) {
    final localCheckIn = checkIn.toLocal();

    if (_checkInTime == localCheckIn &&
        _checkOutTime == null &&
        _timer != null) {
      return;
    }

    _checkInTime = localCheckIn;
    _checkOutTime = null;
    _timer?.cancel();

    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    _elapsed = DateTime.now().difference(_checkInTime!);
    notifyListeners();
  }

  /// Stops the live ticking and freezes the display at the actual time
  /// spent (checkOut − checkIn). Unlike a hard reset, this keeps the final
  /// duration visible so the user can see how long their session was.
  void stopAt(DateTime checkOut) {
    if (_checkInTime == null) {
      // No known check-in to measure from — nothing meaningful to freeze.
      return;
    }
    _timer?.cancel();
    _timer = null;
    _checkOutTime = checkOut.toLocal();
    _elapsed = _checkOutTime!.difference(_checkInTime!);
    notifyListeners();
  }

  /// Single entry point meant to be called whenever attendance data loads
  /// or refreshes. It figures out whether to (re)start ticking, freeze at
  /// the checkout time, or reset to "not checked in" — so callers don't
  /// need to reason about the state machine themselves.
  void syncWithAttendance({DateTime? checkIn, DateTime? checkOut}) {
    if (checkIn == null) {
      reset();
      return;
    }
    if (checkOut != null) {
      _checkInTime = checkIn.toLocal();
      stopAt(checkOut);
      return;
    }
    start(checkIn);
  }

  /// Full reset back to "not checked in" — e.g. a new day with no
  /// attendance yet, or on logout.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _checkInTime = null;
    _checkOutTime = null;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  /// Kept for backward compatibility with any existing callers — behaves
  /// like [reset]. Prefer [stopAt] where you have the actual checkout time
  /// and want the spent duration to stay visible instead of zeroing out.
  void stop() => reset();

  String get formattedTime {
    final duration = _elapsed.abs();

    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return "${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
