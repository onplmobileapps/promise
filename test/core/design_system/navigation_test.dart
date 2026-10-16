import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  group('AppNavigationBar', () {
    const items = [
      AppNavItem(glyph: AppGlyphs.home, label: 'Home'),
      AppNavItem(glyph: AppGlyphs.train, label: 'Trains'),
      AppNavItem(glyph: AppGlyphs.bell, label: 'Alerts'),
      AppNavItem(glyph: AppGlyphs.profile, label: 'Profile'),
    ];

    Future<void> pumpBar(
      WidgetTester tester, {
      required int? selected,
      required ValueChanged<int> onSelected,
      VoidCallback? onAction,
      Size size = const Size(393, 852),
      double textScale = 1,
    }) => pumpScreen(
      tester,
      Scaffold(
        extendBody: true,
        body: const SizedBox.expand(),
        bottomNavigationBar: AppNavigationBar(
          items: items,
          selectedIndex: selected,
          onSelected: onSelected,
          action: AppActionKey(
            icon: const Icon(Icons.face_rounded),
            label: 'Check in',
            onPressed: onAction ?? () {},
            ringColor: Colors.white,
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );

    testWidgets('items either side of the action, each selectable', (
      tester,
    ) async {
      final picked = <int>[];
      await pumpBar(tester, selected: 0, onSelected: picked.add);
      final action = tester.getCenter(find.byType(AppActionKey)).dx;
      expect(tester.getCenter(find.text('Trains')).dx, lessThan(action));
      expect(tester.getCenter(find.text('Alerts')).dx, greaterThan(action));
      for (final label in ['Home', 'Trains', 'Alerts', 'Profile']) {
        await tester.tap(find.text(label));
      }
      expect(picked, [0, 1, 2, 3]);
    });

    testWidgets('the selected item says so to a screen reader', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester, selected: 2, onSelected: (_) {});
      expect(
        tester.getSemantics(find.bySemanticsLabel('Alerts')),
        isSemantics(
          label: 'Alerts',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(
          label: 'Home',
          isButton: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('all of the raised action can be tapped, its top too', (
      tester,
    ) async {
      var taps = 0;
      await pumpBar(
        tester,
        selected: 0,
        onSelected: (_) {},
        onAction: () {
          taps++;
        },
      );
      final key = tester.getRect(find.byType(AppActionKey));
      final bar = tester.getRect(find.byType(AppNavigationBar));
      // The action has a slot as wide as an item's, so it shows whole.
      expect(key.width, greaterThanOrEqualTo(AppSizes.navActionSize));
      // It stands above the painted bar, but inside the bar's own box.
      expect(key.top, moreOrLessEquals(bar.top));
      await tester.tapAt(key.topCenter + const Offset(0, 3));
      await tester.tapAt(key.center);
      expect(taps, 2);
    });

    testWidgets('the glass lens can be dragged to another item', (
      tester,
    ) async {
      final picked = <int>[];
      await pumpBar(tester, selected: 0, onSelected: picked.add);
      final home = tester.getCenter(find.text('Home'));
      final profile = tester.getCenter(find.text('Profile'));
      await tester.dragFrom(home, Offset(profile.dx - home.dx, 0));
      await tester.pumpAndSettle();
      expect(picked, [3]);
    });

    testWidgets('dropped over the action, the lens goes back', (tester) async {
      final picked = <int>[];
      await pumpBar(tester, selected: 0, onSelected: picked.add);
      final home = tester.getCenter(find.text('Home'));
      final action = tester.getCenter(find.byType(AppActionKey));
      await tester.dragFrom(home, Offset(action.dx - home.dx, 0));
      await tester.pumpAndSettle();
      expect(picked, isEmpty);
    });

    testWidgets('fits narrow phones and large text', (tester) async {
      await pumpBar(
        tester,
        selected: 3,
        onSelected: (_) {},
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays clear of the system navigation', (tester) async {
      await pumpBar(tester, selected: 0, onSelected: (_) {});
      // The notched test view keeps 34 at the foot.
      expect(
        tester.getBottomLeft(find.text('Home')).dy,
        lessThanOrEqualTo(852 - 34),
      );
    });
  });

  group('AppActionKey', () {
    testWidgets('sinks while pressed, without changing size', (tester) async {
      await pumpScreen(
        tester,
        Center(
          child: AppActionKey(
            icon: const Icon(Icons.face_rounded),
            label: 'Check in',
            onPressed: () {},
          ),
        ),
      );
      final size = tester.getSize(find.byType(AppActionKey));
      final face = find.descendant(
        of: find.byType(AppActionKey),
        matching: find.byType(DecoratedBox),
      );
      final restTop = tester.getTopLeft(face.first).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppActionKey)),
      );
      await tester.pump();
      expect(tester.getTopLeft(face.first).dy, greaterThan(restTop));
      expect(tester.getSize(find.byType(AppActionKey)), size);
      await gesture.up();
    });

    testWidgets('while loading it shows a spinner and ignores taps', (
      tester,
    ) async {
      var taps = 0;
      await pumpScreen(
        tester,
        Center(
          child: AppActionKey(
            icon: const Icon(Icons.face_rounded),
            label: 'Check in',
            isLoading: true,
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppActionKey));
      expect(taps, 0);
    });
  });

  testWidgets('AppGrid lines up a row whatever each cell holds', (
    tester,
  ) async {
    const cells = [Key('short'), Key('tall'), Key('last')];
    await pumpScreen(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: AppGrid(
          columns: 2,
          children: [
            SizedBox(key: Key('short'), height: 40),
            SizedBox(key: Key('tall'), height: 120),
            SizedBox(key: Key('last'), height: 10),
          ],
        ),
      ),
    );
    Size sizeOf(Key key) => tester.getSize(find.byKey(key));
    expect(sizeOf(cells[0]).height, 120);
    expect(sizeOf(cells[1]).height, 120);
    // A short last row keeps its cell the width of the others.
    expect(sizeOf(cells[2]).width, sizeOf(cells[0]).width);
  });

  test('AppAvatar takes up to two initials', () {
    expect(AppAvatar.initialsOf('Ahmed Raza'), 'AR');
    expect(AppAvatar.initialsOf('  muhammad   ali khan '), 'MA');
    expect(AppAvatar.initialsOf('Bilal'), 'B');
    expect(AppAvatar.initialsOf(''), '');
  });

  testWidgets('AppTileButton is a full tap target with a count badge', (
    tester,
  ) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(
        child: AppTileButton(
          icon: const AppGlyphIcon(AppGlyphs.bell),
          tooltip: 'Alerts',
          count: 3,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(AppTileButton)),
      const Size.square(AppSizes.minTapTarget),
    );
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byTooltip('Alerts'));
    expect(taps, 1);
  });
}
