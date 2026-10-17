import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

/// Hands its loop out to the test.
class _Looper extends StatefulWidget {
  const _Looper({required this.onLoop});

  final ValueChanged<AppLoop> onLoop;

  @override
  State<_Looper> createState() => _LooperState();
}

class _LooperState extends State<_Looper> with AppLoopsMixin {
  late final AppLoop _pulse = loop(const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    widget.onLoop(_pulse);
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  tearDown(() => AppPerformance.debugBudget = RenderBudget.full);

  Future<(AppLoop, List<int>)> pumpLoop(
    WidgetTester tester, {
    bool covered = false,
  }) async {
    late AppLoop pulse;
    final drawn = [0];
    await tester.pumpWidget(
      TickerMode(
        enabled: !covered,
        child: _Looper(
          onLoop: (loop) => pulse = loop..addListener(() => drawn[0]++),
        ),
      ),
    );
    return (pulse, drawn);
  }

  testWidgets('a loop is drawn on its clock, not every frame', (tester) async {
    final (_, drawn) = await pumpLoop(tester);
    await tester.pump(const Duration(seconds: 1));
    // 60 a second with drawing to spare…
    expect(drawn[0], inInclusiveRange(58, 61));

    // …and 30 on a phone drawing at a steady 60 frames a second.
    AppPerformance.debugBudget = RenderBudget.steady;
    drawn[0] = 0;
    await tester.pump(const Duration(seconds: 1));
    expect(drawn[0], inInclusiveRange(28, 31));

    // …and fewer still on one drawing lite.
    AppPerformance.debugBudget = RenderBudget.lite;
    drawn[0] = 0;
    await tester.pump(const Duration(seconds: 1));
    expect(drawn[0], inInclusiveRange(22, 25));
  });

  testWidgets('a loop on a covered screen rests', (tester) async {
    final (pulse, drawn) = await pumpLoop(tester, covered: true);
    await tester.pump(const Duration(seconds: 1));
    expect(drawn[0], 0);
    expect(pulse.status, AnimationStatus.dismissed);
  });

  testWidgets('a stopped loop rests where it is told and goes on from there', (
    tester,
  ) async {
    final (pulse, drawn) = await pumpLoop(tester);
    pulse.stop(at: 0.4);
    final before = drawn[0];
    await tester.pump(const Duration(seconds: 1));
    expect(drawn[0], before);
    expect(pulse.value, 0.4);

    pulse.start();
    // Taken up from where it rested, not from the top.
    expect(pulse.value, closeTo(0.4, 0.05));
    await tester.pump(const Duration(milliseconds: 100));
    expect(drawn[0], greaterThan(before));
  });

  testWidgets('a loop leaves no clock running once its screen goes', (
    tester,
  ) async {
    await pumpLoop(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    // The test would fail on a timer left running.
  });
}
