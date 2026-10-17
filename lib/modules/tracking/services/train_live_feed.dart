import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:railway_hrms/core/network/network_monitor.dart';
import 'package:railway_hrms/modules/tracking/data/models/live_train_models.dart';

enum LinkState {
  /// Opening the socket.
  connecting,

  /// Connected; positions arrive as the devices report (about every 10 s
  /// while moving, nothing at all from a switched-off device).
  open,

  /// Dropped; reconnecting after a delay.
  retrying,
}

/// Where screens get trains' live positions from. They [watch] the GPS
/// devices they show and [unwatch] them when done.
abstract interface class TrainFeed {
  void watch(int deviceId);
  void unwatch(int deviceId);

  /// The device of the train followed on its own map, whose reports come
  /// the moment they arrive; the rest come a few times a second, together.
  /// Null when none is followed.
  void follow(int? deviceId);
  void dispose();
}

/// Makes the feed a cubit listens to: [onPosition] with each new report of
/// a watched device, [onLinkChanged] as the connection comes and goes for
/// the [deviceIds] it carries (null once they are no longer watched). The
/// devices share one connection, so they hear of a change together, in one
/// call, however many there are.
typedef LiveFeedFactory =
    TrainFeed Function({
      required void Function(TrainPosition position) onPosition,
      required void Function(Iterable<int> deviceIds, LinkState? state)
      onLinkChanged,
    });

/// Live positions of every train from the tracking server's one shared
/// socket, `ws/track/proxy/`. On connecting it sends the last position of
/// every device it knows, in a second or two, then every new report, about
/// every 10 s; a single train's own socket can take half a minute to say
/// anything.
///
/// Every feed of the app shares one connection: tracking closed and opened
/// again soon after finds the socket still open and is live at once, with
/// the last report of each train it shows.
///
/// The socket and its JSON, tens of kilobytes a message for hundreds of
/// devices, are handled on a background isolate, so the app's frames never
/// wait on them; only the newer reports of watched devices come across.
/// The socket reconnects by itself, with growing pauses, when it drops or
/// goes quiet, and at once when the phone's internet comes back, a socket
/// that died with the old network included; it closes once the app has
/// been in the background a while, or nothing is watched.
class TrainProxyFeed implements TrainFeed {
  TrainProxyFeed({
    required this.onPosition,
    required this.onLinkChanged,
    String url = proxyUrl,
    ValueListenable<NetworkStatus>? network,
  }) : _connection = network == null && url == proxyUrl
           ? _ProxyConnection.shared
           : _ProxyConnection(url, network: network) {
    _connection.attach(this);
  }

  static const String proxyUrl =
      'wss://pakistanrailway.org/api/ws/track/proxy/';

  final void Function(TrainPosition position) onPosition;
  final void Function(Iterable<int> deviceIds, LinkState? state) onLinkChanged;
  final _ProxyConnection _connection;

  /// A device nobody watches stays watched this long, so a card scrolled
  /// out of view and back keeps its status.
  static const Duration _linger = Duration(seconds: 20);

  /// Devices unwatched this close together linger together, and are let
  /// go of in one change: a whole fleet let go of over a moment goes at
  /// once, not train by train.
  static const Duration _lingerSlack = Duration(seconds: 2);

  /// Watchers of each watched device; 0 while it lingers.
  final Map<int, int> _watchers = {};

  /// The lingering devices, in groups that are let go of together; new
  /// ones join [_openLinger] while it takes them.
  final List<_Linger> _lingers = [];
  _Linger? _openLinger;

  /// Devices newly watched, told the link and their last report together
  /// once the watching that added them is done.
  final Set<int> _joined = {};
  bool _joinScheduled = false;
  bool _disposed = false;

  /// The devices watched, lingering ones included.
  Iterable<int> get watched => _watchers.keys;

  /// The device followed; see [follow].
  int? followed;

  @override
  void follow(int? deviceId) {
    if (_disposed || deviceId == followed) return;
    followed = deviceId;
    _connection.watchedChanged();
  }

  @override
  void watch(int deviceId) {
    if (_disposed) return;
    final before = _watchers[deviceId];
    if (before == 0) {
      for (final linger in _lingers) {
        linger.ids.remove(deviceId);
      }
    }
    _watchers[deviceId] = (before ?? 0) + 1;
    if (before != null) return;
    _joined.add(deviceId);
    if (!_joinScheduled) {
      _joinScheduled = true;
      scheduleMicrotask(_announceJoined);
    }
    _connection.watchedChanged();
  }

  void _announceJoined() {
    _joinScheduled = false;
    if (_disposed) return;
    final joined = [
      for (final id in _joined)
        if (_watchers.containsKey(id)) id,
    ];
    _joined.clear();
    if (joined.isEmpty) return;
    onLinkChanged(joined, _connection.link);
    // What the connection already heard of them, at once.
    for (final id in joined) {
      if (_connection.known[id] case final report?) onPosition(report);
    }
  }

  @override
  void unwatch(int deviceId) {
    final count = _watchers[deviceId];
    if (count == null || count == 0) return;
    _watchers[deviceId] = count - 1;
    if (count > 1) return;
    final linger = _openLinger ?? _openNewLinger();
    linger.ids.add(deviceId);
  }

  _Linger _openNewLinger() {
    final linger = _Linger();
    linger
      ..timer = Timer(_linger, () => _letGo(linger))
      ..window = Timer(_lingerSlack, () {
        if (identical(_openLinger, linger)) _openLinger = null;
      });
    _lingers.add(linger);
    return _openLinger = linger;
  }

  /// Lets go of [linger]'s devices that nobody watched again meanwhile.
  void _letGo(_Linger linger) {
    _lingers.remove(linger);
    linger.window?.cancel();
    if (identical(_openLinger, linger)) _openLinger = null;
    if (_disposed) return;
    final expired = [
      for (final id in linger.ids)
        if (_watchers[id] == 0) id,
    ];
    if (expired.isEmpty) return;
    for (final id in expired) {
      _watchers.remove(id);
      _joined.remove(id);
    }
    onLinkChanged(expired, null);
    _connection.watchedChanged();
  }

  void _linkChanged(LinkState link) {
    if (_watchers.isEmpty) return;
    onLinkChanged(_watchers.keys.toList(), link);
  }

  void _reports(List<TrainPosition> reports) {
    for (final report in reports) {
      if (_watchers.containsKey(report.deviceId)) onPosition(report);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final linger in _lingers) {
      linger.timer?.cancel();
      linger.window?.cancel();
    }
    _lingers.clear();
    _openLinger = null;
    _watchers.clear();
    _joined.clear();
    _connection.detach(this);
  }
}

/// Devices that stopped being watched at about the same time, let go of
/// together once they have lingered.
class _Linger {
  final Set<int> ids = {};
  Timer? timer;

  /// While it runs, devices unwatched join this group.
  Timer? window;
}

/// The one socket every [TrainProxyFeed] reads, on its background isolate:
/// open while any of them watches a device, and a while after.
class _ProxyConnection {
  _ProxyConnection(this.url, {ValueListenable<NetworkStatus>? network})
    : _network = network ?? NetworkMonitor.instance.status,
      _isShared = false;

  _ProxyConnection._shared()
    : url = TrainProxyFeed.proxyUrl,
      _network = NetworkMonitor.instance.status,
      _isShared = true;

  static final _ProxyConnection shared = _ProxyConnection._shared();

  final String url;

  /// The phone's connection, to reconnect the moment it is back.
  final ValueListenable<NetworkStatus> _network;

  /// The app's own, which outlives the screens: one made for a single feed
  /// closes with it.
  final bool _isShared;

  final Set<TrainProxyFeed> _feeds = {};

  /// Each device's newest report passed on, for a screen that starts
  /// watching it later.
  final Map<int, TrainPosition> known = {};

  LinkState link = LinkState.connecting;

  /// With nothing watched for this long, the socket closes: long enough
  /// that tracking opened again soon after finds it still open.
  static const Duration _idle = Duration(seconds: 45);

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _worker;
  bool _starting = false;
  Timer? _idleTimer;
  AppLifecycleListener? _lifecycle;
  bool _paused = false;
  bool _wasOffline = false;

  /// The devices the worker was last told of, and of those the followed.
  Set<int> _sent = const {};
  Set<int> _sentFollowed = const {};
  bool _syncScheduled = false;

  /// Tests have no network: there the feed stays connecting.
  static bool get _offline =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  void attach(TrainProxyFeed feed) => _feeds.add(feed);

  void detach(TrainProxyFeed feed) {
    _feeds.remove(feed);
    watchedChanged();
  }

  /// What the feeds watch changed: the worker hears of it once the change
  /// is done, however many devices it took.
  void watchedChanged() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    scheduleMicrotask(_syncWatched);
  }

  void _syncWatched() {
    _syncScheduled = false;
    final ids = {for (final feed in _feeds) ...feed.watched};
    if (ids.isEmpty) {
      if (!_isShared && _feeds.isEmpty) {
        _stop();
        return;
      }
      if (_idleTimer == null && (_isolate != null || _starting)) {
        _idleTimer = Timer(_idle, _stop);
      }
    } else {
      _idleTimer?.cancel();
      _idleTimer = null;
      unawaited(_start());
    }
    final followed = {for (final feed in _feeds) ?feed.followed};
    if (!setEquals(followed, _sentFollowed)) {
      _sentFollowed = followed;
      _worker?.send(('follow', followed));
    }
    if (setEquals(ids, _sent)) return;
    _sent = ids;
    _worker?.send(ids);
  }

  Future<void> _start() async {
    if (_offline || _isolate != null || _starting) return;
    _starting = true;
    _listen();
    final inbox = ReceivePort();
    _inbox = inbox;
    inbox.listen(_onWorkerMessage);
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(_proxyWorkerMain, (
        inbox.sendPort,
        url,
        _paused,
        _network.value == NetworkStatus.offline,
      ), debugName: 'train-proxy-feed');
    } catch (e) {
      debugPrint('⚠️ Live feed: could not start: $e');
      inbox.close();
      if (identical(_inbox, inbox)) _inbox = null;
      return;
    } finally {
      _starting = false;
    }
    // Closed while it started: started again if it is wanted after all.
    if (!identical(_inbox, inbox)) {
      isolate.kill();
      watchedChanged();
      return;
    }
    _isolate = isolate;
    watchedChanged();
  }

  void _listen() {
    if (_lifecycle != null) return;
    final state = WidgetsBinding.instance.lifecycleState;
    _paused =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    _lifecycle = AppLifecycleListener(onStateChange: _onAppState);
    _wasOffline = _network.value == NetworkStatus.offline;
    _network.addListener(_onNetwork);
  }

  void _unlisten() {
    _lifecycle?.dispose();
    _lifecycle = null;
    _network.removeListener(_onNetwork);
  }

  void _onWorkerMessage(Object? message) {
    switch (message) {
      case final SendPort worker:
        _worker = worker;
        _sent = {for (final feed in _feeds) ...feed.watched};
        _sentFollowed = {for (final feed in _feeds) ?feed.followed};
        worker
          ..send(('follow', _sentFollowed))
          ..send(_sent)
          // What changed while it started.
          ..send(_paused ? 'pause' : 'resume');
        if (_network.value == NetworkStatus.offline) worker.send('offline');
      case final int state:
        _setLink(LinkState.values[state]);
      case final List<Object?> reports:
        final fresh = <TrainPosition>[
          for (final report in reports)
            if (report is TrainPosition) report,
        ];
        for (final report in fresh) {
          known[report.deviceId] = report;
        }
        for (final feed in _feeds.toList()) {
          feed._reports(fresh);
        }
    }
  }

  void _setLink(LinkState next) {
    if (next == link) return;
    link = next;
    for (final feed in _feeds.toList()) {
      feed._linkChanged(next);
    }
  }

  void _stop() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _worker?.send('close');
    _worker = null;
    _inbox?.close();
    _inbox = null;
    final isolate = _isolate;
    _isolate = null;
    // Asked to close; made to, should it not.
    if (isolate != null) {
      Timer(const Duration(seconds: 2), () => isolate.kill());
    }
    _sent = const {};
    _sentFollowed = const {};
    _unlisten();
    _setLink(LinkState.connecting);
  }

  void _onNetwork() {
    final offline = _network.value == NetworkStatus.offline;
    if (offline == _wasOffline) return;
    _wasOffline = offline;
    _worker?.send(offline ? 'offline' : 'now');
  }

  void _onAppState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_paused) return;
        _paused = false;
        _worker?.send('resume');
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_paused) return;
        _paused = true;
        _worker?.send('pause');
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }
}

/// Reads the proxy's messages: keeps every device's newest report, and of
/// those passes on the watched devices' that are newer than any passed on
/// before. The proxy repeats reports, sends every device's again after a
/// reconnect and mixes in devices that aren't trains; none of that gets
/// through.
class ProxyReports {
  final Map<int, TrainPosition> _latest = {};
  final Map<int, DateTime> _passed = {};

  /// Each device online or not, as the proxy's device list last said.
  final Map<int, bool> _online = {};
  Set<int> _watched = const {};

  /// The watched devices are now [ids]: the newest report known of each
  /// newly watched one, to pass on at once.
  List<TrainPosition> watch(Set<int> ids) {
    final added = ids.difference(_watched);
    _watched = ids;
    return [for (final id in added) ?_take(_latest[id])];
  }

  /// The reports in [message] to pass on.
  List<TrainPosition> read(String message) {
    final Object? decoded;
    try {
      decoded = jsonDecode(message);
    } catch (_) {
      return const [];
    }
    // The proxy's device list: whether each device is online, as it says.
    if (decoded case {'devices': final List<Object?> devices}) {
      return _readDevices(devices);
    }
    final reports = switch (decoded) {
      {'positions': final List<Object?> list} => list,
      {'type': 'position_update', 'data': final Object? one} => [one],
      final Map<String, dynamic> one when one.containsKey('latitude') => [one],
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    final fresh = <TrainPosition>[];
    for (final json in reports) {
      if (json is! Map<String, dynamic>) continue;
      TrainPosition? report;
      try {
        report = TrainPosition.fromJson(json);
      } catch (_) {
        continue;
      }
      if (report == null) continue;
      // Its own status first, else the device list's.
      final online = report.online ?? _online[report.deviceId];
      if (online != report.online) report = report.withOnline(online);
      final known = _latest[report.deviceId];
      if (known != null && !report.fixTime.isAfter(known.fixTime)) continue;
      _latest[report.deviceId] = report;
      if (_take(report) case final passed?) fresh.add(passed);
    }
    return fresh;
  }

  /// The device list's statuses; a watched device's newest report again,
  /// with its new status, where the status changed.
  List<TrainPosition> _readDevices(List<Object?> devices) {
    final changed = <TrainPosition>[];
    for (final device in devices) {
      if (device is! Map<String, dynamic>) continue;
      final id = device['id'];
      final online = switch (device['status']) {
        'online' => true,
        'offline' => false,
        _ => null,
      };
      if (id is! int || online == null) continue;
      _online[id] = online;
      final known = _latest[id];
      if (known == null || known.online == online) continue;
      final updated = known.withOnline(online);
      _latest[id] = updated;
      if (_watched.contains(id)) changed.add(updated);
    }
    return changed;
  }

  /// [report], if its device is watched and it is newer than what was
  /// passed on for it.
  TrainPosition? _take(TrainPosition? report) {
    if (report == null || !_watched.contains(report.deviceId)) return null;
    final passed = _passed[report.deviceId];
    if (passed != null && !report.fixTime.isAfter(passed)) return null;
    _passed[report.deviceId] = report.fixTime;
    return report;
  }
}

/// The proxy socket's side of [TrainProxyFeed], on its own isolate.
void _proxyWorkerMain((SendPort, String, bool, bool) start) {
  final (out, url, paused, offline) = start;
  final inbox = ReceivePort();
  final worker = _ProxyWorker(out, url, paused: paused, offline: offline);
  inbox.listen(worker.command);
  out.send(inbox.sendPort);
  worker.connect();
}

class _ProxyWorker {
  _ProxyWorker(
    this._out,
    this._url, {
    required bool paused,
    required bool offline,
  }) : _paused = paused,
       _offline = offline;

  final SendPort _out;
  final String _url;
  final ProxyReports _reports = ProxyReports();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _quietTimer;
  Timer? _pauseTimer;

  /// Fresh reports on their way to the app, newest of each device: sent
  /// together a few times a second, however the proxy splits them up, so
  /// the app's isolate wakes for a handful of messages rather than one per
  /// train; a followed device's go at once.
  final Map<int, TrainPosition> _outbox = {};
  Timer? _sendTimer;
  Set<int> _followed = const {};

  /// The longest a report waits to be sent with others.
  static const Duration _sendEvery = Duration(milliseconds: 200);

  /// Each connection made; a callback of an older one is ignored.
  int _attempt = 0;
  int _failures = 0;
  bool _paused;
  bool _closed = false;

  /// The phone has no internet: the socket is not knocked at again and
  /// again for nothing, only now and then in case the phone is wrong.
  bool _offline;

  /// When the socket last said anything.
  DateTime? _lastHeard;

  static const List<int> _retrySeconds = [1, 2, 3, 5, 8, 13, 20, 30];

  /// After the server's own trouble (a 5xx), it is given longer.
  static const List<int> _serverSeconds = [5, 10, 20, 40, 60];

  /// Turned away (401, 403, 429), as a server guarding itself against a
  /// client knocking too often does: a real rest before asking again.
  static const List<int> _refusedSeconds = [30, 60, 120];

  /// While the phone is offline.
  static const List<int> _offlineSeconds = [30];

  /// Not before this, after being turned away, even when the app comes
  /// back to the front.
  DateTime _restUntil = DateTime(0);

  /// A handshake taking longer than this has failed; the proxy usually
  /// opens in a second or two.
  static const Duration _handshakeTimeout = Duration(seconds: 15);

  /// How often the socket is pinged: a socket whose pong doesn't come back
  /// in this long is closed, and opened again.
  static const Duration _pingEvery = Duration(seconds: 10);

  /// The proxy sends something every 10 s or so; this long without a word
  /// and the socket has quietly died.
  static const Duration _quietAfter = Duration(seconds: 30);

  /// How long the socket stays open while the app is in the background.
  static const Duration _keepWhilePaused = Duration(seconds: 30);

  /// When the phone's network changes, a socket that has said nothing for
  /// this long went with the old network: it is opened again at once
  /// rather than after the pings or the quiet give up on it.
  static const Duration _stillAfter = Duration(seconds: 6);

  static final math.Random _jitter = math.Random();

  bool _heardWithin(Duration duration) {
    final heard = _lastHeard;
    return heard != null && DateTime.now().difference(heard) < duration;
  }

  void command(Object? message) {
    switch (message) {
      case final Set<int> ids:
        final known = _reports.watch(ids);
        if (known.isNotEmpty) _out.send(known);
      case ('follow', final Set<int> ids):
        _followed = ids;
      case 'pause':
        if (_paused) return;
        _paused = true;
        _retryTimer?.cancel();
        // Kept a little while: a glance at another app finds the socket
        // still open, and the trains live, on coming back.
        _pauseTimer?.cancel();
        _pauseTimer = Timer(_keepWhilePaused, () {
          _drop(retry: false);
          _out.send(LinkState.connecting.index);
        });
      case 'resume':
        if (!_paused) return;
        _paused = false;
        _pauseTimer?.cancel();
        _pauseTimer = null;
        if (_socket != null) return;
        final rest = _restUntil.difference(DateTime.now());
        if (rest > Duration.zero) {
          _retryTimer?.cancel();
          _retryTimer = Timer(rest, connect);
        } else {
          _failures = 0;
          connect();
        }
      case 'offline':
        _offline = true;
        // A socket still talking is kept; one gone quiet went with the
        // network, and is tried again when it is back.
        if (_socket != null && !_heardWithin(_stillAfter)) _drop(retry: true);
      case 'now':
        // The phone is back online: try at once rather than when the last
        // pause runs out, unless the server asked for a rest.
        _offline = false;
        if (_paused || _closed) return;
        if (DateTime.now().isBefore(_restUntil)) return;
        if (_socket != null) {
          if (_heardWithin(_stillAfter)) return;
          // Open on the old network, and dead with it.
          _drop(retry: false);
        }
        _failures = 0;
        unawaited(connect());
      case 'close':
        _closed = true;
        _pauseTimer?.cancel();
        _sendTimer?.cancel();
        _drop(retry: false);
        Isolate.exit();
    }
  }

  Future<void> connect() async {
    if (_paused || _closed || _socket != null) return;
    final attempt = ++_attempt;
    _retryTimer?.cancel();
    _out.send(
      (_failures == 0 ? LinkState.connecting : LinkState.retrying).index,
    );
    final WebSocket socket;
    try {
      socket = await WebSocket.connect(_url).timeout(_handshakeTimeout);
    } catch (e) {
      debugPrint('⚠️ Live feed: $e');
      if (attempt == _attempt) _drop(retry: true, status: _statusOf(e));
      return;
    }
    if (attempt != _attempt || _paused || _closed) {
      unawaited(socket.close().catchError((_) {}));
      return;
    }
    _socket = socket..pingInterval = _pingEvery;
    _lastHeard = DateTime.now();
    _out.send(LinkState.open.index);
    _expectMore(attempt);
    _subscription = socket.listen(
      (message) {
        if (attempt != _attempt) return;
        _failures = 0;
        _lastHeard = DateTime.now();
        _expectMore(attempt);
        if (message is! String) return;
        _pass(_reports.read(message));
      },
      onError: (Object _) {
        if (attempt == _attempt) _drop(retry: true);
      },
      onDone: () {
        if (attempt == _attempt) _drop(retry: true);
      },
      cancelOnError: true,
    );
  }

  void _pass(List<TrainPosition> fresh) {
    if (fresh.isEmpty) return;
    var now = false;
    for (final report in fresh) {
      _outbox[report.deviceId] = report;
      if (_followed.contains(report.deviceId)) now = true;
    }
    if (now) {
      _sendOutbox();
    } else {
      _sendTimer ??= Timer(_sendEvery, _sendOutbox);
    }
  }

  void _sendOutbox() {
    _sendTimer?.cancel();
    _sendTimer = null;
    if (_outbox.isEmpty) return;
    _out.send(_outbox.values.toList());
    _outbox.clear();
  }

  void _expectMore(int attempt) {
    _quietTimer?.cancel();
    _quietTimer = Timer(_quietAfter, () {
      if (attempt == _attempt) _drop(retry: true);
    });
  }

  /// The HTTP status a handshake was answered with, if it was.
  static int? _statusOf(Object error) => error is WebSocketException
      ? int.tryParse(
          RegExp(r'status code: (\d{3})').firstMatch(error.message)?[1] ?? '',
        )
      : null;

  /// Lets the socket go and, with [retry], connects again after a pause
  /// that grows with each failure, spread out a little, and is longer when
  /// the server answered the handshake with [status] trouble or the phone
  /// is offline.
  void _drop({required bool retry, int? status}) {
    _attempt++;
    _quietTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    final socket = _socket;
    _socket = null;
    _lastHeard = null;
    if (socket != null) unawaited(socket.close().catchError((_) {}));
    if (!retry || _closed) return;
    final steps = switch (status) {
      401 || 403 || 429 => _refusedSeconds,
      final code? when code >= 500 => _serverSeconds,
      _ when _offline => _offlineSeconds,
      _ => _retrySeconds,
    };
    final base = steps[math.min(_failures, steps.length - 1)];
    _failures++;
    final delay = Duration(
      milliseconds: (base * (0.75 + _jitter.nextDouble() * 0.5) * 1000).round(),
    );
    if (steps == _refusedSeconds) _restUntil = DateTime.now().add(delay);
    if (_paused) return;
    _out.send(LinkState.retrying.index);
    _retryTimer = Timer(delay, connect);
  }
}
