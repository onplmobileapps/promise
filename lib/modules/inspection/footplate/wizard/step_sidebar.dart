import 'package:flutter/material.dart';

class StepMeta {
  final String title;
  final IconData icon;
  const StepMeta(this.title, this.icon);
}

const List<StepMeta> kSteps = [
  StepMeta('Train Schedule', Icons.train),
  StepMeta('Locomotive', Icons.build_circle),
  StepMeta('Station Assets', Icons.location_city),
  StepMeta('Asset Checks', Icons.checklist),
  StepMeta('Punctuality & OPs', Icons.timer),
  StepMeta('Review & Submit', Icons.fact_check),
];

/// Vertical sidebar for wide screens (tablet / desktop / web).
class StepSidebar extends StatelessWidget {
  final int currentStep;
  final int maxReachedStep;
  final ValueChanged<int> onStepTapped;

  const StepSidebar({
    super.key,
    required this.currentStep,
    required this.maxReachedStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.train, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Footplate\nInspection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < kSteps.length; i++) _tile(context, i),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, int i) {
    final scheme = Theme.of(context).colorScheme;
    final step = kSteps[i];
    final unlocked = i <= maxReachedStep;
    final isCurrent = i == currentStep;
    final isDone = i < maxReachedStep;

    return InkWell(
      onTap: unlocked ? () => onStepTapped(i) : null,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isCurrent ? scheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          color: isCurrent
              ? scheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,

              child: isDone
                  ? Icon(Icons.check, size: 16)
                  : Icon(
                      step.icon,
                      size: 15,
                      color: isCurrent
                          ? Colors.white
                          : (unlocked
                                ? scheme.onSurfaceVariant
                                : scheme.outline),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: unlocked ? scheme.onSurface : scheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable step tabs for narrow (mobile) screens.
class StepTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final int maxReachedStep;
  final ValueChanged<int> onStepTapped;

  const StepTopBar({
    super.key,
    required this.currentStep,
    required this.maxReachedStep,
    required this.onStepTapped,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 64,
      color: scheme.surfaceContainerLow,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: kSteps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final step = kSteps[i];
          final unlocked = i <= maxReachedStep;
          final isCurrent = i == currentStep;
          return ChoiceChip(
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: isCurrent ? Colors.white : scheme.onSurfaceVariant,
            ),
            backgroundColor: scheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),

            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  step.icon,
                  key: ValueKey('step_icon'),
                  size: 14,
                  color: isCurrent ? Colors.white : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text('${i + 1}. ${step.title}'),
              ],
            ),
            selected: isCurrent,
            onSelected: unlocked ? (_) => onStepTapped(i) : null,
            selectedColor: scheme.primaryContainer,
            disabledColor: scheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
          );
        },
      ),
    );
  }
}
