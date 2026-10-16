import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/widgets/civil_form_widgets.dart';

/// Renders a `List<CivilFieldSpec>` and manages the answers in-memory.
///
/// Answers are kept as a flat `Map<String, dynamic>` on the *caller's*
/// [answers] object so drafts can be persisted trivially (it's already
/// JSON-shaped — see `civil_inspection_draft_service.dart`). Repeat-group
/// instances are stored under `${groupKey}[instanceIndex].${fieldKey}`.
class DynamicCivilForm extends StatefulWidget {
  final List<CivilFieldSpec> fields;
  final Map<String, dynamic> answers;
  final VoidCallback onChanged;

  const DynamicCivilForm({
    super.key,
    required this.fields,
    required this.answers,
    required this.onChanged,
  });

  @override
  State<DynamicCivilForm> createState() => _DynamicCivilFormState();
}

class _DynamicCivilFormState extends State<DynamicCivilForm> {
  /// Number of instances currently added for each repeat-group key.
  final Map<String, int> _repeatCounts = {};

  bool _visible(CivilFieldSpec spec, [String prefix = '']) {
    if (spec.conditionKey == null) return true;
    final actual = widget.answers['$prefix${spec.conditionKey}'];
    final expected = spec.conditionValue;
    if (expected is List) return expected.contains(actual);
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

  Widget _buildField(CivilFieldSpec spec, [String prefix = '']) {
    if (!_visible(spec, prefix)) return const SizedBox.shrink();
    final key = '$prefix${spec.key}';

    switch (spec.type) {
      case CivilFieldType.section:
        return CivilSectionHeader(spec.label);

      case CivilFieldType.radio:
        return CivilRadioField(
          label: spec.label,
          options: spec.options ?? const [],
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case CivilFieldType.date:
        return CivilDateField(
          label: spec.label,
          value: widget.answers[key] as DateTime?,
          onChanged: (v) => _set(key, v),
        );

      case CivilFieldType.number:
        return CivilNumberField(
          label: spec.label,
          unit: spec.unit,
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case CivilFieldType.text:
        return CivilTextField(
          label: spec.label,
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case CivilFieldType.dropdown:
        return CivilDropdownField(
          label: spec.label,
          options: spec.options ?? const [],
          value: widget.answers[key] as String?,
          onChanged: (v) => _set(key, v),
        );

      case CivilFieldType.display:
        return CivilDisplayRow(
          label: spec.label,
          value: spec.displayValue ?? '—',
        );

      case CivilFieldType.group:
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

      case CivilFieldType.repeatGroup:
        return _buildRepeatGroup(spec, prefix);
    }
  }

  Widget _buildRepeatGroup(CivilFieldSpec spec, String prefix) {
    final count =
        _repeatCounts[spec.key] ??
        // Infer existing count from any previously-saved answers so a
        // resumed draft shows the right number of instances.
        _inferExistingCount(spec, prefix);
    _repeatCounts[spec.key] = count;

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < count; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${spec.itemLabel} ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () =>
                            setState(() => _repeatCounts[spec.key] = count - 1),
                      ),
                    ],
                  ),
                  ...(spec.children ?? []).map(
                    (c) => _buildField(c, '$prefix${spec.key}[$i].'),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _repeatCounts[spec.key] = count + 1),
            icon: const Icon(Icons.add),
            label: Text('Add ${spec.itemLabel}'),
          ),
        ],
      ),
    );
  }

  int _inferExistingCount(CivilFieldSpec spec, String prefix) {
    final pattern = RegExp('^${RegExp.escape("$prefix${spec.key}[")}(\\d+)\\]');
    var maxIndex = -1;
    for (final k in widget.answers.keys) {
      final m = pattern.firstMatch(k);
      if (m != null) {
        final idx = int.tryParse(m.group(1)!) ?? -1;
        if (idx > maxIndex) maxIndex = idx;
      }
    }
    return maxIndex + 1;
  }
}
