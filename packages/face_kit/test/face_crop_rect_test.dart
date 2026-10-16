import 'dart:ui';

import 'package:face_kit/src/engine/face_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildFaceCropRectForFrame', () {
    test(
      'keeps the crop centered on the face and avoids the lower neck area',
      () {
        final faceBox = Rect.fromLTWH(240, 340, 220, 240);
        final crop = buildFaceCropRectForFrame(faceBox, const Size(1080, 1920));

        expect(crop.center.dx, closeTo(faceBox.center.dx, 1));
        expect(crop.center.dy < faceBox.center.dy, isTrue);
        expect(crop.height <= faceBox.height * 1.2, isTrue);
        expect(crop.width <= faceBox.width * 1.35, isTrue);
        expect(crop.top >= 0, isTrue);
        expect(crop.left >= 0, isTrue);
        expect(crop.bottom <= 1920, isTrue);
        expect(crop.right <= 1080, isTrue);
      },
    );
  });
}
