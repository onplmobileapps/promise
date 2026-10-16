import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';

class PunctualityStep extends StatefulWidget {
  final List<PunctualityEntry> punctuality;
  final List<OPEntry> ops;
  final VoidCallback onChanged;

  const PunctualityStep({
    super.key,
    required this.punctuality,
    required this.ops,
    required this.onChanged,
  });

  @override
  State<PunctualityStep> createState() => _PunctualityStepState();
}

class _PunctualityStepState extends State<PunctualityStep> {
  String _fmtDiff(Duration? d) {
    if (d == null) return '—';
    final neg = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes % 60;
    final s = abs.inSeconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    parts.add('${s}s');
    return (neg ? '-' : '+') + parts.join(' ');
  }

  Future<void> _pickTime(PunctualityEntry e, String field) async {
    final now = DateTime.now();
    final initial = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final dt = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      switch (field) {
        case 'schedArr':
          e.scheduleArrival = dt;
          break;
        case 'actArr':
          e.actualArrival = dt;
          break;
        case 'schedDep':
          e.scheduleDeparture = dt;
          break;
        case 'actDep':
          e.actualDeparture = dt;
          break;
      }
    });
    widget.onChanged();
  }

  void _addStation() {
    setState(
      () => widget.punctuality.add(PunctualityEntry(station: kStations.first)),
    );
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Punctuality & Caution Orders',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Punctuality of Trains',
          icon: Icons.timer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.punctuality.map(
                (e) => _PunctualityCard(
                  entry: e,
                  fmtDiff: _fmtDiff,
                  onPickTime: (f) => _pickTime(e, f),
                  onStationChanged: (v) => setState(() {
                    e.station = v;
                    widget.onChanged();
                  }),
                  onRemarksChanged: (v) {
                    e.remarks = v;
                    widget.onChanged();
                  },
                  onDelete: () => setState(() {
                    widget.punctuality.remove(e);
                    widget.onChanged();
                  }),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addStation,
                icon: const Icon(Icons.add),
                label: const Text('Add Station Record'),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Caution Orders / OPs',
          icon: Icons.report_gmailerrorred,
          subtitle:
              'Select every OP received and note the decimal it applies to.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCautionOrders.map((op) {
                  final selected = widget.ops.any((o) => o.opCode == op);
                  return FilterChip(
                    label: Text(op),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        widget.ops.add(OPEntry(opCode: op));
                      } else {
                        widget.ops.removeWhere((o) => o.opCode == op);
                      }
                      widget.onChanged();
                    }),
                  );
                }).toList(),
              ),
              if (widget.ops.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                ...widget.ops.map(
                  (o) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            o.opCode,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            key: ValueKey(o.opCode),
                            initialValue: o.decimal,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                            decoration: InputDecoration(
                              hintText: 'Decimal (e.g. 425/0.987)',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (v) {
                              o.decimal = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _PunctualityCard extends StatelessWidget {
  final PunctualityEntry entry;
  final String Function(Duration?) fmtDiff;
  final void Function(String field) onPickTime;
  final ValueChanged<String> onStationChanged;
  final ValueChanged<String> onRemarksChanged;
  final VoidCallback onDelete;

  const _PunctualityCard({
    required this.entry,
    required this.fmtDiff,
    required this.onPickTime,
    required this.onStationChanged,
    required this.onRemarksChanged,
    required this.onDelete,
  });

  Widget _timeChip(
    BuildContext context,
    String label,
    DateTime? value,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              value == null
                  ? '--:--'
                  : TimeOfDay.fromDateTime(value).format(context),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: entry.station,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelText: 'Station',
                  ),
                  items: kStations
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onStationChanged(v);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _timeChip(
                context,
                'Sched. Arrival',
                entry.scheduleArrival,
                () => onPickTime('schedArr'),
              ),
              const SizedBox(width: 8),
              _timeChip(
                context,
                'Actual Arrival',
                entry.actualArrival,
                () => onPickTime('actArr'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _timeChip(
                context,
                'Sched. Departure',
                entry.scheduleDeparture,
                () => onPickTime('schedDep'),
              ),
              const SizedBox(width: 8),
              _timeChip(
                context,
                'Actual Departure',
                entry.actualDeparture,
                () => onPickTime('actDep'),
              ),
            ],
          ),
          if (entry.arrivalDiff != null || entry.departureDiff != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                if (entry.arrivalDiff != null)
                  StatusPill(
                    text: 'Arrival ${fmtDiff(entry.arrivalDiff)}',
                    color: entry.arrivalDiff!.inSeconds == 0
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                  ),
                if (entry.departureDiff != null)
                  StatusPill(
                    text: 'Departure ${fmtDiff(entry.departureDiff)}',
                    color: entry.departureDiff!.inSeconds == 0
                        ? Colors.green.shade600
                        : Colors.orange.shade700,
                  ),
              ],
            ),
          ],
          if (entry.hasDifference) ...[
            const SizedBox(height: 10),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Remarks (required — time differs from schedule)',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
              onChanged: onRemarksChanged,
            ),
          ],
        ],
      ),
    );
  }
}
