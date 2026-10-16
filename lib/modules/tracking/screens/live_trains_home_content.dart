import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:railway_hrms/core/design_system/design_system.dart'
    show AppLoop, AppLoopsMixin;
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_cubit.dart';
import 'package:railway_hrms/modules/tracking/bloc/real_time_tracking_state.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/screens/all_trains_map_view.dart';
import 'package:railway_hrms/modules/tracking/screens/train_tracking_view.dart';
import 'package:railway_hrms/modules/tracking/services/pakistan_outline.dart';
import 'package:railway_hrms/modules/tracking/services/rail_router.dart';
import 'package:railway_hrms/modules/tracking/widgets/tracking_ui.dart'
    show TrackPalette, kStaleAfter;

/// Pakistan Railways livery for the little trains.
const _locoGreen = Color(0xFF1F7A4D);
const _livery = Color(0xFFF2C94C);

class LiveTrainsHomeContent extends StatefulWidget {
  const LiveTrainsHomeContent({super.key});

  @override
  State<LiveTrainsHomeContent> createState() => _LiveTrainsHomeContentState();
}

class _LiveTrainsHomeContentState extends State<LiveTrainsHomeContent>
    with TickerProviderStateMixin, AppLoopsMixin {
  late AnimationController _entranceController;

  /// One long loop: each train's run divides it, so none jumps when it
  /// restarts. Drawn on a loop, not every frame.
  late final AppLoop _trains = loop(
    const Duration(seconds: _TrainsPainter.loopSeconds),
  );

  /// Every train's live position is listened to from here, so the map card
  /// shows them moving and the full map has them as soon as it opens.
  late final RealTimeTrackingCubit _tracking = context
      .read<RealTimeTrackingCubit>();

  @override
  void initState() {
    super.initState();
    _tracking.watchFleet();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _tracking.unwatchFleet();
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _entrance(
    double start,
    double end, {
    Curve curve = Curves.easeOut,
  }) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: curve),
    );
  }

  /// How far the Quick Access sheet rides up over the hero.
  static const double _sheetOverlap = 34;

  /// Opens [screen] over this page, sharing its tracking cubit.
  void _push(Widget screen) {
    final cubit = context.read<RealTimeTrackingCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(value: cubit, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final palette = TrackPalette.of(context);
    // The page fills the screen: the hero on top, the cards down to the
    // bottom. On short screens it scrolls instead.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: palette.bg,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Tall enough for the title and button even with large text.
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final minHero = 240 + 90 * textScale + media.padding.top;
            final heroHeight = math.min(
              math.max(constraints.maxHeight * 0.48, minHero),
              600.0,
            );
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  // One column, so the sheet paints over the hero's edge (a
                  // viewport paints its first sliver last). The hero's fixed
                  // height also spares its LayoutBuilder from being measured.
                  child: Column(
                    children: [
                      // The hero's tracks run on past its sides so trains
                      // roll in and out of view; clipped, so they never
                      // show over the page beside it as this one slides.
                      SizedBox(
                        height: heroHeight,
                        child: ClipRect(child: _buildHero()),
                      ),
                      Expanded(
                        child: _buildSheet(
                          bottomInset: math.max(
                            16,
                            media.padding.bottom + 16 - _sheetOverlap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero() {
    final palette = TrackPalette.of(context);
    return Stack(
      children: [
        // Soft mint, lighter towards the sheet, with a glow behind the
        // radar.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.tint(palette.g2, 0.22),
                  palette.tint(palette.g2, 0.1),
                  palette.bg,
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.35),
                radius: 0.75,
                colors: [
                  palette.card.withValues(alpha: palette.isDark ? 0.25 : 0.6),
                  palette.card.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        // Static backdrop: dots, grid, skyline and the rail tracks.
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BackdropPainter(
                TrackPalette.of(context),
                bottomInset: _sheetOverlap,
              ),
            ),
          ),
        ),
        // Trains running on the tracks, and stations along them.
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _trains,
              builder: (context, _) => CustomPaint(
                painter: _TrainsPainter(
                  _trains.value * _TrainsPainter.loopSeconds,
                  TrackPalette.of(context),
                  bottomInset: _sheetOverlap,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Short heroes shrink the title, and only tall ones repeat
              // today's counts from the Network card.
              final compact = constraints.maxHeight < 360;
              final showCounts = constraints.maxHeight >= 520;
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  _sheetOverlap + (compact ? 18 : 28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedEntrance(
                      animation: _entrance(0.0, 0.33),
                      child: _buildHeader(context),
                    ),
                    // The radar fills the space between the header and the
                    // title, centred in it.
                    Expanded(
                      child: _AnimatedEntrance(
                        animation: _entrance(0.05, 0.5),
                        slideOffset: 0,
                        child: const Center(child: _Radar()),
                      ),
                    ),
                    _AnimatedEntrance(
                      animation: _entrance(0.08, 0.47),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Live\n'),
                            TextSpan(
                              text: 'Tracking',
                              style: TextStyle(color: palette.g1),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: compact ? 34 : 42,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    _AnimatedEntrance(
                      animation: _entrance(0.15, 0.54),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: compact ? 8 : 12,
                          bottom: compact ? 12 : 14,
                        ),
                        child: const _Tagline(),
                      ),
                    ),
                    if (showCounts)
                      _AnimatedEntrance(
                        animation: _entrance(0.18, 0.58),
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _TodayCounts(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The cards, riding up over the hero's bottom edge and filling the rest
  /// of the page. No LayoutBuilder below here: the page measures this
  /// to decide whether it has to scroll.
  Widget _buildSheet({required double bottomInset}) {
    final palette = TrackPalette.of(context);
    return Transform.translate(
      offset: const Offset(0, -_sheetOverlap),
      child: _AnimatedEntrance(
        animation: _entrance(
          0.11,
          0.61,
          curve: const Cubic(0.2, 0.9, 0.25, 1.0),
        ),
        slideOffset: 120,
        child: Container(
          padding: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(36),
              topRight: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.shadowInk.withValues(
                  alpha: palette.isDark ? 0.4 : 0.12,
                ),
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _AnimatedEntrance(
                          animation: _entrance(0.4, 0.8),
                          curve: const Cubic(0.3, 1.3, 0.5, 1.0),
                          child: _FleetMapCard(
                            onTap: () => _push(const AllTrainsMapView()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedEntrance(
                        animation: _entrance(0.48, 0.9),
                        curve: const Cubic(0.3, 1.3, 0.5, 1.0),
                        child: _NetworkCard(
                          onTap: () => _push(
                            const TrainTrackingView(useParentCubit: true),
                          ),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: palette.line),
              boxShadow: [
                BoxShadow(
                  color: palette.g1.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_left_rounded,
              color: palette.ink,
              size: 24,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: palette.line),
            boxShadow: [
              BoxShadow(
                color: palette.g1.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 8),
              Text(
                'LIVE TRACKER',
                style: TextStyle(
                  color: palette.g1,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The hero's tagline on a white pill.
class _Tagline extends StatelessWidget {
  const _Tagline();

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.line),
        boxShadow: [
          BoxShadow(
            color: palette.g1.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [palette.g2, palette.g1]),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gps_fixed_rounded,
              color: palette.onAccent,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Instant Locomotive Positioning',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick access ─────────────────────────────────────────────────────────

/// Shrinks slightly while pressed.
class _Pressable extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Today's trains at a glance, from the tracking API; opens their list.
class _NetworkCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NetworkCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return _Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.card,
              palette.tint(palette.g2, 0.04),
              palette.tint(palette.g2, 0.1),
            ],
          ),
          border: Border.all(color: palette.line),
          boxShadow: [
            BoxShadow(
              color: palette.g1.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          // Faint track crossing the card, behind everything.
          painter: _CardRailsPainter(TrackPalette.of(context)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child:
                BlocSelector<
                  RealTimeTrackingCubit,
                  RealTimeTrackingState,
                  (int, int, int, int, bool)
                >(
                  selector: (s) => (
                    s.trains.length,
                    s.reportingCount(DateTime.now()),
                    s.trains.where((t) => t.isUp).length,
                    s.trains.where((t) => t.isDown).length,
                    s.isLoading && s.trains.isEmpty,
                  ),
                  builder: (context, data) {
                    final (running, tracked, up, down, loading) = data;
                    final share = running == 0 ? 0.0 : tracked / running;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: palette.soft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: palette.line),
                              ),
                              child: Icon(
                                Icons.format_list_bulleted_rounded,
                                color: palette.g1,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Trains',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Every train running today',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: palette.mute,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [palette.g2, palette.g1],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.g1.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: palette.onAccent,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBlock(
                                value: running,
                                loading: loading,
                                label: 'Running today',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: palette.line,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatBlock(
                                value: tracked,
                                loading: loading,
                                label: 'Live on GPS',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _DirectionChip(
                                  icon: Icons.north_rounded,
                                  label: loading ? 'Up' : '$up Up',
                                ),
                                const SizedBox(height: 6),
                                _DirectionChip(
                                  icon: Icons.south_rounded,
                                  label: loading ? 'Down' : '$down Down',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: share),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, _) =>
                                      LinearProgressIndicator(
                                        value: v,
                                        minHeight: 7,
                                        backgroundColor: palette.soft,
                                        valueColor: AlwaysStoppedAnimation(
                                          palette.g2,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              loading
                                  ? 'Loading…'
                                  : '${(share * 100).round()}% tracked live',
                              style: TextStyle(
                                color: palette.g1,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final int value;
  final bool loading;
  final String label;

  const _StatBlock({
    required this.value,
    required this.loading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final style = TextStyle(
      color: palette.ink,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: -0.8,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loading)
          Text('—', style: style)
        else
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text('${v.round()}', style: style),
          ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: palette.mute,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DirectionChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 11, 5),
      decoration: BoxDecoration(
        color: palette.soft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.g1),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: palette.g1,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// A railway track sweeping across the card at low opacity.
class _CardRailsPainter extends CustomPainter {
  final TrackPalette palette;

  const _CardRailsPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.35, size.height + 10)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.62,
        size.width * 0.8,
        size.height * 0.5,
        size.width + 12,
        size.height * 0.08,
      );
    _drawRailTrack(canvas, path, 0.12, color: palette.g1);
  }

  @override
  bool shouldRepaint(_CardRailsPainter old) => old.palette != palette;
}

/// Opens the map of every train. Pakistan fills the card — railways,
/// stations and any trains already located — with the title in the empty
/// north-west corner and the way in at the empty south-east one.
class _FleetMapCard extends StatefulWidget {
  final VoidCallback onTap;

  const _FleetMapCard({required this.onTap});

  @override
  State<_FleetMapCard> createState() => _FleetMapCardState();
}

class _FleetMapCardState extends State<_FleetMapCard> with AppLoopsMixin {
  late final AppLoop _pulse = loop(const Duration(milliseconds: 2600));
  final Future<PakistanOutline> _outline = PakistanOutline.load();
  final Future<List<List<LatLng>>?> _network = RailRouter.instance.network(
    toleranceM: 250,
  );

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    final mint = palette.g2;
    return _Pressable(
      onTap: widget.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.card,
              palette.tint(palette.g2, 0.05),
              palette.tint(palette.g2, 0.12),
            ],
          ),
          border: Border.all(color: palette.line),
          boxShadow: [
            BoxShadow(
              color: palette.g1.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              // Loaded once for the app, so a card built again, as when
              // coming back to it, draws its map on the first frame.
              child: FutureBuilder<PakistanOutline>(
                future: _outline,
                initialData: PakistanOutline.loaded,
                builder: (context, outline) =>
                    FutureBuilder<List<List<LatLng>>?>(
                      future: _network,
                      initialData: RailRouter.instance.loadedNetwork(
                        toleranceM: 250,
                      ),
                      builder: (context, network) =>
                          BlocSelector<
                            RealTimeTrackingCubit,
                            RealTimeTrackingState,
                            (List<LiveTrain>, List<TrainStation>)
                          >(
                            selector: (s) => (s.trains, s.stations),
                            builder: (context, data) {
                              final shape = outline.data;
                              if (shape == null) return const SizedBox.shrink();
                              final art = _MapArt(
                                shape,
                                network.data,
                                data.$1,
                                data.$2,
                              );
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        painter: _MapArtPainter(
                                          art,
                                          TrackPalette.of(context),
                                        ),
                                        isComplex: true,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child:
                                          BlocSelector<
                                            RealTimeTrackingCubit,
                                            RealTimeTrackingState,
                                            List<_MapTrain>
                                          >(
                                            selector: _mapTrains,
                                            builder: (context, trains) =>
                                                AnimatedBuilder(
                                                  animation: _pulse,
                                                  builder: (context, _) =>
                                                      CustomPaint(
                                                        painter:
                                                            _MapPulsePainter(
                                                              art,
                                                              trains,
                                                              _pulse.value,
                                                              TrackPalette.of(
                                                                context,
                                                              ),
                                                            ),
                                                      ),
                                                ),
                                          ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        painter: _MapLabelsPainter(
                                          art,
                                          TrackPalette.of(context),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                    ),
              ),
            ),
            // Keeps the title readable where it overlaps the map.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-1.15, -1.25),
                    radius: 1.15,
                    colors: [
                      palette.card.withValues(alpha: 0.95),
                      palette.card.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LiveDot(color: mint, size: 7),
                            SizedBox(width: 7),
                            Text(
                              'LIVE MAP',
                              style: TextStyle(
                                color: palette.g1,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'All trains',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Every train across Pakistan, moving live',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        BlocSelector<
                          RealTimeTrackingCubit,
                          RealTimeTrackingState,
                          (int, int)
                        >(
                          selector: (s) => (
                            s.reportingCount(DateTime.now()),
                            s.stations.length,
                          ),
                          builder: (context, counts) {
                            final (gps, stations) = counts;
                            return Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (gps > 0)
                                  _MapStat(
                                    icon: Icons.satellite_alt_rounded,
                                    text: '$gps live',
                                  ),
                                if (stations > 0)
                                  _MapStat(
                                    icon: Icons.place_rounded,
                                    text: '$stations stations',
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [palette.g2, palette.g1],
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: palette.g1.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open map',
                            style: TextStyle(
                              color: palette.onAccent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: palette.onAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: palette.g1,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_MapTrain> _mapTrains(RealTimeTrackingState s) {
    final now = DateTime.now();
    return [
      for (final position in s.positions.values)
        (
          position.position,
          now.difference(position.fixTime) > kStaleAfter
              ? _MapTrainKind.old
              : (position.moving
                    ? _MapTrainKind.moving
                    : _MapTrainKind.stopped),
        ),
    ];
  }
}

enum _MapTrainKind { moving, stopped, old }

/// A train already located, for the map card.
typedef _MapTrain = (LatLng, _MapTrainKind);

class _MapStat extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MapStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.g1),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: palette.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the map card draws, and where in the card.
class _MapArt {
  final PakistanOutline outline;
  final List<List<LatLng>>? network;

  /// Every station, or those of today's trains until all are loaded.
  final List<LatLng> stations;

  /// The busiest of [stations], which pulse.
  final List<LatLng> hubs;

  factory _MapArt(
    PakistanOutline outline,
    List<List<LatLng>>? network,
    List<LiveTrain> trains,
    List<TrainStation> allStations,
  ) {
    final visits = <String, (LatLng, int)>{};
    for (final train in trains) {
      for (final station in train.journey) {
        final p = station.position;
        if (p == null) continue;
        final key =
            '${p.latitude.toStringAsFixed(2)},${p.longitude.toStringAsFixed(2)}';
        visits[key] = (p, (visits[key]?.$2 ?? 0) + 1);
      }
    }
    final busiest = visits.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return _MapArt._(
      outline,
      network,
      allStations.isNotEmpty
          ? [for (final station in allStations) ?station.position]
          : [for (final v in visits.values) v.$1],
      [for (final v in busiest.take(6)) v.$1],
    );
  }

  _MapArt._(this.outline, this.network, this.stations, this.hubs);

  /// The same picture: the trains move on every update, but the map they
  /// run on changes only when its stations do, so it isn't drawn again.
  @override
  bool operator ==(Object other) =>
      other is _MapArt &&
      identical(other.outline, outline) &&
      identical(other.network, network) &&
      listEquals(other.stations, stations) &&
      listEquals(other.hubs, hubs);

  @override
  int get hashCode => Object.hash(
    outline,
    network,
    Object.hashAll(stations),
    Object.hashAll(hubs),
  );

  /// The degrees of longitude worth one of latitude at Pakistan's middle.
  static const double _kx = 0.86;

  /// Fits the country into a card of [size], against its right edge.
  Offset Function(LatLng) projector(Size size) {
    final b = outline.bounds;
    final w = (b.northeast.longitude - b.southwest.longitude) * _kx;
    final h = b.northeast.latitude - b.southwest.latitude;
    final area = Rect.fromLTRB(8, 10, size.width - 10, size.height - 8);
    final scale = math.min(area.width / w, area.height / h);
    final dx = area.right - w * scale;
    final dy = area.top + (area.height - h * scale) / 2;
    return (p) => Offset(
      dx + (p.longitude - b.southwest.longitude) * _kx * scale,
      dy + (b.northeast.latitude - p.latitude) * scale,
    );
  }
}

class _MapArtPainter extends CustomPainter {
  final TrackPalette palette;

  final _MapArt art;

  _MapArtPainter(this.art, this.palette);

  /// [path] as dashes along its length.
  static Path _dashed(Path path, double dash, double gap) {
    final out = Path();
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        out.addPath(
          metric.extractPath(d, math.min(d + dash, metric.length)),
          Offset.zero,
        );
      }
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final project = art.projector(size);

    // Parallels and meridians every two degrees, across the whole card.
    final graticule = Paint()
      ..color = palette.g1.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final b = art.outline.bounds;
    for (
      var lon = (b.southwest.longitude / 2).floor() * 2.0 - 8;
      lon <= b.northeast.longitude + 8;
      lon += 2
    ) {
      final x = project(LatLng(b.southwest.latitude, lon)).dx;
      if (x >= 0 && x <= size.width) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), graticule);
      }
    }
    for (
      var lat = (b.southwest.latitude / 2).floor() * 2.0 - 4;
      lat <= b.northeast.latitude + 4;
      lat += 2
    ) {
      final y = project(LatLng(lat, b.southwest.longitude)).dy;
      if (y >= 0 && y <= size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), graticule);
      }
    }

    final land = Path()
      ..addPolygon([for (final p in art.outline.ring) project(p)], true);
    canvas.drawPath(
      land.shift(const Offset(0, 4)),
      Paint()
        ..color = palette.g1.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      land,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            palette.tint(palette.g2, 0.2),
            palette.tint(palette.g2, 0.32),
            palette.tint(palette.g2, 0.45),
          ],
        ).createShader(land.getBounds()),
    );

    final borders = Path();
    for (final line in art.outline.borders) {
      borders.addPolygon([for (final p in line) project(p)], false);
    }
    canvas.drawPath(
      _dashed(borders, 2.6, 2.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = palette.halo.withValues(alpha: 0.95),
    );

    final network = art.network;
    if (network != null) {
      final rails = Path();
      for (final line in network) {
        rails.addPolygon([for (final p in line) project(p)], false);
      }
      canvas.drawPath(
        rails,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..strokeJoin = StrokeJoin.round
          ..color = palette.g1.withValues(alpha: 0.5),
      );
    }
    canvas.drawPath(
      land,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = palette.g1,
    );
    // Many stations: smaller dots.
    final many = art.stations.length > 100;
    final dot = Paint()
      ..color = palette.g1.withValues(alpha: many ? 0.55 : 0.8);
    for (final station in art.stations) {
      canvas.drawCircle(project(station), many ? 1.2 : 1.7, dot);
    }
  }

  @override
  bool shouldRepaint(_MapArtPainter old) =>
      old.art != art || old.palette != palette;
}

/// Province and territory names, above the trains so they stay readable.
class _MapLabelsPainter extends CustomPainter {
  final TrackPalette palette;

  final _MapArt art;

  _MapLabelsPainter(this.art, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final project = art.projector(size);
    final fontSize = (size.shortestSide / 26).clamp(7.0, 9.5);
    for (final (name, at) in art.outline.labels) {
      final text = _provinceLabels[name] ?? name.toUpperCase();
      final p = project(at);
      if (p.dx < 0 || p.dx > size.width || p.dy < 0 || p.dy > size.height) {
        continue;
      }
      TextPainter label(Paint foreground) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            height: 1.1,
            foreground: foreground,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final halo = label(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..color = palette.halo.withValues(alpha: 0.9),
      );
      final fill = label(Paint()..color = palette.g1);
      final origin = p - Offset(fill.width / 2, fill.height / 2);
      halo.paint(canvas, origin);
      fill.paint(canvas, origin);
    }
  }

  /// Names short enough for the card.
  static const _provinceLabels = {
    'Khyber Pakhtunkhwa': 'KPK',
    'Gilgit-Baltistan': 'GILGIT\nBALTISTAN',
    'Azad Kashmir': 'AJK',
    'Jammu & Kashmir': 'J & K',
  };

  @override
  bool shouldRepaint(_MapLabelsPainter old) =>
      old.art != art || old.palette != palette;
}

/// Rings spreading from the busiest stations, and the trains already
/// located.
class _MapPulsePainter extends CustomPainter {
  final TrackPalette palette;

  final _MapArt art;
  final List<_MapTrain> trains;
  final double t;

  _MapPulsePainter(this.art, this.trains, this.t, this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final project = art.projector(size);
    for (var i = 0; i < art.hubs.length; i++) {
      final p = project(art.hubs[i]);
      final phase = (t + i / art.hubs.length) % 1.0;
      canvas.drawCircle(
        p,
        3 + 13 * phase,
        Paint()..color = palette.g1.withValues(alpha: 0.4 * (1 - phase)),
      );
      canvas.drawCircle(p, 3.6, Paint()..color = palette.halo);
      canvas.drawCircle(p, 2.2, Paint()..color = palette.g1);
    }
    for (var i = 0; i < trains.length; i++) {
      final (at, kind) = trains[i];
      final p = project(at);
      final color = switch (kind) {
        // Darker than the mint land so moving trains stand out on it.
        _MapTrainKind.moving => palette.g1,
        _MapTrainKind.stopped => palette.amber,
        _MapTrainKind.old => palette.grey,
      };
      if (kind == _MapTrainKind.moving) {
        final phase = (t * 1.5 + i * 0.37) % 1.0;
        canvas.drawCircle(
          p,
          2.5 + 7 * phase,
          Paint()..color = color.withValues(alpha: 0.45 * (1 - phase)),
        );
      }
      canvas.drawCircle(p, 4.2, Paint()..color = palette.halo);
      canvas.drawCircle(p, 3.0, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_MapPulsePainter old) =>
      old.t != t ||
      old.art != art ||
      old.trains != trains ||
      old.palette != palette;
}

/// Today's train numbers from the tracking API, as glass chips.
class _TodayCounts extends StatelessWidget {
  const _TodayCounts();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      RealTimeTrackingCubit,
      RealTimeTrackingState,
      (int, int, bool)
    >(
      selector: (s) => (
        s.trains.length,
        s.reportingCount(DateTime.now()),
        s.isLoading && s.trains.isEmpty,
      ),
      builder: (context, counts) {
        final (running, tracked, loading) = counts;
        if (loading) {
          return const _GlassChip(
            icon: Icons.sync_rounded,
            text: "Loading today's trains…",
          );
        }
        if (running == 0) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _GlassChip(
              icon: Icons.train_rounded,
              text: '$running running today',
            ),
            _GlassChip(
              icon: Icons.satellite_alt_rounded,
              text: '$tracked GPS tracked',
            ),
          ],
        );
      },
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: palette.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.g1),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: palette.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Radar ────────────────────────────────────────────────────────────────

/// Radar scope with a locomotive at its centre; sized to the space it gets
/// and hidden when that is too small.
class _Radar extends StatefulWidget {
  const _Radar();

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with AppLoopsMixin {
  late final AppLoop _ripple = loop(const Duration(milliseconds: 4500));
  late final AppLoop _sweep = loop(const Duration(seconds: 5));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        if (size < 90) return const SizedBox.shrink();
        final core = (size * 0.48).clamp(64.0, 112.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_ripple, _sweep]),
                    builder: (context, _) => CustomPaint(
                      painter: _RadarPainter(
                        palette: TrackPalette.of(context),
                        ripple: _ripple.value,
                        sweep: _sweep.value,
                        core: core / size,
                      ),
                    ),
                  ),
                ),
              ),
              _LocoBadge(size: core, glow: _ripple),
            ],
          ),
        );
      },
    );
  }
}

/// A photo of a Pakistan Railways locomotive in a round frame, its
/// headlamps glowing.
class _LocoBadge extends StatelessWidget {
  final double size;

  /// Drives the headlamp glow.
  final Animation<double> glow;

  const _LocoBadge({required this.size, required this.glow});

  /// The headlamps' place in `assets/radar_loco.jpg`, as fractions of it.
  static const Alignment _lamps = Alignment(-0.066, -0.696);

  @override
  Widget build(BuildContext context) {
    final palette = TrackPalette.of(context);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.card, palette.g2],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.g1.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: palette.g2.withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/radar_loco.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
            // Glass sheen across the top.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: glow,
              builder: (context, _) {
                final t = 0.5 + 0.5 * math.sin(glow.value * 4 * math.pi);
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: _lamps,
                      radius: 0.16,
                      colors: [
                        const Color(
                          0xFFFFF6C8,
                        ).withValues(alpha: 0.35 + 0.4 * t),
                        const Color(0x00FFF6C8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final TrackPalette palette;

  final double ripple;
  final double sweep;

  /// The badge's diameter as a share of the radar's.
  final double core;

  _RadarPainter({
    required this.palette,
    required this.ripple,
    required this.sweep,
    required this.core,
  });

  /// Trains the sweep "finds": angle (radians from east, clockwise) and
  /// distance from the centre as a fraction of the radius.
  static const _blips = [(0.6, 0.8), (2.4, 0.92), (4.1, 0.86)];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Scope rings and crosshair.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = palette.g1.withValues(alpha: 0.22);
    for (final f in [core + 0.14, (core + 1.14) / 2, 1.0]) {
      canvas.drawCircle(c, r * f, ring);
    }
    final cross = Paint()
      ..strokeWidth = 1
      ..color = palette.g1.withValues(alpha: 0.14);
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), cross);
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), cross);

    // Ripples spreading out from the badge.
    for (var i = 0; i < 3; i++) {
      final t = (ripple + i / 3) % 1.0;
      canvas.drawCircle(
        c,
        r * (core + (1.1 - core) * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = palette.g2.withValues(alpha: 0.55 * (1 - t)),
      );
    }

    // Rotating sweep with a fading tail.
    final angle = sweep * 2 * math.pi;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      -1.6,
      1.6,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: 2 * math.pi - 1.6,
          endAngle: 2 * math.pi,
          colors: [
            palette.g2.withValues(alpha: 0),
            palette.g2.withValues(alpha: 0.38),
          ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: r)),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..strokeWidth = 1.6
        ..color = palette.g1.withValues(alpha: 0.6),
    );
    canvas.restore();

    // Blips glow as the sweep passes over them.
    for (final (blipAngle, distance) in _blips) {
      final behind = (angle - blipAngle) % (2 * math.pi);
      final glow = behind < 2.4 ? 1 - behind / 2.4 : 0.0;
      final p =
          c + Offset(math.cos(blipAngle), math.sin(blipAngle)) * r * distance;
      canvas.drawCircle(
        p,
        7 * glow + 2,
        Paint()..color = palette.g1.withValues(alpha: 0.18 * glow),
      );
      canvas.drawCircle(
        p,
        2.6,
        Paint()..color = palette.g1.withValues(alpha: 0.35 + 0.6 * glow),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.ripple != ripple ||
      old.sweep != sweep ||
      old.core != core ||
      old.palette != palette;
}

// ─── Rail scenery ─────────────────────────────────────────────────────────

/// The hero was designed as the top 55% of a full-screen canvas; the rail
/// lines keep that layout whatever the hero's own height.
Size _designSize(Size hero) => Size(hero.width, hero.height / 0.55);

/// The two rail lines crossing the hero, in a 400 × 400 design space
/// stretched over [_designSize]. Each runs straight on well past both
/// edges, so trains can come on and go off fully out of sight.
Path _railPath1(Size hero) {
  final size = _designSize(hero);
  double sx(num x) => x * size.width / 400;
  double sy(num y) => y * size.height / 400;
  return Path()
    ..moveTo(sx(-97.4), sy(348.6))
    ..lineTo(sx(-10), sy(300))
    ..cubicTo(sx(80), sy(250), sx(120), sy(320), sx(200), sy(220))
    ..cubicTo(sx(280), sy(120), sx(330), sy(120), sx(420), sy(150))
    ..lineTo(sx(514.9), sy(181.6));
}

Path _railPath2(Size hero) {
  final size = _designSize(hero);
  double sx(num x) => x * size.width / 400;
  double sy(num y) => y * size.height / 400;
  return Path()
    ..moveTo(sx(-99.4), sy(244.7))
    ..lineTo(sx(-10), sy(200))
    ..cubicTo(sx(70), sy(160), sx(150), sy(230), sx(230), sy(130))
    ..cubicTo(sx(310), sy(30), sx(350), sy(60), sx(420), sy(70))
    ..lineTo(sx(519), sy(84.1));
}

/// Two rails with sleepers between them along [path].
void _drawRailTrack(
  Canvas canvas,
  Path path,
  double opacity, {
  required Color color,
}) {
  const gauge = 3.4;
  const sleeperHalf = 6.0;
  const sleeperGap = 9.0;
  final rail = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..color = color.withValues(alpha: opacity);
  final sleeper = Paint()
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..color = color.withValues(alpha: opacity * 0.5);
  for (final metric in path.computeMetrics()) {
    for (var d = sleeperGap / 2; d < metric.length; d += sleeperGap) {
      final t = metric.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx);
      canvas.drawLine(
        t.position + n * sleeperHalf,
        t.position - n * sleeperHalf,
        sleeper,
      );
    }
    final left = Path();
    final right = Path();
    for (var d = 0.0; d <= metric.length; d += 4) {
      final t = metric.getTangentForOffset(d)!;
      final n = Offset(-t.vector.dy, t.vector.dx);
      final l = t.position + n * gauge;
      final r = t.position - n * gauge;
      if (d == 0) {
        left.moveTo(l.dx, l.dy);
        right.moveTo(r.dx, r.dy);
      } else {
        left.lineTo(l.dx, l.dy);
        right.lineTo(r.dx, r.dy);
      }
    }
    canvas.drawPath(left, rail);
    canvas.drawPath(right, rail);
  }
}

class _BackdropPainter extends CustomPainter {
  final TrackPalette palette;

  /// Height at the bottom covered by the sheet.
  final double bottomInset;

  const _BackdropPainter(this.palette, {this.bottomInset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    // Dots fading out down the hero.
    final dot = Paint();
    const gap = 18.0;
    for (var x = 0.0; x < size.width; x += gap) {
      for (var y = 0.0; y < size.height * 0.6; y += gap) {
        final mask = (1.0 - y / (size.height * 0.6)).clamp(0.0, 1.0);
        dot.color = palette.g1.withValues(alpha: 0.16 * mask);
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }

    // Grid.
    final grid = Paint()
      ..color = palette.g1.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    for (var x = 0.0; x <= size.width; x += 80) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 80) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Skyline just above the sheet.
    final design = _designSize(size);
    double sx(num x) => x * design.width / 400;
    double sy(num y) => y * design.height / 400;
    final far = Paint()..color = palette.g2.withValues(alpha: 0.12);
    final near = Paint()..color = palette.g2.withValues(alpha: 0.2);
    canvas.save();
    canvas.translate(0, size.height - bottomInset - sy(100));
    void blocks(List<List<num>> rects, Paint p) {
      for (final r in rects) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sx(r[0]), sy(r[1]), sx(r[2]), sy(r[3])),
            const Radius.circular(1.5),
          ),
          p,
        );
      }
    }

    blocks([
      [0, 41, 21, 59],
      [45, 40, 22, 60],
      [168, 51, 29, 49],
      [309, 41, 25, 59],
    ], far);
    blocks([
      [0, 71, 28, 29],
      [62, 63, 19, 37],
      [157, 64, 14, 36],
      [362, 76, 29, 24],
    ], near);
    canvas.restore();

    // Rail lines.
    _drawRailTrack(canvas, _railPath2(size), 0.3, color: palette.g1);
    _drawRailTrack(canvas, _railPath1(size), 0.5, color: palette.g1);
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.bottomInset != bottomInset || old.palette != palette;
}

/// Trains running along the rail lines, and stations pulsing on them.
class _TrainsPainter extends CustomPainter {
  final TrackPalette palette;

  /// Seconds into [loopSeconds].
  final double seconds;

  /// Height at the bottom covered by the sheet.
  final double bottomInset;

  _TrainsPainter(this.seconds, this.palette, {this.bottomInset = 0});

  /// The animation's loop. Every period below divides it, so the scene
  /// carries on seamlessly when it starts over.
  static const int loopSeconds = 120;

  /// Seconds for a train to run the length of each line.
  static const double _line1Run = 15;
  static const double _line2Run = 20;
  static const double _stationPulse = 2.4;

  /// Stations as (line, fraction along it); only those above the sheet show.
  static const _stations = [(1, 0.6), (2, 0.74)];

  @override
  void paint(Canvas canvas, Size size) {
    final line1 = _railPath1(size).computeMetrics().first;
    final line2 = _railPath2(size).computeMetrics().first;

    for (final (line, fraction) in _stations) {
      final metric = line == 1 ? line1 : line2;
      final p = metric.getTangentForOffset(metric.length * fraction)!.position;
      if (p.dy > size.height - bottomInset - 24) continue;
      final pulse = (seconds / _stationPulse + fraction) % 1.0;
      canvas.drawCircle(
        p,
        6 + 14 * pulse,
        Paint()..color = palette.g2.withValues(alpha: 0.4 * (1 - pulse)),
      );
      canvas.drawCircle(p, 6.5, Paint()..color = palette.halo);
      canvas.drawCircle(
        p,
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = palette.g2,
      );
      canvas.drawCircle(p, 3.2, Paint()..color = palette.g1);
    }

    // Two trains a line, half a run apart, so one is always on its way.
    for (final offset in const [0.0, 0.5]) {
      final run1 = (seconds / _line1Run + offset) % 1.0;
      _drawTrain(canvas, line1, line1.length * run1, forward: true, scale: 1.0);
      final run2 = (seconds / _line2Run + offset) % 1.0;
      _drawTrain(
        canvas,
        line2,
        line2.length * (1 - run2),
        forward: false,
        scale: 0.8,
      );
    }
  }

  /// Locomotive at [head] with two coaches behind it.
  void _drawTrain(
    Canvas canvas,
    ui.PathMetric metric,
    double head, {
    required bool forward,
    required double scale,
  }) {
    const spacing = [0.0, 26.0, 50.0];
    for (var i = spacing.length - 1; i >= 0; i--) {
      final d = forward ? head - spacing[i] * scale : head + spacing[i] * scale;
      if (d < 0 || d > metric.length) continue;
      final t = metric.getTangentForOffset(d)!;
      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.rotate(
        math.atan2(t.vector.dy, t.vector.dx) + (forward ? 0 : math.pi),
      );
      canvas.scale(scale);
      i == 0 ? _drawLocomotive(canvas) : _drawCoach(canvas);
      canvas.restore();
    }
  }

  static final Paint _carShadow = Paint()
    ..color = const Color(0xFF1F5C47).withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

  /// A green Pakistan Railways locomotive with its yellow band, cab at the
  /// front and headlamp lit.
  void _drawLocomotive(Canvas canvas) {
    final body = RRect.fromLTRBR(
      -13,
      -5.5,
      13,
      5.5,
      const Radius.circular(4.5),
    );
    canvas.drawRRect(body.shift(const Offset(0.8, 1.6)), _carShadow);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -5.5),
          const Offset(0, 5.5),
          [const Color(0xFF2E9A63), _locoGreen, const Color(0xFF165C3A)],
          [0, 0.55, 1],
        ),
    );
    // Yellow band down both sides.
    final band = Paint()..color = _livery;
    canvas.drawRect(const Rect.fromLTRB(-11.5, -4.4, 8.5, -3.4), band);
    canvas.drawRect(const Rect.fromLTRB(-11.5, 3.4, 8.5, 4.4), band);
    // Cab windscreen.
    canvas.drawRRect(
      RRect.fromLTRBR(7.5, -3.2, 10.6, 3.2, const Radius.circular(1.2)),
      Paint()..color = const Color(0xFFCFEFFF),
    );
    // Roof units.
    final roof = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawRRect(
      RRect.fromLTRBR(-9, -1.6, -3, 1.6, const Radius.circular(1)),
      roof,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(-1.5, -1.6, 4.5, 1.6, const Radius.circular(1)),
      roof,
    );
    canvas.drawCircle(
      const Offset(12.4, 0),
      1.6,
      Paint()..color = const Color(0xFFFFF3B0),
    );
    final beam = Path()
      ..moveTo(13, 0)
      ..lineTo(40, -8)
      ..lineTo(40, 8)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(13, 0),
          const Offset(40, 0),
          [_livery.withValues(alpha: 0.4), _livery.withValues(alpha: 0)],
        ),
    );
  }

  /// A cream coach with a green waist band and windows.
  void _drawCoach(Canvas canvas) {
    final body = RRect.fromLTRBR(
      -10.5,
      -5,
      10.5,
      5,
      const Radius.circular(3.5),
    );
    canvas.drawRRect(body.shift(const Offset(0.8, 1.6)), _carShadow);
    canvas.drawRRect(body, Paint()..color = const Color(0xFFFFFDF6));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = _locoGreen.withValues(alpha: 0.45),
    );
    final band = Paint()..color = _locoGreen;
    canvas.drawRect(const Rect.fromLTRB(-9.5, -4.2, 9.5, -3.3), band);
    canvas.drawRect(const Rect.fromLTRB(-9.5, 3.3, 9.5, 4.2), band);
    final window = Paint()..color = palette.g1.withValues(alpha: 0.75);
    for (final x in [-7.5, -1.75, 4.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -1.8, 3.5, 3.6),
          const Radius.circular(1),
        ),
        window,
      );
    }
  }

  @override
  bool shouldRepaint(_TrainsPainter old) =>
      old.seconds != seconds ||
      old.bottomInset != bottomInset ||
      old.palette != palette;
}

class _AnimatedEntrance extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double slideOffset;
  final Curve curve;
  const _AnimatedEntrance({
    required this.animation,
    required this.child,
    this.slideOffset = 24.0,
    this.curve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double t = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, slideOffset * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _LiveDot extends StatefulWidget {
  final Color color;
  final double size;

  const _LiveDot({this.color = const Color(0xFF22C55E), this.size = 8});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with AppLoopsMixin {
  late final AppLoop _controller = loop(const Duration(milliseconds: 1600));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.8 * (1 - _controller.value),
                ),
                spreadRadius: widget.size * 1.25 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
