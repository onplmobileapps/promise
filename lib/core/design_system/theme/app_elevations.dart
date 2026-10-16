import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';

/// The depth of the design: how raised keys, cards, dialogs and sheets sit
/// above the page. Primary keys carry a solid edge underneath, which is what
/// reads as 3D; pressing one sinks it onto that edge.
@immutable
class AppElevations extends ThemeExtension<AppElevations> {
  const AppElevations({
    required this.raised,
    required this.card,
    required this.key,
    required this.keyPressed,
    required this.dangerKey,
    required this.dangerKeyPressed,
    required this.dialog,
    required this.sheet,
    required this.glass,
    required this.dome,
    required this.domeInset,
    required this.tileInset,
    required this.recessInset,
    required this.pressedInset,
    required this.knob,
    required this.iconDrop,
    required this.keyInset,
    required this.keyPressedInset,
    required this.raisedInset,
    required this.sphere,
    required this.sphereInset,
    required this.daySphere,
  });

  /// Elevations drawn from [colors], for either brightness.
  factory AppElevations.from(AppColors colors, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final shadow = colors.shadow;
    BoxShadow soft(double alpha, double y, double blur, [double spread = 0]) =>
        BoxShadow(
          color: shadow.withValues(alpha: alpha),
          offset: Offset(0, y),
          blurRadius: blur,
          spreadRadius: spread,
        );
    BoxShadow edge(Color color, double depth) =>
        BoxShadow(color: color, offset: Offset(0, depth));
    return AppElevations(
      raised: [
        soft(dark ? 0.5 : 0.06, 1, 2),
        soft(dark ? 0.7 : 0.12, 6, 14, -4),
      ],
      card: [
        soft(dark ? 0.4 : 0.04, 1, 3),
        soft(dark ? 0.7 : 0.09, 10, 28, -6),
      ],
      key: [
        edge(colors.primaryEdge, AppSizes.keyEdge),
        BoxShadow(
          color: colors.shadowAccent.withValues(alpha: dark ? 0.6 : 0.28),
          offset: const Offset(0, 10),
          blurRadius: 20,
          spreadRadius: -6,
        ),
      ],
      keyPressed: [edge(colors.primaryEdge, AppSizes.keyEdgePressed)],
      dangerKey: [
        edge(colors.dangerEdge, AppSizes.keyEdge),
        BoxShadow(
          color: colors.onDangerContainer.withValues(alpha: dark ? 0.4 : 0.2),
          offset: const Offset(0, 10),
          blurRadius: 20,
          spreadRadius: -6,
        ),
      ],
      dangerKeyPressed: [edge(colors.dangerEdge, AppSizes.keyEdgePressed)],
      dialog: [soft(dark ? 0.6 : 0.22, 18, 44, -10)],
      sheet: [soft(dark ? 0.6 : 0.16, -8, 30, -6)],
      glass: [soft(dark ? 0.6 : 0.16, 14, 34, -10)],
      dome: [
        edge(colors.domeEdge, AppSizes.domeEdge),
        soft(dark ? 0.6 : 0.22, 12, 22, -6),
      ],
      domeInset: [
        BoxShadow(color: colors.surfaceRaised, offset: const Offset(0, 3)),
        soft(dark ? 0.3 : 0.08, -8, 14),
      ],
      tileInset: [
        BoxShadow(color: colors.surfaceRaised, offset: const Offset(0, 1)),
        BoxShadow(
          color: colors.shadowAccent.withValues(alpha: dark ? 0.3 : 0.08),
          offset: const Offset(0, -2),
          blurRadius: 4,
        ),
      ],
      recessInset: [
        soft(dark ? 0.5 : 0.12, 2, 4),
        BoxShadow(color: colors.surfaceRaised, offset: const Offset(0, -1)),
      ],
      pressedInset: [soft(dark ? 0.6 : 0.3, 2, 4)],
      knob: [soft(dark ? 0.7 : 0.28, 3, 6), soft(dark ? 0.6 : 0.2, 1, 1)],
      iconDrop: BoxShadow(
        color: (dark ? colors.shadow : colors.accent).withValues(
          alpha: dark ? 0.5 : 0.3,
        ),
        offset: const Offset(0, 10),
        blurRadius: 8,
      ),
      keyInset: [
        BoxShadow(
          color: colors.surfaceRaised.withValues(alpha: dark ? 0.5 : 0.75),
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: colors.shadowAccent.withValues(alpha: dark ? 0.12 : 0.16),
          offset: const Offset(0, -2),
        ),
      ],
      keyPressedInset: [soft(dark ? 0.5 : 0.2, 2, 5)],
      raisedInset: [
        BoxShadow(color: colors.surfaceRaised, offset: const Offset(0, 1)),
        soft(dark ? 0.3 : 0.05, -2, 0),
      ],
      sphere: [soft(dark ? 0.6 : 0.2, 10, 20, -4)],
      sphereInset: [
        BoxShadow(
          color: colors.surfaceRaised.withValues(alpha: dark ? 0.3 : 0.65),
          offset: const Offset(0, 2),
        ),
        soft(dark ? 0.4 : 0.14, -5, 9),
      ],
      daySphere: [
        BoxShadow(
          color: colors.shadowAccent.withValues(alpha: dark ? 0.6 : 0.4),
          offset: const Offset(0, 3),
          blurRadius: 6,
        ),
        BoxShadow(
          color: colors.success.withValues(alpha: dark ? 0.4 : 0.6),
          offset: const Offset(0, 8),
          blurRadius: 14,
          spreadRadius: -6,
        ),
      ],
    );
  }

  static final light = AppElevations.from(AppColors.light, Brightness.light);
  static final dark = AppElevations.from(AppColors.dark, Brightness.dark);

  /// Secondary keys, chips, segmented thumbs: lifted a little.
  final List<BoxShadow> raised;

  /// Cards floating over the page.
  final List<BoxShadow> card;

  /// A primary key at rest, with its edge.
  final List<BoxShadow> key;

  /// A primary key while pressed.
  final List<BoxShadow> keyPressed;

  /// A destructive key at rest, with its edge.
  final List<BoxShadow> dangerKey;

  /// A destructive key while pressed.
  final List<BoxShadow> dangerKeyPressed;

  /// Dialogs over the scrim.
  final List<BoxShadow> dialog;

  /// Bottom sheets, cast upwards.
  final List<BoxShadow> sheet;

  /// Frosted glass floating over the page. Drawn for a ring
  /// [AppSizes.medallionDesign] across; [ScaledShadows] fits it to others.
  final List<BoxShadow> glass;

  /// A raised dome standing on its rim. Drawn for a dome
  /// [AppSizes.domeDesign] across; [ScaledShadows] fits it to others.
  final List<BoxShadow> dome;

  /// Light along the top of a dome and shade gathering at its foot,
  /// painted inside it by `InsetShadowPainter`. Drawn for a dome
  /// [AppSizes.domeDesign] across.
  final List<BoxShadow> domeInset;

  /// Light along the top of a 3D icon tile and a jade shade at its foot,
  /// painted inside it by `InsetShadowPainter`. Drawn for a tile
  /// [AppSizes.moduleTile] across.
  final List<BoxShadow> tileInset;

  /// Shade inside a track or well sunk into the page, lit along its
  /// lower lip; painted by `InsetShadowPainter`.
  final List<BoxShadow> recessInset;

  /// Shade inside something pressed in, like a selected filter chip;
  /// painted by `InsetShadowPainter`.
  final List<BoxShadow> pressedInset;

  /// A switch's knob, a ball resting on its track.
  final List<BoxShadow> knob;

  /// The soft jade shadow a 3D icon casts below its own outline. Drawn for
  /// an icon [AppSizes.moduleIcon] across.
  final BoxShadow iconDrop;

  /// The light along the top of a key's face and the shade at its foot,
  /// painted inside it by `InsetShadowPainter`.
  final List<BoxShadow> keyInset;

  /// The shade inside a key while it is pressed in.
  final List<BoxShadow> keyPressedInset;

  /// The light along the top of a raised face, painted inside it.
  final List<BoxShadow> raisedInset;

  /// The drop beneath a dialog's sphere badge.
  final List<BoxShadow> sphere;

  /// The light along the top of a sphere badge and the shade at its foot,
  /// painted inside it.
  final List<BoxShadow> sphereInset;

  /// The drop beneath a picked day, a small jade sphere on a calendar.
  final List<BoxShadow> daySphere;

  @override
  AppElevations copyWith({
    List<BoxShadow>? raised,
    List<BoxShadow>? card,
    List<BoxShadow>? key,
    List<BoxShadow>? keyPressed,
    List<BoxShadow>? dangerKey,
    List<BoxShadow>? dangerKeyPressed,
    List<BoxShadow>? dialog,
    List<BoxShadow>? sheet,
    List<BoxShadow>? glass,
    List<BoxShadow>? dome,
    List<BoxShadow>? domeInset,
    List<BoxShadow>? tileInset,
    List<BoxShadow>? recessInset,
    List<BoxShadow>? pressedInset,
    List<BoxShadow>? knob,
    BoxShadow? iconDrop,
    List<BoxShadow>? keyInset,
    List<BoxShadow>? keyPressedInset,
    List<BoxShadow>? raisedInset,
    List<BoxShadow>? sphere,
    List<BoxShadow>? sphereInset,
    List<BoxShadow>? daySphere,
  }) {
    return AppElevations(
      raised: raised ?? this.raised,
      card: card ?? this.card,
      key: key ?? this.key,
      keyPressed: keyPressed ?? this.keyPressed,
      dangerKey: dangerKey ?? this.dangerKey,
      dangerKeyPressed: dangerKeyPressed ?? this.dangerKeyPressed,
      dialog: dialog ?? this.dialog,
      sheet: sheet ?? this.sheet,
      glass: glass ?? this.glass,
      dome: dome ?? this.dome,
      domeInset: domeInset ?? this.domeInset,
      tileInset: tileInset ?? this.tileInset,
      recessInset: recessInset ?? this.recessInset,
      pressedInset: pressedInset ?? this.pressedInset,
      knob: knob ?? this.knob,
      iconDrop: iconDrop ?? this.iconDrop,
      keyInset: keyInset ?? this.keyInset,
      keyPressedInset: keyPressedInset ?? this.keyPressedInset,
      raisedInset: raisedInset ?? this.raisedInset,
      sphere: sphere ?? this.sphere,
      sphereInset: sphereInset ?? this.sphereInset,
      daySphere: daySphere ?? this.daySphere,
    );
  }

  @override
  AppElevations lerp(ThemeExtension<AppElevations>? other, double t) {
    if (other is! AppElevations) return this;
    List<BoxShadow> mix(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? b;
    return AppElevations(
      raised: mix(raised, other.raised),
      card: mix(card, other.card),
      key: mix(key, other.key),
      keyPressed: mix(keyPressed, other.keyPressed),
      dangerKey: mix(dangerKey, other.dangerKey),
      dangerKeyPressed: mix(dangerKeyPressed, other.dangerKeyPressed),
      dialog: mix(dialog, other.dialog),
      sheet: mix(sheet, other.sheet),
      glass: mix(glass, other.glass),
      dome: mix(dome, other.dome),
      domeInset: mix(domeInset, other.domeInset),
      tileInset: mix(tileInset, other.tileInset),
      recessInset: mix(recessInset, other.recessInset),
      pressedInset: mix(pressedInset, other.pressedInset),
      knob: mix(knob, other.knob),
      iconDrop: BoxShadow.lerp(iconDrop, other.iconDrop, t) ?? other.iconDrop,
      keyInset: mix(keyInset, other.keyInset),
      keyPressedInset: mix(keyPressedInset, other.keyPressedInset),
      raisedInset: mix(raisedInset, other.raisedInset),
      sphere: mix(sphere, other.sphere),
      sphereInset: mix(sphereInset, other.sphereInset),
      daySphere: mix(daySphere, other.daySphere),
    );
  }
}

/// Shadows drawn for one size, redrawn for another: offsets, blurs and
/// spreads all scale by [factor].
extension ScaledShadows on List<BoxShadow> {
  List<BoxShadow> scaled(double factor) => [
    for (final shadow in this) shadow.scale(factor),
  ];
}
