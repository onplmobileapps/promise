import 'package:camera/camera.dart' show XFile;
import 'package:face_kit/src/capture/face_capture_session.dart';
import 'package:face_kit/src/ui/captured_faces_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the dialog; the returned list receives its result once closed.
Future<List<bool>> _open(WidgetTester tester, Object result) async {
  final closedWith = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              closedWith.add(await showCapturedFacesDialog(context, result)),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  return closedWith;
}

final _verification = FaceVerificationResult(
  images: [XFile('/tmp/a.jpg'), XFile('/tmp/b.jpg')],
  embeddings: const [[], []],
  livenessScore: 0.97,
  faceQuality: 0.71,
);

void main() {
  testWidgets('verification shows both images and scores; Continue → true', (
    tester,
  ) async {
    final closedWith = await _open(tester, _verification);

    expect(find.text('Verification images'), findsOneWidget);
    expect(find.text('2 images will be sent to the server'), findsOneWidget);
    expect(find.text('Liveness score: 97%'), findsOneWidget);
    expect(find.text('Face quality: 71%'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Verification images'), findsNothing);
    expect(closedWith, [true]);
  });

  testWidgets('Cancel → false, so no request is sent', (tester) async {
    final closedWith = await _open(tester, _verification);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(closedWith, [false]);
  });

  testWidgets('spoof failure says nothing is uploaded', (tester) async {
    await _open(
      tester,
      FaceCaptureFailedResult(
        'Live face not detected.',
        spoof: true,
        images: [XFile('/tmp/a.jpg')],
        livenessScore: 0.01,
      ),
    );

    expect(find.text('Spoof detected'), findsOneWidget);
    expect(
      find.text('Live face not detected.\nNothing is sent to the server.'),
      findsOneWidget,
    );
    expect(find.text('Liveness score: 1%'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);

    await tester.tap(find.text('OK'));
    await tester.pump();
  });
}
