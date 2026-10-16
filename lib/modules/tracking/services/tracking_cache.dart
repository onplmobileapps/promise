import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';
import 'package:railway_hrms/modules/tracking/services/route_geometry.dart';

/// What live tracking last knew, kept for the app's session: tracking
/// opened again starts from it — the trains, the stations, where every
/// train was and its route — instead of from nothing, and refreshes in the
/// background. The live feed's first message after connecting can be hours
/// old; with this, a train seen moving a minute ago still shows moving.
class TrackingCache {
  TrackingCache({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// Today's trains are shown from here this long after they were loaded.
  static const Duration trainsFor = Duration(minutes: 30);

  /// Out of touch with the feed for less than this, the time in touch
  /// carries on: a device silent all along is still known to be silent.
  static const Duration touchGap = Duration(minutes: 2);

  List<LiveTrain> _trains = const [];
  DateTime? _trainsAt;
  List<TrainStation> stations = const [];
  Map<int, TrainPosition> positions = const {};
  Map<String, RoutePath> paths = const {};

  DateTime? _inTouchSince;
  DateTime? _inTouchUntil;

  /// The trains, while recent enough to show; empty otherwise.
  List<LiveTrain> get trains {
    final at = _trainsAt;
    if (at == null || _clock().difference(at) > trainsFor) return const [];
    return _trains;
  }

  set trains(List<LiveTrain> trains) {
    if (identical(trains, _trains)) return;
    _trains = trains;
    _trainsAt = _clock();
  }

  /// The feed is open.
  void opened() {
    final now = _clock();
    final until = _inTouchUntil;
    if (_inTouchSince == null ||
        until == null ||
        now.difference(until) > touchGap) {
      _inTouchSince = now;
    }
    _inTouchUntil = now;
  }

  /// The feed is open and has just been heard from.
  void heard() {
    _inTouchSince ??= _clock();
    _inTouchUntil = _clock();
  }

  /// The feed dropped.
  void lost() {
    _inTouchSince = null;
    _inTouchUntil = null;
  }

  /// Since when the app has been in touch with the feed without a break,
  /// counting a reconnect within [touchGap]; null if it isn't.
  DateTime? get inTouchSince {
    final until = _inTouchUntil;
    if (until == null || _clock().difference(until) > touchGap) return null;
    return _inTouchSince;
  }
}
