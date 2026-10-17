import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart' show XFile;
import 'package:dio/dio.dart';
import 'package:face_kit/face_kit.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/face_verification/face_attendance_outcome.dart';
import 'package:railway_hrms/core/face_verification/face_repository.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/location/current_location_service.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/network/dio_client.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/team/team_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/team_member.dart';
import 'package:railway_hrms/modules/hrms/data/team_remote_datasource.dart';
import 'package:railway_hrms/modules/hrms/data/team_repository.dart';
import 'package:railway_hrms/modules/hrms/screens/face_registration_view.dart';
import 'package:railway_hrms/modules/hrms/utils/face_registration.dart';
import 'package:railway_hrms/modules/hrms/widgets/team_member_sheets.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Marks someone else's attendance with their face. Someone with no face
/// on record registers it, with their CNIC, on the setup screen first. The
/// team is listed to pick from.
class OthersAttendanceView extends StatefulWidget {
  const OthersAttendanceView({super.key, this.employeeId});

  /// Fills in whose attendance to mark, as from a team member's profile.
  final String? employeeId;

  @override
  State<OthersAttendanceView> createState() => _OthersAttendanceViewState();
}

class _OthersAttendanceViewState extends State<OthersAttendanceView> {
  late final _employeeId = TextEditingController(text: widget.employeeId);
  final FaceRepository _repository = sl<FaceRepository>();
  final _form = GlobalKey<FormState>();
  late final _team = TeamCubit(
    TeamRepositoryImpl(TeamRemoteDataSourceImpl(DioClient())),
  )..load();
  bool _busy = false;

  @override
  void dispose() {
    _employeeId.dispose();
    _team.close();
    super.dispose();
  }

  Future<void> _tell(
    String title,
    String? message, {
    bool ok = false,
    AppGlyph? glyph,
  }) => showAppDialog(
    context: context,
    tone: ok ? AppDialogTone.success : AppDialogTone.error,
    glyph: glyph,
    title: title,
    message: message,
    primaryLabel: context.l10n.actionOk,
  );

  /// The faces the camera took, or null after telling why there are none.
  Future<({List<XFile> images, List<List<double>> embeddings})?>
  _capture() async {
    final l10n = context.l10n;
    // Says why the camera is needed before the system asks.
    if (!await sl<PermissionGate>().request(
          AppPermission.camera,
          context: context,
        ) ||
        !mounted) {
      return null;
    }
    final result = await FaceCapture.open(
      context,
      mode: CaptureMode.verification,
      layout: FaceCaptureScreen.layout,
    );
    if (!mounted) return null;
    if (result is FaceCaptureFailedResult) {
      await _tell(
        result.spoof ? l10n.livenessFailedTitle : l10n.faceCaptureFailedTitle,
        result.message,
      );
      return null;
    }
    return switch (result) {
      FaceVerificationResult(:final images, :final embeddings)
          when images.isNotEmpty =>
        (images: images, embeddings: embeddings),
      // The camera was closed.
      _ => null,
    };
  }

  /// Checks [faces] against [id]'s face on record and marks them in at
  /// [position].
  Future<FaceAttendanceOutcome> _verify(
    String id,
    List<XFile> images,
    List<List<double>> embeddings,
    Position position,
  ) async {
    final result = await _repository.verifyFace(
      id,
      [
        for (final image in images)
          await MultipartFile.fromFile(image.path, filename: image.name),
      ],
      embeddings,
      position.latitude,
      position.longitude,
    );
    return result.fold(
      (failure) => FaceAttendanceOutcome.failed(
        failure.message,
        notRegistered: FaceAttendanceOutcome.saysNotRegistered(
          failure.status,
          failure.message,
        ),
      ),
      // Read the same way as one's own check-in.
      (response) => FaceAttendanceOutcome.fromResponse(response.data),
    );
  }

  /// [id] has no face on record: their face and CNIC are registered on the
  /// setup screen, and the photos it took mark them in.
  Future<FaceAttendanceOutcome?> _registerThenMark(
    String id,
    Position position,
  ) async {
    final registration = await FaceRegistrationView.open(
      context,
      employeeId: id,
      onRegister: (registration) =>
          sendFaceRegistration(_repository, id, registration, own: false),
    );
    if (registration == null || !mounted) return null;
    final take = math.min(_checkPhotos, registration.images.length);
    return _verify(
      id,
      registration.images.take(take).toList(),
      registration.embeddings.take(take).toList(),
      position,
    );
  }

  Future<void> _markAttendance() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final id = _employeeId.text.trim();
    setState(() => _busy = true);
    try {
      // A rooted phone can fake where it is; it marks no attendance.
      final blocked = (await DeviceIntegrity.check()).blockReason();
      if (!mounted) return;
      if (blocked != null) {
        await _tell(l10n.gateNotAllowedTitle, blocked);
        return;
      }
      Position? position;
      try {
        position = await CurrentLocationService.getCurrentLocation();
      } on LocationSpoofedException catch (error) {
        if (mounted) await _tell(l10n.gateFakeLocationTitle, error.message);
        return;
      } catch (_) {
        position = null;
      }
      if (!mounted) return;
      if (position == null) {
        await _tell(l10n.locationErrorTitle, l10n.locationErrorMessage);
        return;
      }
      final faces = await _capture();
      if (faces == null || !mounted) return;
      var outcome = await _verify(id, faces.images, faces.embeddings, position);
      if (!mounted) return;
      if (!outcome.success && outcome.notRegistered) {
        final registered = await _registerThenMark(id, position);
        if (registered == null || !mounted) return;
        outcome = registered;
      }
      if (outcome.success) unawaited(_team.load(silent: true));
      await _tell(
        outcome.success
            ? l10n.attendanceMarkedTitle
            : l10n.verificationFailedTitle,
        outcome.message,
        ok: outcome.success,
      );
    } catch (error) {
      debugPrint('Marking attendance failed: $error');
      if (mounted) await _tell(l10n.markFailedTitle, l10n.markFailedMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        onRefresh: () => _team.load(silent: true),
        children: [
          AppHeaderBar(
            title: l10n.othersTitle,
            subtitle: l10n.othersSubtitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _employeeId,
                    label: l10n.memberEmployeeId,
                    hint: l10n.othersEmployeeIdHint,
                    glyph: AppGlyphs.idCard,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_busy,
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? l10n.othersEmployeeIdRequired
                        : null,
                  ),
                  AppSpacing.gapLg,
                  AppButton(
                    label: l10n.memberMarkAttendance,
                    leadingGlyph: AppGlyphs.scanFace,
                    isLoading: _busy,
                    onPressed: _busy ? null : _markAttendance,
                  ),
                  AppSpacing.gapSm,
                  Text(
                    l10n.othersFirstTimeNote,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapXl,
          BlocProvider.value(
            value: _team,
            child: _TeamPicker(
              enabled: !_busy,
              selected: _employeeId,
              onPick: (id) {
                _employeeId.text = id;
                _form.currentState?.validate();
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The photos a check takes, as for one's own check-in.
const _checkPhotos = 2;

/// The team to pick from, with a search once it is long; picking someone
/// fills in their ID.
class _TeamPicker extends StatefulWidget {
  const _TeamPicker({
    required this.enabled,
    required this.selected,
    required this.onPick,
  });

  final bool enabled;
  final ValueListenable<TextEditingValue> selected;
  final ValueChanged<String> onPick;

  @override
  State<_TeamPicker> createState() => _TeamPickerState();
}

class _TeamPickerState extends State<_TeamPicker> {
  /// Longer than this, the team gets a search.
  static const _searchFrom = 6;

  String _query = '';

  bool _matches(TeamMember member) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return member.name.toLowerCase().contains(query) ||
        member.employeeId.contains(query) ||
        member.designation.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<TeamCubit, TeamState>(
      builder: (context, state) {
        final loading = state.load != TeamLoad.ready;
        final members = state.members.where(_matches).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionTitle(
              state.members.isEmpty
                  ? l10n.othersTeam
                  : l10n.othersTeamCount(state.members.length),
            ),
            AppSpacing.gapSm,
            if (state.members.length > _searchFrom) ...[
              AppSearchField(
                hint: l10n.othersTeamSearch,
                onChanged: (query) => setState(() => _query = query),
              ),
              AppSpacing.gapMd,
            ],
            if (loading && state.members.isEmpty)
              Skeletonizer(
                child: AppListGroup(
                  children: [
                    for (var i = 0; i < 4; i++)
                      TeamMemberRow(
                        member: const TeamMember(
                          name: 'Employee name',
                          employeeId: '000000',
                          designation: 'Designation',
                        ),
                        onTap: () {},
                      ),
                  ],
                ),
              )
            else if (members.isEmpty)
              _Quiet(
                message: state.membersFailed
                    ? l10n.othersTeamFailed
                    : state.members.isEmpty
                    ? l10n.othersTeamEmpty
                    : l10n.othersTeamNoMatch,
                onRetry: state.membersFailed
                    ? () => context.read<TeamCubit>().load()
                    : null,
              )
            else
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.selected,
                builder: (context, selected, _) => AppListGroup(
                  children: [
                    for (final member in members)
                      TeamMemberRow(
                        member: member,
                        picked:
                            member.employeeId.isNotEmpty &&
                            member.employeeId == selected.text.trim(),
                        onTap: widget.enabled
                            ? () => widget.onPick(member.employeeId)
                            : () {},
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

/// A quiet card in place of the list, with a way to try again.
class _Quiet extends StatelessWidget {
  const _Quiet({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final onRetry = this.onRetry;
    return DecoratedBox(
      decoration: appCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapSm,
              AppButton(
                label: context.l10n.actionRetry,
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                expand: false,
                underlined: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
