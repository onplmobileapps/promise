import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/l10n/generated/app_localizations_en.dart';
import 'package:railway_hrms/core/reports/report_assets.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report_pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

/// Passes or fails every check, and counts them.
class _Verifier implements InspectionFaceVerifier {
  _Verifier({this.pass = true});

  bool pass;
  final List<InspectionMoment> moments = [];

  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async {
    moments.add(moment);
    if (!pass) return const FaceCheckFailed('Profile does not match.');
    return FaceCheckPassed(
      InspectionIdentity(
        photoPath: 'footplate_images/${moment.name}.jpg',
        verifiedAt: DateTime(2026, 10, 17, 10, moment.index * 30),
      ),
    );
  }
}

InspectionReport _report() => InspectionReport(
  title: 'Station inspection',
  subtitle: 'Lahore Jn',
  date: DateTime(2026, 10, 17, 10),
  facts: [ReportRow('Section', 'Lahore – Raiwind')],
  sections: [
    ReportSection(
      title: 'Relay room',
      rows: [
        ReportRow('Locking and sealing', 'YES'),
        ReportRow('Lighting', 'Not working'),
        ReportRow('UPS', ''),
      ],
      note: 'AC serviced last week.',
    ),
  ],
);

/// Tests can't draw PDFs into pages: the review shows the report as a list.
Future<Uint8List> _noPdf(InspectionReport report, Object l10n, String locale) =>
    Future.error(UnsupportedError('No PDF in tests'));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('answers read as good, wrong, plain or missing', () {
    expect(ReportTone.of('YES'), ReportTone.good);
    expect(ReportTone.of('Satisfactory'), ReportTone.good);
    expect(ReportTone.of('Not working'), ReportTone.bad);
    expect(ReportTone.of('Unsatisfactory'), ReportTone.bad);
    expect(ReportTone.of('Neal\'s Token'), ReportTone.plain);
    expect(ReportTone.of('  '), ReportTone.missing);
    final report = _report();
    expect(report.findings, 1);
    expect(report.unanswered, 1);
  });

  test('draws the report as a PDF, signed or not yet', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('en');
    final assets = await ReportAssets.load();
    final unsigned = await InspectionReportPdf(
      _report(),
      AppLocalizationsEn(),
      assets,
      locale: 'en',
    ).build();
    expect(String.fromCharCodes(unsigned.take(5)), '%PDF-');
    final signed = await InspectionReportPdf(
      _report().copyWith(
        inspector: 'Ali Raza · SSE',
        signatures: InspectionSignatures(
          start: InspectionIdentity(
            photoPath: 'missing.jpg',
            verifiedAt: DateTime(2026, 10, 17, 9),
            latitude: 31.5,
            longitude: 74.3,
          ),
        ),
      ),
      AppLocalizationsEn(),
      assets,
      locale: 'en',
    ).build();
    expect(signed, isA<Uint8List>());
  });

  testWidgets('an inspection opens only once the face is verified', (
    tester,
  ) async {
    final verifier = _Verifier(pass: false);
    await pumpScreen(
      tester,
      InspectionStartGate(
        title: 'Station inspection',
        verifier: verifier,
        child: Builder(
          builder: (context) => Text(
            'form started '
            '${InspectionSession.maybeOf(context)?.start.photoPath}',
          ),
        ),
      ),
    );
    expect(find.text('Verify your face to start'), findsOneWidget);
    await tapVisible(tester, 'Verify and start');
    expect(find.text('Face not verified'), findsOneWidget);
    expect(find.textContaining('form started'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    verifier.pass = true;
    await tapVisible(tester, 'Verify and start');
    expect(
      find.text('form started footplate_images/start.jpg'),
      findsOneWidget,
    );
    expect(verifier.moments, [InspectionMoment.start, InspectionMoment.start]);
  });

  testWidgets('a form inside a started inspection opens at once', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      InspectionSession(
        start: InspectionIdentity(
          photoPath: 'a.jpg',
          verifiedAt: DateTime(2026),
        ),
        child: InspectionStartGate(
          title: 'Level crossing',
          verifier: _Verifier(),
          child: const Text('the form'),
        ),
      ),
    );
    expect(find.text('the form'), findsOneWidget);
  });

  testWidgets('submit opens only after the report is confirmed and the face '
      'verified again', (tester) async {
    final verifier = _Verifier();
    InspectionSignatures? sent;
    bool? result;
    await pumpScreen(
      tester,
      InspectionSession(
        start: InspectionIdentity(
          photoPath: 'start.jpg',
          verifiedAt: DateTime(2026, 10, 17, 9),
        ),
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await reviewAndSubmit(
                  context,
                  report: _report(),
                  verifier: verifier,
                  render: _noPdf,
                  submit: (signatures) async {
                    sent = signatures;
                    return const Right('Report number 42 received.');
                  },
                );
              },
              child: const Text('submit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    // No pages can be drawn in a test: the report shows as a list.
    expect(find.text('Relay room'), findsOneWidget);
    expect(find.text('Not answered'), findsOneWidget);
    expect(find.text('Submit inspection'), findsNothing);
    expect(find.text('Verify face to submit'), findsNothing);

    await tester.tap(find.text('The report is correct'));
    await tester.pumpAndSettle();
    expect(find.text('You confirmed the report'), findsOneWidget);
    await tester.tap(find.text('Verify face to submit'));
    await tester.pumpAndSettle();
    expect(verifier.moments, [InspectionMoment.submit]);

    await tester.tap(find.text('Submit inspection'));
    await tester.pumpAndSettle();
    expect(find.text('Report number 42 received.'), findsOneWidget);
    expect(sent?.start?.photoPath, 'start.jpg');
    expect(sent?.submit?.photoPath, 'footplate_images/submit.jpg');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('a refused submission says why and can be tried again', (
    tester,
  ) async {
    var tries = 0;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => reviewAndSubmit(
              context,
              report: _report(),
              verifier: _Verifier(),
              render: _noPdf,
              submit: (_) async {
                tries++;
                return Left(ServerException('Relay room ac: required'));
              },
            ),
            child: const Text('submit'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The report is correct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify face to submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit inspection'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't submit"), findsOneWidget);
    expect(find.text('Relay room ac: required'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit inspection'));
    await tester.pumpAndSettle();
    expect(tries, 2);
  });
}
