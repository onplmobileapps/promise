import 'package:flutter/widgets.dart';

/// The picture at [url], decoded no wider than [width] physical pixels,
/// its shape kept: only as much of it as the screen can show, not all a
/// camera took, so a large photo doesn't take tens of megabytes of memory.
ImageProvider sizedNetworkImage(String url, {required int width}) =>
    ResizeImage(NetworkImage(url), width: width, allowUpscaling: false);

/// The physical pixels across [logicalWidth] on this screen, for
/// [sizedNetworkImage] and `cacheWidth`. An unbounded width takes the
/// screen's.
int physicalWidth(BuildContext context, double logicalWidth) {
  final width = logicalWidth.isFinite
      ? logicalWidth
      : MediaQuery.sizeOf(context).width;
  return (width * MediaQuery.devicePixelRatioOf(context)).round().clamp(
    1,
    _widest,
  );
}

/// No picture is decoded wider than this, whatever the screen.
const _widest = 4096;
