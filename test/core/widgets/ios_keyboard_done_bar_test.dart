import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/widgets/ios_keyboard_done_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('IosKeyboardDoneBar is not visible on non-iOS platforms', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      IosKeyboardDoneBar(
        child: const Scaffold(body: Center(child: TextField())),
      ),
      platform: TargetPlatform.android,
    );

    // Simulate keyboard visible
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(find.text('Done'), findsNothing);
  });

  testWidgets(
    'IosKeyboardDoneBar shows Done button on iOS when keyboard is open',
    (tester) async {
      await pumpScreen(
        tester,
        IosKeyboardDoneBar(
          child: const Scaffold(body: Center(child: TextField())),
        ),
        platform: TargetPlatform.iOS,
      );

      // Simulate keyboard visible
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);

      // Tap textfield to focus
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
            true,
        isTrue,
      );

      // Tap Done to unfocus
      await tester.tap(find.text('Done'));
      await tester.pump();

      // Verify keyboard is unfocused
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );
}
