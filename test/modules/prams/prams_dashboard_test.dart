import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/error/exceptions.dart';
import 'package:railway_hrms/core/utils/either.dart';
import 'package:railway_hrms/modules/prams/bloc/accident_cubit.dart';
import 'package:railway_hrms/modules/prams/data/accident_repository.dart';
import 'package:railway_hrms/modules/prams/screens/prams_dashboard_screen.dart';

import '../../helpers/pump_app.dart';

class _Cases implements AccidentRepository {
  @override
  Future<Either<AppException, Response>> loadAccidentList() async => Right(
    Response(
      requestOptions: RequestOptions(),
      data: {
        'status': 'success',
        'count': 3,
        'accidents': [
          {
            'id': 1,
            'train_number': '1',
            'train_direction': 'UP',
            'train_name': 'Khyber Mail',
            'accident_class_meaning': 'Derailment',
            'kilometer_number': '1280/04',
            'block_section_label': 'Rohri – Sukkur',
            'accident_date_time': '2026-10-04T10:20:00',
            'severity': 'CRITICAL',
            'status': 'UNDER_INVESTIGATION',
          },
          {
            'id': 2,
            'train_number': '40',
            'train_direction': 'DN',
            'train_name': 'Jaffar Express',
            'accident_class_meaning': 'Level crossing',
            'nearest_station_name': 'Sibi',
            'accident_date_time': '2026-10-02T08:00:00',
            'severity': 'MODERATE',
            'status': 'REPORTED',
          },
          {
            'id': 3,
            'train_number': '7',
            'train_direction': 'UP',
            'train_name': 'Tezgam',
            'accident_class_meaning': 'Fire',
            'accident_date_time': '2026-09-20T08:00:00',
            'severity': 'MINOR',
            'status': 'CLOSED',
          },
        ],
      },
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadAppFonts);

  test('reads severities and stages as the server words them', () {
    expect(AccidentSeverity.of('CRITICAL'), AccidentSeverity.critical);
    expect(AccidentSeverity.of('major'), AccidentSeverity.critical);
    expect(AccidentSeverity.of('Moderate'), AccidentSeverity.moderate);
    expect(AccidentSeverity.of(null), AccidentSeverity.minor);
    expect(AccidentStage.of('REPORTED'), AccidentStage.reported);
    expect(AccidentStage.of('UNDER_INVESTIGATION'), AccidentStage.relief);
    expect(AccidentStage.of('closed'), AccidentStage.cleared);
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(393, 852),
  }) async {
    final cubit = AccidentCubit(repository: _Cases())..loadAccidentList();
    addTearDown(cubit.close);
    await pumpScreen(
      tester,
      PramsDashboardScreen(cubit: cubit, now: () => DateTime(2026, 10, 5)),
      size: size,
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows the report card, the month and the cases', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Report an accident'), findsOneWidget);
    expect(find.text('Report accident'), findsOneWidget);
    expect(find.text('THIS MONTH'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1UP Khyber Mail · Derailment'),
      200,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(find.text('KM 1280/04 · Rohri – Sukkur'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a severity shows only its cases', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Moderate').first);
    await tester.tap(find.text('Moderate').first);
    await tester.pump();
    expect(find.textContaining('Khyber Mail'), findsNothing);
    expect(find.textContaining('Jaffar Express'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fits a small phone', (tester) async {
    await pump(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
