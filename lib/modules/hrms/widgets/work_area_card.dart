import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';
import 'package:railway_hrms/modules/hrms/widgets/location_refresh_prompt.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// "40 m" or "1.2 km", in the user's language.
String formatMeters(AppLocalizations l10n, double meters) => meters < 1000
    ? l10n.distanceMeters(meters.round())
    : l10n.distanceKilometers((meters / 1000).toStringAsFixed(1));

/// Where the employee stands against their work area: a small map of the
/// fence with them on it, whether they are inside, and how far they are.
/// Tapping opens the map, or asks for the location when it is off.
class WorkAreaCard extends StatelessWidget {
  const WorkAreaCard({super.key, required this.onOpenMap});

  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return BlocBuilder<WorkAreaCubit, WorkAreaState>(
      builder: (context, area) {
        final office = area.currentOffice ?? area.nearestOffice;
        final name = office?.name ?? l10n.workAreaYours;
        final at = area.position;
        final fromOffice = office != null && at != null
            ? distanceMeters(at, office.center)
            : null;
        final enable = context.read<WorkAreaCubit>().enableLocation;
        final (
          String title,
          String detail,
          Color tone,
          VoidCallback? tap,
        ) = switch (area) {
          _ when area.spoofed => (
            l10n.workAreaFake,
            l10n.workAreaFakeDetail,
            colors.danger,
            onOpenMap,
          ),
          _ when area.offices.isEmpty && area.loadingOffices => (
            l10n.workAreaLoading,
            '',
            colors.textTertiary,
            null,
          ),
          _ when area.offices.isEmpty => (
            l10n.workAreaUnavailable,
            area.officesError ?? l10n.workAreaRetryDetail,
            colors.textTertiary,
            null,
          ),
          _ when area.access == LocationAccess.serviceOff => (
            l10n.workAreaLocationOff,
            l10n.workAreaLocationOffDetail,
            colors.danger,
            enable,
          ),
          _ when area.access == LocationAccess.denied => (
            l10n.workAreaLocationDenied,
            l10n.workAreaDeniedDetail,
            colors.danger,
            enable,
          ),
          _ when area.presence == Presence.unknown => (
            l10n.workAreaFinding,
            l10n.workAreaFindingDetail(name),
            colors.infoMark,
            onOpenMap,
          ),
          _ when area.presence == Presence.inside => (
            l10n.workAreaInside,
            l10n.workAreaInsideDetail(
              name,
              formatMeters(l10n, fromOffice ?? 0),
            ),
            colors.success,
            onOpenMap,
          ),
          _ => (
            l10n.workAreaOutside,
            l10n.workAreaOutsideDetail(
              formatMeters(l10n, area.distanceToEdgeM ?? 0),
              name,
            ),
            colors.warningMark,
            onOpenMap,
          ),
        };
        final loading =
            area.loadingOffices ||
            (area.access == LocationAccess.checking && area.position == null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeletonizer(
              enabled: loading && area.offices.isEmpty,
              child: AppLinkCard(
                leading: _AreaThumb(tone: tone),
                title: title,
                subtitle: detail,
                onTap: tap,
              ),
            ),
            // When the location may not be where they are: what to do.
            if (LocationRefreshPrompt.showsFor(area)) AppSpacing.gapSm,
            LocationRefreshPrompt(state: area),
          ],
        );
      },
    );
  }
}

/// A tiny map: two roads, the dashed fence and the employee's dot in it.
class _AreaThumb extends StatelessWidget {
  const _AreaThumb({required this.tone});

  final Color tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.borderMd,
      child: CustomPaint(
        painter: _AreaThumbPainter(
          ground: colors.surfaceMuted,
          road: colors.surface,
          tone: tone,
          tint: tone.withValues(alpha: 0.18),
        ),
        child: const SizedBox.square(dimension: AppSizes.linkThumb),
      ),
    );
  }
}

class _AreaThumbPainter extends CustomPainter {
  const _AreaThumbPainter({
    required this.ground,
    required this.road,
    required this.tone,
    required this.tint,
  });

  final Color ground;
  final Color road;
  final Color tone;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on the design's 52-unit square.
    final unit = size.width / AppSizes.linkThumb;
    Offset at(double x, double y) => Offset(x * unit, y * unit);
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    final roads = Paint()..color = road;
    canvas
      ..drawLine(at(-2, 18), at(54, 11), roads..strokeWidth = 6 * unit)
      ..drawLine(at(18, -2), at(15, 54), roads..strokeWidth = 5 * unit);
    final center = at(28, 27);
    final fence = 15 * unit;
    canvas.drawCircle(center, fence, Paint()..color = tint);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * unit
      ..color = tone;
    const dashes = 16;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: fence),
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        dash,
      );
    }
    canvas
      ..drawCircle(center, 4.5 * unit, Paint()..color = tone)
      ..drawCircle(
        center,
        4.5 * unit,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * unit
          ..color = road,
      );
  }

  @override
  bool shouldRepaint(_AreaThumbPainter old) =>
      old.ground != ground ||
      old.road != road ||
      old.tone != tone ||
      old.tint != tint;
}
