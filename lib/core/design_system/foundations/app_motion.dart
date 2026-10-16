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

  /// One turn of the loader's arc.
  static const Duration loaderTurn = Duration(milliseconds: 1400);

  /// One breath of a loading placeholder.
  static const Duration skeletonPulse = Duration(milliseconds: 1100);

  /// One spread of a calling halo.
  static const Duration halo = Duration(milliseconds: 2400);

  /// Quick to start, gentle to land: for things coming on screen.
  static const Curve enter = Curves.easeOutCubic;

  /// The sign-in screen's pieces rising into place, one after another.
  static const Duration loginEntrance = Duration(milliseconds: 900);

  /// The gleam across the biometric sign-in key, and its badge's ring.
  static const Duration biometricGleam = Duration(milliseconds: 1100);

  /// A card shaking its head at a failed sign-in.
  static const Duration shake = Duration(milliseconds: 480);
}
