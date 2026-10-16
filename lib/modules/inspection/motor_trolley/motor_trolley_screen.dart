import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/widgets/form_widgets.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/inspection_params_config.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_cubit.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';

class MotorTrolleyInspectionScreen extends StatelessWidget {
  const MotorTrolleyInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MotorTrolleyInspectionCubit(),
      child: const _MotorTrolleyInspectionView(),
    );
  }
}

class _MotorTrolleyInspectionView extends StatelessWidget {
  const _MotorTrolleyInspectionView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const FormAppBar(title: 'Motor Trolley Inspection'),
      body: BlocConsumer<MotorTrolleyInspectionCubit, MotorTrolleyInspectionState>(
        listener: (context, state) {
          if (state.isSuccess) {
            showAppMessage(
              context,
              'Inspection report saved successfully',
              tone: AppDialogTone.success,
            );
          }
          if (state.errorMessage != null) {
            showAppMessage(
              context,
              state.errorMessage!,
              tone: AppDialogTone.error,
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<MotorTrolleyInspectionCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ───────────────────────────────────────
                _SectionCard(
                  title: 'Inspection Header',
                  icon: Icons.assignment_outlined,
                  children: [
                    FormGroup(
                      label: 'Name / Designation of Inspecting Officer',
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Enter name & designation',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            cubit.updateField(inspectingOfficer: v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Date of Inspection',
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  state.inspectionDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                            if (date != null) {
                              cubit.updateField(inspectionDate: date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: 'Select date',
                              prefixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                              isDense: true,
                            ),
                            child: Text(
                              state.inspectionDate != null
                                  ? DateFormat(
                                      'dd MMM yyyy',
                                    ).format(state.inspectionDate!)
                                  : 'Select date',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Between Station',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.betweenStation,
                          hint: const Text('Select station'),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.train_outlined, size: 18),
                            isDense: true,
                          ),
                          items:
                              const [
                                    'Lahore',
                                    'Kot Lakhpat',
                                    'Raiwind',
                                    'Okara',
                                    // add more stations
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              cubit.updateField(betweenStation: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Section From',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'From',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(sectionFrom: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Section To',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'To',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(sectionTo: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'KM From',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Km',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(kmFrom: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'KM To',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Km',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(kmTo: v),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── I. TRACK GEOMETRY ─────────────────────────────────
                _ExpandableSection(
                  title: 'I. Track Geometry',
                  initiallyExpanded: true,
                  children: [
                    _SubSectionTitle('Alignment'),
                    const SizedBox(height: 8),
                    Text(
                      'Standard: Straight  |  Permissible: ±5 mm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Reading (mm)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(alignmentReading: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Out of Limit',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.alignmentOutOfLimit,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Yes', 'No']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(alignmentOutOfLimit: v),
                        ),
                      ),
                    ),
                    if (state.alignmentOutOfLimit == 'Yes') ...[
                      const SizedBox(height: 12),
                      FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.alignmentReason,
                          hint: const Text('Select reason'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'Short Fitting',
                                    'US Sleepers',
                                    'Defective Rail',
                                    'Others',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              cubit.updateField(alignmentReason: v),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _SubSectionTitle('Gauge'),
                    const SizedBox(height: 8),
                    FormGroup(
                      label: 'Speed Category',
                      child: DropdownButtonFormField<String>(
                        initialValue: state.gaugeSpeedCategory,
                        hint: const Text('Select speed range'),
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items:
                            const [
                                  'Above 100 Kmph',
                                  '80 to 100 km/h',
                                  '60 to 80 km/h',
                                  '60 km/h and below',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            cubit.updateField(gaugeSpeedCategory: v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Reading',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'mm',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(gaugeReading: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Out of Limit',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.gaugeOutOfLimit,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Yes', 'No']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(gaugeOutOfLimit: v),
                        ),
                      ),
                    ),
                    if (state.gaugeOutOfLimit == 'Yes') ...[
                      const SizedBox(height: 12),
                      FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.gaugeReason,
                          hint: const Text('Select reason'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'Short Fitting',
                                    'US Sleepers',
                                    'Defective Rail',
                                    'Others',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => cubit.updateField(gaugeReason: v),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _SubSectionTitle('Cross Level'),
                    const SizedBox(height: 8),
                    Text(
                      'Standard: Level  |  Permissible: ±6 mm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Reading (mm)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(crossLevelReading: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Out of Limit',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.crossLevelOutOfLimit,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Yes', 'No']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(crossLevelOutOfLimit: v),
                        ),
                      ),
                    ),
                    if (state.crossLevelOutOfLimit == 'Yes') ...[
                      const SizedBox(height: 12),
                      FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.crossLevelReason,
                          hint: const Text('Select reason'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'Loose Packing',
                                    'Short Ballast Cushion',
                                    'Others',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              cubit.updateField(crossLevelReason: v),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _SubSectionTitle('Rail'),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Rail Type',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.railType,
                          hint: const Text('Select type'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'UIC-54',
                                    '100 RE',
                                    '90-R',
                                    '90-BSS',
                                    '75-R',
                                    '75-BSS',
                                    '75/87',
                                    '75/92',
                                    '87-FF',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => cubit.updateField(railType: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Remarks',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.railRemarks,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'Top wear',
                                    'Side wear',
                                    'End Bettered',
                                    'Hogged',
                                    'Wheel Burnt',
                                    'Defective',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => cubit.updateField(railRemarks: v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Sleeper'),
                    const SizedBox(height: 8),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      trackGeometryExtraFields
                          .where((f) => f.key.startsWith('sleeper'))
                          .toList(),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Fittings'),
                    const SizedBox(height: 8),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      trackGeometryExtraFields
                          .where((f) => f.key.startsWith('fitting'))
                          .toList(),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Ballast, Embankment, Drainage & Other'),
                    const SizedBox(height: 8),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      trackGeometryExtraFields
                          .where(
                            (f) =>
                                !f.key.startsWith('sleeper') &&
                                !f.key.startsWith('fitting'),
                          )
                          .toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 2. CURVES ─────────────────────────────────────────
                _ExpandableSection(
                  title: '2. Curves',
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Curve No',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'No.',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(curveNo: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Degree of Curve',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.degreeOfCurve,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: [
                            for (var i = 0.5; i <= 10; i += 0.5)
                              DropdownMenuItem(
                                value: i.toString(),
                                child: Text(i.toString()),
                              ),
                          ],
                          onChanged: (v) => cubit.updateField(degreeOfCurve: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormGroup(
                      label: 'Speed (KMPH)',
                      child: DropdownButtonFormField<String>(
                        initialValue: state.curveSpeed,
                        hint: const Text('Select speed range'),
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items:
                            const [
                                  'Above 100',
                                  '80 to 100',
                                  '60 to 80',
                                  'Below 60',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => cubit.updateField(curveSpeed: v),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Gauge on Curve'),
                    const SizedBox(height: 8),
                    Text(
                      'Standard: 1676  |  Permissible: ≤4° +13/-3 to +15/-4, >4° +20 mm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Reading (mm)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(curveGaugeReading: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Out of Limit',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.curveGaugeOutOfLimit,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Yes', 'No']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(curveGaugeOutOfLimit: v),
                        ),
                      ),
                    ),
                    if (state.curveGaugeOutOfLimit == 'Yes') ...[
                      const SizedBox(height: 12),
                      ResponsiveFieldGroup(
                        left: FormGroup(
                          label: 'Action',
                          child: DropdownButtonFormField<String>(
                            initialValue: state.curveGaugeAction,
                            hint: const Text('Select'),
                            isExpanded: true,
                            decoration: const InputDecoration(isDense: true),
                            items:
                                const ['Adjustment (Versine)', 'Re-alignment']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                cubit.updateField(curveGaugeAction: v),
                          ),
                        ),
                        right: FormGroup(
                          label: 'Reason',
                          child: DropdownButtonFormField<String>(
                            initialValue: state.curveGaugeReason,
                            hint: const Text('Select'),
                            isExpanded: true,
                            decoration: const InputDecoration(isDense: true),
                            items:
                                const [
                                      'Excessive side rail wear',
                                      'Less Ballast on Shoulders',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                cubit.updateField(curveGaugeReason: v),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _SubSectionTitle('Super Elevation'),
                    const SizedBox(height: 8),
                    Text(
                      'Standard: Max 165 mm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Reading (mm)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(superElevationReading: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Action',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.superElevationAction,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Adjusted Super Elevation']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(superElevationAction: v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Curve Post (Standard: 1000)',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.curvePostAvailable,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Available', 'Not Available']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(curvePostAvailable: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Check Rail Clearance (6° & above)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Standard: 47 mm',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(
                            checkRailClearanceCurveReading: v,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormGroup(
                      label: 'Check Rail Clearance Status',
                      child: DropdownButtonFormField<String>(
                        initialValue: state.checkRailClearanceCurveStatus,
                        hint: const Text('Select'),
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items:
                            const [
                                  '< 47 (need adjustment)',
                                  '> 47 (need adjustment)',
                                  '= 47 (OK)',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            cubit.updateField(checkRailClearanceCurveStatus: v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 3. POINTS & CROSSINGS ─────────────────────────────
                _ExpandableSection(
                  title: '3. Points & Crossings',
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Gauge',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcGauge,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Exact', 'Slack', 'Tight']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => cubit.updateField(pcGauge: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Cross Level',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcCrossLevel,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Exact', 'Out']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => cubit.updateField(pcCrossLevel: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormGroup(
                      label: 'Fittings (Standard: 100%)',
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter %',
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            cubit.updateField(pcFittingsPercentage: v),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Wear of Switch (Permissible: 0–150)'),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Action',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcSwitchWearAction,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Within Limit', 'Replace Switch']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcSwitchWearAction: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcSwitchWearReason,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Excessive wear', 'Broken']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcSwitchWearReason: v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Wear of Crossing (Permissible: 0–9.5)'),
                    const SizedBox(height: 8),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Action',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcCrossingWearAction,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Within Limit', 'Replace Crossing']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcCrossingWearAction: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcCrossingWearReason,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    'Excessive wear',
                                    'Broken',
                                    'Ultrasonic Defective',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcCrossingWearReason: v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Check Rails Clearance (Standard: 45)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(pcCheckRailsClearance: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Wing Rail Clearance (Standard: 45–47)',
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter reading',
                            isDense: true,
                          ),
                          onChanged: (v) =>
                              cubit.updateField(pcWingRailClearance: v),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _SubSectionTitle('Crossing Timbers'),
                    const SizedBox(height: 8),
                    FormGroup(
                      label: 'US Percentage',
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 45',
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            cubit.updateField(pcCrossingTimbersPercentage: v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Action',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcCrossingTimbersAction,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items:
                              const [
                                    '95 (Engg Speed Restriction)',
                                    '90',
                                    '70',
                                    '65',
                                    '60',
                                    '50',
                                    '20 to 50',
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcCrossingTimbersAction: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Reason',
                        child: DropdownButtonFormField<String>(
                          initialValue: state.pcCrossingTimbersReason,
                          hint: const Text('Select'),
                          isExpanded: true,
                          decoration: const InputDecoration(isDense: true),
                          items: const ['Increase US percentage']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              cubit.updateField(pcCrossingTimbersReason: v),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 4. BRIDGES ─────────────────────────────────────────
                _ExpandableSection(
                  title: '4. Bridges',
                  children: [
                    _SubSectionTitle('Sub-structure'),
                    const SizedBox(height: 8),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      bridgeSubStructureFields,
                    ),
                    const SizedBox(height: 20),
                    _SubSectionTitle('Super-structure'),
                    const SizedBox(height: 8),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      bridgeSuperStructureFields,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 5. LEVEL CROSSINGS (MANNED) ───────────────────────
                _ExpandableSection(
                  title: '5. Level Crossings (Manned)',
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Km From',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) =>
                              cubit.updateField(lcMannedKmFrom: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Km To',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) => cubit.updateField(lcMannedKmTo: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      levelCrossingMannedFields,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 5A. LEVEL CROSSINGS (UN-MANNED) ───────────────────
                _ExpandableSection(
                  title: '5A. Level Crossings (Un-Manned)',
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Km From',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) =>
                              cubit.updateField(lcUnmannedKmFrom: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Km To',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) =>
                              cubit.updateField(lcUnmannedKmTo: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      levelCrossingUnmannedFields,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 6. TUNNEL ──────────────────────────────────────────
                _ExpandableSection(
                  title: '6. Tunnel',
                  children: [
                    ..._buildParamFields(context, cubit, state, tunnelFields),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 7. STATION BUILDINGS ───────────────────────────────
                _ExpandableSection(
                  title: '7. Station Buildings',
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Name',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) => cubit.updateField(sbName: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Km',
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) => cubit.updateField(sbKm: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormGroup(
                      label: 'Section',
                      child: TextField(
                        decoration: const InputDecoration(isDense: true),
                        onChanged: (v) => cubit.updateField(sbSection: v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      stationBuildingFields,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 8. YARDS ───────────────────────────────────────────
                _ExpandableSection(
                  title: '8. Yards',
                  children: [
                    ..._buildParamFields(context, cubit, state, yardFields),
                  ],
                ),

                const SizedBox(height: 12),

                // ── 9. BLOCK SECTIONS ──────────────────────────────────
                _ExpandableSection(
                  title: '9. Block Sections',
                  children: [
                    ..._buildParamFields(
                      context,
                      cubit,
                      state,
                      blockSectionFields,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Signature ─────────────────────────────────────────
                _SectionCard(
                  title: 'Certification',
                  icon: Icons.verified_outlined,
                  children: [
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'Inspected by',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(inspectedBy: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Designation',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Designation',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(designation: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ResponsiveFieldGroup(
                      left: FormGroup(
                        label: 'PWI / In-charge',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(pwiIncharge: v),
                        ),
                      ),
                      right: FormGroup(
                        label: 'Verified by',
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Name',
                            isDense: true,
                          ),
                          onChanged: (v) => cubit.updateField(verifiedBy: v),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Actions ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => cubit.reset(),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: state.isSubmitting
                            ? null
                            : () => cubit.submit(),
                        icon: state.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          state.isSubmitting
                              ? 'Saving…'
                              : (state.isFormComplete
                                    ? 'Save and Submit'
                                    : 'Save Report'),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Renders a list of [ParamField]s (from inspection_param_configs.dart)
/// as FormGroup/ResponsiveFieldGroup rows wired to
/// `cubit.updateValue` / `state.value`. This is what lets the Bridges,
/// Level Crossings, Tunnel, Station Buildings, Yards and Block Sections
/// (and the remaining Track Geometry sub-parts) grow by editing config
/// data instead of the widget tree.
List<Widget> _buildParamFields(
  BuildContext context,
  MotorTrolleyInspectionCubit cubit,
  MotorTrolleyInspectionState state,
  List<ParamField> fields,
) {
  final widgets = <Widget>[];
  for (var i = 0; i < fields.length; i++) {
    widgets.add(_ParamRow(field: fields[i], cubit: cubit, state: state));
    if (i != fields.length - 1) {
      widgets.add(const SizedBox(height: 12));
    }
  }
  return widgets;
}

class _ParamRow extends StatelessWidget {
  final ParamField field;
  final MotorTrolleyInspectionCubit cubit;
  final MotorTrolleyInspectionState state;

  const _ParamRow({
    required this.field,
    required this.cubit,
    required this.state,
  });

  Widget _actualInput(BuildContext context) {
    final currentValue = state.value(field.key);
    switch (field.type) {
      case ParamInputType.dropdown:
        return DropdownButtonFormField<String>(
          initialValue: currentValue,
          hint: const Text('Select'),
          isExpanded: true,
          decoration: const InputDecoration(isDense: true),
          items: (field.options ?? const [])
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) cubit.updateValue(field.key, v);
          },
        );
      case ParamInputType.number:
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: field.hint ?? 'Enter value',
            isDense: true,
          ),
          onChanged: (v) => cubit.updateValue(field.key, v),
        );
      case ParamInputType.text:
        return TextField(
          decoration: InputDecoration(
            hintText: field.hint ?? 'Enter value',
            isDense: true,
          ),
          onChanged: (v) => cubit.updateValue(field.key, v),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRemedyDropdown = field.remedyOptions != null;
    final hasRemedyStatic = field.remedyStatic != null;

    final actualField = FormGroup(
      label: field.label,
      child: _actualInput(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.standard != null) ...[
          Text(
            field.standard!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (hasRemedyDropdown)
          ResponsiveFieldGroup(
            left: actualField,
            right: FormGroup(
              label: 'Remedy',
              child: DropdownButtonFormField<String>(
                initialValue: state.value('${field.key}_remedy'),
                hint: const Text('Select'),
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                items: field.remedyOptions!
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    cubit.updateValue('${field.key}_remedy', v);
                  }
                },
              ),
            ),
          )
        else
          actualField,
        if (hasRemedyStatic) ...[
          const SizedBox(height: 4),
          Text(
            'Remedy: ${field.remedyStatic}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppFormStyle.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const _ExpandableSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppFormStyle.cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      // The tile's ink shows on the card rather than under it.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SubSectionTitle extends StatelessWidget {
  final String text;
  const _SubSectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
