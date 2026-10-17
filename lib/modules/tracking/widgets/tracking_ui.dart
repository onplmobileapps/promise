import 'dart:async';

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

// ─── Palette ──────────────────────────────────────────────────────────────

/// Tracking's colours for light and dark mode, from the design's palette.
/// Read with [TrackPalette.of]; painters take one.
@immutable
class TrackPalette {
  TrackPalette._(AppColors c, {required this.isDark})
    : g1 = c.accentStrong,
      g2 = c.accent,
      g3 = c.primaryShade,
      soft = c.primaryContainer,
      bg = c.background,
      card = c.surface,
      raised = c.surfaceRaised,
      ink = c.textPrimary,
      mute = c.textTertiary,
      line = c.outline,
      rail = c.outlineStrong,
      amber = c.onGoldContainer,
      amberSoft = c.goldContainer,
      grey = c.textTertiary,
      offline = c.offline,
      red = c.onDangerContainer,
      redSoft = c.dangerContainer,
      blue = c.info,
      heat = c.warningMark,
      heatHot = c.danger,
      down = c.onInfoContainer,
      onAccent = c.surface,
      shadowInk = c.shadow,
      halo = c.surface,
      mask = c.shadow;

  static final light = TrackPalette._(AppColors.light, isDark: false);
  static final dark = TrackPalette._(AppColors.dark, isDark: true);

  static TrackPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  final bool isDark;

  /// Deepest green: headings and the UP direction.
  final Color g1;

  /// The green of keys, live marks and the route.
  final Color g2;

  /// The light green of gradients' far ends.
  final Color g3;

  /// The faintest green tint.
  final Color soft;

  /// The page behind the cards.
  final Color bg;

  /// Cards and sheets.
  final Color card;

  /// Buttons floating over a map.
  final Color raised;
  final Color ink;
  final Color mute;
  final Color line;

  /// Track yet to be run.
  final Color rail;
  final Color amber;
  final Color amberSoft;
  final Color grey;

  /// A train gone quiet, on the map and in its status: grey-blue.
  final Color offline;
  final Color red;
  final Color redSoft;
  final Color blue;

  /// A fast and a too-fast speed on the gauge.
  final Color heat;
  final Color heatHot;

  /// The DN direction.
  final Color down;

  /// Text and icons on [g1] and [g2].
  final Color onAccent;
  final Color shadowInk;

  /// Text halos and the ring around marks drawn over a map.
  final Color halo;

  /// The world outside Pakistan on a map.
  final Color mask;

  /// [color] faintly washed into a card.
  Color tint(Color color, double amount) =>
      Color.alphaBlend(color.withValues(alpha: amount), card);

  List<BoxShadow> shadow([double strength = 1]) => [
    BoxShadow(
      color: shadowInk.withValues(alpha: (isDark ? 0.4 : 0.07) * strength),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}

/// "#RRGGBB" for a map style.
String mapHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

// ─── Formatting ───────────────────────────────────────────────────────────
String formatAgo(DateTime time, DateTime now) {
  final d = now.difference(time);
  if (d.inSeconds < 15) return 'just now';
  if (d.inMinutes < 1) return '${d.inSeconds} s ago';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ${d.inMinutes % 60} min ago';
  return '${d.inDays} d ago';
}

String formatDuration(Duration d) {
  if (d.inMinutes < 1) return '<1 min';
  if (d.inHours < 1) return '${d.inMinutes} min';
  if (d.inDays < 1) {
    final m = d.inMinutes % 60;
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m min';
  }
  return '${d.inDays} d ${d.inHours % 24} h';
}

String formatKm(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  if (km < 100) return '${km.round()} km';
  final whole = km.round().toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$grouped km';
}

// ─── Live status ──────────────────────────────────────────────────────────
enum TrainLiveStatus {
  noDevice,
  connecting,
  waiting,
  silent,
  moving,
  stopped,
  weakGps,
  stale,
}

class LiveStatus {
  final TrainLiveStatus kind;
  final String label;
  final Color color;
  final IconData icon;

  const LiveStatus(this.kind, this.label, this.color, this.icon);

  bool get isLive =>
      kind == TrainLiveStatus.moving || kind == TrainLiveStatus.stopped;
}

/// A standing train's device reports about once a minute (two at most,
/// as measured); older than this it has gone quiet.
const Duration kStaleAfter = Duration(minutes: 10);

/// A moving train's device reports every 15 s or so, now and then two and
/// a half minutes apart (as measured); older than this it has gone quiet.
const Duration kStaleWhileMovingAfter = Duration(minutes: 4);

/// After the feed (re)connects, the last report the server kept of a
/// device can be hours old: the device is only taken to be offline once it
/// has had this long to report again.
const Duration kConfirmOfflineAfter = Duration(minutes: 2);

/// The server pushes every 10 s and a moving train reports every 10–20 s,
/// so no report this long after the socket opened means the device is
/// silent.
const Duration kSilentAfter = Duration(seconds: 75);

/// [listeningSince] is when the device's socket first opened, [openedAt]
/// when it last (re)connected; null until it has.
///
/// A train is only called offline when the app is in touch with the
/// server and the device has had time to report: with the phone offline,
/// or the feed just back, its last report says nothing yet.
LiveStatus liveStatusOf(
  LiveTrain train,
  TrainPosition? position,
  LinkState? link, {
  required DateTime now,
  required TrackPalette palette,
  DateTime? listeningSince,
  DateTime? openedAt,
}) {
  if (!train.hasDevice) {
    return LiveStatus(
      TrainLiveStatus.noDevice,
      'No GPS device',
      palette.grey,
      Icons.gps_off_rounded,
    );
  }
  if (position == null) {
    if (listeningSince != null &&
        now.difference(listeningSince) > kSilentAfter) {
      return LiveStatus(
        TrainLiveStatus.silent,
        'No signal yet',
        palette.grey,
        Icons.signal_cellular_off_rounded,
      );
    }
    if (link == LinkState.open) {
      return LiveStatus(
        TrainLiveStatus.waiting,
        'Waiting for location…',
        palette.blue,
        Icons.satellite_alt_rounded,
      );
    }
    return LiveStatus(
      TrainLiveStatus.connecting,
      'Connecting…',
      palette.blue,
      Icons.sync_rounded,
    );
  }
  final age = now.difference(position.fixTime);
  // The live feed says whether the device is online: taken as it says.
  if (position.online == false) {
    return LiveStatus(
      TrainLiveStatus.stale,
      'Offline',
      palette.grey,
      Icons.cloud_off_rounded,
    );
  }
  // Only where it doesn't say, the report's age tells.
  if (position.online == null &&
      age > (position.moving ? kStaleWhileMovingAfter : kStaleAfter)) {
    // Out of touch with the server: the device may be reporting.
    if (link != null && link != LinkState.open) {
      return LiveStatus(
        TrainLiveStatus.connecting,
        'Reconnecting…',
        palette.blue,
        Icons.sync_rounded,
      );
    }
    // Just back in touch, with only the report the server kept.
    if (openedAt != null &&
        now.difference(openedAt) < kConfirmOfflineAfter &&
        position.fixTime.isBefore(openedAt)) {
      return LiveStatus(
        TrainLiveStatus.waiting,
        'Updating…',
        palette.blue,
        Icons.satellite_alt_rounded,
      );
    }
    return LiveStatus(
      TrainLiveStatus.stale,
      // Its device has gone quiet: no live position to show.
      'Offline',
      palette.offline,
      Icons.cloud_off_rounded,
    );
  }
  if (!position.validFix) {
    return LiveStatus(
      TrainLiveStatus.weakGps,
      'Weak GPS signal',
      palette.amber,
      Icons.gps_not_fixed_rounded,
    );
  }
  if (position.moving) {
    return LiveStatus(
      TrainLiveStatus.moving,
      'Moving · ${position.speedKmh.round()} km/h',
      palette.g2,
      Icons.trending_flat_rounded,
    );
  }
  // The device reports how long it had stood at the time of the report.
  final stoppedFor = position.stoppedFor;
  final stopped = stoppedFor == null
      ? null
      : stoppedFor + (age.isNegative ? Duration.zero : age);
  return LiveStatus(
    TrainLiveStatus.stopped,
    stopped == null ? 'Stopped' : 'Stopped · ${formatDuration(stopped)}',
    palette.amber,
    Icons.pause_circle_filled_rounded,
  );
}

// ─── Widgets ──────────────────────────────────────────────────────────────

/// Rebuilds [builder] every [every], for "12 s ago" style text.
class TimeTicker extends StatefulWidget {
  final Duration every;
  final Widget Function(BuildContext context, DateTime now) builder;

  const TimeTicker({
    super.key,
    this.every = const Duration(seconds: 10),
    required this.builder,
  });

  @override
  State<TimeTicker> createState() => _TimeTickerState();
}

class _TimeTickerState extends State<TimeTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.every, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// A train's direction colour: green for UP, blue for DN.
Color trainDirectionColor(LiveTrain train, TrackPalette palette) => train.isDown
    ? palette.down
    : train.isUp
    ? palette.g1
    : palette.mute;

/// Train number with its direction, on the lightest tint of the direction's
/// colour, with a train icon when there is room.
class TrainNumberBadge extends StatelessWidget {
  final LiveTrain train;
  final double size;

  const TrainNumberBadge({super.key, required this.train, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final color = trainDirectionColor(train, palette);
    final withIcon = size >= 46;
    final number = train.number?.toString() ?? '—';
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.tint(color, 0.08), palette.tint(color, 0.18)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (withIcon)
              Icon(Icons.train_rounded, size: size * 0.27, color: color),
            Text(
              number,
              style: TextStyle(
                color: Color.lerp(color, palette.ink, 0.3),
                fontWeight: FontWeight.w900,
                fontSize: size * (withIcon ? 0.3 : 0.36),
                height: 1.05,
              ),
            ),
            if (train.directionLabel.isNotEmpty)
              Text(
                train.directionLabel,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.16,
                  letterSpacing: 1,
                  height: 1.2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final LiveStatus status;
  final bool dense;

  const StatusPill({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveDot(
            color: status.color,
            pulsing: status.isLive,
            size: dense ? 7 : 8,
          ),
          SizedBox(width: dense ? 5 : 6),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontWeight: FontWeight.w800,
                fontSize: dense ? 11.5 : 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDot extends StatefulWidget {
  final Color color;
  final bool pulsing;
  final double size;

  const LiveDot({
    super.key,
    required this.color,
    this.pulsing = false,
    this.size = 8,
  });

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with AppLoopsMixin {
  // A dot in every card of a list pulses: on a loop, not every frame.
  late final AppLoop _pulse = loop(
    const Duration(milliseconds: 1600),
    running: widget.pulsing,
  );

  @override
  void didUpdateWidget(LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing) {
      _pulse.start();
    } else {
      _pulse.stop(at: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: widget.pulsing
              ? [
                  BoxShadow(
                    color: widget.color.withValues(
                      alpha: 0.45 * (1 - _pulse.value),
                    ),
                    spreadRadius: widget.size * 0.9 * _pulse.value,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// Round button floating over a map.
class MapIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const MapIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? palette.g2 : palette.raised,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: palette.shadow(1.4),
            ),
            child: Icon(
              icon,
              color: active ? palette.onAccent : palette.g2,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
