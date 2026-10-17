import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/locomotive/locomotive_form.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/local_spec_store.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_inspection_screen.dart';

/// A GEU-40 locomotive's inspection, cab to load test: the face first,
/// each part as a step, a fault asking what was found, and the signed
/// report kept on the phone, as there is no server for it yet.
class LocomotiveInspectionScreen extends StatelessWidget {
  const LocomotiveInspectionScreen({super.key, this.verifier});

  /// Where its draft is kept; also its entry among the dashboard's drafts.
  static const draftId = 'locomotive_inspection_draft_v1';

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SpecInspectionScreen(
      title: l10n.inspLocomotiveTitle,
      subtitle: l10n.inspLocomotiveSubtitle,
      specs: kLocomotiveSpecs,
      glyph: AppGlyphs.wrench,
      verifier: verifier,
      store: LocalSpecStore(
        id: draftId,
        type: 'locomotive',
        title: l10n.inspLocomotiveTitle,
      ),
    );
  }
}
