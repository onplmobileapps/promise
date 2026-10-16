import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

/// Takes a photo with the camera or picks one from the gallery. Before the
/// camera opens, the app explains why it needs it and asks.
abstract final class PhotoPicker {
  /// The photo, or null when the user cancels or doesn't allow the camera.
  static Future<XFile?> pick({
    required ImageSource source,
    BuildContext? context,
    CameraDevice camera = CameraDevice.rear,
    int? imageQuality,
    double? maxWidth,
  }) async {
    if (source == ImageSource.camera &&
        !await sl<PermissionGate>().request(
          AppPermission.camera,
          context: context,
        )) {
      return null;
    }
    return ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
  }
}
