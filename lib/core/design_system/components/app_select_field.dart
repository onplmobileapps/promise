import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_badged.dart';
import 'package:railway_hrms/core/design_system/components/app_field_frame.dart';
import 'package:railway_hrms/core/design_system/components/app_grid.dart';
import 'package:railway_hrms/core/design_system/components/app_sheet.dart';
import 'package:railway_hrms/core/design_system/components/liquid_glass.dart';
import 'package:railway_hrms/core/design_system/foundations/app_motion.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The name shown for [option].
typedef OptionLabel<T> = String Function(T option);

/// A mark shown beside [option], [size] across: a logo, an avatar, an icon.
typedef OptionLeadingBuilder<T> =
    Widget Function(BuildContext context, T option, double size);

/// A form field that picks one of [options] from a sheet: a network, a
/// station, a type of leave. It is labelled, hinted and validated like the
/// text fields around it.
///
/// Options are compared with `==`, so the chosen one is ticked in the sheet.
class AppSelectField<T> extends FormField<T> {
  AppSelectField({
    super.key,
    required String label,
    required String hint,
    required List<T> options,
    required OptionLabel<T> optionLabel,
    OptionLeadingBuilder<T>? optionLeading,
    AppGlyph? glyph,
    String? sheetTitle,
    bool gridOptions = false,
    ValueChanged<T>? onChanged,
    super.validator,
    super.onSaved,
    super.initialValue,
    super.enabled,
    super.autovalidateMode,
  }) : super(
         builder: (state) => _SelectInput<T>(
           state: state,
           label: label,
           hint: hint,
           options: options,
           optionLabel: optionLabel,
           optionLeading: optionLeading,
           glyph: glyph,
           sheetTitle: sheetTitle ?? hint,
           grid: gridOptions,
           onChanged: onChanged,
         ),
       );
}

class _SelectInput<T> extends StatelessWidget {
  const _SelectInput({
    required this.state,
    required this.label,
    required this.hint,
    required this.options,
    required this.optionLabel,
    required this.optionLeading,
    required this.glyph,
    required this.sheetTitle,
    required this.grid,
    required this.onChanged,
  });

  final FormFieldState<T> state;
  final String label;
  final String hint;
  final List<T> options;
  final OptionLabel<T> optionLabel;
  final OptionLeadingBuilder<T>? optionLeading;

  /// Shown before anything is chosen, or beside a choice with no mark.
  final AppGlyph? glyph;
  final String sheetTitle;
  final bool grid;
  final ValueChanged<T>? onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showAppOptionsSheet<T>(
      context: context,
      title: sheetTitle,
      options: options,
      optionLabel: optionLabel,
      optionLeading: optionLeading,
      selected: state.value,
      grid: grid,
    );
    if (picked == null || !state.mounted) return;
    state.didChange(picked);
    onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = state.value;
    final enabled = state.widget.enabled;
    final leading = optionLeading;
    final error = state.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: value == null ? hint : optionLabel(value),
          child: ExcludeSemantics(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: enabled ? () => _pick(context) : null,
                borderRadius: AppRadius.borderLg,
                splashFactory: NoSplash.splashFactory,
                child: AppFieldFrame(
                  label: label,
                  glyph: value != null && leading != null ? null : glyph,
                  state: !enabled
                      ? AppFieldState.disabled
                      : error != null
                      ? AppFieldState.error
                      : AppFieldState.idle,
                  trailing: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppGlyphIcon(
                      AppGlyphs.chevronDown,
                      size: AppSizes.iconMd,
                      color: colors.textTertiary,
                    ),
                  ),
                  child: value == null
                      ? Text(
                          hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelLarge?.copyWith(
                            color: colors.textTertiary,
                            fontWeight: FontWeight.normal,
                          ),
                        )
                      : Row(
                          children: [
                            if (leading != null) ...[
                              leading(
                                context,
                                value,
                                AppSizes.optionLeadingCompact,
                              ),
                              AppSpacing.gapSm,
                            ],
                            Flexible(
                              child: Text(
                                optionLabel(value),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        if (error != null) AppFieldError(error),
      ],
    );
  }
}

/// Shows [options] in a sheet titled [title] and returns the one tapped, or
/// null if the sheet is closed without a choice. With [grid], a few options
/// with marks, such as networks with their logos, show as cards.
Future<T?> showAppOptionsSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required OptionLabel<T> optionLabel,
  OptionLeadingBuilder<T>? optionLeading,
  T? selected,
  bool grid = false,
}) {
  return showAppSheet<T>(
    context: context,
    title: title,
    closeLabel: context.l10n.actionClose,
    builder: (sheetContext) {
      void pick(T option) => Navigator.of(sheetContext).pop(option);
      if (grid) {
        return AppOptionsGrid<T>(
          options: options,
          optionLabel: optionLabel,
          optionLeading: optionLeading,
          selected: selected,
          onSelected: pick,
        );
      }
      return AppOptionsList<T>(
        options: options,
        optionLabel: optionLabel,
        optionLeading: optionLeading,
        selected: selected,
        onSelected: pick,
      );
    },
  );
}

/// [options] as cards, three to a row: each its mark over its name, the
/// [selected] one lit in jade with a tick on its corner.
class AppOptionsGrid<T> extends StatelessWidget {
  const AppOptionsGrid({
    super.key,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
    this.optionLeading,
    this.selected,
  });

  final List<T> options;
  final OptionLabel<T> optionLabel;
  final ValueChanged<T> onSelected;
  final OptionLeadingBuilder<T>? optionLeading;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: AppGrid(
        columns: AppSizes.optionGridColumns,
        children: [
          for (final option in options)
            _OptionCard(
              label: optionLabel(option),
              mark: optionLeading?.call(
                context,
                option,
                AppSizes.optionCardMark,
              ),
              selected: option == selected,
              onTap: () => onSelected(option),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.mark,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget? mark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final mark = this.mark;
    final card = AnimatedContainer(
      duration: AppMotion.short,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: selected
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
              ),
        color: selected ? colors.primaryContainer : null,
        borderRadius: AppRadius.borderLg,
        // The ring a picked card wears is drawn outside it, so picking one
        // never changes its size.
        border: Border.all(color: selected ? colors.primary : colors.outline),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colors.primary,
                  spreadRadius: AppSizes.optionCardRing - 1,
                ),
              ]
            : elevations.raised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark != null) ...[
            // Logos are drawn for a light ground, in either theme.
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.knob,
                borderRadius: AppRadius.borderMd,
                boxShadow: elevations.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: mark,
              ),
            ),
            AppSpacing.gapSm,
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: selected ? colors.onPrimaryContainer : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: LiquidPop(
        selected: selected,
        radius: AppRadius.borderLg,
        amount: AppSizes.liquidPopCard,
        child: GestureDetector(
          onTap: onTap,
          child: selected
              ? AppBadged(
                  badge: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxs),
                        child: AppGlyphIcon(
                          AppGlyphs.check,
                          size: AppSizes.iconXs,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  child: card,
                )
              : card,
        ),
      ),
    );
  }
}

/// [options] as a list to choose from, with the [selected] one ticked.
class AppOptionsList<T> extends StatelessWidget {
  const AppOptionsList({
    super.key,
    required this.options,
    required this.optionLabel,
    required this.onSelected,
    this.optionLeading,
    this.selected,
  });

  final List<T> options;
  final OptionLabel<T> optionLabel;
  final ValueChanged<T> onSelected;
  final OptionLeadingBuilder<T>? optionLeading;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (_, _) => Divider(color: colors.outline),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option == selected;
        return ListTile(
          selected: isSelected,
          selectedTileColor: colors.primaryContainer,
          leading: optionLeading?.call(context, option, AppSizes.optionLeading),
          title: Text(optionLabel(option)),
          trailing: isSelected
              ? AppGlyphIcon(
                  AppGlyphs.check,
                  size: AppSizes.iconMd,
                  color: colors.iconAccent,
                )
              : null,
          onTap: () => onSelected(option),
        );
      },
    );
  }
}
