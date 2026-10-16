import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The device permissions the app asks for.
enum AppPermission {
  camera,
  location,
  notifications;

  /// The mark shown with the explanation.
  AppGlyph get glyph => switch (this) {
    camera => AppGlyphs.camera,
    location => AppGlyphs.mapPin,
    notifications => AppGlyphs.bell,
  };

  /// The heading of the explanation.
  String title(AppLocalizations l10n) => switch (this) {
    camera => l10n.permissionCameraTitle,
    location => l10n.permissionLocationTitle,
    notifications => l10n.permissionNotificationsTitle,
  };

  /// What the app uses it for, said before the system asks.
  String reason(AppLocalizations l10n) => switch (this) {
    camera => l10n.permissionCameraReason,
    location => l10n.permissionLocationReason,
    notifications => l10n.permissionNotificationsReason,
  };

  /// How to turn it back on, once the system no longer asks.
  String blocked(AppLocalizations l10n) => switch (this) {
    camera => l10n.permissionCameraBlocked,
    location => l10n.permissionLocationBlocked,
    notifications => l10n.permissionNotificationsBlocked,
  };
}
