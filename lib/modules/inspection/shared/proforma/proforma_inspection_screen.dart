import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/models/login_response.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_repository.dart';
import 'package:railway_hrms/modules/inspection/data/user_stations.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma.dart';
import 'package:railway_hrms/modules/inspection/shared/proforma/proforma_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';
import 'package:railway_hrms/modules/inspection/station/models/station_model.dart';

/// What a proforma's inspection is sent as is made from: what was
/// answered, the sections it asked, and who inspected.
@immutable
class ProformaContext {
  const ProformaContext({
    required this.definition,
    required this.answers,
    required this.sections,
    required this.user,
  });

  final ProformaDefinition definition;
  final ProformaAnswers answers;
  final List<ProformaSection> sections;
  final User? user;

  Object? field(String key) => answers.field(key);

  /// The items' answers, by section and number, as the server takes them.
  Map<String, dynamic> get data =>
      answers.data(sections, noteKey: definition.noteKey);

  /// A field's answer as text, null if blank.
  String? text(String key) {
    final value = answers.field(key)?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }
}

/// An inspection on a proforma: the facts asked first, each section of
/// items as a step, then the result and remarks; its answers, and how it
/// goes out.
@immutable
class ProformaDefinition {
  const ProformaDefinition({
    required this.id,
    required this.title,
    required this.sections,
    this.subtitle,
    this.glyph = AppGlyphs.clipboardList,
    this.header = const [],
    this.closing = const [],
    this.tables = const [],
    this.shows,
    this.prefill,
    this.describe,
    this.api,
    this.payload,
    this.noteKey = 'observation',
    this.noteLabel,
  });

  /// Its draft's key, and how a saved one is opened again.
  final String id;
  final String title;
  final String? subtitle;
  final AppGlyph glyph;

  /// Asked first, as what is inspected and where.
  final List<ProformaField> header;
  final List<ProformaSection> sections;

  /// Asked last, as the result and remarks; with [tables] before them.
  final List<ProformaField> closing;
  final List<ProformaTable> tables;

  /// Whether [section] is asked, given what is answered, as only the
  /// areas picked; all are when not given.
  final bool Function(ProformaSection section, ProformaAnswers answers)? shows;

  /// The facts filled in for a new inspection, as who is inspecting.
  final Map<String, Object?> Function(User? user)? prefill;

  /// What is inspected, in a few words, as "GEU-40 · 4005".
  final String? Function(ProformaAnswers answers)? describe;

  /// Where it goes; kept on the phone when not given.
  final InspectionApi? api;

  /// The inspection as the server takes it, without the face checks.
  final Map<String, dynamic> Function(ProformaContext context)? payload;

  /// What a note on an item is sent as, and called on the form.
  final String noteKey;
  final String? noteLabel;

  List<ProformaSection> sectionsFor(ProformaAnswers answers) => [
    for (final section in sections)
      if (shows?.call(section, answers) ?? true) section,
  ];

  String get draftId => 'proforma_$id';
}

/// An inspection on a proforma: the face first, then its steps, and its
/// report to read, sign with the face again and send, or keep on the
/// phone where the inspection has no server yet. Left part-way, it opens
/// again where it was left.
class ProformaInspectionScreen extends StatelessWidget {
  const ProformaInspectionScreen({
    super.key,
    required this.definition,
    this.verifier,
  });

  final ProformaDefinition definition;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: definition.title,
    verifier: verifier,
    child: _ProformaForm(definition: definition, verifier: verifier),
  );
}

class _ProformaForm extends StatefulWidget {
  const _ProformaForm({required this.definition, this.verifier});

  final ProformaDefinition definition;
  final InspectionFaceVerifier? verifier;

  @override
  State<_ProformaForm> createState() => _ProformaFormState();
}

class _ProformaFormState extends State<_ProformaForm> {
  ProformaAnswers _answers = ProformaAnswers();
  DateTime _startedAt = DateTime.now();
  User? _user;
  bool _ready = false;
  bool _dirty = false;
  Timer? _autosave;

  List<StationItem> _stations = const [];
  String? _stationsError;
  bool _loadingStations = false;

  ProformaDefinition get _definition => widget.definition;

  bool get _asksStation => [
    ..._definition.header,
    ..._definition.closing,
  ].any((field) => field.kind == ProformaFieldKind.station);

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void dispose() {
    _autosave?.cancel();
    super.dispose();
  }

  Future<void> _open() async {
    _user = (await StorageService.getUser())?.user;
    final raw = await StorageService.getInspectionDraft(_definition.draftId);
    var resumed = false;
    if (raw != null && raw.isNotEmpty) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        _answers = ProformaAnswers.fromJson(saved['answers']);
        _startedAt =
            DateTime.tryParse('${saved['startedAt'] ?? ''}') ?? _startedAt;
        resumed = true;
      } on Object catch (e) {
        debugPrint('Proforma draft could not be read: $e');
      }
    }
    if (!resumed) {
      for (final MapEntry(:key, :value)
          in (_definition.prefill?.call(_user) ?? const {}).entries) {
        _answers.setField(key, value);
      }
    }
    if (!mounted) return;
    setState(() => _ready = true);
    if (_asksStation) await _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _loadingStations = true;
      _stationsError = null;
    });
    final loaded = await UserStations.load(
      sl<InspectionRepository>(),
      section: _user?.section,
    );
    if (!mounted) return;
    setState(() {
      _loadingStations = false;
      _stations = loaded.stations;
      _stationsError = loaded.error;
      // The only station there is needs no picking.
      for (final field in _definition.header) {
        if (field.kind == ProformaFieldKind.station &&
            _answers.field(field.key) == null &&
            _stations.length == 1) {
          _answers
            ..setField(field.key, _stations.single.id)
            ..setField('${field.key}_name', _stations.single.displayLabel);
        }
      }
    });
  }

  int _lastSectionsCount = 0;

  void _changed() {
    final count = _sections.length;
    final sectionsChanged = count != _lastSectionsCount;
    _lastSectionsCount = count;
    if (!_dirty || sectionsChanged) {
      setState(() => _dirty = true);
    }
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  List<ProformaSection> get _sections => _definition.sectionsFor(_answers);

  bool get _closes =>
      _definition.closing.isNotEmpty || _definition.tables.isNotEmpty;

  String? get _described => _definition.describe?.call(_answers);

  Future<void> _saveDraft() async {
    _autosave?.cancel();
    if (_answers.isEmpty) return;
    await StorageService.saveInspectionDraft(
      _definition.draftId,
      jsonEncode({
        'answers': _answers.toJson(),
        'startedAt': _startedAt.toIso8601String(),
      }),
    );
    var answered = 0;
    var total = 0;
    for (final section in _sections) {
      final (a, t) = _answers.progress(section);
      answered += a;
      total += t;
    }
    await StorageService.saveInspectionRecord({
      'id': _definition.draftId,
      'status': 'in_progress',
      'train': [_definition.title, ?_described].join(' · '),
      'date': DateTime.now().toIso8601String(),
      'progress': total == 0 ? 0 : answered / total,
      'payload': {'type': 'proforma', 'proforma': _definition.id},
    });
  }

  bool _blank(ProformaField field) {
    final value = _answers.field(field.key);
    return value == null || (value is List && value.isEmpty);
  }

  /// [fields] asked, given what is answered.
  List<ProformaField> _asked(List<ProformaField> fields) => [
    for (final field in fields)
      if (field.asks(_answers)) field,
  ];

  List<String> _missing() => [
    for (final field in _asked([..._definition.header, ..._definition.closing]))
      if (field.required && _blank(field)) field.label,
  ];

  String _shown(ProformaField field) {
    final value = _answers.field(field.key);
    String? labelOf(Object? code) {
      for (final option in field.options) {
        if (option.code == code) return option.label;
      }
      return code?.toString();
    }

    return switch (field.kind) {
      ProformaFieldKind.station =>
        _answers.field('${field.key}_name')?.toString() ?? '',
      ProformaFieldKind.date => switch (DateTime.tryParse('${value ?? ''}')) {
        final day? => displayValue(day),
        null => '',
      },
      ProformaFieldKind.choice => labelOf(value) ?? '',
      ProformaFieldKind.multi =>
        value is List ? value.map(labelOf).nonNulls.join(', ') : '',
      _ => value?.toString() ?? '',
    };
  }

  InspectionReport _report() {
    final sections = _sections;
    final day = DateTime.tryParse('${_answers.field('inspection_date') ?? ''}');
    return InspectionReport(
      title: _definition.title,
      subtitle: _described ?? _definition.subtitle,
      date: day ?? _startedAt,
      facts: [
        for (final field in _asked(_definition.header))
          ReportRow(field.label, _shown(field), tone: ReportTone.plain),
      ],
      sections: [
        ..._answers.report(
          sections,
          firstStep: 1,
          date: (day) => displayValue(day),
        ),
        if (_closes)
          ReportSection(
            title: context.l10n.inspFormFinish,
            step: sections.length + 1,
            rows: [
              for (final table in _definition.tables)
                for (final (n, row) in _answers.rowsOf(table.key).indexed)
                  ReportRow(
                    '${table.item} ${n + 1}',
                    [
                      for (final column in table.columns)
                        if (row[column.key] case final value?)
                          column.kind == ProformaFieldKind.date
                              ? displayValue(DateTime.tryParse('$value'))
                              : '$value',
                    ].join(' · '),
                    tone: ReportTone.plain,
                  ),
              for (final field in _asked(_definition.closing))
                ReportRow(field.label, _shown(field)),
            ],
          ),
      ],
    );
  }

  Future<void> _review() async {
    final l10n = context.l10n;
    final definition = _definition;
    await _saveDraft();
    if (!mounted) return;
    final api = definition.api;
    final payload = definition.payload;
    final id = '${definition.id}-${DateTime.now().millisecondsSinceEpoch}';
    final sections = _sections;
    final described = _described;
    final kept = await reviewAndSubmit(
      context,
      verifier: widget.verifier,
      report: _report(),
      send: api == null || payload == null
          ? null
          : (signatures) => OutboxItem(
              id: id,
              api: api,
              title: definition.title,
              subtitle: described,
              queuedAt: DateTime.now(),
              signatures: signatures,
              payload: payload(
                ProformaContext(
                  definition: definition,
                  answers: _answers,
                  sections: sections,
                  user: _user,
                ),
              ),
            ),
      submit: api != null && payload != null
          ? null
          : (signatures) async {
              await _complete(signatures: signatures.toJson());
              return Right(l10n.inspFormSavedLocally);
            },
    );
    if (!kept || !mounted) return;
    if (api != null && payload != null) await _complete();
    if (mounted) Navigator.of(context).pop();
  }

  /// Takes the draft away and keeps the finished inspection among those
  /// done.
  Future<void> _complete({Map<String, dynamic>? signatures}) async {
    final definition = _definition;
    final finishedAt = DateTime.now();
    await StorageService.deleteInspectionRecord(definition.draftId);
    await StorageService.saveInspectionRecord({
      'id': '${definition.draftId}_${finishedAt.millisecondsSinceEpoch}',
      'status': 'completed',
      'train': [definition.title, ?_described].join(' · '),
      'date': finishedAt.toIso8601String(),
      'payload': {
        'type': 'proforma',
        'proforma': definition.id,
        'answers': _answers.toJson(),
        ...?signatures,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final definition = _definition;
    if (!_ready) return const Scaffold(body: Center(child: AppLoader()));
    final sections = _sections;
    Widget field(ProformaField field) => ProformaFieldInput(
      field: field,
      answers: _answers,
      onChanged: _changed,
      stations: _stations,
      stationsError: _stationsError,
      loadingStations: _loadingStations,
      onRetryStations: _loadStations,
    );
    int answeredOf(List<ProformaField> fields) =>
        fields.where((field) => !_blank(field)).length;
    return InspectionFormScaffold(
      title: definition.title,
      subtitle: _described ?? definition.subtitle,
      initialStep: _answers.step,
      dirty: _dirty || !_answers.isEmpty,
      onLeave: _saveDraft,
      onStepChanged: (step) {
        _answers.step = step;
        unawaited(_saveDraft());
      },
      missing: _missing,
      onReview: _review,
      steps: [
        InspectionStep(
          title: l10n.inspFormDetails,
          total: _asked(definition.header).length,
          answered: answeredOf(_asked(definition.header)),
          builder: (_) => InspectionCard(
            title: definition.title,
            subtitle: definition.subtitle,
            glyph: definition.glyph,
            children: [for (final f in _asked(definition.header)) field(f)],
          ),
        ),
        for (final section in sections)
          if (_answers.progress(section) case (final answered, final total))
            InspectionStep(
              title: section.title,
              total: total,
              answered: answered,
              builder: (_) => ProformaSectionBody(
                section: section,
                answers: _answers,
                glyph: definition.glyph,
                noteLabel: definition.noteLabel,
                onChanged: _changed,
              ),
            ),
        if (_closes)
          InspectionStep(
            title: l10n.inspFormFinish,
            total: _asked(definition.closing).length,
            answered: answeredOf(_asked(definition.closing)),
            builder: (_) => InspectionCard(
              title: l10n.inspFormFinish,
              glyph: AppGlyphs.fileEdit,
              children: [
                for (final table in definition.tables)
                  ProformaTableBody(
                    table: table,
                    answers: _answers,
                    onChanged: _changed,
                  ),
                for (final f in _asked(definition.closing)) field(f),
                if (_faults(sections) case final faults when faults > 0)
                  InspectionFieldNote(
                    text: l10n.inspFormFaultsFound(faults),
                    warning: true,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  int _faults(List<ProformaSection> sections) =>
      sections.fold(0, (sum, section) => sum + _answers.faults(section));
}
