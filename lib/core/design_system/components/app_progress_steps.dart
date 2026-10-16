import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/foundations/app_fonts.dart';
import 'package:railway_hrms/core/design_system/foundations/app_sizes.dart';
import 'package:railway_hrms/core/design_system/foundations/app_spacing.dart';
import 'package:railway_hrms/core/design_system/theme/theme_context.dart';

/// Progress along a fixed path, like an accident case from report to clear.
/// The steps done are jade dots on a jade line, the [current] one a gold dot
/// in a halo, and the rest hollow on a dashed line. Each label sits under
/// its dot.
class AppProgressSteps extends StatelessWidget {
  const AppProgressSteps({
    super.key,
    required this.steps,
    required this.current,
    this.semanticLabel,
  });

  final List<String> steps;

  /// The step under way, counted from zero.
  final int current;

  /// What a screen reader says, such as "Step 3 of 4: Relief".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    assert(steps.length > 1, 'A path needs at least two steps.');
    final colors = context.colors;
    final text = context.textTheme;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: AppSizes.stepDotCurrent + AppSizes.stepHalo * 2,
              child: CustomPaint(
                painter: _StepsPainter(
                  count: steps.length,
                  current: current,
                  done: colors.primaryShade,
                  now: colors.ornamentAccent,
                  halo: colors.goldContainer,
                  ahead: colors.outlineStrong,
                ),
              ),
            ),
            AppSpacing.gapXs,
            Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  // Each label keeps to its share, shrinking rather than
                  // cutting a long word.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: i == 0
                          ? AlignmentDirectional.centerStart
                          : i == steps.length - 1
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.center,
                      child: Text(
                        steps[i].toUpperCase(),
                        maxLines: 1,
                        style: text.labelSmall?.copyWith(
                          fontSize: AppFonts.stepLabelSize,
                          letterSpacing: AppFonts.tagLetterSpacing,
                          color: i == current
                              ? colors.onGoldContainer
                              : colors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepsPainter extends CustomPainter {
  const _StepsPainter({
    required this.count,
    required this.current,
    required this.done,
    required this.now,
    required this.halo,
    required this.ahead,
  });

  final int count;
  final int current;
  final Color done;
  final Color now;
  final Color halo;
  final Color ahead;

  /// Dashes of the line still to go, and the gaps between them.
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final edge = AppSizes.stepDotCurrent / 2 + AppSizes.stepHalo;
    final span = size.width - edge * 2;
    double xOf(int i) => edge + span * i / (count - 1);
    final line = Paint()..strokeWidth = AppSizes.stepLine;
    for (var i = 0; i < count - 1; i++) {
      final from = xOf(i);
      final to = xOf(i + 1);
      if (i < current) {
        canvas.drawLine(Offset(from, y), Offset(to, y), line..color = done);
      } else {
        line.color = ahead;
        for (var x = from; x < to; x += _dash + _gap) {
          canvas.drawLine(
            Offset(x, y),
            Offset((x + _dash).clamp(from, to), y),
            line,
          );
        }
      }
    }
    for (var i = 0; i < count; i++) {
      final at = Offset(xOf(i), y);
      if (i < current) {
        canvas.drawCircle(at, AppSizes.stepDot / 2, Paint()..color = done);
      } else if (i == current) {
        canvas
          ..drawCircle(
            at,
            AppSizes.stepDotCurrent / 2 + AppSizes.stepHalo,
            Paint()..color = halo,
          )
          ..drawCircle(at, AppSizes.stepDotCurrent / 2, Paint()..color = now);
      } else {
        canvas.drawCircle(
          at,
          AppSizes.stepDot / 2 - AppSizes.stepLine / 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = AppSizes.stepLine
            ..color = ahead,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StepsPainter old) =>
      old.count != count ||
      old.current != current ||
      old.done != done ||
      old.now != now ||
      old.halo != halo ||
      old.ahead != ahead;
}
