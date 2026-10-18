import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(() => AppPerformance.debugBudget = RenderBudget.full);

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(text),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('a list\'s rows come in one after another, then stay', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: AppListGroup(
          children: [for (var i = 0; i < 3; i++) AppListRow(title: 'Row $i')],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));
    // The first is on its way before the last has begun.
    expect(opacityOf(tester, 'Row 0'), greaterThan(opacityOf(tester, 'Row 2')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(opacityOf(tester, 'Row $i'), 1);
    }
  });

  testWidgets('on a phone drawing lite, nothing waits to come in', (
    tester,
  ) async {
    AppPerformance.debugBudget = RenderBudget.lite;
    await pumpScreen(
      tester,
      const Scaffold(body: AppReveal(index: 5, child: Text('At once'))),
    );
    expect(opacityOf(tester, 'At once'), 1);
  });

  testWidgets('an empty state draws its mark, ending on the glyph itself', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(
        body: AppEmptyState(glyph: AppGlyphs.bell, title: 'No alerts'),
      ),
    );
    expect(find.byType(AppGlyphDraw), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppGlyphDraw),
        matching: find.byType(AppGlyphIcon),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a row that does something gives under the finger', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: AppListGroup(
          children: [AppListRow(title: 'Press me', onTap: () {})],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final press = await tester.startGesture(
      tester.getCenter(find.text('Press me')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final scale = tester
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.text('Press me'),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
    expect(scale, lessThan(1));
    await press.up();
    await tester.pumpAndSettle();
  });
}
