import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/components/app_avatar.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// A few people's initials overlapping in a row, each on a ring of the
/// surface, with "+N" for the rest: a team at a glance.
class AppAvatarStack extends StatelessWidget {
  const AppAvatarStack({
    super.key,
    required this.names,
    this.shown = 4,
    this.size = AppSizes.avatarMedium,
    this.tints = const [],
  });

  final List<String> names;

  /// How many faces show before "+N".
  final int shown;
  final double size;

  /// The tints behind the faces, in turn; the muted surface by default.
  final List<Color> tints;

  /// How much of each face the next one leaves showing.
  static const double _showing = 0.68;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final faces = names.take(shown).toList();
    final rest = names.length - faces.length;
    // Each face sits on the surface, so the one under it never shows
    // through a see-through tint.
    Widget ringed(Widget face) => DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(color: colors.surface, width: AppSizes.avatarRing),
      ),
      child: face,
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, name) in faces.indexed)
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: index == faces.length - 1 && rest == 0
                  ? 1
                  : _showing,
              child: ringed(
                AppAvatar.soft(
                  name: name,
                  size: size,
                  tint: tints.isEmpty ? null : tints[index % tints.length],
                ),
              ),
            ),
          if (rest > 0)
            ringed(
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.textPrimary,
                ),
                child: SizedBox.square(
                  dimension: size,
                  child: Center(
                    child: Text(
                      '+$rest',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.background,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
