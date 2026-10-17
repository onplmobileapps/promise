import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/civil/screens/civil_inspection_home_screen.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_rtl_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_form.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_inspection_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_form.dart';
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('parts split at headings; a fault asks what was found', () {
    final parts = specParts(kLocomotiveSpecs, first: 'Locomotive');
    expect(parts.first.title, 'Locomotive');
    expect(parts.map((p) => p.title), contains('Compressor Room'));

    final answers = SpecAnswers();
    final room = parts.firstWhere((p) => p.title == 'Compressor Room');
    final remarks = room.specs.firstWhere((s) => s.key == 'knocking_remarks');
    expect(answers.shows(remarks), isFalse);
    answers.values['knocking'] = 'No';
    expect(answers.shows(remarks), isFalse);
    answers.values['knocking'] = 'Yes';
    expect(answers.shows(remarks), isTrue);

    final rows = answers.rows(room.specs);
    final knocking = rows.firstWhere((r) => r.label == 'Any Knocking Sound');
    // "Yes" to a knocking sound is the fault, whatever the word says.
    expect(knocking.tone, ReportTone.bad);
  });

  test('a repeat counts its things from a draft and drops the last', () {
    final pier = CivilFieldSpec.repeatGroup('piers', 'Piers', 'Pier', [
      CivilFieldSpec.number('depth', 'Depth', unit: 'ft'),
    ]);
    final answers = SpecAnswers({'piers[0].depth': '4', 'piers[1].depth': '5'});
    expect(answers.repeats(pier), 2);
    expect(answers.progress([pier]), (2, 2));
    expect(answers.rows([pier]).map((r) => (r.label, r.value)), [
      ('Pier 1 · Depth', '4 ft'),
      ('Pier 2 · Depth', '5 ft'),
    ]);
    answers.removeRepeat(pier);
    expect(answers.repeats(pier), 1);
    expect(answers.values.containsKey('piers[1].depth'), isFalse);
  });

  testWidgets('the locomotive form opens on the face and keeps a draft', (
    tester,
  ) async {
    await pumpScreen(tester, LocomotiveInspectionScreen(verifier: _Verifier()));
    await tapVisible(tester, 'Verify and start');
    await tester.pumpAndSettle();
    expect(find.text('Locomotive inspection'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'Lahore Loco Shed');
    await tester.pump(const Duration(seconds: 1));
    final draft = await StorageService.getInspectionDraft(
      LocomotiveInspectionScreen.draftId,
    );
    expect(draft, contains('Lahore Loco Shed'));
    final records = await StorageService.getInspectionRecords();
    expect(records.single['payload'], {'type': 'locomotive'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('a civil asset shows its details and its sections as steps', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      CivilAssetFormScreen(
        department: 'Civil',
        subDepartment: 'Works',
        asset: 'Bridge',
        formId: 'civil_works_bridge',
        verifier: _Verifier(),
        fields: [
          CivilFieldSpec.section('Foundation'),
          CivilFieldSpec.radio('scour', 'Scouring', const ['No', 'Yes']),
          CivilFieldSpec.section('Deck'),
          CivilFieldSpec.text('deckNote', 'Deck note'),
        ],
      ),
    );
    await tapVisible(tester, 'Verify and start');
    await tester.pumpAndSettle();
    expect(find.text('Bridge'), findsWidgets);
    expect(find.text('Works'), findsOneWidget);
    expect(find.text('Scouring'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Deck note'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the civil catalogue lists assets and an empty history', (
    tester,
  ) async {
    await pumpScreen(tester, const CivilInspectionHomeScreen());
    await tester.pumpAndSettle();
    expect(find.text('Civil inspection'), findsOneWidget);
    expect(find.text('New inspection'), findsOneWidget);
    await tester.tap(find.text('Finished'));
    await tester.pumpAndSettle();
    expect(find.text('No finished inspections yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL asks for a place before it starts', (tester) async {
    await pumpScreen(
      tester,
      ElectricalRtlInspectionScreen(verifier: _Verifier()),
    );
    await tapVisible(tester, 'Verify and start');
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Start inspection');
    expect(find.text('Pick at least one place to inspect.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Workshop');
    await tapVisible(tester, 'Start inspection');
    await tester.pumpAndSettle();
    // Started within the inspection: no second face check before the form.
    expect(find.text('Verify and start'), findsNothing);
    expect(find.text('Workshop'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
