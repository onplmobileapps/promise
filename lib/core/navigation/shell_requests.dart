import 'package:flutter/foundation.dart';

/// Asks the signed-in shell, from outside it, to show its alerts, as a
/// tapped notification does. A request made before the shell is up, as on
/// a cold start that goes through sign-in first, waits for it.
abstract final class ShellRequests {
  static final ValueNotifier<int> alerts = ValueNotifier(0);
  static bool _pendingAlerts = false;

  static void openAlerts() {
    _pendingAlerts = true;
    alerts.value++;
  }

  /// Whether the alerts were asked for since last taken.
  static bool takeAlerts() {
    final pending = _pendingAlerts;
    _pendingAlerts = false;
    return pending;
  }
}
