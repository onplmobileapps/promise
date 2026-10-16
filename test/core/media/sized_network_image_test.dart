import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/media/sized_network_image.dart';

void main() {
  test("a photo is decoded at the width asked, its shape kept", () {
    final image = sizedNetworkImage('https://hrms.test/a.jpg', width: 600);
    expect(image, isA<ResizeImage>());
    final resized = image as ResizeImage;
    expect(resized.width, 600);
    expect(resized.height, isNull);
    expect(resized.allowUpscaling, isFalse);
    expect(
      (resized.imageProvider as NetworkImage).url,
      'https://hrms.test/a.jpg',
    );
  });

  testWidgets('the width in pixels is the screen\'s, never past the cap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    expect(physicalWidth(context, 200), 525);
    expect(physicalWidth(context, double.infinity), 1080);
    expect(physicalWidth(context, 100000), 4096);
  });
}
