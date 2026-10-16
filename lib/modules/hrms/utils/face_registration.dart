import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/screens/face_registration_view.dart';
import 'package:railway_hrms/modules/hrms/utils/cnic_capture.dart';

/// Sends [registration] for [employeeId]: their face's photos and their
/// CNIC. With [own], the signed-in employee is remembered as registered.
/// Null when it went through, or what went wrong.
Future<String?> sendFaceRegistration(
  FaceRepository repository,
  String employeeId,
  FaceRegistration registration, {
  bool own = true,
}) async {
  final response = await repository.registerFace(
    employeeId,
    [
      for (final image in registration.images)
        await MultipartFile.fromFile(image.path, filename: image.name),
    ],
    registration.embeddings,
    0,
    0,
    cnicImage: await cnicUpload(registration.cnic),
  );
  return response.fold((failure) async => failure.message, (_) async {
    if (own) {
      final login = await StorageService.getUser();
      if (login != null) {
        await StorageService.saveUser(
          login.copyWith(
            user: login.user?.copyWith(
              faceRegistered: true,
              verificationStatus: 'InProgress',
            ),
          ),
        );
      }
    }
    return null;
  });
}

/// Displays a progress dialog with a 3-step stepper (Pending -> InProgress -> Verified).
Future<bool?> showVerificationProgressDialog(
  BuildContext context, {
  int step = 1,
}) {
  final l10n = context.l10n;
  const steps = ['Pending', 'InProgress', 'Verified'];
  final safeStep = step.clamp(0, steps.length - 1);
  return showAppDialog(
    context: context,
    tone: AppDialogTone.info,
    glyph: AppGlyphs.clock,
    title: l10n.verificationInProgressTitle,
    message: l10n.verificationInProgressMessage,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppProgressSteps(
          steps: steps,
          current: safeStep,
          semanticLabel: l10n.cnicStepOf(
            safeStep + 1,
            steps.length,
            steps[safeStep],
          ),
        ),
      ],
    ),
    primaryLabel: l10n.actionOk,
  );
}

/// Whether the signed-in employee still has to register their face.
Future<bool> faceRegistrationNeeded() async {
  final user = (await StorageService.getUser())?.user;
  return user != null && user.isPending;
}

/// The setup is open, so a second ask doesn't open it twice.
bool _setupOpen = false;

/// Opens the face check-in setup straight away when the signed-in
/// employee hasn't registered their face yet; true once they have, before
/// or now.
Future<bool> ensureFaceRegistered(BuildContext context) async {
  final user = (await StorageService.getUser())?.user;
  if (user?.isApproved == true) return true;
  if (user?.isInProgress == true) {
    if (context.mounted) {
      await showVerificationProgressDialog(context);
    }
    return false;
  }
  if (_setupOpen) return false;
  final login = await StorageService.getUser();
  final employeeId = login?.user?.empid?.toString() ?? '';
  if (!context.mounted) return false;
  _setupOpen = true;
  try {
    final registration = await FaceRegistrationView.open(
      context,
      onRegister: (registration) =>
          sendFaceRegistration(sl<FaceRepository>(), employeeId, registration),
    );
    if (registration != null && context.mounted) {
      await showVerificationProgressDialog(context);
    }
    return registration != null;
  } finally {
    _setupOpen = false;
  }
}
