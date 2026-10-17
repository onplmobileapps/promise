import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_haptics.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The design's switch: a ball of a knob on a track that is a jade key when
/// on and sunk into the page when off. A null [onChanged] disables it.
///
/// As on iOS, while it is touched or on its way the knob swells into a
/// clear lens of liquid glass that glides over the track, and settles back
/// into a knob.
class AppSwitch extends StatefulWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Names it for screen readers when nothing beside it does.
  final String? label;

  /// Where the knob's light comes from.
  static const Alignment _knobLight = Alignment(-0.3, -0.44);
  static const List<double> _knobStops = [0, 0.45, 1];

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> with TickerProviderStateMixin {
  /// Where the knob is, from off (0) to on (1).
  late final _at = AnimationController(
    vsync: this,
    value: widget.value ? 1 : 0,
    duration: AppMotion.medium,
  );

  /// How much the knob has turned to glass.
  late final _glass = AnimationController(
    vsync: this,
    duration: AppMotion.glassRise,
    reverseDuration: AppMotion.glassFade,
  );
  bool _held = false;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(AppSwitch old) {
    super.didUpdateWidget(old);
    if (widget.value == old.value) return;
    if (_still) {
      _at.value = widget.value ? 1 : 0;
      return;
    }
    _glass.forward();
    _at
        .animateTo(widget.value ? 1 : 0, curve: AppMotion.spring)
        .whenComplete(_settle);
  }

  void _touch(PointerDownEvent _) {
    if (widget.onChanged == null || _still) return;
    _held = true;
    _glass.forward();
  }

  void _release(PointerEvent _) {
    _held = false;
    // Let go before it moved, as when a tap is about to toggle it: the
    // glass stays for the trip and settles after.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_at.isAnimating) _settle();
    });
  }

  void _settle() {
    if (!mounted || _held) return;
    _glass.reverse();
  }

  @override
  void dispose() {
    _at.dispose();
    _glass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final value = widget.value;
    final onChanged = widget.onChanged;
    final enabled = onChanged != null;
    const track = StadiumBorder();
    final face = DecoratedBox(
      decoration: ShapeDecoration(
        shape: value
            ? track
            : StadiumBorder(side: BorderSide(color: colors.outlineStrong)),
        gradient: value
            ? AppButton.keyGradient(
                colors.primaryHighlight,
                colors.primary,
                colors.primaryShade,
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.surfaceSunken, colors.surfaceSunkenEnd],
              ),
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(
          shape: track,
          shadows: elevations.recessInset,
        ),
        child: SizedBox(
          width: AppSizes.switchWidth,
          height: AppSizes.switchHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([_at, _glass]),
            builder: (context, _) {
              final glass = Curves.easeOut.transform(_glass.value);
              final at = _at.value;
              return AppLiquidGlass(
                amount: glass,
                lens: (size) => _lens(size, at, glass),
                child: Align(
                  alignment: Alignment.lerp(
                    Alignment.centerLeft,
                    Alignment.centerRight,
                    at,
                  )!,
                  child: Padding(
                    padding: const EdgeInsets.all(_inset),
                    // The knob clears as the glass takes its place.
                    child: Opacity(
                      opacity: 1 - glass,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: AppSwitch._knobLight,
                            colors: [
                              colors.knob,
                              colors.knob,
                              colors.knobShade,
                            ],
                            stops: AppSwitch._knobStops,
                          ),
                          boxShadow: elevations.knob,
                        ),
                        child: const SizedBox.square(
                          dimension: AppSizes.switchKnob,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: widget.label,
      // Its own ink, so it works on any surface.
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: enabled
              ? () {
                  AppHaptics.select();
                  onChanged(!value);
                }
              : null,
          radius: AppSizes.minTapTarget / 2,
          borderRadius: AppRadius.borderPill,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTapTarget,
              minHeight: AppSizes.minTapTarget,
            ),
            child: Listener(
              onPointerDown: _touch,
              onPointerUp: _release,
              onPointerCancel: _release,
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: enabled ? face : Opacity(opacity: 0.5, child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _inset =
      (AppSizes.switchHeight - AppSizes.switchKnob) / 2;

  /// The glass lens: the knob where it is, swollen and stretched along the
  /// track as it turns to glass.
  static RRect _lens(Size size, double at, double glass) {
    final travel = size.width - _inset * 2 - AppSizes.switchKnob;
    final knob = Rect.fromLTWH(
      _inset + travel * at,
      _inset,
      AppSizes.switchKnob,
      AppSizes.switchKnob,
    );
    return liquidShape(
      knob,
      motion: glass * AppSizes.switchGlassStretch,
      lift: glass,
    );
  }
}
