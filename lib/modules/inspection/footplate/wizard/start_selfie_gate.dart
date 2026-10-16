import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/selfie_capture_sheet.dart';

/// Blocks the wizard until the inspector takes a "start of inspection"
/// selfie — mirrors the start-selfie verification pattern used elsewhere
/// in the app (e.g. attendance / other inspections) so every inspection
/// envelope is bounded by a start and end selfie.
class StartSelfieGate extends StatefulWidget {
  final String trainLabel;
  final ValueChanged<String> onCaptured; // returns saved image path

  const StartSelfieGate({
    super.key,
    required this.trainLabel,
    required this.onCaptured,
  });

  @override
  State<StartSelfieGate> createState() => _StartSelfieGateState();
}

class _StartSelfieGateState extends State<StartSelfieGate> {
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    final path = await captureAndConfirmSelfie(
      context,
      title: 'Start of Inspection Selfie',
    );
    if (!mounted) return;
    setState(() => _capturing = false);
    if (path != null) widget.onCaptured(path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.camera_front,
                  size: 44,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify You Are Starting This Inspection',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Take a selfie now to confirm you are beginning the footplate inspection${widget.trainLabel.isNotEmpty ? ' for ${widget.trainLabel}' : ''}. '
                'A matching selfie will be required again when you submit the inspection.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _capturing ? null : _capture,
                icon: _capturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _capturing ? 'Opening Camera...' : 'Take Start Selfie',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(240, 52),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
