import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/media/camera/card_frame.dart';

void main() {
  test("a card's frame is a card's shape, a little above the middle", () {
    final frame = cardFrameIn(const Size(350, 280));
    expect(frame.width / frame.height, closeTo(idCardAspectRatio, 0.001));
    expect(frame.center.dx, 175);
    expect(frame.center.dy, lessThan(140));
  });

  test('a part of the window maps onto the picture its preview covered', () {
    // A 9:16 picture covering a 350 × 280 window is cropped top and bottom.
    const view = Size(350, 280);
    const image = Size(720, 1280);
    expect(
      viewToImage(Offset.zero & view, view: view, image: image),
      rectMoreOrLessEquals(
        Rect.fromLTWH(0, (1280 - 280 * 720 / 350) / 2, 720, 280 * 720 / 350),
      ),
    );
    // Its middle stays its middle.
    expect(
      viewToImage(
        Rect.fromCenter(center: const Offset(175, 140), width: 2, height: 2),
        view: view,
        image: image,
      ).center,
      offsetMoreOrLessEquals(const Offset(360, 640)),
    );
  });
}
