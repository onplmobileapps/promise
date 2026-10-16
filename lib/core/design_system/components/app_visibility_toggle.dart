import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/components/app_icon_tile.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The eye beside a secret field that shows or hides what is typed. While
/// it shows, the eye is open and lit in jade, its iris glinting; while it
/// is hidden, the eye is shut, lashes down. It blinks between the two, and
/// sinks a little while pressed.
class AppVisibilityToggle extends StatefulWidget {
  const AppVisibilityToggle({
    super.key,
    required this.visible,
    required this.onPressed,
    required this.showLabel,
    required this.hideLabel,
  });

  /// Whether what is typed shows now.
  final bool visible;
  final VoidCallback onPressed;

  /// What the key does, said while the text is hidden, and while it shows.
  final String showLabel;
  final String hideLabel;

  @override
  State<AppVisibilityToggle> createState() => _AppVisibilityToggleState();
}

class _AppVisibilityToggleState extends State<AppVisibilityToggle>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: widget.visible ? 1 : 0,
    // A spring past open widens the eye for a moment.
    upperBound: 1.2,
  );
  bool _pressed = false;

  @override
  void didUpdateWidget(AppVisibilityToggle old) {
    super.didUpdateWidget(old);
    if (old.visible == widget.visible) return;
    final target = widget.visible ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _open.value = target;
    } else {
      _open.animateTo(
        target,
        curve: widget.visible ? AppMotion.spring : AppMotion.enter,
      );
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.selectionClick();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = widget.visible ? widget.hideLabel : widget.showLabel;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: SizedBox.square(
            dimension: AppSizes.minTapTarget,
            child: Center(
              // On a small raised tile, as the field's own icon is.
              child: AnimatedScale(
                scale: _pressed ? 0.86 : 1,
                duration: AppMotion.short,
                curve: AppMotion.enter,
                child: AppIconTile(
                  size: AppSizes.fieldIconTile,
                  child: AnimatedBuilder(
                    animation: _open,
                    builder: (context, _) => CustomPaint(
                      size: const Size.square(AppSizes.iconMd),
                      painter: _EyePainter(
                        open: _open.value,
                        shut: colors.textTertiary,
                        lit: colors.iconAccent,
                        glint: colors.surface,
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

/// An eye [open] from 0, shut, to 1, open, a little past 1 at a spring's
/// top: [shut]'s colour while closed, [lit]'s while open, with a [glint].
class _EyePainter extends CustomPainter {
  _EyePainter({
    required this.open,
    required this.shut,
    required this.lit,
    required this.glint,
  });

  final double open;
  final Color shut;
  final Color lit;
  final Color glint;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final t = open.clamp(0.0, 1.0);
    final y = s / 2;
    final left = Offset(s * 0.06, y);
    final right = Offset(s * 0.94, y);
    // Shut, both lids bend down into one arc; open, they part into an
    // almond.
    final topBend = y + s * lerpDouble(0.24, -0.5, open)!;
    final bottomBend = y + s * lerpDouble(0.24, 0.5, open)!;
    final almond = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(y, topBend, right.dx, right.dy)
      ..quadraticBezierTo(y, bottomBend, left.dx, left.dy)
      ..close();
    final colour = Color.lerp(shut, lit, t)!;

    // The iris, seen only between the lids.
    if (t > 0) {
      canvas
        ..save()
        ..clipPath(almond);
      final centre = Offset(s / 2, y);
      final iris = s * 0.22;
      canvas
        ..drawCircle(
          centre,
          iris,
          Paint()
            ..shader = RadialGradient(
              colors: [Color.lerp(lit, glint, 0.35)!, lit],
            ).createShader(Rect.fromCircle(center: centre, radius: iris)),
        )
        ..drawCircle(
          centre,
          s * 0.09,
          Paint()..color = Color.lerp(lit, const Color(0xFF000000), 0.55)!,
        )
        ..drawCircle(
          centre + Offset(s * 0.06, -s * 0.06),
          s * 0.04,
          Paint()..color = glint.withValues(alpha: t),
        )
        ..restore();
    }

    final stroke = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // In 3D: a soft shadow under the lids, and the lids lit from above.
    canvas.drawPath(
      almond.shift(Offset(0, s * 0.06)),
      Paint()
        ..color = colour.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.085
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
    );
    canvas.drawPath(
      almond,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colour, glint, 0.25)!,
            Color.lerp(colour, const Color(0xFF000000), 0.2)!,
          ],
        ).createShader(Offset.zero & size),
    );

    // Lashes under the shut lid.
    final lashes = 1 - t;
    if (lashes > 0) {
      final paint = stroke..color = shut.withValues(alpha: lashes);
      for (final at in const [0.22, 0.5, 0.78]) {
        // A point on the lower lid and the way out of it.
        final point = _onCurve(left, Offset(y, bottomBend), right, at);
        final angle = math.pi / 2 + (at - 0.5) * 1.4;
        canvas.drawLine(
          point,
          point +
              Offset(math.cos(angle), math.sin(angle)) * (s * 0.16 * lashes),
          paint,
        );
      }
    }
  }

  static Offset _onCurve(Offset a, Offset control, Offset b, double t) =>
      a * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + b * (t * t);

  @override
  bool shouldRepaint(_EyePainter old) =>
      old.open != open ||
      old.shut != shut ||
      old.lit != lit ||
      old.glint != glint;
}
