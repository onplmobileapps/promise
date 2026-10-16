import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('the document frame', () {
    test('has the shape of an ID card and fits its window', () {
      for (final size in [
        const Size(342, 430),
        const Size(300, 220),
        const Size(600, 400),
      ]) {
        final frame = cardFrameIn(size);
        expect(frame.width / frame.height, closeTo(idCardAspectRatio, 0.001));
        expect((Offset.zero & size).contains(frame.topLeft), isTrue);
        expect((Offset.zero & size).contains(frame.bottomRight), isTrue);
      }
    });
  });

  group('the appearance', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is light until picked, then remembered', () async {
      final first = AppearanceController();
      await first.load();
      expect(first.value, ThemeMode.light);
      await first.pick(ThemeMode.system);
      final again = AppearanceController();
      await again.load();
      expect(again.value, ThemeMode.system);
    });
  });

  group('the navigation bar', () {
    Widget bar({required bool team}) => Scaffold(
      bottomNavigationBar: AppNavigationBar(
        items: [
          const AppNavItem(glyph: AppGlyphs.home, label: 'Home'),
          const AppNavItem(glyph: AppGlyphs.navLeave, label: 'Leave'),
          AppNavItem(glyph: AppGlyphs.navTeam, label: 'Team', visible: team),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
    );

    testWidgets('folds an item away and back', (tester) async {
      await pumpScreen(tester, bar(team: false));
      expect(find.text('Team'), findsNothing);
      await pumpScreen(tester, bar(team: true));
      await tester.pumpAndSettle();
      expect(find.text('Team'), findsOneWidget);
      await pumpScreen(tester, bar(team: false));
      await tester.pumpAndSettle();
      expect(find.text('Team'), findsNothing);
    });

    testWidgets('shows a press on the icon pill, not the whole item', (
      tester,
    ) async {
      await pumpScreen(tester, bar(team: true));
      await tester.pumpAndSettle();
      expect(find.byType(InkResponse), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });
}
