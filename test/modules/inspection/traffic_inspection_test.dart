import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_inspection_home.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

class _Verifier implements InspectionFaceVerifier {
  int checks = 0;

  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async {
    checks++;
    return FaceCheckPassed(
      InspectionIdentity(photoPath: 'start.jpg', verifiedAt: DateTime(2026)),
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a flagged item reads as a finding, with its remark', () {
    final data = TrafficCommercialStationData();
    data.bookingOffice.of(kBookingOfficeChecklist.first.key)
      ..checked = false
      ..remarks = 'Register torn';
    final booking = commercialReport(data).first;
    final first = booking.rows.first;
    expect(first.value, 'Not Updated — Register torn');
    expect(first.tone, ReportTone.bad);
    expect(booking.rows.skip(1).every((r) => r.tone == ReportTone.good), true);
  });

  testWidgets('a form opens inside the visit, without a second face check', (
    tester,
  ) async {
    final verifier = _Verifier();
    await pumpScreen(
      tester,
      TrafficInspectionHome(stationName: 'Lahore Jn', verifier: verifier),
    );
    await tapVisible(tester, 'Verify and start');
    await tester.pumpAndSettle();
    expect(
      find.text('Choose the form to conduct'.toUpperCase()),
      findsOneWidget,
    );
    await tester.tap(find.text('Commercial — Station'));
    await tester.pumpAndSettle();
    expect(verifier.checks, 1);
    expect(find.text('Booking Office'), findsOneWidget);

    await tester.tap(find.text('Not Updated').first);
    await tester.pumpAndSettle();
    expect(find.text('Describe what is wrong'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    final records = await StorageService.getInspectionRecords();
    expect(records.single['payload']['type'], 'traffic');
    expect(tester.takeException(), isNull);
  });
}
