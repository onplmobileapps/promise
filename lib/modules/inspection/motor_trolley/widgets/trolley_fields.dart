import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/inspection_params_config.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// A step's 3D mark.
AppGlyph trolleyStepGlyph(String id) => switch (id) {
  'header' => AppGlyphs.clipboardList,
  'geometry' => AppGlyphs.route,
  'curves' => AppGlyphs.gauge,
  'points' => AppGlyphs.layers,
  'bridges' => AppGlyphs.map,
  'lcManned' || 'lcUnmanned' => AppGlyphs.triangleAlert,
  'tunnel' => AppGlyphs.locate,
  'buildings' => AppGlyphs.station,
  'yards' => AppGlyphs.train,
  'block' => AppGlyphs.mapPin,
  'certification' => AppGlyphs.badgeCheck,
  _ => AppGlyphs.clipboardList,
};

/// The questions of a step of the trolley form, on its card.
class TrolleyStepBody extends StatelessWidget {
  const TrolleyStepBody({
    super.key,
    required this.step,
    required this.state,
    required this.onChanged,
    this.leading = const [],
  });

  final TrolleyStep step;
  final MotorTrolleyInspectionState state;
  final void Function(String key, String value) onChanged;

  /// Fields before the step's own, as the day on the first.
  final List<Widget> leading;

  @override
  Widget build(BuildContext context) => InspectionCard(
    title: step.title,
    glyph: trolleyStepGlyph(step.id),
    children: [
      ...leading,
      InspectionFieldGrid(
        items: [
          for (final item in step.items)
            switch (item) {
              TrolleyHeading(:final title, :final note) => InspectionGridItem(
                InspectionSubhead(title, note: note),
                wide: true,
              ),
              TrolleyAsk(:final field) when state.asks(field) =>
                InspectionGridItem(
                  TrolleyField(
                    field: field,
                    state: state,
                    onChanged: onChanged,
                  ),
                  wide: _choice(field) || field.remedyOptions != null,
                ),
              TrolleyAsk() => const InspectionGridItem(SizedBox.shrink()),
            },
        ],
      ),
    ],
  );
}

/// A few short options are quicker tapped than picked from a sheet.
bool _choice(ParamField field) {
  final options = field.options ?? const [];
  return field.type == ParamInputType.dropdown &&
      options.length <= 4 &&
      options.every((option) => option.length <= 14);
}

/// One question of the trolley form, with its standard under it and its
/// remedy, when it has one.
class TrolleyField extends StatelessWidget {
  const TrolleyField({
    super.key,
    required this.field,
    required this.state,
    required this.onChanged,
  });

  final ParamField field;
  final MotorTrolleyInspectionState state;
  final void Function(String key, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = field.key;
    final value = state.value(key);
    final remedyStatic = field.remedyStatic;
    final note = [
      ?field.standard,
      if (remedyStatic != null) l10n.inspFormRemedyNote(remedyStatic),
    ].join('\n');
    final Widget answer = switch (field.type) {
      ParamInputType.dropdown when _choice(field) => InspectionChoiceInput(
        label: field.label,
        options: field.options ?? const [],
        value: value,
        // Out of limit, "Yes" is the fault.
        toneOf: key.endsWith('OutOfLimit')
            ? (option) => option == 'Yes' ? AppTone.danger : AppTone.brand
            : answerTone,
        note: note.isEmpty ? null : note,
        onChanged: (picked) => onChanged(key, picked),
      ),
      ParamInputType.dropdown => InspectionSelectInput(
        label: field.label,
        options: field.options ?? const [],
        value: value,
        note: note.isEmpty ? null : note,
        onChanged: (picked) => onChanged(key, picked),
      ),
      ParamInputType.number || ParamInputType.text => InspectionTextInput(
        label: field.label,
        value: value,
        hint: field.hint,
        unit: field.unit,
        note: note.isEmpty ? null : note,
        kind: field.type == ParamInputType.number
            ? InspectionTextKind.decimal
            : InspectionTextKind.text,
        onChanged: (typed) => onChanged(key, typed),
      ),
    };
    final remedies = field.remedyOptions;
    if (remedies == null) return answer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        answer,
        AppSpacing.gapSm,
        InspectionSelectInput(
          label: l10n.inspFormRemedy,
          options: remedies,
          value: state.value(field.remedyKey),
          glyph: AppGlyphs.wrench,
          onChanged: (picked) => onChanged(field.remedyKey, picked),
        ),
      ],
    );
  }
}
