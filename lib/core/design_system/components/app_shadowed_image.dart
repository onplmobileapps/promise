import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// An image with a soft [shadow] that follows its own outline, the way CSS
/// `drop-shadow` draws it: for the 3D icons. It is decoded at the size it
/// is shown.
class AppShadowedImage extends StatefulWidget {
  const AppShadowedImage({
    super.key,
    required this.asset,
    required this.size,
    required this.shadow,
    this.semanticLabel,
  });

  final String asset;

  /// The square it is fitted into.
  final double size;
  final BoxShadow shadow;
  final String? semanticLabel;

  @override
  State<AppShadowedImage> createState() => _AppShadowedImageState();
}

class _AppShadowedImageState extends State<AppShadowedImage> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(_onImage);
  ImageInfo? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AppShadowedImage old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset || old.size != widget.size) _resolve();
  }

  void _resolve() {
    final pixels = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round();
    final stream = ResizeImage(
      AssetImage(widget.asset),
      width: pixels,
      height: pixels,
      policy: ResizeImagePolicy.fit,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  void _onImage(ImageInfo image, bool synchronousCall) {
    if (!mounted) return;
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: widget.semanticLabel != null,
      label: widget.semanticLabel,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _ShadowedImagePainter(_image?.image, widget.shadow),
      ),
    );
  }
}

class _ShadowedImagePainter extends CustomPainter {
  const _ShadowedImagePainter(this.image, this.shadow);

  final ui.Image? image;
  final BoxShadow shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;
    final source =
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, source.size, size);
    final target = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    // The shadow: the image's outline in the shadow's colour, blurred and
    // moved by its offset.
    canvas
      ..drawImageRect(
        image,
        source,
        target.shift(shadow.offset),
        Paint()
          ..colorFilter = ColorFilter.mode(shadow.color, BlendMode.srcIn)
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: shadow.blurSigma,
            sigmaY: shadow.blurSigma,
          ),
      )
      ..drawImageRect(
        image,
        source,
        target,
        Paint()..filterQuality = FilterQuality.medium,
      );
  }

  @override
  bool shouldRepaint(_ShadowedImagePainter old) =>
      old.image != image || old.shadow != shadow;
}
