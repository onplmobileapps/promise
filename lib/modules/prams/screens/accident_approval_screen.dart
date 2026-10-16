import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/widgets/form_widgets.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_state.dart';
import 'package:railway_hrms/modules/prams/bloc/incident_photo_cubit.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_reference.dart';
import 'package:railway_hrms/modules/prams/screens/accident_submitted_screen.dart';
import 'package:railway_hrms/modules/prams/screens/report_accident_screen.dart';
import 'package:railway_hrms/modules/prams/services/file_upload_service.dart';
import 'package:railway_hrms/modules/prams/widgets/classification_sheet_widget.dart';

class AccidentApprovalScreen extends StatelessWidget {
  final ScrollController? scrollController;

  const AccidentApprovalScreen({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = AccidentCubit(repository: sl<AccidentRepository>());
            // Load reference data first, then the accident, so that
            // divisions / sections / classes / trains are available to match.
            cubit.bootstrap(accidentId: 81);
            return cubit;
          },
        ),
        BlocProvider(create: (_) => IncidentPhotosCubit(FileUploadService())),
      ],
      child: _AccidentApprovalForm(scrollController: scrollController),
    );
  }
}

class _AccidentApprovalForm extends StatefulWidget {
  final ScrollController? scrollController;

  const _AccidentApprovalForm({this.scrollController});

  @override
  State<_AccidentApprovalForm> createState() => _AccidentApprovalFormState();
}

class _AccidentApprovalFormState extends State<_AccidentApprovalForm> {
  final _locomotiveController = TextEditingController();
  final _kilometersController = TextEditingController();
  final _lastStationController = TextEditingController();
  final _remarksController = TextEditingController();
  final _captionController = TextEditingController();

  DateTime? _pickedDate;
  TimeOfDay? _pickedTime;

  /// Guards the one-shot hydration of the form from AccidentState.
  /// Prevents the listener from clobbering user edits on every emit.
  bool _hasHydrated = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _locomotiveController.dispose();
    _kilometersController.dispose();
    _lastStationController.dispose();
    _remarksController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  // ── Auto-fill controllers whenever a train is selected ───────────────

  void _syncControllersWithTrain(ActiveTrain? train) {
    if (train == null) return;
    _locomotiveController.text = train.locomotiveNumber ?? '';
    _kilometersController.text = train.kilometerNumber?.toString() ?? '';
    _lastStationController.text = train.lastCrossedStation?.name ?? '';
  }

  /// Populate the form fields from an accident already loaded by the cubit.
  /// Called once (guarded by [_hasHydrated]).
  void _populateFromState(AccidentState state) {
    _locomotiveController.text = state.locomotiveOverride ?? '';
    _kilometersController.text = state.kilometerOverride?.toString() ?? '';
    _remarksController.text = state.description;
    _lastStationController.text =
        state.accidentDetails?.lastCrossedStationName ?? '';

    final dateTime = state.accidentDateTime;
    if (dateTime != null) {
      _pickedDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      _pickedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (result == null) return;

    setState(() => _pickedDate = result);

    if (context.mounted) {
      _combineAndSetDateTime(context);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final result = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
    );

    if (result == null) return;

    setState(() => _pickedTime = result);

    if (context.mounted) {
      _combineAndSetDateTime(context);
    }
  }

  void _combineAndSetDateTime(BuildContext context) {
    final date = _pickedDate;
    final time = _pickedTime;

    if (date == null || time == null) return;

    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    context.read<AccidentCubit>().setAccidentDateTime(combined);
  }

  Future<void> _pickAccidentClass(BuildContext context) async {
    final cubit = context.read<AccidentCubit>();

    final selected = await showModalBottomSheet<AccidentClass>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ClassificationSheet(
        classes: cubit.state.accidentClasses,
        selected: cubit.state.selectedAccidentClass,
      ),
    );

    if (selected != null) {
      cubit.selectAccidentClass(selected);
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final cubit = context.read<AccidentCubit>();
    final photosCubit = context.read<IncidentPhotosCubit>();

    if (!cubit.state.canSubmit) {
      showAppMessage(
        context,
        'Select a train, classification, and date/time first.',
        tone: AppDialogTone.warning,
      );
      return;
    }

    cubit.setDescription(_remarksController.text);
    cubit.setCaption(_captionController.text);

    final success = await cubit.submitAccident(
      photos: photosCubit.state.photos,
    );

    if (!context.mounted) return;

    if (!success) {
      showAppMessage(
        context,
        cubit.state.errorMessage ?? 'Submission failed. Please try again.',
        tone: AppDialogTone.warning,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccidentReportSubmittedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AccidentCubit, AccidentState>(
      listenWhen: (previous, current) {
        return previous.status != current.status ||
            previous.selectedTrain != current.selectedTrain ||
            previous.accidentDateTime != current.accidentDateTime ||
            previous.description != current.description ||
            previous.locomotiveOverride != current.locomotiveOverride ||
            previous.kilometerOverride != current.kilometerOverride;
      },
      listener: (context, state) {
        // One-shot hydration once the accident + reference data are loaded.
        if (!_hasHydrated &&
            state.status == AccidentStatus.referenceLoaded &&
            state.accidentDetails != null) {
          _hasHydrated = true;
          _populateFromState(state);
          // If the accident has no matched train but locomotive/kilometer
          // came back from the API, the controllers are already populated
          // by _populateFromState. Only sync from train when available.
          if (state.selectedTrain != null &&
              (state.locomotiveOverride == null ||
                  state.kilometerOverride == null)) {
            _syncControllersWithTrain(state.selectedTrain);
          }
          if (mounted) setState(() {});
        }
      },
      builder: (context, state) {
        final cubit = context.read<AccidentCubit>();

        final isLoadingTrains = state.status == AccidentStatus.loadingReference;

        final isSubmitting = state.status == AccidentStatus.submitting;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            clipBehavior: Clip.none,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accident Report Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Provide essential incident information',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoadingTrains)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Train: full width so long labels are readable ───────
                FormGroup(
                  label: 'Train',
                  child: TextField(
                    controller: TextEditingController(
                      text:
                          state.accidentDetails?.trainName ??
                          state.selectedTrain?.trainName ??
                          '',
                    ),
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 4001',
                      prefixIcon: Icon(
                        Icons.directions_railway_filled_outlined,
                        size: 20,
                      ),
                      isDense: true,
                      contentPadding: AppFormStyle.fieldPadding,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Locomotive + Kilometers ─────────────────────────────
                ResponsiveFieldGroup(
                  left: FormGroup(
                    label: 'Locomotive No.',
                    child: TextField(
                      controller: _locomotiveController,
                      onChanged: cubit.setLocomotive,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 4001',
                        prefixIcon: Icon(
                          Icons.directions_railway_filled_outlined,
                          size: 20,
                        ),
                        isDense: true,
                        contentPadding: AppFormStyle.fieldPadding,
                      ),
                    ),
                  ),
                  right: FormGroup(
                    label: 'Kilometers',
                    child: TextField(
                      controller: _kilometersController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (v) => cubit.setKilometer(double.tryParse(v)),
                      decoration: const InputDecoration(
                        hintText: 'Km',
                        prefixIcon: Icon(Icons.straighten_outlined, size: 20),
                        isDense: true,
                        contentPadding: AppFormStyle.fieldPadding,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Last Station: full width ────────────────────────────
                FormGroup(
                  label: 'Last Station',
                  isRequired: false,
                  child: TextField(
                    controller: _lastStationController,
                    enabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Auto-filled from train',
                      prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                      isDense: true,
                      contentPadding: AppFormStyle.fieldPadding,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Division ────────────────────────────────────────────
                FormGroup(
                  label: 'Division',
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(
                      'division-${state.divisionId}-${state.divisions.length}',
                    ),
                    initialValue:
                        state.divisions.any((d) => d.id == state.divisionId)
                        ? state.divisionId
                        : null,
                    hint: const Text('Select division'),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.corporate_fare_rounded, size: 20),
                      isDense: true,
                      contentPadding: AppFormStyle.fieldPadding,
                    ),
                    items: state.divisions
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              d.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: cubit.selectDivision,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Section ─────────────────────────────────────────────
                FormGroup(
                  label: 'Section',
                  child: DropdownButtonFormField<int>(
                    key: ValueKey(
                      'section-${state.divisionId}-${state.sectionId}-'
                      '${state.availableSections.length}',
                    ),
                    initialValue:
                        state.availableSections.any(
                          (s) => s.id == state.sectionId,
                        )
                        ? state.sectionId
                        : null,
                    hint: const Text('Select section'),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.route_rounded, size: 20),
                      isDense: true,
                      contentPadding: AppFormStyle.fieldPadding,
                    ),
                    items: state.availableSections
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: state.divisionId == null
                        ? null
                        : cubit.selectSection,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Block Section ───────────────────────────────────────
                FormGroup(
                  label: 'Block Section',
                  isRequired: false,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'block-${state.divisionId}-${state.blockSectionId}-'
                      '${state.availableBlockSections.length}',
                    ),
                    initialValue:
                        state.availableBlockSections.any(
                          (b) => b.id == state.blockSectionId,
                        )
                        ? state.blockSectionId
                        : null,
                    hint: const Text('Select block section'),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.linear_scale_rounded, size: 20),
                      isDense: true,
                      contentPadding: AppFormStyle.fieldPadding,
                    ),
                    items: state.availableBlockSections
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              b.label ?? b.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: state.divisionId == null
                        ? null
                        : cubit.selectBlockSection,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Date + Time ─────────────────────────────────────────
                ResponsiveFieldGroup(
                  left: FormGroup(
                    label: 'Incident Date',
                    child: PickerField(
                      icon: Icons.calendar_today_outlined,
                      hint: 'Select date',
                      value: _pickedDate == null
                          ? null
                          : '${_pickedDate!.year}-'
                                '${_pickedDate!.month.toString().padLeft(2, '0')}-'
                                '${_pickedDate!.day.toString().padLeft(2, '0')}',
                      onTap: () => _pickDate(context),
                    ),
                  ),
                  right: FormGroup(
                    label: 'Incident Time',
                    child: PickerField(
                      icon: Icons.access_time_rounded,
                      hint: 'Select time',
                      value: _pickedTime?.format(context),
                      onTap: () => _pickTime(context),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Classification (full width) + read-only Severity ────
                FormGroup(
                  label: 'Classification',
                  child: PickerField(
                    icon: Icons.category_outlined,
                    hint: 'Select accident type',
                    value: state.selectedAccidentClass == null
                        ? null
                        : '${state.selectedAccidentClass!.code} · '
                              '${state.selectedAccidentClass!.shortMeaning}',
                    onTap: () => _pickAccidentClass(context),
                  ),
                ),

                const SizedBox(height: 14),

                FormGroup(
                  label: 'Severity',
                  isRequired: false,
                  child: SeverityReadOnlyField(severity: state.severity),
                ),

                const SizedBox(height: 14),

                // ── Incident conditions ─────────────────────────────────
                FormGroup(
                  label: 'Incident Conditions',
                  isRequired: false,
                  child: Column(
                    children: [
                      ConditionSwitchTile(
                        icon: Icons.report_problem_outlined,
                        title: 'Train Derailed',
                        subtitle: 'One or more vehicles off the track',
                        color: const Color(0xFFD97706),
                        value: state.trainDerailed,
                        onChanged: cubit.setTrainDerailed,
                      ),

                      const SizedBox(height: 8),

                      ConditionSwitchTile(
                        icon: Icons.local_fire_department_rounded,
                        title: 'Fire Involved',
                        subtitle: 'Fire or explosion at the site',
                        color: const Color(0xFFDC2626),
                        value: state.hasFire,
                        onChanged: cubit.setHasFire,
                      ),

                      const SizedBox(height: 8),

                      ConditionSwitchTile(
                        icon: Icons.personal_injury_outlined,
                        title: 'People Injured',
                        subtitle: 'Passengers or staff hurt',
                        color: const Color(0xFFE11D48),
                        value: state.peopleInjured,
                        onChanged: cubit.setPeopleInjured,
                        expandedChild: TextField(
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              cubit.setInjuredCount(int.tryParse(v) ?? 0),
                          decoration: const InputDecoration(
                            labelText: 'Injured count',
                            prefixIcon: Icon(Icons.numbers_rounded, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      ConditionSwitchTile(
                        icon: Icons.dangerous_outlined,
                        title: 'Dangerous Goods',
                        subtitle: 'Hazardous cargo involved',
                        color: const Color(0xFF7C3AED),
                        value: state.dangerousGoods,
                        onChanged: cubit.setDangerousGoods,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                FormGroup(
                  label: 'Remarks',
                  child: TextFormField(
                    controller: _remarksController,
                    textInputAction: TextInputAction.done,
                    maxLines: 3,
                    onChanged: cubit.setDescription,
                    decoration: const InputDecoration(
                      hintText: 'Enter Remarks',
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Full width: Upload + Caption ────────────────────────
                const FormGroup(
                  label: 'Upload Incident Media',
                  child: DottedUploadCard(),
                ),

                const SizedBox(height: 14),

                FormGroup(
                  label: 'Caption',
                  isRequired: false,
                  child: TextFormField(
                    controller: _captionController,
                    maxLines: 2,
                    onChanged: cubit.setCaption,
                    decoration: const InputDecoration(
                      hintText: 'Describe the photos (optional)',
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Actions ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                cubit.clearTrain();
                                context.read<IncidentPhotosCubit>().clear();

                                setState(() {
                                  _pickedDate = null;
                                  _pickedTime = null;
                                  _hasHydrated = false;
                                });

                                _locomotiveController.clear();
                                _kilometersController.clear();
                                _lastStationController.clear();
                                _remarksController.clear();
                                _captionController.clear();
                              },
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
                        onPressed: isSubmitting
                            ? null
                            : () => _handleSubmit(context),
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(isSubmitting ? 'Submitting...' : 'Submit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
