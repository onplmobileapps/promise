import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/media/cnic/cnic_check.dart';

/// The card's frame in a frame of the camera.
const window = Rect.fromLTWH(100, 400, 900, 568);

/// The holder's photo on a card filling [window]: an eighth of it across.
const portrait = Rect.fromLTWH(160, 520, 117, 140);

OcrLine run(String text, double left, double top) =>
    OcrLine(text, Rect.fromLTWH(left, top, text.length * 14.0, 24));

CnicSighting glance({
  List<OcrLine> lines = const [],
  List<Rect> faces = const [],
  double green = 0,
}) =>
    CnicCheck.glance(lines: lines, faces: faces, green: green, window: window);

void main() {
  group("a CNIC's green", () {
    test('is the pale green of the cards, old and new', () {
      // Sampled from photos of an old Urdu CNIC, a NICOP and a worn,
      // laminated CNIC.
      expect(CnicCheck.isCardGreen(205, 232, 200), isTrue);
      expect(CnicCheck.isCardGreen(216, 240, 208), isTrue);
      expect(CnicCheck.isCardGreen(201, 217, 184), isTrue);
      expect(CnicCheck.isCardGreen(150, 200, 170), isTrue);
      // Washed pale in bright light.
      expect(CnicCheck.isCardGreen(232, 242, 230), isTrue);
    });

    test('is not grey, white, dark, blue, red or yellow', () {
      expect(CnicCheck.isCardGreen(120, 120, 120), isFalse);
      expect(CnicCheck.isCardGreen(250, 250, 248), isFalse);
      expect(CnicCheck.isCardGreen(20, 45, 20), isFalse);
      expect(CnicCheck.isCardGreen(40, 80, 200), isFalse);
      expect(CnicCheck.isCardGreen(200, 40, 40), isFalse);
      expect(CnicCheck.isCardGreen(230, 210, 60), isFalse);
    });
  });

  group('the holder\'s photo', () {
    test('is a face the size of a card\'s photo inside the frame', () {
      expect(
        CnicCheck.portraitShare([portrait], window),
        closeTo(117 / 900, 0.001),
      );
    });

    test('is not a person in front of the camera, nor a speck of print', () {
      expect(
        CnicCheck.portraitShare([
          const Rect.fromLTWH(200, 420, 500, 520),
          const Rect.fromLTWH(600, 700, 10, 12),
        ], window),
        isNull,
      );
    });

    test('is not a face outside the frame', () {
      expect(
        CnicCheck.portraitShare([const Rect.fromLTWH(0, 0, 100, 120)], window),
        isNull,
      );
    });
  });

  group('the live camera sees', () {
    test('a CNIC: its green and its holder\'s photo', () {
      expect(glance(faces: [portrait], green: 0.5), CnicSighting.cnic);
    });

    test('an Urdu CNIC, its English unread', () {
      expect(
        glance(
          lines: [run('36301-1752220-5', 400, 600)],
          faces: [portrait],
          green: 0.4,
        ),
        CnicSighting.cnic,
      );
    });

    test('a CNIC too far away', () {
      expect(
        glance(faces: [const Rect.fromLTWH(500, 600, 40, 48)], green: 0.1),
        CnicSighting.far,
      );
    });

    test('a card with a photo that is not a CNIC\'s green', () {
      expect(glance(faces: [portrait], green: 0.05), CnicSighting.notCnic);
    });

    test('a bank card, by its words or its number', () {
      expect(
        glance(lines: [run('VISA', 800, 900)], green: 0.5),
        CnicSighting.bankCard,
      );
      expect(
        glance(lines: [run('4111 1111 1111 1111', 200, 600)]),
        CnicSighting.bankCard,
      );
    });

    test('a green card with a photo that says it is a licence', () {
      expect(
        glance(
          lines: [run('DRIVING LICENCE', 200, 450)],
          faces: [portrait],
          green: 0.5,
        ),
        CnicSighting.otherCard,
      );
    });

    test('an office card that names its CNIC number', () {
      expect(
        glance(
          lines: [run('CNIC: 35202-1234567-1', 200, 600)],
          faces: [portrait],
          green: 0.5,
        ),
        CnicSighting.otherCard,
      );
    });

    test('a CNIC whose name is not taken for a short word of other cards', () {
      // "Army" is a word of other cards; a card that says it is a national
      // identity card isn't one.
      expect(
        glance(
          lines: [
            run('National Identity Card', 500, 420),
            run('ARMY', 200, 600),
          ],
          faces: [portrait],
          green: 0.5,
        ),
        CnicSighting.cnic,
      );
    });

    test('a green card with no photo yet, or text', () {
      expect(glance(green: 0.5), CnicSighting.card);
      expect(glance(lines: [run('Chapter 3', 200, 600)]), CnicSighting.card);
    });

    test('nothing', () {
      expect(glance(), CnicSighting.nothing);
      expect(glance(lines: [run('Bank', 10, 10)]), CnicSighting.nothing);
    });
  });

  group('a photo of a card', () {
    const size = Size(930, 586);
    const face = Rect.fromLTWH(60, 140, 120, 150);

    test('is taken when it shows a CNIC', () {
      expect(
        CnicCheck.photo(lines: const [], faces: [face], green: 0.5, size: size),
        isNull,
      );
    });

    test('is turned away when blurred past telling', () {
      expect(
        CnicCheck.photo(
          lines: const [],
          faces: const [],
          green: 0.5,
          size: size,
        ),
        CnicProblem.nothing,
      );
    });

    test('is turned away for a look-alike card', () {
      expect(
        CnicCheck.photo(
          lines: [run('MASTERCARD', 600, 450)],
          faces: [face],
          green: 0.5,
          size: size,
        ),
        CnicProblem.bankCard,
      );
      expect(
        CnicCheck.photo(
          lines: const [],
          faces: [face],
          green: 0.02,
          size: size,
        ),
        CnicProblem.notCnic,
      );
    });
  });
}
