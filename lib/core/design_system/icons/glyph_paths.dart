import 'dart:ui';

import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';

/// One part of a glyph as a path on its 24-unit grid, with how it is
/// filled.
class GlyphShape {
  const GlyphShape(this.path, this.fill);

  final Path path;
  final GlyphFill fill;
}

final Map<AppGlyph, List<GlyphShape>> _shapes = {};

/// [glyph]'s parts as paths, read from their SVG once and kept.
List<GlyphShape> glyphShapes(AppGlyph glyph) => _shapes[glyph] ??= [
  for (final part in glyph.parts)
    GlyphShape(_elementPath(part.element), part.fill),
];

/// Paints [glyph] in a [size] square at [offset]: each part filled as it
/// asks, then its lines in [stroke]. Tinted parts take [tint], cut-out
/// parts [cut], and solid parts [stroke], as in the SVG it is drawn from.
/// With [depth] it is drawn in 3D: lit from above, glossed along its top
/// and standing off the page on a soft shadow.
void paintGlyph(
  Canvas canvas,
  AppGlyph glyph, {
  required Offset offset,
  required double size,
  required Color stroke,
  required Color tint,
  required Color cut,
  bool depth = false,
}) {
  final scale = size / 24;
  canvas
    ..save()
    ..translate(offset.dx, offset.dy)
    ..scale(scale);
  final shapes = glyphShapes(glyph);
  if (depth) _paintShadow(canvas, glyph, shapes, stroke);
  final lines = glyph.strokeWidth > 0
      ? (Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = glyph.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = stroke)
      : null;
  // In depth, lit from above: lines and fills lighter at the top, deeper
  // at the foot.
  if (depth && lines != null) {
    lines.shader = Gradient.linear(const Offset(0, 2), const Offset(0, 22), [
      Color.lerp(stroke, const Color(0xFFFFFFFF), 0.18)!,
      Color.lerp(stroke, const Color(0xFF000000), 0.22)!,
    ]);
  }
  for (final shape in shapes) {
    final fill = switch (shape.fill) {
      GlyphFill.none => null,
      GlyphFill.tint => tint,
      GlyphFill.cut => cut,
      GlyphFill.ink => stroke,
    };
    if (fill != null && fill.a > 0) {
      final paint = Paint()..color = fill;
      if (depth && shape.fill != GlyphFill.cut) {
        final box = shape.path.getBounds();
        paint.shader = Gradient.linear(
          box.topCenter,
          box.bottomCenter,
          [
            Color.lerp(fill, const Color(0xFFFFFFFF), 0.45)!,
            fill,
            Color.lerp(fill, const Color(0xFF000000), 0.12)!,
          ],
          const [0, 0.55, 1],
        );
      }
      canvas.drawPath(shape.path, paint);
      if (depth && shape.fill == GlyphFill.tint) {
        _paintGloss(canvas, shape.path);
      }
    }
    if (lines != null) canvas.drawPath(shape.path, lines);
  }
  canvas.restore();
}

/// A soft shadow under a glyph in depth, as if it stood off the page.
void _paintShadow(
  Canvas canvas,
  AppGlyph glyph,
  List<GlyphShape> shapes,
  Color stroke,
) {
  final shade = Paint()
    ..color = stroke.withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);
  final outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = glyph.strokeWidth > 0 ? glyph.strokeWidth : 1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = shade.color
    ..maskFilter = shade.maskFilter;
  canvas
    ..save()
    ..translate(0, 1.4);
  for (final shape in shapes) {
    if (shape.fill != GlyphFill.none) canvas.drawPath(shape.path, shade);
    if (glyph.strokeWidth > 0) canvas.drawPath(shape.path, outline);
  }
  canvas.restore();
}

/// A gloss across the top of a tinted part, where the light falls.
void _paintGloss(Canvas canvas, Path path) {
  final box = path.getBounds();
  canvas
    ..save()
    ..clipPath(path)
    ..drawRect(
      Rect.fromLTRB(box.left, box.top, box.right, box.top + box.height * 0.5),
      Paint()
        ..shader = Gradient.linear(
          box.topCenter,
          Offset(box.center.dx, box.top + box.height * 0.5),
          [const Color(0x8CFFFFFF), const Color(0x00FFFFFF)],
        ),
    )
    ..restore();
}

/// The path of one SVG element: a path, circle, line, rect, polyline or
/// polygon.
Path _elementPath(String element) {
  final tag = RegExp(r'<(\w+)').firstMatch(element)?.group(1);
  final attributes = {
    for (final m in RegExp(r'([\w-]+)="([^"]*)"').allMatches(element))
      m.group(1)!: m.group(2)!,
  };
  double number(String name) => double.tryParse(attributes[name] ?? '') ?? 0;
  switch (tag) {
    case 'path':
      return parseSvgPath(attributes['d'] ?? '');
    case 'circle':
      return Path()..addOval(
        Rect.fromCircle(
          center: Offset(number('cx'), number('cy')),
          radius: number('r'),
        ),
      );
    case 'line':
      return Path()
        ..moveTo(number('x1'), number('y1'))
        ..lineTo(number('x2'), number('y2'));
    case 'rect':
      final rect = Rect.fromLTWH(
        number('x'),
        number('y'),
        number('width'),
        number('height'),
      );
      final rx = attributes.containsKey('rx') ? number('rx') : number('ry');
      final ry = attributes.containsKey('ry') ? number('ry') : rx;
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.elliptical(rx, ry)));
    case 'polyline' || 'polygon':
      final values = _Reader(attributes['points'] ?? '');
      final path = Path();
      var first = true;
      while (values.hasNumber) {
        final x = values.number();
        final y = values.number();
        first ? path.moveTo(x, y) : path.lineTo(x, y);
        first = false;
      }
      if (tag == 'polygon') path.close();
      return path;
    default:
      return Path();
  }
}

/// The path an SVG path's data [d] draws: every command, absolute and
/// relative, arcs included.
Path parseSvgPath(String d) {
  final path = Path();
  final read = _Reader(d);
  var current = Offset.zero;
  var start = Offset.zero;
  // The last curve's second control point, for a smooth curve after it.
  Offset? lastCubic;
  Offset? lastQuad;
  String? command;
  while (true) {
    read.skipSeparators();
    if (read.done) break;
    if (read.atCommand) {
      command = read.command();
    } else if (command == null) {
      break;
    }
    final relative = command == command.toLowerCase();
    final base = relative ? current : Offset.zero;
    Offset point() => base + Offset(read.number(), read.number());
    var cubic = false;
    var quad = false;
    switch (command.toUpperCase()) {
      case 'M':
        current = point();
        start = current;
        path.moveTo(current.dx, current.dy);
        // Further pairs after a move are lines.
        command = relative ? 'l' : 'L';
      case 'L':
        current = point();
        path.lineTo(current.dx, current.dy);
      case 'H':
        current = Offset(
          read.number() + (relative ? current.dx : 0),
          current.dy,
        );
        path.lineTo(current.dx, current.dy);
      case 'V':
        current = Offset(
          current.dx,
          read.number() + (relative ? current.dy : 0),
        );
        path.lineTo(current.dx, current.dy);
      case 'C':
        final c1 = point();
        final c2 = point();
        final end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubic = c2;
        current = end;
        cubic = true;
      case 'S':
        final c1 = lastCubic == null ? current : current * 2 - lastCubic;
        final c2 = point();
        final end = point();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastCubic = c2;
        current = end;
        cubic = true;
      case 'Q':
        final c = point();
        final end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuad = c;
        current = end;
        quad = true;
      case 'T':
        final c = lastQuad == null ? current : current * 2 - lastQuad;
        final end = point();
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastQuad = c;
        current = end;
        quad = true;
      case 'A':
        final rx = read.number().abs();
        final ry = read.number().abs();
        final rotation = read.number();
        final largeArc = read.flag();
        final sweep = read.flag();
        final end = point();
        if (rx == 0 || ry == 0) {
          path.lineTo(end.dx, end.dy);
        } else {
          path.arcToPoint(
            end,
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
        }
        current = end;
      case 'Z':
        path.close();
        current = start;
      default:
        // Unknown: stop rather than misdraw.
        return path;
    }
    if (!cubic) lastCubic = null;
    if (!quad) lastQuad = null;
  }
  return path;
}

/// Reads numbers, flags and commands from SVG path data or points.
class _Reader {
  _Reader(this.text);

  final String text;
  int _at = 0;

  bool get done => _at >= text.length;

  bool get atCommand {
    final c = text.codeUnitAt(_at);
    // Letters, but not the "e" of an exponent, which only follows a digit.
    return (c >= 65 && c <= 90 || c >= 97 && c <= 122) && c != 101 && c != 69;
  }

  bool get hasNumber {
    skipSeparators();
    return !done && !atCommand;
  }

  void skipSeparators() {
    while (!done) {
      final c = text[_at];
      if (c == ' ' || c == ',' || c == '\n' || c == '\t' || c == '\r') {
        _at++;
      } else {
        break;
      }
    }
  }

  String command() => text[_at++];

  /// An arc's flag: a single 0 or 1, which may run into what follows.
  bool flag() {
    skipSeparators();
    if (done) return false;
    return text[_at++] == '1';
  }

  double number() {
    skipSeparators();
    final from = _at;
    if (!done && (text[_at] == '-' || text[_at] == '+')) _at++;
    var dot = false;
    var exponent = false;
    while (!done) {
      final c = text[_at];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        _at++;
      } else if (c == '.' && !dot && !exponent) {
        dot = true;
        _at++;
      } else if ((c == 'e' || c == 'E') && !exponent) {
        exponent = true;
        _at++;
        if (!done && (text[_at] == '-' || text[_at] == '+')) _at++;
      } else {
        break;
      }
    }
    if (_at == from) {
      // Nothing readable: step past it so reading always moves on.
      _at++;
      return 0;
    }
    return double.tryParse(text.substring(from, _at)) ?? 0;
  }
}
