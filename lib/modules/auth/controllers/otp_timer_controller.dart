import 'dart:async';

import 'package:flutter/foundation.dart';

/// Counts down until a one-time code may be sent again.
class OtpTimerController {
  OtpTimerController({this.resendAfter = const Duration(seconds: 30)});

  final Duration resendAfter;

  late final ValueNotifier<int> secondsRemaining = ValueNotifier(
    resendAfter.inSeconds,
  );
  final ValueNotifier<bool> canResend = ValueNotifier(false);
  Timer? _timer;

  void start() {
    secondsRemaining.value = resendAfter.inSeconds;
    canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  /// Runs [onResend] and starts counting again, if the wait is over.
  void resend(VoidCallback onResend) {
    if (!canResend.value) return;
    onResend();
    start();
  }

  void dispose() {
    _timer?.cancel();
    secondsRemaining.dispose();
    canResend.dispose();
  }
}
