import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/config/app_flags.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => AppFlags.inspectionFaceCheck = true);

  test('the inspection checks switch is kept for the next start', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    AppFlags.restore(prefs);
    expect(AppFlags.inspectionFaceCheck, isTrue);

    await AppFlags.setInspectionChecks(false, prefs);
    expect(AppFlags.inspectionFaceCheck, isFalse);

    // As the app starts again.
    AppFlags.inspectionFaceCheck = true;
    AppFlags.restore(prefs);
    expect(AppFlags.inspectionFaceCheck, isFalse);
    // Tests run as a debug build: the switch shows.
    expect(AppFlags.testingTools, isTrue);
  });
}
