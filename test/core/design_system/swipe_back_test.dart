import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<int Function()> pump(WidgetTester tester) async {
    var backs = 0;
    await pumpScreen(
      tester,
      Scaffold(
        body: AppSwipeBack(
          onBack: () => backs++,
          child: const SizedBox.expand(child: Text('Page')),
        ),
      ),
    );
    return () => backs;
  }

  testWidgets('a swipe in from the edge goes back', (tester) async {
    final backs = await pump(tester);
    await tester.dragFrom(const Offset(5, 400), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(backs(), 1);
  });

  testWidgets('a short swipe from the edge springs back', (tester) async {
    final backs = await pump(tester);
    await tester.timedDragFrom(
      const Offset(5, 400),
      const Offset(60, 0),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
    expect(backs(), 0);
  });

  testWidgets('a swipe from the middle is left to the page', (tester) async {
    final backs = await pump(tester);
    await tester.dragFrom(const Offset(200, 400), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(backs(), 0);
  });
}
