import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// The colours of the design's liquid glass selection: a quiet pill while
/// it rests under the selected choice, and a clear, lit drop of glass while
/// it is held or on the move, as on iOS.
@immutable
class LiquidLook {
  const LiquidLook({
    required this.pill,
    required this.glass,
    required this.shine,
    required this.rim,
    required this.shade,
    required this.dark,
  });

  /// The look for [context]'s theme.
  factory LiquidLook.of(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LiquidLook(
      pill: colors.textPrimary.withValues(alpha: dark ? 0.13 : 0.075),
      glass: dark
          ? colors.textPrimary.withValues(alpha: 0.08)
          : colors.surface.withValues(alpha: 0.28),
      shine: colors.surface,
      rim: dark ? colors.textPrimary.withValues(alpha: 0.55) : colors.surface,
      shade: colors.shadow,
      dark: dark,
    );
  }

  /// The resting pill.
  final Color pill;

  /// The clear body of the drop.
  final Color glass;

  /// The light the drop catches at its top.
  final Color shine;
  final Color rim;

  /// Its shadow.
  final Color shade;
  final bool dark;

  @override
  bool operator ==(Object other) =>
      other is LiquidLook &&
      other.pill == pill &&
      other.glass == glass &&
      other.shine == shine &&
      other.rim == rim &&
      other.shade == shade &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(pill, glass, shine, rim, shade, dark);
}

/// The selection's shape at a moment: [rest] stretched along its way by
/// [motion] (0 at rest to 1 at full speed) and swollen by [lift] (0 resting
/// to 1 held), round at its ends.
RRect liquidShape(Rect rest, {double motion = 0, double lift = 0}) {
  final swell =
      1 + AppSizes.liquidSwell * lift + AppSizes.navLensSwell * motion;
  final width = rest.width * (1 + AppSizes.navLensStretch * motion) * swell;
  final height = rest.height * (1 - AppSizes.navLensSquash * motion) * swell;
  final shape = Rect.fromCenter(
    center: rest.center,
    width: width,
    height: height,
  );
  return RRect.fromRectAndRadius(shape, Radius.circular(height / 2));
}

/// The resting pill, [opacity] faded.
void paintLiquidPill(
  Canvas canvas,
  RRect shape,
  LiquidLook look, {
  double opacity = 1,
}) {
  if (opacity <= 0) return;
  canvas.drawRRect(
    shape,
    Paint()..color = look.pill.withValues(alpha: look.pill.a * opacity),
  );
}

/// The drop of glass, [opacity] faded in: clear at its heart, a bright rim
/// where the light comes from, a band of shine across its top and a soft
/// shadow under it.
void paintLiquidDrop(
  Canvas canvas,
  RRect shape,
  LiquidLook look, {
  double opacity = 1,
}) {
  if (opacity <= 0) return;
  final o = opacity.clamp(0.0, 1.0);
  final bounds = shape.outerRect;
  Color fade(Color c, double alpha) => c.withValues(alpha: alpha * o);

  canvas.drawRRect(
    shape.shift(const Offset(0, 3)),
    Paint()..color = fade(look.shade, look.dark ? 0.35 : 0.12),
  );
  canvas.drawRRect(
    shape,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 0.95,
        colors: [
          fade(look.glass, look.glass.a * 0.6),
          fade(look.glass, math.min(1, look.glass.a * 1.8)),
        ],
      ).createShader(bounds),
  );
  final shine = RRect.fromRectAndRadius(
    Rect.fromLTRB(
      bounds.left + bounds.width * 0.14,
      bounds.top + 2,
      bounds.right - bounds.width * 0.14,
      bounds.top + bounds.height * 0.46,
    ),
    Radius.circular(bounds.height / 3),
  );
  canvas.drawRRect(
    shine,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fade(look.shine, look.dark ? 0.26 : 0.75),
          fade(look.shine, 0),
        ],
      ).createShader(shine.outerRect),
  );
  // A thin bright rim, brightest at the top left and again at the foot,
  // where light bends through the edge.
  canvas.drawRRect(
    shape.deflate(0.75),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fade(look.rim, 1), fade(look.rim, 0.12), fade(look.rim, 0.7)],
        stops: const [0, 0.55, 1],
      ).createShader(bounds),
  );
}

/// A tab bar's indicator of liquid glass: at rest it is [base], the design's
/// raised thumb; while the selection moves between tabs it stretches along
/// its way, swells a little and fades under the glass laid over it, and
/// settles back into the thumb as it arrives.
class LiquidTabIndicator extends Decoration {
  const LiquidTabIndicator({
    required this.base,
    required this.animation,
    required this.look,
  });

  final BoxDecoration base;

  /// The tab controller's animation, whose fraction says how far between
  /// two tabs the selection is.
  final Animation<double>? animation;
  final LiquidLook look;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _LiquidTabPainter(this, onChanged);
}

class _LiquidTabPainter extends BoxPainter {
  _LiquidTabPainter(this._decoration, VoidCallback? onChanged)
    : _base = _decoration.base.createBoxPainter(onChanged),
      super(onChanged);

  final LiquidTabIndicator _decoration;
  final BoxPainter _base;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final value = _decoration.animation?.value ?? 0;
    final between = (value - value.floorToDouble()).abs();
    // Most on the move halfway between two tabs.
    final motion = math.sin(between * math.pi).clamp(0.0, 1.0);
    final rest = offset & size;
    if (motion < 0.01) {
      _base.paint(canvas, offset, configuration);
      return;
    }
    final shape = liquidShape(rest, motion: motion * 0.7, lift: motion * 0.35);
    final bounds = shape.outerRect;
    // The thumb, stretched with it and fading as the glass shows.
    canvas.saveLayer(
      bounds.inflate(AppSizes.liquidShadowRoom),
      Paint()..color = Color.fromRGBO(0, 0, 0, 1 - motion * 0.8),
    );
    _base.paint(
      canvas,
      bounds.topLeft,
      configuration.copyWith(size: bounds.size),
    );
    canvas.restore();
  }

  @override
  void dispose() {
    _base.dispose();
    super.dispose();
  }
}

/// Makes a choice come alive as iOS's controls do: while it is touched a
/// lens of liquid glass rises over it, and when it is picked it swells on
/// a soft spring and settles with a wobble while the glass melts away.
/// [radius] rounds the glass to the choice's shape.
class LiquidPop extends StatefulWidget {
  const LiquidPop({
    super.key,
    required this.selected,
    required this.child,
    this.radius,
    this.amount = AppSizes.liquidPop,
  });

  final bool selected;
  final Widget child;

  /// The choice's corners; a capsule by default.
  final BorderRadius? radius;

  /// How much it swells at most, as a share of its size.
  final double amount;

  @override
  State<LiquidPop> createState() => _LiquidPopState();
}

class _LiquidPopState extends State<LiquidPop> with TickerProviderStateMixin {
  late final _pop = AnimationController.unbounded(vsync: this);
  late final _glass = AnimationController(
    vsync: this,
    duration: AppMotion.glassRise,
    reverseDuration: AppMotion.glassFade,
  );
  bool _held = false;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: AppMotion.liftStiffness,
    damping: AppMotion.liftDamping,
  );

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(LiquidPop old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected && !_still) {
      // Pushed out from rest, it swings past and back to rest.
      _pop.animateWith(
        SpringSimulation(_spring, 0, 0, AppMotion.liquidPopVelocity),
      );
      _glass.forward().whenComplete(_melt);
    }
  }

  void _touch(PointerDownEvent _) {
    if (_still) return;
    _held = true;
    _glass.forward();
  }

  void _release(PointerEvent _) {
    _held = false;
    if (_glass.status == AnimationStatus.forward) {
      // Still rising: it melts once it is up.
      _glass.forward().whenComplete(_melt);
    } else {
      _melt();
    }
  }

  void _melt() {
    if (!mounted || _held) return;
    _glass.reverse();
  }

  @override
  void dispose() {
    _pop.dispose();
    _glass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _touch,
      onPointerUp: _release,
      onPointerCancel: _release,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pop, _glass]),
        child: widget.child,
        // Wrapped the same way at rest, so the choice keeps its state.
        builder: (context, child) => Transform.scale(
          scale: 1 + widget.amount * (_pop.value + _glass.value * 0.35),
          child: AppLiquidGlass(
            amount: Curves.easeOut.transform(_glass.value),
            radius: widget.radius,
            style: LiquidGlassStyle.sheen,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A lens of liquid glass over [child] while it is [pressed], rising fast
/// and melting slowly once it is let go, as iOS's buttons do. [radius]
/// rounds it to the child's shape.
class LiquidPress extends StatefulWidget {
  const LiquidPress({
    super.key,
    required this.pressed,
    required this.child,
    this.radius,
  });

  final bool pressed;
  final Widget child;

  /// The child's corners; a capsule by default.
  final BorderRadius? radius;

  @override
  State<LiquidPress> createState() => _LiquidPressState();
}

class _LiquidPressState extends State<LiquidPress>
    with SingleTickerProviderStateMixin {
  late final _glass = AnimationController(
    vsync: this,
    duration: AppMotion.glassRise,
    reverseDuration: AppMotion.glassFade,
  );

  @override
  void didUpdateWidget(LiquidPress old) {
    super.didUpdateWidget(old);
    if (widget.pressed == old.pressed) return;
    if (widget.pressed) {
      if (!MediaQuery.disableAnimationsOf(context)) _glass.forward();
    } else if (_glass.status == AnimationStatus.forward) {
      // A quick tap still shows the glass before it melts.
      _glass.forward().whenComplete(() {
        if (mounted && !widget.pressed) _glass.reverse();
      });
    } else {
      _glass.reverse();
    }
  }

  @override
  void dispose() {
    _glass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _glass,
    child: widget.child,
    builder: (context, child) => AppLiquidGlass(
      amount: Curves.easeOut.transform(_glass.value),
      radius: widget.radius,
      style: LiquidGlassStyle.sheen,
      child: child,
    ),
  );
}
