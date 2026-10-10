import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/app.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/app/router/app_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/presentation/screens/transactions_screen.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_transaction_row.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_details.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/transaction_status_badge.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'helpers/fonts.dart';

void main() {
  setUpAll(loadAppFonts);
  Future<GoRouter> mount(
    WidgetTester tester, {
    double width = 393,
    double textScale = 1,
    MockScenario scenario = MockScenario.success,
  }) async {
    tester.view.physicalSize = Size(width, 852);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 56, bottom: 34);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
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
        id: 'transaction-test',
        name: 'Babatunde Yusuf',
        email: 'investor@example.test',
      ),
      experience: Experience.investor,
    );
    final router = createAppRouter(
      dependencies,
      initialLocation: '/investor/transactions',
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
    return router;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final width in [360.0, 390.0, 393.0, 402.0, 430.0]) {
    testWidgets(
      'Transaction filters, receipt variants and back state at $width with large text',
      (tester) async {
        final router = await mount(tester, width: width, textScale: 1.6);
        final store = tester
            .widget<TransactionsScreen>(find.byType(TransactionsScreen))
            .store;
        for (final (filter, label, suffix, count, detailLabel) in [
          (
            InvestorTransactionKind.investment,
            'Investments',
            'investment-payment',
            1,
            'Quarterly Payout',
          ),
          (
            InvestorTransactionKind.topUp,
            'Wallet Top up',
            'topup-0',
            2,
            'Payment Method',
          ),
          (
            InvestorTransactionKind.topUp,
            'Wallet Top up',
            'topup-1',
            2,
            'Remark',
          ),
          (
            InvestorTransactionKind.withdrawal,
            'Withdrawals',
            'withdrawal',
            1,
            'Account Name',
          ),
          (
            InvestorTransactionKind.distribution,
            'Distributions',
            'distribution-saffron',
            2,
            'Term',
          ),
        ]) {
          await tap(tester, find.widgetWithText(TextButton, label));
          expect(store.filter, filter);
          expect(store.transactions.length, count);
          final row = find.byWidgetPredicate(
            (widget) =>
                widget is InvestorTransactionRow &&
                widget.transaction.id == 'individual-$suffix',
          );
          if (row.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              row,
              160,
              scrollable: find.byType(Scrollable).last,
            );
          }
          await tap(tester, row);
          expect(
            router.state.uri.path,
            '/investor/transactions/individual-$suffix',
          );
          final detail = tester.widget<TransactionDetails>(
            find.byType(TransactionDetails),
          );
          expect(detail.transaction.id, 'individual-$suffix');
          await tester.ensureVisible(find.text(detailLabel));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final download = find.widgetWithText(AppButton, 'Download Receipt');
          expect(download.hitTestable(), findsOneWidget);
          expect(tester.getSize(download).height, greaterThanOrEqualTo(44));
          await tap(tester, download);
          expect(find.text('Receipt preview'), findsOneWidget);
          expect(find.textContaining('No file is downloaded'), findsOneWidget);
          await tap(tester, find.widgetWithText(TextButton, 'Done'));
          await tap(tester, find.bySemanticsLabel('Back'));
          expect(router.state.uri.path, '/investor/transactions');
          expect(
            tester
                .widget<TransactionsScreen>(find.byType(TransactionsScreen))
                .store,
            same(store),
          );
          expect(store.filter, filter);
          expect(store.transactions.length, count);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets(
    'Transaction read failure retries and an invalid receipt cannot download',
    (tester) async {
      final router = await mount(tester, scenario: MockScenario.networkFailure);
      expect(find.text('Unable to connect. Please try again.'), findsOneWidget);
      await tap(tester, find.text('Try again'));
      expect(find.byType(InvestorTransactionRow), findsWidgets);
      router.go('/investor/transactions/unknown-receipt');
      await tester.pumpAndSettle();
      expect(find.text('This transaction could not be found.'), findsOneWidget);
      expect(find.text('Download Receipt'), findsNothing);
      await tap(tester, find.text('Try again'));
      expect(router.state.uri.path, '/investor/transactions');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Empty transaction filters retain the empty state and allow refresh',
    (tester) async {
      await mount(tester, scenario: MockScenario.noTransactions);
      expect(find.text('No transactions yet'), findsOneWidget);
      await tap(tester, find.widgetWithText(TextButton, 'Investments'));
      expect(find.text('No transactions yet'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pumpAndSettle();
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Transaction status badges convey success, pending and failure in text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 852);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (_, child) => MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Column(
                children: [
                  for (final status in InvestorTransactionStatus.values)
                    TransactionStatusBadge(status),
                ],
              ),
            ),
          ),
        ),
      );
      for (final label in ['Successful', 'Pending', 'Failed']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Transaction calendar grouping handles midnight and year boundaries',
    () {
      final now = DateTime(2027, 1, 1, 0, 5);
      expect(
        AppDateFormat.relativeDayDate(DateTime(2027, 1, 1, 0), now: now),
        'Today, 01 January 2027',
      );
      expect(
        AppDateFormat.relativeDayDate(DateTime(2026, 12, 31, 23, 59), now: now),
        'Yesterday, 31 December 2026',
      );
      expect(
        AppDateFormat.relativeDayDate(DateTime(2026, 12, 30), now: now),
        '30 December 2026',
      );
      expect(AppDateFormat.time12(DateTime(2026, 7, 8, 0, 4)), '12:04AM');
      expect(AppDateFormat.time12(DateTime(2026, 7, 8, 12, 4)), '12:04PM');
    },
  );
}
