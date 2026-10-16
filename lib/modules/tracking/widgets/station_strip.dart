import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:railway_hrms/core/design_system/design_system.dart'
    show AppLoop, AppLoopsMixin;
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart';
import 'package:railway_hrms/modules/tracking/widgets/train_sprite.dart';

/// A train standing this close to a station is at it.
const double _atStationKm = 1.2;

/// The stations along a train's route as a horizontal track, with the train
/// on it and the next station called out above.
class StationStrip extends StatefulWidget {
  final List<RouteStop> stops;

  /// How far the train is along the route; null while unknown.
  final double? coveredKm;
  final TrainPosition? position;

  /// The day the journey began, for placing timetable times.
  final DateTime? runDate;

  const StationStrip({
    super.key,
    required this.stops,
    required this.coveredKm,
    required this.position,
    this.runDate,
  });

  @override
  State<StationStrip> createState() => _StationStripState();
}

/// Where the train is among the stops.
class _Progress {
  /// The first stop still ahead; null once all are behind.
  final int? next;

  /// The stop the train is standing at, if any.
  final int? at;

  const _Progress(this.next, this.at);
}

class _StationStripState extends State<StationStrip> with AppLoopsMixin {
  static const double _itemWidth = 94;

  late final AppLoop _pulse = loop(const Duration(milliseconds: 1800));
  final _scroll = ScrollController();

  /// After the user scrolls the strip, it stops following the train for a
  /// while.
  DateTime? _userScrolledAt;
  int? _followedNext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _follow(force: true));
  }

  @override
  void didUpdateWidget(StationStrip old) {
    super.didUpdateWidget(old);
    final next = _progress.next;
    if (next != _followedNext ||
        (old.coveredKm == null) != (widget.coveredKm == null) ||
        _trainOutOfView) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _follow());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  _Progress get _progress {
    final covered = widget.coveredKm;
    if (covered == null || widget.stops.isEmpty) {
      return const _Progress(null, null);
    }
    var next = nextStopIndex(widget.stops, covered);
    final standing = !(widget.position?.moving ?? true);
    int? at;
    if (standing) {
      // The station just ahead or the one just passed, if close enough.
      for (final i in [?next, (next ?? widget.stops.length) - 1]) {
        if (i >= 0 && (widget.stops[i].km - covered).abs() <= _atStationKm) {
          at = i;
          break;
        }
      }
    }
    // Standing at the next station: the one after it is next.
    if (at != null && at == next) {
      next = at + 1 < widget.stops.length ? at + 1 : null;
    }
    return _Progress(next, at);
  }

  /// The train has run off the part of the strip in view.
  bool get _trainOutOfView {
    if (!_scroll.hasClients) return false;
    final x = _trainX(widget.stops, widget.coveredKm);
    if (x == null) return false;
    final position = _scroll.position;
    return x < position.pixels + 30 ||
        x > position.pixels + position.viewportDimension - 30;
  }

  /// The train's place along the strip, from its left edge.
  double? _trainX(List<RouteStop> stops, double? covered) {
    if (covered == null || stops.isEmpty) return null;
    if (covered <= stops.first.km) return _itemWidth / 2;
    for (var i = 0; i + 1 < stops.length; i++) {
      final a = stops[i].km;
      final b = stops[i + 1].km;
      if (covered < b) {
        final f = b > a ? (covered - a) / (b - a) : 0.0;
        return _itemWidth * (i + 0.5 + f.clamp(0.0, 1.0));
      }
    }
    return _itemWidth * (stops.length - 0.5);
  }

  void _follow({bool force = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final scrolledAt = _userScrolledAt;
    if (!force &&
        scrolledAt != null &&
        DateTime.now().difference(scrolledAt) < const Duration(seconds: 15)) {
      return;
    }
    _followedNext = _progress.next;
    final x = _trainX(widget.stops, widget.coveredKm);
    if (x == null) return;
    final position = _scroll.position;
    final target = (x - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 4) return;
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final stops = widget.stops;
    final progress = _progress;
    final covered = widget.coveredKm;
    final trainX = _trainX(stops, covered);
    final moving = widget.position?.moving ?? false;
    // Timetable times, each on the first day that keeps them in order.
    final scheduled = <DateTime?>[];
    DateTime? lastDue;
    for (final stop in stops) {
      final due = scheduledAt(stop, widget.runDate, after: lastDue);
      scheduled.add(due);
      if (due != null) lastDue = due;
    }
    final timetable = scheduled.any((due) => due != null);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Stations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.soft,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${stops.length}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: palette.g1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: stops.length > 3
                  ? Text(
                      'Swipe to see all',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: palette.mute,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        if (covered != null && stops.isNotEmpty) ...[
          const SizedBox(height: 10),
          _NextStopCard(
            stops: stops,
            progress: progress,
            coveredKm: covered,
            position: widget.position,
          ),
        ],
        const SizedBox(height: 6),
        SizedBox(
          // Name, place or distance, then time, and how late if timetabled.
          height: (timetable ? 172 : 152) + 52 * (textScale - 1),
          child: NotificationListener<UserScrollNotification>(
            onNotification: (_) {
              _userScrolledAt = DateTime.now();
              return false;
            },
            child: ListView.builder(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              itemExtent: _itemWidth,
              itemCount: stops.length,
              itemBuilder: (context, i) => _StopItem(
                stop: stops[i],
                index: i,
                count: stops.length,
                itemWidth: _itemWidth,
                kind: _kindOf(i, progress, covered),
                trainX: trainX,
                trainMoving: moving,
                coveredKm: covered,
                scheduled: scheduled[i],
                pulse: _pulse,
              ),
            ),
          ),
        ),
      ],
    );
  }

  _StopKind _kindOf(int i, _Progress progress, double? covered) {
    if (covered == null) return _StopKind.unknown;
    if (progress.at == i) return _StopKind.at;
    if (progress.next == i) return _StopKind.next;
    final next = progress.next;
    if (next == null || i < next) return _StopKind.passed;
    return _StopKind.ahead;
  }
}

enum _StopKind { unknown, passed, at, next, ahead }

class _NextStopCard extends StatelessWidget {
  final List<RouteStop> stops;
  final _Progress progress;
  final double coveredKm;
  final TrainPosition? position;

  const _NextStopCard({
    required this.stops,
    required this.progress,
    required this.coveredKm,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final p = position;
    final moving = p != null && p.moving;
    final String label;
    final String name;
    final String detail;
    final IconData icon;
    final at = progress.at;
    final next = progress.next;
    if (at != null) {
      label = at == stops.length - 1 ? 'ARRIVED AT' : 'STOPPED AT';
      name = stops[at].station.name;
      final stood = p?.stoppedFor;
      detail = [
        if (stood != null) 'Standing for ${formatDuration(stood)}',
        if (next != null) 'Next: ${stops[next].station.name}',
      ].join(' · ');
      icon = Icons.pause_circle_filled_rounded;
    } else if (next == null) {
      label = 'FINAL STOP';
      name = stops.last.station.name;
      detail = 'Reaching the end of its route';
      icon = Icons.flag_rounded;
    } else {
      label = 'NEXT STATION';
      name = stops[next].station.name;
      final distance = math.max(0.0, stops[next].km - coveredKm);
      // Only what is known: no arrival is guessed.
      detail = [
        '${formatKm(distance)} away',
        if (!moving) 'train stopped',
        if (next > 0) 'after ${stops[next - 1].station.name}',
      ].join(' · ');
      icon = Icons.near_me_rounded;
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.soft, palette.soft.withValues(alpha: 0.4)],
        ),
        border: Border.all(color: palette.g2.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.g1, palette.g3],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.g2.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: palette.onAccent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: palette.g1,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: palette.ink,
                  ),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: palette.mute,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopItem extends StatelessWidget {
  final RouteStop stop;
  final int index;
  final int count;
  final double itemWidth;
  final _StopKind kind;

  /// The train's place along the whole strip; null while unknown.
  final double? trainX;
  final bool trainMoving;
  final double? coveredKm;

  /// When the train should reach this stop, if it is ahead.

  /// When the timetable has it here.
  final DateTime? scheduled;
  final Animation<double> pulse;

  const _StopItem({
    required this.stop,
    required this.index,
    required this.count,
    required this.itemWidth,
    required this.kind,
    required this.trainX,
    required this.trainMoving,
    required this.coveredKm,
    this.scheduled,
    required this.pulse,
  });

  bool get _isFirst => index == 0;
  bool get _isLast => index == count - 1;

  /// FROM, TO, NEXT or HERE above the dot.
  (String, Color, Color)? _badge(TrackPalette palette) => switch (kind) {
    _StopKind.next => ('NEXT', palette.g2, palette.onAccent),
    _StopKind.at => ('HERE', palette.g1, palette.onAccent),
    _ when _isFirst => ('FROM', palette.soft, palette.g1),
    _ when _isLast => ('TO', palette.redSoft, palette.red),
    _ => null,
  };

  /// What the train has done here, or how far it has to go.
  String get _status {
    final covered = coveredKm;
    return switch (kind) {
      _StopKind.unknown => '${stop.km.round()} km',
      _StopKind.passed => _isFirst ? 'Departed' : 'Passed',
      _StopKind.at => 'Train here',
      _StopKind.next || _StopKind.ahead =>
        '${formatKm(math.max(0, stop.km - (covered ?? 0)))} away',
    };
  }

  /// Station arrival / departure time directly from API response.
  (String, String, bool)? get _time {
    final schedArr = stop.station.arrivalTime;
    final schedDep = stop.station.departureTime;
    if (schedArr != null && schedArr.trim().isNotEmpty) {
      return ('ARR', _formatTimeString(schedArr), true);
    }
    if (schedDep != null && schedDep.trim().isNotEmpty) {
      return ('DEP', _formatTimeString(schedDep), true);
    }
    return null;
  }

  static String _formatTimeString(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = parts[1];
      if (h != null) {
        final period = h >= 12 ? 'PM' : 'AM';
        final hour = h % 12 == 0 ? 12 : h % 12;
        return '$hour:$m $period';
      }
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final badge = _badge(palette);
    final passed = kind == _StopKind.passed;
    final highlighted = kind == _StopKind.next || kind == _StopKind.at;
    final left = itemWidth * index;
    // Only the items the train overlaps draw it.
    final drawsTrain =
        trainX != null &&
        trainX! > left - _TrackPainter.trainLength &&
        trainX! < left + itemWidth + _TrackPainter.trainLength;
    return Column(
      children: [
        SizedBox(
          height: 20,
          child: Center(
            child: badge == null
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badge.$1,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: badge.$3,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(
          height: 30,
          width: itemWidth,
          child: CustomPaint(
            painter: _TrackPainter(
              left: left,
              itemWidth: itemWidth,
              isFirst: _isFirst,
              isLast: _isLast,
              kind: kind,
              trainX: drawsTrain ? trainX : null,
              trainMoving: trainMoving,
              pulse: highlighted || drawsTrain ? pulse : null,
              palette: palette,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            stop.station.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: highlighted || stop.scheduled
                  ? FontWeight.w900
                  : FontWeight.w700,
              color: highlighted
                  ? palette.g1
                  : (passed ? palette.mute : palette.ink),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: highlighted ? palette.g2 : palette.grey,
          ),
        ),
        if (_time case (final label, final clock, final expected)) ...[
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: expected ? palette.g2 : palette.grey,
            ),
          ),
          Text(
            clock,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: expected
                  ? palette.g1
                  : (passed ? palette.mute : palette.ink),
            ),
          ),
        ],
      ],
    );
  }
}

/// The track through one stop, its dot, and the train where it overlaps.
class _TrackPainter extends CustomPainter {
  final double left;
  final double itemWidth;
  final bool isFirst;
  final bool isLast;
  final _StopKind kind;

  /// The train's place along the whole strip, when it overlaps this stop.
  final double? trainX;
  final bool trainMoving;
  final Animation<double>? pulse;
  final TrackPalette palette;

  static const double trainLength = 42;

  _TrackPainter({
    required this.left,
    required this.itemWidth,
    required this.isFirst,
    required this.isLast,
    required this.kind,
    required this.trainX,
    required this.trainMoving,
    required this.pulse,
    required this.palette,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final cx = itemWidth / 2;
    final from = isFirst ? cx : 0.0;
    final to = isLast ? cx : itemWidth;
    // The track is green up to the train (or this stop, once passed).
    final greenTo = switch (kind) {
      _StopKind.unknown => from,
      _ =>
        trainX != null
            ? (trainX! - left).clamp(from, to).toDouble()
            : (kind == _StopKind.passed || kind == _StopKind.at ? to : from),
    };
    _rails(canvas, from, greenTo, cy, palette.g2);
    _rails(canvas, greenTo, to, cy, palette.rail);

    final t = pulse?.value ?? 0;
    switch (kind) {
      case _StopKind.passed:
        canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = palette.g2);
        final tick = Path()
          ..moveTo(cx - 3.2, cy + 0.2)
          ..lineTo(cx - 0.8, cy + 2.6)
          ..lineTo(cx + 3.4, cy - 2.4);
        canvas.drawPath(
          tick,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = palette.onAccent,
        );
      case _StopKind.next:
      case _StopKind.at:
        canvas.drawCircle(
          Offset(cx, cy),
          9 + 9 * t,
          Paint()..color = palette.g2.withValues(alpha: 0.35 * (1 - t)),
        );
        canvas.drawCircle(
          Offset(cx, cy),
          9,
          Paint()..color = kind == _StopKind.at ? palette.g1 : palette.card,
        );
        canvas.drawCircle(
          Offset(cx, cy),
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..color = palette.g1,
        );
        if (kind == _StopKind.at) {
          canvas.drawCircle(
            Offset(cx, cy),
            3,
            Paint()..color = palette.onAccent,
          );
        }
      case _StopKind.ahead:
      case _StopKind.unknown:
        final ring = isLast
            ? palette.red
            : (isFirst ? palette.g1 : palette.grey);
        final r = isFirst || isLast ? 8.0 : 6.5;
        canvas.drawCircle(Offset(cx, cy), r, Paint()..color = palette.card);
        canvas.drawCircle(
          Offset(cx, cy),
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isFirst || isLast ? 3 : 2.4
            ..color = ring,
        );
    }

    final x = trainX;
    if (x != null) {
      // Clipped to this stop, so neighbours drawing the rest of it don't
      // draw it twice.
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(0, -size.height, itemWidth, size.height * 3),
      );
      final tx = x - left;
      canvas.drawCircle(
        Offset(tx, cy),
        14 + 8 * t,
        Paint()..color = palette.g2.withValues(alpha: 0.18 * (1 - t)),
      );
      final scale = trainLength / kTrainSpriteSize.height;
      canvas.translate(tx, cy);
      canvas.rotate(math.pi / 2);
      canvas.scale(scale);
      canvas.translate(
        -kTrainSpriteSize.width / 2,
        -kTrainSpriteSize.height / 2,
      );
      paintTrain(canvas, TrainLivery.pakistanRailways, headlights: trainMoving);
      canvas.restore();
    }
  }

  void _rails(Canvas canvas, double from, double to, double cy, Color color) {
    if (to - from < 0.5) return;
    final sleeper = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Sleepers on a grid shared by all stops, so they line up across them.
    final start = ((left + from) / 7).ceil() * 7.0 - left;
    for (var x = start; x < to; x += 7) {
      canvas.drawLine(Offset(x, cy - 4.5), Offset(x, cy + 4.5), sleeper);
    }
    final rail = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(from, cy - 2.6), Offset(to, cy - 2.6), rail);
    canvas.drawLine(Offset(from, cy + 2.6), Offset(to, cy + 2.6), rail);
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.left != left ||
      old.kind != kind ||
      old.trainX != trainX ||
      old.trainMoving != trainMoving ||
      old.isFirst != isFirst ||
      old.isLast != isLast ||
      old.pulse != pulse ||
      old.palette != palette;
}
