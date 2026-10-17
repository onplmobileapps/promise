import 'package:face_kit/face_kit.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/media/camera/camera_fault_notice.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

/// Takes a photo with the camera or picks one from the gallery. Before the
/// camera opens, the app explains why it needs it and asks.
abstract final class PhotoPicker {
  /// The photo, or null when the user cancels or doesn't allow the camera.
  /// A camera that can't be used is explained in a dialog when there is a
  /// [context] to show it in, and tried again if the user asks.
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
    try {
      return await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    } on PlatformException catch (error) {
      if (source != ImageSource.camera || context == null || !context.mounted) {
        rethrow;
      }
      debugPrint('The camera failed to take a photo: $error');
      final fault = switch (error.code) {
        'camera_access_denied' => CameraFault.denied,
        'no_available_camera' => CameraFault.missing,
        _ => CameraHealth.faultOf(error) ?? CameraFault.broken,
      };
      if (!await showCameraFault(context, fault) || !context.mounted) {
        return null;
      }
      return pick(
        source: source,
        context: context,
        camera: camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
    }
  }
}
