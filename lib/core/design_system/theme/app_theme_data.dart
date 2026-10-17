import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_back_button.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_palette.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/app_colors.dart';
import 'package:railway_hrms/core/design_system/theme/app_elevations.dart';
import 'package:railway_hrms/core/design_system/theme/app_spheres.dart';
import 'package:railway_hrms/core/design_system/theme/app_system_ui.dart';
import 'package:railway_hrms/core/design_system/theme/app_typography.dart';

/// Builds the app's [ThemeData] from the design tokens. Material widgets
/// that a screen hasn't yet replaced with a design-system component still
/// pick up the palette, type and shapes from here.
abstract final class AppThemeData {
  static final ThemeData light = _build(
    AppColors.light,
    AppElevations.light,
    Brightness.light,
  );

  static final ThemeData dark = _build(
    AppColors.dark,
    AppElevations.dark,
    Brightness.dark,
  );

  static ThemeData _build(
    AppColors c,
    AppElevations elevations,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    final text = AppTypography.textTheme(c);
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: isDark ? c.onPrimary : AppPalette.white,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.gold,
      onSecondary: c.textPrimary,
      secondaryContainer: c.goldContainer,
      onSecondaryContainer: c.onGoldContainer,
      tertiary: c.info,
      onTertiary: AppPalette.white,
      tertiaryContainer: c.infoContainer,
      onTertiaryContainer: c.onInfoContainer,
      error: c.onDangerContainer,
      onError: AppPalette.white,
      errorContainer: c.dangerContainer,
      onErrorContainer: c.onDangerContainer,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surfaceEnd,
      surfaceContainer: c.surfaceMuted,
      surfaceContainerHigh: c.surfaceRaisedEnd,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.outlineStrong,
      outlineVariant: c.outline,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.textPrimary,
      onInverseSurface: c.background,
      inversePrimary: c.primaryHighlight,
      surfaceTint: AppPalette.transparent,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.borderLg,
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
    );
    const buttonSize = WidgetStatePropertyAll(
      Size(AppSizes.minTapTarget, AppSizes.buttonLarge),
    );
    final buttonText = WidgetStatePropertyAll(text.labelLarge);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.text,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.outline,
      // A touch lights what it presses with a faint wash of the brand, as on
      // iOS, rather than Material's grey box and spreading ripple.
      splashFactory: NoSplash.splashFactory,
      splashColor: AppPalette.transparent,
      highlightColor: c.primary.withValues(alpha: 0.07),
      hoverColor: AppPalette.transparent,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [c, elevations, AppSpheres.standard],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        surfaceTintColor: AppPalette.transparent,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary, size: AppSizes.iconLg),
        systemOverlayStyle: AppSystemUi.of(brightness),
      ),
      iconTheme: IconThemeData(color: c.textSecondary, size: AppSizes.iconLg),
      // Pages slide in as on iOS, on every platform, and any page can be
      // swiped back from its leading edge.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      // Every bar's back button wears the design's tile.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const AppBackFace(),
      ),
      dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceSunken,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: c.textTertiary),
        labelStyle: text.bodyMedium?.copyWith(color: c.textTertiary),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.error)
                ? c.onDangerContainer
                : states.contains(WidgetState.focused)
                ? c.accent
                : c.textTertiary,
          ),
        ),
        errorStyle: text.bodySmall?.copyWith(color: c.onDangerContainer),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.focused) ? c.accent : c.textTertiary,
        ),
        suffixIconColor: c.textTertiary,
        border: border(c.outline),
        enabledBorder: border(c.outline),
        disabledBorder: border(c.outline),
        focusedBorder: border(c.focus, 1.5),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.surfaceMuted
                : c.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.textDisabled
                : c.onPrimary,
          ),
          elevation: const WidgetStatePropertyAll(0),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.surfaceMuted
                : c.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? c.textDisabled
                : c.onPrimary,
          ),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          side: WidgetStatePropertyAll(BorderSide(color: c.outlineStrong)),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.accent),
          textStyle: buttonText,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textSecondary),
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSizes.minTapTarget),
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppPalette.transparent,
        labelColor: c.textPrimary,
        unselectedLabelColor: c.textTertiary,
        labelStyle: text.labelMedium?.copyWith(
          fontWeight: AppFonts.semiBold,
          letterSpacing: AppFonts.tabLetterSpacing,
        ),
        unselectedLabelStyle: text.labelMedium?.copyWith(
          fontWeight: AppFonts.semiBold,
          letterSpacing: AppFonts.tabLetterSpacing,
        ),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surfaceRaised, c.surfaceRaisedEnd],
          ),
          borderRadius: AppRadius.borderMd,
          boxShadow: elevations.raised,
        ),
        overlayColor: const WidgetStatePropertyAll(AppPalette.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        surfaceTintColor: AppPalette.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderXl,
          side: BorderSide(color: c.outline),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: AppPalette.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
        barrierColor: c.scrim,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: AppPalette.transparent,
        modalBackgroundColor: c.surface,
        modalBarrierColor: c.scrim,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderSheetTop,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceMuted,
        selectedColor: c.primaryContainer,
        side: BorderSide(color: c.outline),
        labelStyle: text.labelMedium,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceMuted,
        circularTrackColor: c.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.surfaceRaised),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primaryEdge
              : c.outlineStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.surfaceSunken,
        ),
        checkColor: WidgetStatePropertyAll(c.onPrimary),
        side: BorderSide(color: c.outlineStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.accent
              : c.outlineStrong,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: AppPalette.transparent,
        headerBackgroundColor: c.primaryContainer,
        headerForegroundColor: c.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.onPrimary
              : c.textPrimary,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.primary : null,
        ),
        todayForegroundColor: WidgetStatePropertyAll(c.accent),
        todayBorder: BorderSide(color: c.accent),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.accent),
        ),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.textSecondary),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyLarge,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          surfaceTintColor: const WidgetStatePropertyAll(
            AppPalette.transparent,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
          ),
        ),
      ),
    );
  }
}
