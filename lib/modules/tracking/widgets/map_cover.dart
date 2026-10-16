import 'package:flutter/material.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_sprite.dart';

/// Lies over a map while it loads, so the base map's tiles and borders
/// never flash before the app's own layers are on it, and lifts away once
/// they are. If loading drags on it says so and offers to try again.
class MapCover extends StatelessWidget {
  const MapCover({
    super.key,
    required this.visible,
    required this.slow,
    required this.onRetry,
  });

  /// Still loading: the cover shows.
  final bool visible;

  /// Loading is taking long, as on a weak connection.
  final bool slow;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(color: palette.bg),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _RollingTrain(),
                  const SizedBox(height: 18),
                  Text(
                    slow ? 'The map is taking a while' : 'Loading the map…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slow
                        ? 'The connection seems slow. It will appear as soon '
                              'as it loads, or try again.'
                        : 'Live positions are coming in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.mute,
                      height: 1.35,
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: slow
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: FilledButton.icon(
                              onPressed: onRetry,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.g1,
                                foregroundColor: palette.onAccent,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text(
                                'Try again',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
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

/// A train rolling along a short stretch of track, round and round.
class _RollingTrain extends StatefulWidget {
  const _RollingTrain();

  @override
  State<_RollingTrain> createState() => _RollingTrainState();
}

class _RollingTrainState extends State<_RollingTrain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  static const double _width = 168;
  static const double _train = 58;

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return SizedBox(
      width: _width,
      height: 34,
      child: AnimatedBuilder(
        animation: _run,
        builder: (context, _) {
          final x = -_train + (_width + _train) * _run.value;
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _TrackPainter(palette)),
                ),
                Positioned(
                  left: x,
                  top: 0,
                  bottom: 0,
                  child: const Center(
                    child: TrainGlyph(length: _train, headlights: true),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter(this.palette);

  final TrackPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final sleeper = Paint()
      ..color = palette.g2.withValues(alpha: 0.35)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var x = 3.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, cy - 5.5), Offset(x, cy + 5.5), sleeper);
    }
    final rail = Paint()
      ..color = palette.g1.withValues(alpha: 0.6)
      ..strokeWidth = 1.8;
    canvas
      ..drawLine(Offset(0, cy - 3), Offset(size.width, cy - 3), rail)
      ..drawLine(Offset(0, cy + 3), Offset(size.width, cy + 3), rail);
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.palette != palette;
}
