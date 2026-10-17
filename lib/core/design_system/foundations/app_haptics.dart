import 'package:flutter/services.dart';

/// The kinds of touch the app answers with a tap of the phone.
enum AppHaptic {
  /// A button pressed: a light, firm tap.
  press,

  /// A choice picked or changed, as a chip or a switch: the lightest tick.
  select,

  /// Nothing, for a control that gives its own.
  none,
}

/// The app's haptics, few and quiet: one light tick for a choice, one tap
/// for a button, and a stronger one only when something has succeeded or
/// gone wrong.
abstract final class AppHaptics {
  static void of(AppHaptic kind) => switch (kind) {
    AppHaptic.press => press(),
    AppHaptic.select => select(),
    AppHaptic.none => null,
  };

  static void press() => HapticFeedback.lightImpact();

  static void select() => HapticFeedback.selectionClick();

  /// Something done, as an inspection submitted.
  static void success() => HapticFeedback.mediumImpact();

  /// Something to mind, as a confirmation asked.
  static void warning() => HapticFeedback.lightImpact();

  /// Something that failed.
  static void error() => HapticFeedback.heavyImpact();
}
