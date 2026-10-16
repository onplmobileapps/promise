import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/navigation/navigator_key.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for device permissions the considerate way. The app first says, in
/// its own dialog, what it needs the permission for, and only if the user
/// goes on does the system ask. Once the system won't ask any more, the app
/// offers its settings page instead.
///
/// A permission the user has just refused isn't asked about again on the
/// spot; the next time a feature needs it, the settings are offered.
class PermissionGate {
  PermissionGate({
    PermissionPlatform platform = const SystemPermissions(),
    Future<SharedPreferences> Function()? preferences,
  }) : _platform = platform,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final PermissionPlatform _platform;
  final Future<SharedPreferences> Function() _preferences;

  static const _offeredKey = 'permission_offered';

  /// Whether the app may use [permission], asking for it if need be.
  ///
  /// The dialogs show over [context], or over the current screen when there
  /// is none, as for a service. With [once], the app explains only the
  /// first time and afterwards leaves a missing permission alone: for one it
  /// can do without, like notifications.
  Future<bool> request(
    AppPermission permission, {
    BuildContext? context,
    bool once = false,
  }) {
    // Asked again while already asking, the same answer serves both: one
    // explanation, one system prompt.
    final asking = _asking[permission];
    if (asking != null) return asking;
    final answer = _ask(permission, context: context, once: once);
    _asking[permission] = answer;
    return answer.whenComplete(() => _asking.remove(permission));
  }

  final _asking = <AppPermission, Future<bool>>{};

  Future<bool> _ask(
    AppPermission permission, {
    BuildContext? context,
    bool once = false,
  }) async {
    final state = await _platform.status(permission);
    if (state == PermissionState.granted) return true;
    if (once && !await _firstOffer(permission)) return false;

    final screen = context ?? navigatorKey.currentContext;
    // With nowhere to explain, the system's prompt is all there is.
    if (screen == null || !screen.mounted) {
      return state == PermissionState.denied &&
          await _platform.request(permission) == PermissionState.granted;
    }
    final l10n = screen.l10n;

    if (state == PermissionState.blocked) {
      final open = await showAppDialog(
        context: screen,
        tone: AppDialogTone.warning,
        glyph: permission.glyph,
        title: l10n.permissionBlockedTitle,
        message: permission.blocked(l10n),
        primaryLabel: l10n.permissionOpenSettings,
        secondaryLabel: l10n.permissionNotNow,
      );
      if (open ?? false) await _platform.openSettings();
      return false;
    }

    final goOn = await showAppDialog(
      context: screen,
      tone: AppDialogTone.info,
      glyph: permission.glyph,
      title: permission.title(l10n),
      message: permission.reason(l10n),
      primaryLabel: l10n.actionContinue,
      secondaryLabel: l10n.permissionNotNow,
    );
    if (!(goOn ?? false)) return false;
    return await _platform.request(permission) == PermissionState.granted;
  }

  /// Opens the app's page in the system settings, where permissions can be
  /// changed.
  Future<bool> openSettings() => _platform.openSettings();

  /// Whether the app may already use [permission]; never asks.
  Future<bool> isGranted(AppPermission permission) async =>
      await _platform.status(permission) == PermissionState.granted;

  /// Asks for each of [permissions] in turn, stopping at the first refused;
  /// true when all are granted. For a feature that needs several at once,
  /// so they're settled before it starts.
  Future<bool> requestAll(
    List<AppPermission> permissions, {
    BuildContext? context,
  }) async {
    for (final permission in permissions) {
      if (context != null && !context.mounted) return false;
      if (!await request(permission, context: context)) return false;
    }
    return true;
  }

  /// Whether this is the first time [permission] is offered, noting that it
  /// now has been.
  Future<bool> _firstOffer(AppPermission permission) async {
    final preferences = await _preferences();
    final key = '$_offeredKey.${permission.name}';
    if (preferences.getBool(key) ?? false) return false;
    await preferences.setBool(key, true);
    return true;
  }
}
