import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/security/biometric_authenticator.dart';

/// Signs in with the face or fingerprint set up on the phone, [kind]: the
/// sign-in card's main key, named for it, as Face ID on an iPhone.
///
/// The design's jade key, its name and mark in deep jade. Its mark sits in
/// a lit glass badge that sends a ring out as the key arrives, a gleam sweeps across
/// it then and again each time it is pressed, and it sinks under the
/// finger with a tap of haptics.
class BiometricSignInButton extends StatefulWidget {
  const BiometricSignInButton({
    super.key,
    required this.kind,
    required this.onPressed,
  });

  final BiometricKind kind;
  final VoidCallback onPressed;

  @override
  State<BiometricSignInButton> createState() => _BiometricSignInButtonState();
}

class _BiometricSignInButtonState extends State<BiometricSignInButton>
    with SingleTickerProviderStateMixin {
  /// The gleam and the badge's ring, from 0 to 1, once on arrival and on
  /// each press.
  late final _gleam = AnimationController(
    vsync: this,
    duration: AppMotion.biometricGleam,
  );
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_gleam.status == AnimationStatus.dismissed &&
        !MediaQuery.disableAnimationsOf(context)) {
      _gleam.forward();
    }
  }

  @override
  void dispose() {
    _gleam.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (_pressed == down) return;
    setState(() => _pressed = down);
  }

  void _tap() {
    HapticFeedback.lightImpact();
    if (!MediaQuery.disableAnimationsOf(context)) _gleam.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isApple = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };
    final label = switch (widget.kind) {
      BiometricKind.face when isApple => l10n.biometricFaceId,
      BiometricKind.face => l10n.biometricFace,
      BiometricKind.fingerprint => l10n.biometricFingerprint,
    };
    final glyph = widget.kind == BiometricKind.face
        ? AppGlyphs.scanFace
        : AppGlyphs.fingerprint;
    // The design's jade key, as every main key; its name and mark in the
    // deepest jade so they read clearly on it.
    final ink = colors.onPrimaryContainer;
    final elevations = context.elevations;
    const radius = BorderRadius.all(
      Radius.circular(AppSizes.biometricKeyRadius),
    );
    final shape = RoundedRectangleBorder(borderRadius: radius);

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: _tap,
        // The card's full width, its mark and name in the middle.
        child: SizedBox(
          width: double.infinity,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: AppMotion.short,
            curve: AppMotion.enter,
            child: LiquidPress(
              pressed: _pressed,
              radius: radius,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: _pressed
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colors.primaryPressed, colors.primaryShade],
                        )
                      : AppButton.keyGradient(
                          colors.primaryHighlight,
                          colors.primary,
                          colors.primaryShade,
                        ),
                  boxShadow: _pressed ? elevations.keyPressed : elevations.key,
                ),
                child: CustomPaint(
                  painter: InsetShadowPainter(
                    shape: shape,
                    shadows: _pressed
                        ? elevations.keyPressedInset
                        : elevations.keyInset,
                  ),
                  child: ClipRRect(
                    borderRadius: radius,
                    child: AnimatedBuilder(
                      animation: _gleam,
                      builder: (context, child) => CustomPaint(
                        foregroundPainter: _GleamPainter(
                          progress: _gleam.value,
                          colour: colors.surface,
                        ),
                        child: child,
                      ),
                      child: SizedBox(
                        height: AppSizes.biometricKeyHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Badge(
                                glyph: glyph,
                                ink: ink,
                                glass: colors.surface,
                                ring: _gleam,
                              ),
                              AppSpacing.gapMd,
                              Flexible(
                                child: Text(
                                  softWrap: false,
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.titleSmall?.copyWith(
                                    color: ink,
                                    fontWeight: AppFonts.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The key's mark in a round badge of lit glass, sending a ring out as
/// [ring] runs.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.glyph,
    required this.ink,
    required this.glass,
    required this.ring,
  });

  final AppGlyph glyph;
  final Color ink;

  /// The light the badge's glass is made of.
  final Color glass;
  final Animation<double> ring;

  @override
  Widget build(BuildContext context) {
    const size = AppSizes.biometricBadge;
    return SizedBox.square(
      dimension: size,
      child: AnimatedBuilder(
        animation: ring,
        builder: (context, child) {
          final t = Curves.easeOut.transform(ring.value);
          return CustomPaint(
            painter: _RingPainter(progress: t, colour: glass),
            child: child,
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [
                glass.withValues(alpha: 0.85),
                glass.withValues(alpha: 0.45),
              ],
            ),
            border: Border.all(color: glass.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: ink.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: AppGlyphIcon(
              glyph,
              depth: true,
              size: AppSizes.iconMd,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A ring spreading from the badge and fading as [progress] runs.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final radius = size.width / 2 * (1 + 0.5 * progress);
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - progress)
        ..color = colour.withValues(alpha: 0.6 * (1 - progress)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colour != colour;
}

/// A slanted band of light sweeping across the key as [progress] runs.
class _GleamPainter extends CustomPainter {
  const _GleamPainter({required this.progress, required this.colour});

  final double progress;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final band = size.height * 1.2;
    final x =
        -band + (size.width + band * 2) * Curves.easeInOut.transform(progress);
    final rect = Rect.fromLTWH(
      x - band / 2,
      -size.height,
      band,
      size.height * 3,
    );
    canvas
      ..save()
      ..translate(rect.center.dx, size.height / 2)
      ..rotate(math.pi / 8)
      ..translate(-rect.center.dx, -size.height / 2)
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              colour.withValues(alpha: 0),
              colour.withValues(alpha: 0.28),
              colour.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_GleamPainter old) =>
      old.progress != progress || old.colour != colour;
}
