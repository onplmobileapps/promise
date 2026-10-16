import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/inspection/civil/models/civil_field_spec.dart';
import 'package:railway_hrms/modules/inspection/civil/services/civil_inspection_draft_service.dart';
import 'package:railway_hrms/modules/inspection/civil/widgets/civil_form_widgets.dart';
import 'package:railway_hrms/modules/inspection/civil/widgets/dynamic_civil_form.dart';

/// A single Rail or Sleeper on the current Pole/Decimal.
class _TrackElement {
  final int number;
  String condition;
  bool selected;
  _TrackElement(this.number, this.condition) : selected = false;
}

const _railConditions = [
  'Serviceable',
  'Ultrasonic Flaw Detective (USFD)',
  'Wheel Burnt',
  'Excessive Wear',
  'End battered',
  'Hogged',
  'Worn Out',
];
const _sleeperConditions = ['Un-Service', 'Serviceable'];

/// The "During Inspection: Exists/Removed -> Same/New -> [details]"
/// blocks that repeat for Trespassing, Electric Crossing, Encroachments,
/// and Sui Gas Crossing (BRD pages 23-25).
final List<CivilFieldSpec> _trespassingFields = [
  CivilFieldSpec.radio(
    'trespassingPresent',
    'Un-Authorized Trespassing',
    const ['Yes', 'No'],
  ),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.dropdown('trespassingType', 'Type', const [
        'Shop',
        'Path',
        'Structure',
      ]),
      CivilFieldSpec.dropdown('trespassingRemedy', 'Remedy', const [
        'FIR',
        'Notice',
        'Removal',
      ]),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'trespassing',
        newFields: [
          CivilFieldSpec.dropdown('trespassingNewType', 'Type', const [
            'Shop',
            'Path',
            'Structure',
          ]),
          CivilFieldSpec.dropdown('trespassingNewRemedy', 'Remedy', const [
            'FIR',
            'Notice',
            'Removal',
          ]),
        ],
      ),
    ],
    conditionKey: 'trespassingPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _electricCrossingFields = [
  CivilFieldSpec.radio('electricCrossingPresent', 'Electric Crossing', const [
    'Yes',
    'No',
  ]),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number('electricVoltage', 'Voltage'),
      CivilFieldSpec.radio('electricPassingFrom', 'Passing From', const [
        'Over Head',
        'Under Ground',
      ]),
      CivilFieldSpec.number('electricDiameter', 'Diameter', unit: 'Inches'),
      CivilFieldSpec.date('electricCrossingDate', 'Crossing Date'),
      CivilFieldSpec.radio('electricNocApproved', 'NOC Approved', const [
        'Yes',
        'No',
      ]),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'electricCrossing',
        newFields: [
          CivilFieldSpec.number('electricNewVoltage', 'Voltage'),
          CivilFieldSpec.radio('electricNewPassingFrom', 'Passing From', const [
            'Over Head',
            'Under Ground',
          ]),
          CivilFieldSpec.number(
            'electricNewDiameter',
            'Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.date('electricNewCrossingDate', 'Crossing Date'),
          CivilFieldSpec.radio('electricNewNocApproved', 'NOC Approved', const [
            'Yes',
            'No',
          ]),
        ],
      ),
    ],
    conditionKey: 'electricCrossingPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _encroachmentFields = [
  CivilFieldSpec.radio('encroachmentPresent', 'Encroachments', const [
    'Yes',
    'No',
  ]),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number(
        'encroachLeftFeet',
        'Left Side Encroachment',
        unit: 'Feet',
      ),
      CivilFieldSpec.number(
        'encroachRightFeet',
        'Right Side Encroachment',
        unit: 'Feet',
      ),
      CivilFieldSpec.text('encroacherName', 'Name of Encroacher'),
      CivilFieldSpec.dropdown('encroachType', 'Type of Encroachment', const [
        'Brackets',
        'Shop',
        'Structure',
        'Other',
      ]),
      CivilFieldSpec.number('encroachSinceYear', 'Encroachment Since (Year)'),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'encroachment',
        newFields: [
          CivilFieldSpec.number(
            'encroachNewLeftFeet',
            'Left Side Encroachment',
            unit: 'Feet',
          ),
          CivilFieldSpec.number(
            'encroachNewRightFeet',
            'Right Side Encroachment',
            unit: 'Feet',
          ),
          CivilFieldSpec.text('encroachNewName', 'Name of Encroacher'),
          CivilFieldSpec.dropdown(
            'encroachNewType',
            'Type of Encroachment',
            const ['Brackets', 'Shop', 'Structure', 'Other'],
          ),
          CivilFieldSpec.number(
            'encroachNewSinceYear',
            'Encroachment Since (Year)',
          ),
        ],
      ),
    ],
    conditionKey: 'encroachmentPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _suiGasFields = [
  CivilFieldSpec.radio(
    'suiGasPresent',
    'Sui Gas Crossing on this Decimal',
    const ['Yes', 'No'],
  ),
  CivilFieldSpec.group(
    'Existing Record',
    [
      CivilFieldSpec.number(
        'suiGasPipeDiameter',
        'Pipe Diameter',
        unit: 'Inches',
      ),
      CivilFieldSpec.number(
        'suiGasCasingDiameter',
        'Casing Diameter',
        unit: 'Inches',
      ),
      CivilFieldSpec.text('suiGasApprovalNo', 'HQ / FGIR Approval No'),
      CivilFieldSpec.radio(
        'suiGasIndicationBoard',
        'Indication Board of Sui Gas Xing',
        const ['Provided', 'Not Provided'],
      ),
      ...CivilFieldSpec.duringInspectionBlock(
        prefix: 'suiGas',
        newFields: [
          CivilFieldSpec.number(
            'suiGasNewPipeDiameter',
            'Pipe Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.number(
            'suiGasNewCasingDiameter',
            'Casing Diameter',
            unit: 'Inches',
          ),
          CivilFieldSpec.text('suiGasNewApprovalNo', 'HQ / FGIR Approval No'),
          CivilFieldSpec.radio(
            'suiGasNewIndicationBoard',
            'Indication Board of Sui Gas Xing',
            const ['Provided', 'Not Provided'],
          ),
        ],
      ),
    ],
    conditionKey: 'suiGasPresent',
    conditionValue: 'Yes',
  ),
];

final List<CivilFieldSpec> _embankmentAndBoundaryFields = [
  _civilSectionAsGroup('Embankment', [
    CivilFieldSpec.number(
      'embankmentWidthFeet',
      'Width Embankment',
      unit: 'Feet',
    ),
    CivilFieldSpec.number(
      'embankmentWidthInches',
      'Width Embankment',
      unit: 'Inches',
    ),
    CivilFieldSpec.number(
      'avgHeightNSL',
      'Average height of bank w.r.t NSL (Natural Surface Level)',
    ),
    CivilFieldSpec.number(
      'actualWidthEmbankment',
      'Actual Width of Embankment',
    ),
  ]),
  _civilSectionAsGroup('Land Boundary', [
    CivilFieldSpec.number('landBoundaryLeftFeet', 'Left Side', unit: 'Feet'),
    CivilFieldSpec.number('landBoundaryRightFeet', 'Right Side', unit: 'Feet'),
  ]),
];

/// Small helper so a labelled block of plain fields reads as one visual
/// group without pulling in the full conditional machinery.
CivilFieldSpec _civilSectionAsGroup(
  String label,
  List<CivilFieldSpec> fields,
) => CivilFieldSpec.group(label, fields);

class SleepersRailsSidingsScreen extends StatefulWidget {
  const SleepersRailsSidingsScreen({super.key});

  @override
  State<SleepersRailsSidingsScreen> createState() =>
      _SleepersRailsSidingsScreenState();
}

class _SleepersRailsSidingsScreenState
    extends State<SleepersRailsSidingsScreen> {
  final _kmFromCtrl = TextEditingController(text: '425');
  final _kmToCtrl = TextEditingController(text: '426');
  bool _dataLoaded = false;
  bool _inspectionRunning = false;
  int _currentPole = 11;
  double _currentDecimal = 0.987;

  final Map<String, dynamic> _answers = {};
  final DateTime _startedAt = DateTime.now();

  List<_TrackElement> _rails = [];
  List<_TrackElement> _sleepers = [];

  void _loadData() {
    setState(() {
      _dataLoaded = true;
      _rails = List.generate(
        19,
        (i) => _TrackElement(i + 1, _railConditions[i % 2 == 0 ? 0 : 2]),
      );
      _sleepers = List.generate(
        78,
        (i) => _TrackElement(i + 1, i % 3 == 0 ? 'Un-Service' : 'Serviceable'),
      );
    });
  }

  void _goToNextPoleDecimal() {
    setState(() {
      _currentPole += 1;
      _currentDecimal = (_currentDecimal + 0.271) % 1;
      _loadData();
    });
  }

  Future<void> _openInspectDialog(
    _TrackElement el,
    List<String> conditions,
    String kind,
  ) async {
    String selected = el.condition;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$kind #${el.number} — Inspection'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((c) {
              return ChoiceChip(
                label: Text(c),
                selected: selected == c,
                onSelected: (_) => setDialogState(() => selected = c),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() => el.condition = result);
    }
  }

  void _toggleSelect(_TrackElement el) {
    setState(() => el.selected = !el.selected);
  }

  Future<void> _saveDraft() async {
    await CivilInspectionDraftService.saveDraft(
      formId: 'civil_track_sleepers_rails_private_sidings',
      answers: _answers,
      startedAt: _startedAt,
      department: 'Civil',
      subDepartment: 'Track',
      asset: 'Sleepers, Rails, Private Sidings',
    );
    if (mounted) {
      showAppMessage(context, 'Draft saved', tone: AppDialogTone.success);
    }
  }

  Future<void> _submit() async {
    await CivilInspectionDraftService.submit(
      formId: 'civil_track_sleepers_rails_private_sidings',
      answers: _answers,
      startedAt: _startedAt,
      department: 'Civil',
      subDepartment: 'Track',
      asset: 'Sleepers, Rails, Private Sidings',
    );
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Inspection Submitted'),
        content: const Text(
          'Sleepers, Rails, Private Sidings inspection has been recorded.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleepers, Rails, Private Sidings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save Draft',
            onPressed: _saveDraft,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CivilAssetDetailsAccordion(
              department: 'Civil',
              subDepartment: 'Track',
              asset: 'Sleepers, Rails, Private Sidings',
            ),
            const SizedBox(height: 16),
            _buildKmSelector(),
            const SizedBox(height: 16),
            if (_dataLoaded) ...[
              _buildPoleHeader(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildElementColumn(
                      'Rails',
                      _rails,
                      _railConditions,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildElementColumn(
                      'Sleepers',
                      _sleepers,
                      _sleeperConditions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _goToNextPoleDecimal,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Pole / Decimal'),
                ),
              ),
              const Divider(height: 32),
              DynamicCivilForm(
                fields: _embankmentAndBoundaryFields,
                answers: _answers,
                onChanged: () {},
              ),
              const Divider(height: 32),
              const Text(
                'Assets on this stretch',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: 8),
              DynamicCivilForm(
                fields: _trespassingFields,
                answers: _answers,
                onChanged: () {},
              ),
              const Divider(height: 24),
              DynamicCivilForm(
                fields: _electricCrossingFields,
                answers: _answers,
                onChanged: () {},
              ),
              const Divider(height: 24),
              DynamicCivilForm(
                fields: _encroachmentFields,
                answers: _answers,
                onChanged: () {},
              ),
              const Divider(height: 24),
              DynamicCivilForm(
                fields: _suiGasFields,
                answers: _answers,
                onChanged: () {},
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.send),
                      label: const Text('Submit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Select a KM range and tap "Load Data" to begin.',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select KM Range',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Text(
              'Loads all track data for offline inspection (per generic requirement: online load, offline save).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kmFromCtrl,
                    decoration: const InputDecoration(
                      labelText: 'From',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _kmToCtrl,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _loadData,
                  child: const Text('Load Data'),
                ),
              ],
            ),
            if (_dataLoaded) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Toggle Inspection: '),
                  Switch(
                    value: _inspectionRunning,
                    onChanged: (v) => setState(() => _inspectionRunning = v),
                  ),
                  Text(_inspectionRunning ? 'Running' : 'Stopped'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPoleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'KM: ${_kmFromCtrl.text}, Pole: $_currentPole, Decimal: ${_currentDecimal.toStringAsFixed(3)}   '
        '·   Rails: ${_rails.length}, Sleepers: ${_sleepers.length}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildElementColumn(
    String title,
    List<_TrackElement> items,
    List<String> conditions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Scrollbar(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final el = items[i];
                final isBad = el.condition != 'Serviceable';
                return ListTile(
                  dense: true,
                  tileColor: el.selected
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : null,
                  leading: Text(
                    '${el.number}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  title: Text(
                    el.condition,
                    style: TextStyle(
                      fontSize: 12,
                      color: isBad
                          ? Colors.orange.shade800
                          : Colors.green.shade700,
                    ),
                  ),
                  onTap: () => _toggleSelect(el),
                  onLongPress: () => _openInspectDialog(
                    el,
                    conditions,
                    title.substring(0, title.length - 1),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openInspectDialog(
                      el,
                      conditions,
                      title.substring(0, title.length - 1),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to select · long-press or ✎ to open inspection',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
