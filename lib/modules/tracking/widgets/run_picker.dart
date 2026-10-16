import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';

/// "Today", "Yesterday" or "Sat 11 Oct": the day a run belongs to.
String runDayLabel(LiveTrain run, DateTime now) {
  final day = run.runDate;
  if (day == null) return 'Date unknown';
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (difference == -1) return 'Tomorrow';
  return DateFormat('EEE d MMM').format(day);
}

/// The run's date in full: "Saturday, 11 October".
String runDateLabel(LiveTrain run) {
  final day = run.runDate;
  return day == null ? '—' : DateFormat('EEEE, d MMMM').format(day);
}

/// A small pill naming the day of a run, for telling apart the runs of a
/// train that takes more than a day. Tapping it, when [onTap] is given,
/// offers the other runs.
class RunDateChip extends StatelessWidget {
  const RunDateChip({super.key, required this.run, this.onTap});

  final LiveTrain run;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final chip = Container(
      padding: const EdgeInsets.fromLTRB(7, 2, 5, 2),
      decoration: BoxDecoration(
        color: palette.amberSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 12, color: palette.amber),
          const SizedBox(width: 4),
          Text(
            runDayLabel(run, DateTime.now()),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: palette.amber,
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: palette.amber,
            ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      label: 'Running ${runDateLabel(run)}. Choose another day',
      excludeSemantics: true,
      child: GestureDetector(onTap: onTap, child: chip),
    );
  }
}

/// Asks which day's run of a train to show: a train that takes more than
/// a day is on the line twice at once under one name and number. Each run
/// shows where it is now, so the one wanted is easy to tell. Gives the run
/// picked, or null.
Future<LiveTrain?> showRunPicker(
  BuildContext context, {
  required List<LiveTrain> runs,
  required RealTimeTrackingState state,
  String? currentId,
}) {
  final palette = TrackPalette.of(context);
  return showModalBottomSheet<LiveTrain>(
    context: context,
    backgroundColor: palette.card,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) =>
        _RunPicker(runs: runs, state: state, currentId: currentId),
  );
}

class _RunPicker extends StatelessWidget {
  const _RunPicker({required this.runs, required this.state, this.currentId});

  final List<LiveTrain> runs;
  final RealTimeTrackingState state;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final train = runs.first;
    final now = DateTime.now();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TrainNumberBadge(train: train, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Which day's train?",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${train.displayName} takes more than a day, so '
                        '${runs.length} of its trains are running now.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: palette.mute,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final run in runs) ...[
              _RunCard(
                run: run,
                state: state,
                now: now,
                current: run.id == currentId,
                onTap: () => Navigator.of(context).pop(run),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.run,
    required this.state,
    required this.now,
    required this.current,
    required this.onTap,
  });

  final LiveTrain run;
  final RealTimeTrackingState state;
  final DateTime now;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final position = state.positionOf(run);
    final status = liveStatusOf(
      run,
      position,
      state.linkOf(run),
      now: now,
      palette: palette,
      listeningSince: state.listeningSinceOf(run),
      openedAt: state.openedAtOf(run),
    );
    final place = position?.shortAddress;
    final day = run.runDate;
    return Material(
      color: current ? palette.soft : palette.bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: current ? palette.g2 : palette.line,
              width: current ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.line),
                ),
                child: Column(
                  children: [
                    Text(
                      day == null ? '—' : DateFormat('MMM').format(day),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: palette.red,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      day == null ? '?' : '${day.day}',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: palette.ink,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${runDayLabel(run, now)}'s train",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusPill(status: status),
                    if (place != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Near $place',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.mute,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                current
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: current ? palette.g2 : palette.mute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Says that a train has more than one run on the line, and which days:
/// "2 trains · Today, Yesterday".
class RunCountChip extends StatelessWidget {
  const RunCountChip({super.key, required this.runs});

  final List<LiveTrain> runs;

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: palette.amberSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_rounded, size: 12, color: palette.amber),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${runs.length} trains · '
              '${runs.map((run) => runDayLabel(run, now)).join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: palette.amber,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
