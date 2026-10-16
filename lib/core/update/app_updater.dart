import 'package:flutter/widgets.dart';

/// Keeps the app on the store's latest version.
///
/// [check] never throws: when the store can't be asked, there is simply no
/// update to offer, and the next launch asks again.
abstract interface class AppUpdater {
  /// The newer version on offer, or null when the app is current or the
  /// store can't be reached.
  Future<AppUpdate?> check();
}

/// A newer version the store offers.
abstract interface class AppUpdate {
  /// Takes the user through updating, over the screen of [context].
  Future<void> start(BuildContext context);
}
