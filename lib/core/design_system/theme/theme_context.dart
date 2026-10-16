import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';
import 'package:railway_hrms/core/design_system/theme/app_elevations.dart';
import 'package:railway_hrms/core/design_system/theme/app_spheres.dart';

/// Short ways to the design tokens from a [BuildContext].
extension ThemeContext on BuildContext {
  /// The colour roles of the current theme, light or dark.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light);

  /// The shadows that give controls and cards their depth.
  AppElevations get elevations =>
      Theme.of(this).extension<AppElevations>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppElevations.dark
          : AppElevations.light);

  /// The 3D spheres that badge dialogs.
  AppSpheres get spheres =>
      Theme.of(this).extension<AppSpheres>() ?? AppSpheres.standard;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
