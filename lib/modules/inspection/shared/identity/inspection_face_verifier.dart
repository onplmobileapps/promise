import 'dart:async';

import 'package:camera/camera.dart' show XFile;
import 'package:dio/dio.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:railway_hrms/core/config/app_flags.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/face_verification/face_attendance_outcome.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';

/// When in an inspection the face is checked.
enum InspectionMoment {
  /// Before the first answer.
  start,

  /// After the report is read, before it is sent.
  submit,
}

/// How a face check went.
sealed class FaceCheckResult {
  const FaceCheckResult();
}

final class FaceCheckPassed extends FaceCheckResult {
  const FaceCheckPassed(this.identity);

  final InspectionIdentity identity;
}

final class FaceCheckFailed extends FaceCheckResult {
  const FaceCheckFailed(this.message);

  /// Why, for the employee.
  final String message;
}

/// The employee backed out, or refused the camera.
final class FaceCheckCancelled extends FaceCheckResult {
  const FaceCheckCancelled();
}

/// Checks that the person holding the phone is the employee signed in, as
/// an inspection starts and as it is submitted.
abstract interface class InspectionFaceVerifier {
  Future<FaceCheckResult> verify(BuildContext context, InspectionMoment moment);
}

/// Matches a face taken with no connection, once there is one: the check
/// matched, or why not. A [NetworkException] means there is still no
/// connection, and the check waits; anything else, that the face isn't
/// the employee's.
abstract interface class InspectionFaceMatcher {
  Future<Either<AppException, InspectionIdentity>> match(
    InspectionIdentity identity,
  );
}

/// Matches whichever of [signatures] were taken with no connection.
Future<Either<AppException, InspectionSignatures>> matchSignatures(
  InspectionSignatures signatures,
  InspectionFaceMatcher matcher,
) async {
  Future<Either<AppException, InspectionIdentity?>> one(
    InspectionIdentity? check,
  ) async => check == null || check.matched
      ? Right(check)
      : (await matcher.match(check)).fold(Left.new, Right.new);
  final start = await one(signatures.start);
  if (start case Left(:final value)) return Left(value);
  final submit = await one(signatures.submit);
  if (submit case Left(:final value)) return Left(value);
  return Right(
    InspectionSignatures(
      start: start.fold((_) => null, (check) => check),
      submit: submit.fold((_) => null, (check) => check),
    ),
  );
}

/// Checks the face as a check-in does: the camera takes it live (passive
/// liveness, one person, a clear frontal face), and the face server
/// matches it against the employee's registered face. The phone must be
/// genuine and its location real; where it was is noted with the photo.
///
/// With no connection the face is still taken live and kept, to be
/// matched (as [InspectionFaceMatcher]) before the inspection goes out.
///
/// This uses the face server's one verification endpoint, the one station
/// inspections already used. Should the server gain an inspection-only
/// check, it is the one place to change.
class ServerInspectionFaceVerifier
    implements InspectionFaceVerifier, InspectionFaceMatcher {
  ServerInspectionFaceVerifier(this._faces);

  final FaceRepository _faces;

  /// The photos a check sends, as a check-in's.
  static const int _photos = 2;

  /// The longest the location is waited for once the face is taken.
  static const Duration _placeWait = Duration(seconds: 8);

  @override
  Future<FaceCheckResult> verify(
    BuildContext context,
    InspectionMoment moment,
  ) async {
    // Turned off for testing away from the office (see [AppFlags]).
    if (!AppFlags.inspectionFaceCheck) {
      return FaceCheckPassed(
        InspectionIdentity(
          photoPath: '',
          verifiedAt: DateTime.now(),
          matched: true,
        ),
      );
    }
    final l10n = context.l10n;
    final allowed = await sl<PermissionGate>().requestAll(const [
      AppPermission.camera,
      AppPermission.location,
    ], context: context);
    if (!allowed || !context.mounted) return const FaceCheckCancelled();

    final blocked = (await DeviceIntegrity.check()).blockReason();
    if (blocked != null) return FaceCheckFailed(blocked);

    final user = (await StorageService.getUser())?.user;
    if (user?.isApproved != true) {
      return FaceCheckFailed(
        user?.isInProgress == true
            ? l10n.inspRegistrationPending
            : l10n.inspNotRegistered,
      );
    }

    // Where the phone is, found while the camera is up. A faked location
    // stops the check; one that can't be had in time doesn't.
    Object? placeError;
    final place = CurrentLocationService.getCurrentLocation().then<Position?>(
      (position) => position,
      onError: (Object error) {
        placeError = error;
        return null;
      },
    );

    if (!context.mounted) return const FaceCheckCancelled();
    final capture = await FaceCapture.open(
      context,
      mode: CaptureMode.verification,
      rootNavigator: false,
      layout: FaceCaptureScreen.layoutWith(
        steps: switch (moment) {
          InspectionMoment.start => [l10n.inspStepVerify, l10n.inspStepStart],
          InspectionMoment.submit => [
            l10n.inspStepReview,
            l10n.inspStepVerify,
            l10n.inspStepSubmit,
          ],
        },
        step: moment == InspectionMoment.start ? 0 : 1,
        checks: [
          (label: l10n.faceCheckLive, passed: false),
          (label: l10n.faceCheckDevice, passed: true),
        ],
      ),
    );
    final List<XFile> images;
    final List<List<double>> embeddings;
    switch (capture) {
      case FaceCaptureFailedResult(:final message):
        return FaceCheckFailed(message);
      case FaceVerificationResult() when capture.images.length >= _photos:
        images = capture.images.take(_photos).toList();
        embeddings = capture.embeddings.take(_photos).toList();
      case FaceVerificationResult():
        return FaceCheckFailed(l10n.faceIncompleteMessage);
      default:
        return const FaceCheckCancelled();
    }
    if (!context.mounted) return const FaceCheckCancelled();

    return _withProgress(context, l10n.inspVerifying, () async {
      final position = await place.timeout(_placeWait, onTimeout: () => null);
      if (placeError is LocationSpoofedException) {
        return FaceCheckFailed(
          (placeError! as LocationSpoofedException).message,
        );
      }
      final answer = await _faces.verifyFace(
        user!.empid?.toString() ?? '',
        [for (final image in images) await MultipartFile.fromFile(image.path)],
        embeddings,
        position?.latitude ?? 0,
        position?.longitude ?? 0,
      );
      return answer.fold<Future<FaceCheckResult>>(
        (failure) async {
          if (failure is! NetworkException) {
            return FaceCheckFailed(
              failure.message.isEmpty ? l10n.inspVerifyFailed : failure.message,
            );
          }
          // No connection: the live face is kept, to be matched before
          // the inspection goes out.
          final kept = [
            for (final image in images)
              await FootplateFileUtils.saveImagePermanently(image.path),
          ];
          return FaceCheckPassed(
            InspectionIdentity(
              photoPath: kept.first,
              verifiedAt: DateTime.now(),
              latitude: position?.latitude,
              longitude: position?.longitude,
              matched: false,
              photos: kept,
              embeddings: embeddings,
            ),
          );
        },
        (response) async {
          final outcome = FaceAttendanceOutcome.fromResponse(response.data);
          if (!outcome.success) {
            return FaceCheckFailed(
              outcome.notRegistered ? l10n.inspNotRegistered : outcome.message,
            );
          }
          final kept = await FootplateFileUtils.saveImagePermanently(
            images.first.path,
          );
          return FaceCheckPassed(
            InspectionIdentity(
              photoPath: kept,
              verifiedAt: DateTime.now(),
              latitude: position?.latitude,
              longitude: position?.longitude,
            ),
          );
        },
      );
    });
  }

  @override
  Future<Either<AppException, InspectionIdentity>> match(
    InspectionIdentity identity,
  ) async {
    if (identity.matched) return Right(identity);
    final user = (await StorageService.getUser())?.user;
    final photos = identity.photos.isEmpty
        ? [identity.photoPath]
        : identity.photos;
    final List<MultipartFile> files;
    try {
      files = [
        for (final path in photos)
          await MultipartFile.fromFile(
            await FootplateFileUtils.resolveAbsolutePath(path),
          ),
      ];
    } on Object {
      return Left(
        AppException("The face photo taken offline couldn't be read."),
      );
    }
    final answer = await _faces.verifyFace(
      user?.empid?.toString() ?? '',
      files,
      identity.embeddings,
      identity.latitude ?? 0,
      identity.longitude ?? 0,
    );
    return answer.fold(Left.new, (response) {
      final outcome = FaceAttendanceOutcome.fromResponse(response.data);
      if (!outcome.success) return Left(AppException(outcome.message));
      return Right(identity.asMatched());
    });
  }

  /// Runs [work] under a dialog saying [label], which can't be dismissed.
  static Future<FaceCheckResult> _withProgress(
    BuildContext context,
    String label,
    Future<FaceCheckResult> Function() work,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var open = true;
    unawaited(
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppLoader(label: label),
            ),
          ),
        ),
      ).whenComplete(() => open = false),
    );
    try {
      return await work();
    } catch (_) {
      return FaceCheckFailed(
        context.mounted ? context.l10n.inspVerifyFailed : '',
      );
    } finally {
      if (open) navigator.pop();
    }
  }
}
