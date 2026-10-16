import 'package:flutter/material.dart';

/// Bold sub-heading used between blocks of fields (e.g. "Tank", "Bearings").
class ElectricalSectionHeader extends StatelessWidget {
  final String label;
  const ElectricalSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Single-select radio/choice-chip row. Wraps like the BRD mockups when
/// there are more than a couple of options.
class ElectricalRadioField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  const ElectricalRadioField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final selected = value == opt;
              return ChoiceChip(
                label: Text(opt),
                selected: selected,
                onSelected: (_) => onChanged(opt),
                selectedColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class ElectricalDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const ElectricalDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            value == null
                ? 'Select date'
                : '${value!.day}/${value!.month}/${value!.year}',
          ),
        ),
      ),
    );
  }
}

class ElectricalNumberField extends StatelessWidget {
  final String label;
  final String? unit;
  final String? value;
  final int? maxValue;
  final ValueChanged<String> onChanged;

  const ElectricalNumberField({
    super.key,
    required this.label,
    this.unit,
    required this.value,
    required this.onChanged,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          errorText:
              maxValue != null &&
                  value != null &&
                  int.tryParse(value!) != null &&
                  int.parse(value!) > maxValue!
              ? 'Value must not exceed $maxValue'
              : null,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class ElectricalTextField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;

  const ElectricalTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class ElectricalDropdownField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const ElectricalDropdownField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

/// Read-only row showing existing asset-master data (per the BRD's
/// "Show all Asset Details in read only on top of each inspection form"
/// requirement).
class ElectricalDisplayRow extends StatelessWidget {
  final String label;
  final String value;
  const ElectricalDisplayRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible "Asset Details" header — the accordion required at the top
/// of every inspection form (page 4 of the BRD) so the input area isn't
/// permanently obstructed.
class ElectricalAssetDetailsAccordion extends StatelessWidget {
  final String department;
  final String subDepartment;
  final String asset;
  final Map<String, String> extraDetails;

  const ElectricalAssetDetailsAccordion({
    super.key,
    required this.department,
    required this.subDepartment,
    required this.asset,
    this.extraDetails = const {},
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            title: const Text(
              'Asset Details',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('$department · $subDepartment · $asset'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              ElectricalDisplayRow(label: 'Department', value: department),
              ElectricalDisplayRow(
                label: 'Sub-department',
                value: subDepartment,
              ),
              ElectricalDisplayRow(label: 'Asset', value: asset),
              for (final e in extraDetails.entries)
                ElectricalDisplayRow(label: e.key, value: e.value),
            ],
          ),
        ),
      ),
    );
  }
}
