import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';

/// A titled card used to group related fields on every step.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final String? subtitle;
  final Color? iconColor;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Compact chip-based single-select — faster to tap than radio buttons, and
/// visually communicates "one choice" without eating vertical space.
class RadioChipGroup extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool dense;

  const RadioChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
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
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Two-state segmented toggle defaulting to "Functional" (green) so the user
/// only has to interact with items that actually have a problem.
class FunctionalToggleTile extends StatelessWidget {
  final String label;
  final bool functional;
  final ValueChanged<bool> onChanged;

  const FunctionalToggleTile({
    super.key,
    required this.label,
    required this.functional,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final goodColor = Colors.green.shade600;
    final badColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('OK'),
                selected: functional,
                onSelected: (val) {
                  if (val) onChanged(true);
                },
                selectedColor: goodColor,
                avatar: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: functional ? Colors.white : goodColor,
                ),
                showCheckmark: false,
                labelStyle: TextStyle(color: functional ? Colors.white : null),
              ),
              ChoiceChip(
                label: const Text('Issue'),
                selected: !functional,
                onSelected: (val) {
                  if (val) onChanged(false);
                },
                selectedColor: badColor,
                avatar: Icon(
                  Icons.warning,
                  size: 16,
                  color: !functional ? Colors.white : badColor,
                ),
                showCheckmark: false,
                labelStyle: TextStyle(color: !functional ? Colors.white : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fast "type a name" picker with autocomplete over the staff directory,
/// with a collapsible fallback for a fully manual cascading selection.
class PersonPickerField extends StatelessWidget {
  final String label;
  final Person? value;
  final ValueChanged<Person?> onChanged;

  const PersonPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Autocomplete<Person>(
          displayStringForOption: (p) => p.display,
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return kStaffDirectory;
            final q = textEditingValue.text.toLowerCase();
            return kStaffDirectory.where(
              (p) => p.display.toLowerCase().contains(q),
            );
          },
          onSelected: onChanged,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) {
            if (value != null && controller.text.isEmpty) {
              controller.text = value!.display;
            }
            return TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => focusNode.unfocus(),
              decoration: InputDecoration(
                hintText: 'Search name, designation, department, org unit',
                prefixIcon: const Icon(Icons.person_search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                suffixIcon: value != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          controller.clear();
                          onChanged(null);
                        },
                      )
                    : null,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 240,
                    maxWidth: 420,
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: options
                        .map(
                          (p) => ListTile(
                            dense: true,
                            title: Text(p.name),
                            subtitle: Text(
                              '${p.designation} • ${p.department} • ${p.orgUnit}',
                            ),
                            onTap: () => onSelected(p),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Small status pill, e.g. used in the review step and sidebar.
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
