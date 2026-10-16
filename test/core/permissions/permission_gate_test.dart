import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/permissions/permission_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_app.dart';

/// The system, answering as a test wants.
class _FakeSystem implements PermissionPlatform {
  final states = <AppPermission, PermissionState>{};

  /// What the system's prompt ends in.
  PermissionState answer = PermissionState.granted;
  final prompted = <AppPermission>[];
  int settingsOpened = 0;

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      states[permission] ?? PermissionState.denied;

  @override
  Future<PermissionState> request(AppPermission permission) async {
    prompted.add(permission);
    return states[permission] = answer;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

void main() {
  late _FakeSystem system;
  late PermissionGate gate;

  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    system = _FakeSystem();
    gate = PermissionGate(platform: system);
  });

  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    Size size = const Size(393, 852),
    double textScale = 1,
  }) async {
    late BuildContext host;
    await pumpScreen(
      tester,
      Builder(
        builder: (context) {
          host = context;
          return const Scaffold();
        },
      ),
      size: size,
      textScale: textScale,
    );
    return host;
  }

  testWidgets('a permission already granted is used without a word', (
    tester,
  ) async {
    system.states[AppPermission.camera] = PermissionState.granted;
    final host = await pumpHost(tester);
    expect(await gate.request(AppPermission.camera, context: host), isTrue);
    expect(find.byType(AppDialog), findsNothing);
    expect(system.prompted, isEmpty);
  });

  testWidgets('the app says why before the system asks', (tester) async {
    final host = await pumpHost(tester);
    final granted = gate.request(AppPermission.location, context: host);
    await tester.pumpAndSettle();

    expect(find.text('Allow location access'), findsOneWidget);
    expect(find.textContaining('work area'), findsOneWidget);
    // The system waits while the user reads.
    expect(system.prompted, isEmpty);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(system.prompted, [AppPermission.location]);
    expect(await granted, isTrue);
  });

  testWidgets('"Not now" leaves the system unasked', (tester) async {
    final host = await pumpHost(tester);
    final granted = gate.request(AppPermission.camera, context: host);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await granted, isFalse);
    expect(system.prompted, isEmpty);
  });

  testWidgets('a refusal in the system prompt is respected on the spot', (
    tester,
  ) async {
    system.answer = PermissionState.blocked;
    final host = await pumpHost(tester);
    final granted = gate.request(AppPermission.camera, context: host);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(await granted, isFalse);
    // No settings pushed at the user right after they said no.
    expect(find.byType(AppDialog), findsNothing);
    expect(system.settingsOpened, 0);
  });

  testWidgets('once the system no longer asks, the settings are offered', (
    tester,
  ) async {
    system.states[AppPermission.camera] = PermissionState.blocked;
    final host = await pumpHost(tester);
    final granted = gate.request(AppPermission.camera, context: host);
    await tester.pumpAndSettle();

    expect(find.text('Allow access in Settings'), findsOneWidget);
    expect(find.textContaining('Camera access is turned off'), findsOneWidget);
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(system.settingsOpened, 1);
    expect(system.prompted, isEmpty);
    expect(await granted, isFalse);
  });

  testWidgets('with once, the app explains only the first time', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    final first = gate.request(
      AppPermission.notifications,
      context: host,
      once: true,
    );
    await tester.pumpAndSettle();
    expect(find.text('Turn on notifications'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await first, isFalse);

    expect(
      await gate.request(
        AppPermission.notifications,
        context: host,
        once: true,
      ),
      isFalse,
    );
    await tester.pump();
    expect(find.byType(AppDialog), findsNothing);
    expect(system.prompted, isEmpty);
  });

  testWidgets('several permissions are asked in turn, stopping at a no', (
    tester,
  ) async {
    final host = await pumpHost(tester);
    final refused = gate.requestAll(const [
      AppPermission.location,
      AppPermission.camera,
    ], context: host);
    await tester.pumpAndSettle();
    expect(find.text('Allow location access'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(await refused, isFalse);
    expect(find.text('Allow camera access'), findsNothing);

    final both = gate.requestAll(const [
      AppPermission.location,
      AppPermission.camera,
    ], context: host);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Allow camera access'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(await both, isTrue);
    expect(system.prompted, [AppPermission.location, AppPermission.camera]);
  });

  testWidgets('every explanation fits a small screen with large text', (
    tester,
  ) async {
    for (final permission in AppPermission.values) {
      for (final state in [PermissionState.denied, PermissionState.blocked]) {
        system.states[permission] = state;
        final host = await pumpHost(
          tester,
          size: const Size(320, 568),
          textScale: 2,
        );
        final asked = gate.request(permission, context: host);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$permission $state');
        await tester.tap(find.text('Not now'));
        await tester.pumpAndSettle();
        expect(await asked, isFalse);
      }
    }
  });

  test('with no screen to explain on, the system asks directly', () async {
    expect(await gate.isGranted(AppPermission.camera), isFalse);
    expect(await gate.request(AppPermission.camera), isTrue);
    expect(system.prompted, [AppPermission.camera]);
    expect(await gate.isGranted(AppPermission.camera), isTrue);
  });
}
