import 'package:camera/camera.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/cnic/cnic_capture_card.dart';
import 'package:railway_hrms/modules/hrms/screens/face_registration_view.dart';

import '../../helpers/cnic_fakes.dart';
import '../../helpers/pump_app.dart';

AppButton faceKey(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Start face scan'));

/// A stand-in face camera that takes five photos of a face.
Future<Object?> fakeFaceCamera(_, _) async => FaceRegistrationResult(
  images: [for (var i = 0; i < 5; i++) XFile('/nowhere/face_$i.jpg')],
  embeddings: [
    for (var i = 0; i < 5; i++) [0.0],
  ],
);

/// Takes the CNIC and the face with the stand-in cameras.
Future<void> takeBoth(WidgetTester tester) async {
  await tapVisible(tester, 'Tap to scan your CNIC');
  await tapVisible(tester, 'Take');
  await tapVisible(tester, 'Start face scan');
}

AppButton proceedKey(WidgetTester tester) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, 'Proceed'));

/// Opens [setup] over a screen, as the app does, so it can close.
Future<void> openOver(WidgetTester tester, FaceRegistrationView setup) async {
  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => setup)),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('the CNIC is scanned in the page, as at sign-in, then the face', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FaceRegistrationView(
        onRegister: (_) async => null,
        cnicCamera: fakeCnicCamera,
      ),
    );
    expect(find.byType(CnicCaptureCard), findsOneWidget);
    // Titled by its step, not twice.
    expect(find.text('PAKISTANI CNIC'), findsNothing);
    expect(faceKey(tester).onPressed, isNull);

    await tapVisible(tester, 'Tap to scan your CNIC');
    await tapVisible(tester, 'Take');
    expect(tester.takeException(), isNull);
    expect(find.text('Verified'), findsOneWidget);
    expect(faceKey(tester).onPressed, isNotNull);

    // Scanning it again locks the face step until it is taken.
    await tapVisible(tester, 'Scan again');
    expect(faceKey(tester).onPressed, isNull);
  });

  testWidgets('with the CNIC and the face both taken, the setup is done', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      FaceRegistrationView(
        onRegister: (_) async => null,
        cnicCamera: fakeCnicCamera,
        faceCamera: fakeFaceCamera,
      ),
    );
    await tapVisible(tester, 'Tap to scan your CNIC');
    await tapVisible(tester, 'Take');
    await tapVisible(tester, 'Start face scan');
    // Both taken: the page stays, its last step reached, its close key
    // there to leave by.
    expect(tester.takeException(), isNull);
    expect(find.byType(FaceRegistrationView), findsOneWidget);
    expect(find.bySemanticsLabel('Step 3 of 3: Done'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    final proceed = tester.widget<AppButton>(
      find.widgetWithText(AppButton, 'Proceed'),
    );
    expect(proceed.onPressed, isNotNull);
  });

  testWidgets('photos that fail to send stop the registration, and say why', (
    tester,
  ) async {
    var registered = 0;
    await pumpScreen(
      tester,
      FaceRegistrationView(
        onRegister: (_) async {
          registered++;
          return null;
        },
        cnicCamera: fakeCnicCamera,
        faceCamera: fakeFaceCamera,
        sendAttachments: (cnic, {employeeId, facePhoto}) async =>
            "Can't reach the server.",
      ),
    );
    await takeBoth(tester);
    await tapVisible(tester, 'Proceed');

    expect(registered, 0);
    expect(
      find.text(
        "The CNIC and face photos couldn't be sent, so nothing was "
        "registered. Can't reach the server.",
      ),
      findsOneWidget,
    );
    // Nothing is lost: the user can try again.
    expect(proceedKey(tester).onPressed, isNotNull);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('the photos go before the face is registered, and only once', (
    tester,
  ) async {
    final sent = <String>[];
    final problems = <String?>['The server is busy', null];
    var registered = 0;
    await openOver(
      tester,
      FaceRegistrationView(
        employeeId: '135387',
        onRegister: (registration) async {
          registered++;
          expect(registration.cnic, same(fakeCnicScan.photo));
          expect(registration.images, hasLength(5));
          return problems.removeAt(0);
        },
        cnicCamera: fakeCnicCamera,
        faceCamera: fakeFaceCamera,
        sendAttachments: (cnic, {employeeId, facePhoto}) async {
          sent.add('${cnic.path} ${facePhoto?.path} $employeeId');
          return null;
        },
      ),
    );
    await takeBoth(tester);

    await tapVisible(tester, 'Proceed');
    expect(sent, ['/nowhere/cnic.jpg /nowhere/face_0.jpg 135387']);
    expect(registered, 1);
    expect(find.text('The server is busy'), findsOneWidget);

    // Tried again: the photos already went, the face is registered.
    await tapVisible(tester, 'Proceed');
    expect(sent, hasLength(1));
    expect(registered, 2);
    expect(find.byType(FaceRegistrationView), findsNothing);
  });

  for (final (name, size, scale, platform) in layoutMatrix()) {
    testWidgets('face setup with its CNIC lays out on $name', (tester) async {
      await pumpScreen(
        tester,
        FaceRegistrationView(
          onRegister: (_) async => null,
          cnicCamera: fakeCnicCamera,
        ),
        size: size,
        textScale: scale,
        platform: platform,
      );
      await tapVisible(tester, 'Tap to scan your CNIC');
      await tapVisible(tester, 'Take');
      expect(tester.takeException(), isNull);
    });
  }
}
