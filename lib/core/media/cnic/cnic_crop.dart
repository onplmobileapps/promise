import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';

/// A crop of a CNIC's photo: its [pixels], RGBA, [width] by [height], to be
/// read at once; and a JPEG of it, written apart from the UI when first
/// asked for.
class CnicCut {
  CnicCut._(this.pixels, this.width, this.height, this._name);

  final Uint8List pixels;
  final int width;
  final int height;
  final String _name;

  /// The JPEG, started the first time it is asked for.
  late final Future<XFile> file = _saveJpeg(this, _name);

  /// The pixels as an image, to show at once; the caller disposes it.
  Future<ui.Image> image() {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }
}

/// Crops [shot] to [frame], the card's frame in a camera window of
/// [viewport] size that the preview covered: what the user saw of the
/// camera, only the card. Null when the photo can't be read.
///
/// The phone's own decoder does the heavy work, off the UI.
Future<CnicCut?> cropCnic(XFile shot, Rect frame, Size viewport) async {
  if (viewport.isEmpty) return null;
  final ui.Image photo;
  try {
    final codec = await ui.instantiateImageCodec(await shot.readAsBytes());
    photo = (await codec.getNextFrame()).image;
    codec.dispose();
  } catch (error) {
    debugPrint('The CNIC photo could not be read: $error');
    return null;
  }
  try {
    final size = Size(photo.width.toDouble(), photo.height.toDouble());
    final framed = viewToImage(
      frame,
      view: viewport,
      image: size,
    ).intersect(Offset.zero & size);
    if (framed.width < 32 || framed.height < 20) return null;
    return await _cut(
      photo,
      framed,
      'card_${DateTime.now().microsecondsSinceEpoch}',
    );
  } catch (error) {
    debugPrint('The CNIC photo could not be cropped: $error');
    return null;
  } finally {
    photo.dispose();
  }
}

const _jpegQuality = 90;

/// [rect] of [photo], as pixels.
Future<CnicCut> _cut(ui.Image photo, Rect rect, String name) async {
  final image = await _draw(photo, rect, rect.width.round());
  try {
    final rgba = await image.toByteData();
    return CnicCut._(
      rgba!.buffer.asUint8List(),
      image.width,
      image.height,
      name,
    );
  } finally {
    image.dispose();
  }
}

/// [cut] written as a JPEG named [name], encoded apart from the UI.
Future<XFile> _saveJpeg(CnicCut cut, String name) async {
  final jpeg = await compute(_encodeJpeg, (
    rgba: cut.pixels,
    width: cut.width,
    height: cut.height,
  ));
  final folder = await getTemporaryDirectory();
  final file = File('${folder.path}/cnic_$name.jpg');
  await file.writeAsBytes(jpeg, flush: true);
  return XFile(file.path, mimeType: 'image/jpeg');
}

Uint8List _encodeJpeg(({Uint8List rgba, int width, int height}) job) =>
    img.encodeJpg(
      img.Image.fromBytes(
        width: job.width,
        height: job.height,
        bytes: job.rgba.buffer,
        bytesOffset: job.rgba.offsetInBytes,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      ),
      quality: _jpegQuality,
    );

/// [rect] of [photo], drawn [width] pixels wide.
Future<ui.Image> _draw(ui.Image photo, Rect rect, int width) async {
  final height = math.max(1, (rect.height * width / rect.width).round());
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    photo,
    rect,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..filterQuality = FilterQuality.medium,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}
