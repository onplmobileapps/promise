import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_payload.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_screen.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/trolley_report.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

class _Verifier implements InspectionFaceVerifier {
  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async => FaceCheckPassed(
    InspectionIdentity(photoPath: 'start.jpg', verifiedAt: DateTime(2026)),
  );
}

class _Repository implements InspectionRepository {
  @override
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  }) async => const Right([]);

  @override
  Future<Either<AppException, InspectionSubmission>> submit(
    InspectionApi api,
    Map<String, dynamic> payload,
  ) async => const Right(InspectionSubmission(message: 'Received.'));
}

final _filled = MotorTrolleyInspectionState(
  inspectionDate: DateTime(2026, 10, 17),
  values: const {
    'sectionFrom': 'Lahore',
    'sectionTo': 'Raiwind',
    'kmFrom': '12.5',
    'alignmentReading': '4',
    'alignmentOutOfLimit': 'Yes',
    'alignmentReason': 'US Sleepers',
    'ballastCushion': '6-8"',
    'ballastCushion_remedy': 'Re-Ballasting',
    'railType': 'UIC-54',
    'kmTo': '  ',
  },
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the server gets the answers given, readings as numbers', () {
    final payload = TrolleyInspectionPayload.build(_filled);
    expect(payload['inspection_date'], '2026-10-17');
    expect(payload['section_from'], 'Lahore');
    expect(payload['km_from'], 12.5);
    expect(payload['alignment_reading_mm'], 4.0);
    expect(payload['alignment_out_of_limit'], 'Yes');
    expect(payload['ballast_cushion'], '6-8"');
    expect(payload['ballast_remedy'], 'Re-Ballasting');
    expect(payload['rail_type'], 'UIC-54');
    // Blank, so left out: not sent as "No" or zero.
    for (final blank in ['km_to', 'gauge_out_of_limit', 'inspected_by']) {
      expect(payload.containsKey(blank), isFalse, reason: blank);
    }
  });

  test('a reason is asked only once a reading is out of limit', () {
    final reason = kTrolleySteps
        .expand((step) => step.fields)
        .firstWhere((field) => field.key == 'gaugeReason');
    expect(const MotorTrolleyInspectionState().asks(reason), isFalse);
    expect(
      const MotorTrolleyInspectionState(
        values: {'gaugeOutOfLimit': 'Yes'},
      ).asks(reason),
      isTrue,
    );
  });

  test('the report reads out of limit as a fault, with units and remedy', () {
    final report = trolleyReport(
      _filled,
      title: 'Motor trolley inspection',
      sectionLabel: 'Section',
      dateLabel: 'Date',
    );
    expect(report.subtitle, 'Lahore – Raiwind');
    final geometry = report.sections.firstWhere(
      (s) => s.title == 'I. Track Geometry',
    );
    final out = geometry.rows.firstWhere((r) => r.label == 'Out of Limit');
    expect(out.tone, ReportTone.bad);
    expect(geometry.rows.firstWhere((r) => r.label == 'Reading').value, '4 mm');
    expect(
      geometry.rows.firstWhere((r) => r.label == 'Ballast Cushion').value,
      '6-8" — Remedy: Re-Ballasting',
    );
  });

  group('the form', () {
    setUp(() => sl.registerSingleton<InspectionRepository>(_Repository()));
    tearDown(sl.reset);

    testWidgets('opens on the face and needs the section to be reviewed', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MotorTrolleyInspectionScreen(verifier: _Verifier()),
      );
      await tapVisible(tester, 'Verify and start');
      await tester.pumpAndSettle();
      expect(find.text('Motor trolley inspection'), findsWidgets);
      for (var i = 1; i < kTrolleySteps.length; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Review and submit'));
      await tester.pumpAndSettle();
      expect(find.text('Fill these in first'), findsOneWidget);
      expect(find.textContaining('Section From'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
