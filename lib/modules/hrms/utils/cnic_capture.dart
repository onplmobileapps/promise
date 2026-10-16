import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';

/// Sends the CNIC's [photo] (attachment type 2) and the face's [facePhoto]
/// (type 3) to the employee's attachments in one multipart request: those
/// of [employeeId], or of the signed-in employee. It goes through the
/// app's [client], so an expired session is renewed on the way.
///
/// Resolves to null once the server has them, or to what went wrong.
Future<String?> uploadCnicAttachment(
  XFile photo, {
  String? employeeId,
  XFile? facePhoto,
  DioClient? client,
}) async {
  try {
    final login = await StorageService.getUser();
    final empId = (employeeId != null && employeeId.isNotEmpty)
        ? employeeId
        : (login?.user?.empid?.toString() ?? login?.user?.id?.toString() ?? '');

    final formData = FormData();
    formData.fields.add(MapEntry('emp', empId));

    // Attachment Type 2: CNIC
    formData.fields.add(const MapEntry('attachment_type', '2'));
    final cnicName = photo.name.isNotEmpty ? photo.name : 'cnic.jpg';
    formData.files.add(
      MapEntry(
        'attachment',
        await MultipartFile.fromFile(photo.path, filename: cnicName),
      ),
    );

    // Attachment Type 3: Face (if provided)
    if (facePhoto != null) {
      final faceFile = File(facePhoto.path);
      if (await faceFile.exists() && await faceFile.length() > 0) {
        formData.fields.add(const MapEntry('attachment_type', '3'));
        final faceName = facePhoto.name.isNotEmpty
            ? facePhoto.name
            : 'face.jpg';
        formData.files.add(
          MapEntry(
            'attachment',
            await MultipartFile.fromFile(facePhoto.path, filename: faceName),
          ),
        );
      } else {
        debugPrint('The face photo is missing: ${facePhoto.path}');
      }
    }

    await (client ?? sl<DioClient>()).post(
      ApiEndpoints.uploadCNIC,
      data: formData,
    );
    return null;
  } catch (error) {
    debugPrint('The CNIC and face attachments failed to upload: $error');
    return ErrorHandler.handle(error).message;
  }
}

/// [photo] ready to upload.
Future<MultipartFile> cnicUpload(XFile photo) =>
    MultipartFile.fromFile(photo.path, filename: 'cnic.jpg');
