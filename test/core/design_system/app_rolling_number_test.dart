import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  Widget number(int value) =>
      Scaffold(body: Center(child: AppRollingNumber(value)));

  testWidgets('a changed figure rolls from the old one to the new', (
    tester,
  ) async {
    await pumpScreen(tester, number(14));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    await pumpScreen(tester, number(15));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-roll: the old figure on its way out, the new one coming in.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('4'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    // The figure that didn't change never moved.
    expect(find.text('1'), findsOneWidget);
    expect(find.bySemanticsLabel('15'), findsOneWidget);
  });
}
