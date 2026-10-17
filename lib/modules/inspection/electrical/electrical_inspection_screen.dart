import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/electrical/power/power_inspection.dart';
import 'package:railway_hrms/modules/inspection/electrical/rtl/rtl_inspection.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_launcher.dart';

/// Electrical inspections: of power installations, and of train lighting
/// (RTL), each on the proforma of the officer making it, with how often
/// that officer inspects.
class ElectricalInspectionScreen extends StatelessWidget {
  const ElectricalInspectionScreen({super.key, this.verifier});

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProformaLauncher(
      title: l10n.inspElectrical,
      subtitle: l10n.inspElectricalAbout,
      verifier: verifier,
      groups: [
        ProformaGroup(l10n.inspPowerGroup, [
          for (final power in powerDefinitions(l10n))
            ProformaChoice(
              power.definition,
              title: power.definition.subtitle ?? power.definition.title,
              subtitle: power.frequency,
              glyph: AppGlyphs.zap,
            ),
        ]),
        ProformaGroup(l10n.inspRtlGroup, [
          for (final rtl in rtlDefinitions(l10n))
            ProformaChoice(
              rtl.definition,
              title: rtl.definition.subtitle ?? rtl.definition.title,
              subtitle: rtl.frequency,
              glyph: AppGlyphs.lightbulb,
            ),
        ]),
      ],
    );
  }
}
