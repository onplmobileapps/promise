import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_performance.dart';

/// How a drop of liquid glass bends and catches the light.
@immutable
class LiquidGlassStyle {
  const LiquidGlassStyle({
    required this.rim,
    required this.bend,
    required this.split,
    required this.magnify,
    required this.rimLight,
    required this.ambient,
    required this.saturation,
    required this.brighten,
    required this.shade,
    required this.blur,
    required this.shadow,
  });

  /// The selection that glides between choices, as in a tab bar: deep,
  /// clear and magnifying.
  static const drop = LiquidGlassStyle(
    rim: 16,
    bend: 1.1,
    split: 0.45,
    magnify: 1.14,
    rimLight: 1,
    ambient: 0.12,
    saturation: 1.3,
    brighten: 0.04,
    shade: 0.16,
    blur: 0.4,
    shadow: true,
  );

  /// A choice that has just been picked, such as a chip or a button: a
  /// thin lens over it that barely magnifies.
  static const sheen = LiquidGlassStyle(
    rim: 10,
    bend: 0.8,
    split: 0.35,
    magnify: 1.04,
    rimLight: 1,
    ambient: 0.1,
    saturation: 1.2,
    brighten: 0.05,
    shade: 0.08,
    blur: 0,
    shadow: false,
  );

  /// How deep the curved rim is, in logical pixels.
  final double rim;

  /// How strongly the rim bends what is behind it.
  final double bend;

  /// How far the colours part at the rim.
  final double split;

  /// How much the middle magnifies; 1 for not at all.
  final double magnify;

  /// How bright the lit rim is.
  final double rimLight;

  /// How bright the rim is where no light falls on it.
  final double ambient;

  /// How much richer the colours seen through it are; 1 for unchanged.
  final double saturation;

  /// How much lighter what is seen through it is.
  final double brighten;

  /// How much shade gathers in the rim away from the light.
  final double shade;

  /// How frosted it is, as a blur in logical pixels.
  final double blur;

  /// Whether it casts a soft shadow round itself.
  final bool shadow;

  @override
  bool operator ==(Object other) =>
      other is LiquidGlassStyle &&
      other.rim == rim &&
      other.bend == bend &&
      other.split == split &&
      other.magnify == magnify &&
      other.rimLight == rimLight &&
      other.ambient == ambient &&
      other.saturation == saturation &&
      other.brighten == brighten &&
      other.shade == shade &&
      other.blur == blur &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    rim,
    bend,
    split,
    magnify,
    rimLight,
    ambient,
    saturation,
    brighten,
    shade,
    blur,
    shadow,
  );
}

/// The liquid glass shader, loaded once. Where the engine cannot run a
/// shader over a backdrop (older renderers, and tests), glass falls back
/// to a painted drop.
abstract final class LiquidGlassShader {
  static ui.FragmentProgram? _program;
  static Future<void>? _loading;

  /// The loaded program, or null while loading or where unsupported.
  static ui.FragmentProgram? get program => _program;

  /// Starts loading the shader, if the engine can run it.
  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
      await _warmUp(program);
      _program = program;
    } on Exception catch (error) {
      debugPrint('Liquid glass shader unavailable: $error');
    }
  }

  /// Runs the shader once off screen, so the GPU has it ready and the
  /// first selection to move doesn't stutter while it is built.
  static Future<void> _warmUp(ui.FragmentProgram program) async {
    const box = Rect.fromLTWH(0, 0, 8, 8);
    final shader = program.fragmentShader();
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..saveLayer(box, Paint()..imageFilter = ui.ImageFilter.shader(shader))
      ..drawRect(box, Paint()..color = const Color(0xFFFFFFFF))
      ..restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    image.dispose();
    picture.dispose();
    shader.dispose();
  }
}

/// The shape of a drop of glass in a box of [size], or null for none.
typedef LiquidLensShape = RRect? Function(Size size);

/// A drop of liquid glass laid over [child], [amount] shown (0 for none),
/// as iOS does for a selection: what lies under it, [child] included, is
/// seen through clear glass that magnifies and bends it at the rim, with a
/// bright rim that catches the light.
///
/// The drop fills the box rounded by [radius] (a capsule by default), or
/// takes the shape [lens] gives, such as a selection gliding over a bar.
class AppLiquidGlass extends SingleChildRenderObjectWidget {
  const AppLiquidGlass({
    super.key,
    required this.amount,
    this.lens,
    this.radius,
    this.style = LiquidGlassStyle.drop,
    this.light = defaultLight,
    super.child,
  });

  /// Light from the top left, y down.
  static const defaultLight = Offset(-0.5547, -0.8321);

  final double amount;
  final LiquidLensShape? lens;
  final BorderRadius? radius;
  final LiquidGlassStyle style;

  /// Where the light comes from, y down; the rim glints where it faces
  /// it. A drop on the move swings it, so the glint sweeps round.
  final Offset light;

  @override
  RenderLiquidGlass createRenderObject(BuildContext context) =>
      RenderLiquidGlass(
        amount: amount,
        lens: lens,
        radius: radius,
        style: style,
        light: light,
        look: LiquidLook.of(context),
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
        painted: AppPerformance.flatOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlass renderObject,
  ) {
    renderObject
      ..amount = amount
      ..lens = lens
      ..radius = radius
      ..style = style
      ..light = light
      ..look = LiquidLook.of(context)
      ..pixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..painted = AppPerformance.flatOf(context);
  }
}

/// Paints its child, then the glass over it.
class RenderLiquidGlass extends RenderProxyBox {
  RenderLiquidGlass({
    required double amount,
    required LiquidLensShape? lens,
    required BorderRadius? radius,
    required LiquidGlassStyle style,
    required LiquidLook look,
    required double pixelRatio,
    Offset light = AppLiquidGlass.defaultLight,
    bool painted = false,
  }) : _painted = painted,
       _light = light,
       _amount = amount,
       _lens = lens,
       _radius = radius,
       _style = style,
       _look = look,
       _pixelRatio = pixelRatio;

  double _amount;
  set amount(double value) {
    if (value == _amount) return;
    final wasShown = _shown;
    _amount = value;
    if (_shown != wasShown) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  LiquidLensShape? _lens;
  set lens(LiquidLensShape? value) {
    if (identical(value, _lens)) return;
    _lens = value;
    if (_shown) markNeedsPaint();
  }

  BorderRadius? _radius;
  set radius(BorderRadius? value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  LiquidGlassStyle _style;
  set style(LiquidGlassStyle value) {
    if (value == _style) return;
    _style = value;
    markNeedsPaint();
  }

  Offset _light;
  set light(Offset value) {
    if (value == _light) return;
    _light = value;
    markNeedsPaint();
  }

  LiquidLook _look;
  set look(LiquidLook value) {
    if (value == _look) return;
    _look = value;
    markNeedsPaint();
  }

  double _pixelRatio;
  set pixelRatio(double value) {
    if (value == _pixelRatio) return;
    _pixelRatio = value;
    markNeedsPaint();
  }

  /// Painted as a drop always, never bending what is behind it: lighter
  /// work for a phone that can't spare it.
  bool _painted;
  set painted(bool value) {
    if (value == _painted) return;
    _painted = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  ui.FragmentShader? _shader;
  final _clip = LayerHandle<ClipRRectLayer>();
  final _backdrop = LayerHandle<BackdropFilterLayer>();

  bool get _shown => _amount > 0.004;

  bool get _real => _shown && !_painted && LiquidGlassShader.program != null;

  @override
  bool get alwaysNeedsCompositing => _real || super.alwaysNeedsCompositing;

  RRect? _shapeOf(Size size) {
    final lens = _lens;
    if (lens != null) return lens(size);
    final rect = Offset.zero & size;
    return _radius?.toRRect(rect) ??
        RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final shape = _shown ? _shapeOf(size) : null;
    if (shape == null || shape.isEmpty) {
      _clip.layer = null;
      return;
    }
    final amount = _amount.clamp(0.0, 1.0);
    if (_style.shadow) {
      _paintShadow(context.canvas, shape.shift(offset), amount);
    }

    final program = LiquidGlassShader.program;
    if (program == null || _painted || !needsCompositing) {
      _clip.layer = null;
      paintLiquidDrop(
        context.canvas,
        shape.shift(offset),
        _look,
        opacity: amount,
      );
      return;
    }
    final shader = _shader ??= program.fragmentShader();
    _setUniforms(shader, shape, amount);
    var filter = ui.ImageFilter.shader(shader);
    final blur = _style.blur * _pixelRatio * amount;
    if (blur > 0.01) {
      filter = ui.ImageFilter.compose(
        outer: filter,
        inner: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      );
    }
    final backdrop = _backdrop.layer ??= BackdropFilterLayer();
    backdrop.filter = filter;
    _clip.layer = context.pushClipRRect(
      true,
      offset,
      shape.outerRect,
      shape,
      (context, offset) => context.pushLayer(backdrop, (_, _) {}, offset),
      oldLayer: _clip.layer,
    );
  }

  /// A soft shadow round the drop, never under it, where the glass would
  /// show it.
  void _paintShadow(Canvas canvas, RRect shape, double amount) {
    final room = shape.outerRect.inflate(_style.rim * 2);
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(room)
          ..addRRect(shape),
      )
      ..drawRRect(
        shape.shift(const Offset(0, 2)),
        Paint()
          ..color = _look.shade.withValues(
            alpha: (_look.dark ? 0.4 : 0.14) * amount,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      )
      ..restore();
  }

  void _setUniforms(ui.FragmentShader shader, RRect shape, double amount) {
    // The shader works in the view's physical pixels.
    final toView = getTransformTo(null);
    final rect = MatrixUtils.transformRect(toView, shape.outerRect);
    final scale = shape.outerRect.width <= 0
        ? 1.0
        : rect.width / shape.outerRect.width;
    final px = _pixelRatio * scale;
    final s = _style;
    final radius = shape.tlRadiusX;
    final values = <double>[
      // uRect
      rect.left * _pixelRatio,
      rect.top * _pixelRatio,
      rect.right * _pixelRatio,
      rect.bottom * _pixelRatio,
      // uShape
      radius * px,
      s.rim * px,
      s.bend,
      s.split * amount,
      // uLight
      1 + (s.magnify - 1) * amount,
      s.rimLight,
      s.ambient,
      amount,
      // uTint
      0,
      0,
      0,
      0,
      // uLook
      1 + (s.saturation - 1) * amount,
      s.brighten * (_look.dark ? 0.6 : 1),
      s.shade * (_look.dark ? 0.5 : 1),
      px,
      // uLightDir
      _light.dx,
      _light.dy,
    ];
    // The backdrop's size comes first, set by the engine.
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i + 2, values[i]);
    }
  }

  @override
  void dispose() {
    _clip.layer = null;
    _backdrop.layer = null;
    _shader?.dispose();
    super.dispose();
  }
}
