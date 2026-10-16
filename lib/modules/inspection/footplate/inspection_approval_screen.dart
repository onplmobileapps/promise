import 'package:flutter/material.dart';

import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/footplate/wizard/wizard_screen.dart';

class InspectionApprovalScreen extends StatefulWidget {
  const InspectionApprovalScreen({super.key});

  @override
  State<InspectionApprovalScreen> createState() =>
      _InspectionApprovalScreenState();
}

class _InspectionApprovalScreenState extends State<InspectionApprovalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _officerController = TextEditingController();

  String? _train;
  String? _origin;
  String? _destination;
  DateTime? _inspectionDate;
  TimeOfDay? _departureTime;
  TimeOfDay? _arrivalTime;
  bool _requestSubmitted = false;

  @override
  void dispose() {
    _officerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _inspectionDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _inspectionDate = picked);
  }

  Future<void> _pickTime({required bool departure}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: departure
          ? (_departureTime ?? TimeOfDay.now())
          : (_arrivalTime ?? TimeOfDay.now()),
    );
    if (picked == null) return;
    setState(() {
      if (departure) {
        _departureTime = picked;
      } else {
        _arrivalTime = picked;
      }
    });
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate() ||
        _inspectionDate == null ||
        _departureTime == null ||
        _arrivalTime == null) {
      setState(() {});
      return;
    }

    setState(() => _requestSubmitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Approval')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              _requestSubmitted
                  ? 'Inspection approved'
                  : 'Request inspection approval',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _requestSubmitted
                  ? 'This request is approved for now. You can start the inspection.'
                  : 'Share the planned train movement with the concern officer before starting the inspection.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _SectionCard(
              title: 'Train assignment',
              icon: Icons.train_rounded,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _train,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Train',
                      hintText: 'Select train number',
                    ),
                    items: kTrainNumbers
                        .map(
                          (train) => DropdownMenuItem(
                            value: train,
                            child: Text(train),
                          ),
                        )
                        .toList(),
                    onChanged: _requestSubmitted
                        ? null
                        : (value) => setState(() => _train = value),
                    validator: (value) =>
                        value == null ? 'Select a train' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _officerController,
                    enabled: !_requestSubmitted,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'Concern officer',
                      hintText: 'Enter officer name or designation',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter the concern officer'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Schedule',
              icon: Icons.schedule_rounded,
              child: Column(
                children: [
                  _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Inspection date',
                    value: _inspectionDate == null
                        ? null
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_inspectionDate!),
                    onTap: _requestSubmitted ? null : _pickDate,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.departure_board_rounded,
                          label: 'Departure',
                          value: _departureTime?.format(context),
                          onTap: _requestSubmitted
                              ? null
                              : () => _pickTime(departure: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.flag_rounded,
                          label: 'Arrival',
                          value: _arrivalTime?.format(context),
                          onTap: _requestSubmitted
                              ? null
                              : () => _pickTime(departure: false),
                        ),
                      ),
                    ],
                  ),
                  if (!_requestSubmitted &&
                      (_inspectionDate == null ||
                          _departureTime == null ||
                          _arrivalTime == null))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Date and both schedule times are required.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Inspection route',
              icon: Icons.alt_route_rounded,
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _origin,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'From'),
                      items: kStations
                          .map(
                            (station) => DropdownMenuItem(
                              value: station,
                              child: Text(
                                station,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _requestSubmitted
                          ? null
                          : (value) => setState(() => _origin = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _destination,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'To'),
                      items: kStations
                          .map(
                            (station) => DropdownMenuItem(
                              value: station,
                              child: Text(
                                station,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _requestSubmitted
                          ? null
                          : (value) => setState(() => _destination = value),
                      validator: (value) => value == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_requestSubmitted)
              _ApprovalStatusCard(
                onStartInspection: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => FootplateWizardScreen(
                        initialTrain: _train,
                        initialStation: _origin,
                        initialDeparture: _departureTime,
                        initialArrival: _arrivalTime,
                        initialDriver: kStaffDirectory[5],
                        initialAssistantDriver: kStaffDirectory[4],
                        initialGuardIncharge: kStaffDirectory[6],
                      ),
                    ),
                  );
                },
              )
            else
              FilledButton.icon(
                onPressed: _submitRequest,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send for approval'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          value ?? 'Select',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ApprovalStatusCard extends StatelessWidget {
  final VoidCallback onStartInspection;

  const _ApprovalStatusCard({required this.onStartInspection});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Approved for inspection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The approval is enabled temporarily. Start the inspection when you are ready.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onStartInspection,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start inspection'),
            ),
          ],
        ),
      ),
    );
  }
}
