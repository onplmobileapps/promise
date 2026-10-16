import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';

/// What a status says, which decides its colours: jade for the brand and
/// for done, gold for waiting or under way, coral for trouble, sky for
/// news, and grey for the rest.
enum AppTone {
  neutral,
  brand,
  warning,
  danger,
  info;

  /// The tint behind it, and the ink on that tint.
  (Color background, Color foreground) colorsIn(AppColors colors) =>
      switch (this) {
        neutral => (colors.surfaceMuted, colors.textSecondary),
        brand => (colors.primaryContainer, colors.onPrimaryContainer),
        warning => (colors.goldContainer, colors.onGoldContainer),
        danger => (colors.dangerContainer, colors.onDangerContainer),
        info => (colors.infoContainer, colors.onInfoContainer),
      };
}
