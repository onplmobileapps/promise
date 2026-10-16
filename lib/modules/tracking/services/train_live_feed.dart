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
  void dispose();
}

/// Makes the feed a cubit listens to: [onPosition] with each new report of
/// a watched device, [onLinkChanged] as its connection comes and goes
/// (null once it is no longer watched).
typedef LiveFeedFactory =
    TrainFeed Function({
      required void Function(TrainPosition position) onPosition,
      required void Function(int deviceId, LinkState? state) onLinkChanged,
    });

/// Live positions of every train from the tracking server's one shared
/// socket, `ws/track/proxy/`. On connecting it sends the last position of
/// every device it knows, in a second or two, then every new report, about
/// every 10 s; a single train's own socket can take half a minute to say
/// anything.
///
/// The socket and its JSON, tens of kilobytes a message for hundreds of
/// devices, are handled on a background isolate, so the app's frames never
/// wait on them; only the newer reports of watched devices come across.
/// The socket reconnects by itself, with growing pauses, when it drops or
/// goes quiet, and at once when the phone's internet comes back; it closes
/// while the app is in the background or nothing is watched.
class TrainProxyFeed implements TrainFeed {
  TrainProxyFeed({
    required this.onPosition,
    required this.onLinkChanged,
    this.url = proxyUrl,
    ValueListenable<NetworkStatus>? network,
  }) : _network = network ?? NetworkMonitor.instance.status {
    _lifecycle = AppLifecycleListener(onStateChange: _onAppState);
    _wasOffline = _network.value == NetworkStatus.offline;
    _network.addListener(_onNetwork);
  }

  static const String proxyUrl =
      'wss://pakistanrailway.org/api/ws/track/proxy/';

  final void Function(TrainPosition position) onPosition;
  final void Function(int deviceId, LinkState? state) onLinkChanged;
  final String url;

  /// The phone's connection, to reconnect the moment it is back.
  final ValueListenable<NetworkStatus> _network;
  bool _wasOffline = false;

  /// A device nobody watches stays watched this long, so a card scrolled
  /// out of view and back keeps its status.
  static const Duration _linger = Duration(seconds: 20);

  /// With nothing watched for this long, the socket closes.
  static const Duration _idle = Duration(seconds: 30);

  /// Watchers of each watched device; 0 while it lingers.
  final Map<int, int> _watchers = {};
  final Map<int, Timer> _lingering = {};
  LinkState _link = LinkState.connecting;

  Isolate? _isolate;
  ReceivePort? _inbox;
  SendPort? _worker;
  bool _starting = false;
  Timer? _idleTimer;
  late final AppLifecycleListener _lifecycle;
  bool _paused = false;
  bool _disposed = false;

  /// Tests have no network: there the feed stays connecting.
  static bool get _offline =>
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void watch(int deviceId) {
    if (_disposed) return;
    _lingering.remove(deviceId)?.cancel();
    final before = _watchers[deviceId];
    _watchers[deviceId] = (before ?? 0) + 1;
    _idleTimer?.cancel();
    if (before == null) {
      onLinkChanged(deviceId, _link);
      _sendWatched();
    }
    _start();
  }

  @override
  void unwatch(int deviceId) {
    final count = _watchers[deviceId];
    if (count == null || count == 0) return;
    _watchers[deviceId] = count - 1;
    if (count > 1) return;
    _lingering[deviceId] = Timer(_linger, () {
      _lingering.remove(deviceId);
      _watchers.remove(deviceId);
      onLinkChanged(deviceId, null);
      _sendWatched();
      if (_watchers.isEmpty) _idleTimer = Timer(_idle, _stop);
    });
  }

  void _sendWatched() => _worker?.send(_watchers.keys.toSet());

  Future<void> _start() async {
    if (_disposed || _offline || _isolate != null || _starting) return;
    _starting = true;
    final inbox = ReceivePort();
    _inbox = inbox;
    inbox.listen(_onWorkerMessage);
    try {
      _isolate = await Isolate.spawn(_proxyWorkerMain, (
        inbox.sendPort,
        url,
        _paused,
      ), debugName: 'train-proxy-feed');
    } catch (e) {
      debugPrint('⚠️ Live feed: could not start: $e');
      inbox.close();
      _inbox = null;
    } finally {
      _starting = false;
    }
    if (_disposed) _stop();
  }

  void _onWorkerMessage(Object? message) {
    switch (message) {
      case final SendPort worker:
        _worker = worker;
        _sendWatched();
      case final int link:
        _setLink(LinkState.values[link]);
      case final List<Object?> reports:
        for (final report in reports) {
          if (report is TrainPosition) onPosition(report);
        }
    }
  }

  void _setLink(LinkState link) {
    if (link == _link) return;
    _link = link;
    for (final deviceId in _watchers.keys.toList()) {
      onLinkChanged(deviceId, link);
    }
  }

  void _stop() {
    _idleTimer?.cancel();
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
    _link = LinkState.connecting;
  }

  void _onNetwork() {
    final offline = _network.value == NetworkStatus.offline;
    if (_wasOffline && !offline) _worker?.send('now');
    _wasOffline = offline;
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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _lifecycle.dispose();
    _network.removeListener(_onNetwork);
    for (final timer in _lingering.values) {
      timer.cancel();
    }
    _lingering.clear();
    _watchers.clear();
    _stop();
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
      final TrainPosition? report;
      try {
        report = TrainPosition.fromJson(json);
      } catch (_) {
        continue;
      }
      if (report == null) continue;
      final known = _latest[report.deviceId];
      if (known != null && !report.fixTime.isAfter(known.fixTime)) continue;
      _latest[report.deviceId] = report;
      if (_take(report) case final passed?) fresh.add(passed);
    }
    return fresh;
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
void _proxyWorkerMain((SendPort, String, bool) start) {
  final (out, url, paused) = start;
  final inbox = ReceivePort();
  final worker = _ProxyWorker(out, url, paused: paused);
  inbox.listen(worker.command);
  out.send(inbox.sendPort);
  worker.connect();
}

class _ProxyWorker {
  _ProxyWorker(this._out, this._url, {required bool paused}) : _paused = paused;

  final SendPort _out;
  final String _url;
  final ProxyReports _reports = ProxyReports();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _quietTimer;

  /// Each connection made; a callback of an older one is ignored.
  int _attempt = 0;
  int _failures = 0;
  bool _paused;
  bool _closed = false;

  static const List<int> _retrySeconds = [1, 2, 3, 5, 8, 13, 20, 30];

  /// After the server's own trouble (a 5xx), it is given longer.
  static const List<int> _serverSeconds = [5, 10, 20, 40, 60];

  /// Turned away (401, 403, 429), as a server guarding itself against a
  /// client knocking too often does: a real rest before asking again.
  static const List<int> _refusedSeconds = [30, 60, 120];

  /// Not before this, after being turned away, even when the app comes
  /// back to the front.
  DateTime _restUntil = DateTime(0);

  /// A handshake taking longer than this has failed; the proxy usually
  /// opens in a second or two.
  static const Duration _handshakeTimeout = Duration(seconds: 20);

  /// The proxy sends something every 10 s or so; this long without a word
  /// and the socket has quietly died.
  static const Duration _quietAfter = Duration(seconds: 45);

  static final math.Random _jitter = math.Random();

  void command(Object? message) {
    switch (message) {
      case final Set<int> ids:
        final known = _reports.watch(ids);
        if (known.isNotEmpty) _out.send(known);
      case 'pause':
        _paused = true;
        _drop(retry: false);
      case 'resume':
        if (!_paused) return;
        _paused = false;
        final rest = _restUntil.difference(DateTime.now());
        if (rest > Duration.zero) {
          _retryTimer = Timer(rest, connect);
        } else {
          _failures = 0;
          connect();
        }
      case 'now':
        // The phone is back online: try at once rather than when the last
        // pause runs out, unless the server asked for a rest.
        if (_paused || _closed || _socket != null) return;
        if (DateTime.now().isBefore(_restUntil)) return;
        _failures = 0;
        unawaited(connect());
      case 'close':
        _closed = true;
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
    _socket = socket..pingInterval = const Duration(seconds: 20);
    _out.send(LinkState.open.index);
    _expectMore(attempt);
    _subscription = socket.listen(
      (message) {
        if (attempt != _attempt) return;
        _failures = 0;
        _expectMore(attempt);
        if (message is! String) return;
        final fresh = _reports.read(message);
        if (fresh.isNotEmpty) _out.send(fresh);
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
  /// the server answered the handshake with [status] trouble.
  void _drop({required bool retry, int? status}) {
    _attempt++;
    _quietTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) unawaited(socket.close().catchError((_) {}));
    if (!retry || _closed) return;
    final steps = switch (status) {
      401 || 403 || 429 => _refusedSeconds,
      final code? when code >= 500 => _serverSeconds,
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
