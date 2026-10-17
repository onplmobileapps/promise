import 'dart:async';
import 'dart:io';

import 'package:face_kit/face_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/app/app.dart';
import 'package:railway_hrms/app/di/injection_container.dart' as di;
import 'package:railway_hrms/core/config/app_env.dart';
import 'package:railway_hrms/core/config/app_flags.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/font_licences.dart';
import 'package:railway_hrms/core/design_system/responsive/app_orientation.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/network/network_monitor.dart';
import 'package:railway_hrms/core/notifications/fcm_service.dart';
import 'package:railway_hrms/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Logs can carry personal data, so a release build prints none.
  if (kReleaseMode) debugPrint = (String? message, {int? wrapWidth}) {};
  // Behind the system bars on every Android version, as Android 15 and later
  // require; screens keep clear of them with SafeArea and MediaQuery padding.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Upright on a phone; a tablet turns.
  unawaited(AppOrientation.apply());
  registerFontLicences();
  // Ready before the first selection moves; glass is painted until then.
  unawaited(LiquidGlassShader.load());
  // Effects as rich as the phone keeps up with, and lighter if it is seen
  // dropping frames.
  AppPerformance.start();
  NetworkMonitor.instance.start();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Crash reports come from release builds only; while developing, errors
  // stay on the console and nothing reaches Crashlytics.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode,
  );
  if (kReleaseMode) {
    FlutterError.onError = (details) {
      // A picture that won't download is the network's trouble, not a
      // crash: it is still reported, but not as one.
      if (details.library == 'image resource service') {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } else {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    // Errors outside Flutter's own callbacks, such as in a Future no one
    // awaited.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  final prefs = await SharedPreferences.getInstance();
  // The testing switches as last left; a release always checks.
  AppFlags.restore(prefs);
  // A phone that was seen to need a lighter budget starts with it.
  AppPerformance.restore(
    read: () => prefs.getString('render_budget'),
    write: (value) => unawaited(prefs.setString('render_budget', value)),
  );
  await di.init();
  // The API's addresses come from here, so it loads before anything can
  // call the API. It is a small bundled file, quick to read.
  await AppEnv.load('.env.prod');
  // Notifications set up in the background, so the splash shows at once.
  final fcmService = FcmService();
  unawaited(
    fcmService.init().catchError(
      (Object error, StackTrace stack) => FirebaseCrashlytics.instance
          .recordError(error, stack, reason: 'FCM setup'),
    ),
  );

  FaceKit.configure(
    FaceKitConfig(
      // Five photos to register a face, two to check it.
      registrationImages: 5,
      verificationImages: 2,
      // No debug preview of the captured faces and their scores: the check
      // in goes straight on after the camera, as in release.
      showPreviewDialog: false,
      onError: (error, stack, reason) => FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason),
      // The design's face camera, around face_kit's camera.
      layout: FaceCaptureScreen.layout,
    ),
  );
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.idleTimeout = const Duration(seconds: 30);
    // Debug builds may go through a proxy that signs its own traffic;
    // release builds check the server's certificate, which is valid.
    if (kDebugMode) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}
