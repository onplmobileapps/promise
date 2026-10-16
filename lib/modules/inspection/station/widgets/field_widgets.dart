import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ⚠️ Update this import to point at wherever AppColors lives in your app
// (the file that defines InspectionColors.success / InspectionColors.warning / InspectionColors.danger).

import 'package:railway_hrms/modules/inspection/shared/inspection_colors.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';

/// Renders a single [FieldSpec] against the ambient [Theme] — no hard-coded
/// colors here, only `Theme.of(context).colorScheme` and the app's own
/// [AppColors] status palette (success / warning / danger) for tone cues.
class FieldRenderer extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  final ValueChanged<String>?
  onToggleChanged; // used by 'blockType' select to re-key overhaul years
  final int?
  overdueYearsOverride; // used by blockOverhaulDate, which depends on blockType

  const FieldRenderer({
    super.key,
    required this.spec,
    required this.controller,
    this.onToggleChanged,
    this.overdueYearsOverride,
  });

  @override
  Widget build(BuildContext context) {
    final child = switch (spec.kind) {
      FieldKind.text => _TextInput(spec: spec, controller: controller),
      FieldKind.textarea => _TextInput(
        spec: spec,
        controller: controller,
        maxLines: 4,
      ),
      FieldKind.number => _NumberInput(spec: spec, controller: controller),
      FieldKind.date => _DateInput(spec: spec, controller: controller),
      FieldKind.select => _SelectInput(
        spec: spec,
        controller: controller,
        onChanged: onToggleChanged,
      ),
      FieldKind.decimal => _DecimalInput(spec: spec, controller: controller),
      FieldKind.dateOverdue => _DateOverdueInput(
        spec: spec,
        controller: controller,
        yearsOverride: overdueYearsOverride,
      ),
      FieldKind.toggle => _ToggleInput(spec: spec, controller: controller),
      FieldKind.toggleRemark => _ToggleRemarkInput(
        spec: spec,
        controller: controller,
      ),
      FieldKind.stepper => _StepperInput(spec: spec, controller: controller),
    };

    return SizedBox(width: spec.span2 ? double.infinity : null, child: child);
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _FieldNote extends StatelessWidget {
  final String text;
  const _FieldNote(this.text);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    isDense: true,
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: scheme.surfaceContainerLow,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: scheme.primary, width: 1.6),
    ),
  );
}

// ---------------------------------------------------------------------------
// Text / textarea
// ---------------------------------------------------------------------------

class _TextInput extends StatefulWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  final int maxLines;
  const _TextInput({
    required this.spec,
    required this.controller,
    this.maxLines = 1,
  });

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  late final TextEditingController _tec = TextEditingController(
    text: widget.controller.get<String>(widget.spec.id) ?? '',
  );

  @override
  void dispose() {
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.spec.label),
        TextField(
          controller: _tec,
          maxLines: widget.maxLines,
          decoration: _decoration(context, hint: widget.spec.placeholder),
          onChanged: (v) => widget.controller.setField(widget.spec.id, v),
        ),
        if (widget.spec.note != null) _FieldNote(widget.spec.note!),
      ],
    );
  }
}

class _NumberInput extends StatefulWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _NumberInput({required this.spec, required this.controller});

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _tec = TextEditingController(
    text: widget.controller.get<num>(widget.spec.id)?.toString() ?? '',
  );

  @override
  void dispose() {
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.spec.label),
        TextField(
          controller: _tec,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration(context),
          onChanged: (v) {
            final n = int.tryParse(v);
            widget.controller.setField(widget.spec.id, n);
          },
        ),
        if (widget.spec.note != null) _FieldNote(widget.spec.note!),
      ],
    );
  }
}

class _DecimalInput extends StatefulWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _DecimalInput({required this.spec, required this.controller});

  @override
  State<_DecimalInput> createState() => _DecimalInputState();
}

class _DecimalInputState extends State<_DecimalInput> {
  late final TextEditingController _tec = TextEditingController(
    text: widget.controller.get<double>(widget.spec.id)?.toString() ?? '',
  );

  @override
  void dispose() {
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final raw = widget.controller.get<double>(widget.spec.id);
    final outOfRange =
        raw != null &&
        ((widget.spec.min != null && raw < widget.spec.min!) ||
            (widget.spec.max != null && raw > widget.spec.max!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(widget.spec.label),
        TextField(
          controller: _tec,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: _decoration(
            context,
            suffix: widget.spec.unit != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        widget.spec.unit!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          onChanged: (v) {
            final n = double.tryParse(v);
            widget.controller.setField(widget.spec.id, n);
            setState(() {});
          },
        ),
        if (widget.spec.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              outOfRange
                  ? '⚠ Outside expected range — ${widget.spec.hint}'
                  : widget.spec.hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: outOfRange
                    ? InspectionColors.warning
                    : scheme.onSurfaceVariant,
                fontWeight: outOfRange ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date / date-overdue
// ---------------------------------------------------------------------------

class _DateInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _DateInput({required this.spec, required this.controller});

  @override
  Widget build(BuildContext context) {
    final date = controller.get<DateTime>(spec.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(spec.label),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) controller.setField(spec.id, picked);
          },
          child: InputDecorator(
            decoration: _decoration(
              context,
              suffix: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              date != null ? _fmt(date) : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        if (spec.note != null) _FieldNote(spec.note!),
      ],
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _DateOverdueInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  final int? yearsOverride;
  const _DateOverdueInput({
    required this.spec,
    required this.controller,
    this.yearsOverride,
  });

  @override
  Widget build(BuildContext context) {
    final date = controller.get<DateTime>(spec.id);
    final years = yearsOverride ?? spec.overdueYears ?? 1;
    final info = controller.overdueInfo(spec.id, years);
    final scheme = Theme.of(context).colorScheme;

    Color badgeColor;
    switch (info.status) {
      case OverdueStatus.overdue:
        badgeColor = InspectionColors.danger;
        break;
      case OverdueStatus.dueSoon:
        badgeColor = InspectionColors.warning;
        break;
      case OverdueStatus.valid:
        badgeColor = InspectionColors.success;
        break;
      case OverdueStatus.empty:
        badgeColor = scheme.onSurfaceVariant;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(spec.label),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) controller.setField(spec.id, picked);
          },
          child: InputDecorator(
            decoration: _decoration(
              context,
              suffix: const Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(
              date != null ? _DateInput._fmt(date) : 'Select date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: date != null
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  info.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (spec.note != null) _FieldNote(spec.note!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Select (dropdown)
// ---------------------------------------------------------------------------

class _SelectInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  final ValueChanged<String>? onChanged;
  const _SelectInput({
    required this.spec,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = controller.get<String>(spec.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(spec.label),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: _decoration(context),
          hint: const Text('Select…'),
          items: spec.options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            controller.setField(spec.id, v);
            onChanged?.call(v);
          },
        ),
        if (spec.note != null) _FieldNote(spec.note!),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle buttons (with tone coloring) + optional remark field
// ---------------------------------------------------------------------------

Color _toneColor(BuildContext context, FieldTone tone) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    FieldTone.positive => InspectionColors.success,
    FieldTone.negative => InspectionColors.danger,
    FieldTone.amber => InspectionColors.warning,
    FieldTone.neutral => scheme.primary,
  };
}

class _ToggleInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _ToggleInput({required this.spec, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = controller.get<String>(spec.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(spec.label),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: spec.options.map((opt) {
            final isSelected = selected == opt;
            final tone = classifyValue(opt);
            final color = _toneColor(context, tone);
            return OutlinedButton(
              onPressed: () => controller.setField(spec.id, opt),
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? color
                    : scheme.surfaceContainerLow,
                foregroundColor: isSelected
                    ? scheme.surface
                    : scheme.onSurfaceVariant,
                side: BorderSide(
                  color: isSelected ? color : scheme.outlineVariant,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(opt, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
        ),
        if (spec.note != null) _FieldNote(spec.note!),
      ],
    );
  }
}

class _ToggleRemarkInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _ToggleRemarkInput({required this.spec, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.get<String>(spec.id);
    final showRemark =
        selected != null && classifyValue(selected) == FieldTone.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleInput(spec: spec, controller: controller),
        if (showRemark) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: InspectionColors.danger.withValues(alpha: 0.05),
              border: Border.all(
                color: InspectionColors.danger.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks (unsatisfactory)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: InspectionColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                RemarkField(fieldId: spec.remarkId, controller: controller),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class RemarkField extends StatefulWidget {
  final String fieldId;
  final StationInspectionController controller;
  const RemarkField({
    super.key,
    required this.fieldId,
    required this.controller,
  });

  @override
  State<RemarkField> createState() => _RemarkFieldState();
}

class _RemarkFieldState extends State<RemarkField> {
  late final TextEditingController _tec = TextEditingController(
    text: widget.controller.get<String>(widget.fieldId) ?? '',
  );

  @override
  void dispose() {
    _tec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _tec,
      maxLines: 3,
      maxLength: 100,
      decoration: _decoration(
        context,
        hint: 'Describe the issue…',
      ).copyWith(counterStyle: const TextStyle(fontSize: 10)),
      onChanged: (v) => widget.controller.setField(widget.fieldId, v),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper (fire extinguisher count, etc.)
// ---------------------------------------------------------------------------

class _StepperInput extends StatelessWidget {
  final FieldSpec spec;
  final StationInspectionController controller;
  const _StepperInput({required this.spec, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = controller.get<int>(spec.id) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(spec.label),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          width: 132,
          height: 40,
          child: Row(
            children: [
              _StepBtn(
                icon: Icons.remove,
                onTap: value > 0
                    ? () => controller.setField(spec.id, value - 1)
                    : null,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: scheme.outlineVariant),
                      right: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                onTap: () => controller.setField(spec.id, value + 1),
              ),
            ],
          ),
        ),
        if (spec.note != null) _FieldNote(spec.note!),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: double.infinity,
      child: Material(
        color: scheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
