import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/authentication/data/mock_auth_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/presentation/stores/explore_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_home_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_notifications_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/payment_methods_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/portfolio_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/project_detail_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transactions_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/transfer_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late InvestorDrafts drafts;
  late MockTransactionAuthorization authorization;
  late MockBehavior behavior;
  late MockBehavior catalogBehavior;
  late MockInvestorAccountRepository accounts;
  late MockInvestorCatalogRepository catalog;
  final stores = <Lifecycle>[];
  T own<T extends Lifecycle>(T store) {
    stores.add(store);
    return store;
  }

  Future<InvestorAccountSnapshot> snapshot() async =>
      (await accounts.snapshot() as Success<InvestorAccountSnapshot>).value;
  Future<void> flush() => Future<void>.delayed(Duration.zero);
  setUp(() {
    session = SessionService()
      ..signIn(
        const AppUser(
          id: 'store-investor',
          name: 'Investor',
          email: 'investor@example.test',
        ),
        experience: Experience.investor,
      );
    context = InvestorAccountContext(session);
    drafts = InvestorDrafts(context);
    authorization = MockTransactionAuthorization(session);
    behavior = MockBehavior(delay: Duration.zero);
    catalogBehavior = MockBehavior(delay: Duration.zero);
    catalog = MockInvestorCatalogRepository(catalogBehavior, context);
    accounts = MockInvestorAccountRepository(
      behavior,
      context,
      catalog: catalog,
      authorization: authorization,
      now: () => DateTime(2026, 9, 12),
    );
  });
  tearDown(() {
    for (final store in stores.reversed) {
      store.dispose();
    }
    stores.clear();
    accounts.dispose();
    catalog.dispose();
    drafts.dispose();
    context.dispose();
    authorization.dispose();
    session.dispose();
  });

  test(
    'Home exposes loading, retry, empty, balance visibility and shared favourites',
    () async {
      final home = own(InvestorHomeStore(accounts, catalog));
      behavior.failNext();
      final first = home.load();
      expect(home.status, LoadStatus.loading);
      await first;
      expect(home.status, LoadStatus.error);
      await home.load();
      expect(home.status, LoadStatus.success);
      home.toggleBalance();
      expect(home.balanceVisible, false);
      await home.toggleFavourite('marula-heights');
      await flush();
      expect(home.favourites, contains('marula-heights'));
      final emptyCatalog = MockInvestorCatalogRepository(
        MockBehavior(delay: Duration.zero, empty: true),
        context,
      );
      addTearDown(emptyCatalog.dispose);
      final emptyHome = own(InvestorHomeStore(accounts, emptyCatalog));
      await emptyHome.load();
      expect(emptyHome.status, LoadStatus.empty);
    },
  );

  test(
    'Project favourites refresh after catalog changes and entity switching',
    () async {
      final store = own(InvestorProjectDetailStore(catalog, accounts));
      await store.load('marula-heights', includeRelated: true);
      expect(store.relatedProjects.length, 6);
      await catalog.setFavourite('marula-heights', true);
      await flush();
      expect(store.favourite, true);
      context.selectEntity(EntityType.trust);
      await flush();
      expect(store.favourite, false);
      await store.toggleFavourite();
      expect(store.favourite, true);
      context.selectEntity(EntityType.individual);
      await flush();
      expect(store.favourite, true);
    },
  );

  test(
    'Saving a favourite while an investment reloads preserves the saved result',
    () async {
      final delayedAccounts = MockInvestorAccountRepository(
        MockBehavior(delay: const Duration(milliseconds: 50)),
        context,
        authorization: authorization,
      );
      addTearDown(delayedAccounts.dispose);
      final store = own(InvestorProjectDetailStore(catalog, delayedAccounts));
      await store.loadInvestment('individual-saffron-0');
      final saving = store.toggleFavourite();
      final reloading = store.loadInvestment('individual-saffron-0');
      expect(store.project, isNull);
      try {
        await expectLater(saving, completes);
      } finally {
        await reloading;
      }
      expect(store.status, LoadStatus.success);
      expect(store.project!.id, 'saffron-towers');
      expect(store.favourite, isTrue);
      expect(catalog.favouriteIds, contains('saffron-towers'));
      expect(store.error, isNull);
    },
  );

  test(
    'Portfolio project context validates holdings and clears data on entity switch',
    () async {
      final store = own(InvestorProjectDetailStore(catalog, accounts));
      await store.loadInvestment('individual-saffron-0');
      expect(store.investment!.id, 'individual-saffron-0');
      expect(store.project!.id, 'saffron-towers');
      store.selectTab(6);
      expect(store.tab, 6);
      expect(store.project!.content!.documents, isEmpty);
      context.selectEntity(EntityType.trust);
      await flush();
      expect(store.investment, isNull);
      expect(store.project, isNull);
      await flush();
      expect(store.status, LoadStatus.error);
      expect(store.error, 'This investment could not be found.');
      await store.loadInvestment('trust-saffron-0');
      expect(store.investment!.id, 'trust-saffron-0');
      expect(store.status, LoadStatus.success);
      await store.loadInvestment('unknown');
      expect(store.status, LoadStatus.error);
      expect(store.project, isNull);
      expect(store.investment, isNull);
      await store.load('marula-heights');
      expect(store.status, LoadStatus.success);
      expect(store.investment, isNull);
    },
  );

  test(
    'Explore funding, investment-range and date filters compose and reset',
    () async {
      final store = own(ExploreStore(catalog));
      await store.load();
      store.setSort(ProjectSort.newest);
      expect(store.results.first.id, 'azure-bay');
      store.setSort(ProjectSort.closingSoon);
      expect(store.results.first.id, 'saffron-towers');
      store.setInvestmentRange(200, 50000);
      expect(store.results, isEmpty);
      store.setInvestmentRange(1, 200);
      expect(store.results.length, 6);
      store.toggleFunding(ProjectFundingStatus.targetReached);
      expect(store.results.single.id, 'coastline-villas');
      store.toggleFunding(ProjectFundingStatus.open);
      expect(store.results.length, 6);
      store.toggleFunding(ProjectFundingStatus.open);
      store.toggleFunding(ProjectFundingStatus.targetReached);
      store.toggleFunding(ProjectFundingStatus.newToday);
      expect(store.results, isEmpty);
      store.selectCategory(ProjectCategory.industrial);
      store.resetFilters();
      expect(store.results.length, 6);
      expect(store.filter.parameters, isEmpty);
    },
  );

  test(
    'Explore combines search, categories, location, return, sorting and favourites',
    () async {
      final store = own(ExploreStore(catalog));
      await store.load();
      store.search('Saffron');
      expect(store.results, isNotEmpty);
      expect(
        store.results.every((project) => project.name.contains('Saffron')),
        true,
      );
      store.selectCategory(ProjectCategory.hospitality);
      expect(store.results.single.category, ProjectCategory.hospitality);
      store.search('unavailable project');
      expect(store.results, isEmpty);
      store.search('');
      store.resetFilters();
      store.setLocation('Cape Town');
      expect(
        store.results.every((project) => project.city == 'Capetown'),
        true,
      );
      store.setReturn(1500);
      expect(store.results.single.id, 'lissana-villa');
      store.setSort(ProjectSort.returnRate);
      await store.toggleFavourite('lissana-villa');
      await flush();
      store.toggleFavourites();
      expect(store.results.single.id, 'lissana-villa');
      context.selectEntity(EntityType.trust);
      await flush();
      expect(store.favourites, isEmpty);
      expect(store.results, isEmpty);
    },
  );

  test(
    'Investment validates amount and balance, retains drafts, and requires review authorization',
    () async {
      final store = own(InvestmentStore(catalog, accounts, drafts));
      await store.load('marula-heights');
      for (final amount in ['', '0', '-2', '0.99', '100000']) {
        store.editAmount(amount);
        expect(store.review(), false, reason: amount);
      }
      store.editAmount('1000');
      store.setAgreement(true);
      expect(await store.confirm('1234'), false);
      expect(store.review(), true);
      store.authorize();
      store.cancelAuthorization();
      expect(store.stage, InvestmentStage.review);
      final resumed = own(InvestmentStore(catalog, accounts, drafts));
      await resumed.load('marula-heights');
      expect(resumed.amountText, '1000');
      expect(resumed.agreed, true);
      expect(
        resumed.projectedPayout,
        const MonetaryAmount(143500, Currency.zar),
      );
    },
  );

  test(
    'Investment retries an incorrect PIN and failed operation without duplicate deductions',
    () async {
      final store = own(InvestmentStore(catalog, accounts, drafts));
      await store.load('marula-heights');
      store.editAmount('1000');
      store.setAgreement(true);
      store.review();
      store.authorize();
      final before = await snapshot();
      expect(await store.confirm('0000'), false);
      expect(store.stage, InvestmentStage.authorizing);
      behavior.failNext();
      expect(await store.confirm('1234'), false);
      expect(store.stage, InvestmentStage.failure);
      store.authorize();
      expect(await store.confirm('1234'), true);
      expect(await store.confirm('1234'), false);
      expect(
        (await snapshot()).balance(Currency.zar).minorUnits,
        before.balance(Currency.zar).minorUnits - 100000,
      );
      expect(drafts.investment('marula-heights').amount, isEmpty);
    },
  );

  test(
    'A new investor can add simulated bank funds without a linked withdrawal account',
    () async {
      session.signOut();
      session.signIn(
        const AppUser(
          id: 'local-investor-new',
          name: 'New Investor',
          email: 'new@example.test',
        ),
        experience: Experience.investor,
      );
      await flush();
      final store = own(TransferStore(accounts, drafts));
      await store.load(InvestorTransferKind.topUp);
      expect(store.account!.paymentMethods, isEmpty);
      store.chooseKind(PaymentMethodKind.bankAccount);
      store.editAmount('500');
      expect(store.method!.id, InvestorDepositAccount.method.id);
      expect(store.fee.minorUnits, 0);
      expect(store.review(), true);
      store.authorize();
      expect(await store.confirm('1234'), true);
      expect((await snapshot()).balance(Currency.zar).minorUnits, 50000);
      expect((await snapshot()).paymentMethods, isEmpty);
    },
  );

  test(
    'Withdrawal validates amount, verification and bank selection before confirmation',
    () async {
      final store = own(TransferStore(accounts, drafts));
      await store.load(InvestorTransferKind.withdrawal);
      expect(store.method, isNull);
      expect(
        store.methods.every(
          (method) => method.kind == PaymentMethodKind.bankAccount,
        ),
        true,
      );
      for (final value in ['0', '0.001', '1.50', '999999']) {
        store.editAmount(value);
        expect(store.review(), false);
      }
      store.editAmount('20000');
      expect(store.review(), false);
      store.editAmount('500');
      expect(store.review(), false);
      store.selectMethod('individual-bank');
      expect(store.review(), true);
      expect(store.fee, const MonetaryAmount(150, Currency.zar));
      expect(store.received, const MonetaryAmount(49850, Currency.zar));
      expect(await store.confirm('1234'), false);
      store.authorize();
      expect(await store.confirm('1234'), true);
      expect(store.stage, TransferStage.success);
      expect(drafts.transfer(InvestorTransferKind.withdrawal).amount, isEmpty);
    },
  );

  test(
    'Removing the last selected card preserves card payment and its amount draft',
    () async {
      final store = own(TransferStore(accounts, drafts));
      await store.load(InvestorTransferKind.topUp);
      store.chooseKind(PaymentMethodKind.card);
      store.editAmount('500');
      final balance = (await snapshot()).balance(Currency.zar);
      expect(store.review(), isTrue);
      store.authorize();
      final cardIds = store.methods
          .where((method) => method.kind == PaymentMethodKind.card)
          .map((method) => method.id)
          .toList();
      expect(cardIds, isNotEmpty);
      for (final id in cardIds) {
        expect(await accounts.removePaymentMethod(id), isA<Success<void>>());
      }
      await flush();
      await store.refreshMethods();
      expect(store.paymentKind, PaymentMethodKind.card);
      expect(store.method, isNull);
      expect(store.amountText, '500');
      expect(store.stage, TransferStage.amount);
      expect(await store.confirm('1234'), isFalse);
      expect((await snapshot()).balance(Currency.zar), balance);
      expect(store.review(), isFalse);
      store.showPaymentTypes();
      expect(store.stage, TransferStage.method);
      store.chooseKind(PaymentMethodKind.bankAccount);
      expect(store.method!.id, InvestorDepositAccount.method.id);
      expect(store.amountText, '500');
      expect(store.review(), isTrue);
    },
  );

  test(
    'Bank details reset on entity changes and restore only that entity’s draft',
    () async {
      final store = own(TransferStore(accounts, drafts));
      await store.load(InvestorTransferKind.topUp);
      store.chooseKind(PaymentMethodKind.bankAccount);
      store.editAmount('125.50');
      store.showBankDetails();
      expect(store.stage, TransferStage.bankDetails);
      context.selectEntity(EntityType.trust);
      await flush();
      expect(store.stage, TransferStage.method);
      expect(store.amountText, isEmpty);
      expect(store.paymentKind, PaymentMethodKind.card);
      context.selectEntity(EntityType.individual);
      await flush();
      expect(store.stage, TransferStage.method);
      expect(store.amountText, '125.50');
      expect(store.paymentKind, PaymentMethodKind.bankAccount);
      store.showBankDetails();
      store.leaveBankDetails();
      expect(store.stage, TransferStage.method);
      await store.load(InvestorTransferKind.withdrawal);
      store.showBankDetails();
      expect(store.stage, TransferStage.amount);
    },
  );

  test(
    'Top-up prefers the saved default without replacing an explicit draft selection',
    () async {
      final second =
          (await accounts.addCard(
                    cardNumber: '4012888888881881',
                    holder: 'Investor',
                    expiry: '12/29',
                    securityCode: '123',
                  )
                  as Success<InvestorPaymentMethod>)
              .value;
      await accounts.setDefaultPaymentMethod(second.id, true);
      final transfer = own(TransferStore(accounts, drafts));
      await transfer.load(InvestorTransferKind.topUp);
      expect(transfer.methodId, second.id);
      transfer.selectMethod('individual-visa');
      transfer.editAmount('500');
      await accounts.setDefaultPaymentMethod(second.id, true);
      await flush();
      await flush();
      expect(transfer.methodId, 'individual-visa');
      expect(transfer.amountText, '500');
      transfer.chooseKind(PaymentMethodKind.card);
      expect(transfer.methodId, second.id);
      final withdrawal = own(TransferStore(accounts, drafts));
      await withdrawal.load(InvestorTransferKind.withdrawal);
      expect(withdrawal.methodId, isNull);
    },
  );

  test(
    'One-time cards clear form secrets and are removed after one charge, with replay protection',
    () async {
      final form = own(PaymentMethodsStore(accounts));
      expect(form.cardComplete, false);
      for (final entry in {
        'holder': 'Investor',
        'number': '4111111111111111',
        'expiry': '12/29',
        'cvv': '123',
        'save': 'false',
      }.entries) {
        form.edit(entry.key, entry.value);
      }
      expect(form.cardComplete, true);
      expect(await form.save(PaymentMethodKind.card), true);
      expect(form.values, isEmpty);
      expect(form.formRevision, 1);
      final id = form.lastSavedId!;
      final method = (await snapshot()).paymentMethods.singleWhere(
        (method) => method.id == id,
      );
      expect(method.reusable, false);
      expect(method.lastFour, '1111');
      final operation = accounts.newOperationId();
      for (var attempt = 0; attempt < 2; attempt++) {
        expect(
          await accounts.addMoney(
            amount: const MonetaryAmount(50000, Currency.zar),
            methodId: id,
            operationId: operation,
            pin: '1234',
          ),
          isA<Success<InvestorOperationReceipt>>(),
        );
      }
      final after = await snapshot();
      expect(after.paymentMethods.any((method) => method.id == id), false);
      expect(after.balance(Currency.zar).minorUnits, 1068201);
      expect(
        await accounts.addMoney(
          amount: const MonetaryAmount(50000, Currency.zar),
          methodId: id,
          operationId: accounts.newOperationId(),
          pin: '1234',
        ),
        isA<Failure<InvestorOperationReceipt>>(),
      );
    },
  );

  test(
    'Saved cards remain reusable and payment forms survive failure for correction',
    () async {
      final form = own(PaymentMethodsStore(accounts));
      for (final entry in {
        'holder': 'Investor',
        'number': 'invalid',
        'expiry': '12/29',
        'cvv': '123',
        'save': 'true',
      }.entries) {
        form.edit(entry.key, entry.value);
      }
      expect(await form.save(PaymentMethodKind.card), false);
      expect(form.values['number'], 'invalid');
      form.edit('number', '4111111111111111');
      expect(await form.save(PaymentMethodKind.card), true);
      expect(
        (await snapshot()).paymentMethods
            .singleWhere((method) => method.id == form.lastSavedId)
            .reusable,
        true,
      );
      expect(await form.remove(form.lastSavedId!), true);
      expect(
        (await snapshot()).paymentMethods.any(
          (method) => method.id == form.lastSavedId,
        ),
        false,
      );
    },
  );

  test(
    'Custom PIN and simulated biometrics share authorization and reset on logout',
    () async {
      expect(authorization.setPin('9876'), true);
      final store = own(TransferStore(accounts, drafts));
      await store.load(InvestorTransferKind.topUp);
      store.chooseKind(PaymentMethodKind.card);
      store.editAmount('100');
      store.review();
      store.authorize();
      expect(await store.confirm('1234'), false);
      expect(await store.confirm('', simulateBiometric: true), true);
      expect(authorization.verifyPin('9876'), true);
      session.signOut();
      expect(authorization.verifyPin('9876'), false);
      expect(authorization.simulateBiometric(), false);
      session.signIn(
        const AppUser(id: 'other', name: 'Other', email: 'other@example.test'),
      );
      expect(authorization.verifyPin('1234'), true);
      expect(authorization.verifyPin('9876'), false);
    },
  );

  test(
    'Transactions, notifications and portfolio filters track account changes',
    () async {
      final transactions = own(TransactionsStore(accounts));
      final notifications = own(InvestorNotificationsStore(accounts));
      final portfolio = own(PortfolioStore(accounts));
      await Future.wait([
        transactions.load(),
        notifications.load(),
        portfolio.load(),
      ]);
      transactions.setFilter(InvestorTransactionKind.topUp);
      expect(
        transactions.transactions.every(
          (item) => item.kind == InvestorTransactionKind.topUp,
        ),
        true,
      );
      portfolio.setFilter(InvestorInvestmentStatus.completed);
      expect(portfolio.investments.length, 5);
      expect(
        portfolio.investments.every(
          (item) => item.status == InvestorInvestmentStatus.completed,
        ),
        true,
      );
      expect(await notifications.markRead(), true);
      await flush();
      expect(
        notifications.data!.notifications.every((item) => item.read),
        true,
      );
      session.signOut();
      await flush();
      expect(transactions.data, isNull);
      expect(notifications.data, isNull);
      expect(portfolio.data, isNull);
    },
  );

  test(
    'Signup verifies the challenge, stores the selected PIN and starts a clean account',
    () async {
      session.signOut();
      final auth = MockAuthRepository(MockBehavior(delay: Duration.zero));
      final store = own(InvestorSignupStore(auth, session, authorization));
      store.nonResident = true;
      expect(await store.createProfile(), false);
      for (final entry in {
        'name': 'New Investor',
        'email': 'new@example.test',
        'phone': '821234567',
        'password': 'SafePassword1!',
        'confirmation': 'SafePassword1!',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(await store.createProfile(), true);
      expect(session.isAuthenticated, false);
      store.setCode('111111');
      expect(await store.verify(), false);
      store.setCode('123456');
      expect(await store.verify(), true);
      store.continueVerified();
      store.setPin('9876');
      expect(store.continuePin(), true);
      store.continueBiometrics();
      store.completeSecurity();
      expect(await store.finish(), true);
      expect(session.experience, Experience.investor);
      expect(session.user!.nonResident, true);
      expect(session.user!.countryCode, 'US');
      expect(authorization.verifyPin('9876'), true);
      expect(store.values, isEmpty);
      expect(store.pin, isEmpty);
      expect(store.code, isEmpty);
      expect((await snapshot()).verification, VerificationStatus.incomplete);
      expect((await snapshot()).investments, isEmpty);
      expect((await snapshot()).transactions, isEmpty);
    },
  );
}
