import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/material.dart';

import '../capture/face_capture_session.dart';
import '../engine/face_engine.dart' show kMinFaceSharpness;

const _kSuccess = Color(0xFF16A34A);
const _kError = Color(0xFFDC2626);

/// Shows the images produced by a face capture — exactly what will be sent
/// to the server on success, or the frames that were captured on failure.
///
/// Returns true when the user taps Continue on a successful capture. Cancel,
/// dismissing the dialog, or any failed capture returns false, and the caller
/// must then not send anything to the server.
Future<bool> showCapturedFacesDialog(
  BuildContext context,
  Object result,
) async {
  final (
    images,
    livenessScore,
    faceQuality,
    sharpness,
    title,
    message,
    ok,
  ) = switch (result) {
    FaceRegistrationResult r => (
      r.images,
      r.livenessScore,
      r.faceQuality,
      r.sharpness,
      'Registration images',
      '${r.images.length} images will be sent to the server',
      true,
    ),
    FaceVerificationResult r => (
      r.images,
      r.livenessScore,
      r.faceQuality,
      r.sharpness,
      'Verification images',
      '${r.images.length} images will be sent to the server',
      true,
    ),
    FaceCaptureFailedResult r => (
      r.images,
      r.livenessScore,
      r.faceQuality,
      r.sharpness,
      r.spoof ? 'Spoof detected' : 'Capture failed',
      '${r.message}\nNothing is sent to the server.',
      false,
    ),
    _ => (const <XFile>[], null, null, null, 'Face capture', '', false),
  };

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CapturedFacesDialog(
      images: images,
      livenessScore: livenessScore,
      faceQuality: faceQuality,
      sharpness: sharpness,
      title: title,
      message: message,
      ok: ok,
    ),
  );
  return ok && confirmed == true;
}

class _CapturedFacesDialog extends StatelessWidget {
  final List<XFile> images;
  final double? livenessScore;
  final double? faceQuality;
  final double? sharpness;
  final String title;
  final String message;
  final bool ok;

  const _CapturedFacesDialog({
    required this.images,
    required this.livenessScore,
    required this.faceQuality,
    required this.sharpness,
    required this.title,
    required this.message,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final color = ok ? _kSuccess : _kError;
    final scoreStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: color,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isNotEmpty)
              Text(message, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (livenessScore case final score?) ...[
              const SizedBox(height: 8),
              Text(
                'Liveness score: ${(score * 100).toStringAsFixed(0)}%',
                style: scoreStyle,
              ),
            ],
            if (faceQuality case final quality?) ...[
              const SizedBox(height: 4),
              Text(
                'Face quality: ${(quality * 100).toStringAsFixed(0)}%',
                style: scoreStyle,
              ),
            ],
            if (sharpness case final value?) ...[
              const SizedBox(height: 4),
              Text(
                'Sharpness: ${value.toStringAsFixed(0)} '
                '(blurry below ${kMinFaceSharpness.toStringAsFixed(0)})',
                style: scoreStyle,
              ),
            ],
            const SizedBox(height: 14),
            if (images.isEmpty)
              const Text(
                'No images available',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < images.length; i++)
                    _Thumbnail(image: images[i], index: i + 1),
                ],
              ),
          ],
        ),
      ),
      actions: ok
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('OK'),
              ),
            ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final XFile image;
  final int index;

  const _Thumbnail({required this.image, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            child: Image.file(File(image.path), fit: BoxFit.contain),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.file(
              File(image.path),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              cacheWidth: 216,
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
