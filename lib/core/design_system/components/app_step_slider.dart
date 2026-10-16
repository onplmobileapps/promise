import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A slider that stops at [steps] places, such as text sizes from small to
/// large: a track sunk into the page, jade up to the knob, with a dot at
/// each stop. The knob follows a drag or a tap and settles on the nearest
/// stop; as on iOS it turns to a lens of liquid glass while it is held.
/// [onChanged] hears each new stop as it is reached; null disables it.
class AppStepSlider extends StatefulWidget {
  const AppStepSlider({
    super.key,
    required this.value,
    required this.steps,
    required this.onChanged,
    required this.label,
    required this.valueLabel,
  }) : assert(steps >= 2 && value >= 0 && value < steps);

  /// The stop it is at, from 0.
  final int value;
  final int steps;
  final ValueChanged<int>? onChanged;

  /// What a screen reader calls it.
  final String label;

  /// What a screen reader says each stop is.
  final String Function(int step) valueLabel;

  @override
  State<AppStepSlider> createState() => _AppStepSliderState();
}

class _AppStepSliderState extends State<AppStepSlider>
    with TickerProviderStateMixin {
  /// Where the knob is, from the first stop (0) to the last (1).
  late final _at = AnimationController(
    vsync: this,
    value: _fractionOf(widget.value),
    duration: AppMotion.medium,
  );
  late final _glass = AnimationController(
    vsync: this,
    duration: AppMotion.glassRise,
    reverseDuration: AppMotion.glassFade,
  );
  double _width = 1;
  bool _held = false;

  /// The stop the knob was last put at, which [widget.value] catches up to
  /// a frame later. A tap is down and up again within one frame, so the
  /// knob settles here rather than on the value from before the tap.
  late int _goal = widget.value;

  double _fractionOf(int step) => step / (widget.steps - 1);

  int get _nearest =>
      (_at.value * (widget.steps - 1)).round().clamp(0, widget.steps - 1);

  bool get _still => MediaQuery.disableAnimationsOf(context);

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  @override
  void didUpdateWidget(AppStepSlider old) {
    super.didUpdateWidget(old);
    if (!_held && widget.value != _goal) {
      _goal = widget.value;
      _settle();
    }
  }

  void _follow(double dx) {
    final travel = _width - AppSizes.sliderKnob;
    if (travel <= 0) return;
    var at = ((dx - AppSizes.sliderKnob / 2) / travel).clamp(0.0, 1.0);
    if (_rtl) at = 1 - at;
    _at.value = at;
    final step = _nearest;
    if (step == _goal) return;
    _goal = step;
    widget.onChanged?.call(step);
  }

  void _hold(double dx) {
    if (widget.onChanged == null) return;
    _held = true;
    _at.stop();
    if (!_still) _glass.forward();
    _follow(dx);
  }

  void _letGo() {
    if (!_held) return;
    _held = false;
    _settle();
    _glass.reverse();
  }

  void _settle() {
    final target = _fractionOf(_goal);
    if (_still) {
      _at.value = target;
    } else {
      _at.animateTo(target, curve: AppMotion.spring);
    }
  }

  void _step(int by) {
    final next = (widget.value + by).clamp(0, widget.steps - 1);
    if (next != widget.value) widget.onChanged?.call(next);
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
    final enabled = widget.onChanged != null;
    final value = widget.value;
    return Semantics(
      slider: true,
      enabled: enabled,
      label: widget.label,
      value: widget.valueLabel(value),
      increasedValue: value < widget.steps - 1
          ? widget.valueLabel(value + 1)
          : null,
      decreasedValue: value > 0 ? widget.valueLabel(value - 1) : null,
      onIncrease: enabled && value < widget.steps - 1 ? () => _step(1) : null,
      onDecrease: enabled && value > 0 ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            _width = box.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (d) => _hold(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => _follow(d.localPosition.dx),
              onHorizontalDragEnd: (_) => _letGo(),
              onHorizontalDragCancel: _letGo,
              onTapDown: (d) => _hold(d.localPosition.dx),
              onTapUp: (_) => _letGo(),
              onTapCancel: _letGo,
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: SizedBox(
                  height: AppSizes.minTapTarget,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_at, _glass]),
                    builder: (context, _) {
                      final at = _at.value;
                      final glass = Curves.easeOut.transform(_glass.value);
                      final shown = _rtl ? 1 - at : at;
                      return AppLiquidGlass(
                        amount: glass,
                        lens: (size) => _lens(size, shown, glass),
                        child: CustomPaint(
                          painter: _TrackPainter(
                            at: shown,
                            steps: widget.steps,
                            rtl: _rtl,
                            sunk: colors.surfaceSunken,
                            edge: colors.outlineStrong,
                            fill: colors.primary,
                            tick: colors.textTertiary,
                            tickOn: colors.onPrimary,
                          ),
                          child: Align(
                            alignment: Alignment.lerp(
                              Alignment.centerLeft,
                              Alignment.centerRight,
                              shown,
                            )!,
                            // The knob clears as the glass takes its place.
                            child: Opacity(
                              opacity: 1 - glass,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppButton.keyGradient(
                                    colors.knob,
                                    colors.knob,
                                    colors.knobShade,
                                  ),
                                  boxShadow: elevations.knob,
                                ),
                                child: const SizedBox.square(
                                  dimension: AppSizes.sliderKnob,
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
          },
        ),
      ),
    );
  }

  /// The knob as a lens, swollen and stretched as it turns to glass.
  static RRect _lens(Size size, double at, double glass) {
    final travel = size.width - AppSizes.sliderKnob;
    final knob = Rect.fromLTWH(
      travel * at,
      (size.height - AppSizes.sliderKnob) / 2,
      AppSizes.sliderKnob,
      AppSizes.sliderKnob,
    );
    return liquidShape(
      knob,
      motion: glass * AppSizes.switchGlassStretch,
      lift: glass,
    );
  }
}

/// The sunk track, jade up to the knob, with a dot at each stop.
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.at,
    required this.steps,
    required this.rtl,
    required this.sunk,
    required this.edge,
    required this.fill,
    required this.tick,
    required this.tickOn,
  });

  /// The knob's place from left (0) to right (1).
  final double at;
  final int steps;
  final bool rtl;
  final Color sunk;
  final Color edge;
  final Color fill;
  final Color tick;
  final Color tickOn;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppSizes.sliderKnob / 2;
    final y = size.height / 2;
    final track = RRect.fromLTRBR(
      inset - AppSizes.sliderTrack / 2,
      y - AppSizes.sliderTrack / 2,
      size.width - inset + AppSizes.sliderTrack / 2,
      y + AppSizes.sliderTrack / 2,
      const Radius.circular(AppSizes.sliderTrack / 2),
    );
    canvas
      ..drawRRect(track, Paint()..color = sunk)
      ..drawRRect(
        track.deflate(0.25),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = edge,
      );
    final knobX = inset + (size.width - inset * 2) * at;
    final filled = rtl
        ? Rect.fromLTRB(knobX, track.top, track.right, track.bottom)
        : Rect.fromLTRB(track.left, track.top, knobX, track.bottom);
    canvas.drawRRect(
      RRect.fromRectAndRadius(filled, track.tlRadius),
      Paint()..color = fill,
    );
    for (var i = 0; i < steps; i++) {
      final x = inset + (size.width - inset * 2) * i / (steps - 1);
      final on = rtl ? x >= knobX : x <= knobX;
      canvas.drawCircle(
        Offset(x, y),
        AppSizes.sliderTick,
        Paint()..color = on ? tickOn : tick,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.at != at ||
      old.steps != steps ||
      old.rtl != rtl ||
      old.sunk != sunk ||
      old.edge != edge ||
      old.fill != fill ||
      old.tick != tick ||
      old.tickOn != tickOn;
}
