import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';

enum TrainFilter {
  all('All', Icons.apps_rounded),
  moving('Moving', Icons.speed_rounded),
  stopped('Stopped', Icons.pause_circle_filled_rounded),
  up('UP', Icons.north_rounded),
  down('DN', Icons.south_rounded);

  const TrainFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  Color colorIn(TrackPalette palette) => switch (this) {
    TrainFilter.all => palette.g2,
    TrainFilter.moving => palette.g2,
    TrainFilter.stopped => palette.amber,
    TrainFilter.up => palette.g1,
    TrainFilter.down => palette.down,
  };

  bool passes(LiveTrain train, LiveStatus status) => switch (this) {
    TrainFilter.all => true,
    TrainFilter.moving => status.kind == TrainLiveStatus.moving,
    TrainFilter.stopped => status.kind == TrainLiveStatus.stopped,
    TrainFilter.up => train.isUp,
    TrainFilter.down => train.isDown,
  };
}

/// Live status of every train at [now], by train id.
Map<String, LiveStatus> liveStatuses(
  RealTimeTrackingState state,
  DateTime now,
  TrackPalette palette,
) => {
  for (final train in state.trains)
    train.id: liveStatusOf(
      train,
      state.positionOf(train),
      state.linkOf(train),
      now: now,
      palette: palette,
      listeningSince: state.listeningSinceOf(train),
      openedAt: state.openedAtOf(train),
    ),
};

Map<TrainFilter, int> filterCounts(
  List<LiveTrain> trains,
  Map<String, LiveStatus> statuses,
) => {
  for (final filter in TrainFilter.values)
    filter: trains
        .where(
          (t) => statuses[t.id] != null && filter.passes(t, statuses[t.id]!),
        )
        .length,
};

/// The filters as one segmented bar, each with its count, sharing the width
/// so all of them fit without scrolling.
///
/// The chosen one sits on a pill of its colour that runs to the next one
/// picked on a spring, as the bottom bar's selection does: it stretches as
/// it goes, a drop of liquid glass swells over it on the way, and it
/// settles back into a pill with a little wobble, its colour turning to
/// the new filter's.
class TrainFilterBar extends StatefulWidget {
  final TrainFilter selected;
  final Map<TrainFilter, int> counts;
  final ValueChanged<TrainFilter> onSelected;
  final EdgeInsetsGeometry padding;

  const TrainFilterBar({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  State<TrainFilterBar> createState() => _TrainFilterBarState();
}

class _TrainFilterBarState extends State<TrainFilterBar>
    with TickerProviderStateMixin {
  /// The pill's place, in segments from the first.
  late final AnimationController _at = AnimationController.unbounded(
    vsync: this,
    value: widget.selected.index.toDouble(),
  );

  /// How far the pill is lifted into a drop of glass, from 0 to 1.
  late final AnimationController _lift = AnimationController.unbounded(
    vsync: this,
  );

  static const _run = SpringDescription(
    mass: 1,
    stiffness: AppMotion.lensStiffness,
    damping: AppMotion.lensDamping,
  );
  static const _settle = SpringDescription(
    mass: 1,
    stiffness: AppMotion.liftStiffness,
    damping: AppMotion.liftDamping,
  );

  /// How fast the pill must go, in segments a second, to look fully on
  /// the move.
  static const double _motionGain = 0.12;

  @override
  void didUpdateWidget(TrainFilterBar old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final target = widget.selected.index.toDouble();
    if (MediaQuery.disableAnimationsOf(context)) {
      _at.value = target;
      return;
    }
    _at.animateWith(SpringSimulation(_run, _at.value, target, _at.velocity));
    _lift
      ..value = 0
      ..animateTo(
        AppMotion.liftPeek,
        duration: AppMotion.short,
        curve: Curves.easeOut,
      ).whenComplete(() {
        if (!mounted) return;
        _lift.animateWith(
          SpringSimulation(_settle, _lift.value, 0, _lift.velocity),
        );
      });
  }

  @override
  void dispose() {
    _at.dispose();
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    const filters = TrainFilter.values;
    return Padding(
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: palette.shadow(0.8),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_at, _lift]),
          builder: (context, _) {
            final at = _at.value.clamp(0.0, filters.length - 1.0);
            final lift = _lift.value.clamp(0.0, 1.0);
            final motion = (_at.velocity.abs() * _motionGain).clamp(0.0, 1.0);
            // The pill's colour runs from one filter's into the next's.
            final from = filters[at.floor()].colorIn(palette);
            final to = filters[at.ceil()].colorIn(palette);
            final colour = Color.lerp(from, to, at - at.floor())!;
            RRect pill(Size size) {
              final share = size.width / filters.length;
              final rest = Rect.fromLTWH(at * share, 0, share, size.height);
              final shape = liquidShape(rest, motion: motion, lift: lift);
              return RRect.fromRectAndRadius(
                shape.outerRect,
                const Radius.circular(14),
              );
            }

            return AppLiquidGlass(
              amount: math.max(lift, motion * 0.6).clamp(0.0, 1.0),
              lens: pill,
              radius: BorderRadius.circular(14),
              style: LiquidGlassStyle.sheen,
              child: CustomPaint(
                painter: _PillPainter(shape: pill, colour: colour),
                child: Row(
                  children: [
                    for (final filter in filters)
                      Expanded(
                        child: _FilterSegment(
                          filter: filter,
                          count: widget.counts[filter] ?? 0,
                          active: filter == widget.selected,
                          // On the pill, its words are light.
                          onPill: (1 - (at - filter.index).abs()).clamp(
                            0.0,
                            1.0,
                          ),
                          onTap: () => widget.onSelected(filter),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The selection's pill, in [colour], shaded from its top.
class _PillPainter extends CustomPainter {
  const _PillPainter({required this.shape, required this.colour});

  final RRect Function(Size size) shape;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final pill = shape(size);
    canvas
      ..drawRRect(
        pill.shift(const Offset(0, 4)),
        Paint()
          ..color = colour.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawRRect(
        pill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colour,
              Color.lerp(colour, const Color(0xFFFFFFFF), 0.28)!,
            ],
          ).createShader(pill.outerRect),
      );
  }

  @override
  bool shouldRepaint(_PillPainter old) => true;
}

class _FilterSegment extends StatelessWidget {
  final TrainFilter filter;
  final int count;
  final bool active;

  /// How much of the pill is under it, from 0 to 1: its words turn light
  /// as the pill comes.
  final double onPill;
  final VoidCallback onTap;

  const _FilterSegment({
    required this.filter,
    required this.count,
    required this.active,
    required this.onPill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final color = filter.colorIn(palette);
    return Semantics(
      button: true,
      selected: active,
      label: '${filter.label}, $count trains',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          // Large system fonts shrink the text rather than overflow.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 14,
                      color: Color.lerp(color, palette.onAccent, onPill),
                    ),
                    const SizedBox(width: 4),
                    AppRollingNumber(
                      count,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        color: Color.lerp(
                          palette.ink,
                          palette.onAccent,
                          onPill,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  filter.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color.lerp(
                      palette.mute,
                      palette.onAccent.withValues(alpha: 0.92),
                      onPill,
                    ),
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
