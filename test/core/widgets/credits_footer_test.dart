import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/widgets/powered_by_badge.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('the credit and the copyright, for the year it is', (
    tester,
  ) async {
    await pumpScreen(tester, CreditsFooter(now: DateTime(2031, 5, 2)));
    expect(find.text('Designed & Developed by'), findsOneWidget);
    expect(find.text('© 2031 All rights reserved'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Designed and developed by One Network'),
      findsOneWidget,
    );
  });

  for (final width in [320.0, 393.0, 744.0]) {
    testWidgets('the badge sits in the middle, ${width.toInt()} wide', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Center(child: CreditsFooter()),
        size: Size(width, 600),
      );
      final badge = tester.getCenter(find.byType(PoweredByBadge));
      expect(badge.dx, moreOrLessEquals(width / 2, epsilon: 0.5));
      expect(tester.takeException(), isNull);
    });
  }
}
