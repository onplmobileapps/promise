import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';

/// One 3D sphere's colours: lit at [highlight], through [body], into
/// [shade], ringed by a soft [halo], with a [mark] drawn on it.
@immutable
class SphereColors {
  const SphereColors({
    required this.highlight,
    required this.body,
    required this.shade,
    required this.halo,
    this.mark = AppPalette.ink900,
  });

  final Color highlight;
  final Color body;
  final Color shade;
  final Color halo;

  /// The ink of a glyph on the sphere. Spheres stay luminous in both
  /// themes, so it stays dark in both.
  final Color mark;

  static SphereColors lerp(SphereColors a, SphereColors b, double t) =>
      SphereColors(
        highlight: Color.lerp(a.highlight, b.highlight, t)!,
        body: Color.lerp(a.body, b.body, t)!,
        shade: Color.lerp(a.shade, b.shade, t)!,
        halo: Color.lerp(a.halo, b.halo, t)!,
        mark: Color.lerp(a.mark, b.mark, t)!,
      );
}

/// The 3D spheres that badge the dialogs: jade for done, coral for trouble
/// and for confirming something that can't be undone, gold for warnings,
/// sky for news. They stay luminous in both themes.
@immutable
class AppSpheres extends ThemeExtension<AppSpheres> {
  const AppSpheres({
    required this.jade,
    required this.coral,
    required this.gold,
    required this.sky,
  });

  static const standard = AppSpheres(
    jade: SphereColors(
      highlight: AppPalette.sphereJadeLight,
      body: AppPalette.sphereJade,
      shade: AppPalette.sphereJadeShade,
      halo: AppPalette.sphereJadeHalo,
    ),
    coral: SphereColors(
      highlight: AppPalette.sphereCoralLight,
      body: AppPalette.sphereCoral,
      shade: AppPalette.sphereCoralShade,
      halo: AppPalette.sphereCoralHalo,
    ),
    gold: SphereColors(
      highlight: AppPalette.sphereGoldLight,
      body: AppPalette.sphereGold,
      shade: AppPalette.sphereGoldShade,
      halo: AppPalette.sphereGoldHalo,
      mark: AppPalette.gold800,
    ),
    sky: SphereColors(
      highlight: AppPalette.sphereSkyLight,
      body: AppPalette.sphereSky,
      shade: AppPalette.sphereSkyShade,
      halo: AppPalette.sphereSkyHalo,
    ),
  );

  final SphereColors jade;
  final SphereColors coral;
  final SphereColors gold;
  final SphereColors sky;

  @override
  AppSpheres copyWith({
    SphereColors? jade,
    SphereColors? coral,
    SphereColors? gold,
    SphereColors? sky,
  }) => AppSpheres(
    jade: jade ?? this.jade,
    coral: coral ?? this.coral,
    gold: gold ?? this.gold,
    sky: sky ?? this.sky,
  );

  @override
  AppSpheres lerp(ThemeExtension<AppSpheres>? other, double t) {
    if (other is! AppSpheres) return this;
    return AppSpheres(
      jade: SphereColors.lerp(jade, other.jade, t),
      coral: SphereColors.lerp(coral, other.coral, t),
      gold: SphereColors.lerp(gold, other.gold, t),
      sky: SphereColors.lerp(sky, other.sky, t),
    );
  }
}
