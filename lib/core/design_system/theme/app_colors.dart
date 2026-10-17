import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';

/// The colour roles of the design, for light and dark mode.
///
/// Widgets read these from the theme (`context.colors`) and never name a
/// colour themselves; `AppPalette` holds the values.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.backgroundWash,
    required this.surface,
    required this.surfaceEnd,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.surfaceRaisedEnd,
    required this.surfaceSunken,
    required this.surfaceSunkenEnd,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.primary,
    required this.primaryHighlight,
    required this.primaryShade,
    required this.primaryEdge,
    required this.onPrimary,
    required this.accent,
    required this.accentStrong,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.focus,
    required this.focusRing,
    required this.gold,
    required this.goldContainer,
    required this.onGoldContainer,
    required this.danger,
    required this.dangerHighlight,
    required this.dangerShade,
    required this.dangerEdge,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.pattern,
    required this.scrim,
    required this.shadow,
    required this.shadowAccent,
    required this.domeShade,
    required this.domeEdge,
    required this.glass,
    required this.ornament,
    required this.ornamentAccent,
    required this.glow,
    required this.tile,
    required this.tileEnd,
    required this.navIndicator,
    required this.onDanger,
    required this.iconFill,
    required this.iconFillActive,
    required this.dangerRing,
    required this.iconAccent,
    required this.primaryPressed,
    required this.disabledSurface,
    required this.glassStrong,
    required this.blobJade,
    required this.blobSand,
    required this.blobSky,
    required this.knob,
    required this.knobShade,
    required this.success,
    required this.warningMark,
    required this.infoMark,
    required this.offline,
    required this.textFaint,
    required this.dayPresent,
    required this.dayPresentEdge,
    required this.dayLate,
    required this.dayLateEdge,
    required this.dayLeave,
    required this.dayLeaveEdge,
  });

  static const light = AppColors(
    background: AppPalette.ivory100,
    backgroundWash: AppPalette.sage50,
    surface: AppPalette.white,
    surfaceEnd: AppPalette.ivory50,
    surfaceMuted: AppPalette.ivory300,
    surfaceRaised: AppPalette.white,
    surfaceRaisedEnd: AppPalette.ivory200,
    surfaceSunken: AppPalette.ivory400,
    surfaceSunkenEnd: AppPalette.ivory50,
    outline: AppPalette.sand200,
    outlineStrong: AppPalette.sand400,
    textPrimary: AppPalette.ink900,
    textSecondary: AppPalette.ink700,
    textTertiary: AppPalette.ink500,
    textDisabled: AppPalette.ink300,
    primary: AppPalette.jade450,
    primaryHighlight: AppPalette.jade300,
    primaryShade: AppPalette.jade500,
    primaryEdge: AppPalette.jade600,
    onPrimary: AppPalette.ink900,
    accent: AppPalette.jade800,
    accentStrong: AppPalette.jade900,
    primaryContainer: AppPalette.jade100,
    onPrimaryContainer: AppPalette.jade950,
    focus: AppPalette.jade500,
    focusRing: AppPalette.focusRingLight,
    gold: AppPalette.gold500,
    goldContainer: AppPalette.gold50,
    onGoldContainer: AppPalette.gold800,
    danger: AppPalette.coral500,
    dangerHighlight: AppPalette.coral200,
    dangerShade: AppPalette.coral300,
    dangerEdge: AppPalette.coral600,
    dangerContainer: AppPalette.coral50,
    onDangerContainer: AppPalette.coral800,
    info: AppPalette.sky500,
    infoContainer: AppPalette.sky50,
    onInfoContainer: AppPalette.sky800,
    pattern: AppPalette.patternLight,
    scrim: AppPalette.scrimLight,
    shadow: AppPalette.shadowInk,
    shadowAccent: AppPalette.shadowJade,
    domeShade: AppPalette.sage200,
    domeEdge: AppPalette.sand300,
    glass: AppPalette.white55,
    ornament: AppPalette.ornamentLight,
    ornamentAccent: AppPalette.gold300,
    glow: AppPalette.sunriseLight,
    tile: AppPalette.ivory150,
    tileEnd: AppPalette.jade100,
    navIndicator: AppPalette.jade200,
    onDanger: AppPalette.white,
    iconFill: AppPalette.jadeFill,
    iconFillActive: AppPalette.jadeFillActive,
    dangerRing: AppPalette.dangerRingLight,
    iconAccent: AppPalette.jadeIcon,
    primaryPressed: AppPalette.jade475,
    disabledSurface: AppPalette.ivory450,
    glassStrong: AppPalette.white78,
    blobJade: AppPalette.jade200,
    blobSand: AppPalette.sandBlob,
    blobSky: AppPalette.skyBlob,
    knob: AppPalette.white,
    knobShade: AppPalette.sand400,
    success: AppPalette.jade700,
    warningMark: AppPalette.gold300,
    infoMark: AppPalette.sky300,
    offline: AppPalette.steel500,
    textFaint: AppPalette.ink200,
    dayPresent: AppPalette.jade75,
    dayPresentEdge: AppPalette.jade400,
    dayLate: AppPalette.gold75,
    dayLateEdge: AppPalette.gold400,
    dayLeave: AppPalette.sky75,
    dayLeaveEdge: AppPalette.sky300,
  );

  static const dark = AppColors(
    background: AppPalette.night950,
    backgroundWash: AppPalette.night900,
    surface: AppPalette.night800,
    surfaceEnd: AppPalette.night800,
    surfaceMuted: AppPalette.night700,
    surfaceRaised: AppPalette.night600,
    surfaceRaisedEnd: AppPalette.night700,
    surfaceSunken: AppPalette.night975,
    surfaceSunkenEnd: AppPalette.night900,
    outline: AppPalette.white08,
    outlineStrong: AppPalette.white16,
    textPrimary: AppPalette.mist100,
    textSecondary: AppPalette.mist300,
    textTertiary: AppPalette.mist500,
    textDisabled: AppPalette.mist700,
    primary: AppPalette.jadeNight500,
    primaryHighlight: AppPalette.jadeNight300,
    primaryShade: AppPalette.jadeNight600,
    primaryEdge: AppPalette.jadeNight800,
    onPrimary: AppPalette.jadeNight900,
    accent: AppPalette.jadeNight500,
    accentStrong: AppPalette.jadeNight300,
    primaryContainer: AppPalette.jadeNight16,
    onPrimaryContainer: AppPalette.jadeNight300,
    focus: AppPalette.jadeNight500,
    focusRing: AppPalette.jadeNight24,
    gold: AppPalette.goldNight,
    goldContainer: AppPalette.goldNight16,
    onGoldContainer: AppPalette.goldNightText,
    danger: AppPalette.coralNight,
    dangerHighlight: AppPalette.coral200,
    dangerShade: AppPalette.coral300,
    dangerEdge: AppPalette.coralNight800,
    dangerContainer: AppPalette.coralNight16,
    onDangerContainer: AppPalette.coralNightText,
    info: AppPalette.skyNight,
    infoContainer: AppPalette.skyNight16,
    onInfoContainer: AppPalette.skyNightText,
    pattern: AppPalette.patternDark,
    scrim: AppPalette.scrimDark,
    shadow: AppPalette.black,
    shadowAccent: AppPalette.black,
    domeShade: AppPalette.night800,
    domeEdge: AppPalette.night975,
    glass: AppPalette.white08,
    ornament: AppPalette.white16,
    ornamentAccent: AppPalette.goldNight,
    glow: AppPalette.goldNight16,
    tile: AppPalette.night650,
    tileEnd: AppPalette.night650,
    navIndicator: AppPalette.jadeNight24,
    onDanger: AppPalette.white,
    iconFill: AppPalette.jadeNight16,
    iconFillActive: AppPalette.jadeNight40,
    dangerRing: AppPalette.coralNight16,
    iconAccent: AppPalette.jadeNight500,
    primaryPressed: AppPalette.jadeNight600,
    disabledSurface: AppPalette.night700,
    glassStrong: AppPalette.white08,
    blobJade: AppPalette.transparent,
    blobSand: AppPalette.transparent,
    blobSky: AppPalette.transparent,
    knob: AppPalette.mist100,
    knobShade: AppPalette.mist300,
    success: AppPalette.jadeNight500,
    warningMark: AppPalette.goldNight,
    infoMark: AppPalette.skyNight,
    offline: AppPalette.steel300,
    textFaint: AppPalette.night500,
    dayPresent: AppPalette.jadeNight16,
    dayPresentEdge: AppPalette.jadeNight40,
    dayLate: AppPalette.goldNight16,
    dayLateEdge: AppPalette.goldNight,
    dayLeave: AppPalette.skyNight16,
    dayLeaveEdge: AppPalette.skyNight,
  );

  /// The page behind everything.
  final Color background;

  /// The soft wash at the top of a screen.
  final Color backgroundWash;

  /// Cards, sheets and dialogs.
  final Color surface;

  /// Where a card's gentle top-to-bottom shading ends.
  final Color surfaceEnd;

  /// Tiles and wells inside a card.
  final Color surfaceMuted;

  /// The top of a raised control, such as a secondary button or a selected tab.
  final Color surfaceRaised;

  /// The bottom of a raised control.
  final Color surfaceRaisedEnd;

  /// The top of a pressed-in control, such as a text field.
  final Color surfaceSunken;

  /// The bottom of a pressed-in control.
  final Color surfaceSunkenEnd;

  /// Hairlines and borders.
  final Color outline;

  /// Borders that must stand out, such as an empty checkbox.
  final Color outlineStrong;

  /// Headings and body text.
  final Color textPrimary;

  /// Supporting text.
  final Color textSecondary;

  /// Captions, hints and placeholder text.
  final Color textTertiary;

  /// Text of a disabled control.
  final Color textDisabled;

  /// The face of a primary key: the middle of its jade gradient.
  final Color primary;

  /// The lit top of a primary key.
  final Color primaryHighlight;

  /// The bottom of a primary key.
  final Color primaryShade;

  /// The 3D edge under a primary key.
  final Color primaryEdge;

  /// Text and icons on a primary key.
  final Color onPrimary;

  /// Jade for icons, links and selected states on a plain surface.
  final Color accent;

  /// Jade text that has to read at small sizes.
  final Color accentStrong;

  /// A jade tint behind selected rows and chips.
  final Color primaryContainer;

  /// Text on the jade tint.
  final Color onPrimaryContainer;

  /// The border of a focused field.
  final Color focus;

  /// The soft ring around a focused control.
  final Color focusRing;

  /// Gold accents and pending states.
  final Color gold;

  /// A gold tint behind pending items.
  final Color goldContainer;

  /// Text on the gold tint.
  final Color onGoldContainer;

  /// Errors and destructive actions.
  final Color danger;

  /// The lit top of a destructive key.
  final Color dangerHighlight;

  /// The bottom of a destructive key.
  final Color dangerShade;

  /// The 3D edge under a destructive key.
  final Color dangerEdge;

  /// A coral tint behind error messages.
  final Color dangerContainer;

  /// Error text, readable on the page and on the coral tint.
  final Color onDangerContainer;

  /// Information and links to more detail.
  final Color info;

  /// A sky tint behind informative items.
  final Color infoContainer;

  /// Text on the sky tint.
  final Color onInfoContainer;

  /// The lines of the khatam pattern.
  final Color pattern;

  /// The veil behind dialogs and sheets.
  final Color scrim;

  /// The base of every shadow.
  final Color shadow;

  /// The base of the shadow under primary keys.
  final Color shadowAccent;

  /// Where a raised dome turns away from the light.
  final Color domeShade;

  /// The solid rim that lifts a raised dome off the page.
  final Color domeEdge;

  /// Frosted glass over the page, like the ring around the emblem.
  final Color glass;

  /// Fine decorative lines, like the emblem's dashed orbit.
  final Color ornament;

  /// The gold marker on decorative lines.
  final Color ornamentAccent;

  /// Warm light behind the emblem.
  final Color glow;

  /// Where a 3D icon tile's face starts.
  final Color tile;

  /// Where a 3D icon tile's face ends.
  final Color tileEnd;

  /// The pill behind the selected item of a navigation bar.
  final Color navIndicator;

  /// Text and icons on the danger colour, like a count badge.
  final Color onDanger;

  /// The soft fill inside a line icon.
  final Color iconFill;

  /// The fill inside a selected line icon.
  final Color iconFillActive;

  /// The halo around a field in error.
  final Color dangerRing;

  /// Line icons inside fields and on tiles.
  final Color iconAccent;

  /// The top of a primary key's face while pressed.
  final Color primaryPressed;

  /// The face of a disabled button.
  final Color disabledSurface;

  /// Frosted glass that holds a form, like the sign-in card.
  final Color glassStrong;

  /// The jade blob behind the sign-in and settings screens.
  final Color blobJade;

  /// The sand blob behind the sign-in and settings screens.
  final Color blobSand;

  /// The sky blob behind the sign-in and settings screens.
  final Color blobSky;

  /// The ball of a switch, light in both themes so it shows on any track.
  final Color knob;

  /// The shaded side of [knob].
  final Color knobShade;

  /// Marks something done or present: a status dot, a ring, a bar.
  final Color success;

  /// Marks something late or waiting.
  final Color warningMark;

  /// Marks leave, or news.
  final Color infoMark;

  /// Marks something out of touch, as a train whose GPS has gone quiet:
  /// grey with blue in it, apart from the greys of plain text.
  final Color offline;

  /// Days outside the month shown, and other text that only fills a grid.
  final Color textFaint;

  /// A calendar day worked on time.
  final Color dayPresent;

  /// The edge of [dayPresent], as in a legend.
  final Color dayPresentEdge;

  /// A calendar day started late.
  final Color dayLate;

  /// The edge of [dayLate], as in a legend.
  final Color dayLateEdge;

  /// A calendar day on leave.
  final Color dayLeave;

  /// The edge of [dayLeave], as in a legend.
  final Color dayLeaveEdge;

  @override
  AppColors copyWith({
    Color? background,
    Color? backgroundWash,
    Color? surface,
    Color? surfaceEnd,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? surfaceRaisedEnd,
    Color? surfaceSunken,
    Color? surfaceSunkenEnd,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? primary,
    Color? primaryHighlight,
    Color? primaryShade,
    Color? primaryEdge,
    Color? onPrimary,
    Color? accent,
    Color? accentStrong,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? focus,
    Color? focusRing,
    Color? gold,
    Color? goldContainer,
    Color? onGoldContainer,
    Color? danger,
    Color? dangerHighlight,
    Color? dangerShade,
    Color? dangerEdge,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? pattern,
    Color? scrim,
    Color? shadow,
    Color? shadowAccent,
    Color? domeShade,
    Color? domeEdge,
    Color? glass,
    Color? ornament,
    Color? ornamentAccent,
    Color? glow,
    Color? tile,
    Color? tileEnd,
    Color? navIndicator,
    Color? onDanger,
    Color? iconFill,
    Color? iconFillActive,
    Color? dangerRing,
    Color? iconAccent,
    Color? primaryPressed,
    Color? disabledSurface,
    Color? glassStrong,
    Color? blobJade,
    Color? blobSand,
    Color? blobSky,
    Color? knob,
    Color? knobShade,
    Color? success,
    Color? warningMark,
    Color? infoMark,
    Color? offline,
    Color? textFaint,
    Color? dayPresent,
    Color? dayPresentEdge,
    Color? dayLate,
    Color? dayLateEdge,
    Color? dayLeave,
    Color? dayLeaveEdge,
  }) {
    return AppColors(
      background: background ?? this.background,
      backgroundWash: backgroundWash ?? this.backgroundWash,
      surface: surface ?? this.surface,
      surfaceEnd: surfaceEnd ?? this.surfaceEnd,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceRaisedEnd: surfaceRaisedEnd ?? this.surfaceRaisedEnd,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceSunkenEnd: surfaceSunkenEnd ?? this.surfaceSunkenEnd,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      primary: primary ?? this.primary,
      primaryHighlight: primaryHighlight ?? this.primaryHighlight,
      primaryShade: primaryShade ?? this.primaryShade,
      primaryEdge: primaryEdge ?? this.primaryEdge,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      focus: focus ?? this.focus,
      focusRing: focusRing ?? this.focusRing,
      gold: gold ?? this.gold,
      goldContainer: goldContainer ?? this.goldContainer,
      onGoldContainer: onGoldContainer ?? this.onGoldContainer,
      danger: danger ?? this.danger,
      dangerHighlight: dangerHighlight ?? this.dangerHighlight,
      dangerShade: dangerShade ?? this.dangerShade,
      dangerEdge: dangerEdge ?? this.dangerEdge,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      pattern: pattern ?? this.pattern,
      scrim: scrim ?? this.scrim,
      shadow: shadow ?? this.shadow,
      shadowAccent: shadowAccent ?? this.shadowAccent,
      domeShade: domeShade ?? this.domeShade,
      domeEdge: domeEdge ?? this.domeEdge,
      glass: glass ?? this.glass,
      ornament: ornament ?? this.ornament,
      ornamentAccent: ornamentAccent ?? this.ornamentAccent,
      glow: glow ?? this.glow,
      tile: tile ?? this.tile,
      tileEnd: tileEnd ?? this.tileEnd,
      navIndicator: navIndicator ?? this.navIndicator,
      onDanger: onDanger ?? this.onDanger,
      iconFill: iconFill ?? this.iconFill,
      iconFillActive: iconFillActive ?? this.iconFillActive,
      dangerRing: dangerRing ?? this.dangerRing,
      iconAccent: iconAccent ?? this.iconAccent,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      disabledSurface: disabledSurface ?? this.disabledSurface,
      glassStrong: glassStrong ?? this.glassStrong,
      blobJade: blobJade ?? this.blobJade,
      blobSand: blobSand ?? this.blobSand,
      blobSky: blobSky ?? this.blobSky,
      knob: knob ?? this.knob,
      knobShade: knobShade ?? this.knobShade,
      success: success ?? this.success,
      warningMark: warningMark ?? this.warningMark,
      infoMark: infoMark ?? this.infoMark,
      offline: offline ?? this.offline,
      textFaint: textFaint ?? this.textFaint,
      dayPresent: dayPresent ?? this.dayPresent,
      dayPresentEdge: dayPresentEdge ?? this.dayPresentEdge,
      dayLate: dayLate ?? this.dayLate,
      dayLateEdge: dayLateEdge ?? this.dayLateEdge,
      dayLeave: dayLeave ?? this.dayLeave,
      dayLeaveEdge: dayLeaveEdge ?? this.dayLeaveEdge,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundWash: Color.lerp(backgroundWash, other.backgroundWash, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceEnd: Color.lerp(surfaceEnd, other.surfaceEnd, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceRaisedEnd: Color.lerp(
        surfaceRaisedEnd,
        other.surfaceRaisedEnd,
        t,
      )!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceSunkenEnd: Color.lerp(
        surfaceSunkenEnd,
        other.surfaceSunkenEnd,
        t,
      )!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHighlight: Color.lerp(
        primaryHighlight,
        other.primaryHighlight,
        t,
      )!,
      primaryShade: Color.lerp(primaryShade, other.primaryShade, t)!,
      primaryEdge: Color.lerp(primaryEdge, other.primaryEdge, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      focus: Color.lerp(focus, other.focus, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldContainer: Color.lerp(goldContainer, other.goldContainer, t)!,
      onGoldContainer: Color.lerp(onGoldContainer, other.onGoldContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerHighlight: Color.lerp(dangerHighlight, other.dangerHighlight, t)!,
      dangerShade: Color.lerp(dangerShade, other.dangerShade, t)!,
      dangerEdge: Color.lerp(dangerEdge, other.dangerEdge, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      pattern: Color.lerp(pattern, other.pattern, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowAccent: Color.lerp(shadowAccent, other.shadowAccent, t)!,
      domeShade: Color.lerp(domeShade, other.domeShade, t)!,
      domeEdge: Color.lerp(domeEdge, other.domeEdge, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      ornament: Color.lerp(ornament, other.ornament, t)!,
      ornamentAccent: Color.lerp(ornamentAccent, other.ornamentAccent, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      tile: Color.lerp(tile, other.tile, t)!,
      tileEnd: Color.lerp(tileEnd, other.tileEnd, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      iconFill: Color.lerp(iconFill, other.iconFill, t)!,
      iconFillActive: Color.lerp(iconFillActive, other.iconFillActive, t)!,
      dangerRing: Color.lerp(dangerRing, other.dangerRing, t)!,
      iconAccent: Color.lerp(iconAccent, other.iconAccent, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      disabledSurface: Color.lerp(disabledSurface, other.disabledSurface, t)!,
      glassStrong: Color.lerp(glassStrong, other.glassStrong, t)!,
      blobJade: Color.lerp(blobJade, other.blobJade, t)!,
      blobSand: Color.lerp(blobSand, other.blobSand, t)!,
      blobSky: Color.lerp(blobSky, other.blobSky, t)!,
      knob: Color.lerp(knob, other.knob, t)!,
      knobShade: Color.lerp(knobShade, other.knobShade, t)!,
      success: Color.lerp(success, other.success, t)!,
      warningMark: Color.lerp(warningMark, other.warningMark, t)!,
      infoMark: Color.lerp(infoMark, other.infoMark, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      dayPresent: Color.lerp(dayPresent, other.dayPresent, t)!,
      dayPresentEdge: Color.lerp(dayPresentEdge, other.dayPresentEdge, t)!,
      dayLate: Color.lerp(dayLate, other.dayLate, t)!,
      dayLateEdge: Color.lerp(dayLateEdge, other.dayLateEdge, t)!,
      dayLeave: Color.lerp(dayLeave, other.dayLeave, t)!,
      dayLeaveEdge: Color.lerp(dayLeaveEdge, other.dayLeaveEdge, t)!,
    );
  }
}
