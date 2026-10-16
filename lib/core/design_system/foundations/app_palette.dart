import 'package:flutter/painting.dart';

/// The raw colours of PROMISE's design language, "Ivory Jade": warm ivory
/// neutrals, a quiet jade for actions, gold for warmth, coral for danger and
/// sky for information, plus the near-black steps of dark mode.
///
/// This is the only file that spells out colour values. Widgets never read
/// it: they ask the theme for a role in `AppColors`, so light and dark mode
/// change together.
abstract final class AppPalette {
  // Ivory neutrals.
  static const white = Color(0xFFFFFFFF);
  static const ivory50 = Color(0xFFFCFBF9);
  static const ivory100 = Color(0xFFF7F6F3);
  static const ivory200 = Color(0xFFF4F2EE);
  static const ivory300 = Color(0xFFF1EFEA);
  static const ivory400 = Color(0xFFEFEDE8);
  static const sand200 = Color(0xFFE7E4DD);
  static const sand300 = Color(0xFFDEDAD2);
  static const sand400 = Color(0xFFD9D5CC);

  // Slate ink.
  static const ink900 = Color(0xFF1D2939);
  static const ink700 = Color(0xFF4D5B68);
  static const ink500 = Color(0xFF6A7683);
  static const ink400 = Color(0xFF8A96A1);
  static const ink300 = Color(0xFFA3AFA9);

  // Jade.
  static const jade50 = Color(0xFFEFF5F2);
  static const jade100 = Color(0xFFE3EEE9);
  static const jade200 = Color(0xFFD5E6DE);
  static const jade300 = Color(0xFFC5DFD3);
  static const jade400 = Color(0xFFA8CBBC);
  static const jade450 = Color(0xFFA0C9B8);
  static const jade500 = Color(0xFF8DBDA9);
  static const jade600 = Color(0xFF78A894);
  static const jade700 = Color(0xFF5E9C85);
  static const jade800 = Color(0xFF4A8571);
  static const jade900 = Color(0xFF3A6D5C);
  static const jade950 = Color(0xFF2E5A4B);

  // Gold.
  static const gold50 = Color(0xFFFBF1DA);
  static const gold300 = Color(0xFFE4C575);
  static const gold500 = Color(0xFFD9A93A);
  static const gold800 = Color(0xFF7D5A12);

  // Coral.
  static const coral50 = Color(0xFFFDE7E3);
  static const coral200 = Color(0xFFFFD6CD);
  static const coral300 = Color(0xFFF6A497);
  static const coral500 = Color(0xFFE5675A);
  static const coral600 = Color(0xFFD9786A);
  static const coral800 = Color(0xFFA63323);

  // Sky.
  static const sky50 = Color(0xFFE6F1FB);
  static const sky500 = Color(0xFF5FA3D9);
  static const sky800 = Color(0xFF1F5F99);

  // Night, for dark mode.
  static const night950 = Color(0xFF0F1113);
  static const night900 = Color(0xFF16191C);
  static const night800 = Color(0xFF1A1D20);
  static const night700 = Color(0xFF22262A);
  static const night600 = Color(0xFF2B3035);
  static const night500 = Color(0xFF3A4046);
  static const mist100 = Color(0xFFF2F4F5);
  static const mist300 = Color(0xFFA9B0B6);
  static const mist500 = Color(0xFF80878E);
  static const mist700 = Color(0xFF5B6268);
  static const jadeNight300 = Color(0xFFB4D5C7);
  static const jadeNight500 = Color(0xFF8EC3AE);
  static const jadeNight600 = Color(0xFF86B9A4);
  static const jadeNight800 = Color(0xFF4E7F6E);
  static const jadeNight900 = Color(0xFF121A17);
  static const goldNight = Color(0xFFE5C76B);
  static const coralNight = Color(0xFFF28B7D);
  static const coralNight800 = Color(0xFFB65E52);
  static const skyNight = Color(0xFF9CCBF0);

  /// The header wash: ivory leaning to sage.
  static const sage50 = Color(0xFFECEFEA);
  static const night975 = Color(0xFF111315);

  // Translucent steps for dark mode, where tints sit over near-black.
  static const white08 = Color(0x14FFFFFF);
  static const white16 = Color(0x29FFFFFF);
  static const jadeNight16 = Color(0x298EC3AE);
  static const jadeNight24 = Color(0x3D8EC3AE);
  static const goldNight16 = Color(0x29E5C76B);
  static const goldNightText = Color(0xFFEBD38C);
  static const coralNight16 = Color(0x29F28B7D);
  static const coralNightText = Color(0xFFF5A396);
  static const skyNight16 = Color(0x249CCBF0);
  static const skyNightText = Color(0xFFA9CEF5);
  static const scrimLight = Color(0x6B0E161C);
  static const scrimDark = Color(0x99000000);

  // Fixed tones.
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);

  /// The khatam pattern's line, a faint gold-grey.
  static const patternLight = Color(0x1A96805A);
  static const patternDark = Color(0x0BFFFFFF);

  /// The emblem medallion: the shaded side of its dome, frosted glass, the
  /// gold-grey of its orbit, and the warm glow behind it.
  static const sage200 = Color(0xFFE1E7E5);
  static const white55 = Color(0x8CFFFFFF);
  static const ornamentLight = Color(0x5296805A);
  static const sunriseLight = Color(0x99FFE7A8);

  /// The face of a 3D icon tile: warm ivory into a jade tint by day, one
  /// deep grey by night.
  static const ivory150 = Color(0xFFF6F4F0);
  static const night650 = Color(0xFF24292D);

  /// The soft jade inside the line icons, and in a selected one.
  static const jadeFill = Color(0xFFDFEBE5);
  static const jadeFillActive = Color(0xFFB6D6C8);
  static const jadeNight40 = Color(0x668EC3AE);

  /// A primary key while pressed: its face, darker at the top.
  static const jade475 = Color(0xFF93C4B1);

  /// Line icons inside fields and on tiles.
  static const jadeIcon = Color(0xFF4E8A74);

  /// The halo around a focused field, and around one in error.
  static const focusRingLight = Color(0x47A9CDBE);
  static const dangerRingLight = Color(0x24E5675A);

  /// The face of a disabled button.
  static const ivory450 = Color(0xFFECEAE6);

  // Attendance and team statuses.
  static const ink200 = Color(0xFFB3BDC7);
  static const jade75 = Color(0xFFE1ECE7);
  static const gold75 = Color(0xFFFFF0D4);
  static const gold400 = Color(0xFFF2C46B);
  static const sky75 = Color(0xFFE3F0FB);
  static const sky300 = Color(0xFF8CC0EA);

  /// The frosted glass of the sign-in card, nearly opaque.
  static const white78 = Color(0xC7FFFFFF);

  /// The soft blobs of colour behind the sign-in and settings screens.
  static const sandBlob = Color(0xFFF6EDD8);
  static const skyBlob = Color(0xFFE4ECF4);

  /// The dialog badges: 3D spheres lit from the upper left, each with a
  /// soft halo, for success, trouble, warning and news.
  static const sphereJadeLight = Color(0xFFF1F7F4);
  static const sphereJade = Color(0xFFB6D6C8);
  static const sphereJadeShade = Color(0xFF76AE97);
  static const sphereJadeHalo = Color(0x4082B5A0);
  static const sphereCoralLight = Color(0xFFFFF1EE);
  static const sphereCoral = Color(0xFFFBB7AB);
  static const sphereCoralShade = Color(0xFFE57F70);
  static const sphereCoralHalo = Color(0x40F49C8E);
  static const sphereGoldLight = Color(0xFFFFF9E6);
  static const sphereGold = Color(0xFFF3D88E);
  static const sphereGoldShade = Color(0xFFD9AE45);
  static const sphereGoldHalo = Color(0x47EBC86A);
  static const sphereSkyLight = Color(0xFFF2F8FE);
  static const sphereSky = Color(0xFFB9D9F3);
  static const sphereSkyShade = Color(0xFF7FB3E3);
  static const sphereSkyHalo = Color(0x4D9CC9EE);

  /// Shadows are tinted with ink rather than pure black.
  static const shadowInk = Color(0xFF1D2939);
  static const shadowJade = Color(0xFF3A6254);
}
