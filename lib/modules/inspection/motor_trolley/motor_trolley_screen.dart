import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/inspection/data/inspection_api.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_form.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/models/trolley_payload.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_cubit.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/motor_trolley_state.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/trolley_report.dart';
import 'package:railway_hrms/modules/inspection/motor_trolley/widgets/trolley_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_review_screen.dart';
import 'package:railway_hrms/modules/inspection/shared/flow/inspection_session.dart';
import 'package:railway_hrms/modules/inspection/shared/identity/inspection_face_verifier.dart';
import 'package:railway_hrms/modules/inspection/shared/outbox/inspection_outbox.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_fields.dart';
import 'package:railway_hrms/modules/inspection/shared/widgets/inspection_form_scaffold.dart';

/// A motor trolley run over a section: the inspector's face first, then
/// the track, curves, points, bridges, crossings and works step by step,
/// and its report to read, sign with the face again and send.
class MotorTrolleyInspectionScreen extends StatelessWidget {
  const MotorTrolleyInspectionScreen({super.key, this.verifier});

  /// Checks the face; the app's own unless a test stands in.
  final InspectionFaceVerifier? verifier;

  @override
  Widget build(BuildContext context) => InspectionStartGate(
    title: context.l10n.inspTrolleyTitle,
    verifier: verifier,
    child: BlocProvider(
      create: (_) => MotorTrolleyInspectionCubit(),
      child: _TrolleyForm(verifier: verifier),
    ),
  );
}

class _TrolleyForm extends StatefulWidget {
  const _TrolleyForm({this.verifier});

  final InspectionFaceVerifier? verifier;

  @override
  State<_TrolleyForm> createState() => _TrolleyFormState();
}

class _TrolleyFormState extends State<_TrolleyForm> {
  bool _ready = false;
  Timer? _autosave;

  MotorTrolleyInspectionCubit get _cubit =>
      context.read<MotorTrolleyInspectionCubit>();

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
    await _cubit.loadDraft();
    if (mounted) setState(() => _ready = true);
  }

  void _set(String key, String value) {
    _cubit.set(key, value);
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), _cubit.saveDraft);
  }

  Future<void> _review() async {
    final l10n = context.l10n;
    final cubit = _cubit;
    _autosave?.cancel();
    await cubit.saveDraft();
    if (!mounted) return;
    final id = 'trolley-${DateTime.now().millisecondsSinceEpoch}';
    final report = trolleyReport(
      cubit.state,
      title: l10n.inspTrolleyTitle,
      sectionLabel: l10n.inspFormSection,
      dateLabel: l10n.inspFormDate,
    );
    final sent = await reviewAndSubmit(
      context,
      verifier: widget.verifier,
      report: report,
      send: (signatures) => OutboxItem(
        id: id,
        api: InspectionApi.motorTrolley,
        title: l10n.inspTrolleyTitle,
        subtitle: report.subtitle,
        queuedAt: DateTime.now(),
        signatures: signatures,
        payload: TrolleyInspectionPayload.build(cubit.state),
      ),
    );
    if (!sent || !mounted) return;
    await cubit.clearDraft();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!_ready) return const Scaffold(body: Center(child: AppLoader()));
    return BlocBuilder<
      MotorTrolleyInspectionCubit,
      MotorTrolleyInspectionState
    >(
      builder: (context, state) {
        final from = state.value('sectionFrom')?.trim() ?? '';
        final to = state.value('sectionTo')?.trim() ?? '';
        final section = [from, to].where((s) => s.isNotEmpty).join(' – ');
        return InspectionFormScaffold(
          title: l10n.inspTrolleyTitle,
          subtitle: section.isEmpty ? l10n.inspTrolleySubtitle : section,
          initialStep: state.step,
          dirty: state.hasAnswers,
          onLeave: _cubit.saveDraft,
          onStepChanged: (step) {
            _cubit.setStep(step);
            unawaited(_cubit.saveDraft());
          },
          missing: () => [
            if (!state.isAnswered('sectionFrom')) 'Section From',
            if (!state.isAnswered('sectionTo')) 'Section To',
          ],
          onReview: _review,
          steps: [
            for (final (i, step) in kTrolleySteps.indexed)
              if (state.progressOf(step) case (final answered, final total))
                InspectionStep(
                  title: step.title,
                  total: total,
                  answered: answered,
                  builder: (_) => TrolleyStepBody(
                    step: step,
                    state: state,
                    onChanged: _set,
                    leading: [
                      if (i == 0)
                        InspectionDateInput(
                          label: l10n.inspFormDate,
                          value: state.inspectionDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 60),
                          ),
                          lastDate: DateTime.now(),
                          onChanged: _cubit.setDate,
                        ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}
