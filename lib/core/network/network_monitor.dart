import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

enum NetworkStatus { online, slow, offline }

/// Why the device is offline.
enum OfflineReason {
  /// Neither Wi-Fi nor mobile data is on.
  noConnection,

  /// Connected, but nothing on the internet answers.
  noInternet,
}

/// Watches the internet connection: whether Wi-Fi or mobile data is on
/// (connectivity_plus), whether the internet actually answers, and how fast.
///
/// Speed comes from a tiny probe request every so often, timed on a
/// background isolate so a busy moment in the app — starting up, say —
/// isn't taken for a slow network. The app's own API calls only prove the
/// internet answers ([DioClient] reports them here): how long the server
/// takes to answer says nothing of the network.
///
/// It is slow to cry wolf: a probe that fails is tried again a moment
/// later before the internet is taken to be gone, a phone moving between
/// networks is given a moment to settle, and one slow probe is not a slow
/// network.
class NetworkMonitor {
  NetworkMonitor({
    Connectivity? connectivity,
    Future<Duration?> Function()? probe,
    this.onlineInterval = const Duration(seconds: 30),
    this.troubleInterval = const Duration(seconds: 10),
    this.recheckAfter = const Duration(seconds: 3),
    this.settleAfter = const Duration(seconds: 2),
  }) : _connectivity = connectivity ?? Connectivity(),
       _probe = probe ?? _defaultProbe;

  static final NetworkMonitor instance = NetworkMonitor();

  final Connectivity _connectivity;
  final Future<Duration?> Function() _probe;

  /// How often to re-check while online, and while slow or offline.
  final Duration onlineInterval;
  final Duration troubleInterval;

  /// After a failed or slow probe, the next comes this soon, to tell a blip
  /// from a real problem.
  final Duration recheckAfter;

  /// After Wi-Fi or mobile data comes or goes, the network is given this
  /// long to settle before it is probed.
  final Duration settleAfter;

  final ValueNotifier<NetworkStatus> status = ValueNotifier(
    NetworkStatus.online,
  );
  OfflineReason offlineReason = OfflineReason.noConnection;

  /// A probe slower than this means a slow connection.
  static const Duration slowProbe = Duration(milliseconds: 2000);

  /// The server answered an API call this recently: the internet works,
  /// whatever a probe says.
  static const Duration _answerProof = Duration(seconds: 20);

  /// Recent speed samples, newest last: true when slow.
  final List<bool> _samples = [];
  static const int _window = 3;

  StreamSubscription<List<ConnectivityResult>>? _interfaces;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  bool _hasInterface = true;
  bool _checking = false;
  bool _started = false;
  int _failedProbes = 0;
  DateTime? _answeredAt;

  void start() {
    if (_started) return;
    _started = true;
    _interfaces = _connectivity.onConnectivityChanged.listen(
      (results) => _onInterfaces(results, settle: true),
    );
    unawaited(
      _connectivity.checkConnectivity().then(
        (results) => _onInterfaces(results, settle: false),
      ),
    );
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(check());
        _schedule();
      },
      onPause: () => _timer?.cancel(),
    );
  }

  void _onInterfaces(List<ConnectivityResult> results, {required bool settle}) {
    _hasInterface = results.any((r) => r != ConnectivityResult.none);
    if (!_hasInterface) {
      _samples.clear();
      _failedProbes = 0;
      offlineReason = OfflineReason.noConnection;
      _set(NetworkStatus.offline);
      _schedule();
      return;
    }
    if (settle) {
      // Switching networks drops what was in flight; a probe right now
      // would fail for that alone.
      _schedule(after: settleAfter);
    } else {
      unawaited(check());
    }
  }

  /// Checks the internet now, unless a check is already running.
  Future<void> check() async {
    if (!_hasInterface || _checking) return;
    _checking = true;
    final Duration? latency;
    try {
      latency = await _probe();
    } finally {
      _checking = false;
    }
    if (!_hasInterface) return;
    if (latency == null) {
      _failedProbes++;
      // One failure can be a blip; two in a row, a moment apart, is no
      // internet — unless the server has just answered the app.
      if (_failedProbes >= 2 && !_answeredLately) {
        offlineReason = OfflineReason.noInternet;
        _set(NetworkStatus.offline);
        _schedule();
      } else {
        _schedule(after: recheckAfter);
      }
      return;
    }
    _failedProbes = 0;
    final slow = latency > slowProbe;
    _addSample(slow);
    // A slow probe is looked at again soon, so a slow network shows
    // without waiting half a minute, and a one-off doesn't linger.
    _schedule(after: slow ? recheckAfter : null);
  }

  bool get _answeredLately {
    final at = _answeredAt;
    return at != null && DateTime.now().difference(at) < _answerProof;
  }

  /// The server answered an API call, after [duration]. The internet works;
  /// how long it took is the server's affair as much as the network's.
  void reportRequest([Duration? duration]) {
    _answeredAt = DateTime.now();
    if (!_hasInterface) return;
    _failedProbes = 0;
    if (status.value == NetworkStatus.offline) {
      _samples.clear();
      _set(NetworkStatus.online);
      _schedule();
    }
  }

  /// An API call couldn't reach the server.
  void reportUnreachable() => unawaited(check());

  void _addSample(bool slow) {
    _samples.add(slow);
    while (_samples.length > _window) {
      _samples.removeAt(0);
    }
    final slowCount = _samples.where((s) => s).length;
    // Most recent samples slow, and more than one of them: slow. Leaving
    // slow takes most samples fast.
    final isSlow = slowCount >= 2 && slowCount * 2 > _samples.length;
    _set(isSlow ? NetworkStatus.slow : NetworkStatus.online);
  }

  void _set(NetworkStatus next) {
    if (status.value != next) status.value = next;
  }

  void _schedule({Duration? after}) {
    _timer?.cancel();
    if (!_started) return;
    final every =
        after ??
        (status.value == NetworkStatus.online
            ? onlineInterval
            : troubleInterval);
    _timer = Timer(every, () => unawaited(check()));
  }

  void dispose() {
    _timer?.cancel();
    _interfaces?.cancel();
    _lifecycle?.dispose();
    status.dispose();
  }

  /// Time for a tiny request to answer, or null when nothing answers,
  /// timed on its own isolate.
  static Future<Duration?> _defaultProbe() async {
    try {
      final micros = await Isolate.run(_probeOnce);
      return micros == null ? null : Duration(microseconds: micros);
    } catch (_) {
      return null;
    }
  }

  /// Microseconds for Google's connectivity check, or the app's own
  /// server, to answer; null when neither does.
  static Future<int?> _probeOnce() async {
    for (final url in const [
      'https://www.gstatic.com/generate_204',
      'https://pakistanrailway.org/',
    ]) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8);
      final watch = Stopwatch()..start();
      try {
        final request = await client
            .headUrl(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(
          const Duration(seconds: 8),
        );
        await response.drain<void>();
        return watch.elapsedMicroseconds;
      } catch (_) {
        // Try the next one.
      } finally {
        client.close(force: true);
      }
    }
    return null;
  }
}
