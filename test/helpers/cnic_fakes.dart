import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/media/cnic/cnic_camera.dart';

/// The scan the stand-in camera takes.
final fakeCnicScan = CnicScan(photo: XFile('/nowhere/cnic.jpg'));

/// A stand-in for the CNIC camera, for screens that lay it in: "Take"
/// takes [fakeCnicScan], "Shut" closes it.
Widget fakeCnicCamera(
  ValueChanged<CnicScan> onCaptured,
  VoidCallback onClose,
) => Row(
  children: [
    TextButton(
      onPressed: () => onCaptured(fakeCnicScan),
      child: const Text('Take'),
    ),
    TextButton(onPressed: onClose, child: const Text('Shut')),
  ],
);
