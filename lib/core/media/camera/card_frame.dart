import 'dart:math' as math;
import 'dart:ui';

/// The ID-1 card size of a CNIC, a NICOP and bank cards: 85.6 × 53.98 mm.
const idCardAspectRatio = 85.6 / 53.98;

/// The frame's width, as a share of the camera window's.
const _frameShare = 0.86;

/// The frame never takes more of the window's height than this.
const _frameMaxHeightShare = 0.7;

/// The frame's centre, a little above the middle.
const _frameCentre = 0.46;

/// Where a card's frame sits in a camera window of [size]: as wide as the
/// window allows, a little above its middle, and [aspectRatio] wide to
/// high.
Rect cardFrameIn(Size size, {double aspectRatio = idCardAspectRatio}) {
  var width = size.width * _frameShare;
  var height = width / aspectRatio;
  final tallest = size.height * _frameMaxHeightShare;
  if (height > tallest) {
    height = tallest;
    width = height * aspectRatio;
  }
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * _frameCentre),
    width: width,
    height: height,
  );
}

/// Where [rect], a part of a camera window of [view] size, falls in an
/// [image] the window's preview covered: scaled by the larger of the two
/// ratios and centred, as the preview is. A frame of the stream and a
/// photo line up with what was seen this way.
Rect viewToImage(Rect rect, {required Size view, required Size image}) {
  final scale = math.max(view.width / image.width, view.height / image.height);
  final dx = (view.width - image.width * scale) / 2;
  final dy = (view.height - image.height * scale) / 2;
  return Rect.fromLTRB(
    (rect.left - dx) / scale,
    (rect.top - dy) / scale,
    (rect.right - dx) / scale,
    (rect.bottom - dy) / scale,
  );
}
