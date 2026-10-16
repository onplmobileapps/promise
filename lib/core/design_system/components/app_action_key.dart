import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_pressable.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A round raised key for a screen's main action, like check-in in the
/// middle of the navigation bar. It is jade, lit from above, and stands on
/// its edge inside a [ringColor] ring. It sinks while pressed and shows a
/// spinner while [isLoading]. With [glow] it calls the eye: a soft jade
/// glow breathes round it.
class AppActionKey extends StatelessWidget {
  const AppActionKey({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.size = AppSizes.navActionSize,
    this.ringColor,
    this.glow = false,
  });

  /// Drawn in the key's ink colour, about half its size.
  final Widget icon;

  /// What a screen reader says.
  final String label;

  /// Null disables the key.
  final VoidCallback? onPressed;
  final bool isLoading;
  final double size;

  /// A band around the key, such as the bar it rises from; none by default.
  final Color? ringColor;

  /// Glows softly, as the app's main action.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final key = _key(context);
    if (!glow || isLoading) return key;
    return _Glow(
      size: size + (ringColor == null ? 0 : AppSizes.navActionRing * 2),
      child: key,
    );
  }

  Widget _key(BuildContext context) {
    return AppPressable(
      label: label,
      onPressed: isLoading ? null : onPressed,
      builder: (context, pressed, focused) {
        final colors = context.colors;
        final elevations = context.elevations;
        final ring = ringColor;
        final ink = colors.onPrimary;
        final sink = AppSizes.keyEdge - AppSizes.keyEdgePressed;
        // The key keeps room for its edge below it and moves into that room
        // while pressed, so it never changes size.
        return Padding(
          padding: EdgeInsets.only(
            top: pressed ? sink : 0,
            bottom: pressed ? AppSizes.keyEdgePressed : AppSizes.keyEdge,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppButton.keyGradient(
                colors.primaryHighlight,
                colors.primary,
                colors.primaryShade,
              ),
              border: ring == null
                  ? null
                  : Border.all(
                      color: ring,
                      width: AppSizes.navActionRing,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
              boxShadow: [
                if (focused)
                  BoxShadow(color: colors.focusRing, spreadRadius: 3),
                ...(pressed ? elevations.keyPressed : elevations.key),
              ],
            ),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: isLoading
                    ? SizedBox.square(
                        dimension: AppSizes.iconMd,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: AppSizes.spinnerStroke,
                          valueColor: AlwaysStoppedAnimation(ink),
                        ),
                      )
                    : IconTheme.merge(
                        data: IconThemeData(color: ink, size: AppSizes.iconLg),
                        child: icon,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A soft glow round [child] that breathes a few times as it appears, then
/// rests half lit; still from the start for those who ask for less motion,
/// and on a phone short of drawing power. A glow that breathed for ever
/// would redraw the screen, frosted bar and all, every frame the key was
/// in view.
class _Glow extends StatefulWidget {
  const _Glow({required this.size, required this.child});

  /// The key's width, ring included, that the glow surrounds.
  final double size;
  final Widget child;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.keyGlow,
    value: _rest,
  );

  /// Breaths it takes before resting.
  static const int _breaths = 3;

  /// Where in a breath it rests: half lit.
  static const double _rest = 0.25;

  bool _breathed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        AppPerformance.liteOf(context)) {
      _pulse
        ..stop()
        ..value = _rest;
      return;
    }
    if (_breathed) return;
    _breathed = true;
    _pulse.value = 0;
    _pulse.repeat(count: _breaths).whenCompleteOrCancel(() {
      // From the end of a breath, dim, up to half lit.
      if (mounted) {
        _pulse
          ..value = 0
          ..animateTo(_rest);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlowPainter(
        progress: _pulse,
        size: widget.size,
        glow: context.colors.primary,
      ),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.progress, required this.size, required this.glow})
    : super(repaint: progress);

  final Animation<double> progress;
  final double size;
  final Color glow;

  @override
  void paint(Canvas canvas, Size box) {
    // The key's face sits at the top of its box, over the room for its edge.
    final centre = Offset(box.width / 2, size / 2);
    final breath = 0.5 - 0.5 * math.cos(progress.value * 2 * math.pi);
    canvas.drawCircle(
      centre,
      size / 2 + AppSizes.keyGlowSpread * (0.5 + 0.5 * breath),
      Paint()
        ..color = glow.withValues(alpha: 0.14 + 0.12 * breath)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          AppSizes.keyGlowBlur,
        ),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.size != size || old.glow != glow;
}
