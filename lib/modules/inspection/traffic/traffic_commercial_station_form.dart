import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/checklist_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

/// BRD: "2. Forms for Traffic Department with sub department as Commercial
/// → 1. Open for Station".
class TrafficCommercialStationForm extends StatefulWidget {
  final String stationName;
  final TrafficCommercialStationData data;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  /// Whether the Transport department has already recorded the shared
  /// safety-equipment condition check during this visit.
  final bool safetyConditionAlreadyRecordedByOtherDept;

  const TrafficCommercialStationForm({
    super.key,
    required this.stationName,
    required this.data,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraft,
    this.safetyConditionAlreadyRecordedByOtherDept = false,
  });

  @override
  State<TrafficCommercialStationForm> createState() =>
      _TrafficCommercialStationFormState();
}

class _TrafficCommercialStationFormState
    extends State<TrafficCommercialStationForm> {
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
  void didUpdateWidget(TrafficCommercialStationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note: In a real app, you might want to sync controller text if data changes externally.
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Traffic (Commercial) — Station',
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
            'Sub Department': 'Commercial',
            'Classification': 'A-Class',
          },
        ),

        ChecklistGroup(
          title: 'Booking Office',
          icon: Icons.confirmation_number,
          items: kBookingOfficeChecklist,
          data: d.bookingOffice,
          positiveLabel: 'Updated',
          negativeLabel: 'Not Updated',
          onChanged: widget.onChanged,
        ),

        ChecklistGroup(
          title: 'Station Statistics (TM-34)',
          icon: Icons.bar_chart,
          items: kStationStatisticsChecklist,
          data: d.stationStatistics,
          positiveLabel: 'Updated',
          negativeLabel: 'Not Updated',
          onChanged: widget.onChanged,
        ),

        ChecklistGroup(
          title: 'Ticketing Data of TCR Office',
          icon: Icons.receipt_long,
          items: kTcrCommercialChecklist,
          data: d.tcrOffice,
          positiveLabel: 'Updated',
          negativeLabel: 'Not Updated',
          onChanged: widget.onChanged,
        ),

        ChecklistGroup(
          title: 'Station Mirror (T.M 35)',
          icon: Icons.receipt,
          items: kStationMirrorChecklist,
          data: d.stationMirror,
          positiveLabel: 'Updated',
          negativeLabel: 'Not Updated',
          onChanged: widget.onChanged,
        ),

        ChecklistGroup(
          title: 'Inward Parcel Office',
          icon: Icons.move_to_inbox,
          items: kInwardParcelChecklist,
          data: d.inwardParcel,
          positiveLabel: 'OK',
          negativeLabel: 'Issue',
          onChanged: widget.onChanged,
        ),
        SectionCard(
          title: 'Undelivered Parcels',
          icon: Icons.inventory_2,
          child: YesNoToggle(
            label: 'Undelivered Parcels present?',
            value: d.undeliveredParcels,
            onChanged: (v) => setState(() {
              d.undeliveredParcels = v;
              widget.onChanged();
            }),
          ),
        ),

        ChecklistGroup(
          title: 'Outward Parcel Office',
          icon: Icons.outbox,
          items: kOutwardParcelChecklist,
          data: d.outwardParcel,
          positiveLabel: 'Appropriate',
          negativeLabel: 'In-Appropriate',
          onChanged: widget.onChanged,
        ),

        SectionCard(
          title: 'Lost Property Office (LPO)',
          icon: Icons.inventory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YesNoToggle(
                label: 'Weighment accuracy available?',
                value: d.lpoWeighmentAvailable,
                onChanged: (v) => setState(() {
                  d.lpoWeighmentAvailable = v;
                  widget.onChanged();
                }),
              ),
              if (d.lpoWeighmentAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Number',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: _getController(
                      'lpoWeighmentNumber',
                      d.lpoWeighmentNumber,
                    ),
                    onChanged: (v) {
                      d.lpoWeighmentNumber = v;
                      widget.onChanged();
                    },
                  ),
                ),
              YesNoToggle(
                label: 'Items duly evaluated by ICG and CMI?',
                value: d.lpoItemsEvaluated,
                onChanged: (v) => setState(() {
                  d.lpoItemsEvaluated = v;
                  widget.onChanged();
                }),
              ),
              if (d.lpoItemsEvaluated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: _getController('lpoAmount', d.lpoAmount),
                    onChanged: (v) {
                      d.lpoAmount = v;
                      widget.onChanged();
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Date of Evaluation',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: _getController(
                      'lpoDateOfEvaluation',
                      d.lpoDateOfEvaluation,
                    ),
                    onChanged: (v) {
                      d.lpoDateOfEvaluation = v;
                      widget.onChanged();
                    },
                  ),
                ),
              const Divider(),
              Text(
                'Last Auction of LPO Office',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      controller: _getController(
                        'lpoLastAuctionAmount',
                        d.lpoLastAuctionAmount,
                      ),
                      onChanged: (v) {
                        d.lpoLastAuctionAmount = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      controller: _getController(
                        'lpoLastAuctionDate',
                        d.lpoLastAuctionDate,
                      ),
                      onChanged: (v) {
                        d.lpoLastAuctionDate = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SectionCard(
          title: 'Goods Office — Weighment Machine',
          icon: Icons.scale,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  controller: _getController(
                    'weighmentDueDate',
                    d.weighmentDueDate,
                  ),
                  onChanged: (v) {
                    d.weighmentDueDate = v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Next Date',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  controller: _getController(
                    'weighmentNextDate',
                    d.weighmentNextDate,
                  ),
                  onChanged: (v) {
                    d.weighmentNextDate = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
        ),
        ChecklistGroup(
          title: 'Goods Office',
          icon: Icons.local_shipping,
          items: kGoodsOfficeChecklist,
          data: d.goodsOffice,
          positiveLabel: 'OK',
          negativeLabel: 'Issue',
          onChanged: widget.onChanged,
        ),

        SectionCard(
          title: 'Vending Shops / Stalls',
          icon: Icons.storefront,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...kVendingStallsChecklist.map(
                (item) => _inlineChecklistRow(item, d.vendingStalls),
              ),
              const Divider(),
              YesNoToggle(
                label: 'Selling of unauthorized items?',
                value: d.sellingUnauthorizedItems,
                onChanged: (v) => setState(() {
                  d.sellingUnauthorizedItems = v;
                  widget.onChanged();
                }),
              ),
              YesNoToggle(
                label: 'Presence of unauthorized vendor at station, if any?',
                value: d.unauthorizedVendorPresent,
                onChanged: (v) => setState(() {
                  d.unauthorizedVendorPresent = v;
                  widget.onChanged();
                }),
              ),
            ],
          ),
        ),

        ChecklistGroup(
          title: "Station Master's Office",
          icon: Icons.meeting_room,
          items: kStationMastersOfficeChecklist,
          data: d.stationMastersOffice,
          positiveLabel: 'OK',
          negativeLabel: 'Issue',
          onChanged: widget.onChanged,
        ),

        ChecklistGroup(
          title: 'General Cleanliness of the Station',
          icon: Icons.cleaning_services,
          items: kGeneralCleanlinessChecklist,
          data: d.generalCleanliness,
          positiveLabel: 'Satisfactory',
          negativeLabel: 'Not Satisfactory',
          onChanged: widget.onChanged,
        ),

        SectionCard(
          title: 'Safety Equipment — Condition',
          icon: Icons.health_and_safety,
          subtitle:
              'Shown only if the station asset record marks these as available. Shared with the Transport department for this visit.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SharedSafetyConditionNotice(
                alreadyAnsweredElsewhere:
                    widget.safetyConditionAlreadyRecordedByOtherDept,
              ),
              ...kSafetyEquipmentConditionChecklist.map(
                (item) => _inlineChecklistRow(
                  item,
                  d.safetyEquipmentCondition,
                  positiveLabel: 'Satisfactory',
                  negativeLabel: 'Not Satisfactory',
                  enabled: !widget.safetyConditionAlreadyRecordedByOtherDept,
                ),
              ),
            ],
          ),
        ),

        ChecklistGroup(
          title: 'Train(s) Present/Arrived at Station',
          icon: Icons.train,
          items: kTrainPresentChecklist,
          data: d.trainsPresent,
          positiveLabel: 'Satisfactory',
          negativeLabel: 'Not Satisfactory',
          onChanged: widget.onChanged,
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

  Widget _inlineChecklistRow(
    ChecklistItem item,
    ChecklistFormData data, {
    String positiveLabel = 'OK',
    String negativeLabel = 'Issue',
    bool enabled = true,
  }) {
    final answer = data.of(item.key);
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
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
                Expanded(child: Text(item.label)),
                StatusPill(
                  text: answer.checked ? positiveLabel : negativeLabel,
                  color: answer.checked ? Colors.green.shade600 : scheme.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
