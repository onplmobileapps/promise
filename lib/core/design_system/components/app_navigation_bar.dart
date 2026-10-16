import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:railway_hrms/core/design_system/components/app_liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/app_pressable.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/components/outer_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// One item of an [AppNavigationBar]: a line [glyph], whose tint deepens
/// when selected, and its [label]. An item that isn't [visible] folds away,
/// the others easing over to fill its room, and unfolds the same way.
@immutable
class AppNavItem {
  const AppNavItem({
    required this.glyph,
    required this.label,
    this.visible = true,
  });

  final AppGlyph glyph;
  final String label;
  final bool visible;
}

/// The bottom navigation bar, as iOS draws its tab bars: a capsule of
/// frosted glass floating over the page, which blurs through it. [items]
/// sit either side of an optional [action], such as an `AppActionKey`,
/// which stands above the bar in its middle.
///
/// The selected item rests on a quiet pill, its icon and name in the
/// brand's colour. Touched, the pill turns into a drop of clear liquid
/// glass that swells out of the bar under the finger and magnifies what it
/// passes; it follows a drag along the bar, and on release runs to the
/// item picked on a spring. It is jelly: it stretches as it speeds up,
/// and when it stops it squashes and wobbles before it settles back into
/// a pill, while the glint on its rim sweeps round with its travel. The
/// bar swells a touch while held, a drag ticks as it crosses each item,
/// and pulled past either end the drop gives like rubber. Picking an item
/// any other way runs the same.
///
/// The bar's own height includes the room the action stands up into, so
/// all of the action can be tapped; only the capsule below that is drawn.
class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.action,
  });

  final List<AppNavItem> items;

  /// The selected item, or null when none is.
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget? action;

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar>
    with TickerProviderStateMixin {
  /// The selection's centre as a share of the bar's width; below 0 for
  /// none.
  late final AnimationController _lens = AnimationController.unbounded(
    vsync: this,
    value: _target,
  );

  /// How far it is lifted into a drop of glass, from 0 to 1.
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );

  /// Where a touch went down, and whether it has turned into a drag.
  Offset? _down;
  bool _dragging = false;

  /// The slot a drag is over, to tick as it crosses into another.
  int? _dragSlot;

  /// The drop's jelly: how stretched it is (below 0, squashed), on an
  /// underdamped spring chasing how fast it moves, so it wobbles as it
  /// stops; and its speed, signed, smoothed, which swings the light.
  late final Ticker _jellyTicker = createTicker(_tickJelly);
  double _jelly = 0;
  double _jellySpeed = 0;
  double _drift = 0;
  double _lastLens = 0;
  Duration? _lastTick;

  static const _run = SpringDescription(
    mass: 1,
    stiffness: AppMotion.lensStiffness,
    damping: AppMotion.lensDamping,
  );

  /// Settles the drop back into a pill with a wobble.
  static const _settle = SpringDescription(
    mass: 1,
    stiffness: AppMotion.liftStiffness,
    damping: AppMotion.liftDamping,
  );

  bool get _still => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _lens.addListener(_wakeJelly);
  }

  void _wakeJelly() {
    if (_jellyTicker.isActive || _still) return;
    _lastTick = null;
    _lastLens = _lens.value;
    _jellyTicker.start();
  }

  void _tickJelly(Duration now) {
    final last = _lastTick;
    _lastTick = now;
    if (last == null) return;
    final dt = ((now - last).inMicroseconds / 1e6).clamp(0.001, 0.05);
    final lens = _lens.value;
    // In bar widths a second, whether a spring or a finger moves it.
    final speed = lens < 0 || _lastLens < 0 ? 0.0 : (lens - _lastLens) / dt;
    _lastLens = lens;
    final target = (speed.abs() * AppMotion.lensMotionGain).clamp(0.0, 1.2);
    final pull =
        AppMotion.jellyStiffness * (target - _jelly) -
        AppMotion.jellyDamping * _jellySpeed;
    _jellySpeed += pull * dt;
    _jelly = (_jelly + _jellySpeed * dt).clamp(-0.4, 1.2);
    final swing = (speed * AppMotion.lensMotionGain).clamp(-1.0, 1.0);
    _drift += (swing - _drift) * math.min(1, dt * 14);
    final settled =
        !_lens.isAnimating &&
        !_dragging &&
        _jelly.abs() < 0.002 &&
        _jellySpeed.abs() < 0.02 &&
        _drift.abs() < 0.002;
    if (settled) {
      _jelly = _jellySpeed = _drift = 0;
      _jellyTicker.stop();
    }
    setState(() {});
  }

  /// Where the light comes from: the top left at rest, swung by the
  /// drop's travel so its glint sweeps along the rim.
  Offset get _light {
    final angle =
        math.atan2(
          AppLiquidGlass.defaultLight.dy,
          AppLiquidGlass.defaultLight.dx,
        ) +
        _drift * AppMotion.glintSwing;
    return Offset(math.cos(angle), math.sin(angle));
  }

  int get _before => widget.action == null
      ? widget.items.length
      : (widget.items.length + 1) ~/ 2;

  /// The slots that show, in order: an item's index, or null for the
  /// action.
  List<int?> get _slots => [
    for (var i = 0; i < _before; i++)
      if (widget.items[i].visible) i,
    if (widget.action != null) null,
    for (var i = _before; i < widget.items.length; i++)
      if (widget.items[i].visible) i,
  ];

  double _centreOf(int slot) => (slot + 0.5) / math.max(1, _slots.length);

  double get _target {
    final selected = widget.selectedIndex;
    final slot = selected == null ? -1 : _slots.indexOf(selected);
    return slot < 0 ? -1 : _centreOf(slot);
  }

  @override
  void didUpdateWidget(AppNavigationBar old) {
    super.didUpdateWidget(old);
    if (_dragging) return;
    final moved = old.selectedIndex != widget.selectedIndex;
    _runTo(_target);
    // Picked some other way than a touch on the bar: the drop still
    // swells on its way and settles.
    if (moved && _down == null && !_still && _lens.value >= 0) {
      _lift
        ..value = 0
        ..animateTo(
          AppMotion.liftPeek,
          duration: AppMotion.short,
          curve: Curves.easeOut,
        ).whenComplete(_land);
    }
  }

  void _runTo(double target) {
    if (target < 0 || _lens.value < 0 || _still) {
      _lens.value = target;
      return;
    }
    _lens.animateWith(
      SpringSimulation(_run, _lens.value, target, _lens.velocity),
    );
  }

  void _land() {
    if (!mounted || _down != null) return;
    if (_still) {
      _lift.value = 0;
      return;
    }
    _lift.animateWith(
      SpringSimulation(_settle, _lift.value, 0, _lift.velocity),
    );
  }

  double _clamp(double share) {
    final slots = _slots;
    return share.clamp(_centreOf(0), _centreOf(slots.length - 1)).toDouble();
  }

  /// [share] held to the bar, giving like rubber past either end: the
  /// further it is pulled, the less it goes.
  double _rubber(double share) {
    final held = _clamp(share);
    final over = share - held;
    if (over == 0) return held;
    final reach = 0.5 / math.max(1, _slots.length);
    return held + reach * over / (over.abs() + reach) * 0.6;
  }

  void _onDown(PointerDownEvent event, double width) {
    if (_lens.value < 0 || width <= 0) return;
    _down = event.localPosition;
    if (_still) return;
    _lift.animateWith(
      SpringSimulation(_settle, _lift.value, 1, _lift.velocity),
    );
    // The drop gathers under the finger.
    _runTo(_clamp(event.localPosition.dx / width));
  }

  void _onMove(PointerMoveEvent event, double width) {
    final down = _down;
    if (down == null || width <= 0) return;
    if (!_dragging &&
        (event.localPosition.dx - down.dx).abs() > AppSizes.dragSlop) {
      setState(() => _dragging = true);
    }
    if (_dragging) {
      _lens.stop();
      _lens.value = _rubber(event.localPosition.dx / width);
      _wakeJelly();
      // A tick for each item crossed, as iOS's controls give.
      final slot = (_clamp(_lens.value) * _slots.length - 0.5).round();
      if (slot != _dragSlot) {
        if (_dragSlot != null) HapticFeedback.selectionClick();
        _dragSlot = slot;
      }
    }
  }

  void _onUp() {
    final dragged = _dragging;
    _down = null;
    _dragSlot = null;
    if (dragged) {
      setState(() => _dragging = false);
      final slots = _slots;
      final nearest = (_lens.value * slots.length - 0.5).round().clamp(
        0,
        slots.length - 1,
      );
      final index = slots[nearest];
      if (index != null && index != widget.selectedIndex) {
        widget.onSelected(index);
      }
    }
    // A tap's item takes the selection itself; either way the drop runs
    // to it and settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runTo(_target);
      _land();
    });
  }

  @override
  void dispose() {
    _jellyTicker.dispose();
    _lens
      ..removeListener(_wakeJelly)
      ..dispose();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lite = AppPerformance.flatOf(context);
    final action = widget.action;
    final items = widget.items;
    final lift = action == null ? 0.0 : AppSizes.navActionLift;
    final before = _before;
    final slots = _slots;
    final actionSlot = action == null ? -1 : slots.indexOf(null);
    final look = LiquidLook.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        math.max(MediaQuery.paddingOf(context).bottom, AppSpacing.md),
      ),
      child: SizedBox(
        height: lift + AppSizes.navBarHeight,
        child: LayoutBuilder(
          builder: (context, box) => Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) => _onDown(e, box.maxWidth),
            onPointerMove: (e) => _onMove(e, box.maxWidth),
            onPointerUp: (_) => _onUp(),
            onPointerCancel: (_) => _onUp(),
            child: AnimatedBuilder(
              animation: Listenable.merge([_lens, _lift]),
              builder: (context, _) {
                final lens = _lens.value;
                final held = _lift.value.clamp(0.0, 1.2);
                // Jelly: stretched on the move, squashed and wobbling as it
                // stops.
                final motion = _jelly;
                final moving = motion.clamp(0.0, 1.0);
                // Each item's nearness to the selection, from 0 to 1.
                double near(int index) {
                  final slot = slots.indexOf(index);
                  if (slot < 0 || lens < 0) return 0;
                  final apart = (lens - _centreOf(slot)).abs() * slots.length;
                  return (1 - apart).clamp(0.0, 1.0);
                }

                Widget item(int index) => _Folding(
                  visible: items[index].visible,
                  child: Padding(
                    padding: EdgeInsets.only(top: lift),
                    child: _NavButton(
                      item: items[index],
                      selected: index == widget.selectedIndex,
                      near: near(index),
                      magnify: near(index) * math.max(held, moving),
                      onTap: () => widget.onSelected(index),
                    ),
                  ),
                );

                final row = Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < before; i++) item(i),
                    // The action's room; it stands over the glass, below.
                    if (action != null)
                      const Expanded(
                        flex: _Folding._share,
                        child: SizedBox.shrink(),
                      ),
                    for (var i = before; i < items.length; i++) item(i),
                  ],
                );

                // The action laid out as the row is, over the glass and
                // outside its clip, so what it draws round itself, like
                // ripples, spreads every way.
                final actionLayer = action == null
                    ? null
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < before; i++)
                            _Folding(
                              visible: items[i].visible,
                              child: const SizedBox.shrink(),
                            ),
                          Expanded(
                            flex: _Folding._share,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: action,
                            ),
                          ),
                          for (var i = before; i < items.length; i++)
                            _Folding(
                              visible: items[i].visible,
                              child: const SizedBox.shrink(),
                            ),
                        ],
                      );

                final selection = _SelectionGeometry(
                  top: lift,
                  centre: lens,
                  share: 1 / math.max(1, slots.length),
                  motion: motion,
                  lift: held,
                );

                // The drop of glass rises over the items and out of the bar,
                // bending them as it passes.
                // The whole bar swells a touch while it is held.
                return Transform.scale(
                  scale: 1 + AppSizes.navHeldSwell * held.clamp(0.0, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: Stack(
                    fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: AppLiquidGlass(
                          amount: math.max(held, moving * 0.6).clamp(0.0, 1.0),
                          lens: selection.shapeIn,
                          light: _light,
                          child: CustomPaint(
                            painter: _GlassShadow(
                              top: lift,
                              shadows: context.elevations.glass,
                            ),
                            child: ClipPath(
                              clipper: _GlassClip(
                                top: lift,
                                actionCentre: actionSlot < 0
                                    ? null
                                    : _centreOf(actionSlot),
                              ),
                              // Solid where the phone can't spare the
                              // blur.
                              child: BackdropFilter(
                                enabled: !lite,
                                filter: ImageFilter.blur(
                                  sigmaX: AppSizes.navGlassBlur,
                                  sigmaY: AppSizes.navGlassBlur,
                                ),
                                child: CustomPaint(
                                  painter: _BarPainter(
                                    top: lift,
                                    fill: colors.surface.withValues(
                                      alpha: lite
                                          ? 1
                                          : AppSizes.navGlassOpacity,
                                    ),
                                    rim: colors.surfaceRaised,
                                    edge: colors.outline,
                                    selection: selection,
                                    look: look,
                                  ),
                                  child: row,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ?actionLayer,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// An item's share of the bar, easing between none and a full share as it
/// shows or hides.
class _Folding extends StatelessWidget {
  const _Folding({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  /// A full share; fractions of it make the in-between widths.
  static const int _share = 1000;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: visible ? 1 : 0),
    duration: AppMotion.medium,
    curve: AppMotion.enter,
    child: child,
    builder: (context, shown, child) => shown <= 0
        ? const SizedBox.shrink()
        : Expanded(
            flex: math.max(1, (shown * _share).round()),
            child: Opacity(opacity: shown, child: child),
          ),
  );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.near,
    required this.magnify,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;

  /// How near the selection is, from 0 to 1: the icon and name take the
  /// brand's colour under it.
  final double near;

  /// How much the drop passing over enlarges the icon, from 0 to 1.
  final double magnify;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ink = Color.lerp(colors.textSecondary, colors.accent, near)!;
    return Semantics(
      selected: selected,
      child: AppPressable(
        label: item.label,
        onPressed: onTap,
        builder: (context, pressed, focused) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 1 + AppSizes.navLensMagnify * magnify,
              child: AppGlyphIcon(
                item.glyph,
                depth: true,
                size: AppSizes.glyphNav,
                color: ink,
                tint: Color.lerp(
                  colors.iconFill,
                  colors.iconFillActive,
                  focused ? 1 : near,
                ),
              ),
            ),
            AppSpacing.gapXxs,
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall?.copyWith(
                color: ink,
                letterSpacing: 0,
                fontWeight: selected ? AppFonts.semiBold : AppFonts.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the selection is and how it moves, shared by the pill drawn in
/// the bar and the drop drawn over it.
@immutable
class _SelectionGeometry {
  const _SelectionGeometry({
    required this.top,
    required this.centre,
    required this.share,
    required this.motion,
    required this.lift,
  });

  final double top;

  /// Its centre as a share of the width; below 0 for none.
  final double centre;

  /// A slot's share of the width.
  final double share;
  final double motion;
  final double lift;

  RRect? shapeIn(Size size) {
    if (centre < 0) return null;
    const inset = AppSpacing.xs;
    final barHeight = size.height - top;
    final rest = Rect.fromCenter(
      center: Offset(size.width * centre, top + barHeight / 2),
      width: size.width * share - inset * 2,
      height: barHeight - inset * 2,
    );
    final shape = liquidShape(rest, motion: motion, lift: lift);
    // Against either end of the bar the drop squashes, as jelly against a
    // wall, rather than spilling past it.
    const room = AppSpacing.xxs;
    final left = math.max(shape.left, -room);
    final right = math.min(shape.right, size.width + room);
    if (left == shape.left && right == shape.right) return shape;
    return RRect.fromLTRBR(
      left,
      shape.top,
      math.max(right, left + shape.height),
      shape.bottom,
      Radius.circular(shape.height / 2),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _SelectionGeometry &&
      other.top == top &&
      other.centre == centre &&
      other.share == share &&
      other.motion == motion &&
      other.lift == lift;

  @override
  int get hashCode => Object.hash(top, centre, share, motion, lift);
}

/// The bar's glass: a tinted fill, a lit rim along its top, a hairline
/// round it, and the selection's resting pill, fading as it lifts.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.top,
    required this.fill,
    required this.rim,
    required this.edge,
    required this.selection,
    required this.look,
  });

  final double top;
  final Color fill;
  final Color rim;
  final Color edge;
  final _SelectionGeometry selection;
  final LiquidLook look;

  @override
  void paint(Canvas canvas, Size size) {
    final pill = _pill(size, top);
    canvas.drawRRect(pill, Paint()..color = fill);
    canvas.drawRRect(
      pill.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rim, edge],
        ).createShader(pill.outerRect),
    );
    final shape = selection.shapeIn(size);
    if (shape != null) {
      paintLiquidPill(
        canvas,
        shape,
        look,
        opacity: 1 - selection.lift.clamp(0.0, 1.0),
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.top != top ||
      old.fill != fill ||
      old.rim != rim ||
      old.edge != edge ||
      old.selection != selection ||
      old.look != look;
}

/// The pill's rounded rectangle in a box [top] down from the bar's top.
RRect _pill(Size size, double top) => RRect.fromRectAndRadius(
  Rect.fromLTRB(0, top, size.width, size.height),
  Radius.circular((size.height - top) / 2),
);

/// The pill, and room round the action standing above it, so the frost
/// covers just what is drawn.
class _GlassClip extends CustomClipper<Path> {
  const _GlassClip({required this.top, required this.actionCentre});

  final double top;

  /// The action's centre as a share of the width; null without one.
  final double? actionCentre;

  @override
  Path getClip(Size size) {
    final path = Path()..addRRect(_pill(size, top));
    final centre = actionCentre;
    if (centre != null) {
      const radius = AppSizes.navActionSize / 2 + AppSizes.navActionRing;
      path.addOval(
        Rect.fromCircle(
          center: Offset(size.width * centre, AppSizes.navActionSize / 2),
          radius: radius,
        ),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(_GlassClip old) =>
      old.top != top || old.actionCentre != actionCentre;
}

/// The pill's shadow, only outside it, so none shows through the glass.
class _GlassShadow extends CustomPainter {
  const _GlassShadow({required this.top, required this.shadows});

  final double top;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(0, top);
    OuterShadowPainter(
      shadows: shadows,
      shape: const StadiumBorder(),
      knockout: true,
    ).paint(canvas, Size(size.width, size.height - top));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassShadow old) =>
      old.top != top || old.shadows != shadows;
}
