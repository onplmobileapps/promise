import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';

class LocomotiveStep extends StatefulWidget {
  final LocomotiveCondition data;
  final VoidCallback onChanged;

  const LocomotiveStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<LocomotiveStep> createState() => _LocomotiveStepState();
}

class _LocomotiveStepState extends State<LocomotiveStep> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Condition of Locomotive',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'All items default to "OK" — just flag anything that has an issue.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        if (widget.data.issueCount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StatusPill(
              text: '${widget.data.issueCount} item(s) flagged',
              color: scheme.error,
            ),
          ),
        SectionCard(
          title: 'Equipment Checklist',
          icon: Icons.build_circle,
          child: Column(
            children: kLocomotiveItems.map((item) {
              final config = kLocomotiveFieldConfigs[item];
              final status = widget.data.getStatus(item);

              // Items like "Weather" describe a condition rather than a
              // pass/fail check — skip the OK/Issue toggle and go straight
              // to the selection panel.
              if (config != null && config.directSelect) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _LocomotiveDirectSelectField(
                    label: item,
                    config: config,
                    status: status,
                    onChanged: (newStatus) {
                      widget.data.setStatus(item, newStatus);
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FunctionalToggleTile(
                    label: item,
                    functional: status.isFunctional,
                    onChanged: (v) {
                      widget.data.setStatus(
                        item,
                        LocomotiveEquipmentStatus(
                          isFunctional: v,
                          selectedIssues: status.selectedIssues,
                          integerValue: status.integerValue,
                          dateValue: status.dateValue,
                        ),
                      );
                      widget.onChanged();
                      setState(() {});
                    },
                  ),
                  // Show additional fields when not functional
                  if (!status.isFunctional && config != null) ...[
                    const SizedBox(height: 8),
                    _LocomotiveIssueFields(
                      config: config,
                      status: status,
                      onChanged: (newStatus) {
                        widget.data.setStatus(item, newStatus);
                        widget.onChanged();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

/// Direct selection panel for items (e.g. "Weather") that describe a
/// condition rather than a pass/fail check — no OK/Issue toggle, the chip
/// panel is always visible.
class _LocomotiveDirectSelectField extends StatelessWidget {
  final String label;
  final LocomotiveFieldConfig config;
  final LocomotiveEquipmentStatus status;
  final ValueChanged<LocomotiveEquipmentStatus> onChanged;

  const _LocomotiveDirectSelectField({
    required this.label,
    required this.config,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: config.options.map((option) {
            final isSelected = status.selectedIssues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: isSelected ? Colors.white : scheme.error,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : scheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (selected) {
                final newIssues = List<String>.from(status.selectedIssues);
                if (selected) {
                  newIssues.add(option);
                } else {
                  newIssues.remove(option);
                }
                onChanged(
                  LocomotiveEquipmentStatus(
                    isFunctional: status.isFunctional,
                    selectedIssues: newIssues,
                    integerValue: status.integerValue,
                    dateValue: status.dateValue,
                  ),
                );
              },
              backgroundColor: scheme.surface,
              selectedColor: scheme.error,
              side: BorderSide(
                color: isSelected ? scheme.error : scheme.outlineVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LocomotiveIssueFields extends StatefulWidget {
  final LocomotiveFieldConfig config;
  final LocomotiveEquipmentStatus status;
  final ValueChanged<LocomotiveEquipmentStatus> onChanged;

  const _LocomotiveIssueFields({
    required this.config,
    required this.status,
    required this.onChanged,
  });

  @override
  State<_LocomotiveIssueFields> createState() => _LocomotiveIssueFieldsState();
}

class _LocomotiveIssueFieldsState extends State<_LocomotiveIssueFields> {
  late TextEditingController _integerController;

  @override
  void initState() {
    super.initState();
    _integerController = TextEditingController(
      text: widget.status.integerValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _integerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMultiSelect =
        widget.config.fieldType == LocomotiveFieldType.multiSelect;
    final requiresInteger = widget.config.requiresInteger;
    final requiresDate = widget.config.requiresDate;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multi-select checkboxes
          if (isMultiSelect) ...[
            Row(
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 16,
                  color: scheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Issues:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.config.options.map((option) {
                final isSelected = widget.status.selectedIssues.contains(
                  option,
                );
                return FilterChip(
                  label: Text(option),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : scheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: isSelected ? Colors.white : scheme.error,
                  ),
                  onSelected: (selected) {
                    final newIssues = List<String>.from(
                      widget.status.selectedIssues,
                    );
                    if (selected) {
                      newIssues.add(option);
                    } else {
                      newIssues.remove(option);
                    }
                    widget.onChanged(
                      LocomotiveEquipmentStatus(
                        isFunctional: widget.status.isFunctional,
                        selectedIssues: newIssues,
                        integerValue: widget.status.integerValue,
                        dateValue: widget.status.dateValue,
                      ),
                    );
                  },
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.error,
                  side: BorderSide(
                    color: isSelected ? scheme.error : scheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ],

          // Integer field
          if (requiresInteger) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _integerController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Value / Quantity',
                labelStyle: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'e.g., notches count, stock qty',
                isDense: true,
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: scheme.error.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: scheme.error.withValues(alpha: 0.3),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final intValue = int.tryParse(value);
                widget.onChanged(
                  LocomotiveEquipmentStatus(
                    isFunctional: widget.status.isFunctional,
                    selectedIssues: widget.status.selectedIssues,
                    integerValue: intValue,
                    dateValue: widget.status.dateValue,
                  ),
                );
              },
            ),
          ],

          // Date field
          if (requiresDate) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: widget.status.dateValue ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  widget.onChanged(
                    LocomotiveEquipmentStatus(
                      isFunctional: widget.status.isFunctional,
                      selectedIssues: widget.status.selectedIssues,
                      integerValue: widget.status.integerValue,
                      dateValue: pickedDate,
                    ),
                  );
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Expiry / Check Date',
                  labelStyle: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: scheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: scheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: scheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: scheme.error,
                  ),
                ),
                child: Text(
                  widget.status.dateValue != null
                      ? '${widget.status.dateValue!.day}/${widget.status.dateValue!.month}/${widget.status.dateValue!.year}'
                      : 'Tap to select date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
