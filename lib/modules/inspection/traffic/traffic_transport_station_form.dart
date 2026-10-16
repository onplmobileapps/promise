import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/checklist_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

/// BRD: "2. Forms for Traffic Department with sub department as Transport
/// → 1. Open for Station".
class TrafficTransportStationForm extends StatefulWidget {
  final String stationName;
  final TrafficTransportStationData data;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;
  final bool safetyConditionAlreadyRecordedByOtherDept;

  const TrafficTransportStationForm({
    super.key,
    required this.stationName,
    required this.data,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraft,
    this.safetyConditionAlreadyRecordedByOtherDept = false,
  });

  @override
  State<TrafficTransportStationForm> createState() =>
      _TrafficTransportStationFormState();
}

class _TrafficTransportStationFormState
    extends State<TrafficTransportStationForm> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getController(String key, String initialValue) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: initialValue),
    );
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(TrafficTransportStationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Traffic (Transport) — Station',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'All fields are optional. Everything defaults to OK — only mark what needs attention.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        AssetDetailsAccordion(
          stationName: widget.stationName,
          details: const {
            'Station Code': 'LHR',
            'Sub Department': 'Transport',
            'Classification': 'A-Class',
          },
        ),

        ChecklistGroup(
          title: 'Station Journal — Registers & Books',
          icon: Icons.menu_book,
          items: kRegisterBooksChecklist,
          data: d.stationJournal,
          positiveLabel: 'Updated',
          negativeLabel: 'Not Updated',
          onChanged: widget.onChanged,
          subtitle: 'Staff Present is recorded separately below.',
        ),
        SectionCard(
          title: 'Staff Present',
          icon: Icons.badge,
          child: YesNoToggle(
            label: 'Staff Present',
            value: d.stationJournal.of('staff_present').checked,
            onChanged: (v) => setState(() {
              d.stationJournal.of('staff_present').checked = v;
              widget.onChanged();
            }),
          ),
        ),

        SectionCard(
          title: 'Equipment / Systems',
          icon: Icons.settings_input_component,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(
                'Slot frame',
                d.stationJournal,
                'slot_frame',
                'Working',
                'Not working',
              ),
              _row(
                'S.M control',
                d.stationJournal,
                'sm_control',
                'Functional',
                'Non-functional',
              ),
              _row(
                'Communication',
                d.stationJournal,
                'communication',
                'Functional',
                'Non-functional',
              ),
              _row(
                'Magneto phone with gate',
                d.stationJournal,
                'magneto_phone',
                'Functional',
                'Non-functional',
              ),
              _row(
                'Block Instruments',
                d.stationJournal,
                'block_instruments',
                'Working',
                'Not working',
              ),
              _row(
                'Neal ball token',
                d.stationJournal,
                'neal_ball_token',
                'Balanced',
                'Un-balanced',
              ),
            ],
          ),
        ),

        ChecklistGroup(
          title: 'Ticketing Data of TCR Office',
          icon: Icons.receipt_long,
          items: kTcrTransportBooksChecklist,
          data: d.tcrBooks,
          positiveLabel: 'Available',
          negativeLabel: 'Not Available',
          onChanged: widget.onChanged,
        ),
        SectionCard(
          title: 'Operating Document',
          icon: Icons.description,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YesNoToggle(
                label: 'Operating Document issued?',
                value: d.operatingDocumentIssued,
                onChanged: (v) => setState(() {
                  d.operatingDocumentIssued = v;
                  widget.onChanged();
                }),
              ),
              if (d.operatingDocumentIssued)
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Total Issued',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: _getController(
                    'operatingDocumentTotalIssued',
                    d.operatingDocumentTotalIssued,
                  ),
                  onChanged: (v) {
                    d.operatingDocumentTotalIssued = v;
                    widget.onChanged();
                  },
                ),
            ],
          ),
        ),

        SectionCard(
          title: 'Caution Order',
          icon: Icons.warning_amber,
          subtitle:
              'Tick each OP that has been issued and record the total issued.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...kCautionOrdersChecklist.map(
                (item) => _CautionOrderRow(
                  item: item,
                  answer: d.cautionOrders.of(item.key, defaultChecked: false),
                  onChanged: widget.onChanged,
                ),
              ),
              ..._customCautionOrders(d).map(
                (item) => _CautionOrderRow(
                  item: item,
                  answer: d.cautionOrders.of(item.key, defaultChecked: false),
                  onChanged: widget.onChanged,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _getController('customOpCode', ''),
                      decoration: const InputDecoration(
                        labelText: 'Add another OP code',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final ctrl = _getController('customOpCode', '');
                      final code = ctrl.text.trim();
                      if (code.isEmpty) return;
                      setState(() {
                        d.cautionOrders.of(
                          code,
                          defaultChecked: false,
                        ); // registers the key
                        ctrl.clear();
                      });
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Staff Equipment — Condition',
          icon: Icons.health_and_safety,
          subtitle:
              'Shown only if the station asset record marks these as available. Shared with the Commercial department for this visit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SharedSafetyConditionNotice(
                alreadyAnsweredElsewhere:
                    widget.safetyConditionAlreadyRecordedByOtherDept,
              ),
              ...kSafetyEquipmentConditionChecklist.map(
                (item) => Opacity(
                  opacity: widget.safetyConditionAlreadyRecordedByOtherDept
                      ? 0.5
                      : 1,
                  child: IgnorePointer(
                    ignoring: widget.safetyConditionAlreadyRecordedByOtherDept,
                    child: _row(
                      item.label,
                      d.staffEquipmentCondition,
                      item.key,
                      'Satisfactory',
                      'Not Satisfactory',
                    ),
                  ),
                ),
              ),
              const Divider(),
              _row(
                'Fire bucket',
                d.staffEquipmentCondition,
                'fire_bucket_condition',
                'Satisfactory',
                'Not Satisfactory',
              ),
            ],
          ),
        ),

        PointsListEditor(points: d.points, onChanged: widget.onChanged),

        SectionCard(
          title: 'Siding',
          icon: Icons.alt_route,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YesNoToggle(
                label: 'Damaged Vehicle For Mughalpura (DVM) Stock present?',
                value: d.dvmStockPresent,
                onChanged: (v) => setState(() {
                  d.dvmStockPresent = v;
                  widget.onChanged();
                }),
              ),
              YesNoToggle(
                label: 'Fit stock present?',
                value: d.fitStockPresent,
                onChanged: (v) => setState(() {
                  d.fitStockPresent = v;
                  widget.onChanged();
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Platform level',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Upper', label: Text('Upper')),
                        ButtonSegment(value: 'Lower', label: Text('Lower')),
                      ],
                      selected: {d.platformLevel},
                      onSelectionChanged: (s) => setState(() {
                        d.platformLevel = s.first;
                        widget.onChanged();
                      }),
                    ),
                  ],
                ),
              ),
              YesNoToggle(
                label: 'Communication with staff?',
                value: d.communicationWithStaff,
                onChanged: (v) => setState(() {
                  d.communicationWithStaff = v;
                  widget.onChanged();
                }),
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Remarks',
          icon: Icons.notes,
          child: TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Final remarks (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            controller: _getController('finalRemarks', d.finalRemarks),
            onChanged: (v) {
              d.finalRemarks = v;
              widget.onChanged();
            },
          ),
        ),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onSaveDraft,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save as draft'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: widget.onSubmit,
          icon: const Icon(Icons.send),
          label: const Text('Submit Inspection'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  /// Any custom OP codes the inspector has added at runtime beyond the
  /// standard list — tracked implicitly via keys already present in
  /// `cautionOrders.answers` that aren't part of the standard config.
  Iterable<ChecklistItem> _customCautionOrders(TrafficTransportStationData d) {
    final standardKeys = kCautionOrdersChecklist.map((e) => e.key).toSet();
    return d.cautionOrders.answers.keys
        .where((k) => !standardKeys.contains(k))
        .map(
          (k) => ChecklistItem(
            key: k,
            label: k,
            hasQuantity: true,
            quantityLabel: 'Total Issued',
          ),
        );
  }

  Widget _row(
    String label,
    ChecklistFormData data,
    String key,
    String positive,
    String negative,
  ) {
    final answer = data.of(key);
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() {
        answer.checked = !answer.checked;
        widget.onChanged();
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: answer.checked,
              onChanged: (v) => setState(() {
                answer.checked = v ?? true;
                widget.onChanged();
              }),
            ),
            Expanded(child: Text(label)),
            StatusPill(
              text: answer.checked ? positive : negative,
              color: answer.checked ? Colors.green.shade600 : scheme.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _CautionOrderRow extends StatefulWidget {
  final ChecklistItem item;
  final ChecklistAnswer answer;
  final VoidCallback onChanged;
  const _CautionOrderRow({
    required this.item,
    required this.answer,
    required this.onChanged,
  });

  @override
  State<_CautionOrderRow> createState() => _CautionOrderRowState();
}

class _CautionOrderRowState extends State<_CautionOrderRow> {
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
  void didUpdateWidget(_CautionOrderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.answer.quantity != _controller.text) {
      _controller.text = widget.answer.quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: widget.answer.checked,
            onChanged: (v) => setState(() {
              widget.answer.checked = v ?? false;
              widget.onChanged();
            }),
          ),
          Expanded(
            flex: 2,
            child: Text(
              widget.item.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (widget.answer.checked)
            Expanded(
              flex: 3,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Total Issued',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: _controller,
                onChanged: (v) {
                  widget.answer.quantity = v;
                  widget.onChanged();
                },
              ),
            )
          else
            Expanded(
              flex: 3,
              child: Text(
                'Not Issued',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
