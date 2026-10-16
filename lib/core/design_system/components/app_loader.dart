import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_logo.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The app's loader: the PROMISE emblem on a soft disc, breathing gently,
/// inside a jade-to-gold arc that runs round it. For whatever loads a
/// screen or a part of one; a key that is busy keeps its own small spinner.
///
/// Still for those who ask for less motion.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = AppSizes.loader, this.label});

  /// A loader in the middle of the space it is given, with [message]
  /// under it when there is one.
  static Widget page({Key? key, String? message}) =>
      _PageLoader(key: key, message: message);

  final double size;

  /// What a screen reader says; "Loading" by default.
  final String? label;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: AppMotion.loaderTurn,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = widget.size;
    return Semantics(
      label: widget.label ?? context.l10n.loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: AnimatedBuilder(
            animation: _spin,
            builder: (context, child) {
              final t = _spin.value;
              // Two breaths a turn, between 94% and 100%.
              final breath = 0.97 + 0.03 * math.sin(t * 4 * math.pi);
              return CustomPaint(
                painter: _RingPainter(
                  turn: t,
                  track: colors.outline,
                  from: colors.primaryShade,
                  to: colors.gold,
                  stroke: size * AppSizes.loaderStrokeShare,
                ),
                child: Center(
                  child: Transform.scale(scale: breath, child: child),
                ),
              );
            },
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // A light face in either theme: the emblem's deep greens
                // need it.
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [colors.textPrimary, colors.textSecondary]
                      : [colors.surface, colors.surfaceMuted],
                ),
                boxShadow: context.elevations.raised,
              ),
              child: SizedBox.square(
                dimension: size * AppSizes.loaderDiscShare,
                child: Center(
                  child: AppEmblem(width: size * AppSizes.loaderEmblemShare),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A faint track round the loader, and an arc on it that runs round,
/// fading from jade at its tail into gold at its head.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.turn,
    required this.track,
    required this.from,
    required this.to,
    required this.stroke,
  });

  /// How far round the arc is, from 0 to 1.
  final double turn;
  final Color track;
  final Color from;
  final Color to;
  final double stroke;

  /// How much of the ring the arc covers.
  static const double _sweep = math.pi * 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final start = turn * 2 * math.pi - math.pi / 2;
    // A flat tail that fades out, and a round gold head drawn on its own:
    // a round cap at the tail would take the gradient's wrapped colour.
    canvas.drawArc(
      rect,
      start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..shader = SweepGradient(
          endAngle: _sweep,
          colors: [from.withValues(alpha: 0), from, to],
          stops: const [0, 0.45, 1],
          transform: GradientRotation(start),
        ).createShader(rect),
    );
    final head = start + _sweep;
    final radius = rect.width / 2;
    canvas.drawCircle(
      rect.center + Offset(math.cos(head), math.sin(head)) * radius,
      stroke / 2,
      Paint()..color = to,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.turn != turn ||
      old.track != track ||
      old.from != from ||
      old.to != to ||
      old.stroke != stroke;
}

class _PageLoader extends StatelessWidget {
  const _PageLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoader(label: message),
            if (message != null) ...[
              AppSpacing.gapLg,
              Text(
                message,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
