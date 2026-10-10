import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/kyc_tax_screen.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<AppDependencies> dependencies() async {
    final deps = await AppDependencies.create(
      environment: const AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: MockScenario.incompleteKyc,
      ),
    );
    deps.session.signIn(
      const AppUser(
        id: 'tax-journey',
        name: 'Example Investor',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    return deps;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.byKey(ValueKey('field-$label'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String label, String value) async {
    await tap(tester, find.byKey(ValueKey('field-$label')));
    await tap(tester, find.text(value).last);
  }

  Future<void> date(WidgetTester tester, String label) async {
    await tap(tester, find.byKey(ValueKey('field-$label')));
    await tap(tester, find.text('OK'));
  }

  testWidgets(
    'tax residency and PEP branch saves and returns with documents and declarations',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final deps = await dependencies();
      final router = createAppRouter(
        deps,
        initialLocation: '/investor/kyc/individual/tax',
      );
      await tester.pumpWidget(
        DevelopifyApp(dependencies: deps, router: router),
      );
      await tester.pumpAndSettle();
      try {
        await select(tester, 'Country of tax residency', 'South Africa');
        await enter(tester, 'Tax Identification Number (TIN)', '1234567890');
        await tap(tester, find.text('I have a secondary tax residency'));
        expect(find.byType(KycTaxScreen), findsOneWidget);
        await enter(tester, 'Reasons for tax residency', 'Employment');
        await tap(tester, find.widgetWithText(AppButton, 'Cancel'));
        expect(find.byType(KycTaxScreen), findsNothing);
        expect(find.text('Add another residency'), findsNothing);
        await tap(tester, find.text('I have a secondary tax residency'));
        expect(find.byType(KycTaxScreen), findsOneWidget);
        expect(
          tester
              .widget<KycTaxScreen>(find.byType(KycTaxScreen))
              .store
              .draft!
              .values['secondaryReason'],
          'Employment',
        );
        await select(tester, 'Country of tax residency', 'United Kingdom');
        await enter(tester, 'Reasons for tax residency', 'Employment');
        await select(tester, 'TIN Type', 'Tax identification number');
        await enter(tester, 'TIN Format', '10 digits');
        await enter(tester, 'Tax Identification Number', '0123456789');
        await date(tester, 'Became resident on');
        await select(tester, 'Status', 'Current');
        await tap(tester, find.text(KycTaxPlan.certification));
        await tap(tester, find.widgetWithText(AppButton, 'Save & Continue'));
        expect(find.byType(KycTaxScreen), findsNothing);
        var main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(main.draft!.taxResidencies.single.country, 'United Kingdom');
        await tap(tester, find.text(KycTaxPlan.pepYes));
        await tap(tester, find.text('I am the PEP myself'));
        await tap(tester, find.text('Domestic'));
        await select(tester, 'Country of Office', 'South Africa');
        await enter(tester, 'Position / Title', 'Mayor');
        await enter(tester, 'Organisation / Department', 'City Council');
        await date(tester, 'Start Date');
        await select(tester, 'Status', 'Current');
        await tap(tester, find.widgetWithText(AppButton, 'Save & Continue'));
        expect(
          tester.widget<KycTaxScreen>(find.byType(KycTaxScreen)).section,
          KycTaxSection.wealth,
        );
        await enter(tester, 'Full Name of the PEP', 'Example Investor');
        await select(tester, 'Relationship', 'Self');
        await enter(
          tester,
          'Briefly describe how you accumulated the wealth you are investing',
          'Employment and savings',
        );
        await enter(tester, 'Estimated net worth (ZAR)', '1200000');
        await tap(tester, find.text('Choose a file'));
        await tap(tester, find.text('Choose Document'));
        var detail = tester
            .widget<KycTaxScreen>(find.byType(KycTaxScreen))
            .store;
        expect(
          detail.draft!.documents[KycTaxPlan.wealthDocument.key]?.mimeType,
          'application/pdf',
        );
        await tap(
          tester,
          find.bySemanticsLabel('Delete ${KycTaxPlan.wealthDocument.title}'),
        );
        await tap(tester, find.text('Delete').last);
        expect(detail.draft!.documents[KycTaxPlan.wealthDocument.key], isNull);
        await tap(tester, find.text('Choose a file'));
        await tap(tester, find.text('Choose Document'));
        await tap(tester, find.text(KycTaxPlan.sanctions));
        await tap(tester, find.text(KycTaxPlan.declaration));
        await tap(tester, find.widgetWithText(AppButton, 'Continue'));
        expect(find.text('Verification in Progress!'), findsOneWidget);
        await tap(tester, find.widgetWithText(AppButton, 'Continue').last);
        expect(find.byType(KycTaxScreen), findsNothing);
        main = tester.widget<KycScreen>(find.byType(KycScreen)).store;
        expect(main.draft!.values['pepName'], 'Example Investor');
        expect(main.draft!.taxResidencies.single.tin, '0123456789');
        expect(main.canContinue, isTrue);
        await tap(tester, find.widgetWithText(AppButton, 'Continue to review'));
        expect(main.selectedStep, 'review');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        await tester.runAsync(deps.dispose);
      }
    },
  );

  testWidgets('tax section and residency IDs have controlled errors', (
    tester,
  ) async {
    final deps = await dependencies();
    final router = createAppRouter(
      deps,
      initialLocation: '/investor/kyc/individual/tax/unknown',
    );
    await tester.pumpWidget(DevelopifyApp(dependencies: deps, router: router));
    await tester.pumpAndSettle();
    try {
      expect(
        find.text('This tax declaration section could not be found.'),
        findsOneWidget,
      );
      router.go('/investor/kyc/individual/tax/residency?residency=unknown');
      await tester.pumpAndSettle();
      expect(
        find.text('This tax residency could not be found.'),
        findsOneWidget,
      );
      await tap(tester, find.text('Try again'));
      expect(
        find.text('This tax residency could not be found.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(AppButton, 'Save & Continue'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      await tester.runAsync(deps.dispose);
    }
  });

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'tax branches retain keyboard drafts at $width and enlarged text',
      (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final deps = await dependencies();
        final router = createAppRouter(deps, initialLocation: '/investor/home');
        await tester.pumpWidget(
          DevelopifyApp(dependencies: deps, router: router),
        );
        try {
          for (final scale in [1.0, 1.6]) {
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            for (final (section, label, key) in [
              ('residency', 'Reasons for tax residency', 'secondaryReason'),
              ('pep', 'Position / Title', 'pepPosition'),
              ('wealth', 'Full Name of the PEP', 'pepName'),
            ]) {
              final path = '/investor/kyc/individual/tax/$section';
              router.go(path);
              await tester.pumpAndSettle();
              await enter(tester, label, 'Saved $section');
              tester.view.viewInsets = const FakeViewPadding(bottom: 320);
              await tester.pumpAndSettle();
              final field = find.byKey(ValueKey('field-$label'));
              await tester.ensureVisible(field);
              await tester.pumpAndSettle();
              final button = find.widgetWithText(AppButton, 'Save & Continue');
              expect(
                button.hitTestable(),
                findsOneWidget,
                reason: '$path $scale',
              );
              expect(tester.getRect(button).bottom, lessThanOrEqualTo(532));
              expect(tester.getRect(field).bottom, lessThanOrEqualTo(532));
              expect(tester.takeException(), isNull, reason: '$path $scale');
              FocusManager.instance.primaryFocus?.unfocus();
              tester.view.resetViewInsets();
              router.go('/investor/home');
              await tester.pumpAndSettle();
              router.go(path);
              await tester.pumpAndSettle();
              expect(
                tester
                    .widget<KycTaxScreen>(find.byType(KycTaxScreen))
                    .store
                    .draft!
                    .values[key],
                'Saved $section',
              );
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox());
          router.dispose();
          await tester.runAsync(deps.dispose);
        }
      },
    );
  }
}
