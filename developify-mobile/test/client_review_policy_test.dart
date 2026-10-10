import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/di/app_dependencies.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/storage/session_storage.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_catalog_repository.dart';
import 'package:developify_mobile/features/investor/domain/account_summary.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/portfolio_analytics.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investment_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_home_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/portfolio_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/wallet_store.dart';

const _user = AppUser(
  id: 'review-user',
  name: 'Investor',
  email: 'review@example.test',
);
MonetaryAmount _rand(int cents) => MonetaryAmount(cents, Currency.zar);

class _MemorySessionStorage implements SessionStorage {
  String? value;
  Completer<void>? pendingRead;
  @override
  Future<String?> read() async {
    await pendingRead?.future;
    return value;
  }

  @override
  Future<void> write(String record) async {
    value = record;
  }
}

void main() {
  test(
    'Fresh, restored, expired and logged-out sessions default to Investor',
    () async {
      final storage = _MemorySessionStorage();
      final now = DateTime.utc(2026, 9, 18);
      final original = SessionService(storage: storage, now: () => now);
      expect(original.experience, Experience.investor);
      expect(original.onboardingComplete, false);
      original.signIn(
        _user,
        experience: Experience.landowner,
        expiresAt: now.add(const Duration(hours: 2)),
      );
      await original.persistenceComplete;
      final restored = SessionService(storage: storage, now: () => now);
      storage.pendingRead = Completer<void>();
      final restore = restored.restore();
      expect(restored.restoring, true);
      storage.pendingRead!.complete();
      await restore;
      expect(restored.isAuthenticated, true);
      expect(restored.user!.id, _user.id);
      expect(restored.experience, Experience.investor);
      restored.selectExperience(Experience.landowner);
      expect(restored.isAuthenticated, true);
      final expired = SessionService(
        storage: storage,
        now: () => now.add(const Duration(days: 2)),
      );
      await expired.restore();
      expect(expired.isAuthenticated, false);
      expect(expired.onboardingComplete, true);
      restored.signOut();
      await restored.persistenceComplete;
      final loggedOut = SessionService(storage: storage, now: () => now);
      await loggedOut.restore();
      expect(loggedOut.isAuthenticated, false);
      expect(loggedOut.returningUser!.id, _user.id);
      expect(jsonDecode(storage.value!)['user'], isNull);
      for (final service in [original, restored, expired, loggedOut]) {
        service.dispose();
      }
    },
  );

  test(
    'Expiry revokes account scope and selected entity survives restoration',
    () async {
      final storage = _MemorySessionStorage();
      var now = DateTime.utc(2026, 9, 18);
      final session = SessionService(storage: storage, now: () => now);
      session.signIn(_user, expiresAt: now.add(const Duration(seconds: 1)));
      final context = InvestorAccountContext(session);
      context.selectEntity(EntityType.company);
      final scope = context.scope!;
      await session.persistenceComplete;
      final restored = SessionService(storage: storage, now: () => now);
      await restored.restore();
      expect(restored.user!.entity, EntityType.company);
      now = now.add(const Duration(seconds: 2));
      expect(context.scope, isNull);
      expect(context.isCurrent(scope), false);
      session.startExpiryMonitoring();
      await Future<void>.delayed(Duration.zero);
      expect(session.user, isNull);
      expect(session.returningUser!.id, _user.id);
      context.dispose();
      session.dispose();
      restored.dispose();
    },
  );

  test('Malformed persisted mock sessions never authenticate', () async {
    for (final value in [
      'bad json',
      '{"version": 77}',
      '{"version":1,"user":{"id":"bad"}}',
    ]) {
      final storage = _MemorySessionStorage()..value = value;
      final session = SessionService(storage: storage);
      await session.restore();
      expect(session.isAuthenticated, false);
      expect(session.restoring, false);
      session.dispose();
    }
  });

  group('Account-scoped ZAR investment policies', () {
    late AppDependencies dependencies;
    late MockInvestorCatalogRepository catalog;
    late MockInvestorAccountRepository account;
    Future<InvestorAccountSnapshot> snapshot() async =>
        (await account.snapshot() as Success<InvestorAccountSnapshot>).value;
    setUp(() async {
      dependencies = await AppDependencies.create(
        environment: const AppEnvironment(mockDelay: Duration.zero),
      );
      dependencies.session.signIn(_user);
      catalog =
          dependencies.container<InvestorCatalogRepository>()
              as MockInvestorCatalogRepository;
      account =
          dependencies.container<InvestorAccountRepository>()
              as MockInvestorAccountRepository;
    });
    tearDown(() => dependencies.dispose());

    test('Every fixture uses ZAR and the authoritative R1 minimum', () async {
      final projects =
          (await catalog.projects() as Success<List<InvestorProject>>).value;
      for (final project in projects) {
        expect(project.target.currency, Currency.zar);
        expect(project.raised!.currency, Currency.zar);
        expect(project.minimumInvestment, _rand(100));
        expect(project.maximumInvestment.currency, Currency.zar);
      }
      final data = await snapshot();
      expect(data.balances.keys, [Currency.zar]);
      expect(
        data.investments.every(
          (h) =>
              h.amount.currency == Currency.zar &&
              h.projectedPayout.currency == Currency.zar &&
              h.earned.currency == Currency.zar,
        ),
        true,
      );
      expect(
        data.transactions.every(
          (t) =>
              t.amount.currency == Currency.zar &&
              t.fee.currency == Currency.zar,
        ),
        true,
      );
    });

    for (final text in ['', '0', '0.99', '-1', '1.001', 'NaN', '1e6']) {
      test(
        'Rejects invalid investment $text without wallet mutation',
        () async {
          final store = dependencies.container<InvestmentStore>();
          addTearDown(store.dispose);
          await store.load('marula-heights');
          final before = await snapshot();
          store.editAmount(text);
          expect(store.validAmount, false);
          expect(store.review(), false);
          expect((await snapshot()).balances, before.balances);
        },
      );
    }
    for (final cents in [100, 101]) {
      test(
        'R${cents / 100} passes review and authorized final submission',
        () async {
          final store = dependencies.container<InvestmentStore>();
          addTearDown(store.dispose);
          await store.load('marula-heights', initialAmountCents: '$cents');
          expect(store.validAmount, true);
          expect(store.review(), true);
          store.setAgreement(true);
          store.authorize();
          expect(await store.confirm('1234'), true);
          expect((await snapshot()).investments.first.amount, _rand(cents));
        },
      );
    }

    test(
      'Home combines one atomic snapshot; transfers and principal returns reconcile',
      () async {
        final before = await snapshot();
        final home = dependencies.container<InvestorHomeStore>();
        addTearDown(home.dispose);
        await home.load();
        final observed = <int>[];
        final subscription = account.changes.listen((_) async {
          observed.add(
            InvestorAccountSummary.from(
              await snapshot(),
            ).overallBalance.minorUnits,
          );
        });
        addTearDown(subscription.cancel);
        final original = InvestorAccountSummary.from(before).overallBalance;
        await account.addMoney(
          amount: _rand(50000),
          methodId: InvestorDepositAccount.method.id,
          operationId: account.newOperationId(),
          pin: '1234',
        );
        expect(
          InvestorAccountSummary.from(await snapshot()).overallBalance,
          original + _rand(50000),
        );
        final receipt =
            (await account.invest(
                      project: catalog.currentProject('marula-heights')!,
                      amount: _rand(10000),
                      operationId: account.newOperationId(),
                      pin: '1234',
                    )
                    as Success<InvestorOperationReceipt>)
                .value;
        expect(
          InvestorAccountSummary.from(await snapshot()).overallBalance,
          original + _rand(50000),
        );
        await account.simulatePrincipalReturn(receipt.investmentId!);
        await account.simulatePrincipalReturn(receipt.investmentId!);
        final returned = await snapshot();
        expect(
          InvestorAccountSummary.from(returned).overallBalance,
          original + _rand(50000),
        );
        expect(
          InvestorAccountSummary.from(returned).investedCapital,
          InvestorAccountSummary.from(before).investedCapital,
        );
        expect(
          returned.transactions
              .where(
                (t) =>
                    t.kind == InvestorTransactionKind.refund &&
                    t.description == 'Simulated principal return',
              )
              .length,
          1,
        );
        await account.withdraw(
          amount: _rand(10000),
          methodId: 'individual-bank',
          operationId: account.newOperationId(),
          pin: '1234',
        );
        final expected = original + _rand(40000);
        expect(
          InvestorAccountSummary.from(await snapshot()).overallBalance,
          expected,
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(
          InvestorAccountSummary.from(home.data!).overallBalance,
          expected,
        );
        expect(
          observed.every(
            (c) => c == original.minorUnits + 50000 || c == expected.minorUnits,
          ),
          true,
        );
      },
    );

    test('Privacy is synchronous, shared, rebuild-safe, and scoped', () async {
      final home = dependencies.container<InvestorHomeStore>();
      final wallet = dependencies.container<WalletStore>();
      final portfolio = dependencies.container<PortfolioStore>();
      addTearDown(home.dispose);
      addTearDown(wallet.dispose);
      addTearDown(portfolio.dispose);
      await Future.wait([home.load(), wallet.load(), portfolio.load()]);
      home.toggleBalance();
      expect(home.balanceVisible, false);
      expect(wallet.balanceVisible, false);
      expect(portfolio.balanceVisible, false);
      await home.load();
      final rebuilt = dependencies.container<InvestorHomeStore>();
      addTearDown(rebuilt.dispose);
      expect(rebuilt.balanceVisible, false);
      dependencies.session.selectExperience(Experience.landowner);
      dependencies.session.selectExperience(Experience.investor);
      expect(home.balanceVisible, false);
      final scope = dependencies.container<InvestorAccountContext>();
      scope.selectEntity(EntityType.company);
      expect(home.balanceVisible, true);
      scope.selectEntity(EntityType.individual);
      expect(home.balanceVisible, false);
    });

    test(
      'Latest exact capacity is rechecked after PIN authorization',
      () async {
        final store = dependencies.container<InvestmentStore>();
        addTearDown(store.dispose);
        await store.load('marula-heights', initialAmountCents: '100');
        expect(store.review(), true);
        store.setAgreement(true);
        store.authorize();
        final before = await snapshot();
        final project = catalog.currentProject('marula-heights')!;
        catalog.simulateFunding(project.id, project.target);
        expect(store.project!.canInvest, false);
        expect(await store.confirm('1234'), false);
        final after = await snapshot();
        expect(after.balances, before.balances);
        expect(after.investments, before.investments);
        expect(after.transactions, before.transactions);
        expect(store.receipt, isNull);
        expect(store.error, contains('fully funded'));
      },
    );

    test(
      'Missing, invalid, closed, full and subminimum capacity fail closed',
      () async {
        final p = catalog.currentProject('marula-heights')!;
        for (final raised in [
          null,
          _rand(-1),
          p.target,
          p.target + _rand(1),
          p.target - _rand(99),
          MonetaryAmount(0, Currency.usd),
        ]) {
          catalog.simulateFunding(p.id, raised);
          expect(catalog.currentProject(p.id)!.canInvest, false);
          final before = await snapshot();
          expect(
            await account.invest(
              project: p,
              amount: _rand(100),
              operationId: account.newOperationId(),
              pin: '1234',
            ),
            isA<Failure<InvestorOperationReceipt>>(),
          );
          expect((await snapshot()).balances, before.balances);
        }
        catalog.simulateFunding(p.id, _rand(0), acceptingInvestments: false);
        expect(catalog.currentProject(p.id)!.canInvest, false);
      },
    );

    test(
      'Capacity uses cents, rejects excess, serializes competing submissions and replays once',
      () async {
        final p = catalog.currentProject('marula-heights')!;
        catalog.simulateFunding(p.id, p.target - _rand(150));
        final nearlyFull = catalog.currentProject(p.id)!;
        expect(nearlyFull.fundedBasisPoints, 9999);
        expect(nearlyFull.canInvest, true);
        final before = await snapshot();
        expect(
          await account.invest(
            project: p,
            amount: _rand(151),
            operationId: account.newOperationId(),
            pin: '1234',
          ),
          isA<Failure<InvestorOperationReceipt>>(),
        );
        final id = account.newOperationId();
        final results = await Future.wait([
          account.invest(
            project: p,
            amount: _rand(100),
            operationId: id,
            pin: '1234',
          ),
          account.invest(
            project: p,
            amount: _rand(100),
            operationId: account.newOperationId(),
            pin: '1234',
          ),
        ]);
        expect(
          results.whereType<Success<InvestorOperationReceipt>>().length,
          1,
        );
        expect(
          results.whereType<Failure<InvestorOperationReceipt>>().length,
          1,
        );
        expect(
          await account.invest(
            project: p,
            amount: _rand(100),
            operationId: id,
            pin: '1234',
          ),
          isA<Success<InvestorOperationReceipt>>(),
        );
        expect(
          (await snapshot()).balance(Currency.zar),
          before.balance(Currency.zar) - _rand(100),
        );
        expect(catalog.currentProject(p.id)!.remainingCapacity, _rand(50));
      },
    );

    test(
      'Projects preserve their configured rate and unsupported terms are explicit',
      () async {
        final a = catalog.currentProject('saffron-towers')!;
        final b = catalog.currentProject('saffron-hospitality')!;
        expect(a.projectedPayout(_rand(10000)), _rand(14350));
        expect(b.projectedPayout(_rand(10000)), _rand(13420));
        final schedule = a.projection(_rand(10000));
        expect(schedule.distributionCount, 36);
        expect(schedule.payments.map((p) => p.minorUnits), [
          ...List.filled(30, 121),
          ...List.filled(6, 120),
        ]);
        expect(
          schedule.payments.fold<int>(0, (sum, p) => sum + p.minorUnits),
          schedule.earnings.minorUnits,
        );
        expect(
          () => InvestmentProjection(
            principal: _rand(100),
            annualRateBasisPoints: 1450,
            termMonths: 17,
          ),
          throwsArgumentError,
        );
        final longer = InvestmentProjection(
          principal: _rand(10000),
          annualRateBasisPoints: 1140,
          termMonths: 36,
        );
        expect(longer.distributionCount, 12);
        expect(longer.payout, _rand(13420));
      },
    );

    test('The supplied example document belongs only to Marula', () {
      expect(
        catalog
            .currentProject('marula-heights')!
            .content!
            .documents
            .single
            .name,
        'CIPC_CoR14_3_Marula',
      );
      expect(
        catalog.currentProject('saffron-towers')!.content!.documents,
        isEmpty,
      );
    });
  });

  test(
    'R1000 wallet plus R2500 capital equals R3500, with duplicates and released holdings excluded',
    () {
      InvestorInvestment holding(
        String id,
        int cents,
        InvestorInvestmentStatus status,
      ) => InvestorInvestment(
        id: id,
        projectId: id,
        projectName: id,
        location: '',
        amount: _rand(cents),
        earned: _rand(0),
        projectedPayout: _rand(cents + 100),
        createdAt: DateTime.utc(2026),
        status: status,
        progressBasisPoints: 5000,
        imageAsset: '',
      );
      final active = holding('active', 250000, InvestorInvestmentStatus.active);
      final snapshot = InvestorAccountSnapshot(
        balances: {Currency.zar: 100000},
        investments: [
          active,
          active,
          holding('released', 99999, InvestorInvestmentStatus.completed),
        ],
        transactions: [],
        notifications: [],
        paymentMethods: [],
        verification: VerificationStatus.verified,
        asOf: DateTime.utc(2026),
      );
      expect(
        InvestorAccountSummary.from(snapshot).overallBalance,
        _rand(350000),
      );
      expect(
        PortfolioAnalytics.from(snapshot, PortfolioPeriod.month).capital,
        _rand(250000),
      );
    },
  );

  test(
    'Rapid favourite intents converge and errors restore confirmed account state',
    () async {
      final session = SessionService()..signIn(_user);
      final context = InvestorAccountContext(session);
      final behavior = MockBehavior(delay: const Duration(milliseconds: 5));
      final catalog = MockInvestorCatalogRepository(behavior, context);
      addTearDown(() {
        catalog.dispose();
        context.dispose();
        session.dispose();
      });
      final pending = [
        catalog.setFavourite('marula-heights', true),
        catalog.setFavourite('marula-heights', false),
        catalog.setFavourite('marula-heights', true),
      ];
      expect(catalog.favouriteIds, contains('marula-heights'));
      await Future.wait(pending);
      behavior.failNext(2);
      await Future.wait([
        catalog.setFavourite('marula-heights', false),
        catalog.setFavourite('marula-heights', true),
      ]);
      expect(catalog.favouriteIds, contains('marula-heights'));
      final cancelled = catalog.setFavourite('marula-heights', false);
      context.selectEntity(EntityType.company);
      await cancelled;
      expect(catalog.favouriteIds, isEmpty);
      context.selectEntity(EntityType.individual);
      expect(catalog.favouriteIds, contains('marula-heights'));
      final stale = catalog.setFavourite('marula-heights', false);
      session.signOut();
      session.signIn(
        const AppUser(id: 'other', name: 'Other', email: 'other@example.test'),
      );
      await stale;
      expect(catalog.favouriteIds, isEmpty);
    },
  );
}
