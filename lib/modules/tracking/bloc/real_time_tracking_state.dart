import 'package:railway_hrms/core/utils/equatable.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';
import 'package:railway_hrms/modules/tracking/services/route_stops.dart';
import 'package:railway_hrms/modules/tracking/services/train_live_feed.dart';

class RealTimeTrackingState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<LiveTrain> trains;

  /// Every station of the railway that has coordinates.
  final List<TrainStation> stations;

  /// Latest report per GPS device, kept while the screen is open.
  final Map<int, TrainPosition> positions;

  /// Socket state of each watched device.
  final Map<int, LinkState> links;

  /// When each watched device's socket first opened, kept across
  /// reconnects, to tell "waiting for the next report" from "the device is
  /// silent".
  final Map<int, DateTime> listeningSince;

  /// When each watched device's feed last (re)connected: a report older
  /// than that may only be the last one the server kept, not proof the
  /// device is silent, until the device has had time to report again.
  final Map<int, DateTime> openedAt;

  final String? selectedTrainId;

  /// Each train's route along the rail network, by train id, once found:
  /// the selected train's, and those of every train with a position, so
  /// the map can run them all along the track.
  final Map<String, RoutePath> paths;

  /// The selected train's route is being found.
  final bool routeLoading;

  /// Where the selected train is along [path].
  final RouteFix? fix;

  /// Distance along [path] of each station in the selected train's
  /// journey, in km; null for a station without coordinates or off the path.
  final List<double?> stationKm;

  /// Every station along [path], the train's own and those it passes.
  final List<RouteStop> routeStops;

  const RealTimeTrackingState({
    this.isLoading = true,
    this.errorMessage,
    this.trains = const [],
    this.stations = const [],
    this.positions = const {},
    this.links = const {},
    this.listeningSince = const {},
    this.openedAt = const {},
    this.selectedTrainId,
    this.paths = const {},
    this.routeLoading = false,
    this.fix,
    this.stationKm = const [],
    this.routeStops = const [],
  });

  LiveTrain? get selectedTrain => trainById(selectedTrainId);

  LiveTrain? trainById(String? id) {
    if (id == null) return null;
    for (final train in trains) {
      if (train.id == id) return train;
    }
    return null;
  }

  /// The selected train's route; null while unknown.
  RoutePath? get path => pathOf(selectedTrainId);

  RoutePath? pathOf(String? trainId) => trainId == null ? null : paths[trainId];

  TrainPosition? positionOf(LiveTrain train) =>
      train.hasDevice ? positions[train.deviceId] : null;

  LinkState? linkOf(LiveTrain train) =>
      train.hasDevice ? links[train.deviceId] : null;

  DateTime? listeningSinceOf(LiveTrain train) =>
      train.hasDevice ? listeningSince[train.deviceId] : null;

  DateTime? openedAtOf(LiveTrain train) =>
      train.hasDevice ? openedAt[train.deviceId] : null;

  /// Trains whose GPS has reported in the last ten minutes: those really
  /// live, rather than merely fitted with a device.
  int reportingCount(DateTime now) => trains.where((train) {
    final position = positionOf(train);
    return position != null &&
        now.difference(position.fixTime) < const Duration(minutes: 10);
  }).length;

  static final Expando<Map<String, List<LiveTrain>>> _services = Expando();

  /// Today's trains by service: a train that takes more than a day runs
  /// twice at once under one name and number, one run per day it left on.
  Map<String, List<LiveTrain>> get services =>
      _services[trains] ??= groupRuns(trains);

  /// Every run of [train]'s service, the latest departure first.
  List<LiveTrain> runsOf(LiveTrain train) =>
      services[train.serviceKey] ?? [train];

  /// Whether another run of [train]'s service is also on the move, so the
  /// two must be told apart by the day they left.
  bool hasOtherRuns(LiveTrain train) => runsOf(train).length > 1;

  static const Object _keep = Object();

  RealTimeTrackingState copyWith({
    bool? isLoading,
    Object? errorMessage = _keep,
    List<LiveTrain>? trains,
    List<TrainStation>? stations,
    Map<int, TrainPosition>? positions,
    Map<int, LinkState>? links,
    Map<int, DateTime>? listeningSince,
    Map<int, DateTime>? openedAt,
    Object? selectedTrainId = _keep,
    Map<String, RoutePath>? paths,
    bool? routeLoading,
    Object? fix = _keep,
    List<double?>? stationKm,
    List<RouteStop>? routeStops,
  }) {
    return RealTimeTrackingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _keep)
          ? this.errorMessage
          : errorMessage as String?,
      trains: trains ?? this.trains,
      stations: stations ?? this.stations,
      positions: positions ?? this.positions,
      links: links ?? this.links,
      listeningSince: listeningSince ?? this.listeningSince,
      openedAt: openedAt ?? this.openedAt,
      selectedTrainId: identical(selectedTrainId, _keep)
          ? this.selectedTrainId
          : selectedTrainId as String?,
      paths: paths ?? this.paths,
      routeLoading: routeLoading ?? this.routeLoading,
      fix: identical(fix, _keep) ? this.fix : fix as RouteFix?,
      stationKm: stationKm ?? this.stationKm,
      routeStops: routeStops ?? this.routeStops,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    trains,
    stations,
    positions,
    links,
    listeningSince,
    openedAt,
    selectedTrainId,
    paths,
    routeLoading,
    fix,
    stationKm,
    routeStops,
  ];
}

/// [trains] grouped by service, each group's latest departure first.
Map<String, List<LiveTrain>> groupRuns(List<LiveTrain> trains) {
  final groups = <String, List<LiveTrain>>{};
  for (final train in trains) {
    groups.putIfAbsent(train.serviceKey, () => []).add(train);
  }
  for (final runs in groups.values) {
    runs.sort(LiveTrain.byLatestRun);
  }
  return groups;
}
