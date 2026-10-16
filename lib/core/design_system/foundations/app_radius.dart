import 'package:flutter/painting.dart';

/// Corner radii. Small controls take the small steps, cards and sheets the
/// large ones.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// The large launch cards on the home screen.
  static const double module = 26;

  /// The corners of large, medium and small buttons.
  static const double buttonLarge = 18;
  static const double buttonMedium = 15;
  static const double buttonSmall = 11;
  static const double sheet = 28;
  static const double pill = 999;

  /// A stat tile sunk into a card.
  static const double tile = 14;

  /// A checkbox's corners.
  static const double checkbox = 8;

  /// A card that opens something, like the work area.
  static const double linkCard = 18;

  /// The main card of a screen, like today's shift.
  static const double heroCard = 22;

  /// A camera's window on the page.
  static const double viewport = 36;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderModule = BorderRadius.all(
    Radius.circular(module),
  );
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius borderSheet = BorderRadius.all(
    Radius.circular(sheet),
  );
  static const BorderRadius borderPill = BorderRadius.all(
    Radius.circular(pill),
  );
  static const BorderRadius borderTile = BorderRadius.all(
    Radius.circular(tile),
  );
  static const BorderRadius borderLinkCard = BorderRadius.all(
    Radius.circular(linkCard),
  );
  static const BorderRadius borderHeroCard = BorderRadius.all(
    Radius.circular(heroCard),
  );
  static const BorderRadius borderViewport = BorderRadius.all(
    Radius.circular(viewport),
  );
  static const BorderRadius borderSheetTop = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
