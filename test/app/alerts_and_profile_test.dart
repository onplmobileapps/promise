import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/app/notifications/app_alert.dart';
import 'package:railway_hrms/app/notifications/notification_view.dart';
import 'package:railway_hrms/app/session/signed_in_user.dart';
import 'package:railway_hrms/app/settings/settings_view.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/profile/profile_face.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/core/theme/app_theme.dart';
import 'package:railway_hrms/core/theme/appearance_controller.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// The switch on the row titled [title].
Finder _switchOf(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(AppListRow)),
  matching: find.byType(AppSwitch),
);

void main() {
  setUpAll(loadAppFonts);

  final now = DateTime(2026, 10, 2, 10, 22);
  Widget alerts() => NotificationView(now: () => now);

  group('alerts', () {
    for (final (name, size, scale, platform) in layoutMatrix()) {
      testWidgets('lay out on $name', (tester) async {
        await pumpScreen(
          tester,
          alerts(),
          size: size,
          textScale: scale,
          platform: platform,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('group by day, newest first, with the case on top', (
      tester,
    ) async {
      await pumpScreen(tester, alerts());
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.byType(AppProgressSteps), findsOneWidget);
      expect(find.text('1 NEW · FRI 02 OCT'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('TODAY')).dy,
        lessThan(tester.getTopLeft(find.text('YESTERDAY')).dy),
      );
    });

    testWidgets('mark all read leaves nothing new', (tester) async {
      await pumpScreen(tester, alerts());
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
      expect(find.text('FRI 02 OCT'), findsOneWidget);
      expect(find.text('Mark all read'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Unread')), findsNothing);
    });

    testWidgets('a filter with nothing in it says so', (tester) async {
      await pumpScreen(tester, alerts());
      await tester.tap(find.text('Leave'));
      await tester.pump();
      expect(find.text('Nothing here yet'), findsOneWidget);
      await tester.tap(find.text('Accidents'));
      await tester.pump();
      expect(find.text('Nothing here yet'), findsNothing);
    });

    testWidgets('tapping an alert reads it', (tester) async {
      final unread = AppAlert(
        id: 'leave',
        kind: AlertKind.leave,
        signal: AlertSignal.done,
        title: 'Leave approved',
        body: 'Casual · 6 – 7 Oct',
        receivedAt: now,
        unread: true,
      );
      await pumpScreen(
        tester,
        NotificationView(alerts: [unread], now: () => now),
      );
      expect(find.bySemanticsLabel(RegExp('Unread')), findsOneWidget);
      await tester.tap(find.text('Leave approved'));
      await tester.pump();
      expect(find.bySemanticsLabel(RegExp('Unread')), findsNothing);
    });
  });

  group('profile', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sl.allowReassignment = true;
      sl.registerSingleton<BiometricAuthenticator>(FakeBiometrics());
      sl.registerSingleton<AppearanceController>(AppearanceController());
      sl.registerSingleton<TextLookController>(TextLookController());
    });
    tearDown(sl.reset);

    const ahmed = SignedInUser(
      name: 'Ahmed Raza',
      role: 'Assistant Engineer',
      employeeId: '10482',
    );

    testWidgets('the look can be light, dark or the phone\'s, remembered', (
      tester,
    ) async {
      await pumpScreen(tester, const SettingsView(user: ahmed));
      final appearance = sl<AppearanceController>();
      expect(appearance.value, ThemeMode.light);
      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(appearance.value, ThemeMode.dark);
      expect(
        (await SharedPreferences.getInstance()).getString('appearance'),
        'dark',
      );
      final reread = AppearanceController();
      await reread.load();
      expect(reread.value, ThemeMode.dark);
    });

    Future<void> openTextDisplay(WidgetTester tester) async {
      await pumpScreen(tester, const SettingsView(user: ahmed));
      final row = find.text('Font & Display Size');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
    }

    testWidgets('text can be sized and made bold, remembered', (tester) async {
      await openTextDisplay(tester);
      final look = sl<TextLookController>();
      // The phone's own size until the user picks another.
      expect(look.value, const TextLook());
      expect(look.value.scale, 1);
      final slider = find.byType(AppStepSlider);
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      // A tap at the far end goes to the largest size, and the knob stays
      // there rather than springing back.
      final box = tester.getRect(slider);
      await tester.tapAt(Offset(box.right - 4, box.center.dy));
      await tester.pumpAndSettle();
      expect(look.value.size, TextLook.sizes.length - 1);
      expect(find.text('Largest'), findsOneWidget);
      final knob = find.descendant(
        of: slider,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      final now = tester.getRect(slider);
      expect(
        tester.getCenter(knob).dx,
        moreOrLessEquals(now.right - AppSizes.sliderKnob / 2, epsilon: 1),
      );
      // A tap in the middle goes to the middle stop.
      await tester.tapAt(now.center);
      await tester.pumpAndSettle();
      expect(look.value.size, TextLook.sizes.length ~/ 2);
      expect(
        tester.getCenter(knob).dx,
        moreOrLessEquals(now.center.dx, epsilon: 1),
      );

      await tester.ensureVisible(find.text('Bold text'));
      await tester.tap(_switchOf('Bold text'));
      await tester.pumpAndSettle();
      expect(look.value.bold, isTrue);

      final reread = TextLookController();
      await reread.load();
      expect(reread.value, look.value);
    });

    testWidgets('the display can be made large, remembered', (tester) async {
      await openTextDisplay(tester);
      final look = sl<TextLookController>();
      expect(look.value.display, DisplaySize.standard);
      await tester.tap(find.widgetWithText(AppChoiceCard, 'Large'));
      await tester.pumpAndSettle();
      expect(look.value.display, DisplaySize.large);
      final reread = TextLookController();
      await reread.load();
      expect(reread.value.display, DisplaySize.large);
    });

    testWidgets('a large display lays out smaller and draws it larger', (
      tester,
    ) async {
      late Size laidOut;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AppFrame(
            displayScale: DisplaySize.large.scale,
            child: Builder(
              builder: (context) {
                laidOut = MediaQuery.sizeOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(laidOut.width, moreOrLessEquals(screen.width / 1.15));
      expect(laidOut.height, moreOrLessEquals(screen.height / 1.15));
    });

    test("each employee's face is their own", () async {
      final store = ProfileFaceStore.instance..showFor('10482');
      await pumpEventQueue();
      await store.useEmoji('🚂');
      expect(store.faceFor('10482'), isA<EmojiFace>());
      // Someone else signs in on the same phone: not theirs.
      store.showFor('20931');
      expect(store.faceFor('20931'), isA<InitialsFace>());
      await pumpEventQueue();
      expect(store.faceFor('20931'), isA<InitialsFace>());
      // The first comes back to their own, after signing out and in.
      store.showFor('10482');
      await pumpEventQueue();
      expect((store.faceFor('10482') as EmojiFace).emoji, '🚂');
      // An emoji keeps the colour picked behind it.
      await store.useEmoji('🚂', tint: AvatarTint.gold);
      store.showFor('20931');
      await pumpEventQueue();
      store.showFor('10482');
      await pumpEventQueue();
      expect((store.faceFor('10482') as EmojiFace).tint, AvatarTint.gold);
      await store.useInitials();
      expect(store.faceFor('10482'), isA<InitialsFace>());
    });

    for (final (name, size, scale, platform) in layoutMatrix()) {
      testWidgets('lays out on $name', (tester) async {
        await pumpScreen(
          tester,
          const SettingsView(user: ahmed),
          size: size,
          textScale: scale,
          platform: platform,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows who is signed in', (tester) async {
      await pumpScreen(tester, const SettingsView(user: ahmed));
      expect(find.text('Ahmed Raza'), findsOneWidget);
      expect(find.text('Assistant Engineer'), findsOneWidget);
      expect(find.text('Emp ID: 10482'), findsOneWidget);
      expect(find.text('AR'), findsOneWidget);
    });

    testWidgets('turns biometric sign-in on once confirmed', (tester) async {
      await pumpScreen(tester, const SettingsView(user: ahmed));
      await tester.pump();
      final toggle = _switchOf('Biometric Sign In');
      expect(tester.widget<AppSwitch>(toggle).value, isFalse);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(tester.widget<AppSwitch>(toggle).value, isTrue);
    });

    testWidgets('a biometric check that fails says so', (tester) async {
      sl.registerSingleton<BiometricAuthenticator>(
        FakeBiometrics(passes: false),
      );
      await pumpScreen(tester, const SettingsView(user: ahmed));
      await tester.pump();
      await tester.ensureVisible(_switchOf('Biometric Sign In'));
      await tester.tap(_switchOf('Biometric Sign In'));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't turn on biometric sign-in"), findsOneWidget);
    });

    testWidgets('log out asks first', (tester) async {
      await pumpScreen(tester, const SettingsView(user: ahmed));
      await tester.ensureVisible(find.text('Log out'));
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(find.text('Log out of PROMISE?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out of PROMISE?'), findsNothing);
    });

    testWidgets('shows the installed app version', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('railway_hrms/app_info'),
        (call) async => {'version': '1.2.3', 'build': '45', 'id': 'pk.promise'},
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('railway_hrms/app_info'),
          null,
        ),
      );
      await pumpScreen(tester, const SettingsView(user: ahmed));
      await tester.scrollUntilVisible(
        find.text('App Version'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('1.2.3+45'), findsOneWidget);
    });
  });
}
