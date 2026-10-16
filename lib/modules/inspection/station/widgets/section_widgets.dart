import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/shared/inspection_colors.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';
import 'package:railway_hrms/modules/inspection/station/widgets/field_widgets.dart';

class FixedSectionBody extends StatelessWidget {
  final InspectionSection section;
  final StationInspectionController controller;
  const FixedSectionBody({
    super.key,
    required this.section,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth < 560 ? 1 : 2;
        const spacing = 18.0;
        final cellWidth = columns == 1
            ? maxWidth
            : (maxWidth - spacing * (columns - 1)) / columns;

        final children = <Widget>[];
        for (final item in section.items) {
          if (item is SubheadFormItem) {
            children.add(SizedBox(width: maxWidth, child: _Subhead(item)));
            continue;
          }
          final spec = (item as FieldFormItem).spec;
          final full = spec.span2 || columns == 1;

          // blockOverhaulDate's overdue period depends on the blockType select
          // above it; the screen already rebuilds this whole body whenever any
          // field changes (StationInspectionController -> ChangeNotifier), so
          // simply re-reading blockType here always reflects the latest choice.
          final field = spec.id == 'blockOverhaulDate'
              ? FieldRenderer(
                  spec: spec,
                  controller: controller,
                  overdueYearsOverride: controller.overhaulYearsForBlockType(
                    controller.get<String>('blockType'),
                  ),
                )
              : FieldRenderer(spec: spec, controller: controller);

          children.add(
            SizedBox(width: full ? maxWidth : cellWidth, child: field),
          );
        }

        final hasExtinguishers = section.items.any(
          (i) => i is FieldFormItem && i.spec.id == 'fireExtCount',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: spacing, runSpacing: 16, children: children),
            if (hasExtinguishers) ...[
              const SizedBox(height: 14),
              _FireExtinguisherDates(
                controller: controller,
                maxWidth: maxWidth,
                columns: columns,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Subhead extends StatelessWidget {
  final SubheadFormItem item;
  const _Subhead(this.item);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: Text(
                item.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                ),
              ),
            ),
            if (item.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FireExtinguisherDates extends StatelessWidget {
  final StationInspectionController controller;
  final double maxWidth;
  final int columns;
  const _FireExtinguisherDates({
    required this.controller,
    required this.maxWidth,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final count = controller.fireExtCount;
    if (count <= 0) {
      final scheme = Theme.of(context).colorScheme;
      return Text(
        'Set the number of extinguishers above to add a filling date for each one.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    const spacing = 18.0;
    final cellWidth = columns == 1
        ? maxWidth
        : (maxWidth - spacing * (columns - 1)) / columns;
    return Wrap(
      spacing: spacing,
      runSpacing: 16,
      children: List.generate(count, (i) {
        final n = i + 1;
        final spec = FieldSpec(
          controller.fireExtDateId(n),
          'Extinguisher #$n — Date of Filling',
          FieldKind.dateOverdue,
          overdueYears: 1,
        );
        return SizedBox(
          width: columns == 1 ? maxWidth : cellWidth,
          child: FieldRenderer(spec: spec, controller: controller),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Signals section: a card per fixed signal, each with 5 compact toggles.
// ---------------------------------------------------------------------------

class SignalsSectionBody extends StatelessWidget {
  final StationInspectionController controller;
  const SignalsSectionBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 640 ? double.infinity : 300.0;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: List.generate(kSignalNames.length, (i) {
        return SizedBox(
          width: cardWidth,
          child: _SignalCard(
            index: i,
            name: kSignalNames[i],
            controller: controller,
          ),
        );
      }),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final int index;
  final String name;
  final StationInspectionController controller;
  const _SignalCard({
    required this.index,
    required this.name,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,

        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...kSignalParts.map((part) {
            final fid = 'sig_${index}_${part[0]}';
            final selected = controller.get<String>(fid);
            final isUnsatisfactory = selected == 'Unsatisfactory';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          part[1],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MiniToggle(
                        fid: fid,
                        selected: selected,
                        controller: controller,
                      ),
                    ],
                  ),
                  if (isUnsatisfactory)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: InspectionColors.danger.withValues(
                            alpha: 0.05,
                          ),
                          border: Border.all(
                            color: InspectionColors.danger.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: RemarkField(
                          fieldId: '${fid}_remark',
                          controller: controller,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String fid;
  final String? selected;
  final StationInspectionController controller;
  const _MiniToggle({
    required this.fid,
    required this.selected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, String value) {
      final isSelected = selected == value;
      final tone = classifyValue(value);
      final color = tone == FieldTone.positive
          ? InspectionColors.success
          : InspectionColors.danger;
      return Padding(
        padding: const EdgeInsets.only(left: 5),
        child: OutlinedButton(
          onPressed: () => controller.setField(fid, value),
          style: OutlinedButton.styleFrom(
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            backgroundColor: isSelected ? color : scheme.surface,
            foregroundColor: isSelected
                ? scheme.surface
                : scheme.onSurfaceVariant,
            side: BorderSide(color: isSelected ? color : scheme.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('Satis', 'Satisfactory'),
        chip('Unsatis', 'Unsatisfactory'),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Repeatable sections: points / level crossings / track circuits / failures.
// ---------------------------------------------------------------------------

class RepeatSectionBody extends StatelessWidget {
  final String type;
  final StationInspectionController controller;
  const RepeatSectionBody({
    super.key,
    required this.type,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final def = kRepeatDefs[type]!;
    final rows = controller.rowsFor(type);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(rows.length, (i) {
          final rowId = rows[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RepeatRowCard(
              type: type,
              rowId: rowId,
              index: i,
              controller: controller,
              canRemove: rows.length > def.minRows,
            ),
          );
        }),
        OutlinedButton.icon(
          onPressed: () => controller.addRow(type),
          icon: Icon(Icons.add, size: 18, color: scheme.primary),
          label: Text(
            'Add ${def.label.toLowerCase()}',
            style: TextStyle(color: scheme.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: scheme.outlineVariant,
              style: BorderStyle.solid,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _RepeatRowCard extends StatelessWidget {
  final String type;
  final int rowId;
  final int index;
  final StationInspectionController controller;
  final bool canRemove;
  const _RepeatRowCard({
    required this.type,
    required this.rowId,
    required this.index,
    required this.controller,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    final def = kRepeatDefs[type]!;
    final scheme = Theme.of(context).colorScheme;
    final prefix = controller.rowPrefix(type, rowId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${def.label} ${index + 1}'.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: .4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (canRemove)
                TextButton.icon(
                  onPressed: () => controller.removeRow(type, rowId),
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: InspectionColors.danger,
                  ),
                  label: Text(
                    'Remove',
                    style: TextStyle(
                      color: InspectionColors.danger,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth < 520 ? 1 : 2;
              const spacing = 16.0;
              final cellWidth = columns == 1
                  ? maxWidth
                  : (maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: 14,
                children: def.cols.map((col) {
                  final spec = col.build('${prefix}_${col.key}');
                  final full = spec.span2 || columns == 1;
                  return SizedBox(
                    width: full ? maxWidth : cellWidth,
                    child: FieldRenderer(spec: spec, controller: controller),
                  );
                }).toList(),
              );
            },
          ),
          if (def.hasTotal) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                'Total: ${controller.rowTotal(type, rowId).toStringAsFixed(0)}',
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
