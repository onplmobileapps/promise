import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/core/update/play_app_updater.dart';
import 'package:railway_hrms/core/update/store_listing_updater.dart';

/// The store listing's update, standing in for the fallback.
class _ListingUpdate implements AppUpdate {
  @override
  Future<void> start(BuildContext context) async {}
}

class _FakeListing implements AppUpdater {
  final update = _ListingUpdate();
  int checks = 0;

  @override
  Future<AppUpdate?> check() async {
    checks++;
    return update;
  }
}

AppUpdateInfo _play(UpdateAvailability availability, {bool immediate = true}) =>
    AppUpdateInfo(
      updateAvailability: availability,
      immediateUpdateAllowed: immediate,
      immediateAllowedPreconditions: null,
      flexibleUpdateAllowed: true,
      flexibleAllowedPreconditions: null,
      availableVersionCode: 42,
      installStatus: InstallStatus.unknown,
      packageName: 'com.onnetwork.hrms.app',
      clientVersionStalenessDays: null,
      updatePriority: 0,
    );

void main() {
  late _FakeListing listing;
  late int playScreens;

  setUp(() {
    listing = _FakeListing();
    playScreens = 0;
  });

  PlayAppUpdater updater(
    Future<AppUpdateInfo> Function() check, {
    Future<AppUpdateResult> Function()? perform,
  }) => PlayAppUpdater(
    fallback: listing,
    checkForUpdate: check,
    performImmediateUpdate:
        perform ??
        () async {
          playScreens++;
          return AppUpdateResult.success;
        },
  );

  Future<BuildContext> anyScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    return tester.element(find.byType(SizedBox));
  }

  test('offers nothing when Play has nothing newer', () async {
    for (final availability in [
      UpdateAvailability.updateNotAvailable,
      UpdateAvailability.unknown,
    ]) {
      expect(await updater(() async => _play(availability)).check(), isNull);
    }
    expect(listing.checks, 0);
  });

  testWidgets("runs Play's own update screen when Play has an update", (
    tester,
  ) async {
    final update = await updater(
      () async => _play(UpdateAvailability.updateAvailable),
    ).check();
    expect(update, isNot(same(listing.update)));
    await update!.start(await anyScreen(tester));
    expect(playScreens, 1);
    expect(listing.checks, 0);
  });

  testWidgets('carries on with an update left unfinished', (tester) async {
    final update = await updater(
      () async => _play(UpdateAvailability.developerTriggeredUpdateInProgress),
    ).check();
    await update!.start(await anyScreen(tester));
    expect(playScreens, 1);
  });

  test("sends to the Play page when Play won't run its screen", () async {
    final update = await updater(
      () async => _play(UpdateAvailability.updateAvailable, immediate: false),
    ).check();
    // Play already knows of the update, so there is nothing to look up.
    expect(update, isA<StoreUpdate>());
    expect(listing.checks, 0);
  });

  test("asks the store listing when Play didn't install the app", () async {
    final update = await updater(
      () async => throw PlatformException(
        code: 'TASK_FAILURE',
        message: 'Install Error(-10): The app is not owned by any user.',
      ),
    ).check();
    expect(update, same(listing.update));
  });

  testWidgets('a declined or failed update leaves the user where they were', (
    tester,
  ) async {
    final screen = await anyScreen(tester);
    for (final perform in <Future<AppUpdateResult> Function()>[
      () async => AppUpdateResult.userDeniedUpdate,
      () async => AppUpdateResult.inAppUpdateFailed,
      () async => throw PlatformException(code: 'ERROR'),
    ]) {
      final update = await updater(
        () async => _play(UpdateAvailability.updateAvailable),
        perform: perform,
      ).check();
      await expectLater(update!.start(screen), completes);
    }
  });
}
