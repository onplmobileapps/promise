import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';

/// A run of words the text recognition read on one line, and where it sits
/// in the image, in pixels. Words far apart on a line, like two columns of
/// a card, are separate runs.
@immutable
class OcrLine {
  const OcrLine(this.text, this.box);

  final String text;
  final Rect box;

  @override
  String toString() => 'OcrLine($text, $box)';
}

/// Why what was held up isn't taken for a CNIC.
enum CnicProblem {
  /// No card in the frame, or one too blurred to tell.
  nothing,

  /// A bank, debit or credit card.
  bankCard,

  /// Another card or document, such as a licence, passport or office card.
  otherCard,

  /// A card with a photo on it that isn't a CNIC's green.
  notCnic,
}

/// What a frame of the live camera shows.
enum CnicSighting {
  /// Nothing inside the frame.
  nothing,

  /// Something card-like, but no photo on it yet.
  card,

  /// A card with its holder's photo, too far away to take well.
  far,

  /// A card with a photo on it that isn't a CNIC's green.
  notCnic,

  /// A bank, debit or credit card.
  bankCard,

  /// Another card or document.
  otherCard,

  /// A CNIC or NICOP, near enough to take.
  cnic,
}

/// Tells a Pakistani CNIC or NICOP, old or new, English or Urdu, from
/// everything else held up to the camera, by how it looks: a card of the
/// CNIC's pale green with its holder's passport photo on it. The text on
/// it is never shown; it is only read to turn away cards that look alike,
/// such as bank cards, licences and office cards.
///
/// It is pure: the photos, colours and text come from the camera's AI
/// (see `cnic_vision.dart`), so the rules can be checked without a camera.
abstract final class CnicCheck {
  /// What a frame shows inside [window], the card's frame in it: the faces
  /// found in the frame, the share of the window that is a CNIC's [green],
  /// and the text read in the frame.
  static CnicSighting glance({
    required List<OcrLine> lines,
    required List<Rect> faces,
    required double green,
    required Rect window,
  }) {
    final text = _Evidence(_inside(lines, window));
    if (text.bankCard) return CnicSighting.bankCard;
    if (text.otherCard) return CnicSighting.otherCard;
    final portrait = portraitShare(faces, window);
    if (portrait == null) {
      return green >= greenCard || text.readable
          ? CnicSighting.card
          : CnicSighting.nothing;
    }
    if (portrait < farPortrait) return CnicSighting.far;
    if (green < greenCard) return CnicSighting.notCnic;
    return CnicSighting.cnic;
  }

  /// What is wrong with a photo of a card, cropped to it, [size] big; null
  /// when it is a CNIC or NICOP.
  static CnicProblem? photo({
    required List<OcrLine> lines,
    required List<Rect> faces,
    required double green,
    required Size size,
  }) => switch (glance(
    lines: lines,
    faces: faces,
    green: green,
    window: Rect.fromLTWH(0, 0, size.width, size.height),
  )) {
    CnicSighting.cnic || CnicSighting.far => null,
    CnicSighting.bankCard => CnicProblem.bankCard,
    CnicSighting.otherCard => CnicProblem.otherCard,
    CnicSighting.notCnic => CnicProblem.notCnic,
    CnicSighting.nothing || CnicSighting.card => CnicProblem.nothing,
  };

  /// How much of [window]'s width the holder's photo on a card spans: the
  /// largest face inside the window that is the size of a card's photo,
  /// not of a person in front of the camera. Null when there is none.
  static double? portraitShare(List<Rect> faces, Rect window) {
    if (window.width <= 0) return null;
    double? largest;
    for (final face in faces) {
      if (!window.contains(face.center)) continue;
      final share = face.width / window.width;
      if (share < _leastPortrait || share > _mostPortrait) continue;
      if (largest == null || share > largest) largest = share;
    }
    return largest;
  }

  /// Whether a pixel is the pale green a CNIC and a NICOP are printed on:
  /// a green to teal hue, a little coloured, not dark.
  static bool isCardGreen(int red, int green, int blue) {
    final most = math.max(red, math.max(green, blue));
    final least = math.min(red, math.min(green, blue));
    if (most < _leastLight || most == least) return false;
    if ((most - least) / most < _leastColour) return false;
    final span = (most - least).toDouble();
    final double hue;
    if (most == red) {
      hue = 60 * (((green - blue) / span) % 6);
    } else if (most == green) {
      hue = 60 * ((blue - red) / span + 2);
    } else {
      hue = 60 * ((red - green) / span + 4);
    }
    return hue >= _greenFrom && hue <= _greenTo;
  }

  /// A frame whose window is at least this much a CNIC's green holds one.
  /// The card's photo and print take the rest.
  static const greenCard = 0.22;

  /// The holder's photo spans about an eighth of a card that fills the
  /// frame. Much less, and the card is too far away to take well; the
  /// camera zooms to keep it near [nearPortrait].
  static const farPortrait = 0.08;
  static const nearPortrait = 0.13;
  static const tooNearPortrait = 0.22;

  /// Faces smaller than this are print, larger a person's own face.
  static const _leastPortrait = 0.03;
  static const _mostPortrait = 0.32;

  /// The card's green: its hue in degrees, how coloured it is at least, and
  /// how light, from 0 to 255.
  static const _greenFrom = 65.0;
  static const _greenTo = 170.0;
  static const _leastColour = 0.045;
  static const _leastLight = 64;

  /// The runs of [lines] inside [window], with a little room around it.
  static List<OcrLine> _inside(List<OcrLine> lines, Rect window) {
    final room = window.inflate(window.width * 0.08);
    return [
      for (final line in lines)
        if (room.contains(line.box.center)) line,
    ];
  }
}

/// Words only a CNIC or a NICOP carries: a card that says it is a national
/// identity card overrides the short words of other cards.
const _identityCues = ['NATIONALIDENTITYCARD', 'IDENTITYNUMBER'];

/// Words only a bank card carries, and its number: never a CNIC.
const _bankTerms = [
  'MASTERCARD',
  'MASTER CARD',
  'MAESTRO',
  'UNIONPAY',
  'UNION PAY',
  'PAYPAK',
  'AMERICAN EXPRESS',
  'CARDHOLDER',
  'CARD HOLDER',
  'VALID THRU',
  'VALID THROUGH',
  'GOOD THRU',
  'MEMBER SINCE',
  'CONTACTLESS',
  'DEBIT CARD',
  'CREDIT CARD',
];

/// Short words of a bank card, which a card that names itself a national
/// identity card overrides: they could be misread from its Urdu.
const _bankWords = [
  'VISA',
  'BANK',
  'BANKING',
  'DEBIT',
  'CREDIT',
  'AMEX',
  'JCB',
  'DISCOVER',
  'CIRRUS',
  'PLATINUM',
  'TITANIUM',
  'VALID FROM',
  'MONTH YEAR',
];

/// Cards and documents that are never a CNIC, and words a CNIC never
/// prints but other cards do, whatever else they say. Other cards name the
/// CNIC's number "CNIC No."; a CNIC calls it its identity number.
const _otherTerms = [
  'PASSPORT',
  'DRIVING LICENCE',
  'DRIVING LICENSE',
  'DRIVING PERMIT',
  'LEARNER PERMIT',
  'ARMS LICENCE',
  'ARMS LICENSE',
  'LICENCE',
  'LICENSE',
  'PAKISTAN ORIGIN CARD',
  'JUVENILE',
  'CHILD REGISTRATION',
  'PROOF OF REGISTRATION',
  'CNIC',
  'STUDENT',
  'UNIVERSITY',
  'COLLEGE',
  'SCHOOL',
  'ACADEMY',
  'INSTITUTE',
  'EMPLOYEE',
  'EMPLOYEES',
  'DESIGNATION',
  'DEPARTMENT',
  'BLOOD GROUP',
  'MEMBERSHIP',
  'INSURANCE',
  'LIBRARY',
  'COMPANY',
  'LIMITED',
  'RAILWAYS',
  'VEHICLE',
];

/// Short words of other cards, which a card that names itself a national
/// identity card overrides.
const _otherWords = [
  'STAFF',
  'HEALTH',
  'SEHAT',
  'ROLL NO',
  'REG NO',
  'POLICE',
  'ARMY',
  'DRIVING',
  'LTD',
  'PVT',
  'CLUB',
  'VOTER',
  'NTN',
];

/// What the text read on a card says about it: whether it is a bank card
/// or another card that only looks like a CNIC.
class _Evidence {
  _Evidence(List<OcrLine> lines)
    : _words = [
        for (final line in lines)
          if (line.text.trim().isNotEmpty)
            ' ${line.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]+'), ' ').trim()} ',
      ],
      _letters = [
        for (final line in lines)
          if (line.text.trim().isNotEmpty) _lettersOf(line.text),
      ] {
    for (final line in lines) {
      final text = _digitize(line.text);
      for (final match in _cardNumber.allMatches(text)) {
        if (_luhn(match[0]!.replaceAll(RegExp(r'\D'), ''))) {
          _paymentNumber = true;
        }
      }
      if (line.text.contains('<<')) _machineReadable = true;
    }
    _identity = _identityCues.any(_hasCue);
  }

  /// Each run in capitals, its words single-spaced and padded with a space.
  /// Each run is matched on its own: words of two runs side by side, like
  /// "Identity Card" over "Holder's Signature", aren't a phrase.
  final List<String> _words;

  /// Each run's letters, in capitals.
  final List<String> _letters;
  bool _paymentNumber = false;
  bool _machineReadable = false;
  late final bool _identity;

  /// Enough text to call it text: a word of three letters or digits.
  bool get readable =>
      _words.any((words) => RegExp('[A-Z0-9]{3}').hasMatch(words));

  bool get bankCard =>
      _paymentNumber ||
      _bankTerms.any(_hasCue) ||
      (!_identity && _bankWords.any(_hasWord));

  bool get otherCard =>
      _machineReadable ||
      _otherTerms.any(_hasCue) ||
      (!_identity && _otherWords.any(_hasWord));

  /// A whole word or phrase on one of the runs.
  bool _hasWord(String word) =>
      _words.any((words) => words.contains(' $word '));

  /// A whole word or phrase; or, eight letters or longer, one read with a
  /// letter or two wrong.
  bool _hasCue(String cue) {
    if (_hasWord(cue)) return true;
    final letters = cue.replaceAll(' ', '');
    if (letters.length < 8) return false;
    final slack = _slack(letters.length);
    return _letters.any((run) => _fuzzyContains(run, letters, slack));
  }
}

/// A payment card's number: sixteen digits in fours, or fifteen in four,
/// six and five.
final _cardNumber = RegExp(
  r'(?<!\d)(?:\d{4}[ -]?){3}\d{4}(?!\d)|(?<!\d)\d{4}[ -]?\d{6}[ -]?\d{5}(?!\d)',
);

/// Letters the text recognition reads in place of digits.
const _lookalikes = {
  'O': '0',
  'o': '0',
  'Q': '0',
  'D': '0',
  'U': '0',
  'I': '1',
  'i': '1',
  'l': '1',
  'L': '1',
  '|': '1',
  '!': '1',
  'Z': '2',
  'z': '2',
  'S': '5',
  's': '5',
  'A': '4',
  'B': '8',
  'b': '6',
  'G': '6',
  'g': '9',
  'q': '9',
  'T': '7',
};

/// [text] with the letters of mostly-digit words read as the digits they
/// look like, as "352O2-I234567-1" for 35202-1234567-1.
String _digitize(String text) => text.splitMapJoin(
  RegExp(r'\S+'),
  onMatch: (match) {
    final word = match[0]!;
    var digits = 0;
    var others = 0;
    for (final char in word.split('')) {
      if (RegExp(r'\d').hasMatch(char)) {
        digits++;
      } else if (_lookalikes.containsKey(char) ||
          RegExp('[A-Za-z]').hasMatch(char)) {
        others++;
      }
    }
    if (digits < 2 || digits < others) return word;
    return word.split('').map((char) => _lookalikes[char] ?? char).join();
  },
  onNonMatch: (text) => text,
);

/// Whether [digits] pass the Luhn check every payment card's number does.
bool _luhn(String digits) {
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var digit = digits.codeUnitAt(digits.length - 1 - i) - 48;
    if (i.isOdd) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
  }
  return digits.isNotEmpty && sum % 10 == 0;
}

String _lettersOf(String text) =>
    text.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');

/// How many letters a word of [length] may be read wrong by and still
/// count.
int _slack(int length) => length >= 11
    ? 2
    : length >= 6
    ? 1
    : 0;

/// Whether [needle] appears somewhere in [hay] with at most [edits]
/// letters changed, added or dropped.
bool _fuzzyContains(String hay, String needle, int edits) {
  final length = needle.length;
  if (length == 0) return true;
  if (hay.contains(needle)) return true;
  if (edits <= 0) return false;
  final column = List<int>.generate(length + 1, (i) => i);
  for (var j = 0; j < hay.length; j++) {
    var diagonal = column[0];
    column[0] = 0;
    for (var i = 1; i <= length; i++) {
      final left = column[i];
      final cost = needle.codeUnitAt(i - 1) == hay.codeUnitAt(j) ? 0 : 1;
      column[i] = math.min(
        math.min(column[i - 1] + 1, left + 1),
        diagonal + cost,
      );
      diagonal = left;
    }
    if (column[length] <= edits) return true;
  }
  return false;
}
