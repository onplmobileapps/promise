import 'package:flutter/material.dart';
import 'package:railway_hrms/app/routes/route_generator.dart';
import 'package:railway_hrms/app/splash/splash_view.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/theme/app_frame.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/navigator_key.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:railway_hrms/core/widgets/ios_keyboard_done_bar.dart';
import 'package:railway_hrms/core/widgets/network_status_banner.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      // Light, dark or the phone's, as picked on the profile.
      valueListenable: sl<AppearanceController>(),
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateTitle: (context) => context.l10n.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashView(),
        onGenerateRoute: RouteGenerator.generateRoute,
        // Text sized and weighted as set on the profile, over the phone's
        // own setting.
        builder: (context, child) => ValueListenableBuilder<TextLook>(
          valueListenable: sl<TextLookController>(),
          builder: (context, look, _) => AppFrame(
            textScale: look.scale,
            boldText: look.bold,
            displayScale: look.display.scale,
            // The connection banner & iOS keyboard done bar, over every
            // screen, each drawn as richly as the phone keeps up with.
            child: AppPerformanceScope(
              child: NetworkStatusBanner(
                child: IosKeyboardDoneBar(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
