import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_radius.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A search box sunk into the page, as at the top of a list: a magnifier,
/// the [hint] until something is typed, and a cross to clear it.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.clearLabel,
  });

  /// Also what a screen reader calls the box.
  final String hint;
  final ValueChanged<String> onChanged;

  /// Read by screen readers on the clear button.
  final String? clearLabel;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  final _query = TextEditingController();

  static const _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.borderLg,
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() {
    _query.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.surfaceSunken,
            Color.lerp(colors.surfaceSunken, colors.surfaceSunkenEnd, 0.35)!,
          ],
        ),
        borderRadius: AppRadius.borderLg,
        // The same whole edge as a text field's, clear on a white card.
        border: Border.all(
          color: Color.lerp(colors.outline, colors.outlineStrong, 0.6)!,
        ),
      ),
      child: CustomPaint(
        // Only the shade under the top edge; a light along the bottom
        // would rub the bottom edge out.
        foregroundPainter: InsetShadowPainter(
          shape: _shape,
          shadows: [context.elevations.recessInset.first],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.searchField),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md + AppSpacing.xxs,
            ),
            child: Row(
              children: [
                AppGlyphIcon(
                  AppGlyphs.search,
                  size: AppSizes.iconSm,
                  color: colors.textTertiary,
                ),
                AppSpacing.gapSmd,
                Expanded(
                  child: TextField(
                    controller: _query,
                    onChanged: (value) {
                      setState(() {});
                      widget.onChanged(value);
                    },
                    textInputAction: TextInputAction.search,
                    style: text.bodyLarge,
                    cursorColor: colors.textPrimary,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: text.bodyLarge?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ),
                if (_query.text.isEmpty)
                  AppSpacing.gapMd
                else
                  IconButton(
                    tooltip: widget.clearLabel,
                    onPressed: _clear,
                    icon: AppGlyphIcon(
                      AppGlyphs.close,
                      size: AppSizes.iconSm,
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
