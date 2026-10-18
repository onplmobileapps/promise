import 'package:flutter/animation.dart';

/// How long movement takes, and how it eases.
///
/// Motion is kept for things that change while the user is looking, like
/// the connection banner. The splash and sign-in screens don't move at all.
abstract final class AppMotion {
  /// A small change in place, such as one icon swapping for another.
  static const Duration short = Duration(milliseconds: 200);

  /// Something arriving or leaving, such as a banner sliding in.
  static const Duration medium = Duration(milliseconds: 320);

  /// Settles with a little overshoot, like the bar's lens sliding over.
  static const Curve spring = Cubic(0.34, 1.36, 0.64, 1);

  /// The spring the bar's glass lens runs on: a little overshoot, then
  /// still.
  static const double lensStiffness = 280;
  static const double lensDamping = 22;

  /// The spring a drop of liquid glass swells and settles on: soft, so it
  /// wobbles once as it lands.
  static const double liftStiffness = 420;
  static const double liftDamping = 16;

  /// The spring a page swiped back slides away or back on.
  static const double swipeStiffness = 400;
  static const double swipeDamping = 36;

  /// One breath of the main action key's glow.
  static const Duration keyGlow = Duration(milliseconds: 2200);

  /// How fast a lens of liquid glass rises over a choice when it is
  /// touched or picked, and how slowly it melts away after.
  static const Duration glassRise = Duration(milliseconds: 140);
  static const Duration glassFade = Duration(milliseconds: 650);

  /// How hard a picked choice is pushed out, in its size a second.
  static const double liquidPopVelocity = 7;

  /// How far a drop swells on its own when the selection moves without a
  /// touch.
  static const double liftPeek = 0.55;

  /// How fast the lens must go, in bar widths a second, to look fully on
  /// the move.
  static const double lensMotionGain = 0.9;

  /// The drop's jelly: a loose spring that overshoots, so a drop that
  /// stops squashes and wobbles a few times before it is still.
  static const double jellyStiffness = 320;
  static const double jellyDamping = 11;

  /// How far, in radians, the light swings round as the drop travels.
  static const double glintSwing = 0.9;

  /// The spring the selection chases a dragging finger on: tight enough to
  /// keep up, with a weight of its own, so it leans and stretches; just
  /// short of critical on iOS, so it settles with the faintest give.
  static const double chaseStiffness = 900;
  static const double chaseDamping = 48;

  /// Android's gliding pill: critically damped springs, so it arrives
  /// without overshooting, after a finger or to the item picked.
  static const double glideStiffness = 360;
  static const double glideDamping = 38;
  static const double glideChaseDamping = 60;

  /// How much the gliding pill stretches on its way, and the spring that
  /// eases it back without a wobble.
  static const double glideMotionGain = 0.5;
  static const double glideStretchStiffness = 500;
  static const double glideStretchDamping = 45;

  /// One turn of the loader's arc.
  static const Duration loaderTurn = Duration(milliseconds: 1400);

  /// One breath of a loading placeholder.
  static const Duration skeletonPulse = Duration(milliseconds: 1100);

  /// One spread of a calling halo.
  static const Duration halo = Duration(milliseconds: 2400);

  /// Quick to start, gentle to land: for things coming on screen.
  static const Curve enter = Curves.easeOutCubic;

  /// A piece coming into view: how long it rises, how far, and how much
  /// later each next one starts, so a list arrives in a ripple.
  static const Duration reveal = Duration(milliseconds: 380);
  static const double revealRise = 12;
  static const Duration revealStagger = Duration(milliseconds: 45);

  /// The most pieces of one list that wait their turn; the rest come with
  /// the last of them, so a long list isn't slow to appear.
  static const int revealStaggerMost = 8;

  /// A glyph drawn line by line, as an empty list's mark appears.
  static const Duration glyphDraw = Duration(milliseconds: 900);

  /// How far a row sinks when pressed, as a share of its size.
  static const double pressScale = 0.985;

  /// How far behind the one above it each of a page's first cards starts
  /// to rise, and how many are held back so; the rest rise with the last.
  static const Duration entranceStep = Duration(milliseconds: 45);
  static const int entranceStaggered = 6;

  /// How long a dialog's badge takes to swell into place.
  static const Duration badge = Duration(milliseconds: 420);

  /// The sign-in screen's pieces rising into place, one after another.
  static const Duration loginEntrance = Duration(milliseconds: 900);

  /// The gleam across the biometric sign-in key, and its badge's ring.
  static const Duration biometricGleam = Duration(milliseconds: 1100);

  /// A card shaking its head at a failed sign-in.
  static const Duration shake = Duration(milliseconds: 480);
}
