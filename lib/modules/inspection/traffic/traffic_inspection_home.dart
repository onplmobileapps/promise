import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/report/inspection_report.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';
import 'package:railway_hrms/modules/inspection/traffic/models.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_forms.dart';
import 'package:railway_hrms/modules/inspection/traffic/traffic_report.dart';

enum _FormKind { commercialStation, transportStation, levelCrossing }

/// A traffic inspection of a station: the face first, then the forms the
/// commercial and transport departments conduct, each step by step and
/// each ending in its signed report, kept on the phone.
///
/// The commercial and transport station forms both ask after the same
/// safety equipment on the same visit. The visit holds that answer once,
/// so the second department to open its form sees it, answered, instead of
/// asking again.
class TrafficInspectionHome extends StatelessWidget {
  const TrafficInspectionHome({
    super.key,
    required this.stationName,
    this.resumeId,
    this.verifier,
  });

  final String stationName;
  final String? resumeId;

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: context.l10n.inspTrafficTitle,
    verifier: verifier,
    child: _TrafficVisit(
      stationName: stationName,
      resumeId: resumeId,
      verifier: verifier,
    ),
  );
}

class _TrafficVisit extends StatefulWidget {
  const _TrafficVisit({
    required this.stationName,
    required this.resumeId,
    required this.verifier,
  });

  final String stationName;
  final String? resumeId;
  final InspectionFaceVerifier? verifier;

  @override
  State<_TrafficVisit> createState() => _TrafficVisitState();
}

class _TrafficVisitState extends State<_TrafficVisit> {
  late final String _id =
      widget.resumeId ?? 'traffic-${DateTime.now().millisecondsSinceEpoch}';
  final _commercial = TrafficCommercialStationData();
  final _transport = TrafficTransportStationData();
  final List<LevelCrossingRecord> _crossings = [];

  /// The forms already sent this visit.
  final Set<String> _done = {};

  /// The step each form was left on.
  final Map<String, int> _steps = {};
  bool _ready = false;
  Timer? _autosave;

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
    final raw = await StorageService.getInspectionDraft(_id);
    if (raw != null && raw.isNotEmpty) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        _commercial.fromJson(
          Map<String, dynamic>.from(saved['commercial'] as Map? ?? {}),
        );
        _transport.fromJson(
          Map<String, dynamic>.from(saved['transport'] as Map? ?? {}),
        );
        for (final lc in saved['levelCrossings'] as List? ?? const []) {
          _crossings.add(
            LevelCrossingRecord.fromJson(Map<String, dynamic>.from(lc as Map)),
          );
        }
        _done.addAll([
          for (final kind in saved['done'] as List? ?? []) '$kind',
        ]);
        _steps.addAll({
          for (final MapEntry(:key, :value)
              in (saved['steps'] as Map? ?? const {}).entries)
            if (value is num) '$key': value.toInt(),
        });
      } on Object catch (e) {
        debugPrint('Traffic draft could not be read: $e');
      }
    }
    if (_crossings.isEmpty) _crossings.add(LevelCrossingRecord());
    if (mounted) setState(() => _ready = true);
  }

  Map<String, dynamic> get _payload => {
    'id': _id,
    'type': 'traffic',
    'stationName': widget.stationName,
    'commercial': _commercial.toJson(),
    'transport': _transport.toJson(),
    'levelCrossings': [for (final lc in _crossings) lc.toJson()],
    'done': _done.toList(),
    'steps': _steps,
  };

  void _changed() {
    if (mounted) setState(() {});
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    _autosave?.cancel();
    final payload = _payload;
    await StorageService.saveInspectionDraft(_id, jsonEncode(payload));
    await StorageService.saveInspectionRecord({
      'id': _id,
      'status': 'in_progress',
      'train': '${widget.stationName} (Traffic)',
      'date': DateTime.now().toIso8601String(),
      'payload': payload,
    });
  }

  bool get _commercialShared =>
      _commercial.safetyEquipmentCondition.answers.isNotEmpty;
  bool get _transportShared =>
      _transport.staffEquipmentCondition.answers.isNotEmpty;

  String _title(AppLocalizations l10n, _FormKind kind) => switch (kind) {
    _FormKind.commercialStation => l10n.inspTrafficCommercial,
    _FormKind.transportStation => l10n.inspTrafficTransport,
    _FormKind.levelCrossing => l10n.inspTrafficLevelCrossing,
  };

  Future<void> _openForm(_FormKind kind) async {
    final l10n = context.l10n;
    final title = _title(l10n, kind);
    await pushInspectionPage<void>(
      context,
      (_) => _TrafficForm(
        title: title,
        subtitle: widget.stationName,
        verifier: widget.verifier,
        steps: (changed) => switch (kind) {
          _FormKind.commercialStation => commercialSteps(
            _commercial,
            changed,
            sharedAnswered: !_commercialShared && _transportShared,
          ),
          _FormKind.transportStation => transportSteps(
            _transport,
            changed,
            sharedAnswered: !_transportShared && _commercialShared,
            addCautionOrder: (code) =>
                _transport.cautionOrders.of(code, defaultChecked: false),
          ),
          _FormKind.levelCrossing => levelCrossingSteps(_crossings, changed),
        },
        report: () => InspectionReport(
          title: '${l10n.inspTrafficTitle} · $title',
          subtitle: widget.stationName,
          date: DateTime.now(),
          facts: [
            ReportRow(
              l10n.inspFormStation,
              widget.stationName,
              tone: ReportTone.plain,
            ),
          ],
          sections: switch (kind) {
            _FormKind.commercialStation => commercialReport(_commercial),
            _FormKind.transportStation => transportReport(_transport),
            _FormKind.levelCrossing => levelCrossingReport(_crossings),
          },
        ),
        onChanged: _changed,
        onLeave: _save,
        initialStep: _steps[kind.name] ?? 0,
        onStepChanged: (step) {
          _steps[kind.name] = step;
          _changed();
        },
        onKept: (signatures) async {
          _done.add(kind.name);
          await _save();
          await StorageService.saveInspectionRecord({
            'id': '${_id}_${kind.name}',
            'status': 'completed',
            'train': '${widget.stationName} · $title',
            'date': DateTime.now().toIso8601String(),
            'payload': {..._payload, 'form': kind.name, ...signatures},
          });
        },
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    if (!_ready) return const Scaffold(body: Center(child: AppLoader()));
    Widget form(_FormKind kind, String about, AppGlyph glyph) => AppListRow(
      leading: AppIconTile(
        size: AppSizes.rowTile,
        child: AppGlyphIcon(
          glyph,
          size: AppSizes.iconMd,
          color: colors.iconAccent,
          depth: true,
        ),
      ),
      title: _title(l10n, kind),
      subtitle: about,
      trailing: _done.contains(kind.name)
          ? AppPill(l10n.inspFormSaved, dot: colors.success)
          : null,
      showChevron: !_done.contains(kind.name),
      onTap: () => _openForm(kind),
    );
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.inspTrafficTitle,
            subtitle: widget.stationName,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapXl,
          AppSectionLabel(l10n.inspTrafficChoose),
          AppSpacing.gapSm,
          AppListGroup(
            children: [
              form(
                _FormKind.commercialStation,
                l10n.inspTrafficCommercialAbout,
                AppGlyphs.briefcase,
              ),
              form(
                _FormKind.transportStation,
                l10n.inspTrafficTransportAbout,
                AppGlyphs.route,
              ),
              form(
                _FormKind.levelCrossing,
                l10n.inspTrafficLevelCrossingAbout,
                AppGlyphs.triangleAlert,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One traffic form, step by step, ending in its signed report.
class _TrafficForm extends StatefulWidget {
  const _TrafficForm({
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.report,
    required this.onChanged,
    required this.onLeave,
    required this.onKept,
    this.initialStep = 0,
    this.onStepChanged,
    this.verifier,
  });

  final String title;
  final String subtitle;
  final List<InspectionStep> Function(VoidCallback changed) steps;
  final InspectionReport Function() report;
  final VoidCallback onChanged;
  final Future<void> Function() onLeave;

  /// Keeps the finished form, signed.
  final Future<void> Function(Map<String, dynamic> signatures) onKept;
  final int initialStep;
  final ValueChanged<int>? onStepChanged;
  final InspectionFaceVerifier? verifier;

  @override
  State<_TrafficForm> createState() => _TrafficFormState();
}

class _TrafficFormState extends State<_TrafficForm> {
  bool _dirty = false;

  void _changed() {
    setState(() => _dirty = true);
    widget.onChanged();
  }

  Future<void> _review() async {
    final l10n = context.l10n;
    await widget.onLeave();
    if (!mounted) return;
    final kept = await reviewAndSubmit(
      context,
      verifier: widget.verifier,
      report: widget.report(),
      submit: (signatures) async {
        await widget.onKept(signatures.toJson());
        return Right(l10n.inspFormSavedLocally);
      },
    );
    if (kept && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => InspectionFormScaffold(
    title: widget.title,
    subtitle: widget.subtitle,
    dirty: _dirty,
    onLeave: widget.onLeave,
    onReview: _review,
    initialStep: widget.initialStep,
    onStepChanged: widget.onStepChanged,
    steps: widget.steps(_changed),
  );
}
