import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/splash/splash_view.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/screens/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// An update that notes the screen it was offered over.
class _NotedUpdate implements AppUpdate {
  BuildContext? offeredOver;

  @override
  Future<void> start(BuildContext context) async => offeredOver = context;
}

class _FakeUpdater implements AppUpdater {
  _FakeUpdater(this.update);

  final AppUpdate? update;

  @override
  Future<AppUpdate?> check() async => update;
}

/// A store that never answers.
class _SilentUpdater implements AppUpdater {
  @override
  Future<AppUpdate?> check() => Completer<AppUpdate?>().future;
}

void main() {
  setUpAll(loadAppFonts);

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('splash lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        const SplashBody(),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppLogo), findsOneWidget);
    });
  }

  testWidgets('the splash stays light when the app is dark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashBody(),
      ),
    );
    await tester.pump();
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      AppTheme.lightTheme.scaffoldBackgroundColor,
    );
  });

  testWidgets('the lockup sits in the middle of the screen', (tester) async {
    await pumpScreen(tester, const SplashBody(), size: const Size(393, 852));
    final logo = tester.getCenter(find.byType(AppLogo));
    // Centred across, and in the upper middle (the tagline hangs below).
    expect(logo.dx, moreOrLessEquals(393 / 2, epsilon: 0.5));
    expect(logo.dy, inInclusiveRange(852 * 0.3, 852 * 0.55));
  });

  testWidgets('nothing on the splash animates', (tester) async {
    await pumpScreen(tester, const SplashBody());
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('on start', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'auth_token': 'old-session'});
      sl.allowReassignment = true;
      sl.registerFactory<AuthCubit>(() => AuthCubit(FailingAuthRepository()));
      sl.registerSingleton<BiometricAuthenticator>(FakeBiometrics());
    });

    tearDown(sl.reset);

    testWidgets('clears the last session, opens sign-in and offers the '
        'update over it', (tester) async {
      final update = _NotedUpdate();
      await pumpScreen(tester, SplashView(updater: _FakeUpdater(update)));
      expect(find.byType(LoginView), findsNothing);

      await tester.pump(SplashView.minimumDisplay);
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(SplashBody), findsNothing);
      final screen = update.offeredOver!;
      expect(screen.mounted, isTrue);
      expect(ModalRoute.of(screen)?.settings.name, AppRoutes.login);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    testWidgets("a store that doesn't answer doesn't hold the splash", (
      tester,
    ) async {
      await pumpScreen(tester, SplashView(updater: _SilentUpdater()));
      await tester.pump(SplashView.minimumDisplay);
      expect(find.byType(LoginView), findsNothing);
      await tester.pump(SplashView.updateCheckLimit);
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('opens sign-in alone when the app is up to date', (
      tester,
    ) async {
      await pumpScreen(tester, SplashView(updater: _FakeUpdater(null)));
      await tester.pump(SplashView.minimumDisplay);
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });
}
