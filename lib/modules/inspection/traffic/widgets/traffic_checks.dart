import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

/// A group of traffic checklist items on a card. Each starts in order, as
/// the traffic proforma has it, so only what is wrong needs a tap; a fault
/// asks for a remark, and a count where the item takes one.
class TrafficChecklist extends StatelessWidget {
  const TrafficChecklist({
    super.key,
    required this.title,
    required this.items,
    required this.data,
    required this.onChanged,
    this.glyph = AppGlyphs.clipboardList,
    this.positiveLabel = 'OK',
    this.negativeLabel = 'Issue',
    this.note,
    this.enabled = true,
    this.defaultChecked = true,
  });

  final String title;
  final List<ChecklistItem> items;
  final ChecklistFormData data;
  final VoidCallback onChanged;
  final AppGlyph glyph;
  final String positiveLabel;
  final String negativeLabel;
  final String? note;

  /// Off when another department has answered it this visit.
  final bool enabled;

  /// How an item starts: in order, or, as caution orders, not issued.
  final bool defaultChecked;

  @override
  Widget build(BuildContext context) {
    final issues = data.issueCountFor(items);
    final issued = items
        .where((item) => data.answers[item.key]?.checked ?? false)
        .length;
    return InspectionCard(
      title: title,
      subtitle: [
        ?note,
        if (defaultChecked)
          issues == 0
              ? '$positiveLabel: ${items.length}'
              : '$negativeLabel: $issues / ${items.length}'
        else if (issued > 0)
          '$positiveLabel: $issued',
      ].join('\n'),
      glyph: glyph,
      trailing: enabled && defaultChecked && issues > 0
          ? AppButton(
              label: context.l10n.inspTrafficAllGood(positiveLabel),
              size: AppButtonSize.small,
              variant: AppButtonVariant.tonal,
              expand: false,
              onPressed: () {
                data.markAll(items, checked: true);
                onChanged();
              },
            )
          : null,
      children: [
        for (final item in items)
          TrafficCheck(
            item: item,
            answer: data.of(item.key, defaultChecked: defaultChecked),
            positiveLabel: positiveLabel,
            negativeLabel: negativeLabel,
            enabled: enabled,
            asksRemark: defaultChecked,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

/// One checklist item: its two answers as chips, the fault in coral, and
/// the count and remark it asks for.
class TrafficCheck extends StatelessWidget {
  const TrafficCheck({
    super.key,
    required this.item,
    required this.answer,
    required this.positiveLabel,
    required this.negativeLabel,
    required this.onChanged,
    this.enabled = true,
    this.asksRemark = true,
  });

  final ChecklistItem item;
  final ChecklistAnswer answer;
  final String positiveLabel;
  final String negativeLabel;
  final VoidCallback onChanged;
  final bool enabled;

  /// A fault asks for a remark; not where "no" is the usual answer.
  final bool asksRemark;

  @override
  Widget build(BuildContext context) {
    final countAsked =
        item.hasQuantity && answer.checked == item.quantityWhenChecked;
    final remarkAsked = asksRemark && !answer.checked;
    final check = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionChoiceInput(
          label: item.label,
          options: [positiveLabel, negativeLabel],
          value: answer.checked ? positiveLabel : negativeLabel,
          toneOf: (option) => option == negativeLabel && asksRemark
              ? AppTone.danger
              : AppTone.brand,
          onChanged: (picked) {
            answer.checked = picked == positiveLabel;
            onChanged();
          },
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: countAsked
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: InspectionTextInput(
                    label: item.quantityLabel,
                    value: answer.quantity,
                    kind: InspectionTextKind.integer,
                    note: item.maxQuantityFromAssetKey == null
                        ? null
                        : context.l10n.inspTrafficQuantityCap,
                    onChanged: (typed) {
                      answer.quantity = typed;
                      onChanged();
                    },
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        InspectionRemarkInput(
          visible: remarkAsked,
          value: answer.remarks,
          onChanged: (note) {
            answer.remarks = note;
            onChanged();
          },
        ),
      ],
    );
    if (enabled) return check;
    return Opacity(opacity: 0.5, child: IgnorePointer(child: check));
  }
}

/// A yes-or-no question kept as a flag.
class TrafficYesNo extends StatelessWidget {
  const TrafficYesNo({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.yesIsFault = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// "Yes" reports the fault, as unauthorised vendors present.
  final bool yesIsFault;

  @override
  Widget build(BuildContext context) => InspectionChoiceInput(
    label: label,
    options: const ['Yes', 'No'],
    value: value ? 'Yes' : 'No',
    toneOf: (option) =>
        (option == 'Yes') == yesIsFault ? AppTone.danger : AppTone.brand,
    onChanged: (picked) => onChanged(picked == 'Yes'),
  );
}

/// A date kept as text on the traffic forms, picked from the wheel.
class TrafficDate extends StatelessWidget {
  const TrafficDate({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => InspectionDateInput(
    label: label,
    value: DateTime.tryParse(value),
    onChanged: (day) => onChanged(
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}',
    ),
  );
}

/// Says the shared safety-equipment check was answered by the other
/// department on this visit, so it is shown, not asked again.
class TrafficSharedNotice extends StatelessWidget {
  const TrafficSharedNotice({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: AppPill(
      context.l10n.inspTrafficSharedAnswered,
      tone: AppTone.info,
      dot: context.colors.info,
    ),
  );
}

/// The station's points, each by its name and whether it works, with a
/// key that adds one more.
class TrafficPoints extends StatelessWidget {
  const TrafficPoints({
    super.key,
    required this.points,
    required this.onChanged,
  });

  final List<StationPointEntry> points;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InspectionCard(
      title: l10n.inspTrafficPoints,
      subtitle: l10n.inspTrafficPointsNote,
      glyph: AppGlyphs.route,
      children: [
        for (final (i, point) in points.indexed)
          Column(
            key: ObjectKey(point),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InspectionTextInput(
                      label: l10n.inspTrafficPointName(i + 1),
                      value: point.label,
                      onChanged: (typed) {
                        point.label = typed;
                        onChanged();
                      },
                    ),
                  ),
                  AppSpacing.gapSm,
                  AppTileButton(
                    icon: const AppGlyphIcon(AppGlyphs.trash),
                    tooltip: l10n.inspFormRemoveRow,
                    onPressed: () {
                      points.remove(point);
                      onChanged();
                    },
                  ),
                ],
              ),
              AppSpacing.gapSm,
              AppChoiceChips<bool>(
                choices: const [
                  AppChoice(true, 'Working'),
                  AppChoice(false, 'Not working', tone: AppTone.danger),
                ],
                selected: point.workingProperly,
                onSelected: (working) {
                  point.workingProperly = working;
                  onChanged();
                },
              ),
            ],
          ),
        AppButton(
          label: l10n.inspFormAddRow('point'),
          variant: AppButtonVariant.secondary,
          leadingGlyph: AppGlyphs.plus,
          onPressed: () {
            points.add(StationPointEntry(label: 'Point ${points.length + 1}'));
            onChanged();
          },
        ),
      ],
    );
  }
}
