import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/utils/dialog_utils.dart';

void main() {
  testWidgets('the coming soon dialog names the feature and closes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => AppDialogs.showComingSoonDialog(
                  context,
                  feature: 'e Inspection',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('e Inspection'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('COMING SOON'), findsNothing);
  });
}
