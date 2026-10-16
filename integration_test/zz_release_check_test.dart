// Temporary: signs in on a phone and photographs sign-in, home and the
// bottom bar. The ID and password come from --dart-define.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:railway_hrms/main.dart' as app;

const _id = String.fromEnvironment('CHECK_ID');
const _password = String.fromEnvironment('CHECK_PASSWORD');

/// Real time passing, frames drawn meanwhile.
Future<void> settle(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  }
}

Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 30}) async {
  for (var i = 0; i < seconds * 4; i++) {
    await settle(tester, 250);
    if (finder.evaluate().isNotEmpty) return;
  }
  throw StateError('Not found: $finder');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sign in and look round', (tester) async {
    app.main();
    await waitFor(tester, find.text('Sign in to your workspace'));
    await settle(tester, 3000);
    await binding.takeScreenshot('1_login');

    final fields = find.byType(TextField);
    // Typed straight into the fields: the phone's own keyboard isn't the
    // test's to drive.
    tester.widget<TextField>(fields.at(0)).controller!.text = _id;
    tester.widget<TextField>(fields.at(1)).controller!.text = _password;
    FocusManager.instance.primaryFocus?.unfocus();
    await settle(tester, 1500);
    await binding.takeScreenshot('2_filled');
    final key = find.text('Sign In with Employee ID & Password');
    final plain = find.text('Sign In');
    final button = key.evaluate().isNotEmpty ? key : plain.last;
    await tester.ensureVisible(button);
    await settle(tester, 500);
    await tester.tap(button);
    try {
      await waitFor(tester, find.text('Alerts'), seconds: 45);
    } catch (_) {
      await binding.takeScreenshot('3_stuck');
      rethrow;
    }
    await settle(tester, 4000);
    await binding.takeScreenshot('3_home');

    await tester.tap(find.text('Alerts'));
    for (var i = 0; i < 6; i++) {
      await settle(tester, 60);
      await binding.takeScreenshot('4_bar_$i');
    }
    await settle(tester, 2000);
    await binding.takeScreenshot('5_alerts');
    await tester.tap(find.text('Home'));
    await settle(tester, 2000);
    await binding.takeScreenshot('6_home_again');
  });
}
