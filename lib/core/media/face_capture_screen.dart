import 'dart:math' as math;

import 'package:face_kit/face_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/camera/camera_fault_notice.dart';

/// A check shown under the face camera: what was checked, and whether it
/// has passed or is still running.
typedef FaceCheck = ({String label, bool passed});

/// The design's face camera, built around face_kit's camera: the [steps]
/// of the task it is part of, the camera in a rounded window with an oval
/// to fit the face in, what to do next, a tip, and the [checks] of the task.
class FaceCaptureScreen extends StatelessWidget {
  const FaceCaptureScreen({
    super.key,
    required this.scene,
    this.steps = const [],
    this.step = 0,
    this.checks = const [],
  });

  /// For [FaceKitConfig.layout]: the camera on its own.
  static Widget layout(BuildContext context, FaceCaptureScene scene) =>
      FaceCaptureScreen(scene: scene);

  /// A layout for a capture that is one of [steps], at [step], with
  /// [checks] shown under it.
  static FaceCaptureLayout layoutWith({
    List<String> steps = const [],
    int step = 0,
    List<FaceCheck> checks = const [],
  }) =>
      (context, scene) => FaceCaptureScreen(
        scene: scene,
        steps: steps,
        step: step,
        checks: checks,
      );

  final FaceCaptureScene scene;
  final List<String> steps;
  final int step;
  final List<FaceCheck> checks;

  bool get _registering => scene.mode == CaptureMode.registration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return Scaffold(
      body: AppBackdrop.blobs(
        child: SafeArea(
          child: ResponsiveBuilder(
            builder: (context, layout) => Padding(
              padding: EdgeInsets.fromLTRB(
                layout.gutter,
                AppSpacing.md,
                layout.gutter,
                AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeaderBar(
                        title: _registering
                            ? l10n.faceTitleRegister
                            : l10n.faceTitleVerify,
                        backGlyph: AppGlyphs.close,
                        backTooltip: l10n.actionClose,
                        onBack: scene.close,
                      ),
                      if (steps.length > 1) ...[
                        AppSpacing.gapMd,
                        AppProgressSteps(
                          steps: steps,
                          current: step,
                          semanticLabel: l10n.cnicStepOf(
                            step + 1,
                            steps.length,
                            steps[step],
                          ),
                        ),
                      ],
                      AppSpacing.gapLg,
                      Expanded(child: _Viewport(scene: scene)),
                      AppSpacing.gapMd,
                      Center(
                        child: ValueListenableBuilder<FaceCaptureStatus>(
                          valueListenable: scene.status,
                          builder: (context, status, _) => Semantics(
                            liveRegion: true,
                            child: switch (scene.fault) {
                              final fault? => AppPill(
                                fault.title(l10n),
                                tone: AppTone.danger,
                                dot: colors.danger,
                              ),
                              null => AppPill(
                                _hintText(l10n, status.hint),
                                tone: status.capturing
                                    ? AppTone.brand
                                    : AppTone.neutral,
                                dot: status.capturing
                                    ? colors.success
                                    : colors.warningMark,
                              ),
                            },
                          ),
                        ),
                      ),
                      AppSpacing.gapMd,
                      const _Tip(),
                      if (checks.isNotEmpty && !layout.isShort) ...[
                        AppSpacing.gapMd,
                        _Checks(checks: checks),
                      ],
                      AppSpacing.gapMd,
                      Text(
                        l10n.faceFooter,
                        textAlign: TextAlign.center,
                        style: text.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _hintText(AppLocalizations l10n, FaceCaptureHint hint) =>
      switch (hint) {
        FaceCaptureHint.lookAtCamera => l10n.faceHintLook,
        FaceCaptureHint.lookStraight => l10n.faceHintStraight,
        FaceCaptureHint.eyeLevel => l10n.faceHintEyeLevel,
        FaceCaptureHint.noFace => l10n.faceHintNoFace,
        FaceCaptureHint.multipleFaces => l10n.faceHintMultiple,
        FaceCaptureHint.eyesClosed => l10n.faceHintEyes,
        FaceCaptureHint.faceCovered => l10n.faceHintCovered,
        FaceCaptureHint.tooFar => l10n.faceHintFar,
        FaceCaptureHint.tooClose => l10n.faceHintClose,
        FaceCaptureHint.holdSteady => l10n.faceHintSteady,
        FaceCaptureHint.lowLight => l10n.faceHintDark,
        FaceCaptureHint.tooBright => l10n.faceHintBright,
        FaceCaptureHint.objectNearFace => l10n.faceHintObject,
        FaceCaptureHint.capturing => l10n.faceHintCapturing,
      };
}

/// The camera in a raised, rounded window, with the oval guide drawn over
/// it and filling in as the photos are taken.
class _Viewport extends StatelessWidget {
  const _Viewport({required this.scene});

  final FaceCaptureScene scene;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fault = scene.fault;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderViewport,
        border: Border.all(color: colors.surfaceRaised),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceSunken, colors.surfaceMuted],
        ),
        boxShadow: [
          BoxShadow(color: colors.domeEdge, offset: const Offset(0, 6)),
          ...context.elevations.card,
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderViewport,
        // A camera that doesn't work says so where its picture would be,
        // so the phone's camera isn't taken for the app.
        child: fault != null
            ? Center(
                child: CameraFaultNotice(fault: fault, onRetry: scene.retry),
              )
            : ExcludeSemantics(
                child: ValueListenableBuilder<FaceCaptureStatus>(
                  valueListenable: scene.status,
                  // Only the face shows: the camera is cut to the oval, and the
                  // window around it stays the design's quiet stone.
                  child: ClipPath(
                    clipper: const _OvalClip(),
                    child: SizedBox.expand(child: scene.camera),
                  ),
                  builder: (context, status, camera) => CustomPaint(
                    painter: _BackdropPainter(
                      lines: colors.pattern,
                      glow: colors.surfaceRaised.withValues(alpha: 0.5),
                    ),
                    foregroundPainter: _FaceGuidePainter(
                      progress: status.progress,
                      ring: [
                        colors.iconFillActive,
                        colors.success,
                        colors.gold,
                      ],
                      done: colors.success,
                      corners: colors.success,
                      rim: colors.surfaceRaised,
                    ),
                    child: camera,
                  ),
                ),
              ),
      ),
    );
  }
}

// On the design's 342 × 430 window.
const _centreHeight = 196 / 430;
const _ovalHeight = 142 / 430;
const _ovalAspect = 110 / 142;
const _ovalMaxWidth = 0.36;

/// Where the face's oval sits in a window of [size].
Rect _faceOval(Size size) {
  final ry = size.height * _ovalHeight;
  final rx = math.min(ry * _ovalAspect, size.width * _ovalMaxWidth);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * _centreHeight),
    width: rx * 2,
    height: ry * 2,
  );
}

/// Cuts the camera to the face's oval.
class _OvalClip extends CustomClipper<Path> {
  const _OvalClip();

  @override
  Path getClip(Size size) => Path()..addOval(_faceOval(size));

  @override
  bool shouldReclip(_OvalClip old) => false;
}

/// The window behind the oval: a soft light where the face goes, and the
/// pattern faintly over the stone.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({required this.lines, required this.glow});

  final Color lines;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = _faceOval(size);
    canvas.drawCircle(
      oval.center,
      oval.height * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
            .createShader(
              Rect.fromCircle(center: oval.center, radius: oval.height * 0.75),
            ),
    );
    KhatamPatternPainter(
      color: lines,
      fadeHeight: size.height,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.lines != lines || old.glow != glow;
}

/// Round the face's oval: a light rim, then a dashed ring in jade to gold
/// drawn over in solid jade as the photos are taken, with marks at the
/// window's corners.
class _FaceGuidePainter extends CustomPainter {
  const _FaceGuidePainter({
    required this.progress,
    required this.ring,
    required this.done,
    required this.corners,
    required this.rim,
  });

  final double progress;
  final List<Color> ring;
  final Color done;
  final Color corners;
  final Color rim;

  static const _ringGap = 10.0;
  static const _rimWidth = 4.0;
  static const _cornerX = 42 / 342;
  static const _cornerY = 30 / 430;
  static const _cornerReach = 26.0;
  static const _cornerRound = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final face = _faceOval(size);
    canvas.drawOval(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimWidth
        ..color = rim,
    );
    final oval = face.inflate(_ringGap);
    // Start the outline at the top, so the progress fills from there.
    final outline = Path()..addArc(oval, -math.pi / 2, math.pi * 2);
    final dashes = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.faceGuideStroke
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: ring,
        stops: const [0, 0.6, 1],
      ).createShader(oval);
    for (final metric in outline.computeMetrics()) {
      for (
        var at = 0.0;
        at < metric.length;
        at += AppSizes.faceGuideDash + AppSizes.faceGuideGap
      ) {
        canvas.drawPath(
          metric.extractPath(
            at,
            math.min(at + AppSizes.faceGuideDash, metric.length),
          ),
          dashes,
        );
      }
      if (progress > 0) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress.clamp(0, 1)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSizes.faceGuideProgress
            ..strokeCap = StrokeCap.round
            ..color = done,
        );
      }
    }

    final mark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.faceGuideStroke
      ..strokeCap = StrokeCap.round
      ..color = corners;
    final dx = size.width * _cornerX;
    final dy = size.height * _cornerY;
    for (final (x, y, across, down) in [
      (dx, dy, 1.0, 1.0),
      (size.width - dx, dy, -1.0, 1.0),
      (dx, size.height - dy, 1.0, -1.0),
      (size.width - dx, size.height - dy, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + down * (_cornerReach + _cornerRound))
          ..lineTo(x, y + down * _cornerRound)
          ..arcToPoint(
            Offset(x + across * _cornerRound, y),
            radius: const Radius.circular(_cornerRound),
            clockwise: across * down > 0,
          )
          ..lineTo(x + across * (_cornerReach + _cornerRound), y),
        mark,
      );
    }
  }

  @override
  bool shouldRepaint(_FaceGuidePainter old) =>
      old.progress != progress ||
      old.done != done ||
      old.corners != corners ||
      old.rim != rim ||
      !listEquals(old.ring, ring);
}

/// "Hold the phone at eye level", on a raised card with a gold sphere.
class _Tip extends StatelessWidget {
  const _Tip();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final sphere = context.spheres.gold;
    return DecoratedBox(
      decoration: appCardDecoration(context, radius: AppRadius.borderHeroCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + AppSpacing.xxs,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderTile,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.44),
                  colors: [sphere.highlight, sphere.body, sphere.shade],
                  stops: const [0, 0.55, 1],
                ),
              ),
              child: SizedBox.square(
                dimension: AppSizes.avatarMedium,
                child: Center(
                  child: AppGlyphIcon(
                    AppGlyphs.smartphone,
                    size: AppSizes.iconMd,
                    color: sphere.mark,
                  ),
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.faceTipTitle, style: text.titleSmall),
                  Text(
                    l10n.faceTipDetail,
                    style: text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The task's checks, side by side and as tall as the tallest: passed
/// ones ticked, running ones spinning.
class _Checks extends StatelessWidget {
  const _Checks({required this.checks});

  final List<FaceCheck> checks;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, check) in checks.indexed) ...[
            if (index > 0) AppSpacing.gapSm,
            Expanded(
              child: _Check(
                label: check.label,
                mark: check.passed
                    ? AppGlyphIcon(
                        AppGlyphs.check,
                        size: AppSizes.iconSm,
                        color: colors.iconAccent,
                      )
                    : SizedBox.square(
                        dimension: AppSizes.checkSpinner,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.spinnerStroke,
                          color: colors.gold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.mark, required this.label});

  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
        ),
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: colors.surfaceRaised),
        boxShadow: context.elevations.raised,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + AppSpacing.xxs,
          vertical: AppSpacing.smd,
        ),
        child: Column(
          children: [
            mark,
            AppSpacing.gapXs,
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: AppFonts.semiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
