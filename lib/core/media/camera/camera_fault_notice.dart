import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';

/// A camera fault in the user's words: most say plainly that the phone's
/// camera, not the app, is at fault, and what to try.
extension CameraFaultWords on CameraFault {
  String title(AppLocalizations l10n) => switch (this) {
    CameraFault.denied => l10n.cameraFaultDeniedTitle,
    CameraFault.missing => l10n.cameraFaultMissingTitle,
    CameraFault.busy => l10n.cameraFaultBusyTitle,
    CameraFault.disabled => l10n.cameraFaultDisabledTitle,
    CameraFault.doNotDisturb => l10n.cameraFaultDoNotDisturbTitle,
    CameraFault.broken => l10n.cameraFaultBrokenTitle,
    CameraFault.noPicture => l10n.cameraFaultNoPictureTitle,
    CameraFault.black => l10n.cameraFaultBlackTitle,
    CameraFault.frozen => l10n.cameraFaultFrozenTitle,
  };

  String message(AppLocalizations l10n) => switch (this) {
    CameraFault.denied => l10n.cameraFaultDeniedMessage,
    CameraFault.missing => l10n.cameraFaultMissingMessage,
    CameraFault.busy => l10n.cameraFaultBusyMessage,
    CameraFault.disabled => l10n.cameraFaultDisabledMessage,
    CameraFault.doNotDisturb => l10n.cameraFaultDoNotDisturbMessage,
    CameraFault.broken => l10n.cameraFaultBrokenMessage,
    CameraFault.noPicture => l10n.cameraFaultNoPictureMessage,
    CameraFault.black => l10n.cameraFaultBlackMessage,
    CameraFault.frozen => l10n.cameraFaultFrozenMessage,
  };
}

/// Tells the user what is wrong with the camera, in the app's dialog, and
/// offers to try again, or for a camera not allowed, the settings. True
/// when they chose to try again.
Future<bool> showCameraFault(BuildContext context, CameraFault fault) async {
  if (!context.mounted) return false;
  final l10n = context.l10n;
  final denied = fault == CameraFault.denied;
  final choice = await showAppDialog(
    context: context,
    tone: AppDialogTone.error,
    glyph: AppGlyphs.cameraOff,
    title: fault.title(l10n),
    message: fault.message(l10n),
    primaryLabel: denied ? l10n.cameraFaultOpenSettings : l10n.actionRetry,
    secondaryLabel: l10n.actionClose,
  );
  if (choice != true) return false;
  if (denied) {
    await sl<PermissionGate>().openSettings();
    return false;
  }
  return true;
}

/// What is wrong with the camera, shown where its picture would be: a
/// camera struck through, what is wrong, and unless [compact], what to do;
/// with a way to try again, or for a camera not allowed, the settings.
class CameraFaultNotice extends StatelessWidget {
  const CameraFaultNotice({
    super.key,
    required this.fault,
    required this.onRetry,
    this.compact = false,
  });

  final CameraFault fault;
  final VoidCallback? onRetry;

  /// Only the title and the action, for a small window.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final denied = fault == CameraFault.denied;
    return Semantics(
      liveRegion: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppToneIcon(glyph: AppGlyphs.cameraOff, tone: AppTone.danger),
            AppSpacing.gapSm,
            Text(
              fault.title(l10n),
              textAlign: TextAlign.center,
              style: text.titleSmall,
            ),
            if (!compact) ...[
              AppSpacing.gapXs,
              Text(
                fault.message(l10n),
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
            AppSpacing.gapMd,
            AppButton(
              label: denied ? l10n.cameraFaultOpenSettings : l10n.actionRetry,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              expand: false,
              onPressed: denied
                  ? () => sl<PermissionGate>().openSettings()
                  : onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
