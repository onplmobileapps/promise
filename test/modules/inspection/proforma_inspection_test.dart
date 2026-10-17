import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/l10n/generated/app_localizations_en.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/models/inspection_submission.dart';
import 'package:railway_hrms/modules/inspection/electrical/power/power_inspection.dart';
import 'package:railway_hrms/modules/inspection/electrical/rtl/rtl_inspection.dart';
import 'package:railway_hrms/modules/inspection/locomotive/loco_proformas.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/proformas.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

final _l10n = AppLocalizationsEn();

class _Verifier implements InspectionFaceVerifier {
  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async => FaceCheckPassed(
    InspectionIdentity(
      photoPath: '${moment.name}.jpg',
      verifiedAt: DateTime(2026),
    ),
  );
}

class _Server implements InspectionRepository {
  final List<(InspectionApi, Map<String, dynamic>)> taken = [];

  @override
  Future<Either<AppException, List<StationItem>>> getUserStations({
    int? section,
  }) async => Right([StationItem(id: 1055, name: 'Karachi Cantt', code: 'KC')]);

  @override
  Future<Either<AppException, InspectionSubmission>> submit(
    InspectionApi api,
    Map<String, dynamic> payload,
  ) async {
    taken.add((api, payload));
    return const Right(InspectionSubmission(message: 'Received.'));
  }
}

class _Matcher implements InspectionFaceMatcher {
  @override
  Future<Either<AppException, InspectionIdentity>> match(
    InspectionIdentity identity,
  ) async => Right(identity.asMatched());
}

ProformaItem _item(ProformaSection section, String no) =>
    section.items.firstWhere((item) => item.no == no);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every proforma numbers its items once and asks something of each', () {
    final ids = <String>{};
    for (final definition in allProformas(_l10n)) {
      expect(ids.add(definition.id), isTrue, reason: definition.id);
      final keys = <String>{};
      for (final section in definition.sections) {
        expect(keys.add(section.key), isTrue, reason: section.key);
        final numbers = <String>{};
        for (final item in section.items) {
          expect(
            numbers.add(item.no),
            isTrue,
            reason: '${section.key} ${item.no}',
          );
          expect(
            item.options.isNotEmpty ||
                item.record ||
                item.reading ||
                item.checks.isNotEmpty,
            isTrue,
            reason: '${section.key} ${item.label}',
          );
          for (final fault in item.faults) {
            expect(item.options.map((o) => o.code), contains(fault));
          }
        }
      }
    }
    expect(proformaNamed(_l10n, 'loco_GEU-40')?.subtitle, 'GEU-40');
    expect(proformaNamed(_l10n, 'loco_PHA-HBU-20')?.subtitle, 'PHA/HBU-20');
  });

  test('a GEU-40 goes to the shed as the proforma numbers it', () {
    final proforma = kLocoProformas.firstWhere((p) => p.locoClass == 'GEU-40');
    expect(
      [for (final s in proforma.sections) (s.key, s.items.length)],
      [
        ('DRIVER_CAB', 18),
        ('BATTERY', 4),
        ('ENGINE_ROOM', 11),
        ('COMPRESSOR_ROOM', 6),
        ('UNDER_TRUCK', 7),
        ('ELECTRICAL_COMPARTMENT', 2),
        ('TRACTION_MOTOR', 4),
        ('LOAD_TEST', 6),
      ],
    );
    final definition = locoDefinition(_l10n, proforma);
    final cab = proforma.sections.first;
    final compressor = proforma.sections[3];
    final answers = ProformaAnswers()
      ..setField('loco_number', '4005')
      ..setField('shed_name', 'Karachi Diesel Shed')
      ..setField('station', 1055)
      ..setField('inspection_date', '2026-10-16')
      ..setField('inspecting_officer_name', 'FWO DME Inspector')
      ..setField('designation', 'DME')
      ..setField('inspection_result', 'SATISFACTORY')
      ..set('DRIVER_CAB', _item(cab, '1'), 'status', 'Clean')
      ..set('DRIVER_CAB', _item(cab, '4'), 'status', 'Satisfactory')
      ..set('DRIVER_CAB', _item(cab, '4'), 'value', '650')
      ..set('DRIVER_CAB', _item(cab, '17'), 'status', 'Valid')
      ..set('DRIVER_CAB', _item(cab, '17'), 'expiry_date', '2027-04-01')
      ..set(
        'COMPRESSOR_ROOM',
        _item(compressor, '6'),
        'status',
        'Unsatisfactory',
      )
      ..set(
        'COMPRESSOR_ROOM',
        _item(compressor, '6'),
        'cause',
        'Shaft uncoupled',
      )
      ..set('COMPRESSOR_ROOM', _item(compressor, '6'), 'note', 'Coupled again')
      ..rowsOf('OFFICER_INSPECTIONS');
    final payload = definition.payload!(
      ProformaContext(
        definition: definition,
        answers: answers,
        sections: definition.sectionsFor(answers),
        user: User(division: 8),
      ),
    );
    expect(payload['loco_class'], 'GEU-40');
    expect(payload['loco_number'], '4005');
    expect(payload['division'], 8);
    expect(payload['station'], 1055);
    final data = payload['data'] as Map<String, dynamic>;
    expect(data['DRIVER_CAB'], {
      '1': {'status': 'Clean'},
      '4': {'status': 'Satisfactory', 'value': '650 KPA'},
      '17': {'status': 'Valid', 'expiry_date': '2027-04-01'},
    });
    expect(data['COMPRESSOR_ROOM']['6'], {
      'status': 'Unsatisfactory',
      'remarks': 'Shaft uncoupled — Coupled again',
    });
    expect(data.containsKey('OFFICER_INSPECTIONS'), isFalse);
    expect(payload['signatures'], [
      {'role': 'DME', 'name': 'FWO DME Inspector', 'signed_date': '2026-10-16'},
    ]);

    // A cause goes once the item is in order again.
    answers.set(
      'COMPRESSOR_ROOM',
      _item(compressor, '6'),
      'status',
      'Satisfactory',
    );
    expect(answers.data(definition.sections)['COMPRESSOR_ROOM']['6'], {
      'status': 'Satisfactory',
      'observation': 'Coupled again',
    });
  });

  test('a train lighting inspection asks the sections of where it is made', () {
    final field = rtlDefinitions(_l10n).first.definition;
    final answers = ProformaAnswers();
    expect(field.sectionsFor(answers), isEmpty);
    answers.setField('inspection_point', RtlPoint.station);
    expect(
      [for (final s in field.sectionsFor(answers)) s.key],
      ['STATION', 'POWER_VAN'],
    );
    answers.setField('inspection_point', RtlPoint.workshop);
    expect([for (final s in field.sectionsFor(answers)) s.key], ['RELEASE']);
    answers.setField('rolling_stock', 'POWER_VAN');
    expect(
      [for (final s in field.sectionsFor(answers)) s.key],
      ['POWER_VAN_WORKSHOP', 'POWER_VAN_TESTS', 'RELEASE'],
    );

    answers.setField('inspection_point', RtlPoint.station);
    final coach = field.sections.first;
    answers
      ..set(
        'STATION',
        _item(coach, '1'),
        'record',
        'Coach AC-1234, Business Class',
      )
      ..set('STATION', _item(coach, '2'), 'status', 'O')
      ..set('STATION', _item(coach, '2'), 'ok', 24)
      ..set('STATION', _item(coach, '2'), 'defective', 0)
      ..set('STATION', _item(coach, '13'), 'status', 'Y')
      ..setField('maintenance_incharge', 'Shahid Mehmood')
      ..setField('inspecting_officer_name', 'FWO Electrical Foreman')
      ..setField('inspection_date', '2026-10-16');
    final payload = field.payload!(
      ProformaContext(
        definition: field,
        answers: answers,
        sections: field.sectionsFor(answers),
        user: null,
      ),
    );
    expect(payload['proforma'], 'EFO_AEFO_FIELD');
    expect(payload['inspection_point'], 'STATION');
    expect(payload.containsKey('work_stage'), isFalse);
    expect(payload['data'], {
      'STATION': {
        '1': {'record': 'Coach AC-1234, Business Class'},
        '2': {'status': 'O', 'ok': 24, 'defective': 0},
        '13': {'status': 'Y'},
      },
    });
    expect(payload['signatures'], [
      {
        'role': 'Maintenance In-charge',
        'name': 'Shahid Mehmood',
        'signed_date': '2026-10-16',
      },
      {
        'role': 'EFO / AEFO',
        'name': 'FWO Electrical Foreman',
        'signed_date': '2026-10-16',
      },
    ]);
  });

  test('a foreman inspects the areas picked; the power payload names them', () {
    final foreman = powerDefinitions(_l10n).first.definition;
    final answers = ProformaAnswers()
      ..setField('applicable_areas', ['SOLAR', 'STATION'])
      ..setField('previous_pending', 'NO')
      ..setField('inspecting_officer_name', 'Asif')
      ..setField('designation', 'EF');
    expect(
      [for (final s in foreman.sectionsFor(answers)) s.key],
      ['STATION', 'SOLAR'],
    );
    final payload = foreman.payload!(
      ProformaContext(
        definition: foreman,
        answers: answers,
        sections: foreman.sectionsFor(answers),
        user: null,
      ),
    );
    expect(payload['officer_level'], 'FOREMAN');
    expect(payload['applicable_areas'], 'Solar, Station');
    expect(payload['previous_pending'], 'NO');
    expect(payload['signatures'], [
      {'name_designation': 'Asif (EF)'},
    ]);
    final dee = powerDefinitions(_l10n)[2].definition;
    expect([for (final s in dee.sectionsFor(answers)) s.key], ['CHECKLIST']);
  });

  group('the form', () {
    late _Server server;
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'user_data':
            '{"user": {"id": 1, "first_name": "Ali", "last_name": "Raza", '
            '"designation": "DME", "division": 8, "empid": "42"}}',
      });
      server = _Server();
      sl
        ..registerSingleton<InspectionRepository>(server)
        ..registerSingleton<InspectionFaceMatcher>(_Matcher())
        ..registerSingleton<InspectionOutbox>(
          InspectionOutbox(repository: server, matcher: _Matcher()),
        );
    });
    tearDown(sl.reset);

    testWidgets('a locomotive is inspected class by class, a section marked '
        'in order at once, kept as a draft and sent', (tester) async {
      await pumpScreen(
        tester,
        LocomotiveInspectionScreen(verifier: _Verifier()),
      );
      await tester.pumpAndSettle();
      expect(find.text('RGE-20'), findsOneWidget);
      await tapVisible(tester, 'GEU-40');
      await tapVisible(tester, 'Verify and start');
      await tester.pumpAndSettle();
      expect(find.text('Locomotive inspection'), findsWidgets);
      // Who inspects, and the only station there is, are filled in.
      expect(find.text('Ali Raza'), findsOneWidget);
      expect(find.text('Karachi Cantt (KC)'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).at(0), '4005');
      await tester.enterText(
        find.byType(EditableText).at(1),
        'Karachi Diesel Shed',
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Driver Cab Area'), findsOneWidget);
      await tapVisible(tester, 'Mark the other 18 in order');
      expect(find.text('18/18'), findsOneWidget);
      await tapVisible(tester, 'Undo');
      expect(find.text('0/18'), findsOneWidget);
      await tapVisible(tester, 'Mark the other 18 in order');
      await tester.pump(const Duration(seconds: 1));

      final draft = await StorageService.getInspectionDraft(
        'proforma_loco_GEU-40',
      );
      expect(draft, contains('Karachi Diesel Shed'));
      expect(draft, contains('"status":"Clean"'));
      final records = await StorageService.getInspectionRecords();
      expect(records.single['payload'], {
        'type': 'proforma',
        'proforma': 'loco_GEU-40',
      });

      // On to the result, then the review, and out.
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      await tapVisible(tester, 'Satisfactory');
      await tester.tap(find.text('Review and submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review anyway'));
      await tester.pumpAndSettle();
      expect(find.text('1. Driver Cab Area'), findsOneWidget);
      await tester.tap(find.text('The report is correct'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify face to submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit inspection'));
      await tester.pumpAndSettle();
      expect(find.text('Received.'), findsOneWidget);
      final (api, body) = server.taken.single;
      expect(api, InspectionApi.shed);
      expect(body['loco_number'], '4005');
      expect(body['station'], 1055);
      expect(body['division'], 8);
      expect((body['data'] as Map)['DRIVER_CAB']['18'], {
        'status': 'Satisfactory',
      });
      expect(body['submit_verification'], isNotNull);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        await StorageService.getInspectionDraft('proforma_loco_GEU-40'),
        isNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a train lighting inspection shows its sections once the '
        'point is picked', (tester) async {
      await pumpScreen(
        tester,
        ProformaInspectionScreen(
          definition: rtlDefinitions(_l10n).first.definition,
          verifier: _Verifier(),
        ),
      );
      await tapVisible(tester, 'Verify and start');
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 2'), findsOneWidget);
      await tapVisible(tester, 'Workshop');
      expect(find.text('Coach or van *'), findsOneWidget);
      await tapVisible(tester, 'Economy coach');
      expect(find.text('Step 1 of 5'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('B. Economy Class Coach'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('every launcher lays out', (tester) async {
    await pumpScreen(tester, const LocomotiveInspectionScreen());
    await tester.pumpAndSettle();
    expect(find.text('Shed inspection'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
