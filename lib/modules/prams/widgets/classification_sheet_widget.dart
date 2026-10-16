import 'package:flutter/material.dart';

import 'package:railway_hrms/modules/prams/data/models/accident_reference.dart';
import 'package:railway_hrms/modules/prams/screens/report_accident_screen.dart';

class ClassificationSheet extends StatelessWidget {
  final List<AccidentClass> classes;
  final AccidentClass? selected;
  const ClassificationSheet({
    super.key,
    required this.classes,
    required this.selected,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accident Classification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Severity is applied automatically from the class',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: classes.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              itemBuilder: (context, index) {
                final c = classes[index];
                final isSelected = selected?.code == c.code;
                final sev = severityColor(c.defaultSeverity.toString());

                return Material(
                  color: isSelected
                      ? cs.primaryContainer.withValues(alpha: 0.35)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 44),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.code,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.shortMeaning,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: sev),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.defaultSeverity,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: sev,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded, color: cs.primary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
