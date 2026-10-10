import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/domain/portfolio_analytics.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/screens/explore_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/portfolio_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/project_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transfer_screen.dart';
import 'package:developify_mobile/features/investor/presentation/screens/investment_screen.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/portfolio_analytics_view.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<(AppDependencies, GoRouter)> mount(
    WidgetTester tester,
    String path, {
    MockScenario scenario = MockScenario.success,
    double width = 393,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final dependencies = await AppDependencies.create(
      environment: AppEnvironment(
        mockDelay: Duration.zero,
        mockScenario: scenario,
      ),
    );
    dependencies.session.signIn(
      const AppUser(
        id: 'journey-investor',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(dependencies, initialLocation: path);
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

  Future<InvestorAccountSnapshot> snapshot(
    WidgetTester tester,
    AppDependencies dependencies,
  ) async =>
      (await tester.runAsync(
                dependencies.container<InvestorAccountRepository>().snapshot,
              )
              as Success<InvestorAccountSnapshot>)
          .value;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pin(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      await tap(tester, find.widgetWithText(TextButton, digit));
    }
  }

  testWidgets(
    'Portfolio refresh retains holdings and underfunded details stay accurate',
    (tester) async {
      final (dependencies, router) = await mount(
        tester,
        '/investor/portfolio',
        width: 360,
        textScale: 1.6,
      );
      final store = tester
          .widget<PortfolioScreen>(find.byType(PortfolioScreen))
          .store;
      final previous = store.data;
      final repository =
          dependencies.container<InvestorAccountRepository>()
              as MockInvestorAccountRepository;
      repository.behavior.failNext();
      unawaited(store.load());
      await tester.pumpAndSettle();
      expect(store.data, same(previous));
      final retry = find.widgetWithText(TextButton, 'Retry');
      await tester.scrollUntilVisible(
        retry,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
      await tap(tester, retry);
      expect(store.error, isNull);
      expect(store.data!.investments.length, previous!.investments.length);
      router.go('/investor/investments/individual-underfunded-saffron');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This investment is underfunded'),
        findsOneWidget,
      );
      final updates = find.widgetWithText(TextButton, 'Updates');
      await tester.scrollUntilVisible(
        updates,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, updates);
      expect(find.text('Funding target not reached'), findsOneWidget);
      expect(find.text('Quarterly Distribution'), findsNothing);
      expect(find.text('Maturity Payout'), findsNothing);
      expect(find.textContaining('Any refund is simulated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'System back follows transfer steps and retains the saved amount',
    (tester) async {
      final (_, router) = await mount(tester, '/investor/wallet');
      unawaited(router.push<void>('/investor/wallet/add-money'));
      await tester.pumpAndSettle();
      final store = tester
          .widget<TransferScreen>(find.byType(TransferScreen))
          .store;
      await tap(tester, find.text('Bank Transfer'));
      expect(store.stage, TransferStage.bankDetails);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, TransferStage.method);
      await tap(tester, find.text('Debit Card'));
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '500',
      );
      await tap(tester, find.text('Continue'));
      expect(store.stage, TransferStage.review);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, TransferStage.amount);
      expect(store.amountText, '500');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, TransferStage.method);
      expect(router.state.uri.path, '/investor/wallet/add-money');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/investor/wallet');
      unawaited(router.push<void>('/investor/wallet/withdraw'));
      await tester.pumpAndSettle();
      final withdrawal = tester
          .widget<TransferScreen>(find.byType(TransferScreen))
          .store;
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '500',
      );
      await tap(
        tester,
        find.bySemanticsLabel('Select Access Bank account ending 0119'),
      );
      await tap(tester, find.widgetWithText(AppButton, 'Withdraw'));
      expect(withdrawal.stage, TransferStage.review);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(withdrawal.stage, TransferStage.amount);
      expect(withdrawal.amountText, '500');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/investor/wallet');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'System back cancels authorization before returning investment review to amount',
    (tester) async {
      final (dependencies, router) = await mount(tester, '/investor/explore');
      unawaited(router.push<void>('/investor/projects/marula-heights/invest'));
      await tester.pumpAndSettle();
      final store = tester
          .widget<InvestmentScreen>(find.byType(InvestmentScreen))
          .store;
      final before = await snapshot(tester, dependencies);
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '1000',
      );
      await tap(tester, find.text('Review Investment'));
      store.setAgreement(true);
      await tester.pumpAndSettle();
      await tap(tester, find.text('Authorize with PIN'));
      expect(store.stage, InvestmentStage.authorizing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, InvestmentStage.review);
      expect(
        (await snapshot(tester, dependencies)).balance(Currency.zar),
        before.balance(Currency.zar),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(store.stage, InvestmentStage.amount);
      expect(store.amountText, '1000');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/investor/explore');
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Portfolio documents and timeline remain navigable with large text at $width',
      (tester) async {
        final (_, router) = await mount(
          tester,
          '/investor/investments/individual-saffron-2',
          width: width,
          textScale: 1.6,
        );
        final store = tester
            .widget<InvestorProjectScreen>(find.byType(InvestorProjectScreen))
            .store;
        final documents = find.widgetWithText(TextButton, 'Documents');
        await tester.scrollUntilVisible(
          documents,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(tester, documents);
        expect(store.tab, 6);
        expect(find.text('No documents yet'), findsOneWidget);
        await tap(tester, find.widgetWithText(TextButton, 'Updates'));
        expect(store.tab, 3);
        await tester.ensureVisible(find.text('Development Timeline'));
        expect(find.text(r'R36.25 expected'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final calculate = find.widgetWithText(AppButton, 'Calculate');
        expect(calculate.hitTestable(), findsOneWidget);
        await tap(tester, calculate);
        expect(
          router.state.uri.path,
          '/investor/projects/saffron-towers/calculator',
        );
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(
          router.state.uri.path,
          '/investor/investments/individual-saffron-2',
        );
        expect(
          tester
              .widget<InvestorProjectScreen>(find.byType(InvestorProjectScreen))
              .store,
          same(store),
        );
        expect(store.tab, 3);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Calculator updates results and preserves an editable amount with large text at $width',
      (tester) async {
        final (_, router) = await mount(
          tester,
          '/investor/projects/saffron-towers/calculator',
          width: width,
          textScale: 1.6,
        );
        final invest = find.widgetWithText(AppButton, 'Invest this amount');
        final input = find.byKey(const ValueKey('investor-amount'));
        expect(tester.widget<AppButton>(invest).onPressed, isNull);
        await tester.enterText(input, '1.2.3');
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(invest).onPressed, isNull);
        await tester.enterText(input, '26000');
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        expect(tester.getRect(input).bottom, lessThan(532));
        expect(tester.getRect(invest).bottom, lessThanOrEqualTo(532));
        expect(tester.takeException(), isNull);
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, '26,000.00');
        expect(find.text(r'R314.16–R314.17 × 36'), findsOneWidget);
        expect(find.text(r'R11,310.00'), findsOneWidget);
        expect(find.text(r'R37,310.00'), findsOneWidget);
        await tester.ensureVisible(input);
        await tester.tap(input);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, '26000');
        await tap(tester, invest);
        expect(
          router.state.uri.path,
          '/investor/projects/saffron-towers/invest',
        );
        expect(router.state.uri.queryParameters['amountCents'], '2600000');
        expect(
          tester
              .widget<InvestmentScreen>(find.byType(InvestmentScreen))
              .store
              .amountText,
          '26000.00',
        );
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(
          router.state.uri.path,
          '/investor/projects/saffron-towers/calculator',
        );
        expect(tester.widget<TextField>(input).controller!.text, '26,000.00');
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Investment amount, review and PIN remain usable with large text at $width',
      (tester) async {
        final (dependencies, router) = await mount(
          tester,
          '/investor/projects/marula-heights/invest',
          width: width,
          textScale: 1.6,
        );
        final review = find.widgetWithText(AppButton, 'Review Investment');
        expect(tester.widget<AppButton>(review).onPressed, isNull);
        final input = find.byKey(const ValueKey('investor-amount'));
        await tester.ensureVisible(input);
        await tester.enterText(input, '0.99');
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(review).onPressed, isNull);
        await tester.enterText(input, '1000');
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        expect(tester.getRect(review).bottom, lessThanOrEqualTo(532));
        expect(tester.takeException(), isNull, reason: 'amount and keyboard');
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.resetViewInsets();
        await tap(tester, review);
        expect(find.text(r'R12.08–R12.09'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.bySemanticsLabel('Accept investment risks'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        await tap(tester, find.bySemanticsLabel('Accept investment risks'));
        await tap(tester, find.text('Authorize with PIN'));
        await tap(tester, find.text('Use PIN Instead'));
        expect(tester.takeException(), isNull, reason: 'PIN sheet');
        final before = await snapshot(tester, dependencies);
        await pin(tester, '1234');
        expect(find.text('You’re an investor!'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'receipt');
        await tap(tester, find.text('View my portfolio'));
        expect(router.state.uri.path, '/investor/portfolio');
        expect(
          (await snapshot(tester, dependencies)).balance(Currency.zar),
          before.balance(Currency.zar) -
              const MonetaryAmount(100000, Currency.zar),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Top-up rejects a wrong PIN, retries and updates Wallet once', (
    tester,
  ) async {
    final (dependencies, router) = await mount(
      tester,
      '/investor/wallet/add-money',
    );
    final before = await snapshot(tester, dependencies);
    await tap(tester, find.text('Debit Card'));
    final next = find.widgetWithText(AppButton, 'Continue');
    expect(tester.widget<AppButton>(next).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('investor-amount')), '0');
    await tester.pumpAndSettle();
    expect(tester.widget<AppButton>(next).onPressed, isNull);
    expect(find.textContaining('greater than zero'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('investor-amount')),
      '500',
    );
    await tap(tester, find.text('Continue'));
    expect(find.text('Confirm Top- Up'), findsOneWidget);
    await tap(tester, find.text('Confirm Payment'));
    await tap(tester, find.text('Use PIN Instead'));
    await pin(tester, '0000');
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining('Incorrect PIN'),
      ),
      findsOneWidget,
    );
    expect(
      (await snapshot(tester, dependencies)).balance(Currency.zar),
      before.balance(Currency.zar),
    );
    await pin(tester, '1234');
    expect(find.text('Top - up Successful'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Top - up Successful'), findsOneWidget);
    await tap(tester, find.text('Back to Wallet'));
    expect(router.state.uri.path, '/investor/wallet');
    final after = await snapshot(tester, dependencies);
    expect(
      after.balance(Currency.zar),
      before.balance(Currency.zar) + const MonetaryAmount(50000, Currency.zar),
    );
    expect(after.transactions.length, before.transactions.length + 1);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Empty card recovery and bank top-up work with large text at $width',
      (tester) async {
        final (dependencies, router) = await mount(
          tester,
          '/investor/wallet/add-money',
          scenario: MockScenario.empty,
          width: width,
          textScale: 1.6,
        );
        final before = await snapshot(tester, dependencies);
        final store = tester
            .widget<TransferScreen>(find.byType(TransferScreen))
            .store;
        await tap(tester, find.text('Debit Card'));
        expect(find.text('No Cards Added Yet'), findsOneWidget);
        expect(find.byKey(const ValueKey('investor-amount')), findsNothing);
        expect(find.text('Continue'), findsNothing);
        expect(tester.takeException(), isNull);
        await tap(tester, find.bySemanticsLabel('Back'));
        await tap(tester, find.text('Bank Transfer'));
        var failCopy = true;
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              if (failCopy) throw PlatformException(code: 'unavailable');
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tap(tester, find.bySemanticsLabel('Copy demo account number'));
        expect(find.text('Unable to copy. Please try again.'), findsOneWidget);
        failCopy = false;
        await tap(tester, find.bySemanticsLabel('Copy demo account number'));
        expect(copied, InvestorDepositAccount.number);
        expect(find.text('Copied demo account number.'), findsOneWidget);
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(store.stage, TransferStage.method);
        expect(router.state.uri.path, '/investor/wallet/add-money');
        await tap(tester, find.text('Bank Transfer'));
        await tap(tester, find.text('Continue'));
        final input = find.byKey(const ValueKey('investor-amount'));
        await tester.enterText(input, '500');
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        final next = find.widgetWithText(AppButton, 'Continue');
        expect(tester.getRect(next).bottom, lessThanOrEqualTo(532));
        expect(tester.takeException(), isNull);
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(input).controller!.text, '500.00');
        await tap(tester, find.text('Change'));
        expect(store.stage, TransferStage.bankDetails);
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(store.stage, TransferStage.amount);
        expect(store.amountText, '500');
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(store.stage, TransferStage.method);
        await tap(tester, find.text('Bank Transfer'));
        await tap(tester, find.text('Continue'));
        expect(store.amountText, '500');
        await tap(tester, find.text('Continue'));
        expect(store.fee, const MonetaryAmount(0, Currency.zar));
        await tap(tester, find.text('Confirm Payment'));
        await tap(tester, find.text('Use PIN Instead'));
        await pin(tester, '1234');
        expect(find.text('Top - up Successful'), findsOneWidget);
        await tap(tester, find.text('Back to Wallet'));
        expect(router.state.uri.path, '/investor/wallet');
        final after = await snapshot(tester, dependencies);
        expect(
          after.balance(Currency.zar),
          before.balance(Currency.zar) +
              const MonetaryAmount(50000, Currency.zar),
        );
        expect(after.transactions.length, before.transactions.length + 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [360.0, 393.0, 430.0]) {
    testWidgets(
      'Withdrawal validates the recipient and opens its receipt with large text at $width',
      (tester) async {
        final (dependencies, router) = await mount(
          tester,
          '/investor/wallet/withdraw',
          width: width,
          textScale: 1.6,
        );
        final before = await snapshot(tester, dependencies);
        final store = tester
            .widget<TransferScreen>(find.byType(TransferScreen))
            .store;
        final next = find.widgetWithText(AppButton, 'Withdraw');
        expect(tester.widget<AppButton>(next).onPressed, isNull);
        final input = find.byKey(const ValueKey('investor-amount'));
        await tester.enterText(input, '1.50');
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(next).onPressed, isNull);
        expect(find.textContaining('withdrawal fee'), findsOneWidget);
        await tester.enterText(input, '20000');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(tester.widget<AppButton>(next).onPressed, isNull);
        final account = find.bySemanticsLabel(
          'Select Access Bank account ending 0119',
        );
        await tester.scrollUntilVisible(
          account,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tap(tester, account);
        await tap(tester, next);
        expect(store.stage, TransferStage.amount);
        expect(
          find.textContaining('exceeds your available balance'),
          findsOneWidget,
        );
        await tester.ensureVisible(input);
        await tester.enterText(input, '500');
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        await tester.pumpAndSettle();
        expect(tester.getRect(next).bottom, lessThanOrEqualTo(532));
        expect(tester.takeException(), isNull);
        FocusManager.instance.primaryFocus?.unfocus();
        tester.view.resetViewInsets();
        await tap(tester, next);
        expect(store.stage, TransferStage.review);
        expect(find.text(r'R498.50'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tap(tester, find.text('Authorize with PIN'));
        await tap(tester, find.text('Use PIN Instead'));
        await pin(tester, '0000');
        expect(store.stage, TransferStage.authorizing);
        expect(
          (await snapshot(tester, dependencies)).balance(Currency.zar),
          before.balance(Currency.zar),
        );
        await pin(tester, '1234');
        expect(find.text('Withdrawal Sent'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final receiptId = store.receipt!.transactionId;
        await tap(tester, find.text('View Receipt'));
        expect(router.state.uri.path, '/investor/transactions/$receiptId');
        final after = await snapshot(tester, dependencies);
        expect(
          after.balance(Currency.zar),
          before.balance(Currency.zar) -
              const MonetaryAmount(50000, Currency.zar),
        );
        expect(
          after.transactions.first.fee,
          const MonetaryAmount(150, Currency.zar),
        );
        expect(after.transactions.first.paymentMethod!.lastFour, '0119');
        await tap(tester, find.bySemanticsLabel('Back'));
        expect(router.state.uri.path, '/investor/wallet');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Explore filter drafts apply, cancel and reset without losing search',
    (tester) async {
      final (_, router) = await mount(tester, '/investor/explore');
      final store = tester
          .widget<ExploreScreen>(find.byType(ExploreScreen))
          .store;
      await tap(tester, find.bySemanticsLabel('Search projects'));
      await tester.enterText(find.byKey(const ValueKey('field-')), 'Saffron');
      await tester.pumpAndSettle();
      await tap(tester, find.bySemanticsLabel('Back'));
      await tap(tester, find.text('Sort : Trending'));
      bool choiceSelected(String label) => tester
          .widget<Semantics>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics &&
                        widget.properties.selected != null,
                  ),
                )
                .first,
          )
          .properties
          .selected!;
      expect(choiceSelected('Trending'), isFalse);
      await tap(tester, find.text('Trending'));
      expect(choiceSelected('Trending'), isTrue);
      await tester.scrollUntilVisible(
        find.text('Industrial'),
        -300,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
      );
      await tap(tester, find.text('Industrial'));
      router.pop();
      await tester.pumpAndSettle();
      expect(store.category, isNull);
      await tap(tester, find.text('Sort : Trending'));
      await tap(tester, find.text('Hospitality'));
      await tap(tester, find.text('Newest'));
      await tap(tester, find.text('Open for funding'));
      await tap(tester, find.text('Apply Filter'));
      expect(store.category, ProjectCategory.hospitality);
      expect(store.sort, ProjectSort.newest);
      expect(store.funding, {ProjectFundingStatus.open});
      expect(store.results.single.id, 'saffron-hospitality');
      await tap(tester, find.text('Sort : Newest'));
      await tester.scrollUntilVisible(
        find.text('Reset'),
        350,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .hitTestable()
            .first,
      );
      await tap(tester, find.text('Reset'));
      expect(choiceSelected('Any'), isFalse);
      await tap(tester, find.text('Any'));
      expect(choiceSelected('Any'), isTrue);
      await tap(tester, find.text('Apply Filter'));
      expect(store.filter.parameters, isEmpty);
      expect(store.query, 'Saffron');
      expect(store.results.length, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Investment consent, PIN and success open the updated portfolio',
    (tester) async {
      final (dependencies, router) = await mount(
        tester,
        '/investor/projects/saffron-towers/invest',
      );
      final before = await snapshot(tester, dependencies);
      await tester.enterText(
        find.byKey(const ValueKey('investor-amount')),
        '1000',
      );
      await tap(tester, find.text('Review Investment'));
      expect(find.text('Investment Amount'), findsOneWidget);
      await tap(tester, find.bySemanticsLabel('Accept investment risks'));
      await tap(tester, find.text('Authorize with PIN'));
      await tap(tester, find.text('Use PIN Instead'));
      await pin(tester, '1234');
      expect(find.text('You’re an investor!'), findsOneWidget);
      await tap(tester, find.text('View my portfolio'));
      expect(router.state.uri.path, '/investor/portfolio');
      final after = await snapshot(tester, dependencies);
      expect(after.investments.length, before.investments.length + 1);
      expect(
        after.balance(Currency.zar),
        before.balance(Currency.zar) -
            const MonetaryAmount(100000, Currency.zar),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Project child pages open, return and validate update identifiers',
    (tester) async {
      final (_, router) = await mount(
        tester,
        '/investor/projects/saffron-towers',
      );
      await tap(tester, find.text('Details'));
      expect(
        router.state.uri.path,
        '/investor/projects/saffron-towers/details',
      );
      expect(find.text('Key Facts'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Developer').first);
      expect(
        router.state.uri.path,
        '/investor/projects/saffron-towers/developer',
      );
      expect(find.text('Verified Developer'), findsOneWidget);
      expect(find.text('Past Projects'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Updates'));
      expect(
        router.state.uri.path,
        '/investor/projects/saffron-towers/updates',
      );
      await tap(tester, find.text('Foundation Poured').first);
      expect(
        router.state.uri.path,
        '/investor/projects/saffron-towers/updates/planning',
      );
      expect(find.text('June 8, 2026'), findsOneWidget);
      router.go('/investor/projects/saffron-towers/updates/missing');
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Low-balance top-up detour preserves the pending investment', (
    tester,
  ) async {
    final (_, router) = await mount(
      tester,
      '/investor/projects/saffron-towers/invest',
      scenario: MockScenario.lowBalance,
    );
    await tester.enterText(
      find.byKey(const ValueKey('investor-amount')),
      '1000',
    );
    await tap(tester, find.text('Review Investment'));
    expect(find.textContaining('balance is too low'), findsOneWidget);
    await tap(tester, find.text('Top up wallet'));
    expect(router.state.uri.path, '/investor/wallet/add-money');
    router.pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('investor-amount')))
          .controller!
          .text,
      '1000.00',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Notifications mark read and link through investment to project details',
    (tester) async {
      final (dependencies, router) = await mount(
        tester,
        '/investor/notifications',
      );
      await tap(tester, find.text('Target reached'));
      expect(
        router.state.uri.path,
        '/investor/notifications/individual-target-reached',
      );
      expect(
        (await snapshot(tester, dependencies)).notifications
            .firstWhere((item) => item.id == 'individual-target-reached')
            .read,
        true,
      );
      await tap(tester, find.text('View Investment'));
      expect(
        router.state.uri.path,
        '/investor/investments/individual-saffron-0/timeline',
      );
      expect(find.text('Timeline'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Foundation Poured completed'),
        findsOneWidget,
      );
      await tap(tester, find.text('View Project'));
      expect(router.state.uri.path, '/investor/projects/saffron-towers');
      await tap(tester, find.widgetWithText(TextButton, 'Details'));
      expect(
        router.state.uri.path,
        '/investor/projects/saffron-towers/details',
      );
      for (var i = 0; i < 4; i++) {
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(router.state.uri.path, '/investor/notifications');
      final unread = (await snapshot(
        tester,
        dependencies,
      )).notifications.where((item) => !item.read).toList();
      for (final item in unread) {
        await tap(tester, find.text(item.title));
        expect(router.state.uri.path, '/investor/notifications/${item.id}');
        router.pop();
        await tester.pumpAndSettle();
      }
      expect(
        (await snapshot(
          tester,
          dependencies,
        )).notifications.every((item) => item.read),
        true,
      );
      expect(find.text('Read all'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Investment timelines distinguish pending milestones and unavailable holdings',
    (tester) async {
      final (_, router) = await mount(
        tester,
        '/investor/investments/individual-saffron-1/timeline',
      );
      expect(
        find.bySemanticsLabel('Investment Confirmed pending'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Foundation Poured pending'),
        findsOneWidget,
      );
      await tap(tester, find.text('Invest More'));
      expect(router.state.uri.path, '/investor/projects/saffron-towers/invest');
      router.pop();
      await tester.pumpAndSettle();
      expect(
        router.state.uri.path,
        '/investor/investments/individual-saffron-1/timeline',
      );
      router.go(
        '/investor/investments/individual-underfunded-saffron/timeline',
      );
      await tester.pumpAndSettle();
      expect(find.text('Funding target not reached'), findsOneWidget);
      expect(find.text('Invest More'), findsNothing);
      expect(find.text('Maturity Payout'), findsNothing);
      router.go('/investor/investments/company-saffron-0/timeline');
      await tester.pumpAndSettle();
      expect(find.text('This investment could not be found.'), findsOneWidget);
      expect(find.text('Invest More'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Portfolio lists retain their filter and analytics periods change',
    (tester) async {
      final (_, router) = await mount(tester, '/investor/portfolio');
      await tap(tester, find.text('Completed').last);
      await tap(tester, find.text('See all'));
      expect(router.state.uri.path, '/investor/portfolio/list/completed');
      expect(find.text('Completed Projects'), findsOneWidget);
      await tap(tester, find.text('Saffron Towers').first);
      expect(
        router.state.uri.path,
        contains('/investor/investments/individual-completed-saffron-'),
      );
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PortfolioScreen>(find.byType(PortfolioScreen))
            .store
            .filter,
        InvestorInvestmentStatus.completed,
      );
      await tap(tester, find.bySemanticsLabel('Portfolio analytics'));
      expect(router.state.uri.path, '/investor/portfolio/analytics');
      await tap(tester, find.text('7 days'));
      expect(
        tester
            .widget<PortfolioAnalyticsView>(find.byType(PortfolioAnalyticsView))
            .period,
        PortfolioPeriod.week,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
