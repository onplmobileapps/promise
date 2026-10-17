import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';

/// The locomotive's equipment, each in order unless flagged; a flagged item
/// asks what is wrong, and a count or date where it takes one.
class LocomotiveStep extends StatelessWidget {
  const LocomotiveStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final LocomotiveCondition data;
  final VoidCallback onChanged;

  void _set(
    String item,
    LocomotiveEquipmentStatus was, {
    bool? functional,
    List<String>? issues,
    int? count,
    DateTime? date,
  }) {
    data.setStatus(
      item,
      LocomotiveEquipmentStatus(
        isFunctional: functional ?? was.isFunctional,
        selectedIssues: issues ?? was.selectedIssues,
        integerValue: count ?? was.integerValue,
        dateValue: date ?? was.dateValue,
      ),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final issues = data.issueCount;
    return InspectionCard(
      title: 'Condition of Locomotive',
      subtitle: issues == 0
          ? 'Everything starts in order: flag only what is wrong.'
          : '$issues flagged',
      glyph: AppGlyphs.wrench,
      children: [
        for (final item in kLocomotiveItems)
          _item(item, kLocomotiveFieldConfigs[item], data.getStatus(item)),
      ],
    );
  }

  Widget _item(
    String item,
    LocomotiveFieldConfig? config,
    LocomotiveEquipmentStatus status,
  ) {
    // Weather and the like describe a condition, not a pass or a fail.
    if (config != null && config.directSelect) {
      return InspectionMultiChoiceInput(
        label: item,
        options: config.options,
        values: status.selectedIssues,
        toneOf: (_) => AppTone.brand,
        onChanged: (picked) => _set(item, status, issues: picked),
      );
    }
    final flagged = !status.isFunctional;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectionChoiceInput(
          label: item,
          options: const ['OK', 'Issue'],
          value: flagged ? 'Issue' : 'OK',
          toneOf: (option) =>
              option == 'Issue' ? AppTone.danger : AppTone.brand,
          onChanged: (picked) => _set(item, status, functional: picked == 'OK'),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.enter,
          alignment: Alignment.topCenter,
          child: !flagged || config == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (config.options.isNotEmpty)
                        InspectionMultiChoiceInput(
                          label: 'What is wrong',
                          options: config.options,
                          values: status.selectedIssues,
                          onChanged: (picked) =>
                              _set(item, status, issues: picked),
                        ),
                      if (config.requiresInteger) ...[
                        AppSpacing.gapMd,
                        InspectionTextInput(
                          label: 'Value / Quantity',
                          kind: InspectionTextKind.integer,
                          value: status.integerValue?.toString(),
                          onChanged: (typed) =>
                              _set(item, status, count: int.tryParse(typed)),
                        ),
                      ],
                      if (config.requiresDate) ...[
                        AppSpacing.gapMd,
                        InspectionDateInput(
                          label: 'Expiry / Check Date',
                          value: status.dateValue,
                          onChanged: (day) => _set(item, status, date: day),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
