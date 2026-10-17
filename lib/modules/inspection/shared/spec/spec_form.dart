import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/form_spec.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// A part of a form described as data: the questions under one heading.
@immutable
class SpecPart {
  const SpecPart(this.title, this.specs);

  final String title;
  final List<FormSpec> specs;
}

/// [specs] split at their section headings, each part a step; questions
/// before the first heading go under [first].
List<SpecPart> specParts(List<FormSpec> specs, {required String first}) {
  final parts = <SpecPart>[];
  var title = first;
  var current = <FormSpec>[];
  for (final spec in specs) {
    if (spec.kind == FormSpecKind.section) {
      if (current.isNotEmpty) parts.add(SpecPart(title, current));
      title = spec.label;
      current = [];
    } else {
      current.add(spec);
    }
  }
  if (current.isNotEmpty || parts.isEmpty) parts.add(SpecPart(title, current));
  return parts;
}

/// The answers of a form described as data, by key; a repeat's questions
/// as `key[n].question`.
class SpecAnswers {
  SpecAnswers([Map<String, dynamic>? values]) : values = values ?? {};

  final Map<String, dynamic> values;
  final Map<String, int> _repeats = {};

  bool _answerable(FormSpec spec) => switch (spec.kind) {
    FormSpecKind.choice ||
    FormSpecKind.select ||
    FormSpecKind.date ||
    FormSpecKind.number ||
    FormSpecKind.text => true,
    _ => false,
  };

  /// Whether [spec] is asked, given the answers so far.
  bool shows(FormSpec spec, [String prefix = '']) {
    final key = spec.showIfKey;
    if (key == null) return true;
    final actual = values['$prefix$key'];
    final expected = spec.showIfValue;
    return expected is List ? expected.contains(actual) : actual == expected;
  }

  bool isAnswered(String key) {
    final value = values[key];
    return value != null && value.toString().trim().isNotEmpty;
  }

  /// How many of [spec]'s things there are, as piers: those added, or
  /// those a draft has answers for.
  int repeats(FormSpec spec, [String prefix = '']) =>
      _repeats.putIfAbsent('$prefix${spec.key}', () {
        final start = '$prefix${spec.key}[';
        var count = 0;
        for (final key in values.keys) {
          if (!key.startsWith(start)) continue;
          final end = key.indexOf(']', start.length);
          final n = int.tryParse(key.substring(start.length, end));
          if (n != null && n + 1 > count) count = n + 1;
        }
        return count;
      });

  void addRepeat(FormSpec spec, [String prefix = '']) =>
      _repeats['$prefix${spec.key}'] = repeats(spec, prefix) + 1;

  /// Removes the last of [spec]'s things, with its answers.
  void removeRepeat(FormSpec spec, [String prefix = '']) {
    final count = repeats(spec, prefix);
    if (count == 0) return;
    final gone = '$prefix${spec.key}[${count - 1}].';
    values.removeWhere((key, _) => key.startsWith(gone));
    _repeats['$prefix${spec.key}'] = count - 1;
  }

  /// Questions asked under [specs], and how many have answers.
  (int answered, int total) progress(
    Iterable<FormSpec> specs, [
    String prefix = '',
  ]) {
    var answered = 0;
    var total = 0;
    for (final spec in specs) {
      if (!shows(spec, prefix)) continue;
      if (_answerable(spec)) {
        total++;
        if (isAnswered('$prefix${spec.key}')) answered++;
      } else if (spec.kind == FormSpecKind.group) {
        final (a, t) = progress(spec.parts, prefix);
        answered += a;
        total += t;
      } else if (spec.kind == FormSpecKind.repeat) {
        for (var n = 0; n < repeats(spec, prefix); n++) {
          final (a, t) = progress(spec.parts, '$prefix${spec.key}[$n].');
          answered += a;
          total += t;
        }
      }
    }
    return (answered, total);
  }

  /// The rows a report reads for [specs], labelled under their groups.
  List<ReportRow> rows(
    Iterable<FormSpec> specs, {
    String prefix = '',
    String? under,
  }) {
    String label(String own) => under == null ? own : '$under · $own';
    return [
      for (final spec in specs)
        if (shows(spec, prefix))
          ...switch (spec.kind) {
            FormSpecKind.section => const <ReportRow>[],
            FormSpecKind.display => [
              ReportRow(
                label(spec.label),
                spec.shownValue,
                tone: ReportTone.plain,
              ),
            ],
            FormSpecKind.group => rows(
              spec.parts,
              prefix: prefix,
              under: under,
            ),
            FormSpecKind.repeat => [
              for (var n = 0; n < repeats(spec, prefix); n++)
                ...rows(
                  spec.parts,
                  prefix: '$prefix${spec.key}[$n].',
                  under: label('${spec.itemLabel ?? spec.label} ${n + 1}'),
                ),
            ],
            _ => [
              ReportRow(
                label(spec.label),
                _shown(values['$prefix${spec.key}'], spec.unit),
                tone: spec.faults.contains(values['$prefix${spec.key}'])
                    ? ReportTone.bad
                    : null,
              ),
            ],
          },
    ];
  }

  static String _shown(Object? value, String? unit) {
    final text = displayValue(value);
    return text.isEmpty || unit == null ? text : '$text $unit';
  }
}

/// The questions of one part of a form described as data, on its card.
class SpecPartBody extends StatelessWidget {
  const SpecPartBody({
    super.key,
    required this.part,
    required this.answers,
    required this.onChanged,
    required this.onRepeat,
    this.glyph = AppGlyphs.clipboardList,
  });

  final SpecPart part;
  final SpecAnswers answers;

  /// An answer given.
  final void Function(String key, Object? value) onChanged;

  /// A thing added to, or taken from, a repeat.
  final VoidCallback onRepeat;
  final AppGlyph glyph;

  @override
  Widget build(BuildContext context) => InspectionCard(
    title: part.title,
    glyph: glyph,
    children: _fields(context, part.specs, ''),
  );

  List<Widget> _fields(
    BuildContext context,
    List<FormSpec> specs,
    String prefix,
  ) => [
    for (final spec in specs)
      if (answers.shows(spec, prefix)) ..._field(context, spec, prefix),
  ];

  List<Widget> _field(BuildContext context, FormSpec spec, String prefix) {
    final l10n = context.l10n;
    final key = '$prefix${spec.key}';
    final value = answers.values[key];
    void set(Object? to) => onChanged(key, to);
    switch (spec.kind) {
      case FormSpecKind.section:
        return [InspectionSubhead(spec.label)];
      case FormSpecKind.choice:
        return [
          InspectionChoiceInput(
            label: spec.label,
            options: spec.choices,
            value: value?.toString(),
            note: spec.note,
            toneOf: spec.faults.isEmpty
                ? answerTone
                : (option) => spec.faults.contains(option)
                      ? AppTone.danger
                      : AppTone.brand,
            onChanged: set,
          ),
        ];
      case FormSpecKind.select:
        return [
          InspectionSelectInput(
            label: spec.label,
            options: spec.choices,
            value: value?.toString(),
            note: spec.note,
            onChanged: set,
          ),
        ];
      case FormSpecKind.date:
        return [
          InspectionDateInput(
            label: spec.label,
            value: value is DateTime ? value : null,
            note: spec.note,
            onChanged: set,
          ),
        ];
      case FormSpecKind.number:
        final max = spec.maxValue;
        final reading = double.tryParse('${value ?? ''}');
        return [
          InspectionTextInput(
            label: spec.label,
            value: value?.toString(),
            unit: spec.unit,
            note: spec.note,
            kind: InspectionTextKind.decimal,
            warning: max != null && reading != null && reading > max
                ? l10n.inspFormOutOfRange('≤ $max')
                : null,
            onChanged: set,
          ),
        ];
      case FormSpecKind.text:
        return [
          InspectionTextInput(
            label: spec.label,
            value: value?.toString(),
            note: spec.note,
            onChanged: set,
          ),
        ];
      case FormSpecKind.display:
        return [
          AppFieldFrame(
            label: spec.label,
            state: AppFieldState.readOnly,
            child: Text(spec.shownValue ?? '—'),
          ),
        ];
      case FormSpecKind.group:
        return [
          InspectionSubhead(spec.label),
          ..._fields(context, spec.parts, prefix),
        ];
      case FormSpecKind.repeat:
        final count = answers.repeats(spec, prefix);
        final item = spec.itemLabel ?? spec.label;
        return [
          InspectionSubhead(spec.label),
          for (var n = 0; n < count; n++)
            _RepeatItem(
              title: '$item ${n + 1}',
              onRemove: n == count - 1
                  ? () async {
                      final sure = await showAppDialog(
                        context: context,
                        tone: AppDialogTone.warning,
                        title: l10n.inspFormRemoveRowTitle,
                        primaryLabel: l10n.inspFormRemoveRow,
                        secondaryLabel: l10n.actionCancel,
                      );
                      if (sure != true) return;
                      answers.removeRepeat(spec, prefix);
                      onRepeat();
                    }
                  : null,
              children: _fields(context, spec.parts, '$key[$n].'),
            ),
          AppButton(
            label: l10n.inspFormAddRow(item.toLowerCase()),
            variant: AppButtonVariant.secondary,
            leadingGlyph: AppGlyphs.plus,
            onPressed: () {
              answers.addRepeat(spec, prefix);
              onRepeat();
            },
          ),
        ];
    }
  }
}

/// One of a repeat's things, on a sunken panel of its own.
class _RepeatItem extends StatelessWidget {
  const _RepeatItem({
    required this.title,
    required this.children,
    this.onRemove,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onRemove = this.onRemove;
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
                  child: Text(title, style: context.textTheme.titleSmall),
                ),
                if (onRemove != null)
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
            for (final child in children) ...[AppSpacing.gapMd, child],
          ],
        ),
      ),
    );
  }
}
