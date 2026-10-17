import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/footplate/inspection_approval_screen.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/footplate_report.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
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

  test('the report reads a flagged locomotive item as a finding', () {
    final data = FootplateInspectionData();
    data.trainSchedule.trainNo = '45 UP';
    data.locomotive.setStatus(
      'Whistle',
      LocomotiveEquipmentStatus(isFunctional: false),
    );
    data.locomotive.setStatus(
      'Fire Extinguisher',
      LocomotiveEquipmentStatus(
        isFunctional: false,
        selectedIssues: const ['Expired'],
      ),
    );
    final report = footplateReport(data, title: 'Footplate inspection');
    final loco = report.sections.firstWhere(
      (s) => s.title == 'Condition of Locomotive',
    );
    final fire = loco.rows.firstWhere((r) => r.label == 'Fire Extinguisher');
    expect(fire.value, 'Issue — Expired');
    expect(fire.tone, ReportTone.bad);
    expect(
      loco.rows.firstWhere((r) => r.label == 'Whistle').tone,
      ReportTone.bad,
    );
  });

  testWidgets('the wizard opens on the face, flags an item, keeps a draft', (
    tester,
  ) async {
    await pumpScreen(tester, FootplateWizardScreen(verifier: _Verifier()));
    await tapVisible(tester, 'Verify and start');
    await tester.pumpAndSettle();
    expect(find.text('Footplate inspection'), findsWidgets);
    expect(find.text('Train & Locomotive'), findsOneWidget);
    // No train or crew is filled in for the inspector.
    expect(find.text('Train No'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Issue').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    final records = await StorageService.getInspectionRecords();
    final payload = records.single['payload'] as Map<String, dynamic>;
    expect(payload['locomotive']['Speedo Meter']['isFunctional'], isFalse);
    expect(payload.containsKey('punctuality'), isTrue);
    final draft = await StorageService.getInspectionDraft(
      records.single['id'] as String,
    );
    expect(jsonDecode(draft!)['step'], 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approval asks for the whole request before it is approved', (
    tester,
  ) async {
    await pumpScreen(tester, const InspectionApprovalScreen());
    await tapVisible(tester, 'Send for approval');
    expect(
      find.text('Fill in the train, officer, date, times and route first.'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
