import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/khatam_pattern.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The page every screen sits on: the ivory background with the khatam
/// pattern fading down from the top, over one of two washes.
///
/// [AppBackdrop.new] lays a sage wash across the top, [washHeight] deep or
/// the whole height: for the home screen and module dashboards.
/// [AppBackdrop.blobs] lays soft blobs of jade, sand and sky instead: for
/// sign-in, settings and forms.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    super.key,
    required this.child,
    this.washHeight,
    this.patternFade,
    this.washColor,
    this.patternColor,
  }) : blobIntensity = null;

  const AppBackdrop.blobs({
    super.key,
    required this.child,
    this.blobIntensity = AppSizes.blobIntensity,
    this.patternFade = AppSizes.blobPattern,
  }) : washHeight = null,
       washColor = null,
       patternColor = null;

  final Widget child;
  final double? washHeight;

  /// How strongly the blobs show, from 0 to 1; null for the wash.
  final double? blobIntensity;

  /// How far down the pattern runs before it has faded out.
  final double? patternFade;

  /// The wash and the pattern in another tint, like coral on a report of
  /// an accident; the sage ones by default.
  final Color? washColor;
  final Color? patternColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = patternColor ?? colors.pattern;
    final pattern = patternFade == null
        ? KhatamPatternPainter(color: ink)
        : KhatamPatternPainter(color: ink, fadeHeight: patternFade!);
    // The page repaints on its own, never the pattern under it: an
    // animation on the page doesn't paint the whole backdrop again.
    final child = RepaintBoundary(child: this.child);
    final intensity = blobIntensity;
    final backgroundPattern = RepaintBoundary(
      child: CustomPaint(
        painter: pattern,
        child: const SizedBox.expand(),
      ),
    );

    if (intensity != null) {
      final blobBackground = RepaintBoundary(
        child: CustomPaint(
          painter: _BlobsPainter(colors: colors, intensity: intensity),
          child: const SizedBox.expand(),
        ),
      );
      return ColoredBox(
        color: colors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            blobBackground,
            backgroundPattern,
            child,
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final wash = washHeight;
        // Past the wash, the gradient holds the background colour.
        final washEnd = wash == null || !height.isFinite || height <= 0
            ? 1.0
            : (wash / height).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [washColor ?? colors.backgroundWash, colors.background],
              stops: [0, washEnd],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              backgroundPattern,
              child,
            ],
          ),
        );
      },
    );
  }
}

/// One soft blob: a disc [diameter] across, blurred by [blur], placed from
/// the top and from the left or, with [fromRight], the right.
@immutable
class _Blob {
  const _Blob({
    required this.x,
    required this.top,
    required this.diameter,
    required this.blur,
    this.fromRight = false,
  });

  final double x;
  final double top;
  final double diameter;
  final double blur;
  final bool fromRight;
}

/// Jade at the top left, sand to the right, sky further down, each a disc
/// so blurred it reads as a glow.
class _BlobsPainter extends CustomPainter {
  const _BlobsPainter({required this.colors, required this.intensity});

  final AppColors colors;
  final double intensity;

  static const _jade = _Blob(x: -130, top: -110, diameter: 390, blur: 60);
  static const _sand = _Blob(
    x: -150,
    top: 60,
    diameter: 350,
    blur: 70,
    fromRight: true,
  );
  static const _sky = _Blob(x: 40, top: 470, diameter: 330, blur: 80);

  @override
  void paint(Canvas canvas, Size size) {
    for (final (blob, color) in [
      (_jade, colors.blobJade),
      (_sand, colors.blobSand),
      (_sky, colors.blobSky),
    ]) {
      if (color.a == 0) continue;
      final radius = blob.diameter / 2;
      // [x] is how far the disc's near edge sits from its side of the page;
      // negative runs it off the page.
      final centre = Offset(
        blob.fromRight ? size.width - blob.x - radius : blob.x + radius,
        blob.top + radius,
      );
      // A blurred disc: full until its blur begins, gone where it ends.
      final reach = radius + blob.blur * 2;
      final tint = color.withValues(alpha: color.a * intensity);
      canvas.drawCircle(
        centre,
        reach,
        Paint()
          ..shader = RadialGradient(
            colors: [tint, tint, tint.withValues(alpha: 0)],
            stops: [0, ((radius - blob.blur) / reach).clamp(0.0, 1.0), 1],
          ).createShader(Rect.fromCircle(center: centre, radius: reach)),
      );
    }
  }

  @override
  bool shouldRepaint(_BlobsPainter old) =>
      old.colors != colors || old.intensity != intensity;
}
