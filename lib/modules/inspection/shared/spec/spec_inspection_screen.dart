import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_identity.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/form_spec.dart';
import 'package:railway_hrms/modules/inspection/shared/spec/spec_form.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';

/// A draft of a form described as data: its answers, and when it began.
typedef SpecDraft = ({Map<String, dynamic> answers, DateTime startedAt});

/// Where a form described as data keeps its answers: its draft while it is
/// filled in, and the finished inspection, signed.
abstract interface class SpecFormStore {
  Future<SpecDraft?> load();

  Future<void> saveDraft(Map<String, dynamic> answers, DateTime startedAt);

  Future<void> complete(
    Map<String, dynamic> answers,
    DateTime startedAt,
    InspectionSignatures signatures,
  );
}

/// An inspection whose questions are described as data, as the civil and
/// electrical assets': the face first, then each section as a step, and
/// the report to read, sign with the face again and keep.
class SpecInspectionScreen extends StatelessWidget {
  const SpecInspectionScreen({
    super.key,
    required this.title,
    required this.specs,
    required this.store,
    this.subtitle,
    this.facts = const [],
    this.glyph = AppGlyphs.clipboardList,
    this.verifier,
  });

  final String title;
  final String? subtitle;
  final List<FormSpec> specs;
  final SpecFormStore store;

  /// What is inspected, shown over the steps and at the head of the report.
  final List<(String, String)> facts;
  final AppGlyph glyph;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: title,
    verifier: verifier,
    child: _SpecForm(screen: this),
  );
}

class _SpecForm extends StatefulWidget {
  const _SpecForm({required this.screen});

  final SpecInspectionScreen screen;

  @override
  State<_SpecForm> createState() => _SpecFormState();
}

class _SpecFormState extends State<_SpecForm> {
  final SpecAnswers _answers = SpecAnswers();
  DateTime _startedAt = DateTime.now();
  bool _ready = false;
  int _step = 0;
  Timer? _autosave;

  late final List<SpecPart> _parts = specParts(
    widget.screen.specs,
    first: widget.screen.title,
  );

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
    final draft = await widget.screen.store.load();
    if (draft != null) {
      _answers.values.addAll(draft.answers);
      _startedAt = draft.startedAt;
    }
    if (mounted) setState(() => _ready = true);
  }

  bool get _dirty => _answers.values.values.any(
    (v) => v != null && v.toString().trim().isNotEmpty,
  );

  void _changed() {
    setState(() {});
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    _autosave?.cancel();
    if (!_dirty) return;
    await widget.screen.store.saveDraft(_answers.values, _startedAt);
  }

  InspectionReport _report() => InspectionReport(
    title: widget.screen.title,
    subtitle: widget.screen.subtitle,
    date: _startedAt,
    facts: [
      for (final (label, value) in widget.screen.facts)
        ReportRow(label, value, tone: ReportTone.plain),
    ],
    sections: [
      for (final part in _parts)
        ReportSection(title: part.title, rows: _answers.rows(part.specs)),
    ],
  );

  Future<void> _review() async {
    final l10n = context.l10n;
    final store = widget.screen.store;
    await _saveDraft();
    if (!mounted) return;
    final kept = await reviewAndSubmit(
      context,
      verifier: widget.screen.verifier,
      report: _report(),
      submit: (signatures) async {
        await store.complete(_answers.values, _startedAt, signatures);
        return Right(l10n.inspFormSavedLocally);
      },
    );
    if (kept && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screen = widget.screen;
    if (!_ready) return const Scaffold(body: Center(child: AppLoader()));
    return InspectionFormScaffold(
      title: screen.title,
      subtitle: screen.subtitle,
      initialStep: _step,
      dirty: _dirty,
      onLeave: _saveDraft,
      onStepChanged: (step) {
        _step = step;
        unawaited(_saveDraft());
      },
      onReview: _review,
      header: screen.facts.isEmpty
          ? null
          : InspectionCard(
              title: l10n.inspFormAsset,
              glyph: screen.glyph,
              children: [InspectionFacts(screen.facts)],
            ),
      steps: [
        for (final part in _parts)
          if (_answers.progress(part.specs) case (final answered, final total))
            InspectionStep(
              title: part.title,
              total: total,
              answered: answered,
              builder: (_) => SpecPartBody(
                part: part,
                answers: _answers,
                glyph: screen.glyph,
                onChanged: (key, value) {
                  _answers.values[key] = value;
                  _changed();
                },
                onRepeat: _changed,
              ),
            ),
      ],
    );
  }
}
