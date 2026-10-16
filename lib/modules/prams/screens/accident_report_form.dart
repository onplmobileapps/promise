import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, Position;
import 'package:intl/intl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/widgets/form_widgets.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_state.dart';
import 'package:railway_hrms/modules/prams/bloc/incident_photo_cubit.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/data/models/accident_reference.dart';
import 'package:railway_hrms/modules/prams/screens/accident_submitted_screen.dart';
import 'package:railway_hrms/modules/prams/services/file_upload_service.dart';
import 'package:railway_hrms/modules/prams/widgets/classification_sheet_widget.dart';

/// Reports an accident: the train and the place, what happened, and
/// photos, sent to control on submit. Where the reporter stands is taken
/// on its own.
class AccidentReportingScreen extends StatelessWidget {
  const AccidentReportingScreen({super.key, this.scrollController});

  /// Scrolls the form, as a sheet holding it does.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AccidentCubit(repository: sl<AccidentRepository>())
                ..loadActiveTrains(),
        ),
        BlocProvider(create: (_) => IncidentPhotosCubit(FileUploadService())),
      ],
      child: _ReportForm(scrollController: scrollController),
    );
  }
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({this.scrollController});

  final ScrollController? scrollController;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _locomotive = TextEditingController();
  final _kilometre = TextEditingController();
  final _remarks = TextEditingController();
  final _injuredController = TextEditingController();

  /// Where the reporter stands; null until found.
  Position? _here;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    final count = context.read<AccidentCubit>().state.injuredCount;
    if (count > 0) _injuredController.text = '$count';
    unawaited(_locate());
  }

  @override
  void dispose() {
    _locomotive.dispose();
    _kilometre.dispose();
    _remarks.dispose();
    _injuredController.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    Position? here;
    try {
      here = await CurrentLocationService.getCurrentLocation();
    } catch (_) {
      here = null;
    }
    if (!mounted) return;
    setState(() {
      _here = here;
      _locating = false;
    });
    if (here != null) {
      context.read<AccidentCubit>().setReportedLocation(
        here.latitude,
        here.longitude,
      );
    }
  }

  void _fillFromTrain(ActiveTrain? train) {
    _locomotive.text = train?.locomotiveNumber ?? '';
    _kilometre.text = train?.kilometerNumber?.toString() ?? '';
  }

  Future<void> _pickTrain(AccidentState state) async {
    final l10n = context.l10n;
    final cubit = context.read<AccidentCubit>();
    final picked = await showAppSheet<ActiveTrain>(
      context: context,
      title: l10n.reportPickTrain,
      subtitle: l10n.reportPickTrainSubtitle,
      closeLabel: l10n.actionClose,
      builder: (_) => _TrainPicker(
        trains: state.trains,
        selected: state.selectedTrain,
        here: _here,
      ),
    );
    if (picked != null) cubit.selectTrain(picked);
  }

  Future<void> _pickDate(DateTime? current) async {
    final cubit = context.read<AccidentCubit>();
    final colors = context.colors;
    final now = DateTime.now();
    final start = current ?? now;
    final day = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: colors.primary,
            onPrimary: colors.onPrimary,
            surface: colors.surface,
            onSurface: colors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (day == null || !mounted) return;
    cubit.setAccidentDateTime(
      DateTime(
        day.year,
        day.month,
        day.day,
        current?.hour ?? now.hour,
        current?.minute ?? now.minute,
      ),
    );
  }

  Future<void> _pickTime(DateTime? current) async {
    final cubit = context.read<AccidentCubit>();
    final now = DateTime.now();
    final start = current ?? now;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null || !mounted) return;
    cubit.setAccidentDateTime(
      DateTime(start.year, start.month, start.day, time.hour, time.minute),
    );
  }

  Future<void> _pickClassification(AccidentState state) async {
    final picked = await showAppSheet<AccidentClass>(
      context: context,
      title: 'Classification',
      closeLabel: context.l10n.actionClose,
      builder: (_) => ClassificationSheet(
        classes: state.accidentClasses,
        selected: state.selectedAccidentClass,
      ),
    );
    if (picked == null || !mounted) return;
    context.read<AccidentCubit>().selectAccidentClass(picked);
  }

  Future<void> _addPhoto() async {
    final l10n = context.l10n;
    final photos = context.read<IncidentPhotosCubit>();
    final fromCamera = await showAppSheet<bool>(
      context: context,
      title: l10n.reportAddPhoto,
      closeLabel: l10n.actionClose,
      builder: (sheet) => AppListGroup(
        children: [
          AppListRow(
            leading: const AppGlyphIcon(AppGlyphs.camera),
            title: l10n.reportTakePhoto,
            onTap: () => Navigator.of(sheet).pop(true),
          ),
          AppListRow(
            leading: const AppGlyphIcon(AppGlyphs.layers),
            title: l10n.reportChoosePhotos,
            onTap: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (fromCamera == null) return;
    fromCamera
        ? await photos.captureFromCamera()
        : await photos.pickFromGallery();
  }

  Future<void> _removePhoto(int index) async {
    final l10n = context.l10n;
    final photos = context.read<IncidentPhotosCubit>();
    final sure = await showAppDialog(
      context: context,
      tone: AppDialogTone.warning,
      title: l10n.reportRemovePhoto,
      primaryLabel: l10n.reportRemove,
      secondaryLabel: l10n.actionCancel,
    );
    if (sure == true) photos.removePhotoAt(index);
  }

  void _reset() {
    context.read<AccidentCubit>()
      ..clearTrain()
      ..setAccidentDateTime(DateTime.now());
    context.read<IncidentPhotosCubit>().clear();
    _remarks.clear();
    _fillFromTrain(null);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final cubit = context.read<AccidentCubit>();
    final photos = context.read<IncidentPhotosCubit>();
    if (!cubit.state.canSubmit) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.info,
        title: l10n.reportMissingTitle,
        message: l10n.reportMissingMessage,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    cubit.setDescription(_remarks.text);
    final sent = await cubit.submitAccident(photos: photos.state.photos);
    if (!mounted) return;
    if (!sent) {
      await showAppDialog(
        context: context,
        tone: AppDialogTone.error,
        title: l10n.reportFailedTitle,
        message: cubit.state.errorMessage ?? l10n.reportFailedMessage,
        primaryLabel: l10n.actionOk,
      );
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const AccidentReportSubmittedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<AccidentCubit, AccidentState>(
      listenWhen: (a, b) => a.selectedTrain != b.selectedTrain,
      listener: (context, state) => _fillFromTrain(state.selectedTrain),
      builder: (context, state) {
        final cubit = context.read<AccidentCubit>();
        final step = state.selectedTrain == null
            ? 0
            : state.selectedAccidentClass == null
            ? 1
            : 2;
        return Scaffold(
          body: AppScrollPage(
            backdrop: AppPageBackdrop.alert,
            controller: widget.scrollController,
            children: [
              AppHeaderBar(
                title: l10n.reportTitle,
                subtitle: l10n.reportSubtitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              AppSpacing.gapLg,
              AppStepHeader(
                steps: [
                  l10n.reportStepTrain,
                  l10n.reportStepWhat,
                  l10n.reportStepPhotos,
                ],
                current: step,
              ),
              AppSpacing.gapMd,
              _LocationCard(here: _here, locating: _locating, onRetry: _locate),
              AppSpacing.gapMd,
              _Section(
                title: l10n.reportTrainAndPlace,
                children: [
                  AppFieldFrame(
                    label: l10n.reportTrain,
                    state: state.selectedTrain == null
                        ? AppFieldState.idle
                        : AppFieldState.focused,
                    trailing: state.status == AccidentStatus.loadingReference
                        ? const SizedBox.square(
                            dimension: AppSizes.iconSm,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppGlyphIcon(AppGlyphs.chevronDown),
                    child: _Tappable(
                      onTap: state.trains.isEmpty
                          ? null
                          : () => _pickTrain(state),
                      child: Text(
                        state.selectedTrain?.displayLabel ??
                            l10n.reportPickTrainHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _locomotive,
                          label: l10n.reportLocomotive,
                          onChanged: cubit.setLocomotive,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: AppTextField(
                          controller: _kilometre,
                          label: l10n.reportKilometre,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (km) =>
                              cubit.setKilometer(double.tryParse(km)),
                        ),
                      ),
                    ],
                  ),
                  AppFieldFrame(
                    label: l10n.reportLastStation,
                    state: AppFieldState.readOnly,
                    trailing: AppTag(l10n.reportFromTrain),
                    child: Text(
                      state.selectedTrain?.lastCrossedStation?.name ?? '–',
                      style: context.textTheme.titleSmall,
                    ),
                  ),
                  AppSelectField<RefDivision>(
                    key: ValueKey('division-${state.divisionId}'),
                    label: l10n.reportDivision,
                    hint: l10n.reportPick,
                    sheetTitle: l10n.reportDivision,
                    options: state.divisions,
                    initialValue: state.selectedDivision,
                    optionLabel: (division) => division.name,
                    onChanged: (division) => cubit.selectDivision(division.id),
                  ),
                  AppSelectField<RefSection>(
                    key: ValueKey(
                      'section-${state.divisionId}-${state.sectionId}',
                    ),
                    label: l10n.reportSection,
                    hint: l10n.reportPick,
                    sheetTitle: l10n.reportSection,
                    options: state.availableSections,
                    initialValue: state.availableSections
                        .where((s) => s.id == state.sectionId)
                        .firstOrNull,
                    optionLabel: (section) => section.name,
                    onChanged: (section) => cubit.selectSection(section.id),
                  ),
                  AppSelectField<RefBlockSection>(
                    key: ValueKey(
                      'block-${state.divisionId}-${state.blockSectionId}',
                    ),
                    label: 'Block Station / Section',
                    hint: l10n.reportPick,
                    sheetTitle: 'Block Station / Section',
                    options: state.availableBlockSections,
                    initialValue: state.availableBlockSections
                        .where((b) => b.id == state.blockSectionId)
                        .firstOrNull,
                    optionLabel: (block) => block.label ?? block.name,
                    onChanged: (block) => cubit.selectBlockSection(block.id),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Tappable(
                          onTap: () => _pickDate(state.accidentDateTime),
                          child: AppFieldFrame(
                            label: 'Incident Date',
                            trailing: const AppGlyphIcon(AppGlyphs.calendar),
                            child: Text(
                              state.accidentDateTime == null
                                  ? 'Select date'
                                  : DateFormat(
                                      'd MMM yyyy',
                                      Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    ).format(state.accidentDateTime!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                color: state.accidentDateTime == null
                                    ? context.colors.textTertiary
                                    : context.colors.textPrimary,
                                fontFeatures: AppFonts.tabularFigures,
                              ),
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapSm,
                      Expanded(
                        child: _Tappable(
                          onTap: () => _pickTime(state.accidentDateTime),
                          child: AppFieldFrame(
                            label: 'Incident Time',
                            trailing: const AppGlyphIcon(AppGlyphs.clock),
                            child: Text(
                              state.accidentDateTime == null
                                  ? 'Select time'
                                  : DateFormat(
                                      'HH:mm',
                                      Localizations.localeOf(
                                        context,
                                      ).toLanguageTag(),
                                    ).format(state.accidentDateTime!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleSmall?.copyWith(
                                color: state.accidentDateTime == null
                                    ? context.colors.textTertiary
                                    : context.colors.textPrimary,
                                fontFeatures: AppFonts.tabularFigures,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapMd,
              _Section(
                title: 'Classification',
                children: [
                  AppFieldFrame(
                    label: 'Accident Type',
                    state: state.selectedAccidentClass == null
                        ? AppFieldState.idle
                        : AppFieldState.focused,
                    trailing: const AppGlyphIcon(AppGlyphs.chevronDown),
                    child: _Tappable(
                      onTap: state.accidentClasses.isEmpty
                          ? null
                          : () => _pickClassification(state),
                      child: Text(
                        state.selectedAccidentClass?.shortMeaning ??
                            'Select accident type',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: state.selectedAccidentClass == null
                              ? context.colors.textTertiary
                              : context.colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  SeverityReadOnlyField(severity: state.severity),
                  AppSpacing.gapMd,
                  Text(
                    'Incident Conditions',
                    style: context.textTheme.labelLarge,
                  ),
                  AppListGroup(
                    children: [
                      _Condition(
                        title: l10n.reportDerailed,
                        about: l10n.reportDerailedAbout,
                        value: state.trainDerailed,
                        onChanged: cubit.setTrainDerailed,
                      ),
                      _Condition(
                        title: l10n.reportFire,
                        about: l10n.reportFireAbout,
                        value: state.hasFire,
                        onChanged: cubit.setHasFire,
                      ),
                      _Condition(
                        title: l10n.reportInjured,
                        about: l10n.reportInjuredAbout,
                        value: state.peopleInjured,
                        onChanged: cubit.setPeopleInjured,
                        expandedChild: AppTextField(
                          controller: _injuredController,
                          label: 'Number of Injured',
                          hint: 'Enter total count',
                          keyboardType: TextInputType.number,
                          onChanged: (v) =>
                              cubit.setInjuredCount(int.tryParse(v) ?? 0),
                        ),
                      ),
                      _Condition(
                        title: l10n.reportDangerousGoods,
                        about: l10n.reportDangerousGoodsAbout,
                        value: state.dangerousGoods,
                        onChanged: cubit.setDangerousGoods,
                      ),
                    ],
                  ),
                ],
              ),
              AppSpacing.gapMd,
              _Section(
                children: [
                  AppTextField(
                    controller: _remarks,
                    label: l10n.reportRemarks,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: cubit.setDescription,
                  ),
                  AppSpacing.gapSm,
                  AppTextField(
                    label: 'Caption (Optional)',
                    hint: 'Enter photo caption',
                    glyph: AppGlyphs.clipboardList,
                    onChanged: cubit.setCaption,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Upload 5 clear photos',
                    style: context.textTheme.titleSmall,
                  ),
                  BlocBuilder<IncidentPhotosCubit, IncidentPhotosState>(
                    builder: (context, photos) => _Photos(
                      photos: photos.photos,
                      busy: photos.isLoading,
                      onAdd: _addPhoto,
                      onRemove: _removePhoto,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: _Actions(
            busy: state.status == AccidentStatus.submitting,
            onReset: _reset,
            onSubmit: _submit,
          ),
        );
      },
    );
  }
}

/// Makes a field's value tappable across the whole field.
class _Tappable extends StatelessWidget {
  const _Tappable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// A card holding one part of the form under its [title].
class _Section extends StatelessWidget {
  const _Section({required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    return DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(title, style: context.textTheme.titleSmall),
              ),
              AppSpacing.gapMd,
            ],
            for (final (i, child) in children.indexed) ...[
              if (i > 0) AppSpacing.gapSm,
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// Where the reporter stands, found on its own: being found, found to so
/// many metres, or not found with a way to try again.
class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.here,
    required this.locating,
    required this.onRetry,
  });

  final Position? here;
  final bool locating;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final here = this.here;
    final (String title, String detail) = switch ((here, locating)) {
      (_, true) => (l10n.reportLocating, l10n.reportLocatingDetail),
      (final at?, _) => (
        l10n.reportLocated,
        l10n.reportLocatedDetail(
          '${at.latitude.abs().toStringAsFixed(2)}° ${at.latitude >= 0 ? 'N' : 'S'}',
          '${at.longitude.abs().toStringAsFixed(2)}° ${at.longitude >= 0 ? 'E' : 'W'}',
          at.accuracy.round(),
        ),
      ),
      _ => (l10n.reportNotLocated, l10n.reportNotLocatedDetail),
    };
    return DecoratedBox(
      decoration: appCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xxs,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AppIconTile(
              size: AppSizes.rowTile,
              child: AppGlyphIcon(
                here == null && !locating
                    ? AppGlyphs.mapPinX
                    : AppGlyphs.mapPin,
                size: AppSizes.iconMd,
                color: colors.iconAccent,
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.labelLarge),
                  Text(
                    detail,
                    style: text.bodySmall?.copyWith(
                      fontFeatures: AppFonts.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapSm,
            if (here != null)
              AppTag(l10n.reportAuto, tone: AppTone.brand)
            else if (!locating)
              AppButton(
                label: l10n.actionRetry,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                expand: false,
                underlined: false,
                onPressed: onRetry,
              ),
          ],
        ),
      ),
    );
  }
}

/// A condition at the scene to tick, with what it means under it.
class _Condition extends StatelessWidget {
  const _Condition({
    required this.title,
    required this.about,
    required this.value,
    required this.onChanged,
    this.expandedChild,
  });

  final String title;
  final String about;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          checked: value,
          child: AppListRow(
            title: title,
            subtitle: about,
            trailing: AppSwitch(value: value, onChanged: onChanged),
            onTap: () => onChanged(!value),
          ),
        ),
        if (value && expandedChild != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md + AppSpacing.xxs,
              0,
              AppSpacing.md + AppSpacing.xxs,
              AppSpacing.md,
            ),
            child: expandedChild,
          ),
        ],
      ],
    );
  }
}

/// The photos taken so far, three to a row, and a dashed tile that adds
/// more. Holding a photo offers to remove it.
class _Photos extends StatelessWidget {
  const _Photos({
    required this.photos,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> photos;
  final bool busy;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return AppGrid(
      columns: 3,
      spacing: AppSpacing.smd,
      children: [
        for (final (i, photo) in photos.indexed)
          Semantics(
            image: true,
            label: l10n.reportPhotoN(i + 1),
            child: GestureDetector(
              onLongPress: () => onRemove(i),
              child: ClipRRect(
                borderRadius: AppRadius.borderLg,
                child: Image.file(
                  photo,
                  height: AppSizes.photoTile,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                ),
              ),
            ),
          ),
        Semantics(
          button: true,
          label: l10n.reportAddPhoto,
          child: InkWell(
            onTap: busy ? null : onAdd,
            borderRadius: AppRadius.borderLg,
            child: CustomPaint(
              foregroundPainter: _DashedBorder(color: colors.outlineStrong),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: AppRadius.borderLg,
                ),
                child: SizedBox(
                  height: AppSizes.photoTile,
                  child: Center(
                    child: busy
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppGlyphIcon(
                                AppGlyphs.camera,
                                size: AppSizes.iconLg,
                                color: colors.iconAccent,
                              ),
                              AppSpacing.gapXxs,
                              Text(
                                l10n.reportAddPhoto,
                                style: text.labelMedium?.copyWith(
                                  color: colors.iconAccent,
                                  fontWeight: AppFonts.semiBold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(AppRadius.borderLg.toRRect(Offset.zero & size).deflate(1));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += AppSizes.dash * 2.5) {
        canvas.drawPath(metric.extractPath(d, d + AppSizes.dash * 1.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Reset and submit, on a frosted bar at the foot of the form.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.busy,
    required this.onReset,
    required this.onSubmit,
  });

  final bool busy;
  final VoidCallback onReset;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.glassStrong,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.reportReset,
                  variant: AppButtonVariant.secondary,
                  onPressed: busy ? null : onReset,
                ),
              ),
              AppSpacing.gapSmd,
              Expanded(
                flex: 2,
                child: AppButton(
                  label: l10n.reportSubmit,
                  isLoading: busy,
                  onPressed: busy ? null : onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trains to pick from, nearest first, with a search; picking one
/// readies the key that uses it.
class _TrainPicker extends StatefulWidget {
  const _TrainPicker({
    required this.trains,
    required this.selected,
    required this.here,
  });

  final List<ActiveTrain> trains;
  final ActiveTrain? selected;
  final Position? here;

  @override
  State<_TrainPicker> createState() => _TrainPickerState();
}

class _TrainPickerState extends State<_TrainPicker> {
  late ActiveTrain? _picked = widget.selected;
  String _query = '';

  /// How far [train] is from the reporter, in kilometres.
  double? _away(ActiveTrain train) {
    final here = widget.here;
    final lat = train.latitude;
    final lon = train.longitude;
    if (here == null || lat == null || lon == null) return null;
    return Geolocator.distanceBetween(here.latitude, here.longitude, lat, lon) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textTheme;
    final query = _query.trim().toLowerCase();
    final trains =
        [
          for (final train in widget.trains)
            if (query.isEmpty ||
                train.displayLabel.toLowerCase().contains(query) ||
                train.trainNumber.toLowerCase().contains(query))
              train,
        ]..sort(
          (a, b) => (_away(a) ?? double.infinity).compareTo(
            _away(b) ?? double.infinity,
          ),
        );
    final picked = _picked;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          hint: l10n.reportSearchTrains,
          onChanged: (query) => setState(() => _query = query),
        ),
        AppSpacing.gapSm,
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final train in trains)
                AppListRow(
                  leading: _TrainCode(
                    code: '${train.trainNumber}${train.direction}',
                  ),
                  title: train.trainName.isEmpty
                      ? train.displayLabel
                      : train.trainName,
                  subtitle: [
                    if (_away(train) case final km?)
                      l10n.reportAway(km.toStringAsFixed(km < 10 ? 1 : 0)),
                    if ((train.location ?? '').isNotEmpty) train.location!,
                  ].join(' · '),
                  trailing: AppRadioMark(
                    selected: picked?.formationId == train.formationId,
                  ),
                  selected: picked?.formationId == train.formationId,
                  onTap: () => setState(() => _picked = train),
                ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        AppButton(
          label: picked == null
              ? l10n.reportPickTrain
              : l10n.reportUseTrain(
                  '${picked.trainNumber}${picked.direction} ${picked.trainName}'
                      .trim(),
                ),
          onPressed: picked == null
              ? null
              : () => Navigator.of(context).pop(picked),
        ),
        if (trains.isEmpty) ...[
          AppSpacing.gapMd,
          Text(
            l10n.reportNoTrains,
            textAlign: TextAlign.center,
            style: text.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// A train's number and direction on a small raised plate, like "1UP".
class _TrainCode extends StatelessWidget {
  const _TrainCode({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderSm,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
        ),
        border: Border.all(color: colors.outline),
      ),
      child: SizedBox(
        width: AppSizes.trainCodeWidth,
        height: AppSizes.trainCodeHeight,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              code,
              style: context.textTheme.labelLarge?.copyWith(
                fontFeatures: AppFonts.tabularFigures,
                fontWeight: AppFonts.semiBold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color severityColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'critical':
      return const Color(0xFFDC2626);
    case 'major':
      return const Color(0xFFEA580C);
    case 'medium':
      return const Color(0xFFD97706);
    case 'minor':
      return const Color(0xFF16A34A);
    default:
      return Colors.grey;
  }
}

class SeverityReadOnlyField extends StatelessWidget {
  final String? severity;
  const SeverityReadOnlyField({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final has = severity != null && severity!.isNotEmpty;
    final color = severityColor(severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppFormStyle.inputRadius),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          if (!has)
            Expanded(
              child: Text(
                'Set automatically from classification',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else ...[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        severity!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
          Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
