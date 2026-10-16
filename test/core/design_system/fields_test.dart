import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  AppFieldState stateOf(WidgetTester tester) =>
      tester.widget<AppFieldFrame>(find.byType(AppFieldFrame).first).state;

  group('AppTextField', () {
    Future<(GlobalKey<FormState>, TextEditingController)> pumpField(
      WidgetTester tester,
    ) async {
      final form = GlobalKey<FormState>();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpScreen(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: form,
              child: AppTextField(
                controller: controller,
                label: 'Employee ID',
                hint: 'e.g. 10482',
                glyph: AppGlyphs.idCard,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Employee ID is required' : null,
              ),
            ),
          ),
        ),
      );
      return (form, controller);
    }

    testWidgets('lifts into a ring while focused', (tester) async {
      await pumpField(tester);
      expect(stateOf(tester), AppFieldState.idle);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(stateOf(tester), AppFieldState.focused);
    });

    testWidgets('shows its error below and clears it when fixed', (
      tester,
    ) async {
      final (form, _) = await pumpField(tester);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(stateOf(tester), AppFieldState.error);
      expect(find.text('Employee ID is required'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '10482');
      expect(form.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Employee ID is required'), findsNothing);
    });

    testWidgets('keeps the form and the controller in step', (tester) async {
      final (form, controller) = await pumpField(tester);
      controller.text = '777';
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.reset();
      expect(controller.text, isEmpty);
    });

    testWidgets('reads its label with what is typed', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpField(tester);
      final node = tester.getSemantics(find.byType(TextField));
      expect(node, isSemantics(isTextField: true));
      // The hint follows the label while the field is empty.
      expect(node.label, startsWith('Employee ID'));
      semantics.dispose();
    });
  });

  group('AppSwitch', () {
    testWidgets('flips, says whether it is on, and can be disabled', (
      tester,
    ) async {
      var value = false;
      await pumpScreen(
        tester,
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: AppSwitch(
              value: value,
              label: 'Biometric sign-in',
              onChanged: (on) => setState(() => value = on),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AppSwitch)),
        isSemantics(label: 'Biometric sign-in', isToggled: false),
      );
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(
        tester.getSize(find.byType(AppSwitch)).height,
        greaterThanOrEqualTo(AppSizes.minTapTarget),
      );

      await pumpScreen(
        tester,
        const Center(child: AppSwitch(value: true, onChanged: null)),
      );
      await tester.tap(find.byType(AppSwitch));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('AppFilterChips picks one and shows counts', (tester) async {
    var picked = 'all';
    await pumpScreen(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: AppFilterChips<String>(
            selected: picked,
            onSelected: (value) => setState(() => picked = value),
            options: const [
              AppFilterOption(value: 'all', label: 'All'),
              AppFilterOption(value: 'leave', label: 'Leave', count: 2),
            ],
          ),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Leave'));
    await tester.pump();
    expect(picked, 'leave');
  });

  testWidgets('AppProgressSteps fits its labels on the narrowest phone', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Padding(
        padding: EdgeInsets.all(20),
        child: AppProgressSteps(
          steps: ['Reported', 'Acknowledged', 'Relief', 'Cleared'],
          current: 2,
        ),
      ),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
