import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/network/network_monitor.dart';
import 'package:railway_hrms/core/widgets/network_status_banner.dart';

class _FakeConnectivity implements Connectivity {
  final controller = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> now = [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => now;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeConnectivity connectivity;
  late Duration? Function() latency;
  late NetworkMonitor monitor;

  setUp(() {
    connectivity = _FakeConnectivity();
    latency = () => const Duration(milliseconds: 300);
    monitor = NetworkMonitor(
      connectivity: connectivity,
      probe: () async => latency(),
      onlineInterval: const Duration(hours: 1),
      troubleInterval: const Duration(hours: 1),
      recheckAfter: Duration.zero,
      settleAfter: Duration.zero,
    );
  });

  tearDown(() => monitor.dispose());

  Future<void> settle() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('no Wi-Fi or data is offline at once', () async {
    monitor.start();
    await settle();
    expect(monitor.status.value, NetworkStatus.online);
    connectivity.controller.add([ConnectivityResult.none]);
    await settle();
    expect(monitor.status.value, NetworkStatus.offline);
    expect(monitor.offlineReason, OfflineReason.noConnection);
  });

  test(
    'connected without internet is offline after two failed probes',
    () async {
      latency = () => null;
      monitor.start();
      await settle();
      await settle();
      expect(monitor.status.value, NetworkStatus.offline);
      expect(monitor.offlineReason, OfflineReason.noInternet);
    },
  );

  test('one failed probe is a blip, not no internet', () async {
    var failures = 1;
    latency = () => failures-- > 0 ? null : const Duration(milliseconds: 300);
    monitor.start();
    await settle();
    expect(monitor.status.value, NetworkStatus.online);
  });

  test('the server answering the app proves the internet works', () async {
    monitor.start();
    await settle();
    latency = () => null;
    monitor.reportRequest();
    await monitor.check();
    await monitor.check();
    expect(monitor.status.value, NetworkStatus.online);
  });

  test('an answer from the server ends offline at once', () async {
    latency = () => null;
    monitor.start();
    await settle();
    expect(monitor.status.value, NetworkStatus.offline);
    monitor.reportRequest();
    expect(monitor.status.value, NetworkStatus.online);
  });

  test('slow probes make it slow and fast ones undo it; one is not '
      'enough either way, and a slow server is not a slow network', () async {
    monitor.start();
    await settle();
    latency = () => const Duration(seconds: 3);
    await monitor.check();
    // A busy moment, not a slow network.
    expect(monitor.status.value, NetworkStatus.online);
    await monitor.check();
    expect(monitor.status.value, NetworkStatus.slow);

    latency = () => const Duration(milliseconds: 300);
    await monitor.check();
    expect(monitor.status.value, NetworkStatus.slow);
    await monitor.check();
    expect(monitor.status.value, NetworkStatus.online);

    // The server taking its time answering says nothing of the network.
    monitor.reportRequest(const Duration(seconds: 9));
    monitor.reportRequest(const Duration(seconds: 9));
    expect(monitor.status.value, NetworkStatus.online);
  });

  testWidgets('the strip sticks to the top, pushes the screen down and '
      'briefly says when it is over', (tester) async {
    final screen = GlobalKey<State<StatefulWidget>>();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: 24)),
          child: AppFrame(
            child: NetworkStatusBanner(monitor: monitor, child: child!),
          ),
        ),
        home: Scaffold(
          key: screen,
          body: const SafeArea(child: Text('screen')),
        ),
      ),
    );
    final screenState = screen.currentState;
    double screenTop() => tester.getTopLeft(find.text('screen')).dy;
    String? stripText() => tester
        .widgetList<RichText>(find.byType(RichText))
        .map((t) => t.text.toPlainText())
        .where((t) => t.contains('  ·  '))
        .firstOrNull;

    // Online from the start: nothing to say.
    expect(stripText(), isNull);
    expect(screenTop(), 24);

    monitor.status.value = NetworkStatus.offline;
    await tester.pumpAndSettle();
    expect(stripText(), startsWith("You're offline"));
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.bySemanticsLabel("You're offline. Turn on Wi-Fi or mobile data"),
      findsOneWidget,
    );
    // Below the status bar and the strip, not under them.
    expect(screenTop(), 24 + AppSizes.bannerHeight);
    // Its button is a full tap target.
    expect(
      tester.getSize(find.byType(TextButton)).height,
      greaterThanOrEqualTo(AppSizes.minTapTarget),
    );
    // The strip is pale like the screens, so the status bar keeps the
    // theme's dark icons over it.
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);

    monitor.status.value = NetworkStatus.slow;
    await tester.pumpAndSettle();
    expect(stripText(), startsWith('Slow internet'));

    monitor.status.value = NetworkStatus.online;
    await tester.pump(const Duration(milliseconds: 500));
    expect(stripText(), startsWith('Back online'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(stripText(), isNull);
    expect(screenTop(), 24);
    // The screen was never rebuilt from scratch.
    expect(screen.currentState, same(screenState));
    expect(SystemChrome.latestStyle?.statusBarIconBrightness, Brightness.dark);
    semantics.dispose();
  });
}
