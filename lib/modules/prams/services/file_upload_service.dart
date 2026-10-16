import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';

class FileUploadService {
  final ImagePicker _imagePicker = ImagePicker();

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  /// Pick photos from device gallery
  Future<List<File>> pickImagesFromGallery({
    required int currentCount,
    int maxAllowed = 5,
  }) async {
    final remainingSlots = maxAllowed - currentCount;
    if (remainingSlots <= 0) return [];

    // Use pickMultiImage for selecting multiple images from gallery
    final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return [];

    final validFiles = <File>[];

    // Limit to remaining available slots
    for (final xFile in pickedFiles.take(remainingSlots)) {
      final file = File(xFile.path);
      final fileSize = await file.length();

      if (fileSize <= maxFileSizeBytes) {
        validFiles.add(file);
      }
    }

    return validFiles;
  }

  /// Capture a new photo with camera
  Future<File?> capturePhotoFromCamera() async {
    // Says why the camera is needed before the system asks.
    final photo = await PhotoPicker.pick(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) return null;

    final file = File(photo.path);
    final fileSize = await file.length();

    if (fileSize <= maxFileSizeBytes) {
      return file;
    }

    return null;
  }
}
