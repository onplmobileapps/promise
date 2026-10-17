import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/shell/promise_dashboard_view.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/core/navigation/navigator_key.dart';
import 'package:railway_hrms/core/navigation/shell_requests.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/sleepers_rails_sidings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a module opening a screen by name gets that screen, not the '
      'home again', (tester) async {
    await pumpScreen(
      tester,
      Navigator(
        onGenerateRoute: (settings) =>
            shellPageRoute(settings, const Text('the home')),
      ),
    );
    expect(find.text('the home'), findsOneWidget);
    final context = tester.element(find.text('the home'));
    Navigator.of(context).pushNamed(AppRoutes.civilInspectionSleepersRails);
    await tester.pumpAndSettle();
    expect(find.byType(SleepersRailsSidingsScreen), findsOneWidget);
  });

  test('an alerts request waits for the shell and is taken once', () {
    ShellRequests.openAlerts();
    expect(ShellRequests.takeAlerts(), isTrue);
    expect(ShellRequests.takeAlerts(), isFalse);
  });

  testWidgets('signing out shows one sign-in screen with nothing under it, '
      'and forgets the session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'a',
      'refresh_token': 'r',
    });
    var signIns = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Text('signed in'),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            signIns++;
            return const Text('sign in');
          },
        ),
      ),
    );
    await Future.wait([
      StorageService.clearAuthData(),
      StorageService.clearAuthData(),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('sign in'), findsOneWidget);
    expect(signIns, 1);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(await StorageService.getAccessToken(), isNull);
    expect(await StorageService.getRefreshToken(), isNull);
  });
}
