import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/media/sized_network_image.dart';

/// Pictures the work area map draws with: the office pin, the employee's
/// avatar and the arrows along the way. Each is drawn at [dpr] so it is
/// sharp on the phone's screen, in the colours of a [MarkerPalette].

/// The colours the map's markers are drawn in.
@immutable
class MarkerPalette {
  const MarkerPalette({
    required this.pinTop,
    required this.pinBottom,
    required this.pinEdge,
    required this.ringStart,
    required this.ringEnd,
    required this.face,
    required this.ink,
    required this.shade,
    required this.arrow,
  });

  /// The design's colours: a jade pin, and the employee in a jade-to-gold
  /// ring like their avatar elsewhere.
  factory MarkerPalette.of(AppColors colors) => MarkerPalette(
    pinTop: colors.iconFillActive,
    pinBottom: colors.success,
    pinEdge: colors.primaryEdge,
    ringStart: colors.primary,
    ringEnd: colors.ornamentAccent,
    face: colors.surface,
    ink: colors.textPrimary,
    shade: colors.shadow,
    arrow: colors.surface,
  );

  final Color pinTop;
  final Color pinBottom;
  final Color pinEdge;
  final Color ringStart;
  final Color ringEnd;
  final Color face;
  final Color ink;
  final Color shade;
  final Color arrow;
}

/// A jade map pin with the office glyph; its tip is the bottom centre.
Future<Uint8List> officePinPng(double dpr, MarkerPalette palette) async {
  const w = 40.0, h = 50.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  final pin = Path()
    ..moveTo(w / 2, h - 2)
    ..cubicTo(w / 2 - 4, h - 12, 3, h * 0.52, 3, h * 0.38)
    ..arcToPoint(Offset(w - 3, h * 0.38), radius: const Radius.circular(17))
    ..cubicTo(w - 3, h * 0.52, w / 2 + 4, h - 12, w / 2, h - 2)
    ..close();
  canvas
    ..drawPath(
      pin.shift(const Offset(0, 3)),
      Paint()
        ..color = palette.shade.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    )
    // The pin's edge, below it, as on the design's keys.
    ..drawPath(pin.shift(const Offset(0, 2)), Paint()..color = palette.pinEdge)
    ..drawPath(
      pin,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(w, h), [
          palette.pinTop,
          palette.pinBottom,
        ]),
    );
  await _glyph(
    canvas,
    AppGlyphs.building,
    palette.ink,
    20,
    Offset(w / 2, h * 0.38),
  );
  return _png(recorder, w, h, dpr);
}

/// The employee as a round avatar: their [photo], or their [initials] on
/// the face, in a jade-to-gold ring. Its centre is where they stand.
Future<Uint8List> userAvatarPng(
  double dpr,
  MarkerPalette palette, {
  required String initials,
  ui.Image? photo,
}) async {
  const size = 60.0;
  const c = Offset(size / 2, size / 2);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  canvas
    ..drawCircle(
      c.translate(0, 3),
      22,
      Paint()
        ..color = palette.shade.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    )
    ..drawCircle(
      c,
      22,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(-22, -22),
          c.translate(22, 22),
          [palette.ringStart, palette.ringEnd],
        ),
    )
    ..drawCircle(c, 19, Paint()..color = palette.face);
  final face = Rect.fromCircle(center: c, radius: 19);
  if (photo != null) {
    canvas
      ..save()
      ..clipPath(Path()..addOval(face));
    paintImage(
      canvas: canvas,
      rect: face,
      image: photo,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
    canvas.restore();
  } else if (initials.isEmpty) {
    await _glyph(canvas, AppGlyphs.user, palette.ink, 20, c);
  } else {
    final text = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          fontFamily: AppFonts.text,
          color: palette.ink,
          fontSize: 13,
          fontWeight: AppFonts.semiBold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
  }
  return _png(recorder, size, size, dpr);
}

/// A chevron pointing along the line it is placed on.
Future<Uint8List> routeArrowPng(double dpr, MarkerPalette palette) async {
  const size = 16.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(dpr);
  canvas.drawPath(
    Path()
      ..moveTo(5.5, 3.5)
      ..lineTo(11, 8)
      ..lineTo(5.5, 12.5),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = palette.arrow,
  );
  return _png(recorder, size, size, dpr);
}

/// Draws [glyph] [size] across, centred on [center], in [color].
Future<void> _glyph(
  Canvas canvas,
  AppGlyph glyph,
  Color color,
  double size,
  Offset center,
) async {
  paintGlyph(
    canvas,
    glyph,
    offset: center - Offset(size / 2, size / 2),
    size: size,
    stroke: color,
    tint: color.withValues(alpha: 0),
    cut: color.withValues(alpha: 0),
  );
}

/// "PP" for "Pervaiz Pervaiz"; empty without a name.
String initialsOf(String? name) {
  final words = (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && w.toLowerCase() != 'null')
      .toList();
  if (words.isEmpty) return '';
  final first = words.first.characters.first;
  final last = words.length > 1 ? words.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// [path] as a full address: as is when it has one, otherwise against
/// [base]. Null when there is no picture, the server's stand-in for one
/// included: it isn't there to download, and the initials say more.
String? photoUrl(String? path, {String? base}) {
  final p = path?.trim() ?? '';
  if (p.isEmpty || p.toLowerCase() == 'null') return null;
  final uri = Uri.tryParse(p);
  if (uri == null || _isStandIn(uri)) return null;
  if (uri.hasScheme) return uri.toString();
  final root = base == null ? null : Uri.tryParse(base);
  if (root == null || !root.hasScheme) return null;
  return root.resolveUri(uri).toString();
}

/// Whether [uri] is the picture the server names for an employee without
/// one of their own.
bool _isStandIn(Uri uri) {
  final segments = uri.pathSegments;
  return segments.isNotEmpty &&
      segments.last.toLowerCase().startsWith('default_profile_image');
}

/// Downloads the picture at [url], decoded no wider than [width] pixels,
/// as much as an avatar needs; null if it can't be had in time or at all.
///
/// It listens until the download ends, even after giving up waiting, so a
/// picture that fails late is still its own to handle and never reported
/// as the app's error.
Future<ui.Image?> loadPhoto(
  String url, {
  Duration timeout = const Duration(seconds: 8),
  int width = 256,
}) {
  final done = Completer<ui.Image?>();
  final stream = sizedNetworkImage(
    url,
    width: width,
  ).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  final timer = Timer(timeout, () {
    if (!done.isCompleted) done.complete(null);
  });
  void end(ui.Image? image) {
    timer.cancel();
    stream.removeListener(listener);
    if (done.isCompleted) {
      image?.dispose();
    } else {
      done.complete(image);
    }
  }

  listener = ImageStreamListener(
    (info, _) {
      final image = info.image.clone();
      info.dispose();
      end(image);
    },
    onError: (_, _) => end(null),
  );
  stream.addListener(listener);
  return done.future;
}

Future<Uint8List> _png(
  ui.PictureRecorder recorder,
  double w,
  double h,
  double dpr,
) async {
  final image = await recorder.endRecording().toImage(
    (w * dpr).ceil(),
    (h * dpr).ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
