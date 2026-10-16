import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:railway_hrms/core/bloc/safe_bloc.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_attendance_outcome.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_register_states.dart';
import 'package:railway_hrms/modules/hrms/screens/face_registration_view.dart';
import 'package:railway_hrms/modules/hrms/utils/face_registration.dart';

/// The photos a face check sends.
const _checkPhotos = 2;

class FaceVerificationCubit extends SafeCubit<FaceRegisterStates> {
  final FaceRepository _profileRepository;

  /// Counts attendance marked anywhere in the app (the HRMS card, the hub's
  /// capture button, others' attendance), so open HRMS screens reload.
  static final ValueNotifier<int> attendanceMarked = ValueNotifier<int>(0);

  FaceVerificationCubit(this._profileRepository)
    : super(FaceVerifyInitialState()) {
    // Load + warm the face models while the user is still on the dashboard
    // (deferred on low-end devices so it never competes with the UI).
    FaceKit.preload();
  }

  Future<void> checkInWithFace(BuildContext context) async {
    try {
      // Location and the camera then run side by side, so both are settled
      // first, each explained before the system asks.
      final allowed = await sl<PermissionGate>().requestAll(const [
        AppPermission.location,
        AppPermission.camera,
      ], context: context);
      if (!allowed || !context.mounted) return;
      emit(FaceVerifying());

      // A rooted phone can fake where it is; it marks no attendance.
      final blocked = (await DeviceIntegrity.check()).blockReason();
      if (blocked != null) {
        emit(FaceVerifyError(blocked));
        return;
      }

      // Location is resolved while the user is looking at the camera.
      Object? locationError;
      final Future<Position?> positionFuture =
          CurrentLocationService.getCurrentLocation().then<Position?>(
            (p) => p,
            onError: (Object e) {
              log('Location error: $e');
              locationError = e;
              return null;
            },
          );

      // Check user verification status
      final user = await StorageService.getUser();
      final userData = user?.user;
      final employeeId = userData?.empid?.toString() ?? '';

      if (!context.mounted) return;

      if (userData?.isInProgress == true) {
        await showVerificationProgressDialog(context);
        emit(FaceVerifyInitialState());
        return;
      }

      // The first time, the face is registered on its own screen, in two
      // steps with the CNIC. After admin approval, one look at the camera is enough.
      final List<XFile> images;
      final List<List<double>> embeddings;
      if (userData?.isApproved == true) {
        // The camera closes within a moment of seeing a face; recognition
        // and liveness finish in the background while FaceVerifying shows.
        final l10n = context.l10n;
        final result = await FaceCapture.open(
          context,
          mode: CaptureMode.verification,
          // The design's camera, as the second step of checking in: the
          // location and the phone were checked before it opened.
          layout: FaceCaptureScreen.layoutWith(
            steps: [
              l10n.faceStepLocation,
              l10n.cnicStepFace,
              l10n.cnicStepDone,
            ],
            step: 1,
            checks: [
              (label: l10n.faceCheckArea, passed: true),
              (label: l10n.faceCheckLive, passed: false),
              (label: l10n.faceCheckDevice, passed: true),
            ],
          ),
        );
        switch (result) {
          case FaceCaptureFailedResult(:final message):
            emit(FaceVerifyError(message));
            return;
          // Two photos check the face; fewer can't be sent.
          case FaceVerificationResult()
              when result.images.length >= _checkPhotos:
            images = result.images.take(_checkPhotos).toList();
            embeddings = result.embeddings.take(_checkPhotos).toList();
          case FaceVerificationResult():
            emit(
              FaceVerifyError(
                'Could not capture a clear face. Please try again.',
              ),
            );
            return;
          default:
            emit(FaceVerifyInitialState());
            return;
        }
      } else {
        final registration = await FaceRegistrationView.open(
          context,
          onRegister: (registration) => sendFaceRegistration(
            _profileRepository,
            employeeId,
            registration,
          ),
        );
        if (registration == null) {
          emit(FaceVerifyInitialState());
          return;
        }
        if (context.mounted) {
          await showVerificationProgressDialog(context);
        }
        emit(FaceVerifyInitialState());
        return;
      }

      if (images.isEmpty) {
        emit(FaceVerifyInitialState());
        return;
      }

      final position = await positionFuture;
      if (position == null) {
        final error = locationError;
        emit(
          FaceVerifyError(
            error is LocationSpoofedException
                ? error.message
                : 'Turn on location and allow the app to use it, then try again.',
          ),
        );
        return;
      }

      // Convert to MultipartFile
      List<MultipartFile> multipartImages = [];
      for (var image in images) {
        multipartImages.add(await MultipartFile.fromFile(image.path));
      }
      await verifyFace(
        employeeId,
        multipartImages,
        embeddings,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      log('Face check-in failed: $e');
      emit(FaceVerifyError('Face capture failed. Please try again.'));
    }
  }

  Future<void> verifyFace(
    String employeeId,
    List<MultipartFile> images,
    List<List<double>> embeddings,
    double latitude,
    double longitude,
  ) async {
    emit(FaceVerifying());
    final response = await _profileRepository.verifyFace(
      employeeId,
      images,
      embeddings,
      latitude,
      longitude,
    );
    await response.fold(
      (failure) async => emit(FaceVerifyError(failure.message)),
      (response) async {
        final outcome = FaceAttendanceOutcome.fromResponse(response.data);
        if (!outcome.success) {
          emit(FaceVerifyError(outcome.message));
          return;
        }
        emit(FaceVerified(outcome.message));
        attendanceMarked.value++;
        await _notify(outcome.message);
      },
    );
  }

  /// A system notification of the marked attendance. Failing to show it
  /// doesn't undo the attendance.
  Future<void> _notify(String message) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'attendance_channel',
          'Attendance Notifications',
          channelDescription: 'Notifications for attendance status',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await FlutterLocalNotificationsPlugin().show(
        id: 1,
        title: 'Attendance Status',
        body: message,
        notificationDetails: details,
      );
    } catch (e) {
      log('Attendance notification failed: $e');
    }
  }
}
