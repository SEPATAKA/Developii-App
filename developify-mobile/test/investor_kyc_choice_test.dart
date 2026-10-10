import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/selection_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'KYC choices preserve saved values and remain accessible at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final dependencies = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration.zero,
            mockScenario: MockScenario.incompleteKyc,
          ),
        );
        dependencies.session.signIn(
          const AppUser(
            id: 'kyc-choices',
            name: 'Sample Investor',
            email: 'sample@example.test',
          ),
          experience: Experience.investor,
        );
        final router = createAppRouter(
          dependencies,
          initialLocation: '/investor/kyc/trust/deed',
        );
        addTearDown(() async {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(dependencies.dispose);
        });
        await tester.pumpWidget(
          DevelopifyApp(dependencies: dependencies, router: router),
        );
        await tester.pumpAndSettle();
        Future<void> open(String label) async {
          final field = find.byKey(ValueKey('field-$label'));
          await tester.ensureVisible(field);
          await tester.tap(field);
          await tester.pumpAndSettle();
          expect(find.byType(SelectionSheetFrame), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        Future<void> choose(String label) async {
          final scrollable = find.descendant(
            of: find.byType(SelectionSheetFrame),
            matching: find.byType(Scrollable),
          );
          await tester.scrollUntilVisible(
            find.text(label).last,
            240,
            scrollable: scrollable,
          );
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(find.byType(SelectionSheetFrame), findsNothing);
          expect(tester.takeException(), isNull);
        }

        var store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        store.edit('masterOffice', 'Makhanda / Grahamstown');
        store.edit('trustType', 'Testamentary');
        await tester.pumpAndSettle();
        expect(find.text('Makhanda / Grahamstown (EC)'), findsOneWidget);
        expect(find.text('Testamentary (created by will)'), findsOneWidget);
        await open('Master of the High Court Office');
        await choose('Mbombela / Nelspruit (MP)');
        expect(
          store.draft!.values['masterOffice'],
          'Mbombela / Nelspruit (MP)',
        );
        await open('Trust Type');
        await choose('Special Trust Type B (minor relatives)');
        expect(
          store.draft!.values['trustType'],
          'Special Trust Type B (minor relatives)',
        );
        await open('Trust Type');
        await tester.tap(find.byKey(const ValueKey('selection-sheet-close')));
        await tester.pumpAndSettle();
        expect(
          store.draft!.values['trustType'],
          'Special Trust Type B (minor relatives)',
        );
        expect(store.saveAndExit(), isTrue);
        router.go('/investor/kyc/stokvel/bank');
        await tester.pumpAndSettle();
        store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        await open('Bank Type');
        await choose('Standard Bank');
        expect(store.draft!.values['bank'], 'Standard Bank');
        router.go('/investor/kyc/trust/deed');
        await tester.pumpAndSettle();
        store = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(
          store.draft!.values['masterOffice'],
          'Mbombela / Nelspruit (MP)',
        );
        expect(
          store.draft!.values['trustType'],
          'Special Trust Type B (minor relatives)',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
