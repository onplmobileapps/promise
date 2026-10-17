import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_inspection_screen.dart';

/// One proforma to start, as a row: what it is, a line on it, its glyph.
@immutable
class ProformaChoice {
  const ProformaChoice(
    this.definition, {
    required this.title,
    this.subtitle,
    this.glyph = AppGlyphs.clipboardList,
  });

  final ProformaDefinition definition;
  final String title;
  final String? subtitle;
  final AppGlyph glyph;
}

/// Proformas offered under one label, as the classes of locomotive.
@immutable
class ProformaGroup {
  const ProformaGroup(this.label, this.choices);

  final String label;
  final List<ProformaChoice> choices;
}

/// Where a kind of inspection is started: its proformas in [groups], each
/// saying whether one is under way, which then opens where it was left.
class ProformaLauncher extends StatefulWidget {
  const ProformaLauncher({
    super.key,
    required this.title,
    required this.groups,
    this.subtitle,
    this.verifier,
  });

  final String title;
  final String? subtitle;
  final List<ProformaGroup> groups;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  State<ProformaLauncher> createState() => _ProformaLauncherState();
}

class _ProformaLauncherState extends State<ProformaLauncher> {
  /// The proformas with a draft under way.
  Set<String> _drafts = const {};

  @override
  void initState() {
    super.initState();
    _findDrafts();
  }

  Future<void> _findDrafts() async {
    final drafts = <String>{};
    for (final group in widget.groups) {
      for (final choice in group.choices) {
        final id = choice.definition.draftId;
        final draft = await StorageService.getInspectionDraft(id);
        if (draft != null && draft.isNotEmpty) drafts.add(id);
      }
    }
    if (mounted) setState(() => _drafts = drafts);
  }

  Future<void> _open(ProformaDefinition definition) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProformaInspectionScreen(
          definition: definition,
          verifier: widget.verifier,
        ),
      ),
    );
    if (mounted) await _findDrafts();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: widget.title,
            subtitle: widget.subtitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          for (final group in widget.groups) ...[
            AppSpacing.gapXl,
            AppSectionLabel(group.label),
            AppSpacing.gapSm,
            AppListGroup(
              children: [
                for (final choice in group.choices)
                  AppListRow(
                    leading: AppIconTile(
                      size: AppSizes.rowTile,
                      child: AppGlyphIcon(
                        choice.glyph,
                        size: AppSizes.iconMd,
                        color: colors.iconAccent,
                        depth: true,
                      ),
                    ),
                    title: choice.title,
                    subtitle: choice.subtitle,
                    trailing: _drafts.contains(choice.definition.draftId)
                        ? AppPill(
                            l10n.inspProformaUnderway,
                            tone: AppTone.warning,
                          )
                        : null,
                    showChevron: true,
                    onTap: () => _open(choice.definition),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
