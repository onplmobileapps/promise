import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_inspection_catalog.dart';
import 'package:railway_hrms/modules/inspection/electrical/screens/electrical_asset_form_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// An electrical (RTL) inspection: the face first, then the day, the role
/// inspected as and the places covered, and on to their checks.
class ElectricalRtlInspectionScreen extends StatelessWidget {
  const ElectricalRtlInspectionScreen({super.key, this.verifier});

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: context.l10n.inspElectrical,
    verifier: verifier,
    child: const _RtlSetup(),
  );
}

class _RtlSetup extends StatefulWidget {
  const _RtlSetup();

  @override
  State<_RtlSetup> createState() => _RtlSetupState();
}

class _RtlSetupState extends State<_RtlSetup> {
  static const _places = ['Workshop', 'Washing Line', 'Station'];
  static const _roles = [
    'Officer / Inspector',
    'Supervisor / JE / SSE',
    'Electrical Staff / Technician',
  ];

  DateTime _date = DateTime.now();
  String _role = _roles.first;
  final Set<String> _chosen = {};

  Future<void> _start() async {
    final l10n = context.l10n;
    if (_chosen.isEmpty) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.inspRtlPlaces,
        message: l10n.inspRtlPickPlace,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    // In the order they are offered, whatever order they were picked in.
    final places = [
      for (final place in _places)
        if (_chosen.contains(place)) place,
    ];
    final asset = places.join(', ');
    final assetData = {
      'inspection_date': _date.toIso8601String(),
      'role': _role,
      'assets': places,
    };
    final fields = ElectricalInspectionCatalog.resolveFields(
      'Electrical',
      'RTL',
      places,
      {...assetData, 'coach_type': 'German', 'category': 'AC Sleeper'},
      role: _role,
    );
    if (fields == null || fields.isEmpty) return;
    final formId = 'electrical_rtl_${places.join('_')}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
    await pushInspectionPage<void>(
      context,
      replace: true,
      (_) => ElectricalAssetFormScreen(
        department: 'Electrical',
        subDepartment: 'RTL',
        asset: asset,
        fields: fields,
        formId: formId,
        assetData: assetData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final now = DateTime.now();
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.inspElectrical,
            subtitle: l10n.inspElectricalSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          InspectionCard(
            title: l10n.inspFormDetails,
            glyph: AppGlyphs.zap,
            children: [
              InspectionDateInput(
                label: l10n.inspFormDate,
                value: _date,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now,
                onChanged: (day) => setState(() => _date = day),
              ),
              InspectionChoiceInput(
                label: l10n.inspRtlRole,
                options: _roles,
                value: _role,
                onChanged: (role) => setState(() => _role = role),
              ),
            ],
          ),
          AppSpacing.gapXl,
          AppSectionLabel(l10n.inspRtlPlaces),
          AppSpacing.gapSm,
          AppListGroup(
            children: [
              for (final place in _places)
                AppListRow(
                  leading: AppIconTile(
                    size: AppSizes.rowTile,
                    child: AppGlyphIcon(
                      switch (place) {
                        'Workshop' => AppGlyphs.wrench,
                        'Washing Line' => AppGlyphs.train,
                        _ => AppGlyphs.station,
                      },
                      size: AppSizes.iconMd,
                      color: colors.iconAccent,
                      depth: true,
                    ),
                  ),
                  title: place,
                  selected: _chosen.contains(place),
                  trailing: AppCheckbox(
                    value: _chosen.contains(place),
                    onChanged: (_) => _toggle(place),
                  ),
                  onTap: () => _toggle(place),
                ),
            ],
          ),
          AppSpacing.gapXl,
          AppButton(
            label: l10n.inspFormStart,
            trailingGlyph: AppGlyphs.arrowRight,
            onPressed: _start,
          ),
        ],
      ),
    );
  }

  void _toggle(String place) => setState(
    () => _chosen.contains(place) ? _chosen.remove(place) : _chosen.add(place),
  );
}
