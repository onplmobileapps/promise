import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// How the train kept time at each station, and the caution orders it was
/// given on the way.
class PunctualityStep extends StatelessWidget {
  const PunctualityStep({
    super.key,
    required this.punctuality,
    required this.ops,
    required this.onChanged,
  });

  final List<PunctualityEntry> punctuality;
  final List<OPEntry> ops;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionCard(
          title: 'Punctuality of Trains',
          glyph: AppGlyphs.clock,
          children: [
            for (final (i, entry) in punctuality.indexed)
              _Stop(
                key: ObjectKey(entry),
                number: i + 1,
                entry: entry,
                onChanged: onChanged,
                onRemove: () {
                  punctuality.remove(entry);
                  onChanged();
                },
              ),
            AppButton(
              label: l10n.inspFormAddRow('station'),
              variant: AppButtonVariant.secondary,
              leadingGlyph: AppGlyphs.plus,
              onPressed: () {
                punctuality.add(PunctualityEntry(station: kStations.first));
                onChanged();
              },
            ),
          ],
        ),
        AppSpacing.gapMd,
        InspectionCard(
          title: 'Caution Orders / OPs',
          subtitle: 'Pick every OP received and the decimal it applies to.',
          glyph: AppGlyphs.triangleAlert,
          children: [
            AppMultiChoiceChips<String>(
              choices: [for (final op in kCautionOrders) AppChoice(op, op)],
              selected: {for (final op in ops) op.opCode},
              onToggled: (code) {
                final had = ops.any((op) => op.opCode == code);
                had
                    ? ops.removeWhere((op) => op.opCode == code)
                    : ops.add(OPEntry(opCode: code));
                onChanged();
              },
            ),
            for (final op in ops)
              InspectionTextInput(
                key: ValueKey(op.opCode),
                label: '${op.opCode} · Decimal',
                hint: 'e.g. 425/0.987',
                value: op.decimal,
                onChanged: (typed) {
                  op.decimal = typed;
                  onChanged();
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// One station's times: scheduled and actual, arriving and leaving, with
/// how far off they were.
class _Stop extends StatelessWidget {
  const _Stop({
    super.key,
    required this.number,
    required this.entry,
    required this.onChanged,
    required this.onRemove,
  });

  final int number;
  final PunctualityEntry entry;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  static String _off(Duration? d) {
    if (d == null) return '—';
    final minutes = d.inMinutes;
    if (minutes == 0) return 'On time';
    return minutes > 0 ? '$minutes min late' : '${-minutes} min early';
  }

  DateTime _today(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  TimeOfDay? _time(DateTime? at) =>
      at == null ? null : TimeOfDay.fromDateTime(at);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget time(String label, DateTime? value, void Function(DateTime) set) =>
        InspectionTimeInput(
          label: label,
          value: _time(value),
          onChanged: (t) {
            set(_today(t));
            onChanged();
          },
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Station $number',
                    style: context.textTheme.titleSmall,
                  ),
                ),
                AppButton(
                  label: context.l10n.inspFormRemoveRow,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.quietDanger,
                  leadingGlyph: AppGlyphs.trash,
                  expand: false,
                  onPressed: onRemove,
                ),
              ],
            ),
            AppSpacing.gapMd,
            InspectionSelectInput(
              label: 'Station',
              options: kStations,
              value: entry.station,
              glyph: AppGlyphs.station,
              onChanged: (v) {
                entry.station = v;
                onChanged();
              },
            ),
            AppSpacing.gapMd,
            InspectionFieldGrid(
              items: [
                InspectionGridItem(
                  time(
                    'Scheduled arrival',
                    entry.scheduleArrival,
                    (at) => entry.scheduleArrival = at,
                  ),
                ),
                InspectionGridItem(
                  time(
                    'Actual arrival',
                    entry.actualArrival,
                    (at) => entry.actualArrival = at,
                  ),
                ),
                InspectionGridItem(
                  time(
                    'Scheduled departure',
                    entry.scheduleDeparture,
                    (at) => entry.scheduleDeparture = at,
                  ),
                ),
                InspectionGridItem(
                  time(
                    'Actual departure',
                    entry.actualDeparture,
                    (at) => entry.actualDeparture = at,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                AppPill(
                  'Arrival: ${_off(entry.arrivalDiff)}',
                  tone: (entry.arrivalDiff?.inMinutes ?? 0) > 0
                      ? AppTone.danger
                      : AppTone.brand,
                ),
                AppPill(
                  'Departure: ${_off(entry.departureDiff)}',
                  tone: (entry.departureDiff?.inMinutes ?? 0) > 0
                      ? AppTone.danger
                      : AppTone.brand,
                ),
              ],
            ),
            if (entry.hasDifference) ...[
              AppSpacing.gapMd,
              InspectionTextInput(
                label: 'Reason for the difference',
                kind: InspectionTextKind.multiline,
                value: entry.remarks,
                onChanged: (typed) {
                  entry.remarks = typed;
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
