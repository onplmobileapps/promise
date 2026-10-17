import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/inspection_history.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';
import 'package:railway_hrms/modules/inspection/station/controller.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_inspection_payload.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';
import 'package:railway_hrms/modules/inspection/station/section_data.dart';
import 'package:railway_hrms/modules/inspection/station/station_report.dart';
import 'package:railway_hrms/modules/inspection/station/widgets/station_fields.dart';

/// A station's signal and telecom inspection: the inspector's face first,
/// then the station and every section, step by step, and its report to
/// read, sign with the face again and send.
class StationInspectionScreen extends StatelessWidget {
  const StationInspectionScreen({super.key, this.verifier});

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: context.l10n.inspStationTitle,
    verifier: verifier,
    child: _StationForm(verifier: verifier),
  );
}

class _StationForm extends StatefulWidget {
  const _StationForm({this.verifier});

  final InspectionFaceVerifier? verifier;

  @override
  State<_StationForm> createState() => _StationFormState();
}

class _StationFormState extends State<_StationForm> {
  final _form = StationInspectionController();
  LoginResponse? _user;
  bool _ready = false;

  List<StationItem> _stations = const [];
  String? _stationsError;
  bool _loadingStations = true;

  /// Saves the draft a moment after the last change, not on every key.
  Timer? _autosave;

  @override
  void initState() {
    super.initState();
    _form.addListener(_changed);
    unawaited(_open());
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _form
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Future<void> _open() async {
    _user = await StorageService.getUser();
    await _form.loadDraftFromDisk();
    if (!mounted) return;
    setState(() => _ready = true);
    await _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loadingStations = true;
      _stationsError = null;
    });
    final result = await sl<InspectionRepository>().getUserStations(
      section: _user?.user?.section,
    );
    if (!mounted) return;
    setState(() {
      _loadingStations = false;
      result.fold((error) => _stationsError = error.message, (stations) {
        _stations = stations;
        final chosen = _chosen;
        if (chosen != null) {
          // A draft's station, named as the server names it now.
          _form.setStation(chosen.displayLabel, id: chosen.id);
        } else if (stations.length == 1) {
          _form.setStation(
            stations.single.displayLabel,
            id: stations.single.id,
          );
        }
      });
    });
  }

  StationItem? get _chosen {
    final id = _form.stationId;
    final name = _form.station;
    for (final station in _stations) {
      if ((id != null && station.id == id) ||
          (id == null &&
              (station.displayLabel == name || station.name == name))) {
        return station;
      }
    }
    return null;
  }

  void _changed() {
    setState(() {});
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    _autosave?.cancel();
    if (!_form.hasAnswers && _form.stationId == null) return;
    await _form.saveDraftToDisk();
    await StorageService.saveInspectionRecord({
      'id': StationInspectionController.draftId,
      'train': 'Station inspection · ${_form.station ?? '—'}',
      'date': DateTime.now().toIso8601String(),
      'status': 'in_progress',
      'progress': _form.overallProgress(kInspectionSections),
      'payload': {'type': 'station', 'stationName': _form.station},
    });
  }

  Future<void> _review() async {
    final l10n = context.l10n;
    _autosave?.cancel();
    await _saveDraft();
    if (!mounted) return;
    final id = 'station-${DateTime.now().millisecondsSinceEpoch}';
    final sent = await reviewAndSubmit(
      context,
      verifier: widget.verifier,
      report: stationReport(
        _form,
        title: l10n.inspStationTitle,
        stationLabel: l10n.inspFormStation,
        dateLabel: l10n.inspFormDate,
      ),
      send: (signatures) => OutboxItem(
        id: id,
        api: InspectionApi.station,
        title: l10n.inspStationTitle,
        subtitle: _form.station,
        queuedAt: DateTime.now(),
        signatures: signatures,
        payload: StationInspectionPayload.build(
          _form,
          stationId: _form.stationId,
          user: _user,
        ),
      ),
    );
    if (!sent || !mounted) return;
    await _form.clearDraftFromDisk();
    await keepFinishedInspection(
      type: 'station',
      title: '${l10n.inspStationTitle} · ${_form.station ?? ''}',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_ready) {
      return const Scaffold(body: Center(child: AppLoader()));
    }
    return InspectionFormScaffold(
      title: l10n.inspStationTitle,
      subtitle: _form.station ?? l10n.inspStationSubtitle,
      initialStep: _form.currentStep,
      dirty: _form.hasAnswers,
      onLeave: _saveDraft,
      onStepChanged: (step) {
        _form.currentStep = step;
        unawaited(_saveDraft());
      },
      missing: () => [if (_form.stationId == null) l10n.inspFormStation],
      onReview: _review,
      steps: [
        InspectionStep(
          title: l10n.inspFormDetails,
          total: 1,
          answered: _form.stationId == null ? 0 : 1,
          builder: (_) => _Details(
            form: _form,
            stations: _stations,
            chosen: _chosen,
            loading: _loadingStations,
            error: _stationsError,
            onRetry: _loadStations,
          ),
        ),
        for (final section in kInspectionSections)
          if (_form.sectionFillProgress(section) case (
            final filled,
            final total,
          ))
            InspectionStep(
              title: section.title,
              total: total,
              answered: filled,
              builder: (_) => StationSectionBody(section: section, form: _form),
            ),
      ],
    );
  }
}

/// What is inspected and when: the station, from those the inspector
/// covers, and the day.
class _Details extends StatelessWidget {
  const _Details({
    required this.form,
    required this.stations,
    required this.chosen,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final StationInspectionController form;
  final List<StationItem> stations;
  final StationItem? chosen;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final error = this.error;
    final now = DateTime.now();
    final Widget station;
    if (loading) {
      station = AppFieldFrame(
        label: l10n.inspFormStation,
        glyph: AppGlyphs.station,
        trailing: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: AppLoader(size: AppSizes.loaderSmall),
        ),
        child: Text(
          form.station ?? l10n.inspFormStationHint,
          style: TextStyle(color: colors.textTertiary),
        ),
      );
    } else if (error != null || stations.isEmpty) {
      station = AppEmptyState(
        glyph: AppGlyphs.station,
        title: error == null
            ? l10n.inspFormNoStations
            : l10n.inspFormStationsFailed,
        message: error,
      );
    } else {
      station = AppSelectField<StationItem>(
        key: ValueKey(chosen?.id),
        label: l10n.inspFormStation,
        hint: l10n.inspFormStationHint,
        sheetTitle: l10n.inspFormStation,
        glyph: AppGlyphs.station,
        options: stations,
        initialValue: chosen,
        optionLabel: (item) => item.displayLabel,
        onChanged: (item) => form.setStation(item.displayLabel, id: item.id),
      );
    }
    return InspectionCard(
      title: l10n.inspFormDetails,
      subtitle: l10n.inspStationSubtitle,
      glyph: AppGlyphs.clipboardList,
      children: [
        station,
        if (!loading && (error != null || stations.isEmpty))
          AppButton(
            label: l10n.actionRetry,
            variant: AppButtonVariant.secondary,
            leadingGlyph: AppGlyphs.refresh,
            onPressed: onRetry,
          ),
        InspectionDateInput(
          label: l10n.inspFormDate,
          value: form.inspDate,
          firstDate: now.subtract(const Duration(days: 60)),
          lastDate: now,
          onChanged: form.setDate,
        ),
      ],
    );
  }
}
