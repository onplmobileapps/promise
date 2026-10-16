import 'dart:io';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';
import 'package:railway_hrms/core/media/cnic/cnic_camera.dart';

/// Builds the camera that scans the CNIC, with what to call once it is
/// taken and when the camera is closed.
typedef CnicCameraBuilder =
    Widget Function(ValueChanged<CnicScan> onCaptured, VoidCallback onClose);

Widget _cnicCamera(ValueChanged<CnicScan> onCaptured, VoidCallback onClose) =>
    CnicCamera(onCaptured: onCaptured, onClose: onClose);

/// A CNIC to scan, in a page: a space to scan it into; the camera, laid
/// into the page, while it is scanned; and once it is, the card's photo.
/// Signing in to train tracking and setting up face check-in both take it.
class CnicCaptureCard extends StatefulWidget {
  const CnicCaptureCard({
    super.key,
    required this.scan,
    required this.onScanned,
    this.camera,
    this.heading = true,
  });

  final CnicScan? scan;

  /// Called with the scan once the card is taken, and with null when it is
  /// to be scanned again.
  final ValueChanged<CnicScan?> onScanned;

  /// The camera; [CnicCamera] by default, a stand-in in tests.
  final CnicCameraBuilder? camera;

  /// Whether it is titled "Pakistani CNIC"; not under a heading of its own.
  final bool heading;

  @override
  State<CnicCaptureCard> createState() => _CnicCaptureCardState();
}

class _CnicCaptureCardState extends State<CnicCaptureCard> {
  bool _scanning = false;

  void _scan() {
    if (widget.scan != null) widget.onScanned(null);
    setState(() => _scanning = true);
  }

  void _captured(CnicScan scan) {
    setState(() => _scanning = false);
    widget.onScanned(scan);
  }

  void _close() => setState(() => _scanning = false);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scan = widget.scan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.heading) ...[
          Row(
            children: [
              Expanded(child: AppSectionLabel(l10n.cnicCardTitle)),
              AppTag(l10n.cnicLiveBadge, tone: AppTone.brand),
            ],
          ),
          AppSpacing.gapSm,
        ],
        if (_scanning)
          (widget.camera ?? _cnicCamera)(_captured, _close)
        else if (scan != null)
          _Scanned(scan: scan, onScan: _scan)
        else
          _EmptySlot(onScan: _scan),
      ],
    );
  }
}

/// The space a CNIC is scanned into: a sketch of a card with the camera
/// key on it.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onScan});

  final VoidCallback? onScan;

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderHeroCard,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return AppPressable(
      label: l10n.cnicCardTap,
      onPressed: onScan,
      builder: (context, pressed, focused) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
          ),
          borderRadius: AppRadius.borderHeroCard,
          border: Border.all(
            color: focused ? colors.focus : colors.outline,
            width: focused ? 1.5 : 1,
          ),
        ),
        child: CustomPaint(
          painter: InsetShadowPainter(
            shape: _shape,
            shadows: pressed
                ? context.elevations.pressedInset
                : context.elevations.recessInset,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: AspectRatio(
                      aspectRatio: idCardAspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _CardSketch.of(context)),
                          Center(child: _CameraKey(pressed: pressed)),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapMd,
                Text(
                  l10n.cnicCardTap,
                  textAlign: TextAlign.center,
                  style: text.titleSmall,
                ),
                AppSpacing.gapXxs,
                Text(
                  l10n.registerCnicDetail,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round jade key on the sketch, sunk while the space is held.
class _CameraKey extends StatelessWidget {
  const _CameraKey({required this.pressed});

  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppButton.keyGradient(
          colors.primaryHighlight,
          colors.primary,
          colors.primaryShade,
        ),
        boxShadow: pressed ? elevations.keyPressed : elevations.key,
      ),
      child: SizedBox.square(
        dimension: AppSizes.heroButton,
        child: Center(
          child: AppGlyphIcon(
            AppGlyphs.camera,
            size: AppSizes.iconLg,
            color: colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// A plain sketch of an identity card.
class _CardSketch extends CustomPainter {
  const _CardSketch({
    required this.face,
    required this.faceEnd,
    required this.edge,
    required this.band,
    required this.print,
    required this.number,
    required this.photo,
    required this.figure,
  });

  factory _CardSketch.of(BuildContext context) {
    final colors = context.colors;
    return _CardSketch(
      face: colors.surfaceRaised,
      faceEnd: colors.surfaceRaisedEnd,
      edge: colors.outlineStrong,
      band: colors.primaryContainer,
      print: colors.textTertiary.withValues(alpha: 0.35),
      number: colors.accent.withValues(alpha: 0.55),
      photo: colors.surfaceMuted,
      figure: colors.textTertiary.withValues(alpha: 0.45),
    );
  }

  final Color face;
  final Color faceEnd;
  final Color edge;
  final Color band;
  final Color print;
  final Color number;
  final Color photo;
  final Color figure;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(h * 0.09),
    );
    canvas
      ..drawRRect(
        card,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [face, faceEnd],
          ).createShader(Offset.zero & size),
      )
      ..save()
      ..clipRRect(card)
      ..drawRect(Rect.fromLTWH(0, 0, w, h * 0.2), Paint()..color = band)
      ..restore()
      ..drawRRect(
        card,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = edge,
      );

    void bar(double x, double y, double width, double height, Color color) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * x, h * y, w * width, h * height),
            Radius.circular(h * height / 2),
          ),
          Paint()..color = color,
        );

    bar(0.07, 0.07, 0.26, 0.06, print);
    bar(0.62, 0.07, 0.3, 0.06, print);
    for (final y in [0.3, 0.47, 0.64]) {
      bar(0.07, y, 0.16, 0.045, print);
      bar(0.07, y + 0.07, 0.42, 0.055, print);
    }
    bar(0.07, 0.84, 0.36, 0.07, number);

    final frame = Rect.fromLTWH(w * 0.66, h * 0.3, w * 0.26, h * 0.56);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, Radius.circular(h * 0.04)),
      Paint()..color = photo,
    );
    final head = frame.width * 0.2;
    canvas
      ..save()
      ..clipRRect(RRect.fromRectAndRadius(frame, Radius.circular(h * 0.04)))
      ..drawCircle(
        Offset(frame.center.dx, frame.top + frame.height * 0.38),
        head,
        Paint()..color = figure,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(frame.center.dx, frame.bottom + frame.height * 0.08),
          width: frame.width * 0.8,
          height: frame.height * 0.62,
        ),
        Paint()..color = figure,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_CardSketch old) =>
      old.face != face ||
      old.faceEnd != faceEnd ||
      old.edge != edge ||
      old.band != band ||
      old.print != print ||
      old.number != number ||
      old.photo != photo ||
      old.figure != figure;
}

/// A scanned CNIC: its photo, landing in place with a light crossing it,
/// badged as verified; and a key to scan it again.
class _Scanned extends StatelessWidget {
  const _Scanned({required this.scan, required this.onScan});

  final CnicScan scan;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScannedPhoto(scan: scan),
        AppSpacing.gapSm,
        Row(
          children: [
            AppGlyphIcon(
              AppGlyphs.shieldCheck,
              size: AppSizes.iconSm,
              color: colors.iconAccent,
            ),
            AppSpacing.gapXs,
            Expanded(
              child: Text(
                l10n.cnicCardAi,
                style: text.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
            AppSpacing.gapSm,
            AppButton(
              label: l10n.cnicScanAgain,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              leadingGlyph: AppGlyphs.refresh,
              expand: false,
              onPressed: onScan,
            ),
          ],
        ),
      ],
    );
  }
}

/// How long the photo takes to land, the light crossing it with it.
const _landTime = Duration(milliseconds: 900);

/// The CNIC's photo, cropped to the card, badged as verified. It lands from
/// a little smaller and lower, and a light crosses it once; still for those
/// who ask for less motion.
class _ScannedPhoto extends StatefulWidget {
  const _ScannedPhoto({required this.scan});

  final CnicScan scan;

  @override
  State<_ScannedPhoto> createState() => _ScannedPhotoState();
}

class _ScannedPhotoState extends State<_ScannedPhoto>
    with SingleTickerProviderStateMixin {
  late final _play = AnimationController(vsync: this, duration: _landTime);
  late final _land = CurvedAnimation(
    parent: _play,
    curve: const Interval(0, 0.5, curve: AppMotion.spring),
  );
  late final _sheen = CurvedAnimation(
    parent: _play,
    curve: const Interval(0.3, 1, curve: Curves.easeInOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _play.value = 1;
    } else if (_play.value == 0 && !_play.isAnimating) {
      _play.forward();
    }
  }

  @override
  void dispose() {
    _land.dispose();
    _sheen.dispose();
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderHeroCard,
        boxShadow: context.elevations.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderHeroCard,
        child: AspectRatio(
          aspectRatio: idCardAspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(widget.scan.photo.path),
                fit: BoxFit.cover,
                semanticLabel: l10n.cnicCardTitle,
                // The photo is kept in the phone's temporary files, which
                // the system may clear.
                errorBuilder: (context, _, _) => ColoredBox(
                  color: colors.surfaceMuted,
                  child: Center(
                    child: AppGlyphIcon(
                      AppGlyphs.idCard,
                      size: AppSizes.iconXl,
                      color: colors.iconAccent,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _SheenPainter(
                    progress: _sheen,
                    light: colors.surfaceRaised,
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: AppPill(
                  l10n.cnicVerified,
                  tone: AppTone.brand,
                  dot: colors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _land,
      child: card,
      builder: (context, card) {
        final t = _land.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, AppSpacing.xxl * (1 - t)),
            child: Transform.scale(scale: 0.9 + 0.1 * t, child: card),
          ),
        );
      },
    );
  }
}

/// A slanted band of light crossing the card from left to right.
class _SheenPainter extends CustomPainter {
  _SheenPainter({required this.progress, required this.light})
    : super(repaint: progress);

  final Animation<double> progress;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final band = size.width * 0.35;
    final centre = -band + (size.width + band * 2) * t;
    final rect = Rect.fromLTWH(
      centre - band / 2,
      -size.height,
      band,
      size.height * 3,
    );
    canvas
      ..save()
      ..translate(centre, size.height / 2)
      ..rotate(0.35)
      ..translate(-centre, -size.height / 2)
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              light.withValues(alpha: 0),
              light.withValues(alpha: 0.55),
              light.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) =>
      old.progress != progress || old.light != light;
}
