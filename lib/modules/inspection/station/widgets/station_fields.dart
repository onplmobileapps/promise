import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';

/// A section's 3D mark.
AppGlyph stationSectionGlyph(String id) => switch (id) {
  'asm' => AppGlyphs.building,
  'panel' => AppGlyphs.layers,
  'block' => AppGlyphs.lock,
  'phones' => AppGlyphs.phone,
  'route' || 'points' => AppGlyphs.route,
  'maint' => AppGlyphs.wrench,
  'paint' => AppGlyphs.calendarCheck,
  'battery' || 'batteryRoom' || 'trackCircuit' => AppGlyphs.zap,
  'cabin' => AppGlyphs.hash,
  'equipRoom' => AppGlyphs.gauge,
  'signals' => AppGlyphs.signal,
  'levelCrossing' => AppGlyphs.triangleAlert,
  'failures' => AppGlyphs.clipboardList,
  'telecom' => AppGlyphs.radioTower,
  'submit' => AppGlyphs.userCheck,
  _ => AppGlyphs.clipboardList,
};

/// The fields of a section of the station form, on its cards.
class StationSectionBody extends StatelessWidget {
  const StationSectionBody({
    super.key,
    required this.section,
    required this.form,
  });

  final InspectionSection section;
  final StationInspectionController form;

  @override
  Widget build(BuildContext context) {
    if (section.isSignals) return _Signals(form: form);
    if (section.isRepeatSection) {
      return _RepeatRows(
        type: section.repeatType!,
        glyph: stationSectionGlyph(section.id),
        form: form,
      );
    }
    final hasExtinguishers = section.items.any(
      (item) => item is FieldFormItem && item.spec.id == 'fireExtCount',
    );
    return InspectionCard(
      title: section.title,
      subtitle: section.blurb,
      glyph: stationSectionGlyph(section.id),
      children: [
        InspectionFieldGrid(
          items: [
            for (final item in section.items)
              switch (item) {
                SubheadFormItem() => InspectionGridItem(
                  InspectionSubhead(item.label, note: item.note),
                  wide: true,
                ),
                FieldFormItem(:final spec) => InspectionGridItem(
                  StationField(
                    spec: spec,
                    form: form,
                    // The overhaul's period follows the instrument's type.
                    overdueYears: spec.id == 'blockOverhaulDate'
                        ? form.overhaulYearsForBlockType(
                            form.get<String>('blockType'),
                          )
                        : null,
                  ),
                  wide: spec.span2 || spec.kind == FieldKind.textarea,
                ),
                _ => const InspectionGridItem(SizedBox.shrink()),
              },
          ],
        ),
        if (hasExtinguishers) _ExtinguisherDates(form: form),
      ],
    );
  }
}

/// One question of the station form, drawn from its [spec].
class StationField extends StatelessWidget {
  const StationField({
    super.key,
    required this.spec,
    required this.form,
    this.overdueYears,
  });

  final FieldSpec spec;
  final StationInspectionController form;

  /// The years a [FieldKind.dateOverdue] date lasts, in place of the
  /// spec's own.
  final int? overdueYears;

  String? get _text {
    final value = form.fields[spec.id];
    return value?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = spec.id;
    void set(Object? value) => form.setField(id, value);
    switch (spec.kind) {
      case FieldKind.text || FieldKind.textarea:
        return InspectionTextInput(
          label: spec.label,
          value: _text,
          hint: spec.placeholder,
          note: spec.note,
          kind: spec.kind == FieldKind.textarea
              ? InspectionTextKind.multiline
              : InspectionTextKind.text,
          onChanged: set,
        );
      case FieldKind.number:
        return InspectionTextInput(
          label: spec.label,
          value: _text,
          hint: spec.placeholder,
          note: spec.note,
          kind: InspectionTextKind.integer,
          onChanged: (typed) => set(int.tryParse(typed)),
        );
      case FieldKind.decimal:
        final reading = switch (form.fields[id]) {
          final num value => value.toDouble(),
          final Object value => double.tryParse('$value'),
          null => null,
        };
        final low = spec.min;
        final high = spec.max;
        final outside =
            reading != null &&
            ((low != null && reading < low) ||
                (high != null && reading > high));
        return InspectionTextInput(
          label: spec.label,
          value: _text,
          unit: spec.unit,
          note: spec.hint ?? spec.note,
          warning: outside
              ? l10n.inspFormOutOfRange(
                  spec.hint ?? '${low ?? ''}–${high ?? ''}',
                )
              : null,
          kind: InspectionTextKind.decimal,
          onChanged: (typed) => set(double.tryParse(typed)),
        );
      case FieldKind.date:
        return InspectionDateInput(
          label: spec.label,
          value: form.fields[id] is DateTime
              ? form.fields[id] as DateTime
              : null,
          note: spec.note,
          onChanged: set,
        );
      case FieldKind.dateOverdue:
        final date = form.fields[id] is DateTime
            ? form.fields[id] as DateTime
            : null;
        final due = form.overdueInfo(
          id,
          overdueYears ?? spec.overdueYears ?? 1,
        );
        return InspectionDateInput(
          label: spec.label,
          value: date,
          lastDate: DateTime.now(),
          note: spec.note,
          status: date == null
              ? null
              : InspectionStatusPill(
                  due.text,
                  tone: switch (due.status) {
                    OverdueStatus.overdue => AppTone.danger,
                    OverdueStatus.dueSoon => AppTone.warning,
                    OverdueStatus.valid => AppTone.brand,
                    OverdueStatus.empty => AppTone.neutral,
                  },
                ),
          onChanged: set,
        );
      // A few short options are quicker tapped than picked from a sheet.
      case FieldKind.select
          when spec.options.length <= 4 &&
              spec.options.every((option) => option.length <= 12):
        return InspectionChoiceInput(
          label: spec.label,
          options: spec.options,
          value: _text,
          note: spec.note,
          onChanged: set,
        );
      case FieldKind.select:
        return InspectionSelectInput(
          label: spec.label,
          options: spec.options,
          value: _text,
          note: spec.note,
          onChanged: set,
        );
      case FieldKind.toggle:
        return InspectionChoiceInput(
          label: spec.label,
          options: spec.options,
          value: _text,
          note: spec.note,
          onChanged: set,
        );
      case FieldKind.toggleRemark:
        final answer = _text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InspectionChoiceInput(
              label: spec.label,
              options: spec.options,
              value: answer,
              note: spec.note,
              onChanged: set,
            ),
            InspectionRemarkInput(
              visible:
                  answer != null && classifyValue(answer) == FieldTone.negative,
              value: form.fields[spec.remarkId]?.toString(),
              onChanged: (note) => form.setField(spec.remarkId, note),
            ),
          ],
        );
      case FieldKind.stepper:
        return InspectionCountInput(
          label: spec.label,
          value: switch (form.fields[id]) {
            final num count => count.toInt(),
            _ => 0,
          },
          max: 50,
          note: spec.note,
          onChanged: set,
        );
    }
  }
}

/// A filling date for each of the station's fire extinguishers.
class _ExtinguisherDates extends StatelessWidget {
  const _ExtinguisherDates({required this.form});

  final StationInspectionController form;

  @override
  Widget build(BuildContext context) {
    final count = form.fireExtCount;
    if (count <= 0) {
      return InspectionFieldNote(text: context.l10n.inspFormNoExtinguishers);
    }
    return InspectionFieldGrid(
      items: [
        for (var n = 1; n <= count; n++)
          InspectionGridItem(
            StationField(
              spec: FieldSpec(
                form.fireExtDateId(n),
                'Extinguisher #$n — Date of Filling',
                FieldKind.dateOverdue,
                overdueYears: 1,
              ),
              form: form,
            ),
          ),
      ],
    );
  }
}

/// A card for each of the station's signals, with its five checks and a
/// key that passes them all at once.
class _Signals extends StatelessWidget {
  const _Signals({required this.form});

  final StationInspectionController form;

  static const _answers = ['Satisfactory', 'Unsatisfactory'];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, name) in kSignalNames.indexed) ...[
          if (i > 0) AppSpacing.gapMd,
          InspectionCard(
            title: name,
            glyph: AppGlyphs.signal,
            trailing: AppButton(
              label: l10n.inspFormAllGood,
              size: AppButtonSize.small,
              variant: AppButtonVariant.tonal,
              expand: false,
              onPressed: () => form.fillBlank([
                for (final part in kSignalParts) 'sig_${i}_${part[0]}',
              ], _answers.first),
            ),
            children: [
              for (final part in kSignalParts)
                _SignalCheck(
                  form: form,
                  id: 'sig_${i}_${part[0]}',
                  label: part[1],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SignalCheck extends StatelessWidget {
  const _SignalCheck({
    required this.form,
    required this.id,
    required this.label,
  });

  final StationInspectionController form;
  final String id;
  final String label;

  @override
  Widget build(BuildContext context) {
    final answer = form.fields[id]?.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionChoiceInput(
          label: label,
          options: _Signals._answers,
          value: answer,
          onChanged: (picked) => form.setField(id, picked),
        ),
        InspectionRemarkInput(
          visible: answer == 'Unsatisfactory',
          value: form.fields['${id}_remark']?.toString(),
          onChanged: (note) => form.setField('${id}_remark', note),
        ),
      ],
    );
  }
}

/// The entries of a list section, as points or level crossings: a card
/// for each, and a key that adds one more.
class _RepeatRows extends StatelessWidget {
  const _RepeatRows({
    required this.type,
    required this.glyph,
    required this.form,
  });

  final String type;
  final AppGlyph glyph;
  final StationInspectionController form;

  Future<void> _remove(BuildContext context, int row) async {
    final l10n = context.l10n;
    final prefix = '${form.rowPrefix(type, row)}_';
    final filled = form.fields.entries.any(
      (e) => e.key.startsWith(prefix) && form.isFilled(e.key),
    );
    if (filled) {
      final sure = await showAppDialog(
        context: context,
        tone: AppDialogTone.warning,
        title: l10n.inspFormRemoveRowTitle,
        primaryLabel: l10n.inspFormRemoveRow,
        secondaryLabel: l10n.actionCancel,
      );
      if (sure != true) return;
    }
    form.removeRow(type, row);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final def = kRepeatDefs[type]!;
    final rows = form.rowsFor(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (n, row) in rows.indexed) ...[
          if (n > 0) AppSpacing.gapMd,
          InspectionCard(
            key: ValueKey(row),
            title: '${def.label} ${n + 1}',
            glyph: glyph,
            trailing: rows.length > def.minRows
                ? AppButton(
                    label: l10n.inspFormRemoveRow,
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.quietDanger,
                    leadingGlyph: AppGlyphs.trash,
                    expand: false,
                    onPressed: () => _remove(context, row),
                  )
                : null,
            children: [
              InspectionFieldGrid(
                items: [
                  for (final (c, column) in def.cols.indexed)
                    if (_shown(def, c, row))
                      InspectionGridItem(
                        StationField(
                          spec: column.build(
                            '${form.rowPrefix(type, row)}_${column.key}',
                          ),
                          form: form,
                        ),
                        wide: column
                            .build('${form.rowPrefix(type, row)}_${column.key}')
                            .span2,
                      ),
                ],
              ),
              if (def.hasTotal)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppPill(
                    '${l10n.inspFormTotal}: '
                    '${form.rowTotal(type, row).toStringAsFixed(0)}',
                  ),
                ),
            ],
          ),
        ],
        AppSpacing.gapMd,
        AppButton(
          label: l10n.inspFormAddRow(def.label.toLowerCase()),
          variant: AppButtonVariant.secondary,
          leadingGlyph: AppGlyphs.plus,
          onPressed: () => form.addRow(type),
        ),
      ],
    );
  }

  /// A column without a label of its own, as "Track gauge — if No", shows
  /// only once the answer before it reports the fault.
  bool _shown(RepeatDef def, int column, int row) {
    if (def.cols[column].label.isNotEmpty || column == 0) return true;
    final before =
        form.fields['${form.rowPrefix(type, row)}_'
            '${def.cols[column - 1].key}'];
    return before != null &&
        classifyValue(before.toString()) == FieldTone.negative;
  }
}
