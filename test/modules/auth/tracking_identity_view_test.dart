import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/cnic/cnic_camera.dart';
import 'package:railway_hrms/core/navigation/app_routes.dart';
import 'package:railway_hrms/modules/auth/screens/tracking_identity_view.dart';

import '../../helpers/cnic_fakes.dart';
import '../../helpers/pump_app.dart';

/// The CNIC step, with a sign-in that says [problem], or goes through.
TrackingIdentityView step({String? problem}) => TrackingIdentityView(
  phoneNumber: '03001234567',
  signIn: (phoneNumber, cnic) async => problem,
  camera: fakeCnicCamera,
);

/// Live train tracking, where signing in leads.
final tracking = <String, WidgetBuilder>{
  AppRoutes.liveTracking: (_) => const Scaffold(body: Text('Live trains')),
};

/// Opens the camera and takes the CNIC.
Future<void> scanTheCnic(WidgetTester tester) async {
  await tapVisible(tester, 'Tap to scan your CNIC');
  await tapVisible(tester, 'Take');
}

AppButton continueButton(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Continue'));

void main() {
  setUpAll(loadAppFonts);

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('the CNIC step lays out on $name, before and after', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        step(),
        size: size,
        textScale: scale,
        platform: platform,
      );
      expect(tester.takeException(), isNull);
      await scanTheCnic(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Verified'), findsOneWidget);
    });
  }

  testWidgets('shows the number typed, fixed', (tester) async {
    await pumpScreen(tester, step());
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, '03001234567');
    expect(field.enabled, isFalse);
  });

  testWidgets('the camera opens in the page, not a screen of its own', (
    tester,
  ) async {
    await pumpScreen(tester, step());
    await tapVisible(tester, 'Tap to scan your CNIC');
    expect(find.text('Take'), findsOneWidget);
    expect(find.byType(TrackingIdentityView), findsOneWidget);
    expect(find.text('Tap to scan your CNIC'), findsNothing);
  });

  testWidgets('Continue waits for the CNIC, then opens train tracking', (
    tester,
  ) async {
    CnicScan? signedIn;
    await pumpScreen(
      tester,
      TrackingIdentityView(
        phoneNumber: '03001234567',
        signIn: (phoneNumber, cnic) async {
          signedIn = cnic;
          return null;
        },
        camera: fakeCnicCamera,
      ),
      routes: tracking,
    );
    expect(continueButton(tester).onPressed, isNull);

    await scanTheCnic(tester);
    expect(find.text('Verified'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);

    await tapVisible(tester, 'Continue');
    expect(signedIn, same(fakeCnicScan));
    expect(find.text('Live trains'), findsOneWidget);
  });

  testWidgets('a sign-in that fails is explained, and stays', (tester) async {
    await pumpScreen(
      tester,
      step(problem: 'This number is not registered'),
      routes: tracking,
    );
    await scanTheCnic(tester);
    await tapVisible(tester, 'Continue');
    expect(find.byType(AppDialog), findsOneWidget);
    expect(find.text('This number is not registered'), findsOneWidget);
    expect(find.text('Live trains'), findsNothing);
  });

  testWidgets('closing the camera leaves the CNIC to scan', (tester) async {
    await pumpScreen(tester, step());
    await tapVisible(tester, 'Tap to scan your CNIC');
    await tapVisible(tester, 'Shut');
    expect(find.text('Tap to scan your CNIC'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets('scanning again lets the CNIC go until it is taken again', (
    tester,
  ) async {
    await pumpScreen(tester, step());
    await scanTheCnic(tester);
    await tapVisible(tester, 'Scan again');
    expect(find.text('Take'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
    await tapVisible(tester, 'Take');
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets('Change goes back to the number', (tester) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => step())),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackingIdentityView), findsOneWidget);
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.byType(TrackingIdentityView), findsNothing);
  });
}
