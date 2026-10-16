import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/modules/hrms/bloc/face/face_verification_cubit.dart';

export 'package:railway_hrms/modules/hrms/utils/attendance_time.dart';

/// Opens a date picker and writes the picked day into [controller] as
/// "yyyy-MM-dd".
Future<void> selectDate(
  BuildContext context,
  TextEditingController controller, {
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final clampedFirst = firstDate ?? DateTime.now();
  final clampedLast = lastDate ?? DateTime.now();
  final now = DateTime.now();
  final initialDate = now.isBefore(clampedFirst) ? clampedFirst : now;
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: clampedFirst,
    lastDate: clampedLast,
    builder: (context, child) {
      final theme = Theme.of(context);
      return Theme(
        data: theme.copyWith(colorScheme: theme.colorScheme),
        child: child!,
      );
    },
  );

  if (picked != null) {
    final formattedDate =
        "${picked.year}-"
        "${picked.month.toString().padLeft(2, '0')}-"
        "${picked.day.toString().padLeft(2, '0')}";

    controller.text = formattedDate;
    log('✅ Date selected: $formattedDate');
  } else {
    log('⚠️ User cancelled date selection');
  }
}

/// Opens the camera to check in or out. The HRMS dashboard refreshes the
/// attendance once the face is verified.
Future<void> onCheckInTap(BuildContext context) =>
    context.read<FaceVerificationCubit>().checkInWithFace(context);
