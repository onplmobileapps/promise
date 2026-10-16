import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';

import '../../helpers/pump_app.dart';

/// A secret field's eye, holding whether the text shows.
class _Field extends StatefulWidget {
  const _Field();

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool visible = false;

  @override
  Widget build(BuildContext context) => Center(
    child: AppVisibilityToggle(
      visible: visible,
      showLabel: 'Show password',
      hideLabel: 'Hide password',
      onPressed: () => setState(() => visible = !visible),
    ),
  );
}

void main() {
  testWidgets('the eye says what it will do, and does it', (tester) async {
    await pumpScreen(tester, const _Field());
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);

    await tester.tap(find.byType(AppVisibilityToggle));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(AppVisibilityToggle));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Show password'), findsOneWidget);
  });
}
