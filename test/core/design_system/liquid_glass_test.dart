import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

/// Remembers how often it was made, to tell a kept state from a new one.
class _Counter extends StatefulWidget {
  const _Counter();

  static int made = 0;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    _Counter.made++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

double _glassOf(WidgetTester tester, Finder within) {
  final glass = find.descendant(
    of: within,
    matching: find.byType(AppLiquidGlass),
  );
  return tester.widget<AppLiquidGlass>(glass.first).amount;
}

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets('turning swipe-back on or off keeps the page it wraps', (
    tester,
  ) async {
    _Counter.made = 0;
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    await pumpScreen(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (context, on, _) =>
            AppSwipeBack(enabled: on, onBack: () {}, child: const _Counter()),
      ),
    );
    enabled.value = true;
    await tester.pump();
    enabled.value = false;
    await tester.pump();
    expect(_Counter.made, 1);
  });

  testWidgets('a swipe that starts keeps the page it wraps', (tester) async {
    _Counter.made = 0;
    await pumpScreen(
      tester,
      AppSwipeBack(onBack: () {}, child: const _Counter()),
    );
    final gesture = await tester.startGesture(const Offset(5, 400));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_Counter.made, 1);
  });

  testWidgets('a switch turns to glass on its way and back to a knob', (
    tester,
  ) async {
    final value = ValueNotifier(false);
    addTearDown(value.dispose);
    await pumpScreen(
      tester,
      Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: value,
          builder: (context, on, _) =>
              AppSwitch(value: on, onChanged: (next) => value.value = next),
        ),
      ),
    );
    final toggle = find.byType(AppSwitch);
    expect(_glassOf(tester, toggle), 0);
    await tester.tap(toggle);
    await _frames(tester, 8);
    expect(_glassOf(tester, toggle), greaterThan(0.5));
    await tester.pumpAndSettle();
    expect(value.value, isTrue);
    expect(_glassOf(tester, toggle), 0);
  });

  testWidgets('a picked chip flashes glass that melts away', (tester) async {
    final picked = ValueNotifier('a');
    addTearDown(picked.dispose);
    await pumpScreen(
      tester,
      Center(
        child: ValueListenableBuilder<String>(
          valueListenable: picked,
          builder: (context, value, _) => AppFilterChips<String>(
            options: const [
              AppFilterOption(value: 'a', label: 'A'),
              AppFilterOption(value: 'b', label: 'B'),
            ],
            selected: value,
            onSelected: (next) => picked.value = next,
          ),
        ),
      ),
    );
    final chip = find.byType(LiquidPop).last;
    await tester.tap(find.text('B'));
    await _frames(tester, 8);
    expect(_glassOf(tester, chip), greaterThan(0.5));
    await tester.pumpAndSettle();
    expect(_glassOf(tester, chip), 0);
  });

  testWidgets('a pressed button shows glass and lets it melt', (tester) async {
    await pumpScreen(
      tester,
      Center(
        child: AppButton(label: 'Go', onPressed: () {}),
      ),
    );
    final button = find.byType(AppButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await _frames(tester, 12);
    expect(_glassOf(tester, button), greaterThan(0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_glassOf(tester, button), 0);
  });
}
