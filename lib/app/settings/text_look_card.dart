import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/theme/text_look_controller.dart';

/// The size and weight of the app's text, as WhatsApp sets them: a short
/// chat that shows the look as it changes, a slider from a small "A" to a
/// large one, and a switch for bold text. Each change applies at once and
/// is remembered for next time.
class TextLookCard extends StatelessWidget {
  const TextLookCard({super.key});

  /// What each of [TextLook.sizes] is called, smallest first.
  static List<String> textSizeNames(AppLocalizations l10n) => [
    l10n.textSizeSmall,
    l10n.textSizeDefault,
    l10n.textSizeLarge,
    l10n.textSizeLarger,
    l10n.textSizeLargest,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final controller = sl<TextLookController>();
    final names = textSizeNames(l10n);
    return ValueListenableBuilder<TextLook>(
      valueListenable: controller,
      builder: (context, look, _) => AppListGroup(
        children: [
          // A short chat in the look being set, on a quiet wash.
          ExcludeSemantics(
            child: ColoredBox(
              color: colors.surfaceSunken,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Bubble(
                      message: l10n.textPreviewMessage,
                      time: l10n.textPreviewTime,
                      mine: false,
                    ),
                    AppSpacing.gapSm,
                    _Bubble(
                      message: l10n.textPreviewReply,
                      time: l10n.textPreviewTime,
                      mine: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.textSizeTitle, style: text.titleSmall),
                    ),
                    AnimatedSwitcher(
                      duration: AppMotion.short,
                      child: AppTag(
                        names[look.size],
                        key: ValueKey(look.size),
                        tone: AppTone.brand,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        'A',
                        textScaler: TextScaler.noScaling,
                        style: text.labelMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: AppStepSlider(
                        value: look.size,
                        steps: TextLook.sizes.length,
                        label: l10n.textSizeTitle,
                        valueLabel: (step) => names[step],
                        onChanged: (size) =>
                            controller.pick(look.copyWith(size: size)),
                      ),
                    ),
                    AppSpacing.gapMd,
                    ExcludeSemantics(
                      child: Text(
                        'A',
                        textScaler: TextScaler.noScaling,
                        style: text.headlineSmall?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppListRow(
            leading: AppGlyphIcon(
              AppGlyphs.bold,
              size: AppSizes.glyphRow,
              color: colors.iconAccent,
            ),
            title: l10n.textBold,
            subtitle: l10n.textBoldDetail,
            trailing: AppSwitch(
              value: look.bold,
              onChanged: (bold) => controller.pick(look.copyWith(bold: bold)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A message in the preview chat: the other side's on the page's surface
/// at the start, the user's in jade at the end, each with its time.
class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.time,
    required this.mine,
  });

  final String message;
  final String time;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    const round = Radius.circular(AppRadius.lg);
    const tail = Radius.circular(AppRadius.xs);
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.textPreviewBubble),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mine ? colors.primaryContainer : colors.surface,
            borderRadius: BorderRadiusDirectional.only(
              topStart: mine ? round : tail,
              topEnd: mine ? tail : round,
              bottomStart: round,
              bottomEnd: round,
            ),
            boxShadow: context.elevations.card,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(
                    color: mine
                        ? colors.onPrimaryContainer
                        : colors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: text.labelSmall?.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
