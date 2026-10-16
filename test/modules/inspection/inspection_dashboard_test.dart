import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/modules/inspection/dashboard/inspection_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

const _sizes = [Size(320, 568), Size(360, 640), Size(412, 915)];

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  bool withDrafts = true,
}) async {
  SharedPreferences.setMockInitialValues({
    if (withDrafts)
      'inspection_records': jsonEncode([
        {
          'id': 'd1',
          'status': 'in_progress',
          'train': '45-UP Pakistan Express',
          'date': '2026-10-01T09:30:00',
          'payload': {'type': 'footplate'},
        },
        {
          'id': 'd2',
          'status': 'in_progress',
          'train': 'Lahore Junction',
          'date': '2026-09-30T14:00:00',
          'payload': {'type': 'station'},
        },
        {
          'id': 'd3',
          'status': 'completed',
          'train': 'Done already',
          'payload': {'type': 'footplate'},
        },
      ]),
  });
  await pumpScreen(
    tester,
    InspectionDashboardScreen(now: () => DateTime(2026, 10, 5)),
    size: size,
    textScale: textScale,
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(loadAppFonts);

  for (final size in _sizes) {
    testWidgets('inspection dashboard lays out at $size', (tester) async {
      await _pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('October plan'), findsOneWidget);
      expect(find.text('Due 31 Oct'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      // Only drafts still in progress.
      await tester.scrollUntilVisible(
        find.text('Continue where you left off'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Lahore Junction'), findsOneWidget);
      expect(find.text('Done already'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('every kind of inspection can be started', (tester) async {
    await _pumpAt(tester, const Size(412, 915), withDrafts: false);
    expect(find.text('Continue where you left off'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Electrical assets'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    for (final about in [
      'Day and night, from the cab',
      'Premises, signals and facilities',
      'Track patrol by trolley',
      'Condition of the loco',
      'Electrical assets',
    ]) {
      expect(find.text(about), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in _sizes.take(2)) {
    testWidgets('inspection dashboard survives large text at $size', (
      tester,
    ) async {
      await _pumpAt(tester, size, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Electrical assets'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
