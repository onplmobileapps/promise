import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/modules/auth/data/auth_repository.dart';
import 'package:railway_hrms/modules/auth/screens/forgot_password_view.dart';
import 'package:railway_hrms/modules/auth/screens/verify_otp_view.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    sl.allowReassignment = true;
    sl.registerSingleton<AuthRepository>(FailingAuthRepository());
  });

  tearDown(sl.reset);

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('code screen lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        const VerifyOtpView(phoneNumber: '+92 300 1234567'),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 31));
      expect(tester.takeException(), isNull);
    });

    testWidgets('forgot password lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        const ForgotPasswordView(),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the code can be sent again after 30 seconds', (tester) async {
    await pumpScreen(
      tester,
      const VerifyOtpView(phoneNumber: '+92 300 1234567'),
    );
    expect(find.text('Resend in 30s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Resend in 20s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 21));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('the screen names the number the code went to', (tester) async {
    await pumpScreen(
      tester,
      const VerifyOtpView(phoneNumber: '+92 300 1234567'),
    );
    expect(find.textContaining('+92 300 1234567'), findsOneWidget);
    expect(find.textContaining('6-digit code'), findsOneWidget);
  });

  testWidgets('forgot password checks the address and calls repository', (
    tester,
  ) async {
    await pumpScreen(tester, const ForgotPasswordView());
    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.text('Please enter a valid email address'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ahmed@railways.gov.pk');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.byType(AppDialog), findsOneWidget);
  });
}
