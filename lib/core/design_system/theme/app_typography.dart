import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';

/// The type scale. Headings and titles are set in Outfit, everything else
/// in Inter; colours come from [AppColors] so dark mode follows.
abstract final class AppTypography {
  static TextTheme textTheme(AppColors colors) {
    TextStyle display(
      double size,
      double letterSpacing,
      double height, {
      FontWeight weight = AppFonts.semiBold,
    }) => TextStyle(
      fontFamily: AppFonts.display,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: colors.textPrimary,
    );
    TextStyle text(
      double size,
      FontWeight weight,
      double height,
      Color color, {
      double letterSpacing = 0,
    }) => TextStyle(
      fontFamily: AppFonts.text,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
    return TextTheme(
      displayLarge: display(40, -0.8, 1.1),
      displayMedium: display(34, -0.6, 1.12),
      displaySmall: display(28, -0.4, 1.15),
      // The greeting on the home screen.
      headlineLarge: display(27, -0.95, 1.15),
      headlineMedium: display(22, -0.3, 1.25),
      headlineSmall: display(20, -0.2, 1.25),
      titleLarge: display(18, -0.1, 1.3),
      titleMedium: text(16, AppFonts.semiBold, 1.35, colors.textPrimary),
      titleSmall: text(14, AppFonts.semiBold, 1.35, colors.textPrimary),
      bodyLarge: text(16, AppFonts.regular, 1.5, colors.textPrimary),
      bodyMedium: text(14, AppFonts.regular, 1.45, colors.textSecondary),
      bodySmall: text(12, AppFonts.regular, 1.4, colors.textTertiary),
      labelLarge: text(
        15,
        AppFonts.semiBold,
        1.2,
        colors.textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: text(13, AppFonts.medium, 1.25, colors.textSecondary),
      labelSmall: text(
        11,
        AppFonts.semiBold,
        1.2,
        colors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }
}
