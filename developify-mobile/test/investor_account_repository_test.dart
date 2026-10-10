import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late MockBehavior behavior;
  late MockInvestorAccountRepository account;
  late MockInvestorCatalogRepository catalog;
  Future<InvestorAccountSnapshot> snapshot() async =>
      (await account.snapshot() as Success<InvestorAccountSnapshot>).value;
  Future<InvestorProject> project() async =>
      (await catalog.project('marula-heights') as Success<InvestorProject>)
          .value;
  setUp(() {
    session = SessionService()
      ..signIn(
        const AppUser(
          id: 'test',
          name: 'Investor',
          email: 'investor@example.test',
        ),
      );
    context = InvestorAccountContext(session);
    behavior = MockBehavior(delay: Duration.zero);
    catalog = MockInvestorCatalogRepository(
      MockBehavior(delay: Duration.zero),
      context,
    );
    account = MockInvestorAccountRepository(
      behavior,
      context,
      catalog: catalog,
      now: () => DateTime(2026, 9, 12),
    );
  });
  tearDown(() async {
    account.dispose();
    catalog.dispose();
    context.dispose();
    session.dispose();
  });

  test(
    'Saved payment defaults remain unique, scoped and failure-safe',
    () async {
      final second =
          (await account.addCard(
                    cardNumber: '4012888888881881',
                    holder: 'Babatunde Yusuf',
                    expiry: '12 / 29',
                    securityCode: '123',
                  )
                  as Success<InvestorPaymentMethod>)
              .value;
      expect(second.expiry, '12/29');
      expect(second.isDefault, false);
      expect(
        await account.setDefaultPaymentMethod(second.id, true),
        isA<Success<void>>(),
      );
      var methods = (await snapshot()).paymentMethods;
      expect(
        methods
            .where(
              (item) => item.kind == PaymentMethodKind.card && item.isDefault,
            )
            .map((item) => item.id),
        [second.id],
      );
      expect(
        methods
            .singleWhere((item) => item.kind == PaymentMethodKind.bankAccount)
            .isDefault,
        true,
      );
      behavior.failNext();
      expect(
        await account.setDefaultPaymentMethod('individual-visa', true),
        isA<Failure<void>>(),
      );
      expect(
        (await snapshot()).paymentMethods
            .singleWhere((item) => item.id == second.id)
            .isDefault,
        true,
      );
      context.selectEntity(EntityType.trust);
      expect(
        await account.setDefaultPaymentMethod(second.id, true),
        isA<Failure<void>>(),
      );
      expect(
        (await snapshot()).paymentMethods.every(
          (item) => item.id.startsWith('trust-'),
        ),
        true,
      );
      context.selectEntity(EntityType.individual);
      expect(
        await account.setDefaultPaymentMethod(second.id, false),
        isA<Success<void>>(),
      );
      methods = (await snapshot()).paymentMethods;
      expect(
        methods
            .where((item) => item.kind == PaymentMethodKind.card)
            .any((item) => item.isDefault),
        false,
      );
      expect(
        await account.removePaymentMethod(second.id),
        isA<Success<void>>(),
      );
      expect(
        await account.setDefaultPaymentMethod(second.id, true),
        isA<Failure<void>>(),
      );
      final temporary =
          (await account.addCard(
                    cardNumber: '4111111111111111',
                    holder: 'Babatunde Yusuf',
                    expiry: '12/29',
                    securityCode: '123',
                    reusable: false,
                  )
                  as Success<InvestorPaymentMethod>)
              .value;
      expect(
        await account.setDefaultPaymentMethod(temporary.id, true),
        isA<Failure<void>>(),
      );
    },
  );

  test(
    'Switching entity cancels an in-flight default payment change',
    () async {
      account.dispose();
      account = MockInvestorAccountRepository(
        MockBehavior(delay: const Duration(milliseconds: 20)),
        context,
      );
      final pending = account.setDefaultPaymentMethod('individual-visa', false);
      context.selectEntity(EntityType.company);
      expect(await pending, isA<Failure<void>>());
      expect(
        (await snapshot()).paymentMethods.every((item) => item.isDefault),
        true,
      );
      context.selectEntity(EntityType.individual);
      expect(
        (await snapshot()).paymentMethods.every((item) => item.isDefault),
        true,
      );
    },
  );

  test(
    'Investment updates the matching currency, portfolio, transaction and notification atomically',
    () async {
      final before = await snapshot();
      final result = await account.invest(
        project: await project(),
        amount: const MonetaryAmount(100000, Currency.zar),
        operationId: account.newOperationId(),
        pin: '1234',
      );
      expect(result, isA<Success<InvestorOperationReceipt>>());
      final after = await snapshot();
      expect(
        after.balance(Currency.zar).minorUnits,
        before.balance(Currency.zar).minorUnits - 100000,
      );
      expect(after.balance(Currency.usd).minorUnits, 0);
      expect(after.investments.length, before.investments.length + 1);
      expect(after.transactions.length, before.transactions.length + 1);
      expect(after.notifications.length, before.notifications.length + 1);
      expect(after.investments.first.projectedPayout.minorUnits, 143500);
      expect(after.investments.first.earned.minorUnits, 0);
      expect(
        after.investments.first.distribution,
        const MonetaryAmount(1209, Currency.zar),
      );
      expect(after.transactions.first.projectTerms!.name, 'Marula Heights');
      expect(
        after.transactions.first.projectTerms!.distributionPayout,
        const MonetaryAmount(1209, Currency.zar),
      );
      expect(after.transactions.first.projectTerms!.durationMonths, 36);
      expect(after.transactions.first.createdAt, DateTime(2026, 9, 12).toUtc());
    },
  );
  test(
    'A repeated confirmation charges once and rejects a changed request',
    () async {
      final id = account.newOperationId();
      final p = await project();
      final before = await snapshot();
      for (var i = 0; i < 2; i++) {
        expect(
          await account.invest(
            project: p,
            amount: const MonetaryAmount(100000, Currency.zar),
            operationId: id,
            pin: '1234',
          ),
          isA<Success<InvestorOperationReceipt>>(),
        );
      }
      expect(
        await account.invest(
          project: p,
          amount: const MonetaryAmount(200000, Currency.zar),
          operationId: id,
          pin: '1234',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
      expect(
        (await snapshot()).balance(Currency.zar).minorUnits,
        before.balance(Currency.zar).minorUnits - 100000,
      );
    },
  );
  test(
    'Failed investment preserves every account collection and can be retried',
    () async {
      final before = await snapshot();
      final p = await project();
      final id = account.newOperationId();
      behavior.failNext();
      expect(
        await account.invest(
          project: p,
          amount: const MonetaryAmount(100000, Currency.zar),
          operationId: id,
          pin: '1234',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
      final after = await snapshot();
      expect(after.balances, before.balances);
      expect(after.investments, before.investments);
      expect(after.transactions, before.transactions);
      expect(
        await account.invest(
          project: p,
          amount: const MonetaryAmount(100000, Currency.zar),
          operationId: id,
          pin: '1234',
        ),
        isA<Success<InvestorOperationReceipt>>(),
      );
    },
  );
  test('Top-up fee and bank withdrawal keep balances consistent', () async {
    final before = await snapshot();
    expect(
      await account.addMoney(
        amount: const MonetaryAmount(50000, Currency.zar),
        methodId: 'individual-visa',
        operationId: account.newOperationId(),
        pin: '1234',
      ),
      isA<Success<InvestorOperationReceipt>>(),
    );
    final funded = await snapshot();
    expect(
      funded.balance(Currency.zar).minorUnits,
      before.balance(Currency.zar).minorUnits + 50000,
    );
    expect(funded.transactions.first.fee.minorUnits, 750);
    expect(
      await account.withdraw(
        amount: const MonetaryAmount(25000, Currency.zar),
        methodId: 'individual-bank',
        operationId: account.newOperationId(),
        pin: '1234',
      ),
      isA<Success<InvestorOperationReceipt>>(),
    );
    expect(
      (await snapshot()).balance(Currency.zar).minorUnits,
      before.balance(Currency.zar).minorUnits + 25000,
    );
  });
  test(
    'Withdrawal deducts its fee from the recipient amount and retains an immutable receipt',
    () async {
      final before = await snapshot();
      for (final amount in [
        const MonetaryAmount(1, Currency.zar),
        const MonetaryAmount(150, Currency.zar),
        const MonetaryAmount(50000, Currency.usd),
      ]) {
        expect(
          await account.withdraw(
            amount: amount,
            methodId: 'individual-bank',
            operationId: account.newOperationId(),
            pin: '1234',
          ),
          isA<Failure<InvestorOperationReceipt>>(),
        );
      }
      expect((await snapshot()).balances, before.balances);
      expect(
        (await snapshot()).transactions.length,
        before.transactions.length,
      );
      final operationId = account.newOperationId();
      final result = await account.withdraw(
        amount: const MonetaryAmount(50000, Currency.zar),
        methodId: 'individual-bank',
        operationId: operationId,
        pin: '1234',
      );
      expect(result, isA<Success<InvestorOperationReceipt>>());
      final after = await snapshot();
      final transaction = after.transactions.first;
      expect(
        after.balance(Currency.zar),
        before.balance(Currency.zar) -
            const MonetaryAmount(50000, Currency.zar),
      );
      expect(transaction.amount, const MonetaryAmount(-50000, Currency.zar));
      expect(transaction.fee, const MonetaryAmount(150, Currency.zar));
      expect(transaction.paymentMethod!.holder, 'Babatunde Yusuf');
      expect(transaction.paymentMethod!.lastFour, '0119');
      expect(transaction.createdAt, DateTime(2026, 9, 12).toUtc());
      await account.removePaymentMethod('individual-bank');
      final replay = await account.withdraw(
        amount: const MonetaryAmount(50000, Currency.zar),
        methodId: 'individual-bank',
        operationId: operationId,
        pin: '1234',
      );
      expect(
        (replay as Success<InvestorOperationReceipt>).value.transactionId,
        (result as Success<InvestorOperationReceipt>).value.transactionId,
      );
      final current = await snapshot();
      expect(current.balance(Currency.zar), after.balance(Currency.zar));
      expect(current.transactions.length, after.transactions.length);
      expect(current.transactions.first.paymentMethod!.lastFour, '0119');
    },
  );

  test(
    'Amount, currency, PIN, method and insufficient balance validation do not mutate funds',
    () async {
      final before = await snapshot();
      final p = await project();
      for (final amount in [
        const MonetaryAmount(0, Currency.zar),
        const MonetaryAmount(1, Currency.zar),
        const MonetaryAmount(100000, Currency.usd),
        const MonetaryAmount(2000000, Currency.zar),
      ]) {
        expect(
          await account.invest(
            project: p,
            amount: amount,
            operationId: account.newOperationId(),
            pin: '1234',
          ),
          isA<Failure<InvestorOperationReceipt>>(),
        );
      }
      expect(
        await account.withdraw(
          amount: const MonetaryAmount(5000, Currency.zar),
          methodId: 'individual-visa',
          operationId: account.newOperationId(),
          pin: '1234',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
      expect(
        await account.addMoney(
          amount: const MonetaryAmount(5000, Currency.zar),
          methodId: 'individual-visa',
          operationId: account.newOperationId(),
          pin: '0000',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
      expect((await snapshot()).balances, before.balances);
    },
  );
  test(
    'Entities retain independent funds and logout clears all account state',
    () async {
      final original = (await snapshot()).balance(Currency.zar);
      await account.addMoney(
        amount: const MonetaryAmount(50000, Currency.zar),
        methodId: 'individual-visa',
        operationId: account.newOperationId(),
        pin: '1234',
      );
      context.selectEntity(EntityType.trust);
      expect((await snapshot()).balance(Currency.zar), original);
      context.selectEntity(EntityType.individual);
      expect(
        (await snapshot()).balance(Currency.zar).minorUnits,
        original.minorUnits + 50000,
      );
      session.signOut();
      expect(await account.snapshot(), isA<Failure<InvestorAccountSnapshot>>());
      session.signIn(
        const AppUser(
          id: 'test',
          name: 'Investor',
          email: 'investor@example.test',
        ),
      );
      expect((await snapshot()).balance(Currency.zar), original);
    },
  );
  test(
    'Switching an entity cancels pending money operations before mutation',
    () async {
      account.dispose();
      account = MockInvestorAccountRepository(
        MockBehavior(delay: const Duration(milliseconds: 20)),
        context,
      );
      final request = account.addMoney(
        amount: const MonetaryAmount(50000, Currency.zar),
        methodId: 'individual-visa',
        operationId: account.newOperationId(),
        pin: '1234',
      );
      context.selectEntity(EntityType.company);
      expect(await request, isA<Failure<InvestorOperationReceipt>>());
      context.selectEntity(EntityType.individual);
      expect((await snapshot()).balance(Currency.zar).minorUnits, 1018201);
    },
  );
  test(
    'Missing IDs and pending verification return controlled failures',
    () async {
      expect(
        await account.transaction('unknown'),
        isA<Failure<InvestorTransaction>>(),
      );
      expect(
        await account.investment('unknown'),
        isA<Failure<InvestorInvestment>>(),
      );
      expect(await catalog.project('unknown'), isA<Failure<InvestorProject>>());
      account.setVerification(VerificationStatus.pending);
      expect(
        await account.invest(
          project: await project(),
          amount: const MonetaryAmount(100000, Currency.zar),
          operationId: account.newOperationId(),
          pin: '1234',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
    },
  );
  test(
    'Cards validate expiry and retain only their last four digits',
    () async {
      expect(
        await account.addCard(
          cardNumber: '4242424242424242',
          holder: 'Investor',
          expiry: '08/26',
          securityCode: '123',
        ),
        isA<Failure<InvestorPaymentMethod>>(),
      );
      final result =
          await account.addCard(
                cardNumber: '4242424242424242',
                holder: 'Investor',
                expiry: '12/29',
                securityCode: '123',
              )
              as Success<InvestorPaymentMethod>;
      expect(result.value.lastFour, '4242');
      expect(result.value.expiry, '12/29');
      await account.removePaymentMethod(result.value.id);
      expect(
        (await snapshot()).paymentMethods.any(
          (method) => method.id == result.value.id,
        ),
        false,
      );
    },
  );
  test(
    'Dedicated empty scenarios preserve unrelated account features',
    () async {
      account.dispose();
      account = MockInvestorAccountRepository(
        behavior,
        context,
        catalog: catalog,
        scenario: MockScenario.noPortfolio,
      );
      final data = await snapshot();
      expect(data.investments, isEmpty);
      expect(data.transactions, isNotEmpty);
      expect(data.balance(Currency.zar).minorUnits, greaterThan(0));
    },
  );
}
