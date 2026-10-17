import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/maps/map_loop.dart';
import 'package:railway_hrms/core/network/api_endpoints.dart';
import 'package:railway_hrms/core/security/device_integrity.dart';
import 'package:railway_hrms/core/storage/storage_service.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';
import 'package:railway_hrms/modules/hrms/widgets/location_refresh_prompt.dart';
import 'package:railway_hrms/modules/hrms/widgets/work_area_card.dart';
import 'package:railway_hrms/modules/hrms/widgets/work_area_markers.dart';

const Map<String, dynamic> _empty = {
  'type': 'FeatureCollection',
  'features': <Object>[],
};

/// The employee's allowed work areas on a map, with where they are and the
/// way into the nearest one. Expects the HRMS [WorkAreaCubit].
///
/// Pops with `true` when the employee asks to mark attendance from inside
/// an area.
class WorkAreaMapScreen extends StatefulWidget {
  /// Opened because a check-in was tried from outside the area.
  final bool fromCheckIn;

  const WorkAreaMapScreen({super.key, this.fromCheckIn = false});

  @override
  State<WorkAreaMapScreen> createState() => _WorkAreaMapScreenState();
}

class _WorkAreaMapScreenState extends State<WorkAreaMapScreen> {
  late final WorkAreaCubit _cubit = context.read<WorkAreaCubit>();

  /// Pulses the ring under the employee: on a timer, as the map draws it
  /// itself, not by having Flutter redraw the screen every frame.
  late final MapLoop _pulse = MapLoop(
    _onTick,
    interval: () => AppPerformance.lite
        ? const Duration(milliseconds: 90)
        : const Duration(milliseconds: 60),
  );
  MapLibreMapController? _map;
  bool _layersReady = false;
  bool _framed = false;
  bool _pulseBusy = false;

  /// The office the employee picked from the list, if any.
  WorkOffice? _picked;

  /// The colours the layers are drawn in, read from the theme once the map
  /// has loaded.
  _MapColors _colors = _MapColors.of(AppColors.light);

  /// The office the way is drawn to: the one picked, else the one they are
  /// in, else the nearest.
  WorkOffice? _target(WorkAreaState state) {
    final picked = _picked;
    if (picked != null && state.offices.contains(picked)) return picked;
    return state.currentOffice ?? state.nearestOffice;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Covered by another screen, the pulse waits.
    _pulse.visible = TickerMode.valuesOf(context).enabled;
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ─── Map ──────────────────────────────────────────────────────────────

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final palette = MarkerPalette.of(context.colors);
    final colors = _MapColors.of(context.colors);
    try {
      final user = (await StorageService.getUser())?.user;
      final initials = initialsOf(user?.fullName);
      await map.addImage('office-pin', await officePinPng(dpr, palette));
      await map.addImage('route-arrow', await routeArrowPng(dpr, palette));
      await map.addImage(
        'me',
        await userAvatarPng(dpr, palette, initials: initials),
      );
      await _addLayers(map, colors);
      _colors = colors;
      unawaited(_usePhoto(map, dpr, palette, user?.profileImage, initials));
    } catch (e) {
      debugPrint('Work area map layers: $e');
      return;
    }
    if (!mounted) return;
    _layersReady = true;
    await _draw(_cubit.state);
    _pulse.start();
  }

  /// Swaps the initials on the avatar for the employee's photo, if they
  /// have one and it downloads.
  Future<void> _usePhoto(
    MapLibreMapController map,
    double dpr,
    MarkerPalette palette,
    String? path,
    String initials,
  ) async {
    String? base;
    try {
      base = ApiEndpoints.base;
    } catch (_) {}
    final url = photoUrl(path, base: base);
    if (url == null) return;
    final photo = await loadPhoto(url);
    if (photo == null) return;
    try {
      if (mounted) {
        await map.addImage(
          'me',
          await userAvatarPng(dpr, palette, initials: initials, photo: photo),
        );
      }
    } catch (e) {
      debugPrint('Work area avatar: $e');
    } finally {
      photo.dispose();
    }
  }

  Future<void> _addLayers(MapLibreMapController map, _MapColors colors) async {
    await map.addGeoJsonSource('fences', _empty);
    await map.addFillLayer(
      'fences',
      'fence-fill',
      const FillLayerProperties(
        fillColor: [Expressions.get, 'color'],
        fillOpacity: [Expressions.get, 'fill'],
      ),
      enableInteraction: false,
    );
    await map.addLineLayer(
      'fences',
      'fence-glow',
      const LineLayerProperties(
        lineColor: [Expressions.get, 'color'],
        lineWidth: 10.0,
        lineBlur: 8.0,
        lineOpacity: 0.45,
      ),
      enableInteraction: false,
    );
    await map.addLineLayer(
      'fences',
      'fence-ring',
      const LineLayerProperties(
        lineColor: [Expressions.get, 'color'],
        lineWidth: 2.6,
        lineDasharray: [2.2, 1.2],
      ),
      enableInteraction: false,
    );

    // The way in: a dotted green line inside the fence to the office...
    await map.addGeoJsonSource('route-in', _empty);
    await map.addLineLayer(
      'route-in',
      'route-in',
      LineLayerProperties(
        lineColor: colors.routeIn,
        lineWidth: 4.0,
        lineDasharray: [0.01, 2.0],
        lineCap: 'round',
      ),
      enableInteraction: false,
    );
    // ...and a solid blue one with arrows from the employee to the fence.
    await map.addGeoJsonSource('route-out', _empty);
    await map.addLineLayer(
      'route-out',
      'route-casing',
      LineLayerProperties(
        lineColor: colors.casing,
        lineWidth: 11.0,
        lineOpacity: 0.95,
        lineCap: 'round',
        lineJoin: 'round',
      ),
      enableInteraction: false,
    );
    await map.addLineLayer(
      'route-out',
      'route-line',
      LineLayerProperties(
        lineColor: colors.route,
        lineWidth: 6.5,
        lineCap: 'round',
        lineJoin: 'round',
      ),
      enableInteraction: false,
    );
    await map.addSymbolLayer(
      'route-out',
      'route-arrows',
      const SymbolLayerProperties(
        symbolPlacement: 'line',
        symbolSpacing: 56,
        iconImage: 'route-arrow',
        iconSize: 0.8,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconRotationAlignment: 'map',
      ),
      enableInteraction: false,
    );
    await map.addGeoJsonSource('route-end', _empty);
    await map.addCircleLayer(
      'route-end',
      'route-end',
      CircleLayerProperties(
        circleRadius: 6.5,
        circleColor: colors.casing,
        circleStrokeColor: colors.inside,
        circleStrokeWidth: 3.5,
      ),
      enableInteraction: false,
    );

    await map.addGeoJsonSource('offices', _empty);
    await map.addSymbolLayer(
      'offices',
      'office-pin',
      SymbolLayerProperties(
        iconImage: 'office-pin',
        iconAnchor: 'bottom',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        textField: [Expressions.get, 'name'],
        textFont: ['Noto Sans Bold'],
        textSize: 12.5,
        textAnchor: 'top',
        textOffset: [0, 0.4],
        textColor: colors.label,
        textHaloColor: colors.casing,
        textHaloWidth: 1.8,
        textOptional: true,
      ),
      enableInteraction: false,
    );

    await map.addGeoJsonSource('accuracy', _empty);
    await map.addFillLayer(
      'accuracy',
      'accuracy',
      FillLayerProperties(fillColor: colors.route, fillOpacity: 0.1),
      enableInteraction: false,
    );
    await map.addGeoJsonSource('user', _empty);
    await map.addCircleLayer(
      'user',
      'user-pulse',
      CircleLayerProperties(
        circleRadius: const [Expressions.get, 'r'],
        circleColor: colors.route,
        circleOpacity: [Expressions.get, 'o'],
      ),
      enableInteraction: false,
    );

    // How far, halfway along the way.
    await map.addGeoJsonSource('route-label', _empty);
    await map.addSymbolLayer(
      'route-label',
      'route-label',
      SymbolLayerProperties(
        textField: const [Expressions.get, 'text'],
        textFont: ['Noto Sans Bold'],
        textSize: 13.0,
        textColor: colors.routeLabel,
        textHaloColor: colors.casing,
        textHaloWidth: 2.5,
        textOffset: [0, -1.1],
        textAllowOverlap: true,
        textIgnorePlacement: true,
      ),
      enableInteraction: false,
    );

    await map.addGeoJsonSource('me', _empty);
    await map.addSymbolLayer(
      'me',
      'me',
      const SymbolLayerProperties(
        iconImage: 'me',
        iconAnchor: 'center',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
  }

  Future<void> _draw(WorkAreaState state) async {
    final map = _map;
    if (map == null || !_layersReady || !mounted) return;
    final at = state.position;
    final current = state.currentOffice;
    final nearest = state.nearestOffice;
    try {
      await map.setGeoJsonSource('fences', {
        'type': 'FeatureCollection',
        'features': [
          for (final office in state.offices)
            _feature(
              {
                'color': office == current ? _colors.inside : _colors.fence,
                'fill': office == current
                    ? 0.2
                    : (office == nearest ? 0.14 : 0.08),
              },
              'Polygon',
              [_coords(office.ring())],
            ),
        ],
      });
      await map.setGeoJsonSource('offices', {
        'type': 'FeatureCollection',
        'features': [
          for (final office in state.offices)
            _feature({'name': office.name}, 'Point', _coord(office.center)),
        ],
      });
      final way = _way(state);
      final out = way?.out;
      final inside = way?.inside;
      await map.setGeoJsonSource(
        'route-out',
        _collection([
          if (out != null) _feature({}, 'LineString', _coords(out)),
        ]),
      );
      await map.setGeoJsonSource(
        'route-in',
        _collection([
          if (inside != null) _feature({}, 'LineString', _coords(inside)),
        ]),
      );
      await map.setGeoJsonSource(
        'route-end',
        _collection([if (out != null) _feature({}, 'Point', _coord(out.last))]),
      );
      await map.setGeoJsonSource(
        'route-label',
        _collection([
          if (out != null)
            _feature(
              {'text': way!.distance},
              'Point',
              _coord(
                LatLng(
                  (out.first.latitude + out.last.latitude) / 2,
                  (out.first.longitude + out.last.longitude) / 2,
                ),
              ),
            ),
        ]),
      );
      await map.setGeoJsonSource(
        'me',
        _collection([if (at != null) _feature({}, 'Point', _coord(at))]),
      );
      final accuracy = state.accuracyM;
      await map.setGeoJsonSource(
        'accuracy',
        at == null || accuracy == null || accuracy < 8
            ? _empty
            : {
                'type': 'FeatureCollection',
                'features': [
                  _feature({}, 'Polygon', [
                    _coords(
                      WorkOffice(
                        id: 0,
                        name: '',
                        unit: '',
                        center: at,
                        radiusM: accuracy,
                      ).ring(points: 48),
                    ),
                  ]),
                ],
              },
      );
    } catch (e) {
      debugPrint('Work area map update: $e');
    }
    if (!_framed && (at != null || state.offices.isNotEmpty)) {
      _framed = at != null;
      await _frame(state);
    }
  }

  /// The way from the employee to the target office: [out] from them to
  /// the fence, then [inside] it to the office itself. Only [inside] when
  /// they are already in that area.
  ({List<LatLng>? out, List<LatLng>? inside, String distance})? _way(
    WorkAreaState state,
  ) {
    final at = state.position;
    final office = _target(state);
    if (at == null || office == null) return null;
    if (office == state.currentOffice || office.distanceToEdgeM(at) <= 0) {
      final d = distanceMeters(at, office.center);
      if (d < 8) return null;
      return (
        out: null,
        inside: [at, office.center],
        distance: formatDistance(d),
      );
    }
    final edge = office.nearestEdgePoint(at);
    return (
      out: [at, edge],
      inside: [edge, office.center],
      distance: formatDistance(office.distanceToEdgeM(at)),
    );
  }

  void _onTick() {
    final map = _map;
    final at = _cubit.state.position;
    if (map == null || !_layersReady || _pulseBusy || !mounted) return;
    final t = (DateTime.now().millisecondsSinceEpoch % 1800) / 1800;
    _pulseBusy = true;
    map
        .setGeoJsonSource(
          'user',
          at == null
              ? _empty
              : {
                  'type': 'FeatureCollection',
                  'features': [
                    _feature(
                      {'r': 20 + 26 * t, 'o': 0.35 * (1 - t)},
                      'Point',
                      _coord(at),
                    ),
                  ],
                },
        )
        .catchError((Object e) => debugPrint('User marker: $e'))
        .whenComplete(() => _pulseBusy = false);
  }

  /// Fits the user and [office] (or the target one) in view, above the
  /// panel.
  Future<void> _frame(WorkAreaState state, [WorkOffice? office]) async {
    final map = _map;
    final target = office ?? _target(state);
    if (map == null || !mounted) return;
    final points = <LatLng>[
      if (target != null) ...target.ring(points: 24),
      ?state.position,
    ];
    if (points.isEmpty) return;
    var south = points.first.latitude, north = south;
    var west = points.first.longitude, east = west;
    for (final p in points) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    final media = MediaQuery.of(context);
    try {
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(south, west),
            northeast: LatLng(north, east),
          ),
          left: 48,
          right: 48,
          top: media.padding.top + 96,
          bottom: media.size.height * 0.42,
        ),
        duration: const Duration(milliseconds: 900),
      );
    } catch (e) {
      debugPrint('Work area camera: $e');
    }
  }

  static Map<String, dynamic> _collection(
    List<Map<String, dynamic>> features,
  ) => {'type': 'FeatureCollection', 'features': features};
  static List<double> _coord(LatLng p) => [p.longitude, p.latitude];
  static List<List<double>> _coords(List<LatLng> ps) => [
    for (final p in ps) _coord(p),
  ];
  static Map<String, dynamic> _feature(
    Map<String, dynamic> properties,
    String type,
    Object coordinates,
  ) => {
    'type': 'Feature',
    'properties': properties,
    'geometry': {'type': type, 'coordinates': coordinates},
  };

  // ─── UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final start = _cubit.state;
    final initial =
        start.position ??
        start.nearestOffice?.center ??
        const LatLng(33.6844, 73.0479);
    return BlocListener<WorkAreaCubit, WorkAreaState>(
      listener: (_, state) => unawaited(_draw(state)),
      child: BlocBuilder<WorkAreaCubit, WorkAreaState>(
        builder: (context, state) {
          final header = _Header(
            textScale: MediaQuery.textScalerOf(context).scale(1),
            state: state,
            focus: _target(state),
            onRecenter: () {
              _frame(state);
              unawaited(context.read<WorkAreaCubit>().refreshLocation());
            },
            onOffice: (office) {
              setState(() => _picked = office);
              unawaited(_draw(state));
              _frame(state, office);
            },
          );
          return Scaffold(
            backgroundColor: context.colors.surfaceMuted,
            resizeToAvoidBottomInset: false,
            // The map runs under the header and the panel, which float on it.
            extendBodyBehindAppBar: true,
            extendBody: true,
            appBar: header,
            body: MapLibreMap(
              styleString: MapLibreStyles.openfreemapLiberty,
              initialCameraPosition: CameraPosition(target: initial, zoom: 15),
              compassEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              attributionButtonPosition: AttributionButtonPosition.topRight,
              attributionButtonMargins: math.Point(
                AppSpacing.md,
                media.padding.top + header.preferredSize.height,
              ),
              onMapCreated: (c) => _map = c,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
            bottomNavigationBar: _Panel(
              state: state,
              fromCheckIn: widget.fromCheckIn,
              focus: _target(state),
              onOffice: (office) {
                setState(() => _picked = office);
                unawaited(_draw(state));
                _frame(state, office);
              },
              onMark: () => Navigator.of(context).pop(true),
              onEnableLocation: _cubit.enableLocation,
              onRetry: _cubit.loadOffices,
            ),
          );
        },
      ),
    );
  }
}

/// The bar floating over the top of the map: back, the title, a way to
/// centre on the employee, and the offices to pick from.
class _Header extends StatelessWidget implements PreferredSizeWidget {
  const _Header({
    required this.textScale,
    required this.state,
    required this.focus,
    required this.onRecenter,
    required this.onOffice,
  });

  /// How much larger than usual text is drawn, which grows the chips.
  final double textScale;
  final WorkAreaState state;
  final WorkOffice? focus;
  final VoidCallback onRecenter;
  final ValueChanged<WorkOffice> onOffice;

  /// The tiles' row, under the status bar.
  static const double height = AppSpacing.xs + AppSizes.minTapTarget;

  /// The chips' row: a full tap target, taller when the text is.
  double get _chips => math.max(
    AppSizes.minTapTarget,
    AppSizes.minTapTarget -
        AppSizes.chipHeight +
        AppSizes.chipHeight * textScale,
  );

  @override
  Size get preferredSize => Size.fromHeight(
    height + (state.offices.isEmpty ? 0 : AppSpacing.md + _chips),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final current = state.currentOffice;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppTileButton(
                  icon: const AppGlyphIcon(AppGlyphs.chevronLeft),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                AppSpacing.gapXs,
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colors.surfaceRaised, colors.surfaceRaisedEnd],
                      ),
                      borderRadius: BorderRadius.circular(
                        AppRadius.buttonMedium,
                      ),
                      border: Border.all(color: colors.surfaceRaised),
                      boxShadow: context.elevations.raised,
                    ),
                    child: SizedBox(
                      height: AppSizes.headerControl,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            header: true,
                            child: Text(
                              l10n.workAreaYours,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AppSpacing.gapXs,
                AppTileButton(
                  icon: state.refreshing
                      ? SizedBox.square(
                          dimension: AppSizes.iconMd,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.spinnerStroke,
                            color: colors.iconAccent,
                          ),
                        )
                      : AppGlyphIcon(
                          AppGlyphs.locateFixed,
                          color: colors.iconAccent,
                        ),
                  tooltip: l10n.mapRecenter,
                  onPressed: state.refreshing ? null : onRecenter,
                ),
              ],
            ),
            if (state.offices.isNotEmpty) ...[
              AppSpacing.gapMd,
              AppFilterChips<WorkOffice?>(
                selected: focus,
                onSelected: (office) {
                  if (office != null) onOffice(office);
                },
                options: [
                  for (final office in state.offices)
                    AppFilterOption(
                      value: office,
                      label: office.name,
                      mark: office == current ? colors.success : null,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The panel over the foot of the map: where the employee stands against
/// the offices, the numbers that decide it, and what they can do.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.state,
    required this.fromCheckIn,
    required this.focus,
    required this.onOffice,
    required this.onMark,
    required this.onEnableLocation,
    required this.onRetry,
  });

  final WorkAreaState state;
  final bool fromCheckIn;
  final WorkOffice? focus;
  final ValueChanged<WorkOffice> onOffice;
  final VoidCallback onMark;
  final VoidCallback onEnableLocation;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final text = context.textTheme;
    final nearest = state.nearestOffice;
    final current = state.currentOffice;
    final target = focus ?? nearest;
    final at = state.position;
    final away = at == null || target == null
        ? null
        : math.max(0.0, target.distanceToEdgeM(at));

    final (
      String pill,
      AppTone tone,
      Color dot,
      String title,
      String detail,
    ) = switch (state) {
      _ when state.spoofed => (
        l10n.workAreaFake,
        AppTone.danger,
        colors.danger,
        l10n.workAreaFake,
        const LocationSpoofedException().message,
      ),
      _ when state.offices.isEmpty && state.loadingOffices => (
        l10n.workAreaLoading,
        AppTone.neutral,
        colors.textTertiary,
        l10n.workAreaLoading,
        l10n.mapLoadingMessage,
      ),
      _ when state.offices.isEmpty => (
        l10n.workAreaUnavailable,
        AppTone.warning,
        colors.warningMark,
        l10n.mapFailedTitle,
        state.officesError ?? l10n.workAreaRetryDetail,
      ),
      _ when state.access == LocationAccess.serviceOff => (
        l10n.workAreaLocationOff,
        AppTone.danger,
        colors.danger,
        l10n.workAreaLocationOff,
        l10n.mapLocationOffMessage,
      ),
      _ when state.access == LocationAccess.denied => (
        l10n.workAreaLocationDenied,
        AppTone.danger,
        colors.danger,
        l10n.mapDeniedTitle,
        l10n.mapDeniedMessage,
      ),
      _ when state.presence == Presence.unknown => (
        l10n.workAreaFinding,
        AppTone.info,
        colors.infoMark,
        l10n.workAreaFinding,
        l10n.mapFindingMessage,
      ),
      // Attendance is marked where the employee is, not at a picked
      // office.
      _ when current != null && target != null && target != current => (
        l10n.workAreaInside,
        AppTone.brand,
        colors.success,
        l10n.mapYouAreAt(current.name),
        l10n.mapOtherOffice(target.name),
      ),
      _ when current != null => (
        l10n.workAreaInside,
        AppTone.brand,
        colors.success,
        l10n.mapYouAreAt(current.name),
        current.unit.isEmpty ? current.address : current.unit,
      ),
      _ => (
        l10n.workAreaOutside,
        AppTone.warning,
        colors.warningMark,
        l10n.workAreaOutside,
        l10n.mapOutsideMessage(
          formatMeters(l10n, state.distanceToEdgeM ?? 0),
          nearest?.name ?? l10n.workAreaYours,
        ),
      ),
    };

    final updated = state.positionAt;
    final minutes = updated == null
        ? null
        : DateTime.now().difference(updated).inMinutes;
    final fromOffice = at == null || target == null
        ? null
        : distanceMeters(at, target.center);
    final accuracy = state.accuracyM;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.borderSheetTop,
        border: Border(top: BorderSide(color: colors.surfaceRaised)),
        boxShadow: context.elevations.sheet,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.smd,
          AppSpacing.xl,
          AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.outlineStrong,
                  borderRadius: AppRadius.borderPill,
                ),
                child: const SizedBox(
                  width: AppSizes.sheetHandleWidth,
                  height: AppSizes.sheetHandleHeight,
                ),
              ),
            ),
            AppSpacing.gapLg,
            Row(
              children: [
                Flexible(
                  child: AppPill(pill, tone: tone, dot: dot),
                ),
                const Spacer(),
                if (minutes != null)
                  Text(
                    minutes < 1
                        ? l10n.mapUpdatedNow
                        : l10n.mapUpdatedMinutes(minutes),
                    style: text.bodySmall?.copyWith(
                      fontWeight: AppFonts.medium,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapMd,
            Text(title, style: text.headlineMedium),
            Text(detail, style: text.bodyMedium),
            if (target != null && at != null) ...[
              AppSpacing.gapMd,
              Row(
                children: [
                  Expanded(
                    child: AppStatTile(
                      value: formatMeters(l10n, fromOffice ?? 0),
                      label: l10n.mapFromOffice,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: AppStatTile(
                      value: accuracy == null
                          ? '--'
                          : l10n.mapAccuracyValue(accuracy.round()),
                      label: l10n.mapAccuracy,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Expanded(
                    child: AppStatTile(
                      value: formatMeters(l10n, target.radiusM),
                      label: away != null && away > 0
                          ? l10n.mapAway(formatMeters(l10n, away))
                          : l10n.mapRange,
                    ),
                  ),
                ],
              ),
            ],
            // When the dot may not be where they are: what to do.
            if (LocationRefreshPrompt.showsFor(state)) AppSpacing.gapMd,
            LocationRefreshPrompt(state: state),
            AppSpacing.gapLg,
            _action(context, current, target),
          ],
        ),
      ),
    );
  }

  /// Marks attendance only at the office the employee is in, and only
  /// while that is the office picked on the map.
  Widget _action(
    BuildContext context,
    WorkOffice? current,
    WorkOffice? target,
  ) {
    final l10n = context.l10n;
    if (state.offices.isEmpty && !state.loadingOffices) {
      return AppButton(
        label: l10n.actionRetry,
        leadingGlyph: AppGlyphs.refresh,
        onPressed: onRetry,
      );
    }
    if (state.access == LocationAccess.serviceOff ||
        state.access == LocationAccess.denied) {
      return AppButton(
        label: state.access == LocationAccess.serviceOff
            ? l10n.mapTurnOnLocation
            : l10n.mapAllowLocation,
        leadingGlyph: AppGlyphs.locate,
        onPressed: onEnableLocation,
      );
    }
    // In one office with another picked: back to where they are.
    if (current != null && target != null && current != target) {
      return AppButton(
        label: l10n.mapMarkInstead(current.name),
        variant: AppButtonVariant.secondary,
        leadingGlyph: AppGlyphs.locateFixed,
        onPressed: () => onOffice(current),
      );
    }
    final here = current != null && !state.spoofed;
    return AppButton(
      label: !here
          ? l10n.mapMarkInside
          : fromCheckIn
          ? l10n.mapContinueAt(current.name)
          : l10n.mapMarkHere,
      leadingGlyph: here ? AppGlyphs.scanFace : AppGlyphs.lock,
      onPressed: here ? onMark : null,
    );
  }
}

/// The map's colours as MapLibre takes them: "#RRGGBB".
class _MapColors {
  const _MapColors({
    required this.inside,
    required this.fence,
    required this.route,
    required this.routeIn,
    required this.routeLabel,
    required this.label,
    required this.casing,
  });

  factory _MapColors.of(AppColors colors) {
    String hex(Color color) =>
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    return _MapColors(
      inside: hex(colors.success),
      fence: hex(colors.accent),
      route: hex(colors.iconAccent),
      routeIn: hex(colors.accent),
      routeLabel: hex(colors.accentStrong),
      label: hex(colors.accentStrong),
      casing: hex(colors.surface),
    );
  }

  /// The office the employee is in.
  final String inside;

  /// The other offices.
  final String fence;

  /// The way in, from the employee to the fence.
  final String route;

  /// The way inside the fence to the office.
  final String routeIn;
  final String routeLabel;
  final String label;

  /// The white under lines and around labels.
  final String casing;
}
