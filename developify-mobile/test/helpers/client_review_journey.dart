import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/domain/account_summary.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/portfolio_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/project_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/landowner/presentation/home_screen.dart';
import 'package:developify_mobile/features/landowner/presentation/submission_screen.dart';
import 'qa_credentials.dart';

typedef ReviewCapture = Future<void> Function(WidgetTester tester, String name);

void registerClientReviewJourney({
  Future<AppDependencies> Function(WidgetTester)? launch,
  ReviewCapture? capture,
  Size? surfaceSize,
}) {
  testWidgets(
    'Client corrections through normal startup and both experiences',
    (tester) async {
      if (surfaceSize != null) {
        tester.view.physicalSize = surfaceSize;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
      }
      Future<void> reveal(Finder target) async {
        if (target.evaluate().isEmpty) {
          final scrollable = find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .hitTestable()
              .first;
          tester.state<ScrollableState>(scrollable).position.jumpTo(0);
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            target,
            220,
            maxScrolls: 35,
            scrollable: scrollable,
          );
        }
        if (target.hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(target);
        }
        await tester.pumpAndSettle();
      }

      var capturedLandownerSplash = false;
      Future<void> tap(Finder target) async {
        await reveal(target);
        await tester.tap(target);
        await tester.pump();
        if (find.text('Landowner Portal').evaluate().isNotEmpty) {
          if (!capturedLandownerSplash) {
            await capture?.call(tester, '14b-landowner-switch-splash');
            capturedLandownerSplash = true;
          }
          await tester.pump(const Duration(milliseconds: 700));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> enter(Finder target, String text) async {
        await reveal(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        await tester.enterText(target, text);
        await tester.pump();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }

      Future<void> shot(String name) async {
        expect(tester.takeException(), isNull, reason: name);
        debugPrint('Client review checkpoint: $name');
        await capture?.call(tester, name);
      }

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }

      Future<void> pin() async {
        await tap(find.text('Use PIN Instead'));
        for (final digit in '1234'.split('')) {
          await tap(find.widgetWithText(TextButton, digit));
        }
      }

      final AppDependencies deps;
      if (launch != null) {
        deps = await launch(tester);
      } else {
        deps = await AppDependencies.create(
          environment: const AppEnvironment(
            mockDelay: Duration(milliseconds: 10),
          ),
        );
        await tester.pumpWidget(DevelopifyApp(dependencies: deps));
      }
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(deps.dispose);
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      if (!deps.session.isAuthenticated) {
        if (find.text('Get started').evaluate().isNotEmpty) {
          await shot('01-normal-investor-onboarding');
          await tap(find.text('Get started'));
          await tap(find.byKey(const ValueKey('terms-declaration')));
          await tap(find.widgetWithText(AppButton, 'Continue'));
          await tap(find.text('I already have an account'));
        }
        await enter(
          find.byKey(const ValueKey('field-Email Address')),
          QaCredentials.email,
        );
        await enter(
          find.byKey(const ValueKey('field-Password')),
          QaCredentials.password,
        );
        await tap(find.byKey(const ValueKey('auth-submit')));
      }
      expect(find.byType(InvestorHomeScreen), findsOneWidget);
      final user = deps.session.user;
      expect(user, isNotNull);
      final router = GoRouter.of(
        tester.element(find.byType(InvestorHomeScreen)),
      );
      final catalog =
          deps.container<InvestorCatalogRepository>()
              as MockInvestorCatalogRepository;
      final account = deps.container<InvestorAccountRepository>();
      var home = tester
          .widget<InvestorHomeScreen>(find.byType(InvestorHomeScreen))
          .store;
      final originalSummary = InvestorAccountSummary.from(home.data!);
      await shot('02-home-zar');
      await tap(find.bySemanticsLabel('Save Marula Heights'));
      expect(router.state.uri.path, '/investor/home');
      expect(catalog.favouriteIds, contains('marula-heights'));
      await tap(find.text('Explore').last);
      expect(catalog.favouriteIds, contains('marula-heights'));
      await tap(find.text('Coastline Villas'));
      expect(
        tester
            .widget<InvestorProjectScreen>(find.byType(InvestorProjectScreen))
            .store
            .project!
            .fullyFunded,
        true,
      );
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Invest Now'))
            .onPressed,
        isNull,
      );
      await shot('02b-normal-catalogue-fully-funded');
      await tap(find.widgetWithText(TextButton, 'Updates'));
      await shot('02c-funded-updates');
      await back();
      await tap(find.widgetWithText(TextButton, 'Documents'));
      await shot('02d-funded-documents');
      await back();
      await tap(find.text('Home').last);
      expect(
        find.bySemanticsLabel('Remove Marula Heights from favourites'),
        findsOneWidget,
      );
      final homeScroll = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      tester.state<ScrollableState>(homeScroll).position.jumpTo(0);
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(InvestorBalanceHeader));
      await tap(find.bySemanticsLabel('Hide balance'));
      expect(tester.getRect(find.byType(InvestorBalanceHeader)), rect);
      expect(find.text('Projected returns hidden'), findsOneWidget);
      await shot('03-home-private-favourite');
      await tap(find.text('Try the investment calculator'));
      expect(find.text('Select a project'), findsOneWidget);
      await back();
      expect(home.balanceVisible, false);
      await tap(find.text('Try the investment calculator'));
      await shot('04-project-selection');
      await tap(
        find.byKey(const ValueKey('calculator-project-marula-heights')),
      );
      final input = find.byKey(const ValueKey('investor-amount'));
      await enter(input, '0.99');
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Invest this amount'),
            )
            .onPressed,
        isNull,
      );
      await enter(input, '26000');
      expect(
        tester
            .widget<InvestmentScreen>(find.byType(InvestmentScreen))
            .store
            .amount,
        const MonetaryAmount(2600000, Currency.zar),
      );
      await reveal(find.text(InvestmentPolicy.calculatorDisclaimer));
      expect(find.text('36 months'), findsOneWidget);
      expect(find.text('R314.16–R314.17 × 36'), findsOneWidget);
      await shot('05-calculator-36-months');
      await tap(find.widgetWithText(AppButton, 'Invest this amount'));
      expect(router.state.uri.path, '/investor/projects/marula-heights/invest');
      expect(router.state.uri.queryParameters['amountCents'], '2600000');
      InvestmentScreen investment() =>
          tester.widget<InvestmentScreen>(find.byType(InvestmentScreen));
      expect(
        investment().store.amount,
        const MonetaryAmount(2600000, Currency.zar),
      );
      await tap(find.widgetWithText(AppButton, 'Review Investment'));
      await tap(find.text('Top up wallet'));
      await tap(find.text('Bank Transfer'));
      await tap(find.widgetWithText(AppButton, 'Continue'));
      await enter(input, '26000');
      await tap(find.widgetWithText(AppButton, 'Continue'));
      await tap(find.widgetWithText(AppButton, 'Confirm Payment'));
      await pin();
      await tap(find.text('Return to investment'));
      expect(router.state.uri.path, '/investor/projects/marula-heights/invest');
      expect(
        investment().store.amount,
        const MonetaryAmount(2600000, Currency.zar),
      );
      await shot('06-funding-return-same-project');
      await tap(find.widgetWithText(AppButton, 'Review Investment'));
      await tap(find.bySemanticsLabel('Accept investment risks'));
      await tap(find.widgetWithText(AppButton, 'Authorize with PIN'));
      await pin();
      await tap(find.text('View my portfolio'));
      final portfolio = tester
          .widget<PortfolioScreen>(find.byType(PortfolioScreen))
          .store;
      expect(portfolio.balanceVisible, false);
      await tap(find.bySemanticsLabel('Show balance'));
      await shot('07-portfolio-active');
      await tap(find.widgetWithText(TextButton, 'Completed'));
      await shot('08-portfolio-completed');
      await tap(find.widgetWithText(TextButton, 'Underfunded'));
      await shot('09-portfolio-underfunded');
      await tap(find.text('Home').last);
      home = tester
          .widget<InvestorHomeScreen>(find.byType(InvestorHomeScreen))
          .store;
      expect(
        InvestorAccountSummary.from(home.data!).overallBalance,
        originalSummary.overallBalance +
            const MonetaryAmount(2600000, Currency.zar),
      );
      expect(
        InvestorAccountSummary.from(home.data!).investedCapital,
        originalSummary.investedCapital +
            const MonetaryAmount(2600000, Currency.zar),
      );
      await shot('10-home-updated');
      await tap(find.text('Marula Heights').first);
      final projectView = tester.widget<InvestorProjectScreen>(
        find.byType(InvestorProjectScreen),
      );
      final project = projectView.store.project!;
      await reveal(find.text('Closing Date'));
      await shot('11-project-overview');
      await tap(find.widgetWithText(TextButton, 'Documents'));
      await shot('12-project-documents');
      await tap(find.text('CIPC_CoR14_3_Marula'));
      expect(find.textContaining('no file is downloaded'), findsOneWidget);
      await shot('13-simulated-document-preview');
      await tap(find.text('Done'));
      catalog.simulateFunding(project.id, project.target);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AppButton>(find.widgetWithText(AppButton, 'Invest Now'))
            .onPressed,
        isNull,
      );
      await shot('14-fully-funded-blocked');
      await tap(find.widgetWithText(AppButton, 'Calculate'));
      await enter(input, '1');
      expect(
        tester
            .widget<AppButton>(
              find.widgetWithText(AppButton, 'Invest this amount'),
            )
            .onPressed,
        isNull,
      );
      await back();
      await back();
      await tap(find.bySemanticsLabel('Switch experience'));
      await back();
      expect(deps.session.user, same(user));
      await tap(find.bySemanticsLabel('Switch experience'));
      await tap(find.text('Landowner'));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(deps.session.user, same(user));
      await tap(find.byKey(const ValueKey('landowner-tab-1')));
      await tap(find.text('Ridge Site 12').first);
      await shot('15-landowner-property');
      await back();
      await tap(find.byKey(const ValueKey('landowner-tab--1')));
      await enter(
        find.byKey(const ValueKey('field-Property Name')),
        'Client review draft',
      );
      final draftId = tester
          .widget<SubmissionScreen>(find.byType(SubmissionScreen))
          .store
          .draft
          .id;
      await tap(find.text('Save & Exit'));
      await tap(find.byKey(const ValueKey('landowner-tab-0')));
      await tap(find.byTooltip('Switch experience'));
      await tap(find.text('Investor'));
      expect(find.byType(InvestorHomeScreen), findsOneWidget);
      expect(catalog.favouriteIds, contains('marula-heights'));
      expect(account.balanceVisible, true);
      await tap(find.bySemanticsLabel('Switch experience'));
      await tap(find.text('Landowner'));
      await tap(find.byKey(const ValueKey('landowner-tab-1')));
      await enter(
        find.byKey(const ValueKey('property-search')),
        'Client review draft',
      );
      await tap(find.text('Client review draft').last);
      expect(
        tester
            .widget<SubmissionScreen>(find.byType(SubmissionScreen))
            .store
            .draft
            .id,
        draftId,
      );
      await shot('16-landowner-draft-resumed');
      await tap(find.text('Save & Exit'));
      await tap(find.byKey(const ValueKey('landowner-tab-0')));
      await tap(find.byTooltip('Switch experience'));
      await tap(find.text('Investor'));
      expect(deps.session.user, same(user));
      await shot('17-investor-after-repeated-switch');
      await tester.runAsync(() => deps.session.persistenceComplete);
      expect(deps.session.persistenceError, isNull);
    },
  );
}
