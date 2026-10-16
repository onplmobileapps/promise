import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';

/// The credit line at the foot of the splash and sign-in screens: "Powered
/// by" and the company's logo, in colour on a light page and in white on a
/// dark one, on a small pill raised in 3D: lit from above with a gloss
/// along its top, edged in the brand's jade and standing on a soft shadow.
class PoweredByBadge extends StatelessWidget {
  const PoweredByBadge({super.key, required this.label});

  /// What a screen reader says.
  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface,
              colors.surfaceRaised,
              colors.surfaceRaisedEnd,
            ],
            stops: const [0, 0.5, 1],
          ),
          borderRadius: AppRadius.borderPill,
          boxShadow: [
            ...context.elevations.raised,
            BoxShadow(
              color: colors.accentStrong.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: CustomPaint(
          painter: InsetShadowPainter(
            shape: const StadiumBorder(),
            shadows: context.elevations.raisedInset,
          ),
          // Over the inner light, so the edge is even all round.
          foregroundPainter: AppEdgePainter(
            colour: colors.primaryEdge.withValues(alpha: 0.6),
            shape: const StadiumBorder(),
            width: 1.2,
          ),
          child: CustomPaint(
            // Under the words and the logo, so they stay crisp.
            painter: _Gloss(colors.surface),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs + AppSpacing.xxs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      l10n.poweredByLead,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: AppFonts.semiBold,
                      ),
                    ),
                  ),
                  AppSpacing.gapSm,
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/darklogo.png'
                        : 'assets/logolight.png',
                    height: AppSizes.poweredByLogo,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A gloss across the top half of the pill, where the light falls.
class _Gloss extends CustomPainter {
  const _Gloss(this.light);

  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final pill = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final top = Rect.fromLTWH(2, 1.5, size.width - 4, size.height * 0.48);
    canvas
      ..save()
      ..clipRRect(pill)
      ..drawRRect(
        RRect.fromRectAndRadius(top, Radius.circular(top.height / 2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light.withValues(alpha: 0.85), light.withValues(alpha: 0)],
          ).createShader(top),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_Gloss old) => old.light != light;
}

/// The foot of the splash and sign-in screens: who designed and developed
/// the app, on its badge, and the copyright under it, for this year.
class CreditsFooter extends StatelessWidget {
  const CreditsFooter({super.key, this.now});

  /// Today, to take the year from; the clock's by default.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final year = (now ?? DateTime.now()).year;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The badge between two hairlines fading out to the sides. The
        // badge takes what it needs, up to most of the row, and the lines
        // share the rest evenly, so it sits in the middle.
        LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              const Expanded(child: _Hairline(fadesLeft: true)),
              AppSpacing.gapMd,
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * 0.8),
                child: PoweredByBadge(label: l10n.poweredBy),
              ),
              AppSpacing.gapMd,
              const Expanded(child: _Hairline(fadesLeft: false)),
            ],
          ),
        ),
        AppSpacing.gapSm,
        Text(
          l10n.copyrightNotice(year),
          textAlign: TextAlign.center,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// A hairline beside the credit, fading out away from it.
class _Hairline extends StatelessWidget {
  const _Hairline({required this.fadesLeft});

  final bool fadesLeft;

  @override
  Widget build(BuildContext context) {
    final line = context.colors.outlineStrong;
    final colours = [line.withValues(alpha: 0), line];
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: fadesLeft ? colours : colours.reversed.toList(),
        ),
      ),
    );
  }
}
