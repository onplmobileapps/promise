import 'package:flutter/material.dart';
import 'package:railway_hrms/app/settings/text_look_card.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';

/// The profile's page for how large the app is drawn: the display size, as
/// the iPhone's Display Zoom sets it, then the size and weight of the text.
/// Each change applies at once and is remembered for next time.
class TextDisplayView extends StatelessWidget {
  const TextDisplayView({super.key});

  /// Opens the page over the app.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
    rootNavigator: true,
  ).push(MaterialPageRoute<void>(builder: (_) => const TextDisplayView()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = sl<TextLookController>();
    return Scaffold(
      body: AppScrollPage(
        backdrop: AppPageBackdrop.blobs,
        children: [
          AppHeaderBar(
            title: l10n.profileTextDisplay,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          AppSpacing.gapLg,
          AppSectionLabel(l10n.displaySizeTitle),
          AppSpacing.gapSm,
          ValueListenableBuilder<TextLook>(
            valueListenable: controller,
            builder: (context, look, _) => Semantics(
              label: l10n.displaySizeTitle,
              container: true,
              child: AppGrid(
                columns: 2,
                spacing: AppSpacing.sm,
                children: [
                  for (final size in DisplaySize.values)
                    AppChoiceCard(
                      selected: look.display == size,
                      onTap: () =>
                          controller.pick(look.copyWith(display: size)),
                      child: _DisplayChoice(size: size),
                    ),
                ],
              ),
            ),
          ),
          AppSpacing.gapSm,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              l10n.displaySizeFooter,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ),
          AppSpacing.gapXl,
          AppSectionLabel(l10n.profileSectionText),
          AppSpacing.gapSm,
          const TextLookCard(),
        ],
      ),
    );
  }
}

/// A display size on its card: a phone showing how much fits at that size,
/// its name, and what it gives.
class _DisplayChoice extends StatelessWidget {
  const _DisplayChoice({required this.size});

  final DisplaySize size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final (name, detail) = switch (size) {
      DisplaySize.standard => (
        l10n.displaySizeStandard,
        l10n.displaySizeStandardDetail,
      ),
      DisplaySize.large => (l10n.displaySizeLarge, l10n.displaySizeLargeDetail),
    };
    return Column(
      children: [
        ExcludeSemantics(child: _PhonePreview(zoom: size.scale)),
        AppSpacing.gapSm,
        Text(
          name,
          textAlign: TextAlign.center,
          style: text.labelLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: AppFonts.semiBold,
          ),
        ),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

/// A phone drawn small, its screen a bar over a grid of tiles and lines of
/// text, all [zoom] times larger, so fewer fit.
class _PhonePreview extends StatelessWidget {
  const _PhonePreview({required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Three tiles fit across at the default size; at large only two do.
    final tile = 15 * zoom;
    final line = 4 * zoom;
    const gap = 5.0;
    Widget block(double width, double height, Color color) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 3),
      ),
    );
    return Container(
      width: AppSizes.displayPreviewWidth,
      height: AppSizes.displayPreviewHeight,
      padding: const EdgeInsets.all(gap),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outlineStrong, width: 1.5),
      ),
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(28 * zoom, line * 1.5, colors.textSecondary),
            const SizedBox(height: gap),
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < 9; i++) block(tile, tile, colors.primary),
              ],
            ),
            const SizedBox(height: gap),
            for (var i = 0; i < 6; i++) ...[
              block(i.isEven ? 50 : 36, line, colors.textTertiary),
              SizedBox(height: line),
            ],
          ],
        ),
      ),
    );
  }
}
