import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railway_hrms/core/design_system/design_system.dart';
import 'package:railway_hrms/core/l10n/l10n.dart';
import 'package:railway_hrms/core/utils/validators.dart';

import '../../helpers/pump_app.dart';

/// WCAG contrast ratio of [a] over [b]; a translucent [a] is first laid
/// over [b], as it would be on screen.
double contrast(Color a, Color b) {
  final la = Color.alphaBlend(a, b).computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(loadAppFonts);

  group('colour roles read clearly', () {
    for (final (name, colors) in [
      ('light', AppColors.light),
      ('dark', AppColors.dark),
    ]) {
      test('$name: text on the page and on cards meets WCAG AA', () {
        for (final surface in [colors.background, colors.surface]) {
          expect(contrast(colors.textPrimary, surface), greaterThan(7));
          expect(contrast(colors.textSecondary, surface), greaterThan(4.5));
          expect(contrast(colors.textTertiary, surface), greaterThan(3));
        }
      });

      test('$name: labels on keys and tints meet WCAG AA', () {
        expect(contrast(colors.onPrimary, colors.primary), greaterThan(4.5));
        expect(
          contrast(colors.onDangerContainer, colors.surface),
          greaterThan(4.5),
        );
        // Tints may be translucent; they sit on a card.
        Color onCard(Color tint) => Color.alphaBlend(tint, colors.surface);
        expect(
          contrast(colors.onPrimaryContainer, onCard(colors.primaryContainer)),
          greaterThan(4.5),
        );
        expect(
          contrast(colors.onGoldContainer, onCard(colors.goldContainer)),
          greaterThan(4.5),
        );
        expect(
          contrast(colors.onDangerContainer, onCard(colors.dangerContainer)),
          greaterThan(4.5),
        );
      });
    }
  });

  group('window size classes', () {
    test('split at 600 and 840', () {
      expect(WindowSizeClass.fromWidth(320), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(599), WindowSizeClass.compact);
      expect(WindowSizeClass.fromWidth(600), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(839), WindowSizeClass.medium);
      expect(WindowSizeClass.fromWidth(840), WindowSizeClass.expanded);
    });

    test('a short height is one under 560', () {
      expect(
        const LayoutInfo(BoxConstraints(maxWidth: 852, maxHeight: 393)).isShort,
        isTrue,
      );
      expect(
        const LayoutInfo(BoxConstraints(maxWidth: 393, maxHeight: 852)).isShort,
        isFalse,
      );
    });
  });

  group('mobile numbers', () {
    test('takes only 03 and nine more digits', () {
      expect(isValidPakistaniMobile('03001234567'), isTrue);
      expect(isValidPakistaniMobile(' 03451234567 '), isTrue);
      expect(isValidPakistaniMobile('3001234567'), isFalse);
      expect(isValidPakistaniMobile('0300123456'), isFalse);
      expect(isValidPakistaniMobile('030012345678'), isFalse);
      expect(isValidPakistaniMobile('04001234567'), isFalse);
      expect(isValidPakistaniMobile('0300-1234567'), isFalse);
    });

    test('says what is wrong with one', () {
      expect(mobileNumberProblem(''), MobileNumberProblem.empty);
      expect(mobileNumberProblem('   '), MobileNumberProblem.empty);
      expect(mobileNumberProblem('3'), MobileNumberProblem.prefix);
      expect(mobileNumberProblem('04'), MobileNumberProblem.prefix);
      expect(mobileNumberProblem('3001234567'), MobileNumberProblem.prefix);
      expect(mobileNumberProblem('03a'), MobileNumberProblem.prefix);
      // Too short to judge its start yet, or just short.
      expect(mobileNumberProblem('0'), MobileNumberProblem.length);
      expect(mobileNumberProblem('0300'), MobileNumberProblem.length);
      expect(mobileNumberProblem('030012345678'), MobileNumberProblem.length);
      expect(mobileNumberProblem('03001234567'), isNull);
    });

    test('formats them for reading', () {
      expect(formatPakistaniMobile('03001234567'), '+92 300 1234567');
      expect(formatPakistaniMobile('3001234567'), '+92 300 1234567');
      expect(formatPakistaniMobile('123'), '123');
    });
  });

  group('AppButton', () {
    testWidgets('sinks onto its edge while pressed, without changing size', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: Center(
            child: AppButton(label: 'Continue', onPressed: () {}),
          ),
        ),
      );
      final face = find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(DecoratedBox),
      );
      final restingSize = tester.getSize(find.byType(AppButton));
      final restingTop = tester.getTopLeft(face).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(AppButton)), restingSize);
      expect(
        tester.getTopLeft(face).dy,
        restingTop + AppSizes.keyEdge - AppSizes.keyEdgePressed,
      );
      await gesture.up();
      await tester.pump();
      expect(tester.getTopLeft(face).dy, restingTop);
    });

    testWidgets('ignores taps while disabled or loading', (tester) async {
      var taps = 0;
      await pumpScreen(
        tester,
        Scaffold(
          body: Column(
            children: [
              const AppButton(label: 'Disabled', onPressed: null),
              AppButton(
                label: 'Saving',
                isLoading: true,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Disabled'));
      await tester.tap(find.text('Saving'));
      expect(taps, 0);
    });

    testWidgets('is a 48 dp tap target and announces itself as a button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(
        tester,
        Scaffold(
          body: Center(
            child: AppButton(
              label: 'Verify',
              variant: AppButtonVariant.text,
              expand: false,
              onPressed: () {},
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(AppButton));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Verify')),
        matchesSemantics(
          label: 'Verify',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
    });
  });

  group('AppDialog', () {
    for (final (label, expected) in [('Log out', true), ('Cancel', false)]) {
      testWidgets('resolves to $expected for "$label"', (tester) async {
        bool? result;
        await pumpScreen(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Open',
                  onPressed: () async {
                    result = await showAppDialog(
                      context: context,
                      tone: AppDialogTone.confirm,
                      title: 'Log out of PROMISE?',
                      message: 'You can sign in again with your PIN.',
                      primaryLabel: 'Log out',
                      secondaryLabel: 'Cancel',
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(result, expected);
      });
    }

    testWidgets('a long message scrolls instead of overflowing', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: AppDialog(
            tone: AppDialogTone.error,
            title: 'Fake location detected',
            message: 'Turn off any fake GPS app. ' * 40,
            primaryLabel: 'Try again',
            secondaryLabel: 'Close',
          ),
        ),
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      // The message scrolls; the actions stay on screen to be tapped.
      for (final action in ['Try again', 'Close']) {
        final button = tester.getRect(find.text(action));
        expect(button.bottom, lessThanOrEqualTo(568), reason: action);
        await tester.tap(find.text(action));
      }
    });
  });

  group('system bars', () {
    test('stay clear, with icons that suit the theme', () {
      for (final (theme, icons) in [
        (Brightness.light, Brightness.dark),
        (Brightness.dark, Brightness.light),
      ]) {
        final style = AppSystemUi.of(theme);
        expect(style.statusBarIconBrightness, icons);
        expect(style.systemNavigationBarIconBrightness, icons);
        // iOS takes the brightness of what is under the bar instead.
        expect(style.statusBarBrightness, theme);
        expect(style.statusBarColor?.a, 0);
        expect(style.systemNavigationBarColor?.a, 0);
      }
      expect(
        AppThemeData.light.appBarTheme.systemOverlayStyle,
        AppSystemUi.lightTheme,
      );
      expect(
        AppThemeData.dark.appBarTheme.systemOverlayStyle,
        AppSystemUi.darkTheme,
      );
    });

    testWidgets('go back to the theme once a screen stops styling them', (
      tester,
    ) async {
      Widget app(ThemeData theme, {required bool styled}) => MaterialApp(
        theme: theme,
        builder: (context, child) => AppFrame(child: child!),
        home: Column(
          children: [
            // Like a strip in a strong colour, under the status bar.
            if (styled)
              const AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: SizedBox(height: 80, width: double.infinity),
              ),
          ],
        ),
      );

      await tester.pumpWidget(app(AppThemeData.light, styled: true));
      expect(
        SystemChrome.latestStyle?.statusBarIconBrightness,
        Brightness.light,
      );
      await tester.pumpWidget(app(AppThemeData.light, styled: false));
      expect(SystemChrome.latestStyle, AppSystemUi.lightTheme);
      await tester.pumpWidget(app(AppThemeData.dark, styled: false));
      // The app eases from one theme to the other.
      await tester.pumpAndSettle();
      expect(SystemChrome.latestStyle, AppSystemUi.darkTheme);
    });
  });

  group('BalancedText', () {
    const tagline =
        'Operations management and integrated services for Pakistan Railways';

    Future<Size> laidOut(WidgetTester tester, Widget text) async {
      await pumpScreen(
        tester,
        Material(
          child: Center(child: SizedBox(width: 244, child: text)),
        ),
      );
      return tester.getSize(find.byType(RichText));
    }

    testWidgets('evens out the lines without adding one', (tester) async {
      final style = AppThemeData.light.textTheme.bodyMedium;
      final plain = await laidOut(
        tester,
        Text(tagline, style: style, textAlign: TextAlign.center),
      );
      final balanced = await laidOut(
        tester,
        BalancedText(tagline, style: style),
      );
      // As many lines, in a narrower measure.
      expect(balanced.height, plain.height);
      expect(balanced.width, lessThan(plain.width - 20));
    });

    testWidgets('keeps the lines even at every text scale', (tester) async {
      for (final scale in textScales) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        final style = AppThemeData.light.textTheme.bodyMedium;
        final plain = await laidOut(
          tester,
          Text(tagline, style: style, textAlign: TextAlign.center),
        );
        final balanced = await laidOut(
          tester,
          BalancedText(tagline, style: style),
        );
        expect(balanced.height, plain.height, reason: 'text x$scale');
        expect(balanced.width, lessThanOrEqualTo(plain.width));
      }
    });

    testWidgets('lays out where width is unlimited', (tester) async {
      await pumpScreen(
        tester,
        const Material(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [BalancedText('PROMISE')],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('PROMISE'), findsOneWidget);
    });
  });

  group('AppMedallion', () {
    for (final (name, theme) in [
      ('light', AppThemeData.light),
      ('dark', AppThemeData.dark),
    ]) {
      testWidgets('$name: paints at every size, with and without its orbit '
          'and glow', (tester) async {
        for (final diameter in [
          AppSizes.medallionMin,
          AppSizes.medallionDesign,
          AppSizes.medallionMax,
        ]) {
          for (final (orbit, glow) in [
            (true, true),
            (false, true),
            (true, false),
            (false, false),
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Center(
                  child: AppMedallion(
                    diameter: diameter,
                    showOrbit: orbit,
                    showGlow: glow,
                    child: const AppEmblem(),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            final medallion = tester.getSize(find.byType(AppMedallion));
            final dome = tester.getRect(find.byType(AppDome));
            final emblem = tester.getRect(find.byType(AppEmblem));
            // The orbit circles the glass ring; without it the ring is
            // the whole medallion.
            expect(
              medallion.width,
              moreOrLessEquals(diameter * (orbit ? 170 / 150 : 1)),
            );
            expect(dome.width, moreOrLessEquals(diameter * 112 / 150));
            // The emblem fills the dome's middle, centred on it.
            expect(
              emblem.width,
              moreOrLessEquals(dome.width * AppSizes.domeContent),
            );
            expect(emblem.center.dx, moreOrLessEquals(dome.center.dx));
            expect(emblem.center.dy, moreOrLessEquals(dome.center.dy));
          }
        }
      });
    }

    test('fits the screen within its bounds', () {
      expect(AppMedallion.diameterFor(200), AppSizes.medallionMin);
      expect(AppMedallion.diameterFor(390), moreOrLessEquals(150, epsilon: 1));
      expect(AppMedallion.diameterFor(1024), AppSizes.medallionMax);
    });

    test('shadows scale with what casts them', () {
      const shadow = BoxShadow(
        offset: Offset(0, 6),
        blurRadius: 10,
        spreadRadius: -4,
      );
      final scaled = [shadow].scaled(0.5).single;
      expect(scaled.offset, const Offset(0, 3));
      expect(scaled.blurRadius, 5);
      expect(scaled.spreadRadius, -2);
    });

    testWidgets('inset shadows paint inside any shape', (tester) async {
      for (final shape in const <ShapeBorder>[
        CircleBorder(),
        RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
        StadiumBorder(),
      ]) {
        await tester.pumpWidget(
          Center(
            child: CustomPaint(
              painter: InsetShadowPainter(
                shape: shape,
                shadows: AppElevations.light.domeInset,
              ),
              size: const Size(120, 60),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
      const painter = InsetShadowPainter(shadows: []);
      expect(
        painter.shouldRepaint(const InsetShadowPainter(shadows: [])),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          const InsetShadowPainter(shadows: [], shape: StadiumBorder()),
        ),
        isTrue,
      );
    });
  });

  group('AppSelectField', () {
    Future<GlobalKey<FormState>> pumpField(
      WidgetTester tester, {
      ValueChanged<_Leave>? onChanged,
    }) async {
      final form = GlobalKey<FormState>();
      await pumpScreen(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: form,
              child: AppSelectField<_Leave>(
                label: 'Leave type',
                hint: 'Choose a leave type',
                glyph: AppGlyphs.calendar,
                options: _Leave.values,
                optionLabel: (leave) => leave.label,
                optionLeading: (context, leave, size) =>
                    Icon(leave.icon, size: size),
                validator: (leave) =>
                    leave == null ? 'Choose a leave type first' : null,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
      return form;
    }

    testWidgets('validates like a text field', (tester) async {
      final form = await pumpField(tester);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Choose a leave type first'), findsOneWidget);
    });

    testWidgets('picks any kind of option from a sheet, and ticks it when '
        'opened again', (tester) async {
      final picked = <_Leave>[];
      final form = await pumpField(tester, onChanged: picked.add);

      await tester.tap(find.text('Choose a leave type'));
      await tester.pumpAndSettle();
      expect(find.byType(AppSheet), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      await tester.tap(find.text('Sick'));
      await tester.pumpAndSettle();

      expect(picked, [_Leave.sick]);
      expect(form.currentState!.validate(), isTrue);
      expect(find.byType(AppSheet), findsNothing);
      // The choice shows in the field, with its mark.
      expect(find.text('Sick'), findsOneWidget);
      expect(find.byIcon(Icons.sick_outlined), findsOneWidget);

      await tester.tap(find.text('Sick'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ListTile>(
              find.ancestor(
                of: find.text('Sick').last,
                matching: find.byType(ListTile),
              ),
            )
            .selected,
        isTrue,
      );
      // Closing without a choice keeps the one made.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(picked, [_Leave.sick]);
      expect(find.text('Sick'), findsOneWidget);
    });

    testWidgets('lays out on every screen and text size', (tester) async {
      for (final (name, size, scale, platform) in layoutMatrix()) {
        await pumpScreen(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AppSelectField<_Leave>(
                label: 'Leave type',
                hint: 'Choose a leave type',
                glyph: AppGlyphs.calendar,
                options: _Leave.values,
                optionLabel: (leave) => leave.label,
                initialValue: _Leave.annual,
              ),
            ),
          ),
          size: size,
          textScale: scale,
          platform: platform,
        );
        expect(tester.takeException(), isNull, reason: name);
      }
    });
  });

  testWidgets('the khatam pattern paints on any size', (tester) async {
    for (final size in [Size.zero, const Size(10, 10), const Size(800, 600)]) {
      await pumpScreen(
        tester,
        CustomPaint(
          size: size,
          painter: const KhatamPatternPainter(color: Color(0x33000000)),
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });
}

/// A stand-in option type, to show the select field works for any.
enum _Leave {
  annual('Annual', Icons.beach_access_outlined),
  sick('Sick', Icons.sick_outlined),
  casual('Casual', Icons.free_breakfast_outlined);

  const _Leave(this.label, this.icon);

  final String label;
  final IconData icon;
}
