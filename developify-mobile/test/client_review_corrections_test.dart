import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/core/widgets/adaptive_navigation_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_home_promotions.dart';
import 'package:developify_mobile/features/landowner/data/mock_landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/home_store.dart';
import 'package:developify_mobile/features/landowner/presentation/stores/earnings_store.dart';
import 'package:developify_mobile/features/landowner/presentation/widgets/home_header.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';
import 'helpers/fidelity_capture.dart';

MonetaryAmount rand(int cents) => MonetaryAmount(cents, Currency.zar);

void main() {
  setUpAll(loadAppFonts);
  for (final sample in [
    (120000, 1450, 36, 52200),
    (10000, 1450, 36, 4350),
    (100, 1450, 36, 44),
    (0, 1450, 36, 0),
    (120000, 1200, 17, 20400),
    (9999999999999, 1450, 36, 4350000000000),
  ]) {
    test('Monthly cent reconciliation $sample', () {
      final p = InvestmentProjection(
        principal: rand(sample.$1),
        annualRateBasisPoints: sample.$2,
        termMonths: sample.$3,
        payoutEveryMonths: 1,
      );
      expect(p.distributionCount, sample.$3);
      expect(p.earnings, rand(sample.$4));
      expect(p.payout, rand(sample.$1 + sample.$4));
      expect(
        p.payments.fold<int>(0, (sum, a) => sum + a.minorUnits),
        sample.$4,
      );
      expect(
        p.payments.first.minorUnits - p.payments.last.minorUnits,
        lessThanOrEqualTo(1),
      );
      if (sample.$1 == 120000 && sample.$2 == 1450) {
        expect(p.payments.every((a) => a == rand(1450)), true);
      }
      if (sample.$1 == 10000) {
        expect(p.payments.where((a) => a == rand(121)).length, 30);
        expect(p.payments.where((a) => a == rand(120)).length, 6);
      }
    });
  }
  test(
    'Normal success catalogue contains a fully funded demo and open projects',
    () async {
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      addTearDown(deps.dispose);
      deps.session.signIn(
        const AppUser(
          id: 'review',
          name: 'Review',
          email: 'review@example.test',
        ),
      );
      final catalog = deps.container<InvestorCatalogRepository>();
      final account = deps.container<InvestorAccountRepository>();
      final p = catalog.currentProject('coastline-villas')!;
      expect(p.name, 'Coastline Villas');
      expect(p.target.minorUnits, greaterThan(0));
      expect(p.raised, p.target);
      expect(p.remainingCapacity, rand(0));
      expect(p.fundedBasisPoints, 10000);
      expect(p.canInvest, false);
      expect(catalog.currentProject('marula-heights')!.canInvest, true);
      final before =
          (await account.snapshot() as Success<InvestorAccountSnapshot>).value;
      final result = await account.invest(
        project: p,
        amount: rand(100),
        operationId: account.newOperationId(),
        pin: '1234',
      );
      expect(result, isA<Failure<InvestorOperationReceipt>>());
      final after =
          (await account.snapshot() as Success<InvestorAccountSnapshot>).value;
      expect(after.balance(Currency.zar), before.balance(Currency.zar));
      expect(after.investments.length, before.investments.length);
      expect(after.transactions.length, before.transactions.length);
      final open = catalog.currentProject('marula-heights')!;
      final quote = open.projection(rand(120000));
      expect(
        await account.invest(
          project: open,
          amount: rand(120000),
          quote: quote,
          operationId: account.newOperationId(),
          pin: '1234',
        ),
        isA<Success<InvestorOperationReceipt>>(),
      );
      final invested =
          (await account.snapshot() as Success<InvestorAccountSnapshot>)
              .value
              .investments;
      expect(invested.first.payoutEveryMonths, 1);
      expect(invested.first.durationMonths, 36);
      expect(invested.first.annualRateBasisPoints, 1450);
      expect(invested.first.distributionPayments, quote.payments);
      expect(invested.first.principalAtMaturity, rand(120000));
      expect(
        invested.skip(1).map((i) => i.payoutEveryMonths),
        before.investments.map((i) => i.payoutEveryMonths),
      );
      final stale = InvestmentProjection(
        principal: rand(100),
        annualRateBasisPoints: 1200,
        termMonths: 36,
        payoutEveryMonths: 1,
      );
      final staleResult = await account.invest(
        project: open,
        amount: rand(100),
        quote: stale,
        operationId: account.newOperationId(),
        pin: '1234',
      );
      expect(staleResult, isA<Failure<InvestorOperationReceipt>>());
      expect((staleResult as Failure).error.message, contains('terms changed'));
    },
  );
  test(
    'Landowner privacy survives refresh, new stores and earnings navigation',
    () async {
      final repository = MockLandownerRepository(
        MockBehavior(delay: Duration.zero),
      );
      final home = HomeStore(repository);
      final earnings = EarningsStore(repository);
      await home.load();
      home.toggleBalance();
      expect(earnings.balanceVisible, false);
      await home.load();
      await earnings.load();
      expect(home.balanceVisible, false);
      final rebuilt = HomeStore(repository);
      expect(rebuilt.balanceVisible, false);
      earnings.toggleBalance();
      expect(rebuilt.balanceVisible, true);
      home.dispose();
      earnings.dispose();
      rebuilt.dispose();
      await repository.dispose();
    },
  );

  test(
    'A stale saved quote blocks review until the amount is reconfirmed',
    () async {
      final deps = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      addTearDown(deps.dispose);
      deps.session.signIn(
        const AppUser(
          id: 'quote-review',
          name: 'Review',
          email: 'review@example.test',
        ),
      );
      final drafts = deps.container<InvestorDrafts>();
      drafts.saveInvestment(
        'marula-heights',
        InvestmentDraft(
          amount: '100',
          agreed: true,
          quote: InvestmentProjection(
            principal: rand(10000),
            annualRateBasisPoints: 1200,
            termMonths: 36,
            payoutEveryMonths: 1,
          ),
        ),
      );
      final store = deps.container<InvestmentStore>();
      addTearDown(store.dispose);
      await store.load('marula-heights');
      final observed = <bool>[];
      final disposeReaction = autorun((_) => observed.add(store.validAmount));
      addTearDown(disposeReaction.call);
      expect(store.validAmount, false);
      expect(store.agreed, false);
      expect(store.error, contains('terms changed'));
      expect(store.review(), false);
      store.editAmount('100');
      expect(observed.last, true);
      expect(store.review(), true);
      final quote = drafts.investment('marula-heights').quote!;
      expect(quote.annualRateBasisPoints, 1450);
      expect(quote.payoutEveryMonths, 1);
      expect(quote.payments.length, 36);
      expect(quote.earnings, rand(4350));
    },
  );

  for (final width in [360.0, 390.0, 393.0, 412.0, 430.0]) {
    for (final scale in [1.0, 1.3, 1.6, 2.0]) {
      testWidgets('Header privacy and promotion separation $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        final repository = MockLandownerRepository(
          MockBehavior(delay: Duration.zero),
        );
        final store = HomeStore(repository);
        await tester.runAsync(store.load);
        final boundary = GlobalKey();
        Future<void> show(Widget child) async {
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(393, 852),
              minTextAdapt: true,
              builder: (_, _) => MaterialApp(
                theme: AppTheme.light,
                home: Scaffold(
                  body: RepaintBoundary(
                    key: boundary,
                    child: SingleChildScrollView(child: child),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        final header = HomeHeader(
          store: store,
          displayName: 'Babatunde Yusuf',
          onProfile: () {},
          onMessages: () {},
          onNotifications: () {},
          onExperience: () {},
        );
        await show(header);
        final semantics = tester.ensureSemantics();
        expect(find.text('Total Earnings to date'), findsOneWidget);
        expect(find.text('Total earned from your property'), findsNothing);
        expect(tester.takeException(), isNull);
        final switchRect = tester.getRect(find.byTooltip('Switch experience'));
        expect(switchRect.right, greaterThan(width - 35));
        final eye = tester.getRect(find.bySemanticsLabel('Hide balance'));
        final label = tester.getRect(find.text('Total Earnings to date'));
        expect(eye.left - label.right, inInclusiveRange(0, 6));
        if (scale == 1) {
          expect(
            tester.getTopLeft(find.text('Next Payouts:')).dy,
            closeTo(tester.getTopLeft(find.text('R60,000')).dy, .1),
          );
          expect(
            tester.getTopLeft(find.text('R60,000')).dy,
            closeTo(tester.getTopLeft(find.text('in 19 days')).dy, .1),
          );
        }
        if (width == 393 || (width == 360 && scale == 2)) {
          await captureFidelity(tester, boundary, 'landowner-$width-$scale');
        }
        await tester.tap(find.bySemanticsLabel('Hide balance'));
        await tester.pump();
        expect(find.text('****'), findsNWidgets(3));
        expect(find.textContaining('480'), findsNothing);
        expect(find.textContaining('60,000'), findsNothing);
        expect(find.bySemanticsLabel(RegExp('480|60,000')), findsNothing);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(tester.getRect(find.bySemanticsLabel('Show balance')), eye);
        expect(tester.getRect(find.byTooltip('Switch experience')), switchRect);
        if (width == 393 && scale == 1) {
          await captureFidelity(tester, boundary, 'landowner-private');
        }
        semantics.dispose();
        for (final data in [
          const LandownerOverview(
            properties: [],
            earnedCents: 0,
            nextPayoutCents: 0,
          ),
          const LandownerOverview(properties: [], earnedCents: 9999999999999),
        ]) {
          store.data = data;
          if (!store.balanceVisible) store.toggleBalance();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        for (final cents in [0, 1388451, 9999999999999]) {
          Widget investorHeader(bool visible) => InvestorBalanceHeader(
            title: 'My Portfolio',
            amount: rand(cents),
            visible: visible,
            onToggle: () {},
            change: '+R652.50 projected returns',
            child: const SizedBox(key: ValueKey('balance-actions'), height: 48),
          );
          await show(investorHeader(true));
          final visibleRect = tester.getRect(
            find.byType(InvestorBalanceHeader),
          );
          final actionsRect = tester.getRect(
            find.byKey(const ValueKey('balance-actions')),
          );
          expect(tester.takeException(), isNull);
          await show(investorHeader(false));
          expect(
            tester.getRect(find.byType(InvestorBalanceHeader)),
            visibleRect,
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('balance-actions'))),
            actionsRect,
          );
          expect(find.text('****'), findsOneWidget);
          expect(find.textContaining('652'), findsNothing);
          expect(tester.takeException(), isNull);
        }
        const labels = ['Home', 'Properties', 'Submit', 'Earnings', 'Profile'];
        await show(
          AdaptiveNavigationRow(
            labels: labels,
            children: [
              for (final label in labels)
                TextButton(
                  onPressed: () {},
                  child: Text(
                    label,
                    style: AppTextStyles.text(12, weight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        );
        for (final label in labels) {
          expect(find.text(label).hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await show(
          const Padding(
            padding: EdgeInsets.all(12),
            child: InvestorHomePromotions(),
          ),
        );
        expect(find.text('Try the investment calculator'), findsOneWidget);
        expect(find.text('Unlock Your Investment Potential'), findsNothing);
        final copy = tester.getRect(
          find.byKey(const ValueKey('promotion-copy')),
        );
        final art = tester.getRect(
          find.byKey(const ValueKey('promotion-artwork')),
        );
        expect(copy.overlaps(art), false);
        if (scale == 1) {
          final heading = tester.getSize(
            find.text('Try the investment calculator'),
          );
          expect(heading.height, lessThan(22 * width / 393));
        }
        expect(tester.takeException(), isNull);
        if (width == 393 || (width == 360 && scale == 2)) {
          await captureFidelity(tester, boundary, 'promotion-$width-$scale');
        }
        await tester.pumpWidget(const SizedBox());
        store.dispose();
        await repository.dispose();
      });
    }
  }
  for (final variant in InvestorHomePromotion.values) {
    testWidgets('Retained promotion routes correctly: ${variant.name}', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                Scaffold(body: InvestorHomePromotions(promotion: variant)),
          ),
          GoRoute(
            path: '/calculator',
            name: InvestorRoutes.calculatorProjects,
            builder: (_, _) => const Text('Project selection'),
          ),
          GoRoute(
            path: '/analytics',
            name: InvestorRoutes.analytics,
            builder: (_, _) => const Text('Portfolio analytics'),
          ),
        ],
      );
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(
          variant == InvestorHomePromotion.calculator
              ? 'Try the investment calculator'
              : 'Unlock Your Investment Potential',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          variant == InvestorHomePromotion.calculator
              ? 'Project selection'
              : 'Portfolio analytics',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
  }
}
