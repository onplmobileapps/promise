import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';

/// What the location prompt says.
enum _Need { finding, failed, updated, outside, stale, rough }

/// Tells the employee, in plain words, when the location the app has may
/// not be where they are, and what to do about it: a key that finds them
/// afresh. It shows while the location is being found again, when that
/// failed or just worked, when they appear outside their office, when the
/// fix is old, and when it is rough; otherwise it stays out of the way.
class LocationRefreshPrompt extends StatefulWidget {
  const LocationRefreshPrompt({super.key, required this.state});

  final WorkAreaState state;

  /// Whether there is anything to say for [state].
  static bool showsFor(WorkAreaState state) =>
      _needOf(state, DateTime.now()) != null;

  /// How long "updated just now" stays.
  static const Duration _updatedFor = Duration(seconds: 4);

  static _Need? _needOf(WorkAreaState s, DateTime now) {
    if (s.offices.isEmpty ||
        s.spoofed ||
        s.access == LocationAccess.serviceOff ||
        s.access == LocationAccess.denied) {
      return null;
    }
    if (s.refreshing) return _Need.finding;
    if (s.refreshFailed) return _Need.failed;
    final refreshed = s.refreshedAt;
    if (refreshed != null && now.difference(refreshed) < _updatedFor) {
      return _Need.updated;
    }
    if (s.position == null) return null;
    if (s.presence == Presence.outside) return _Need.outside;
    if (s.isStale(now)) return _Need.stale;
    if (s.isRough) return _Need.rough;
    return null;
  }

  @override
  State<LocationRefreshPrompt> createState() => _LocationRefreshPromptState();
}

class _LocationRefreshPromptState extends State<LocationRefreshPrompt> {
  Timer? _clear;

  @override
  void didUpdateWidget(LocationRefreshPrompt old) {
    super.didUpdateWidget(old);
    final refreshed = widget.state.refreshedAt;
    if (refreshed != null && refreshed != old.state.refreshedAt) {
      // "Updated just now" gives way after a moment.
      _clear?.cancel();
      _clear = Timer(LocationRefreshPrompt._updatedFor, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _clear?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final s = widget.state;
    final now = DateTime.now();
    final need = LocationRefreshPrompt._needOf(s, now);
    final age = s.positionAt == null
        ? 0
        : now.difference(s.positionAt!).inMinutes;

    final Widget body;
    if (need == null) {
      body = const SizedBox(width: double.infinity);
    } else {
      final (
        String title,
        String detail,
        AppGlyph glyph,
        Color fill,
        Color ink,
      ) = switch (need) {
        _Need.finding => (
          l10n.locFinding,
          l10n.locFindingDetail,
          AppGlyphs.locate,
          colors.infoContainer,
          colors.onInfoContainer,
        ),
        _Need.failed => (
          l10n.locFailed,
          l10n.locFailedDetail,
          AppGlyphs.mapPinX,
          colors.dangerContainer,
          colors.onDangerContainer,
        ),
        _Need.updated => (
          l10n.locUpdated,
          l10n.locUpdatedDetail,
          AppGlyphs.locateFixed,
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
        _Need.outside => (
          l10n.locOutside,
          l10n.locOutsideDetail,
          AppGlyphs.mapPin,
          colors.goldContainer,
          colors.onGoldContainer,
        ),
        _Need.stale => (
          l10n.locStale(age),
          l10n.locStaleDetail,
          AppGlyphs.history,
          colors.goldContainer,
          colors.onGoldContainer,
        ),
        _Need.rough => (
          l10n.locRough((s.accuracyM ?? 0).round()),
          l10n.locRoughDetail,
          AppGlyphs.locate,
          colors.infoContainer,
          colors.onInfoContainer,
        ),
      };
      final busy = need == _Need.finding;
      final done = need == _Need.updated;
      body = Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.borderLinkCard,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppGlyphIcon(glyph, size: AppSizes.iconMd, color: ink),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: text.labelLarge?.copyWith(color: ink),
                          ),
                          AppSpacing.gapXxs,
                          Text(
                            detail,
                            style: text.bodySmall?.copyWith(color: ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!done) ...[
                  AppSpacing.gapMd,
                  AppButton(
                    label: busy ? l10n.locFindingShort : l10n.locRefresh,
                    leadingGlyph: AppGlyphs.locateFixed,
                    variant: need == _Need.outside || need == _Need.failed
                        ? AppButtonVariant.primary
                        : AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    isLoading: busy,
                    onPressed: busy
                        ? null
                        : () => context.read<WorkAreaCubit>().refreshLocation(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.short,
        child: KeyedSubtree(key: ValueKey(need), child: body),
      ),
    );
  }
}
