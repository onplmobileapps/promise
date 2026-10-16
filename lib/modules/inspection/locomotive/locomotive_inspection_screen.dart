import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

class LocomotiveInspectionScreen extends StatefulWidget {
  const LocomotiveInspectionScreen({super.key});
  @override
  State<LocomotiveInspectionScreen> createState() =>
      _LocomotiveInspectionScreenState();
}

class _LocomotiveInspectionScreenState
    extends State<LocomotiveInspectionScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Header Controllers
  final _shedController = TextEditingController();
  final _classController = TextEditingController();
  final _officerController = TextEditingController();
  final _locoNumController = TextEditingController();
  DateTime? _inspectionDate;

  // Form State Storage Map
  final Map<String, dynamic> _formData = {};

  @override
  void dispose() {
    _shedController.dispose();
    _classController.dispose();
    _officerController.dispose();
    _locoNumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _getSteps();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCOMOTIVE INSPECTION (GEU-40)'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Custom Horizontally Scrollable Header with Step Numbers
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: List.generate(steps.length, (index) {
                  final isActive = index <= _currentStep;
                  final isCurrent = index == _currentStep;

                  return InkWell(
                    onTap: () => setState(() => _currentStep = index),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          // Step Circle Number Indicator
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : isActive
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Step Title
                          Text(
                            (steps[index].title as Text).data ?? '',
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),

                          // Step Divider Line
                          if (index < steps.length - 1) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 24,
                              child: Divider(
                                color: isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Divider(height: 1),

            // Active Step Content View
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  steps[_currentStep].content,

                  // Controls Section
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 40.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_currentStep < steps.length - 1) {
                                setState(() => _currentStep++);
                              } else {
                                _submitForm();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: Icon(
                              _currentStep == steps.length - 1
                                  ? Icons.save_outlined
                                  : Icons.arrow_forward,
                            ),
                            label: Text(
                              _currentStep == steps.length - 1
                                  ? 'SUBMIT REPORT'
                                  : 'NEXT STEP',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                            ),
                            child: const Text('BACK'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Header & General Info'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
        content: _buildHeaderStep(),
      ),
      Step(
        title: const Text('Driver Cab & Battery'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            _buildSectionHeader('DRIVER CAB'),
            _buildInspectionRow('Driver Cab Area', ['Clean', 'Dirty']),
            _buildInspectionRow('Driver/Ass Driver Seat', [
              'Comfortable',
              'Not Comfortable',
            ]),
            _buildInspectionRow('Display Screen', ['Working', 'Not Working']),
            _buildMeasurementRow('Fuel Oil Pressure', '600-700 KPA', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildMeasurementRow('Lube Oil Pressure', '150-240 KPA', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildMeasurementRow('Booster Pressure', '80-110 KPA', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Vigilance Device', ['Active', 'Inactive']),
            _buildInspectionRow('Wheel Slip', ['Working', 'Not Working']),
            _buildInspectionRow('Ground Relay', ['Active', 'Inactive']),
            _buildInspectionRow('Head Lights', ['Working', 'Not Working']),
            _buildInspectionRow('Buffer Light', ['Working', 'Not Working']),
            _buildInspectionRow('Horn', ['Working', 'Not Working']),
            _buildInspectionRow('Wipers', ['Working', 'Not Working']),
            _buildMeasurementRow('Independent Brake', '4.2 Bars', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildMeasurementRow('Proportional Brake', '4.2 Bars', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildMeasurementRow('MAR Pressure', '8.3 - 9.8 Bars', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildDateField('Fire Extinguisher Expiry (DCP Valid 6 Months)'),
            _buildInspectionRow('Hand Brake', ['Working', 'Not Working']),
            const SizedBox(height: 16),
            _buildSectionHeader('BATTERY'),
            _buildInspectionRow('Terminal Leads', ['Tight', 'Loose']),
            _buildInspectionRow('Lead Connection', ['Tight', 'Loose']),
            _buildMeasurementRow(
              'Cell Voltages (8 cells, 2V each)',
              'Working/Not Working',
              ['Satisfactory', 'Unsatisfactory'],
            ),
            _buildInspectionRow('Crate Condition', ['Good', 'Fair', 'Damaged']),
          ],
        ),
      ),
      Step(
        title: const Text('Engine & Compressor Room'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            _buildSectionHeader('ENGINE ROOM'),
            _buildInspectionRow('Crank Case Oil Level', ['Full', 'Mid', 'Low']),
            _buildInspectionRow('Water Level', ['Full', 'Dead']),
            _buildInspectionRow('Exhauster Manifold', ['Intact', 'Leaking']),
            _buildInspectionRow('Fuel Lines', ['Intact', 'Leaking']),
            _buildInspectionRow('Fuel Injection Pump', [
              'Working',
              'Not Working',
            ]),
            _buildInspectionRow('Water Pump', ['Intact', 'Leaking']),
            _buildInspectionRow('Lube Oil Pump', ['Working', 'Not Working']),
            _buildInspectionRow('Lube Oil Filter Zone', [
              'Green',
              'Yellow',
              'Red',
            ]),
            _buildInspectionRow('Fuel Filter Housing', ['Intact', 'Leaking']),
            _buildInspectionRow('Fuel Strainer', ['Intact', 'Leaking']),
            _buildInspectionRow('Fuel Racks Assembly (Firing Order)', [
              'YES',
              'NO',
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('COMPRESSOR ROOM'),
            _buildInspectionRow('Oil Level', ['Green', 'Red']),
            _buildInspectionRow(
              'Safety Valves Blowing',
              ['Satisfactory', 'Unsatisfactory'],
              predefinedRemarks: [
                'Air Compress Valves Malfunctioned',
                'Excess Air Pressure',
              ],
            ),
            _buildInspectionRow('Any Knocking Sound', ['Yes', 'No']),
            _buildInspectionRow('Abnormal Temperature', ['Yes', 'No']),
            _buildMeasurementRow('Lube Oil Pressure (> 10 Psi)', '> 10 Psi', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow(
              'Air Compressor Loading (30-35s @ 600-650 RPM)',
              ['Satisfactory', 'Unsatisfactory'],
              predefinedRemarks: [
                'Shaft uncoupled',
                'Hose pipe uncoupled',
                'Valve malfunctioned',
                'Aux voltage drop',
                'Other',
              ],
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Under Truck Inspection'),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            _buildSectionHeader('UNDER TRUCK'),
            _buildMeasurementRow('Brake Shoe (> 0.5")', 'Inches', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Wheel Defects (Profile Gauge)', [
              'Go In',
              'Go Out',
            ], defaultRemark: 'Replace wheel if Go Out'),
            _buildMeasurementRow('Buffers Length', '620-625 mm', [
              'Satisfactory',
              'Unsatisfactory',
            ], defaultRemark: 'Replace buffer if out of range'),
            _buildInspectionRow('Shock Absorber', ['Intact', 'Leaking']),
            _buildMeasurementRow('Gear Case Oil Level', '7-10.5 L', [
              'Satisfactory',
              'Unsatisfactory',
            ], defaultRemark: 'Replace gear case/seal if unsatisfactory'),
            _buildInspectionRow('Coil Springs', ['Intact', 'Broken']),
            _buildInspectionRow('Guide Link', ['Intact', 'Broken']),
          ],
        ),
      ),
      Step(
        title: const Text('Electrical & Load Test'),
        isActive: _currentStep >= 4,
        state: _currentStep >= 4 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            _buildSectionHeader('ELECTRICAL COMPARTMENT'),
            _buildInspectionRow('Cards / Panels (SDIP Test)', [
              'Working',
              'Not Working',
            ]),
            _buildInspectionRow('Blowers & Motors (SDIP Test)', [
              'Working',
              'Not Working',
            ]),
            const SizedBox(height: 16),
            _buildSectionHeader('TRACTION MOTOR'),
            _buildInspectionRow('Inspection Cover', ['Fitted', 'Not Fitted']),
            _buildInspectionRow('Leads Condition', ['Intact', 'Parish']),
            _buildInspectionRow('Thimble', ['Intact', 'Loose']),
            _buildInspectionRow('Air Boot Duct', ['Intact', 'Broken']),
            const SizedBox(height: 16),
            _buildSectionHeader('LOAD TEST'),
            _buildInspectionRow('Engine RPM (1000 - 1050)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Booster Pressure (300-330 KPA)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Lube Oil Pressure (>600 KPA)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Fuel Pressure (550-600 KPA)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Alternator Voltages (1250-1300V)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
            _buildInspectionRow('Gross KW (3400 KW)', [
              'Satisfactory',
              'Unsatisfactory',
            ]),
          ],
        ),
      ),
    ];
  }

  // Header Step Component
  Widget _buildHeaderStep() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Department: Mechanical',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _shedController,
              decoration: const InputDecoration(
                labelText: 'Shed Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _classController,
              decoration: const InputDecoration(
                labelText: 'Class of Loco',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _officerController,
              decoration: const InputDecoration(
                labelText: 'Inspecting Officer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locoNumController,
              decoration: const InputDecoration(
                labelText: 'Loco Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildInspectionRow(
    String key,
    List<String> statusOptions, {
    List<String>? predefinedRemarks,
    String? defaultRemark,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _formData['${key}_status'] ?? statusOptions.first,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: statusOptions.map((opt) {
                return DropdownMenuItem(value: opt, child: Text(opt));
              }).toList(),
              onChanged: (val) {
                setState(() => _formData['${key}_status'] = val);
              },
            ),
            if (predefinedRemarks != null && predefinedRemarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6.0,
                children: predefinedRemarks.map((remarkOption) {
                  final isSelected = (_formData['${key}_chip_remarks'] ?? [])
                      .contains(remarkOption);
                  return ChoiceChip(
                    label: Text(
                      remarkOption,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        List<String> current = List.from(
                          _formData['${key}_chip_remarks'] ?? [],
                        );
                        selected
                            ? current.add(remarkOption)
                            : current.remove(remarkOption);
                        _formData['${key}_chip_remarks'] = current;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              initialValue: defaultRemark,
              decoration: InputDecoration(
                labelText: 'Remarks / Notes',
                hintText: 'Enter specific observations',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.note_alt_outlined,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              onChanged: (val) => _formData['${key}_remarks'] = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementRow(
    String key,
    String unit,
    List<String> statusOptions, {
    String? defaultRemark,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _formData['${key}_status'] ?? statusOptions.first,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: statusOptions.map((opt) {
                      return DropdownMenuItem(value: opt, child: Text(opt));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _formData['${key}_status'] = val);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Value ($unit)',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) => _formData['${key}_value'] = val,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: defaultRemark,
              decoration: InputDecoration(
                labelText: 'Remarks / Notes',
                hintText: 'Enter specific observations',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.note_alt_outlined,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              onChanged: (val) => _formData['${key}_remarks'] = val,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          _inspectionDate == null
              ? 'Select Expiry Date'
              : _inspectionDate.toString().split(' ')[0],
        ),
        trailing: Icon(
          Icons.calendar_month,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (picked != null) setState(() => _inspectionDate = picked);
        },
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      showAppMessage(
        context,
        'Locomotive Inspection Form Saved Successfully!',
        tone: AppDialogTone.success,
      );
    }
  }
}
