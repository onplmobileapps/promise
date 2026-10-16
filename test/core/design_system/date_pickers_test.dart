import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

final _today = DateTime(2026, 10, 10);

/// Holds what the calendar picks, as a screen does.
class _RangeHost extends StatefulWidget {
  const _RangeHost();

  @override
  State<_RangeHost> createState() => _RangeHostState();
}

class _RangeHostState extends State<_RangeHost> {
  DateTimeRange? picked;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: AppDateRangeCalendar(
        firstDate: _today,
        lastDate: DateTime(2026, 12, 31),
        today: _today,
        selected: picked,
        startLabel: 'From',
        endLabel: 'To',
        emptyLabel: 'Pick a day',
        startPrompt: 'Tap the first day',
        endPrompt: 'Now tap the last day',
        onChanged: (range) => setState(() => picked = range),
      ),
    ),
  );
}

void main() {
  group('AppDateRangeCalendar', () {
    DateTimeRange? pickedIn(WidgetTester tester) =>
        tester.state<_RangeHostState>(find.byType(_RangeHost)).picked;

    testWidgets('says which end is being picked, and moves on to the last', (
      tester,
    ) async {
      await pumpScreen(tester, const _RangeHost());
      expect(find.text('Tap the first day'), findsOneWidget);
      expect(find.text('Pick a day'), findsNWidgets(2));

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(
        pickedIn(tester),
        DateTimeRange(
          start: DateTime(2026, 10, 12),
          end: DateTime(2026, 10, 12),
        ),
      );
      expect(find.text('Now tap the last day'), findsOneWidget);

      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      expect(
        pickedIn(tester),
        DateTimeRange(
          start: DateTime(2026, 10, 12),
          end: DateTime(2026, 10, 15),
        ),
      );
      // Another tap moves the last day, not the first.
      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();
      expect(pickedIn(tester)!.start, DateTime(2026, 10, 12));
      expect(pickedIn(tester)!.end, DateTime(2026, 10, 17));
    });

    testWidgets('the first day can be changed from its tile', (tester) async {
      await pumpScreen(tester, const _RangeHost());
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('From'));
      await tester.pumpAndSettle();
      expect(find.text('Tap the first day'), findsOneWidget);
      // An earlier first day keeps the last.
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();
      expect(
        pickedIn(tester),
        DateTimeRange(
          start: DateTime(2026, 10, 11),
          end: DateTime(2026, 10, 15),
        ),
      );
      expect(find.text('Now tap the last day'), findsOneWidget);
    });
  });

  group('showAppDateTimeSheet', () {
    testWidgets('picks the day and keeps the time, on one sheet', (
      tester,
    ) async {
      DateTime? result;
      await pumpScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async => result = await showAppDateTimeSheet(
                  context: context,
                  title: 'Requested Check-Out',
                  closeLabel: 'Close',
                  doneLabel: 'Done',
                  timeLabel: 'Time',
                  initial: DateTime(2026, 10, 10, 17, 30),
                  firstDate: _today,
                  lastDate: _today.add(const Duration(days: 1)),
                  today: _today,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // The calendar and the time on the same sheet.
      expect(find.byType(AppDateRangeCalendar), findsOneWidget);
      expect(find.text('TIME'), findsOneWidget);

      // Past midnight: the next day.
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Done'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, DateTime(2026, 10, 11, 17, 30));
      expect(find.byType(AppDateRangeCalendar), findsNothing);
    });
  });
}
