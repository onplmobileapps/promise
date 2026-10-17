import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';

/// A proforma's section on its card: each item numbered as on paper, and
/// a way to mark every item not yet answered as in order, undone as
/// easily.
class ProformaSectionBody extends StatefulWidget {
  const ProformaSectionBody({
    super.key,
    required this.section,
    required this.answers,
    required this.onChanged,
    this.noteLabel,
    this.glyph = AppGlyphs.clipboardList,
  });

  final ProformaSection section;
  final ProformaAnswers answers;
  final VoidCallback onChanged;

  /// What a note on an item is called, as "Remarks"; "Observation" if not
  /// given.
  final String? noteLabel;
  final AppGlyph glyph;

  @override
  State<ProformaSectionBody> createState() => _ProformaSectionBodyState();
}

class _ProformaSectionBodyState extends State<ProformaSectionBody> {
  /// The items just marked in order, to be undone.
  List<ProformaItem> _marked = const [];

  ProformaSection get _section => widget.section;

  /// The items not yet answered that have an answer saying all is well.
  List<ProformaItem> get _unanswered => [
    for (final item in _section.items)
      if (item.options.isNotEmpty &&
          !item.isFault(item.options.first.code) &&
          widget.answers.of(_section.key, item)['status'] == null)
        item,
  ];

  void _markRest() {
    final rest = _unanswered;
    for (final item in rest) {
      widget.answers.set(_section.key, item, 'status', item.options.first.code);
    }
    setState(() => _marked = rest);
    widget.onChanged();
  }

  void _undo() {
    for (final item in _marked) {
      widget.answers.set(_section.key, item, 'status', null);
    }
    setState(() => _marked = const []);
    widget.onChanged();
  }

  void _set(ProformaItem item, String key, Object? value) {
    widget.answers.set(_section.key, item, key, value);
    if (_marked.isNotEmpty) setState(() => _marked = const []);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final rest = _unanswered;
    final (answered, total) = widget.answers.progress(_section);
    final children = <Widget>[];
    String? group;
    for (final item in _section.items) {
      if (item.group != group) {
        group = item.group;
        if (group != null) {
          children.add(
            InspectionSubhead('${item.no.split('.').first}. $group'),
          );
        }
      }
      children.add(
        ProformaItemTile(
          key: ValueKey('${_section.key}/${item.no}'),
          item: item,
          answer: widget.answers.of(_section.key, item),
          noteLabel: widget.noteLabel ?? l10n.inspFormObservation,
          onChanged: (key, value) => _set(item, key, value),
        ),
      );
    }
    return InspectionCard(
      title: _section.title,
      subtitle: _section.about,
      glyph: widget.glyph,
      trailing: AppPill(
        '$answered/$total',
        tone: answered == total ? AppTone.brand : AppTone.neutral,
        dot: answered == total ? colors.success : null,
      ),
      children: [
        if (rest.isNotEmpty || _marked.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.inspFormMarkRest(rest.length),
                  variant: AppButtonVariant.tonal,
                  size: AppButtonSize.small,
                  leadingGlyph: AppGlyphs.check,
                  onPressed: rest.isEmpty ? null : _markRest,
                ),
              ),
              if (_marked.isNotEmpty) ...[
                AppSpacing.gapSm,
                AppButton(
                  label: l10n.inspFormUndo,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  expand: false,
                  onPressed: _undo,
                ),
              ],
            ],
          ),
        for (final (i, child) in children.indexed) ...[
          if (i > 0 && child is ProformaItemTile)
            Divider(height: 1, thickness: 1, color: colors.outline),
          child,
        ],
      ],
    );
  }
}

/// One item of a proforma: its number and name, what it is held to, its
/// answers as chips, and what else it asks, each as it applies: a
/// reading, an expiry date, counts, a record, and, once at fault, the
/// likely cause, what to do and a note. A note can be added to any item.
class ProformaItemTile extends StatefulWidget {
  const ProformaItemTile({
    super.key,
    required this.item,
    required this.answer,
    required this.onChanged,
    required this.noteLabel,
  });

  final ProformaItem item;
  final Map<String, Object?> answer;
  final void Function(String key, Object? value) onChanged;
  final String noteLabel;

  @override
  State<ProformaItemTile> createState() => _ProformaItemTileState();
}

class _ProformaItemTileState extends State<ProformaItemTile> {
  bool _noting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final item = widget.item;
    final answer = widget.answer;
    final status = answer['status']?.toString();
    final fault = item.isFault(status);
    final note = answer['note']?.toString();
    void set(String key, Object? value) => widget.onChanged(key, value);
    final asksReading =
        item.reading &&
        (item.readingOn.isEmpty || item.readingOn.contains(status));
    // The note is open: at fault, opened, or written in.
    final noted = fault || _noting || (note != null && note.isNotEmpty);
    final parts = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Number(item.no, done: status != null || answer.isNotEmpty),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: text.titleSmall),
                if (item.note case final note?)
                  Text(
                    note,
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // A note can be added to any item, from beside its name.
          if (!noted)
            IconButton(
              tooltip: l10n.inspFormAddNote,
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _noting = true),
              icon: AppGlyphIcon(
                AppGlyphs.fileEdit,
                size: AppSizes.iconSm,
                color: colors.textTertiary,
              ),
            ),
        ],
      ),
      if (item.options.isNotEmpty)
        AppChoiceChips<String>(
          choices: [
            for (final option in item.options)
              AppChoice(
                option.code,
                option.label,
                tone: item.isFault(option.code)
                    ? AppTone.danger
                    : ProformaItem.inapplicable(option)
                    ? AppTone.neutral
                    : AppTone.brand,
              ),
          ],
          selected: status,
          onSelected: (code) => set('status', code),
        ),
      for (final check in item.checks)
        InspectionChoiceInput(
          label: check,
          options: const ['Yes', 'No'],
          value: switch (answer[ProformaItem.checkKey(check)]) {
            'Y' => 'Yes',
            'N' => 'No',
            _ => null,
          },
          toneOf: (option) => option == 'No' ? AppTone.danger : AppTone.brand,
          onChanged: (picked) =>
              set(ProformaItem.checkKey(check), picked == 'Yes' ? 'Y' : 'N'),
        ),
      if (asksReading)
        InspectionTextInput(
          label: l10n.inspFormReading,
          value: answer['value']?.toString(),
          unit: item.unit,
          kind: item.unit == null
              ? InspectionTextKind.text
              : InspectionTextKind.decimal,
          onChanged: (typed) => set('value', typed),
        ),
      if (item.expiry)
        InspectionDateInput(
          label: l10n.inspFormExpiry,
          value: DateTime.tryParse('${answer['expiry_date'] ?? ''}'),
          onChanged: (day) => set('expiry_date', proformaDay(day)),
        ),
      // How many, once it is answered, or once counted before.
      if (item.counts &&
          (status != null ||
              const ['ok', 'defective', 'missing'].any(answer.containsKey)))
        _Counts(answer: answer, onChanged: set),
      if (item.record)
        InspectionTextInput(
          label: l10n.inspFormRecord,
          hint: item.recordHint,
          value: answer['record']?.toString(),
          onChanged: (typed) => set('record', typed),
        ),
      if (fault && item.causes.isNotEmpty)
        InspectionChoiceInput(
          label: l10n.inspFormLikelyCause,
          options: item.causes,
          value: answer['cause']?.toString(),
          toneOf: (_) => AppTone.danger,
          onChanged: (cause) => set('cause', cause),
        ),
      if (fault && item.action != null)
        InspectionFieldNote(text: item.action, warning: true),
      if (fault)
        InspectionRemarkInput(
          visible: true,
          label: widget.noteLabel,
          value: note,
          onChanged: (typed) => set('note', typed),
        )
      else if (noted)
        InspectionTextInput(
          label: widget.noteLabel,
          value: note,
          glyph: AppGlyphs.fileEdit,
          onChanged: (typed) => set('note', typed),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, part) in parts.indexed) ...[
          if (i > 0) AppSpacing.gapSm,
          part,
        ],
      ],
    );
  }
}

/// An item's number as the proforma prints it, filled once answered.
class _Number extends StatelessWidget {
  const _Number(this.no, {required this.done});

  final String no;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: AppMotion.short,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? colors.primaryContainer : colors.surfaceSunken,
        borderRadius: AppRadius.borderPill,
      ),
      child: Text(
        no,
        style: context.textTheme.labelMedium?.copyWith(
          fontFeatures: AppFonts.tabularFigures,
          fontWeight: AppFonts.semiBold,
          color: done ? colors.textPrimary : colors.textSecondary,
        ),
      ),
    );
  }
}

/// How many are okay, defective and missing, side by side where they fit.
class _Counts extends StatelessWidget {
  const _Counts({required this.answer, required this.onChanged});

  final Map<String, Object?> answer;
  final void Function(String key, Object? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fields = [
      for (final (key, label) in [
        ('ok', l10n.inspFormCountOk),
        ('defective', l10n.inspFormCountDefective),
        ('missing', l10n.inspFormCountMissing),
      ])
        InspectionTextInput(
          label: label,
          value: answer[key]?.toString(),
          kind: InspectionTextKind.integer,
          onChanged: (typed) => onChanged(key, int.tryParse(typed)),
        ),
    ];
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 300
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, field) in fields.indexed) ...[
                  if (i > 0) AppSpacing.gapSm,
                  field,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, field) in fields.indexed) ...[
                  if (i > 0) AppSpacing.gapSm,
                  Expanded(child: field),
                ],
              ],
            ),
    );
  }
}

/// A question asked once of the whole inspection, as the field it is.
class ProformaFieldInput extends StatelessWidget {
  const ProformaFieldInput({
    super.key,
    required this.field,
    required this.answers,
    required this.onChanged,
    this.stations = const [],
    this.stationsError,
    this.loadingStations = false,
    this.onRetryStations,
  });

  final ProformaField field;
  final ProformaAnswers answers;
  final VoidCallback onChanged;

  /// For a station field: the stations to pick from.
  final List<StationItem> stations;
  final String? stationsError;
  final bool loadingStations;
  final VoidCallback? onRetryStations;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = answers.field(field.key);
    final label = field.required ? '${field.label} *' : field.label;
    void set(Object? to) {
      answers.setField(field.key, to);
      onChanged();
    }

    String? labelOf(Object? code) {
      for (final option in field.options) {
        if (option.code == code) return option.label;
      }
      return null;
    }

    String codeOf(String label) =>
        field.options.firstWhere((option) => option.label == label).code;

    switch (field.kind) {
      case ProformaFieldKind.text ||
          ProformaFieldKind.multiline ||
          ProformaFieldKind.number:
        return InspectionTextInput(
          label: label,
          hint: field.hint,
          note: field.note,
          value: value?.toString(),
          kind: switch (field.kind) {
            ProformaFieldKind.multiline => InspectionTextKind.multiline,
            ProformaFieldKind.number => InspectionTextKind.integer,
            _ => InspectionTextKind.text,
          },
          onChanged: set,
        );
      case ProformaFieldKind.date:
        return InspectionDateInput(
          label: label,
          note: field.note,
          value: DateTime.tryParse('${value ?? ''}'),
          onChanged: (day) => set(proformaDay(day)),
        );
      case ProformaFieldKind.choice:
        return InspectionChoiceInput(
          label: label,
          note: field.note,
          options: [for (final option in field.options) option.label],
          value: labelOf(value),
          onChanged: (picked) => set(codeOf(picked)),
        );
      case ProformaFieldKind.multi:
        final picked = value is List ? value : const [];
        return InspectionMultiChoiceInput(
          label: label,
          note: field.note,
          options: [for (final option in field.options) option.label],
          values: [for (final code in picked) ?labelOf(code)],
          toneOf: (_) => AppTone.brand,
          onChanged: (all) => set([for (final label in all) codeOf(label)]),
        );
      case ProformaFieldKind.station:
        if (loadingStations) {
          return AppFieldFrame(
            label: label,
            glyph: AppGlyphs.station,
            trailing: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: AppLoader(size: AppSizes.loaderSmall),
            ),
            child: Text(
              answers.field('${field.key}_name')?.toString() ??
                  l10n.inspFormStationHint,
            ),
          );
        }
        if (stations.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppEmptyState(
                glyph: AppGlyphs.station,
                title: stationsError == null
                    ? l10n.inspFormNoStations
                    : l10n.inspFormStationsFailed,
                message: stationsError,
              ),
              if (onRetryStations case final retry?)
                AppButton(
                  label: l10n.actionRetry,
                  variant: AppButtonVariant.secondary,
                  leadingGlyph: AppGlyphs.refresh,
                  onPressed: retry,
                ),
            ],
          );
        }
        StationItem? chosen;
        for (final station in stations) {
          if (station.id == value) chosen = station;
        }
        return AppSelectField<StationItem>(
          key: ValueKey(chosen?.id),
          label: label,
          hint: l10n.inspFormStationHint,
          sheetTitle: field.label,
          glyph: AppGlyphs.station,
          options: stations,
          initialValue: chosen,
          optionLabel: (station) => station.displayLabel,
          onChanged: (station) {
            answers
              ..setField(field.key, station.id)
              ..setField('${field.key}_name', station.displayLabel);
            onChanged();
          },
        );
    }
  }
}

/// A table filled in row by row: each row on a panel of its own, added
/// and taken away as needed.
class ProformaTableBody extends StatelessWidget {
  const ProformaTableBody({
    super.key,
    required this.table,
    required this.answers,
    required this.onChanged,
  });

  final ProformaTable table;
  final ProformaAnswers answers;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final rows = answers.rowsOf(table.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionSubhead(table.title, note: table.about),
        for (final (n, row) in rows.indexed) ...[
          AppSpacing.gapMd,
          DecoratedBox(
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
                          '${table.item} ${n + 1}',
                          style: context.textTheme.titleSmall,
                        ),
                      ),
                      AppButton(
                        label: l10n.inspFormRemoveRow,
                        size: AppButtonSize.small,
                        variant: AppButtonVariant.quietDanger,
                        leadingGlyph: AppGlyphs.trash,
                        expand: false,
                        onPressed: () async {
                          final sure = await showAppDialog(
                            context: context,
                            tone: AppDialogTone.warning,
                            title: l10n.inspFormRemoveRowTitle,
                            primaryLabel: l10n.inspFormRemoveRow,
                            secondaryLabel: l10n.actionCancel,
                          );
                          if (sure != true) return;
                          rows.removeAt(n);
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  for (final column in table.columns) ...[
                    AppSpacing.gapMd,
                    _cell(context, column, row),
                  ],
                ],
              ),
            ),
          ),
        ],
        AppSpacing.gapMd,
        AppButton(
          label: l10n.inspFormAddRow(table.item.toLowerCase()),
          variant: AppButtonVariant.secondary,
          leadingGlyph: AppGlyphs.plus,
          onPressed: () {
            rows.add({});
            onChanged();
          },
        ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    ProformaField column,
    Map<String, Object?> row,
  ) {
    void set(Object? value) {
      if (value == null || '$value'.trim().isEmpty) {
        row.remove(column.key);
      } else {
        row[column.key] = value;
      }
      onChanged();
    }

    final value = row[column.key];
    return switch (column.kind) {
      ProformaFieldKind.date => InspectionDateInput(
        label: column.label,
        value: DateTime.tryParse('${value ?? ''}'),
        onChanged: (day) => set(proformaDay(day)),
      ),
      _ => InspectionTextInput(
        label: column.label,
        value: value?.toString(),
        kind: column.kind == ProformaFieldKind.number
            ? InspectionTextKind.integer
            : InspectionTextKind.text,
        onChanged: set,
      ),
    };
  }
}
