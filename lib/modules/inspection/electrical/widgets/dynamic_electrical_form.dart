import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/electrical/models/electrical_field_spec.dart';
import 'package:railway_hrms/modules/inspection/electrical/widgets/electrical_form_widgets.dart';

class DynamicElectricalForm extends StatefulWidget {
  final List<ElectricalFieldSpec> fields;
  final Map<String, dynamic> answers;
  final VoidCallback onChanged;

  const DynamicElectricalForm({
    super.key,
    required this.fields,
    required this.answers,
    required this.onChanged,
  });

  @override
  State<DynamicElectricalForm> createState() => _DynamicElectricalFormState();
}

class _DynamicElectricalFormState extends State<DynamicElectricalForm> {
  bool _visible(ElectricalFieldSpec spec, [String prefix = '']) {
    if (spec.conditionKey == null) return true;
    final actual = widget.answers['$prefix${spec.conditionKey}'];
    final expected = spec.conditionValue;
    if (expected is List && expected != null) return expected.contains(actual);
    return actual == expected;
  }

  void _set(String key, dynamic value) {
    setState(() => widget.answers[key] = value);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.fields.map((f) => _buildField(f)).toList(),
    );
  }

  Widget _buildField(ElectricalFieldSpec spec, [String prefix = '']) {
    if (!_visible(spec, prefix)) return const SizedBox.shrink();
    final key = '$prefix${spec.key}';

    switch (spec.type) {
      case ElectricalFieldType.section:
        return ElectricalSectionHeader(spec.label);

      case ElectricalFieldType.radio:
        return ElectricalRadioField(
          label: spec.label,
          options: spec.options ?? const [],
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case ElectricalFieldType.date:
        return ElectricalDateField(
          label: spec.label,
          value: widget.answers[key] as DateTime?,
          onChanged: (v) => _set(key, v),
        );

      case ElectricalFieldType.number:
        return ElectricalNumberField(
          label: spec.label,
          unit: spec.unit,
          value: widget.answers[key] as String?,
          maxValue: spec.maxValue,
          onChanged: (v) => _set(key, v),
        );

      case ElectricalFieldType.text:
        return ElectricalTextField(
          label: spec.label,
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case ElectricalFieldType.dropdown:
        return ElectricalDropdownField(
          label: spec.label,
          options: spec.options ?? const [],
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case ElectricalFieldType.group:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                ...(spec.children ?? []).map((c) => _buildField(c, prefix)),
              ],
            ),
          ),
        );

      case ElectricalFieldType.checkbox:
        // For now, treat checkbox as a yes/no radio
        return ElectricalRadioField(
          label: spec.label,
          options: const ['Yes', 'No'],
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );
    }
  }
}
