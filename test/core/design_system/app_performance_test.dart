import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/tracking/services/map_pacer.dart';

import '../../helpers/pump_app.dart';

void main() {
  tearDown(() => AppPerformance.debugBudget = RenderBudget.full);

  Widget screen() => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppCard.glass(child: Text('Sign in')),
          const AppMedallion(diameter: 120, child: SizedBox()),
          AppLiquidGlass(
            amount: 1,
            child: const SizedBox(width: 80, height: 40),
          ),
        ],
      ),
    ),
    bottomNavigationBar: AppNavigationBar(
      items: const [
        AppNavItem(glyph: AppGlyphs.home, label: 'Home'),
        AppNavItem(glyph: AppGlyphs.navLeave, label: 'Leave'),
      ],
      selectedIndex: 0,
      onSelected: (_) {},
    ),
  );

  int blurs(WidgetTester tester) => tester
      .widgetList<BackdropFilter>(find.byType(BackdropFilter))
      .where((f) => f.enabled)
      .length;

  testWidgets('a phone drawing lite gets solid glass, and back', (
    tester,
  ) async {
    await pumpScreen(tester, screen());
    // The card, the medallion and the bar frost what is behind them.
    expect(blurs(tester), 3);

    // Seen dropping frames: everything drawn again, solid.
    AppPerformance.debugBudget = RenderBudget.lite;
    await tester.pump();
    expect(blurs(tester), 0);
    expect(tester.takeException(), isNull);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);

    AppPerformance.debugBudget = RenderBudget.full;
    await tester.pump();
    expect(blurs(tester), 3);
  });

  testWidgets('a steady phone draws glass flat, loops slower, and keeps its '
      'maps in full', (tester) async {
    await pumpScreen(tester, screen());
    expect(AppPerformance.loopFps, 60);

    AppPerformance.debugBudget = RenderBudget.steady;
    await tester.pump();
    expect(blurs(tester), 0);
    expect(AppPerformance.loopFps, 30);
    expect(AppPerformance.lite, isFalse);
    expect(MapPacer.forPhone().draws3d, isTrue);
  });

  testWidgets('a form on glass keeps its focus and what is typed when the '
      'budget changes', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpScreen(
      tester,
      Scaffold(
        body: Center(
          child: AppCard.glass(child: TextField(controller: controller)),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '65546');
    await tester.pump();
    final field = tester.state(find.byType(TextField));

    AppPerformance.debugBudget = RenderBudget.steady;
    await tester.pump();

    expect(tester.state(find.byType(TextField)), same(field));
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode,
      anyOf(isNull, isA<FocusNode>()),
    );
    expect(tester.testTextInput.isVisible, isTrue);
    expect(controller.text, '65546');
  });

  test('a map on a phone drawing lite starts lighter, its trains flat', () {
    expect(MapPacer.forPhone().draws3d, isTrue);
    AppPerformance.debugBudget = RenderBudget.lite;
    final pacer = MapPacer.forPhone();
    expect(pacer.tier, MapTier.steady);
    expect(pacer.draws3d, isFalse);
  });
}
