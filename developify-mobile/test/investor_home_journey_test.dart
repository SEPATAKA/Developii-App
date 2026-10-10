import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester, {
    double width = 393,
    double height = 852,
    double scale = 1,
    MockScenario scenario = MockScenario.success,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: scenario,
      ),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'home-journey-investor',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/home',
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
    return (dependencies, router);
  }

  Finder homeScroll() => find
      .descendant(
        of: find.byKey(const PageStorageKey('investor-home-scroll')),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 150, scrollable: homeScroll());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Home combines available wallet and invested capital without counting transfers twice',
    (tester) async {
      final (dependencies, router) = await mount(
        tester,
        scenario: MockScenario.noPortfolio,
      );
      final account = dependencies.container<InvestorAccountRepository>();
      InvestorBalanceHeader header() => tester.widget<InvestorBalanceHeader>(
        find.byType(InvestorBalanceHeader),
      );
      expect(header().title, 'Babatunde Yusuf');
      expect(header().amount, const MonetaryAmount(1018201, Currency.zar));
      dependencies.session.updateUser(
        dependencies.session.user!.copyWith(name: 'Amara Dlamini'),
      );
      await tester.pumpAndSettle();
      expect(header().title, 'Amara Dlamini');
      final deposit = await tester.runAsync(
        () => account.addMoney(
          amount: const MonetaryAmount(50000, Currency.zar),
          methodId: InvestorDepositAccount.method.id,
          operationId: account.newOperationId(),
          pin: '1234',
        ),
      );
      expect(deposit, isA<Success<InvestorOperationReceipt>>());
      await tester.pumpAndSettle();
      expect(header().amount, const MonetaryAmount(1068201, Currency.zar));
      final project = await tester.runAsync(
        () => dependencies.container<InvestorCatalogRepository>().project(
          'saffron-towers',
        ),
      );
      final investment = await tester.runAsync(
        () => account.invest(
          project: (project as Success<InvestorProject>).value,
          amount: const MonetaryAmount(100000, Currency.zar),
          operationId: account.newOperationId(),
          pin: '1234',
        ),
      );
      expect(investment, isA<Success<InvestorOperationReceipt>>());
      await tester.pumpAndSettle();
      expect(header().amount, const MonetaryAmount(1068201, Currency.zar));
      final homeAmount = header().amount;
      final homeProjection = header().change;
      expect(homeProjection, endsWith('projected returns'));
      router.go('/investor/portfolio');
      await tester.pumpAndSettle();
      expect(header().amount, const MonetaryAmount(100000, Currency.zar));
      expect(header().amount, isNot(homeAmount));
      expect(header().change, homeProjection);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home scrolls its header in a compact landscape viewport', (
    tester,
  ) async {
    await mount(tester, width: 800, height: 600);
    expect(tester.takeException(), isNull, reason: 'initial Home');
    final header = find.byType(InvestorBalanceHeader);
    final originalTop = tester.getTopLeft(header).dy;
    await tester.drag(homeScroll(), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(header).dy, lessThan(originalTop));
    await reveal(tester, find.text('Recently active'));
    expect(find.text('Recently active').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home pins quick actions and preserves one calculator promotion on return',
    (tester) async {
      final (dependencies, router) = await mount(tester);
      final user = dependencies.session.user;
      final header = find.byType(InvestorBalanceHeader);
      final originalHeader = tester.getRect(header);
      final calculator = find.text('Try the investment calculator');
      await reveal(tester, calculator);
      expect(tester.getRect(header), originalHeader);
      final position = tester.state<ScrollableState>(homeScroll()).position;
      final offset = position.pixels;
      expect(offset, greaterThan(0));
      await tester.tap(calculator);
      await tester.pumpAndSettle();
      expect(find.text('Select a project'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(homeScroll()).position.pixels,
        offset,
      );
      expect(calculator.hitTestable(), findsOneWidget);
      expect(find.text('Unlock Your Investment Potential'), findsNothing);
      expect(tester.getRect(header), originalHeader);
      expect(dependencies.session.user, same(user));
      await tester.tap(find.bySemanticsLabel('Hide balance'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Show balance'), findsOneWidget);
      expect(
        tester.state<ScrollableState>(homeScroll()).position.pixels,
        offset,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Empty Home keeps actions and promotions usable with large text at $width',
      (tester) async {
        final (_, router) = await mount(
          tester,
          width: width,
          scale: 1.6,
          scenario: MockScenario.noPortfolio,
        );
        final header = find.byType(InvestorBalanceHeader);
        final originalHeader = tester.getRect(header);
        for (final label in ['Add money', 'Withdraw', 'Invest', 'Portfolio']) {
          expect(find.text(label).first.hitTestable(), findsOneWidget);
        }
        final empty = find.text('Ready to grow?');
        await reveal(tester, empty);
        expect(empty.hitTestable(), findsOneWidget);
        expect(find.text('Saffron Towers'), findsNothing);
        final insights = find.text('Try the investment calculator');
        await tester.ensureVisible(insights);
        await tester.pumpAndSettle();
        expect(insights.hitTestable(), findsOneWidget);
        await tester.tap(insights);
        await tester.pumpAndSettle();
        expect(find.text('Select a project'), findsOneWidget);
        expect(find.text('Unlock Your Investment Potential'), findsNothing);
        router.pop();
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(0);
        await tester.pumpAndSettle();
        expect(tester.getRect(header).size, originalHeader.size);
        expect(tester.getRect(header).top, closeTo(originalHeader.top, .001));
        for (final label in ['Add money', 'Withdraw', 'Invest', 'Portfolio']) {
          expect(find.text(label).first.hitTestable(), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Home reports failed favourites and retries without losing account data',
    (tester) async {
      final (dependencies, _) = await mount(tester);
      final store = tester
          .widget<InvestorHomeScreen>(find.byType(InvestorHomeScreen))
          .store;
      final account = store.data;
      final catalog =
          dependencies.container<InvestorCatalogRepository>()
              as MockInvestorCatalogRepository;
      catalog.behavior.failNext();
      unawaited(store.toggleFavourite('marula-heights'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
      expect(store.data, same(account));
      expect(store.favourites, isEmpty);
      final retry = find.widgetWithText(TextButton, 'Try again');
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(store.error, isNull);
      expect(store.data!.investments.length, account!.investments.length);
      expect(find.bySemanticsLabel('Hide balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
