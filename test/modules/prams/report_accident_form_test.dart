import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/di/service_locator.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/screens/accident_report_form.dart';

import '../../helpers/pump_app.dart';

/// No trains or classes come back; the form still lays out.
class _Offline implements AccidentRepository {
  @override
  Future<Either<AppException, Response>> loadAccidentTrainsData() async =>
      Left(AppException('offline'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => sl.registerFactory<AccidentRepository>(_Offline.new));
  tearDown(sl.reset);

  for (final size in [const Size(320, 568), const Size(393, 852)]) {
    testWidgets('the report form lays out at $size', (tester) async {
      await pumpScreen(tester, const AccidentReportingScreen(), size: size);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('Report accident'), findsOneWidget);
      expect(find.text('Train and place'), findsOneWidget);
      expect(find.text('Submit report'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Dangerous goods'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('ticking a condition shows it ticked', (tester) async {
    await pumpScreen(tester, const AccidentReportingScreen());
    await tester.pump(const Duration(seconds: 1));
    await tester.scrollUntilVisible(
      find.text('People injured'),
      200,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.text('People injured'));
    await tester.pump(const Duration(milliseconds: 300));
    // The count of people hurt is asked for once it is ticked.
    expect(find.text('Number of Injured'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
