import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/profile/emoji_catalog.dart';
import 'package:railway_hrms/core/profile/profile_face.dart';

/// An emoji avatar: the emoji and the colour behind it.
typedef EmojiAvatar = ({String emoji, AvatarTint tint});

/// Lets the user make an emoji avatar: every emoji WhatsApp offers, by
/// group, on a colour of their choice, seen on the avatar as they pick.
/// Gives back what they kept, or null if they closed the sheet. [name]'s
/// initials stand in until an emoji is picked; [initial] is the avatar
/// they have now, if it is an emoji.
Future<EmojiAvatar?> showEmojiPicker(
  BuildContext context, {
  required String name,
  EmojiAvatar? initial,
}) {
  final l10n = context.l10n;
  return showAppSheet<EmojiAvatar>(
    context: context,
    title: l10n.emojiPickerTitle,
    closeLabel: l10n.actionClose,
    builder: (context) => _EmojiPicker(name: name, initial: initial),
  );
}

/// A group of the picker: its key in [emojiByGroup], its icon, its name.
typedef _Group = (
  String key,
  AppGlyph glyph,
  String Function(AppLocalizations),
);

class _EmojiPicker extends StatefulWidget {
  const _EmojiPicker({required this.name, this.initial});

  final String name;
  final EmojiAvatar? initial;

  static final List<_Group> groups = [
    ('smileys', AppGlyphs.smile, (l) => l.emojiGroupSmileys),
    ('animals', AppGlyphs.paw, (l) => l.emojiGroupAnimals),
    ('food', AppGlyphs.cup, (l) => l.emojiGroupFood),
    ('activities', AppGlyphs.trophy, (l) => l.emojiGroupActivities),
    ('travel', AppGlyphs.car, (l) => l.emojiGroupTravel),
    ('objects', AppGlyphs.lightbulb, (l) => l.emojiGroupObjects),
    ('symbols', AppGlyphs.heart, (l) => l.emojiGroupSymbols),
    ('flags', AppGlyphs.flag, (l) => l.emojiGroupFlags),
  ];

  @override
  State<_EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<_EmojiPicker>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: _EmojiPicker.groups.length,
    vsync: this,
  );
  late String? _emoji = widget.initial?.emoji;
  late AvatarTint _tint = widget.initial?.tint ?? AvatarTint.jade;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _tintName(AppLocalizations l10n, AvatarTint tint) => switch (tint) {
    AvatarTint.jade => l10n.avatarTintJade,
    AvatarTint.gold => l10n.avatarTintGold,
    AvatarTint.sky => l10n.avatarTintSky,
    AvatarTint.rose => l10n.avatarTintRose,
    AvatarTint.sand => l10n.avatarTintSand,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final emoji = _emoji;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * AppSizes.emojiSheetShare,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                // The avatar as it will be, springing in at each change.
                AnimatedSwitcher(
                  duration: AppMotion.medium,
                  switchInCurve: AppMotion.spring,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: AppAvatar.key(
                    key: ValueKey((emoji, _tint)),
                    name: widget.name,
                    size: AppSizes.emojiPreview,
                    emoji: emoji,
                    emojiBackground: _tint.colorIn(colors),
                  ),
                ),
                AppSpacing.gapLg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emoji == null
                            ? l10n.emojiPickPrompt
                            : l10n.emojiBackground,
                        style: text.labelMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapSm,
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final tint in AvatarTint.values)
                            _Swatch(
                              color: tint.colorIn(colors),
                              label: _tintName(l10n, tint),
                              selected: tint == _tint,
                              onTap: () => setState(() => _tint = tint),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppSegmentedTabs(
              controller: _tabs,
              segments: [
                for (final (_, glyph, name) in _EmojiPicker.groups)
                  AppSegment.icon(label: name(l10n), glyph: glyph),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final (key, _, _) in _EmojiPicker.groups)
                  _EmojiGrid(
                    emoji: emojiByGroup[key]!.split(' '),
                    picked: emoji,
                    onPick: (each) => setState(() => _emoji = each),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: AppButton(
              label: l10n.emojiUse,
              trailingGlyph: AppGlyphs.check,
              onPressed: emoji == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop<EmojiAvatar>((emoji: emoji, tint: _tint)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A colour an emoji avatar can sit on; ringed in jade when picked.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: LiquidPop(
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.short,
            width: AppSizes.emojiSwatch,
            height: AppSizes.emojiSwatch,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected ? colors.primary : colors.outline,
                width: selected ? AppSizes.emojiSwatchRing : 1,
              ),
            ),
            child: selected
                ? Center(
                    child: AppGlyphIcon(
                      AppGlyphs.check,
                      size: AppSizes.iconXs,
                      color: colors.primary,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({
    required this.emoji,
    required this.picked,
    required this.onPick,
  });

  final List<String> emoji;
  final String? picked;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: AppSizes.emojiCell,
      ),
      itemCount: emoji.length,
      itemBuilder: (context, index) {
        final each = emoji[index];
        final selected = each == picked;
        return Semantics(
          button: true,
          selected: selected,
          label: each,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onPick(each),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: LiquidPop(
                selected: selected,
                radius: AppRadius.borderMd,
                child: AnimatedContainer(
                  duration: AppMotion.short,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.borderMd,
                    color: selected
                        ? colors.primaryContainer
                        : colors.primaryContainer.withValues(alpha: 0),
                    border: Border.all(
                      color: selected
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0),
                      width: AppSizes.emojiSwatchRing,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    each,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(fontSize: AppSizes.emojiGlyph),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
