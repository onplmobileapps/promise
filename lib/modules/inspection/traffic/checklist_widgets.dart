import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

/// Renders a whole group of [ChecklistItem]s as a single multi-select
/// checkbox list, replacing what the BRD expresses as N separate
/// Available/Not-Available radio-button rows.
///
/// Convention (matches the rest of the app): checked = positive state and
/// is the default, so an inspector who finds everything in order can save
/// the section with zero taps — they only interact with the exceptions.
/// A "Mark all" action is provided for the inverse case (e.g. recovering
/// from an accidental mass-uncheck, or a section where most items *are*
/// missing).
class ChecklistGroup extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<ChecklistItem> items;
  final ChecklistFormData data;
  final String positiveLabel;
  final String negativeLabel;
  final VoidCallback onChanged;
  final String? subtitle;

  const ChecklistGroup({
    super.key,
    required this.title,
    required this.items,
    required this.data,
    required this.onChanged,
    this.icon,
    this.positiveLabel = 'OK',
    this.negativeLabel = 'Issue',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final issueCount = data.issueCountFor(items);

    return SectionCard(
      title: title,
      icon: icon,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  issueCount == 0
                      ? 'All items $positiveLabel'
                      : '$issueCount of ${items.length} flagged',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: issueCount == 0
                        ? Colors.green.shade600
                        : scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  data.markAll(items, checked: true);
                  onChanged();
                },
                child: Text('Mark all $positiveLabel'),
              ),
            ],
          ),
          const Divider(height: 8),
          ...items.map(
            (item) => _ChecklistRow(
              item: item,
              answer: data.of(item.key),
              positiveLabel: positiveLabel,
              negativeLabel: negativeLabel,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatefulWidget {
  final ChecklistItem item;
  final ChecklistAnswer answer;
  final String positiveLabel;
  final String negativeLabel;
  final VoidCallback onChanged;

  const _ChecklistRow({
    required this.item,
    required this.answer,
    required this.positiveLabel,
    required this.negativeLabel,
    required this.onChanged,
  });

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.answer.quantity);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ChecklistRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.answer.quantity != _controller.text) {
      _controller.text = widget.answer.quantity;
    }
  }

  bool get _showQuantity =>
      widget.item.hasQuantity &&
      (widget.answer.checked == widget.item.quantityWhenChecked);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                widget.answer.checked = !widget.answer.checked;
              });
              widget.onChanged();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: widget.answer.checked,
                    onChanged: (v) {
                      setState(() {
                        widget.answer.checked = v ?? true;
                      });
                      widget.onChanged();
                    },
                  ),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  StatusPill(
                    text: widget.answer.checked
                        ? widget.positiveLabel
                        : widget.negativeLabel,
                    color: widget.answer.checked
                        ? Colors.green.shade600
                        : scheme.error,
                  ),
                ],
              ),
            ),
          ),
          if (_showQuantity)
            Padding(
              padding: const EdgeInsets.only(left: 44, right: 4, bottom: 8),
              child: SizedBox(
                width: 180,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.item.quantityLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    helperText: widget.item.maxQuantityFromAssetKey != null
                        ? 'Must not exceed asset quantity'
                        : null,
                  ),
                  controller: _controller,
                  onChanged: (v) {
                    widget.answer.quantity = v;
                    widget.onChanged();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small banner explaining that a safety-equipment CONDITION check is
/// shared between the Commercial and Transport forms for the same station
/// visit, so the second department to inspect doesn't have to re-answer
/// from scratch. In this standalone module the data isn't wired to a
/// backend, so this is shown whenever the section has already been
/// answered — swap `alreadyAnsweredElsewhere` for a real cross-department
/// lookup once this is wired into PROMISE's shared inspection session.
class SharedSafetyConditionNotice extends StatelessWidget {
  final bool alreadyAnsweredElsewhere;
  const SharedSafetyConditionNotice({
    super.key,
    required this.alreadyAnsweredElsewhere,
  });

  @override
  Widget build(BuildContext context) {
    if (!alreadyAnsweredElsewhere) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Already recorded by the other department on this visit — shown here read-only to avoid a duplicate check.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only, collapsible header shown at the top of every Traffic
/// inspection form (BRD Generic Requirement #1: "Show all Asset Details in
/// read only on top of each inspection form ... behaves like an
/// accordion"). Defined once, reused by all three forms instead of being
/// rebuilt per screen.
class AssetDetailsAccordion extends StatefulWidget {
  final String stationName;
  final Map<String, String> details;
  const AssetDetailsAccordion({
    super.key,
    required this.stationName,
    required this.details,
  });

  @override
  State<AssetDetailsAccordion> createState() => _AssetDetailsAccordionState();
}

class _AssetDetailsAccordionState extends State<AssetDetailsAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.apartment, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.stationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.details.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact editor for the growable "Point" list on the Transport Station
/// form (BRD: "Ask this for each point on the station").
class PointsListEditor extends StatelessWidget {
  final List<StationPointEntry> points;
  final VoidCallback onChanged;

  const PointsListEditor({
    super.key,
    required this.points,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Point',
      icon: Icons.alt_route,
      subtitle:
          'Add one entry per point on the station and mark whether it is working properly.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...points.asMap().entries.map((entry) {
            return _PointEntryRow(
              point: entry.value,
              index: entry.key,
              onRemove: () {
                points.removeAt(entry.key);
                onChanged();
              },
              onChanged: onChanged,
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              points.add(
                StationPointEntry(label: 'Point ${points.length + 1}'),
              );
              onChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Point'),
          ),
        ],
      ),
    );
  }
}

class _PointEntryRow extends StatefulWidget {
  final StationPointEntry point;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _PointEntryRow({
    required this.point,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_PointEntryRow> createState() => _PointEntryRowState();
}

class _PointEntryRowState extends State<_PointEntryRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.point.label);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PointEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.point.label != _controller.text) {
      _controller.text = widget.point.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Point ${widget.index + 1} name/number',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              controller: _controller,
              onChanged: (v) {
                widget.point.label = v;
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Working'),
            selected: widget.point.workingProperly,
            onSelected: (_) {
              setState(() => widget.point.workingProperly = true);
              widget.onChanged();
            },
            selectedColor: Colors.green.shade100,
          ),
          const SizedBox(width: 4),
          ChoiceChip(
            label: const Text('Not working'),
            selected: !widget.point.workingProperly,
            onSelected: (_) {
              setState(() => widget.point.workingProperly = false);
              widget.onChanged();
            },
            selectedColor: scheme.errorContainer,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

/// Simple Yes/No toggle used for the handful of genuinely single-answer
/// booleans (Lost Property evaluated?, unauthorized vendor present?, etc.)
/// that don't belong in a multi-select checklist.
class YesNoToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const YesNoToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
