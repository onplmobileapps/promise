import 'package:permission_handler/permission_handler.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';

/// Where a permission stands with the system.
enum PermissionState {
  /// The app may use it.
  granted,

  /// Not granted, but the system will still ask.
  denied,

  /// Not granted, and the system won't ask again: only the app's settings
  /// can change it.
  blocked,
}

/// The system's side of permissions, behind an interface so tests can stand
/// in for it.
abstract interface class PermissionPlatform {
  Future<PermissionState> status(AppPermission permission);

  /// Shows the system's prompt, if the system will still show it.
  Future<PermissionState> request(AppPermission permission);

  /// Opens the app's page in the system settings.
  Future<bool> openSettings();
}

/// The real thing, through permission_handler.
class SystemPermissions implements PermissionPlatform {
  const SystemPermissions();

  static Permission _of(AppPermission permission) => switch (permission) {
    AppPermission.camera => Permission.camera,
    AppPermission.location => Permission.locationWhenInUse,
    AppPermission.notifications => Permission.notification,
  };

  static PermissionState _state(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.limited ||
    PermissionStatus.provisional => PermissionState.granted,
    PermissionStatus.denied => PermissionState.denied,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => PermissionState.blocked,
  };

  @override
  Future<PermissionState> status(AppPermission permission) async =>
      _state(await _of(permission).status);

  @override
  Future<PermissionState> request(AppPermission permission) async =>
      _state(await _of(permission).request());

  @override
  Future<bool> openSettings() => openAppSettings();
}
