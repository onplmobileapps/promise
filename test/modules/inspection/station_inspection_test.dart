import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_inspection_payload.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:railway_hrms/modules/inspection/station/station_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/station/station_report.dart';
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

class _Stations implements InspectionRepository {
  int? askedSection;

  @override
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  }) async {
    askedSection = section;
    return Right([
      StationItem(id: 11, name: 'Lahore Junction', code: 'LHR'),
      StationItem(id: 12, name: 'Raiwind Junction', code: 'RND'),
    ]);
  }

  @override
  Future<Either<AppException, InspectionSubmission>> submit(
    InspectionApi api,
    Map<String, dynamic> payload,
  ) async => const Right(InspectionSubmission(message: 'Received.'));
}

StationInspectionController _filled() {
  final form = StationInspectionController()
    ..setStation('Lahore Junction (LHR)', id: 11)
    ..inspDate = DateTime(2026, 10, 17);
  form.fields.addAll({
    'uniform': 'Yes',
    'iyd': 'Not available',
    'slideOverhaulDate': DateTime(2024, 3, 1),
    'slideLockingTest': 'Unsatisfactory',
    'slideLockingTest_remark': 'Lever 4 stiff',
    'fireExtCount': 2,
    'blockType': "Neal's Token",
    'mainBattery': 54.2,
    'chargerOutputV': 56.0,
    'remarks': 'Yard clean.',
    'sig_0_pole': 'Satisfactory',
  });
  final points = form.rowsFor('points');
  form.fields
    ..['${form.rowPrefix('points', points.first)}_pointNo'] = '12'
    ..['${form.rowPrefix('points', points.first)}_gaugeTest'] = 'Pass';
  return form;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the server gets the answers given, by its names, and no others', () {
    final payload = StationInspectionPayload.build(
      _filled(),
      stationId: 11,
      user: LoginResponse(
        user: User()
          ..division = 3
          ..section = 7,
      ),
    );
    expect(payload['station'], 11);
    expect(payload['division'], 3);
    expect(payload['section'], 7);
    expect(payload['sm_uniform'], 'YES');
    expect(payload['sm_iyd'], 'NOT AVAILABLE');
    expect(payload['sm_slide_frame_overhaul_date'], '2024-03-01');
    expect(payload['sm_slide_frame_locking_test'], 'UNSATISFACTORY');
    expect(payload['fire_extinguishers_count'], 2);
    expect(payload['block_instrument_type'], "Neal's Token");
    expect(payload['main_battery_voltage'], 54.2);
    // Nothing is made up for what was left blank.
    for (final blank in ['sm_name', 'route_up_train', 'pa_system']) {
      expect(payload.containsKey(blank), isFalse, reason: blank);
    }
    expect(payload['overall_remarks'], contains('Yard clean.'));
    expect(
      payload['overall_remarks'],
      contains('Locking Test Result: Lever 4 stiff'),
    );
    expect(payload['signals'], [
      {'signal_id': 'Up OHS', 'pole_condition': 'Satisfactory'},
    ]);
    // The second, blank point is left out.
    expect(payload['points'], [
      {'point_number': '12', 'point_setting_test': 'Pass'},
    ]);
    expect(payload['level_crossings'], isEmpty);
    expect(payload['battery_banks'], [
      {
        'bank_type': 'Main',
        'charger_voltage': 56.0,
        'batteries': [
          {'battery_number': 1, 'voltage': 54.2},
        ],
      },
    ]);
    expect(
      (payload['block_instruments'] as List).single['instrument_type'],
      "Neal's Token",
    );
  });

  test('the report reads each answer, a fault with its note', () {
    final report = stationReport(
      _filled(),
      title: 'Station inspection',
      stationLabel: 'Station',
      dateLabel: 'Date',
    );
    final office = report.sections.firstWhere((s) => s.title == 'Office');
    final locking = office.rows.firstWhere(
      (row) => row.label == 'Locking Test Result',
    );
    expect(locking.value, 'Unsatisfactory — Lever 4 stiff');
    expect(locking.tone, ReportTone.bad);
    // Two extinguishers, two filling dates asked for.
    expect(
      office.rows.where((row) => row.label.startsWith('Extinguisher')),
      hasLength(2),
    );
    expect(report.findings, greaterThanOrEqualTo(2));
  });

  group('the form', () {
    late _Stations stations;
    setUp(() {
      stations = _Stations();
      sl.registerSingleton<InspectionRepository>(stations);
    });
    tearDown(sl.reset);

    testWidgets('opens on the face, asks for a station, and steps through', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'user_data':
            '{"user": {"id": 1, "name": "Ali", "section": 7, "division": 3}}',
      });
      await pumpScreen(tester, StationInspectionScreen(verifier: _Verifier()));
      await tapVisible(tester, 'Verify and start');
      await tester.pumpAndSettle();
      expect(find.text('Station inspection'), findsWidgets);
      expect(find.text('Choose the station'), findsOneWidget);

      // Without a station the report can't be read yet.
      for (var i = 0; i < 18; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Review and submit'));
      await tester.pumpAndSettle();
      expect(find.text('Fill these in first'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a picked station shows in the header', (tester) async {
      await pumpScreen(tester, StationInspectionScreen(verifier: _Verifier()));
      await tapVisible(tester, 'Verify and start');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose the station'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Raiwind Junction (RND)'));
      await tester.pumpAndSettle();
      expect(find.text('Raiwind Junction (RND)'), findsWidgets);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Office'), findsWidgets);
      await tester.tap(find.text('Yes').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('1 of'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
