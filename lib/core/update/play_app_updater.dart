import 'package:flutter/widgets.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:railway_hrms/core/update/app_updater.dart';
import 'package:railway_hrms/core/update/store_listing_updater.dart';

/// Updates through Google Play's own in-app update screen: Play downloads
/// and installs the new version over the app, then restarts it.
///
/// Play only knows about installs it made, so for any other, such as a
/// debug build, and for updates its screen won't run, it hands over to
/// [fallback].
class PlayAppUpdater implements AppUpdater {
  PlayAppUpdater({
    required AppUpdater fallback,
    Future<AppUpdateInfo> Function()? checkForUpdate,
    Future<AppUpdateResult> Function()? performImmediateUpdate,
  }) : _fallback = fallback,
       _checkForUpdate = checkForUpdate ?? InAppUpdate.checkForUpdate,
       _performImmediateUpdate =
           performImmediateUpdate ?? InAppUpdate.performImmediateUpdate;

  final AppUpdater _fallback;
  final Future<AppUpdateInfo> Function() _checkForUpdate;
  final Future<AppUpdateResult> Function() _performImmediateUpdate;

  @override
  Future<AppUpdate?> check() async {
    final AppUpdateInfo info;
    try {
      info = await _checkForUpdate();
    } on Exception catch (error) {
      debugPrint('Google Play update check failed: $error');
      return _fallback.check();
    }
    switch (info.updateAvailability) {
      // An update started earlier and left unfinished: carry on with it.
      case UpdateAvailability.developerTriggeredUpdateInProgress:
        return _PlayUpdate(_performImmediateUpdate);
      case UpdateAvailability.updateAvailable:
        // Play knows of it but can't install it here: its store page can.
        return info.immediateUpdateAllowed
            ? _PlayUpdate(_performImmediateUpdate)
            : const StoreUpdate();
      case UpdateAvailability.updateNotAvailable:
      case UpdateAvailability.unknown:
        return null;
    }
  }
}

class _PlayUpdate implements AppUpdate {
  const _PlayUpdate(this._perform);

  final Future<AppUpdateResult> Function() _perform;

  @override
  Future<void> start(BuildContext context) async {
    try {
      // Play takes over the screen. Once installed, the app restarts into
      // the new version; if the user declines, they carry on and are asked
      // again on the next launch.
      final result = await _perform();
      if (result == AppUpdateResult.inAppUpdateFailed) {
        debugPrint('Google Play could not update the app.');
      }
    } on Exception catch (error) {
      debugPrint('Google Play update failed: $error');
    }
  }
}
