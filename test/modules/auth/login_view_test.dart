import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';
import 'package:railway_hrms/modules/auth/bloc/auth_cubit.dart';
import 'package:railway_hrms/modules/auth/screens/login_view.dart';
import 'package:railway_hrms/modules/auth/widgets/biometric_sign_in_button.dart';
import 'package:railway_hrms/modules/auth/widgets/employee_sign_in_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FailingAuthRepository repository;

  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = FailingAuthRepository();
    sl.allowReassignment = true;
    sl.registerFactory<AuthCubit>(() => AuthCubit(repository));
    sl.registerSingleton<BiometricAuthenticator>(FakeBiometrics());
  });

  tearDown(sl.reset);

  Future<void> openPromiseTab(WidgetTester tester) async {
    // Promise is shown directly without tabs
  }

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('promise lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        const LoginView(),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);

      await openPromiseTab(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(BiometricSignInButton), findsOneWidget);

      // Errors under every field still fit.
      // ensureVisible scrolls but doesn't lay out again; the pump does.
      await tester.ensureVisible(
        find.text('Sign In with Employee ID & Password'),
      );
      await tester.pump();
      await tester.tap(find.text('Sign In with Employee ID & Password'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Employee ID is required'), findsOneWidget);
    });
  }

  testWidgets('opens on promise login with logo above', (tester) async {
    await pumpScreen(tester, const LoginView());
    final logo = tester.getRect(find.byType(AppMedallion));
    final wordmark = tester.getRect(find.byType(AppWordmark));
    expect(logo.center.dx, moreOrLessEquals(393 / 2, epsilon: 0.5));
    expect(wordmark.center.dx, moreOrLessEquals(393 / 2, epsilon: 0.5));
    expect(logo.bottom, lessThanOrEqualTo(wordmark.top));
    // The emblem sits on the medallion's dome.
    final emblem = tester.getRect(
      find.descendant(
        of: find.byType(AppMedallion),
        matching: find.byType(AppEmblem),
      ),
    );
    final dome = tester.getRect(find.byType(AppDome));
    expect(dome.contains(emblem.topLeft), isTrue);
    expect(dome.contains(emblem.bottomRight), isTrue);
    expect(emblem.center.dx, moreOrLessEquals(dome.center.dx, epsilon: 0.5));
  });

  testWidgets('sign-in rises into place, then is still', (tester) async {
    await pumpScreen(tester, const LoginView(), size: const Size(412, 915));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('short of room, the greeting steps aside and all still fits', (
    tester,
  ) async {
    await pumpScreen(tester, const LoginView(), size: const Size(393, 759));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsNothing);
    expect(
      find.text('For employees with biometric sign-in turned on.'),
      findsNothing,
    );
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.maxScrollExtent, lessThan(8));
  });

  testWidgets('with animations off, nothing on sign-in moves', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpScreen(tester, const LoginView());
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  // A tall phone, or one set to a small display size, has room for all of
  // sign-in until the keyboard comes up and the card's notes step aside.
  for (final (name, size) in [
    ('a phone', const Size(393, 852)),
    ('a tall phone', const Size(461, 1024)),
  ]) {
    testWidgets(
      'the keyboard coming up keeps the field and what is typed, on $name',
      (tester) async {
        await pumpScreen(tester, const LoginView(), size: size);
        final id = find
            .descendant(
              of: find.byType(EmployeeSignInForm),
              matching: find.byType(TextField),
            )
            .first;
        await tester.tap(id);
        await tester.enterText(id, '10482');
        await tester.pump();
        final form = tester.state(find.byType(EmployeeSignInForm));
        final field = tester.state(id);

        // The keyboard takes the bottom half: the screen turns short and
        // the wordmark steps aside.
        tester.view.viewInsets = FakeViewPadding(
          bottom: tester.view.physicalSize.height / 2,
        );
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        expect(tester.state(find.byType(EmployeeSignInForm)), same(form));
        expect(tester.state(id), same(field));
        expect(tester.widget<TextField>(id).focusNode!.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);
        expect(tester.widget<TextField>(id).controller!.text, '10482');
      },
    );
  }

  testWidgets('scrolling with the keyboard up leaves it up', (tester) async {
    await pumpScreen(tester, const LoginView(), size: const Size(360, 640));
    final id = find
        .descendant(
          of: find.byType(EmployeeSignInForm),
          matching: find.byType(TextField),
        )
        .first;
    await tester.tap(id);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(id).focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  for (final width in [320.0, 393.0, 744.0]) {
    testWidgets('"or use" sits in the middle, ${width.toInt()} wide', (
      tester,
    ) async {
      await pumpScreen(tester, const LoginView(), size: Size(width, 900));
      await tester.pumpAndSettle();
      final words = tester.getCenter(
        find.textContaining('or use', findRichText: true),
      );
      final form = tester.getCenter(find.byType(EmployeeSignInForm));
      expect(words.dx, moreOrLessEquals(form.dx, epsilon: 0.5));
    });
  }

  testWidgets('no spaces, and no more than 10 and 20 characters', (
    tester,
  ) async {
    await pumpScreen(tester, const LoginView());
    final fields = find.descendant(
      of: find.byType(EmployeeSignInForm),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), ' 12 345 678 9012 ');
    await tester.enterText(fields.at(1), 'my secret pass word 1234567890');
    await tester.pump();
    final id = tester.widget<TextField>(fields.at(0)).controller!.text;
    final password = tester.widget<TextField>(fields.at(1)).controller!.text;
    expect(id, '1234567890');
    expect(password, 'mysecretpassword1234');
  });

  testWidgets('a failed sign-in is explained in a dialog, not a toast', (
    tester,
  ) async {
    await pumpScreen(tester, const LoginView());
    await openPromiseTab(tester);
    final fields = find.descendant(
      of: find.byType(EmployeeSignInForm),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '10482');
    await typeText(tester, fields.at(1), 'not-the-password');
    await tester.pump();
    // Typed by hand: nothing happens until the button is pressed.
    expect(repository.attempts, 0);
    await tester.tap(find.text('Sign In with Employee ID & Password'));
    await tester.pumpAndSettle();
    expect(repository.attempts, 1);
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text("Couldn't sign you in"), findsOneWidget);
    expect(find.text('Invalid employee ID or password'), findsOneWidget);
  });

  testWidgets('a saved password filled in signs in by itself', (tester) async {
    await pumpScreen(tester, const LoginView());
    await openPromiseTab(tester);
    final fields = find.descendant(
      of: find.byType(EmployeeSignInForm),
      matching: find.byType(TextField),
    );
    // Autofill puts both in at once.
    await tester.enterText(fields.at(0), '10482');
    await tester.enterText(fields.at(1), 'saved-password');
    await tester.pumpAndSettle();
    expect(repository.attempts, 1);
  });

  testWidgets('biometrics say how to turn them on while they are off', (
    tester,
  ) async {
    await pumpScreen(tester, const LoginView());
    await openPromiseTab(tester);
    await tester.tap(find.byType(BiometricSignInButton));
    await tester.pumpAndSettle();
    expect(find.text('Turn on biometric sign-in'), findsOneWidget);
    expect(repository.attempts, 0);
  });

  testWidgets('no biometric button on a phone without biometrics', (
    tester,
  ) async {
    sl.registerSingleton<BiometricAuthenticator>(
      FakeBiometrics(available: false),
    );
    await pumpScreen(tester, const LoginView());
    await openPromiseTab(tester);
    expect(find.byType(BiometricSignInButton), findsNothing);
    expect(
      find.text('or use Employee ID & Password', findRichText: true),
      findsNothing,
    );
    // The password is the one way in: its key is the main one.
    final signIn = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Sign In'),
    );
    expect(signIn.variant, AppButtonVariant.primary);
  });

  testWidgets('a face set up on the phone is offered first, by name', (
    tester,
  ) async {
    sl.registerSingleton<BiometricAuthenticator>(
      FakeBiometrics(kind: BiometricKind.face),
    );
    await pumpScreen(tester, const LoginView(), platform: TargetPlatform.iOS);
    expect(find.text('Sign In with Face ID'), findsOneWidget);
    expect(
      find.text('or use Employee ID & Password', findRichText: true),
      findsOneWidget,
    );
    final password = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Sign In with Employee ID & Password'),
    );
    expect(password.variant, AppButtonVariant.tonal);
  });
}

/// Types [text] into [field] a letter at a time, as a person does.
Future<void> typeText(WidgetTester tester, Finder field, String text) async {
  for (var i = 1; i <= text.length; i++) {
    await tester.enterText(field, text.substring(0, i));
  }
}
