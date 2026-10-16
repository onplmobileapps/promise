import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

class DeviceUtils {
  DeviceUtils._();

  /// Reusable Face Authentication handler.
  /// Directly launches [FaceCaptureView] on all devices.
  static Future<FaceVerificationResult?> performFaceVerification(
    BuildContext context,
  ) async {
    if (!context.mounted) return null;
    // Says why the camera is needed before the system asks.
    final allowed = await sl<PermissionGate>().request(
      AppPermission.camera,
      context: context,
    );
    if (!allowed || !context.mounted) return null;

    final result = await FaceCapture.open(
      context,
      mode: CaptureMode.verification,
      rootNavigator: false,
      layout: FaceCaptureScreen.layout,
    );
    return result is FaceVerificationResult ? result : null;
  }
}
