/// Window widths at which layouts change, after Material's window size
/// classes: phones are compact, small tablets and unfolded foldables medium,
/// large tablets expanded.
abstract final class AppBreakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// Below this height a screen counts as short (a phone in landscape, or
  /// the keyboard up), and drops decoration to keep its content in view.
  static const double shortHeight = 560;

  /// Tall enough for sign-in's medallion, greeting, card and footer all at
  /// their fullest; shorter, sign-in tightens up so it still fits.
  static const double loginRoomy = 880;

  /// Below this, sign-in's greeting steps aside as well.
  static const double loginTight = 800;
}
