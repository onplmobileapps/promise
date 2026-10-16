import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';
import 'package:railway_hrms/core/media/camera/live_camera.dart';

/// One sweep of the scanning beam, down and back up.
const _sweepTime = Duration(milliseconds: 2400);

/// A camera window for scanning a card: a raised, rounded window in the
/// design's quiet stone, the camera showing only through the card's frame
/// ([cardFrameIn]), its corners lit [corners], a [beam] sweeping the frame
/// while the AI looks, a [badge] under the frame, and a tick in it once
/// [ticked]. While the camera opens it shows a spinner, and a key to try
/// again if it fails.
///
/// The preview covers the whole window beneath the cut, so a frame of the
/// stream and a photo line up with what is seen: [onViewport] is told the
/// window's size, to map between them ([viewToImage]).
///
/// The beam is still for those who ask for less motion.
class CardCameraWindow extends StatefulWidget {
  const CardCameraWindow({
    super.key,
    required this.camera,
    required this.corners,
    this.beam,
    this.badge,
    this.ticked = false,
    this.onViewport,
  });

  final LiveCamera camera;
  final Color corners;

  /// The beam's colour; no beam without it.
  final Color? beam;

  /// Under the frame, such as what is looking.
  final Widget? badge;
  final bool ticked;
  final ValueChanged<Size>? onViewport;

  @override
  State<CardCameraWindow> createState() => _CardCameraWindowState();
}

class _CardCameraWindowState extends State<CardCameraWindow>
    with SingleTickerProviderStateMixin {
  late final _sweep = AnimationController(vsync: this, duration: _sweepTime);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderViewport,
        border: Border.all(color: colors.surfaceRaised),
        boxShadow: [
          BoxShadow(color: colors.domeEdge, offset: const Offset(0, 6)),
          ...context.elevations.card,
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.surfaceSunken, colors.surfaceMuted],
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderViewport,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            widget.onViewport?.call(size);
            final frame = cardFrameIn(size);
            return ListenableBuilder(
              listenable: widget.camera,
              builder: (context, _) {
                final camera = widget.camera;
                final controller = camera.controller;
                final ready = camera.isReady && controller != null;
                final beam = widget.beam;
                final badge = widget.badge;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _StonePainter(
                        lines: colors.pattern,
                        glow: colors.surfaceRaised.withValues(alpha: 0.5),
                      ),
                    ),
                    ClipPath(
                      clipper: const _FrameClip(),
                      child: ColoredBox(
                        color: colors.surfaceSunken,
                        child: ready
                            ? ExcludeSemantics(
                                child: CameraCoverPreview(camera: controller),
                              )
                            : const SizedBox.expand(),
                      ),
                    ),
                    if (!ready)
                      Positioned.fromRect(
                        rect: frame,
                        child: Center(
                          child: camera.status == LiveCameraStatus.failed
                              ? AppButton(
                                  label: l10n.actionRetry,
                                  variant: AppButtonVariant.secondary,
                                  size: AppButtonSize.small,
                                  expand: false,
                                  onPressed: camera.retry,
                                )
                              : const CircularProgressIndicator(),
                        ),
                      ),
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _ScanPainter(
                          sweep: _sweep,
                          edge: colors.surfaceRaised.withValues(alpha: 0.8),
                          corners: widget.corners,
                          beam: beam ?? colors.success,
                          beaming: ready && beam != null,
                        ),
                      ),
                    ),
                    if (ready && badge != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: frame.bottom,
                        bottom: 0,
                        child: Center(child: badge),
                      ),
                    if (widget.ticked)
                      Positioned.fromRect(
                        rect: frame,
                        child: const Center(child: _Tick()),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The camera's preview filling its box, cropped at the sides as needed.
class CameraCoverPreview extends StatelessWidget {
  const CameraCoverPreview({super.key, required this.camera});

  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    final size = camera.value.previewSize;
    if (size == null) return CameraPreview(camera);
    // The sensor reports landscape; the phone holds it upright.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.height,
        height: size.width,
        child: CameraPreview(camera),
      ),
    );
  }
}

/// Cuts the camera to the card's frame.
class _FrameClip extends CustomClipper<Path> {
  const _FrameClip();

  @override
  Path getClip(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        cardFrameIn(size),
        const Radius.circular(AppRadius.md),
      ),
    );

  @override
  bool shouldReclip(_FrameClip old) => false;
}

/// The window round the card: a soft light where the card goes, and the
/// pattern faintly over the stone.
class _StonePainter extends CustomPainter {
  const _StonePainter({required this.lines, required this.glow});

  final Color lines;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = cardFrameIn(size);
    final reach = frame.width * 0.75;
    canvas.drawCircle(
      frame.center,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [glow, glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: frame.center, radius: reach)),
    );
    KhatamPatternPainter(
      color: lines,
      fadeHeight: size.height,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_StonePainter old) =>
      old.lines != lines || old.glow != glow;
}

/// Outlines the card's frame, sweeps a beam of light down and up it while
/// the AI looks, and marks its corners.
class _ScanPainter extends CustomPainter {
  _ScanPainter({
    required this.sweep,
    required this.edge,
    required this.corners,
    required this.beam,
    required this.beaming,
  }) : super(repaint: sweep);

  final Animation<double> sweep;
  final Color edge;
  final Color corners;
  final Color beam;
  final bool beaming;

  /// The light trailing the beam, as a share of the frame's height.
  static const _trail = 0.22;
  static const _beamWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = cardFrameIn(size);
    final window = RRect.fromRectAndRadius(
      frame,
      const Radius.circular(AppRadius.md),
    );
    canvas.drawRRect(
      window,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSizes.todayRing
        ..color = edge,
    );

    if (beaming) {
      // Down in the first half of a sweep, back up in the second.
      final down = sweep.value < 0.5;
      final travel = Curves.easeInOut.transform(
        down ? sweep.value * 2 : (1 - sweep.value) * 2,
      );
      final y = frame.top + frame.height * travel;
      final trail = frame.height * _trail;
      final glow = down
          ? Rect.fromLTRB(frame.left, y - trail, frame.right, y)
          : Rect.fromLTRB(frame.left, y, frame.right, y + trail);
      canvas
        ..save()
        ..clipRRect(window)
        ..drawRect(
          glow,
          Paint()
            ..shader = LinearGradient(
              begin: down ? Alignment.topCenter : Alignment.bottomCenter,
              end: down ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [beam.withValues(alpha: 0), beam.withValues(alpha: 0.3)],
            ).createShader(glow),
        )
        ..drawLine(
          Offset(frame.left + AppSpacing.sm, y),
          Offset(frame.right - AppSpacing.sm, y),
          Paint()
            ..color = beam
            ..strokeWidth = _beamWidth
            ..strokeCap = StrokeCap.round,
        )
        ..restore();
    }

    final mark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppSizes.frameCornerStroke
      ..strokeCap = StrokeCap.round
      ..color = corners;
    final reach = math.min(AppSizes.frameCorner, frame.shortestSide / 3);
    final box = frame.inflate(AppSizes.frameCornerStroke);
    for (final (corner, across, down) in [
      (box.topLeft, 1.0, 1.0),
      (box.topRight, -1.0, 1.0),
      (box.bottomLeft, 1.0, -1.0),
      (box.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, corner.dy + down * reach)
          ..lineTo(corner.dx, corner.dy)
          ..lineTo(corner.dx + across * reach, corner.dy),
        mark,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) =>
      old.sweep != sweep ||
      old.edge != edge ||
      old.corners != corners ||
      old.beam != beam ||
      old.beaming != beaming;
}

/// A jade key with a tick, springing in once the CNIC is taken.
class _Tick extends StatelessWidget {
  const _Tick();

  static const _size = 64.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: AppMotion.medium,
      curve: AppMotion.spring,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppButton.keyGradient(
            colors.primaryHighlight,
            colors.primary,
            colors.primaryShade,
          ),
          boxShadow: context.elevations.key,
        ),
        child: SizedBox.square(
          dimension: _size,
          child: Center(
            child: AppGlyphIcon(
              AppGlyphs.check,
              size: AppSizes.iconXl,
              color: colors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
