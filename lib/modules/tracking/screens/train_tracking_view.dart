import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/screens/all_trains_map_view.dart';
import 'package:railway_hrms/modules/tracking/screens/train_live_map_view.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/widgets/run_picker.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_filters.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_sprite.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Today's running trains with their live status. Tapping one opens it on
/// the map.
class TrainTrackingView extends StatelessWidget {
  final bool showBackButton;

  /// Use the [RealTimeTrackingCubit] provided above (the Live Trains tabs
  /// share one) instead of creating one.
  final bool useParentCubit;

  const TrainTrackingView({
    super.key,
    this.showBackButton = true,
    this.useParentCubit = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useParentCubit) return _TrainListScreen(showBackButton: showBackButton);
    return BlocProvider(
      create: (_) => sl<RealTimeTrackingCubit>()..initialize(),
      child: _TrainListScreen(showBackButton: showBackButton),
    );
  }
}

class _TrainListScreen extends StatefulWidget {
  final bool showBackButton;

  const _TrainListScreen({required this.showBackButton});

  @override
  State<_TrainListScreen> createState() => _TrainListScreenState();
}

class _TrainListScreenState extends State<_TrainListScreen> {
  late final RealTimeTrackingCubit _cubit = context
      .read<RealTimeTrackingCubit>();
  final _search = TextEditingController();
  String _query = '';
  TrainFilter _filter = TrainFilter.all;
  bool _watching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Every train stays live while the list is on screen (so each card
    // shows its status at once and the status filters work), but not while
    // another tab is selected or a map covers the list.
    _setWatching(
      Visibility.of(context) && TickerMode.valuesOf(context).enabled,
    );
  }

  @override
  void dispose() {
    _setWatching(false);
    _search.dispose();
    super.dispose();
  }

  void _setWatching(bool on) {
    if (on == _watching) return;
    _watching = on;
    on ? _cubit.watchFleet() : _cubit.unwatchFleet();
  }

  void _push(Widget screen) {
    // Unfocus the field itself (not the route's scope, which would refocus
    // it), or the search keyboard reopens when coming back from the map.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: _cubit, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    // Inside the Live Trains tabs the list scrolls under a floating tab bar,
    // which the tabs' Scaffold counts in this padding.
    final bottomInset = 24.0 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BlocBuilder<RealTimeTrackingCubit, RealTimeTrackingState>(
              buildWhen: (a, b) =>
                  a.trains != b.trains || a.isLoading != b.isLoading,
              builder: (context, state) => _Header(
                showBack: widget.showBackButton,
                subtitle: _subtitle(state),
                refreshing: state.isLoading,
                onRefresh: _cubit.loadTrains,
                onMap: () => _push(const AllTrainsMapView()),
              ),
            ),
            _SearchField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: BlocBuilder<RealTimeTrackingCubit, RealTimeTrackingState>(
                buildWhen: (a, b) =>
                    a.trains != b.trains ||
                    a.isLoading != b.isLoading ||
                    a.errorMessage != b.errorMessage ||
                    !identical(a.positions, b.positions) ||
                    !identical(a.links, b.links) ||
                    !identical(a.listeningSince, b.listeningSince),
                builder: (context, state) => TimeTicker(
                  every: const Duration(seconds: 15),
                  builder: (context, now) {
                    final statuses = liveStatuses(
                      state,
                      now,
                      TrackPalette.of(context),
                    );
                    final matching = state.trains
                        .where((t) => t.matches(_query))
                        .toList();
                    final visible = matching
                        .where((t) => _filter.passes(t, statuses[t.id]!))
                        .toList();
                    return Column(
                      children: [
                        TrainFilterBar(
                          selected: _filter,
                          counts: filterCounts(matching, statuses),
                          onSelected: (f) => setState(() => _filter = f),
                        ),
                        Expanded(
                          child: _body(
                            state,
                            visible,
                            statuses,
                            now,
                            bottomInset,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(RealTimeTrackingState state) {
    if (state.trains.isEmpty) {
      return state.isLoading ? "Loading today's trains…" : 'Running today';
    }
    final withGps = state.trains.where((t) => t.hasDevice).length;
    return '${state.trains.length} running today · $withGps with GPS';
  }

  Widget _body(
    RealTimeTrackingState state,
    List<LiveTrain> visible,
    Map<String, LiveStatus> statuses,
    DateTime now,
    double bottomInset,
  ) {
    final palette = TrackPalette.of(context);
    if (state.trains.isEmpty) {
      if (state.isLoading) return _LoadingList(bottomInset: bottomInset);
      if (state.errorMessage != null) {
        return _MessageView(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load trains",
          message: state.errorMessage!,
          actionLabel: 'Try again',
          onAction: _cubit.loadTrains,
        );
      }
      return _MessageView(
        icon: Icons.train_rounded,
        title: 'No trains running today',
        message: 'Pull down or tap refresh to check again.',
        actionLabel: 'Refresh',
        onAction: _cubit.loadTrains,
      );
    }
    if (visible.isEmpty) {
      final waitingForStatus =
          (_filter == TrainFilter.moving || _filter == TrainFilter.stopped) &&
          statuses.values.any(
            (s) =>
                s.kind == TrainLiveStatus.connecting ||
                s.kind == TrainLiveStatus.waiting,
          );
      return _MessageView(
        icon: waitingForStatus
            ? Icons.satellite_alt_rounded
            : Icons.search_off_rounded,
        title: waitingForStatus ? 'Checking the trains…' : 'No matching trains',
        message: waitingForStatus
            ? 'Live positions are coming in from the GPS devices.'
            : 'Try another name, number, station or filter.',
      );
    }
    // A train that takes more than a day runs twice at once: one card for
    // it, showing the run that is live, which asks which day's to show.
    final services = <String, List<LiveTrain>>{};
    for (final train in visible) {
      services.putIfAbsent(train.serviceKey, () => []).add(train);
    }
    final cards = [
      for (final runs in services.values) (_shownRun(runs, statuses), runs),
    ];
    return RefreshIndicator(
      color: palette.g2,
      onRefresh: _cubit.loadTrains,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (train, runs) = cards[i];
          final allRuns = state.runsOf(train);
          return _TrainCard(
            key: ValueKey(train.serviceKey),
            train: train,
            runs: allRuns,
            position: state.positionOf(train),
            status: statuses[train.id]!,
            now: now,
            onTap: () => _open(train, allRuns),
          );
        },
      ),
    );
  }

  /// Of a train's runs, the one its card shows: one that is moving, then
  /// one that is standing, then the latest.
  static LiveTrain _shownRun(
    List<LiveTrain> runs,
    Map<String, LiveStatus> statuses,
  ) {
    int rank(LiveTrain run) => switch (statuses[run.id]?.kind) {
      TrainLiveStatus.moving => 0,
      TrainLiveStatus.stopped => 1,
      TrainLiveStatus.weakGps => 2,
      _ => 3,
    };
    return ([...runs]..sort((a, b) {
          final byStatus = rank(a).compareTo(rank(b));
          return byStatus != 0 ? byStatus : LiveTrain.byLatestRun(a, b);
        }))
        .first;
  }

  /// Opens [train] on the map, asking first which day's run when more than
  /// one is on the line.
  Future<void> _open(LiveTrain train, List<LiveTrain> runs) async {
    var run = train;
    if (runs.length > 1) {
      FocusManager.instance.primaryFocus?.unfocus();
      final picked = await showRunPicker(
        context,
        runs: runs,
        state: _cubit.state,
      );
      if (picked == null || !mounted) return;
      run = picked;
    }
    _push(TrainLiveMapView(train: run));
  }
}

class _Header extends StatelessWidget {
  final bool showBack;
  final String subtitle;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onMap;

  const _Header({
    required this.showBack,
    required this.subtitle,
    required this.refreshing,
    required this.onRefresh,
    required this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          if (showBack) ...[const AppBackButton(), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Trains',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: palette.mute,
                  ),
                ),
              ],
            ),
          ),
          _RoundButton(
            icon: Icons.map_rounded,
            tooltip: 'All trains on the map',
            filled: true,
            onTap: onMap,
          ),
          const SizedBox(width: 10),
          _RoundButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            busy: refreshing,
            onTap: refreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool busy;

  /// Green, for the main action.
  final bool filled;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.busy = false,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? null : palette.card,
            gradient: filled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.g1, palette.g3],
                  )
                : null,
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: palette.g2.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : palette.shadow(0.8),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: palette.g2,
                      ),
                    )
                  : Icon(
                      icon,
                      color: filled ? palette.onAccent : palette.g2,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: palette.shadow(0.7),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search train, number or station',
              hintStyle: TextStyle(color: palette.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: palette.mute),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: palette.mute),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainCard extends StatelessWidget {
  final LiveTrain train;

  /// Every run of the train on the line; more than one for a train that
  /// takes more than a day.
  final List<LiveTrain> runs;
  final TrainPosition? position;
  final LiveStatus status;
  final DateTime now;
  final VoidCallback onTap;

  const _TrainCard({
    super.key,
    required this.train,
    this.runs = const [],
    required this.position,
    required this.status,
    required this.now,
    required this.onTap,
  });

  /// No live report yet while the feed connects or listens: the card's
  /// live part loads.
  static bool _loadingLive(TrainPosition? position, LiveStatus status) =>
      position == null &&
      (status.kind == TrainLiveStatus.connecting ||
          status.kind == TrainLiveStatus.waiting);

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final p = position;
    final tint = trainDirectionColor(train, palette);
    return DecoratedBox(
      decoration: BoxDecoration(
        // White, washing into the lightest tint of the train's badge colour
        // on the right.
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            palette.card,
            palette.card,
            palette.tint(tint, 0.06),
            palette.tint(tint, 0.14),
          ],
          stops: const [0, 0.42, 0.75, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: palette.shadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            splashColor: tint.withValues(alpha: 0.14),
            highlightColor: tint.withValues(alpha: 0.06),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status at a glance, down the card's edge.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          status.color,
                          status.color.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TrainNumberBadge(train: train),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Its name and code, and which way it runs.
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        train.code.isEmpty
                                            ? train.displayName
                                            : '${train.displayName} '
                                                  '${train.code}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: palette.ink,
                                        ),
                                      ),
                                    ),
                                    if (train.isUp || train.isDown) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        train.isUp
                                            ? Icons.north_rounded
                                            : Icons.south_rounded,
                                        size: 15,
                                        color: tint,
                                      ),
                                    ],
                                  ],
                                ),
                                if (runs.length > 1) ...[
                                  const SizedBox(height: 4),
                                  RunCountChip(runs: runs),
                                ],
                                const SizedBox(height: 6),
                                _RouteTrack(
                                  train: train,
                                  position: p,
                                  status: status,
                                ),
                                const SizedBox(height: 10),
                                // Until its first live report, the status
                                // and place shimmer as they load.
                                Skeletonizer(
                                  enabled: _loadingLive(p, status),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      StatusPill(status: status, dense: true),
                                      if (p != null ||
                                          _loadingLive(p, status)) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.place_outlined,
                                              size: 13,
                                              color: palette.mute,
                                            ),
                                            const SizedBox(width: 3),
                                            Expanded(
                                              child: Text(
                                                // Where it is; an offline
                                                // train's old place isn't said
                                                // to be when.
                                                p == null
                                                    // Shown only as its skeleton.
                                                    ? 'Finding where the train is'
                                                    : status.kind ==
                                                          TrainLiveStatus.stale
                                                    ? p.shortAddress ??
                                                          'Location received'
                                                    : '${p.shortAddress ?? 'Location received'} · '
                                                          '${formatAgo(p.fixTime, now)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: palette.mute,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: tint.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// The journey as a short stretch of track between the two station codes,
/// with the train on it and the full names under it.
class _RouteTrack extends StatelessWidget {
  final LiveTrain train;
  final TrainPosition? position;
  final LiveStatus status;

  const _RouteTrack({
    required this.train,
    required this.position,
    required this.status,
  });

  /// How far along the train is, judged by straight-line distances to its
  /// two end stations; null without its position or theirs.
  double? get _progress {
    final from = train.origin?.position;
    final to = train.destination?.position;
    final at = position?.position;
    if (from == null || to == null || at == null) return null;
    final done = haversineMeters(from, at);
    final left = haversineMeters(at, to);
    return done + left == 0 ? null : done / (done + left);
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final names = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: palette.mute,
    );
    if (!train.hasRoute) {
      return Text(
        train.routeLabel,
        style: names.copyWith(fontStyle: FontStyle.italic),
      );
    }
    final code = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w900,
      color: palette.ink,
      letterSpacing: 0.3,
    );
    final from = train.origin;
    final to = train.destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(from?.code ?? '—', style: code),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 16,
                // Without a known place on the line the train waits, faded,
                // at the start.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: _progress ?? 0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                    painter: _MiniRailPainter(
                      color: status.color,
                      ends: TrackPalette.of(context).card,
                      progress: progress,
                      livery:
                          _progress != null &&
                              (status.isLive ||
                                  status.kind == TrainLiveStatus.weakGps)
                          ? TrainLivery.pakistanRailways
                          : TrainLivery.offline,
                      headlights:
                          _progress != null &&
                          status.kind == TrainLiveStatus.moving,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(to?.code ?? '—', style: code),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${from?.name ?? 'Unknown'} → ${to?.name ?? 'Unknown'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: names,
        ),
      ],
    );
  }
}

/// Two rails on sleepers with a station dot at each end, darker up to the
/// train and faint beyond it.
class _MiniRailPainter extends CustomPainter {
  final Color color;
  final double progress;
  final TrainLivery livery;
  final bool headlights;

  /// The rings at the track's ends.
  final Color ends;

  _MiniRailPainter({
    required this.color,
    required this.ends,
    required this.progress,
    required this.livery,
    required this.headlights,
  });

  /// Length of the train drawn on the track.
  static const double _trainLength = 34;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const end = 4.0;
    final half = _trainLength / 2;
    final trainX = (end + half + (size.width - 2 * (end + half)) * progress)
        .clamp(end + half, math.max(end + half, size.width - end - half))
        .toDouble();

    void track(double from, double to, double alpha) {
      if (to <= from) return;
      final sleeper = Paint()
        ..color = color.withValues(alpha: 0.4 * alpha)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var x = from + 3; x < to - 1; x += 6) {
        canvas.drawLine(Offset(x, cy - 4), Offset(x, cy + 4), sleeper);
      }
      final rail = Paint()
        ..color = color.withValues(alpha: 0.85 * alpha)
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(from, cy - 2.2), Offset(to, cy - 2.2), rail);
      canvas.drawLine(Offset(from, cy + 2.2), Offset(to, cy + 2.2), rail);
    }

    track(end, trainX, 1);
    track(trainX, size.width - end, 0.4);
    for (final x in [end, size.width - end]) {
      canvas.drawCircle(Offset(x, cy), end, Paint()..color = ends);
      canvas.drawCircle(
        Offset(x, cy),
        end,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }

    // The train, heading towards the destination on the right.
    final scale = _trainLength / kTrainSpriteSize.height;
    canvas.save();
    canvas.translate(trainX, cy);
    canvas.rotate(math.pi / 2);
    canvas.scale(scale);
    canvas.translate(-kTrainSpriteSize.width / 2, -kTrainSpriteSize.height / 2);
    paintTrain(canvas, livery, headlights: headlights);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MiniRailPainter old) =>
      old.color != color ||
      old.ends != ends ||
      old.progress != progress ||
      old.livery != livery ||
      old.headlights != headlights;
}

class _LoadingList extends StatelessWidget {
  final double bottomInset;

  const _LoadingList({required this.bottomInset});

  static final _placeholder = LiveTrain(
    id: 'placeholder',
    name: 'Rehman Baba Express',
    number: 48,
    direction: 2,
    origin: const TrainStation(name: 'Peshawar Cantt', code: 'PSC'),
    destination: const TrainStation(name: 'Karachi Cantt', code: 'KC'),
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = LiveStatus(
      TrainLiveStatus.connecting,
      'Connecting…',
      TrackPalette.of(context).blue,
      Icons.sync_rounded,
    );
    return Skeletonizer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => _TrainCard(
          train: _placeholder,
          position: null,
          status: status,
          now: now,
          onTap: () {},
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: palette.g2, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.mute,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.g2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
