import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:railway_hrms/core/media/photo_picker.dart';
import 'package:railway_hrms/modules/inspection/shared/file_utils.dart';

/// Captures a selfie with the front camera, lets the user confirm or retake
/// it, then returns the permanently-saved image path. Returns null if the
/// user cancels without confirming a photo.
Future<String?> captureAndConfirmSelfie(
  BuildContext context, {
  required String title,
}) async {
  while (true) {
    if (!context.mounted) return null;
    final photo = await PhotoPicker.pick(
      source: ImageSource.camera,
      context: context,
      camera: CameraDevice.front,
      imageQuality: 70,
    );
    if (photo == null) return null; // user backed out of the camera

    if (!context.mounted) return null;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelfieConfirmSheet(title: title, imagePath: photo.path),
    );

    if (confirmed == true) {
      return FootplateFileUtils.saveImagePermanently(photo.path);
    }
    if (confirmed == null) return null; // dismissed without a choice
    // confirmed == false -> retake, loop back to camera
  }
}

class _SelfieConfirmSheet extends StatelessWidget {
  final String title;
  final String imagePath;
  const _SelfieConfirmSheet({required this.title, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Material(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirm this photo, or retake it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(File(imagePath), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.replay),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
