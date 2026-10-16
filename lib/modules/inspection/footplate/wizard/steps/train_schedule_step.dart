import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/modules/inspection/footplate/models/footplate_models.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/common_widgets.dart';

class TrainScheduleStep extends StatefulWidget {
  final TrainScheduleData data;
  final VoidCallback onChanged;

  const TrainScheduleStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<TrainScheduleStep> createState() => _TrainScheduleStepState();
}

class _TrainScheduleStepState extends State<TrainScheduleStep> {
  late final TextEditingController _loadCtrl = TextEditingController(
    text: widget.data.load,
  );
  late final TextEditingController _marginCtrl = TextEditingController(
    text: widget.data.lateMargin.toString(),
  );

  Future<void> _pickTime(bool isArrival) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: isArrival
          ? (widget.data.arrival ?? now)
          : (widget.data.departure ?? now),
    );
    if (picked != null) {
      setState(
        () => isArrival
            ? widget.data.arrival = picked
            : widget.data.departure = picked,
      );
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Train Schedule',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'This information auto-fills the "Particulars of Train" section later.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Train & Locomotive',
          icon: Icons.train,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dropdown(
                'Select Train No',
                d.trainNo,
                kTrainNumbers,
                (v) => setState(() => d.trainNo = v),
              ),
              const SizedBox(height: 14),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: _loadCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: 'Load',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  d.load = v;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 14),
              _dropdown(
                'Select Engine No',
                d.engineNo,
                kEngineNumbers,
                (v) => setState(() => d.engineNo = v),
                helper: 'Engine No. is Locomotive No. of Asset',
              ),
              const SizedBox(height: 14),
              RadioChipGroup(
                label: 'Direction',
                options: const ['Up', 'Down'],
                value: d.direction,
                onChanged: (v) => setState(() => d.direction = v),
                dense: true,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Station & Timing',
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dropdown(
                'Select Station',
                d.station,
                kStations,
                (v) => setState(() => d.station = v),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timeField(
                      'Arrival',
                      d.arrival,
                      () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(
                      'Departure',
                      d.departure,
                      () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: _marginCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                keyboardType: TextInputType.text,
                inputFormatters: [
                  // This restricts the user to typing only whole numbers
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: 'Late Margin (Seconds)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  d.lateMargin = int.tryParse(v) ?? 0;
                  widget.onChanged();
                },
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Crew',
          icon: Icons.groups,
          subtitle:
              'Type a name to search — format: Name, Designation, Department, Org Unit.',
          child: Column(
            children: [
              PersonPickerField(
                label: "Driver's Name",
                value: d.driver,
                onChanged: (p) => setState(() {
                  d.driver = p;
                  widget.onChanged();
                }),
              ),
              const SizedBox(height: 16),
              PersonPickerField(
                label: 'Assistant Driver',
                value: d.assistantDriver,
                onChanged: (p) => setState(() {
                  d.assistantDriver = p;
                  widget.onChanged();
                }),
              ),
              const SizedBox(height: 16),
              PersonPickerField(
                label: 'Guard Incharge',
                value: d.guardIncharge,
                onChanged: (p) => setState(() {
                  d.guardIncharge = p;
                  widget.onChanged();
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    String? helper,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        onChanged(v);
        widget.onChanged();
      },
    );
  }

  Widget _timeField(String label, TimeOfDay? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
          suffixIcon: const Icon(Icons.access_time, size: 18),
        ),
        child: Text(value == null ? 'Select time' : value.format(context)),
      ),
    );
  }
}
