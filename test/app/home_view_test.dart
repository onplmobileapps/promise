import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/app/shell/home_view.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';

import '../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  const ahmed = SignedInUser(name: 'Ahmed Raza', role: 'Assistant Engineer');

  Widget home({
    SignedInUser user = ahmed,
    int hour = 9,
    ValueChanged<String>? onOpenModule,
    VoidCallback? onOpenAlerts,
    VoidCallback? onOpenProfile,
  }) => Scaffold(
    body: HomeView(
      user: user,
      now: () => DateTime(2026, 10, 2, hour),
      onOpenModule: onOpenModule ?? (_) {},
      onOpenAlerts: onOpenAlerts ?? () {},
      onOpenProfile: onOpenProfile ?? () {},
    ),
  );

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('home lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        home(),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppModuleCard), findsNWidgets(4));
    });
  }

  testWidgets('greets by the time of day, with the date and role', (
    tester,
  ) async {
    for (final (hour, greeting) in [
      (9, 'Good Morning, Ahmed'),
      (14, 'Good Afternoon, Ahmed'),
      (19, 'Good Evening, Ahmed'),
    ]) {
      await pumpScreen(tester, home(hour: hour));
      expect(find.text(greeting), findsOneWidget);
    }
    expect(find.text('Friday, October 2'), findsOneWidget);
    expect(find.text('Assistant Engineer'), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
  });

  testWidgets('with no one known yet, it greets plainly', (tester) async {
    await pumpScreen(tester, home(user: SignedInUser.nobody));
    expect(find.text('Good Morning'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('modules sit two to a row, four on a wide screen', (
    tester,
  ) async {
    Future<List<double>> rows(Size size) async {
      await pumpScreen(tester, home(), size: size);
      return [
        for (final card in tester.widgetList(find.byType(AppModuleCard)))
          tester.getTopLeft(find.byWidget(card)).dy,
      ];
    }

    final phone = await rows(const Size(393, 852));
    expect(phone[0], phone[1]);
    expect(phone[2], greaterThan(phone[0]));
    expect(phone[2], phone[3]);

    final tablet = await rows(const Size(1180, 820));
    expect(tablet.toSet(), hasLength(1));
  });

  testWidgets('cards in a row line up, whatever their text', (tester) async {
    await pumpScreen(tester, home(), size: const Size(320, 568), textScale: 2);
    final cards = find.byType(AppModuleCard);
    expect(
      tester.getSize(cards.at(0)).height,
      tester.getSize(cards.at(1)).height,
    );
  });

  testWidgets('modules open in place or full screen', (tester) async {
    final opened = <String>[];
    await pumpScreen(
      tester,
      home(onOpenModule: opened.add),
      routes: {
        AppRoutes.liveTracking: (_) => const Scaffold(body: Text('tracking')),
      },
    );

    await tester.tap(find.text('HRMS'));
    expect(opened, [AppRoutes.hrms]);

    await tester.ensureVisible(find.text('e Inspection'));
    await tester.tap(find.text('e Inspection'));
    await tester.pumpAndSettle();
    expect(opened, [AppRoutes.hrms, AppRoutes.inspection]);

    await tester.tap(find.text('Tracking'));
    await tester.pumpAndSettle();
    expect(find.text('tracking'), findsOneWidget);
    expect(opened, [AppRoutes.hrms, AppRoutes.inspection]);
  });

  testWidgets('the header opens the alerts and the profile', (tester) async {
    var alerts = 0;
    var profile = 0;
    await pumpScreen(
      tester,
      home(onOpenAlerts: () => alerts++, onOpenProfile: () => profile++),
    );
    await tester.tap(find.byTooltip('Alerts'));
    await tester.tap(find.bySemanticsLabel('Your profile'));
    expect(alerts, 1);
    expect(profile, 1);
  });

  testWidgets('nothing on home moves', (tester) async {
    await pumpScreen(tester, home());
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
