import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_badged.dart';
import 'package:railway_hrms/core/design_system/components/app_button.dart';
import 'package:railway_hrms/core/design_system/components/inset_shadow_painter.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyph_icon.dart';
import 'package:railway_hrms/core/design_system/icons/app_glyphs.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

enum _AvatarStyle { ring, key, soft }

/// A person's initials in a circle, or the [photo] or [emoji] they chose in
/// their place. [AppAvatar.new] sets it on the page inside a jade-to-gold
/// ring, as in a header; [AppAvatar.key] on a raised jade key, as on the
/// profile; [AppAvatar.soft] on a plain tint, as in a list of people. With
/// [onTap] it is a button that a screen reader calls [semanticLabel].
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = AppSizes.headerControl,
    this.onTap,
    this.semanticLabel,
    this.photo,
    this.emoji,
    this.badge,
    this.emojiBackground,
  }) : _style = _AvatarStyle.ring,
       tint = null,
       ring = null;

  const AppAvatar.key({
    super.key,
    required this.name,
    this.size = AppSizes.profileAvatar,
    this.onTap,
    this.semanticLabel,
    this.photo,
    this.emoji,
    this.badge,
    this.emojiBackground,
  }) : _style = _AvatarStyle.key,
       tint = null,
       ring = null;

  const AppAvatar.soft({
    super.key,
    required this.name,
    this.size = AppSizes.avatarSmall,
    this.tint,
    this.ring,
    this.onTap,
    this.semanticLabel,
    this.photo,
    this.emoji,
    this.badge,
    this.emojiBackground,
  }) : _style = _AvatarStyle.soft;

  final String name;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// A photo that fills the circle in place of the initials.
  final ImageProvider? photo;

  /// An emoji in place of the initials, when there is no [photo].
  final String? emoji;

  /// The circle's colour behind an [emoji]; the style's own by default.
  final Color? emojiBackground;

  /// A small jade key on its bottom end corner, showing what a tap does,
  /// such as a camera to change the photo.
  final AppGlyph? badge;

  /// The tint behind a [AppAvatar.soft]'s initials; the muted surface by
  /// default.
  final Color? tint;

  /// A ring around a [AppAvatar.soft], like a status colour; none by
  /// default.
  final Color? ring;
  final _AvatarStyle _style;

  /// Up to two initials from [name]: "Ahmed Raza" is "AR".
  static String initialsOf(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    var avatar = switch (_style) {
      _AvatarStyle.ring => _ringFace(context),
      _AvatarStyle.key => _keyFace(context),
      _AvatarStyle.soft => _softFace(context),
    };
    final badge = this.badge;
    if (badge != null) {
      avatar = SizedBox.square(
        dimension: size,
        child: AppBadged(badge: _badge(context, badge), child: avatar),
      );
    }
    if (onTap == null) return ExcludeSemantics(child: avatar);
    // A full 48dp tap target around the face.
    return Semantics(
      button: true,
      label: semanticLabel,
      // Its own ink, so it works on any surface.
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onTap,
          radius: AppSizes.minTapTarget / 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTapTarget,
              minHeight: AppSizes.minTapTarget,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: ExcludeSemantics(child: avatar),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, AppGlyph glyph) {
    final colors = context.colors;
    final side = size * AppSizes.avatarBadgeShare;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppButton.keyGradient(
          colors.primaryHighlight,
          colors.primary,
          colors.primaryShade,
        ),
        border: Border.all(
          color: colors.surface,
          width: AppSizes.avatarBadgeRing,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: context.elevations.key,
      ),
      child: SizedBox.square(
        dimension: side,
        child: Center(
          child: AppGlyphIcon(
            glyph,
            size: side * 0.52,
            color: colors.onPrimary,
          ),
        ),
      ),
    );
  }

  /// What fills a circle [dimension] wide: the photo, the emoji, or the
  /// initials in [style].
  Widget _initials(TextStyle? style, {double? dimension}) {
    final side = dimension ?? size;
    final photo = this.photo;
    if (photo != null) {
      return ClipOval(
        child: Image(
          image: photo,
          width: side,
          height: side,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          // A photo that has gone missing shows the initials again.
          errorBuilder: (context, _, _) => _letters(style),
        ),
      );
    }
    final emoji = this.emoji;
    if (emoji != null) {
      return Text(
        emoji,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: side * AppSizes.avatarEmojiShare, height: 1),
      );
    }
    return _letters(style);
  }

  Widget _letters(TextStyle? style) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(initialsOf(name), style: style),
  );

  /// Initials sized to the circle they sit in.
  TextStyle? _initialsStyle(BuildContext context) {
    final text = context.textTheme;
    if (size >= AppSizes.avatarLarge) return text.headlineMedium;
    if (size >= AppSizes.avatarMedium) return text.titleSmall;
    return text.bodySmall?.copyWith(fontWeight: AppFonts.semiBold);
  }

  /// The fill behind an emoji, when one shows on its own colour.
  Color? get _emojiFill =>
      photo == null && emoji != null ? emojiBackground : null;

  Widget _softFace(BuildContext context) {
    final colors = context.colors;
    final ring = this.ring;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _emojiFill ?? tint ?? colors.surfaceMuted,
        border: ring == null
            ? null
            : Border.all(
                color: ring,
                width: AppSizes.avatarRing,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: _initials(
            _initialsStyle(context)?.copyWith(color: colors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _ringFace(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.ornamentAccent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.avatarRing),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _emojiFill ?? colors.surface,
          ),
          child: SizedBox.square(
            dimension: size - AppSizes.avatarRing * 2,
            child: Center(
              child: _initials(
                dimension: size - AppSizes.avatarRing * 2,
                size > AppSizes.headerControl
                    ? _initialsStyle(
                        context,
                      )?.copyWith(color: colors.textPrimary)
                    : context.textTheme.labelMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: AppFonts.semiBold,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyFace(BuildContext context) {
    final colors = context.colors;
    final elevations = context.elevations;
    final fill = _emojiFill;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        gradient: fill != null
            ? null
            : AppButton.keyGradient(
                colors.primaryHighlight,
                colors.primary,
                colors.primaryShade,
              ),
        boxShadow: elevations.key,
      ),
      child: CustomPaint(
        painter: InsetShadowPainter(shadows: elevations.keyInset),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: _initials(
              context.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
