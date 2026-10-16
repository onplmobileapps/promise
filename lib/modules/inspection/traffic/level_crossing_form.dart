import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/checklist_widgets.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';

const List<String> kSponsoringAgencyOptions = [
  'District Administration',
  'Local Government',
  'Provincial Government',
  'Highway Department',
];
const List<String> kRoadSurfaceTypeOptions = ['Metal', 'Non-Metal'];
const List<String> kRoadSurfaceSoilingOptions = ['Soiling', 'Non-Soiling'];
const List<String> kCommunicationMechanismOptions = [
  'Phone',
  'Bell',
  'Wireless',
  'Nothing',
];

/// BRD: "2. Forms for Traffic Department with sub department as Transport
/// → 2. Open for Level Crossing".
///
/// The BRD's trailing "Add" button implies a station can have more than
/// one level crossing, so — matching how Station Assets are modelled
/// elsewhere in Footplate — this screen manages a growable LIST of
/// [LevelCrossingRecord]s rather than a single form.
class LevelCrossingListScreen extends StatefulWidget {
  final String stationName;
  final List<LevelCrossingRecord> records;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;

  const LevelCrossingListScreen({
    super.key,
    required this.stationName,
    required this.records,
    required this.onChanged,
    required this.onSubmit,
    required this.onSaveDraft,
  });

  @override
  State<LevelCrossingListScreen> createState() =>
      _LevelCrossingListScreenState();
}

class _LevelCrossingListScreenState extends State<LevelCrossingListScreen> {
  int? _openIndex;

  @override
  void initState() {
    super.initState();
    if (widget.records.isEmpty) {
      widget.records.add(LevelCrossingRecord());
    }
    _openIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Traffic (Transport) — Level Crossing',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'All fields are optional. Everything defaults to Functional — only mark what needs attention.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),

        AssetDetailsAccordion(
          stationName: widget.stationName,
          details: const {'Section': 'Transport', 'Form': 'Level Crossing'},
        ),

        ...widget.records.asMap().entries.map((entry) {
          final i = entry.key;
          final record = entry.value;
          final isOpen = _openIndex == i;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(
                    'Level Crossing ${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    record.jurisdictionMeters.isEmpty
                        ? 'Jurisdiction not set'
                        : '${record.jurisdictionMeters} m jurisdiction',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.records.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() {
                            widget.records.removeAt(i);
                            if (_openIndex == i) _openIndex = null;
                            widget.onChanged();
                          }),
                        ),
                      Icon(isOpen ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                  onTap: () => setState(() => _openIndex = isOpen ? null : i),
                ),
                if (isOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _LevelCrossingRecordForm(
                      record: record,
                      onChanged: widget.onChanged,
                    ),
                  ),
              ],
            ),
          );
        }),

        OutlinedButton.icon(
          onPressed: () => setState(() {
            widget.records.add(LevelCrossingRecord());
            _openIndex = widget.records.length - 1;
            widget.onChanged();
          }),
          icon: const Icon(Icons.add),
          label: const Text('Add Level Crossing'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),

        const SizedBox(height: 16),
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
}

class _LevelCrossingRecordForm extends StatefulWidget {
  final LevelCrossingRecord record;
  final VoidCallback onChanged;
  const _LevelCrossingRecordForm({
    required this.record,
    required this.onChanged,
  });

  @override
  State<_LevelCrossingRecordForm> createState() =>
      _LevelCrossingRecordFormState();
}

class _LevelCrossingRecordFormState extends State<_LevelCrossingRecordForm> {
  late final TextEditingController _jurisdictionController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _jurisdictionController = TextEditingController(
      text: widget.record.jurisdictionMeters,
    );
    _latController = TextEditingController(text: widget.record.latitude);
    _lngController = TextEditingController(text: widget.record.longitude);
  }

  @override
  void dispose() {
    _jurisdictionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_LevelCrossingRecordForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.record.jurisdictionMeters != _jurisdictionController.text) {
      _jurisdictionController.text = widget.record.jurisdictionMeters;
    }
    if (widget.record.latitude != _latController.text) {
      _latController.text = widget.record.latitude;
    }
    if (widget.record.longitude != _lngController.text) {
      _lngController.text = widget.record.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioChipGroup(
          label: 'Sponsoring Agency',
          options: kSponsoringAgencyOptions,
          value: r.sponsoringAgency.isEmpty ? null : r.sponsoringAgency,
          onChanged: (v) => setState(() {
            r.sponsoringAgency = v;
            widget.onChanged();
          }),
          dense: true,
        ),
        RadioChipGroup(
          label: 'Road Surface — Type',
          options: kRoadSurfaceTypeOptions,
          value: r.roadSurfaceType.isEmpty ? null : r.roadSurfaceType,
          onChanged: (v) => setState(() {
            r.roadSurfaceType = v;
            widget.onChanged();
          }),
          dense: true,
        ),
        RadioChipGroup(
          label: 'Road Surface — Soiling',
          options: kRoadSurfaceSoilingOptions,
          value: r.roadSurfaceSoiling.isEmpty ? null : r.roadSurfaceSoiling,
          onChanged: (v) => setState(() {
            r.roadSurfaceSoiling = v;
            widget.onChanged();
          }),
          dense: true,
        ),
        RadioChipGroup(
          label: 'Communication Mechanism',
          options: kCommunicationMechanismOptions,
          value: r.communicationMechanism.isEmpty
              ? null
              : r.communicationMechanism,
          onChanged: (v) => setState(() {
            r.communicationMechanism = v;
            widget.onChanged();
          }),
          dense: true,
        ),
        const Divider(),
        ChecklistGroup(
          title: 'Equipment',
          icon: Icons.build,
          items: kLevelCrossingEquipmentChecklist,
          data: r.equipment,
          positiveLabel: 'Functional',
          negativeLabel: 'Not Functional',
          onChanged: widget.onChanged,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Jurisdiction (Meter)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: _jurisdictionController,
                onChanged: (v) {
                  r.jurisdictionMeters = v;
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                controller: _latController,
                onChanged: (v) {
                  r.latitude = v;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                controller: _lngController,
                onChanged: (v) {
                  r.longitude = v;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: const Icon(Icons.my_location),
              tooltip: 'Capture current GPS coordinates',
              onPressed: () {
                // Wire to the existing LocationTrackingService used elsewhere
                // in Footplate to auto-fill lat/long.
              },
            ),
          ],
        ),
      ],
    );
  }
}
