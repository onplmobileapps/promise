import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// Asks the concerned officer's approval for a footplate inspection: the
/// train, the day and times, and the route; once approved, the inspection
/// starts with them filled in.
class InspectionApprovalScreen extends StatefulWidget {
  const InspectionApprovalScreen({super.key});

  @override
  State<InspectionApprovalScreen> createState() =>
      _InspectionApprovalScreenState();
}

class _InspectionApprovalScreenState extends State<InspectionApprovalScreen> {
  String? _train;
  String _officer = '';
  String? _origin;
  String? _destination;
  DateTime? _date;
  TimeOfDay? _departure;
  TimeOfDay? _arrival;
  bool _approved = false;

  bool get _complete =>
      _train != null &&
      _officer.trim().isNotEmpty &&
      _date != null &&
      _departure != null &&
      _arrival != null &&
      _origin != null &&
      _destination != null;

  Future<void> _send() async {
    final l10n = context.l10n;
    if (!_complete) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.inspApprovalRequest,
        message: l10n.inspApprovalMissing,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    setState(() => _approved = true);
  }

  Future<void> _start() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FootplateWizardScreen(
        initialTrain: _train,
        initialStation: _origin,
        initialDeparture: _departure,
        initialArrival: _arrival,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final now = DateTime.now();
    final fields = IgnorePointer(
      ignoring: _approved,
      child: AnimatedOpacity(
        duration: AppMotion.short,
        opacity: _approved ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InspectionCard(
              title: l10n.inspApprovalTrain,
              glyph: AppGlyphs.train,
              children: [
                InspectionSelectInput(
                  label: 'Train',
                  options: kTrainNumbers,
                  value: _train,
                  glyph: AppGlyphs.trainFilled,
                  onChanged: (v) => setState(() => _train = v),
                ),
                InspectionTextInput(
                  label: l10n.inspApprovalOfficer,
                  value: _officer,
                  glyph: AppGlyphs.userCheck,
                  onChanged: (v) => setState(() => _officer = v),
                ),
              ],
            ),
            AppSpacing.gapMd,
            InspectionCard(
              title: l10n.inspApprovalSchedule,
              glyph: AppGlyphs.calendar,
              children: [
                InspectionDateInput(
                  label: l10n.inspFormDate,
                  value: _date,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 365)),
                  onChanged: (d) => setState(() => _date = d),
                ),
                InspectionFieldGrid(
                  items: [
                    InspectionGridItem(
                      InspectionTimeInput(
                        label: 'Departure',
                        value: _departure,
                        onChanged: (t) => setState(() => _departure = t),
                      ),
                    ),
                    InspectionGridItem(
                      InspectionTimeInput(
                        label: 'Arrival',
                        value: _arrival,
                        onChanged: (t) => setState(() => _arrival = t),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapMd,
            InspectionCard(
              title: l10n.inspApprovalRoute,
              glyph: AppGlyphs.route,
              children: [
                InspectionSelectInput(
                  label: l10n.inspApprovalFrom,
                  options: kStations,
                  value: _origin,
                  glyph: AppGlyphs.mapPin,
                  onChanged: (v) => setState(() => _origin = v),
                ),
                InspectionSelectInput(
                  label: l10n.inspApprovalTo,
                  options: kStations,
                  value: _destination,
                  glyph: AppGlyphs.flag,
                  onChanged: (v) => setState(() => _destination = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.inspApprovalTitle,
            subtitle: l10n.inspFootplate,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: Row(
              key: ValueKey(_approved),
              children: [
                AppToneIcon(
                  glyph: _approved ? AppGlyphs.badgeCheck : AppGlyphs.hourglass,
                  tone: _approved ? AppTone.brand : AppTone.warning,
                ),
                AppSpacing.gapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _approved
                            ? l10n.inspApprovalApproved
                            : l10n.inspApprovalRequest,
                        style: text.titleMedium,
                      ),
                      Text(
                        _approved
                            ? l10n.inspApprovalApprovedAbout
                            : l10n.inspApprovalRequestAbout,
                        style: text.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          fields,
          AppSpacing.gapXl,
          AnimatedSwitcher(
            duration: AppMotion.medium,
            child: _approved
                ? AppButton(
                    key: const ValueKey('start'),
                    label: l10n.inspApprovalStart,
                    leadingGlyph: AppGlyphs.scanFace,
                    onPressed: _start,
                  )
                : AppButton(
                    key: const ValueKey('send'),
                    label: l10n.inspApprovalSend,
                    leadingGlyph: AppGlyphs.arrowUpRight,
                    onPressed: _send,
                  ),
          ),
        ],
      ),
    );
  }
}
