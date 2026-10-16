import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:face_kit/face_kit.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/cnic/cnic_camera.dart';
import 'package:railway_hrms/core/media/cnic/cnic_capture_card.dart';
import 'package:railway_hrms/core/media/face_capture_screen.dart';
import 'package:railway_hrms/core/permissions/app_permission.dart';
import 'package:railway_hrms/core/permissions/permission_gate.dart';
import 'package:railway_hrms/modules/hrms/utils/cnic_capture.dart';

/// The fewest clear photos a face registration needs.
const _fewestPhotos = 5;

/// What registering a face gathers: the face's photos, and the front of the
/// CNIC.
@immutable
class FaceRegistration {
  const FaceRegistration({
    required this.images,
    required this.embeddings,
    required this.cnic,
  });

  final List<XFile> images;
  final List<List<double>> embeddings;
  final XFile cnic;
}

/// Sends a [FaceRegistration] to the server: null when it went through, or
/// what went wrong.
typedef RegisterFace = Future<String?> Function(FaceRegistration registration);

/// Sends the CNIC's photo and the face's to the employee's attachments;
/// resolves to null once they are sent, or to what went wrong.
typedef SendAttachments =
    Future<String?> Function(
      XFile cnic, {
      String? employeeId,
      XFile? facePhoto,
    });

/// Opens the face camera laid out by [layout]; resolves to face_kit's
/// result, or null when it was closed.
typedef FaceCamera =
    Future<Object?> Function(BuildContext context, FaceCaptureLayout layout);

/// Sets up face check-in on one screen, in two steps: the CNIC, scanned in
/// the page by on-device AI as at train tracking sign-in, then the face, in
/// its own camera; each shown here once taken. Proceed
/// registers both; anything that goes wrong is said here, so nothing has
/// to be taken again.
class FaceRegistrationView extends StatefulWidget {
  const FaceRegistrationView({
    super.key,
    required this.onRegister,
    this.employeeId,
    this.cnicCamera,
    this.faceCamera,
    this.sendAttachments = uploadCnicAttachment,
  });

  final RegisterFace onRegister;

  /// Sends the photos before the face is registered; if they can't be
  /// sent, nothing is registered.
  final SendAttachments sendAttachments;

  /// The CNIC camera; [CnicCamera] by default, a stand-in in tests.
  final CnicCameraBuilder? cnicCamera;

  /// The face camera; face_kit's by default, a stand-in in tests.
  final FaceCamera? faceCamera;

  /// Someone else's employee ID, when registering them; the signed-in
  /// employee's own registration otherwise.
  final String? employeeId;

  /// Opens the setup over everything; resolves to what was registered, or
  /// null when it was closed first.
  static Future<FaceRegistration?> open(
    BuildContext context, {
    required RegisterFace onRegister,
    String? employeeId,
  }) => Navigator.of(context, rootNavigator: true).push<FaceRegistration>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          FaceRegistrationView(onRegister: onRegister, employeeId: employeeId),
    ),
  );

  @override
  State<FaceRegistrationView> createState() => _FaceRegistrationViewState();
}

class _FaceRegistrationViewState extends State<FaceRegistrationView> {
  ({List<XFile> images, List<List<double>> embeddings})? _face;
  CnicScan? _cnicScan;

  XFile? get _cnic => _cnicScan?.photo;
  bool _busy = false;
  String? _problem;

  /// The photos last sent, so a retry after a failed registration doesn't
  /// send the same ones again.
  ({String cnic, String? face})? _sent;

  int get _done => (_cnic == null ? 0 : 1) + (_face == null ? 0 : 1);

  /// The steps of the setup, as its progress and the face camera show
  /// them: once both are taken, the last is reached.
  static List<String> _steps(AppLocalizations l10n) => [
    l10n.cnicStepCnic,
    l10n.cnicStepFace,
    l10n.cnicStepDone,
  ];

  Future<void> _scanFace() async {
    final l10n = context.l10n;
    final layout = FaceCaptureScreen.layoutWith(steps: _steps(l10n), step: 1);
    final result = await (widget.faceCamera ?? _openFaceCamera)(
      context,
      layout,
    );
    if (!mounted) return;
    switch (result) {
      case FaceCaptureFailedResult(:final message):
        setState(() => _problem = message);
      case FaceRegistrationResult(:final images, :final embeddings)
          when images.length >= _fewestPhotos:
        setState(() {
          _face = (
            images: images.take(_fewestPhotos).toList(),
            embeddings: embeddings.take(_fewestPhotos).toList(),
          );
          _problem = null;
        });
      case FaceRegistrationResult():
        setState(() => _problem = l10n.faceIncompleteMessage);
    }
  }

  /// face_kit's face camera, once the camera is allowed.
  static Future<Object?> _openFaceCamera(
    BuildContext context,
    FaceCaptureLayout layout,
  ) async {
    if (!await sl<PermissionGate>().request(
          AppPermission.camera,
          context: context,
        ) ||
        !context.mounted) {
      return null;
    }
    return FaceCapture.open(
      context,
      mode: CaptureMode.registration,
      layout: layout,
    );
  }

  /// The CNIC taken, or let go to be scanned again.
  void _scannedCnic(CnicScan? scan) => setState(() {
    _cnicScan = scan;
    _problem = null;
  });

  Future<void> _proceed() async {
    final face = _face;
    final cnic = _cnic;
    if (face == null || cnic == null) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _problem = null;
    });
    final facePhoto = face.images.isNotEmpty ? face.images.first : null;
    final photos = (cnic: cnic.path, face: facePhoto?.path);
    // The photos go first: if they can't be sent, nothing is registered,
    // and the user is told why.
    if (_sent != photos) {
      final unsent = await widget.sendAttachments(
        cnic,
        employeeId: widget.employeeId,
        facePhoto: facePhoto,
      );
      if (!mounted) return;
      if (unsent != null) {
        setState(() {
          _busy = false;
          _problem = l10n.registerAttachmentsFailed(unsent);
        });
        return;
      }
      _sent = photos;
    }
    final registration = FaceRegistration(
      images: face.images,
      embeddings: face.embeddings,
      cnic: cnic,
    );
    final problem = await widget.onRegister(registration);
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop(registration);
      return;
    }
    setState(() {
      _busy = false;
      _problem = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final id = widget.employeeId;
    final steps = _steps(l10n);
    final face = _face;
    final cnic = _cnic;
    final problem = _problem;
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.registerIntroTitle,
            subtitle: id == null
                ? l10n.registerSubtitle
                : l10n.registerOthersSubtitle(id),
            backGlyph: AppGlyphs.close,
            backTooltip: l10n.actionClose,
            onBack: _busy ? null : () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          AppProgressSteps(
            steps: steps,
            current: _done,
            semanticLabel: l10n.cnicStepOf(
              _done + 1,
              steps.length,
              steps[_done],
            ),
          ),
          AppSpacing.gapXl,
          _StepCard(
            number: 1,
            state: cnic == null ? _StepState.active : _StepState.done,
            title: l10n.registerCnicTitle,
            detail: l10n.registerCnicDetail,
            doneLabel: l10n.registerCnicDone,
            body: IgnorePointer(
              ignoring: _busy,
              child: CnicCaptureCard(
                scan: _cnicScan,
                onScanned: _scannedCnic,
                camera: widget.cnicCamera,
                heading: false,
              ),
            ),
          ),
          AppSpacing.gapMd,
          _StepCard(
            number: 2,
            state: face != null
                ? _StepState.done
                : cnic == null
                ? _StepState.locked
                : _StepState.active,
            title: l10n.registerFaceTitle,
            detail: cnic == null
                ? l10n.registerCnicLocked
                : l10n.registerFaceDetail,
            doneLabel: l10n.registerFaceDone,
            preview: face == null
                ? null
                : ClipOval(
                    child: Image.file(
                      File(face.images.first.path),
                      width: AppSizes.avatarMedium,
                      height: AppSizes.avatarMedium,
                      fit: BoxFit.cover,
                    ),
                  ),
            action: AppButton(
              label: face == null ? l10n.registerFaceAction : l10n.cnicRetake,
              variant: face == null && cnic != null
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              leadingGlyph: face == null
                  ? AppGlyphs.scanFace
                  : AppGlyphs.refresh,
              onPressed: cnic == null || _busy ? null : _scanFace,
            ),
          ),
          if (problem != null) ...[
            AppSpacing.gapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppGlyphIcon(
                  AppGlyphs.circleAlert,
                  size: AppSizes.iconSm,
                  color: colors.onDangerContainer,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      problem,
                      style: text.bodySmall?.copyWith(
                        color: colors.onDangerContainer,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          AppSpacing.gapLg,
          Text(
            l10n.registerPrivacy,
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          AppSpacing.gapLg,
          AppButton(
            label: l10n.registerProceed,
            loadingLabel: l10n.registerProceeding,
            trailingGlyph: AppGlyphs.arrowRight,
            isLoading: _busy,
            onPressed: face != null && cnic != null && !_busy ? _proceed : null,
          ),
        ],
      ),
    );
  }
}

/// Where a step stands.
enum _StepState { locked, active, done }

/// One step on a card: its number on a sphere (a check once done), what it
/// is and why, what it took, and the key that does it.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.state,
    required this.title,
    required this.detail,
    required this.doneLabel,
    this.action,
    this.preview,
    this.body,
  });

  final int number;
  final _StepState state;
  final String title;
  final String detail;
  final String doneLabel;
  final Widget? action;
  final Widget? preview;

  /// Under the step, the card's full width, such as a camera.
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final locked = state == _StepState.locked;
    final preview = this.preview;
    final action = this.action;
    final body = this.body;
    return Semantics(
      container: true,
      label: l10n.registerStep(number),
      child: Opacity(
        opacity: locked ? 0.6 : 1,
        child: DecoratedBox(
          decoration: appCardDecoration(
            context,
            radius: AppRadius.borderHeroCard,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepBadge(number: number, state: state),
                    AppSpacing.gapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(title, style: text.labelLarge),
                          AppSpacing.gapXxs,
                          Text(
                            detail,
                            style: text.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          if (state == _StepState.done && preview != null) ...[
                            AppSpacing.gapMd,
                            Row(
                              children: [
                                preview,
                                AppSpacing.gapMd,
                                Flexible(
                                  child: AppPill(
                                    doneLabel,
                                    dot: colors.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (action != null) ...[
                            AppSpacing.gapMd,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: action,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (body != null) ...[AppSpacing.gapMd, body],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A step's number on a small sphere: jade with a check once done, ringed
/// while it is the one to do, sunk while it waits.
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.state});

  final int number;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    final done = state == _StepState.done;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: done
            ? AppButton.keyGradient(
                colors.primaryHighlight,
                colors.primary,
                colors.primaryShade,
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: state == _StepState.active
                    ? [colors.surfaceRaised, colors.surfaceRaisedEnd]
                    : [colors.surfaceSunken, colors.surfaceSunkenEnd],
              ),
        border: state == _StepState.active
            ? Border.all(color: colors.primaryShade, width: AppSizes.todayRing)
            : null,
        boxShadow: done
            ? [
                BoxShadow(
                  color: colors.primaryEdge,
                  offset: const Offset(0, AppSizes.keyEdgePressed * 2),
                ),
              ]
            : state == _StepState.active
            ? context.elevations.raised
            : null,
      ),
      child: SizedBox.square(
        dimension: AppSizes.optionLeading + AppSpacing.sm,
        child: Center(
          child: done
              ? AppGlyphIcon(
                  AppGlyphs.check,
                  size: AppSizes.iconSm,
                  color: colors.onPrimary,
                )
              : Text(
                  '$number',
                  style: text.titleSmall?.copyWith(
                    color: state == _StepState.active
                        ? colors.textPrimary
                        : colors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}
