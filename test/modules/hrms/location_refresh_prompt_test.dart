import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_cubit.dart';
import 'package:railway_hrms/modules/hrms/bloc/work_area/work_area_state.dart';
import 'package:railway_hrms/modules/hrms/data/models/work_office.dart';
import 'package:railway_hrms/modules/hrms/widgets/location_refresh_prompt.dart';

import '../../helpers/pump_app.dart';

const _office = WorkOffice(
  id: 1,
  name: 'ONE Network',
  unit: '',
  center: LatLng(33.5892, 73.0465),
  radiusM: 200,
);

WorkAreaState _state({
  LatLng? at = const LatLng(33.5892, 73.0465),
  double accuracy = 10,
  Duration age = Duration.zero,
  bool refreshing = false,
  bool failed = false,
}) => WorkAreaState(
  loadingOffices: false,
  offices: const [_office],
  access: LocationAccess.ready,
  position: at,
  accuracyM: accuracy,
  positionAt: DateTime.now().subtract(age),
  refreshing: refreshing,
  refreshFailed: failed,
);

void main() {
  setUpAll(loadAppFonts);

  Future<void> show(WidgetTester tester, WorkAreaState state) => pumpScreen(
    tester,
    Scaffold(
      body: BlocProvider(
        create: (_) => WorkAreaCubit(fetch: () async => null),
        child: LocationRefreshPrompt(state: state),
      ),
    ),
  );

  testWidgets('inside the office, with a fresh fix, it says nothing', (
    tester,
  ) async {
    await show(tester, _state());
    expect(find.text('Refresh location'), findsNothing);
  });

  testWidgets('shown outside, it says what to do', (tester) async {
    await show(tester, _state(at: const LatLng(33.62, 73.06)));
    expect(find.text('Not where you are?'), findsOneWidget);
    expect(find.text('Refresh location'), findsOneWidget);
  });

  testWidgets('an old fix says how old it is', (tester) async {
    await show(tester, _state(age: const Duration(minutes: 3)));
    expect(find.text('Location from 3 min ago'), findsOneWidget);
  });

  testWidgets('a rough fix says how rough', (tester) async {
    await show(tester, _state(accuracy: 120));
    expect(find.text('Location is rough (±120 m)'), findsOneWidget);
  });

  testWidgets('while finding, the key is busy', (tester) async {
    await show(tester, _state(refreshing: true));
    expect(find.text('Finding your exact location…'), findsOneWidget);
  });

  testWidgets('a failed refresh says what to try', (tester) async {
    await show(tester, _state(failed: true));
    expect(find.text("Couldn't find your location"), findsOneWidget);
  });
}
