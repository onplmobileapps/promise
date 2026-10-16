import 'package:flutter/widgets.dart';

/// The app's root navigator, for navigating from outside the widget tree
/// (session expiry, notifications, permission dialogs).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
