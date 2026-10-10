import 'package:developify_mobile/features/investor/data/investor_transaction_fixtures.dart';
import 'dart:async';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_transfer_fees.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class MockInvestorAccountRepository implements InvestorAccountRepository {
  MockInvestorAccountRepository(
    this.behavior,
    this._context, {
    this.scenario = MockScenario.success,
    DateTime Function()? now,
    this.authorization,
    this.catalog,
  }) : _now = now ?? DateTime.now {
    _userId = _context.scope?.userId;
    _scopeChanges = _context.changes.listen((scope) {
      for (final cancellation in _pending.toList()) {
        cancellation.cancel();
      }
      if (scope?.userId != _userId) {
        _accounts.clear();
        _userId = scope?.userId;
      }
      _emit(const {InvestorDataKind.scope});
    });
  }

  final MockBehavior behavior;
  final MockScenario scenario;
  final DateTime Function() _now;
  final TransactionAuthorization? authorization;
  final InvestorCatalogRepository? catalog;
  final InvestorAccountContext _context;
  final _accounts = <EntityType, _Account>{};
  final _pending = <Cancellation>{};
  final _changes = StreamController<InvestorAccountChange>.broadcast(
    sync: true,
  );
  late final StreamSubscription<InvestorScope?> _scopeChanges;
  String? _userId;
  bool _disposed = false;
  int _sequence = 0;

  @override
  Stream<InvestorAccountChange> get changes => _changes.stream;

  @override
  String newOperationId() => '${_context.entity.name}-operation-${++_sequence}';

  void _emit(Set<InvestorDataKind> kinds) {
    if (!_disposed) _changes.add(InvestorAccountChange(kinds));
  }

  _Account _account(EntityType entity) => _accounts.putIfAbsent(
    entity,
    () => _Account.create(
      entity,
      (_userId?.startsWith('local-investor-') ?? false)
          ? MockScenario.incompleteKyc
          : scenario,
      behavior.empty || (_userId?.startsWith('local-investor-') ?? false),
    ),
  );

  Future<Result<T>> _run<T>(
    Result<T> Function(_Account account) operation, {
    Set<InvestorDataKind> changed = const {},
  }) async {
    final scope = _context.scope;
    if (_disposed || scope == null) {
      return const Failure(
        AppFailure(FailureKind.unauthenticated, 'Sign in to continue.'),
      );
    }
    final cancellation = Cancellation();
    _pending.add(cancellation);
    try {
      final gate = await behavior.run(() => true, cancellation: cancellation);
      if (gate case Failure(:final error)) return Failure(error);
      if (_disposed || !_context.isCurrent(scope)) {
        return const Failure(
          AppFailure(
            FailureKind.cancelled,
            'The selected profile changed. Please try again.',
          ),
        );
      }
      final result = operation(_account(scope.entity));
      if (result.isSuccess && changed.isNotEmpty) _emit(changed);
      return result;
    } finally {
      _pending.remove(cancellation);
    }
  }

  @override
  Future<Result<InvestorAccountSnapshot>> snapshot() =>
      _run((account) => Success(account.snapshot));

  @override
  Future<Result<InvestorTransaction>> transaction(String id) => _run(
    (account) =>
        _find(account.transactions, (item) => item.id == id, 'transaction'),
  );

  @override
  Future<Result<InvestorInvestment>> investment(String id) => _run(
    (account) =>
        _find(account.investments, (item) => item.id == id, 'investment'),
  );

  @override
  Future<Result<InvestorNotification>> notification(String id) => _run(
    (account) =>
        _find(account.notifications, (item) => item.id == id, 'notification'),
  );

  Result<T> _find<T>(
    Iterable<T> values,
    bool Function(T) matches,
    String label,
  ) {
    if (scenario != MockScenario.missingItem) {
      for (final value in values) {
        if (matches(value)) return Success(value);
      }
    }
    return Failure(
      AppFailure(FailureKind.notFound, 'This $label could not be found.'),
    );
  }

  @override
  Future<Result<void>> markNotificationsRead([String? id]) => _run((account) {
    if (id != null && !account.notifications.any((item) => item.id == id)) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This notification could not be found.',
        ),
      );
    }
    account.notifications = [
      for (final item in account.notifications)
        if (id == null || item.id == id) item.markRead() else item,
    ];
    return const Success(null);
  }, changed: const {InvestorDataKind.notifications});

  @override
  Future<Result<InvestorOperationReceipt>> invest({
    required InvestorProject project,
    required MonetaryAmount amount,
    required String operationId,
    required String pin,
    InvestmentProjection? quote,
    bool simulateBiometric = false,
  }) => _run(
    (account) {
      final validation = _authorize(
        amount,
        operationId,
        pin,
        simulateBiometric: simulateBiometric,
      );
      if (validation != null) return Failure(validation);
      final signature =
          'invest|${project.id}|${amount.currency.name}|${amount.minorUnits}|${quote?.annualRateBasisPoints ?? project.annualReturnBasisPoints}|${quote?.termMonths ?? project.durationMonths}|${quote?.payoutEveryMonths ?? InvestmentPolicy.payoutEveryMonths}';
      final replay = _replay(account, operationId, signature);
      if (replay != null) return replay;
      if (account.verification != VerificationStatus.verified) {
        return const Failure(
          AppFailure(
            FailureKind.forbidden,
            'Complete verification before investing.',
          ),
        );
      }
      // Recheck terms and capacity after authorization. The live backend must
      // atomically reserve capacity and execute the idempotent financial write.
      final latest = catalog?.currentProject(project.id);
      if (latest == null) {
        return const Failure(
          AppFailure(
            FailureKind.notFound,
            'This project could not be found. Please reload it.',
          ),
        );
      }
      final eligibilityError = latest.validateInvestment(amount);
      if (eligibilityError != null) {
        return Failure(AppFailure(FailureKind.validation, eligibilityError));
      }
      if (!project.supportsProjection ||
          !(quote ?? project.projection(amount)).matches(
            latest.projection(amount),
          )) {
        return const Failure(
          AppFailure(
            FailureKind.validation,
            'The project terms changed. Enter the amount again to review a new quote.',
          ),
        );
      }
      project = latest;
      final projection = quote ?? project.projection(amount);
      if (amount.minorUnits > (account.balances[amount.currency] ?? 0)) {
        return const Failure(
          AppFailure(
            FailureKind.validation,
            'Your wallet balance is too low. Add funds to continue.',
            fields: {'amount': 'Insufficient balance'},
          ),
        );
      }
      final contribution = catalog!.contribute(project.id, amount);
      if (contribution case Failure(:final error)) return Failure(error);
      final transactionId =
          '${_context.entity.name}-transaction-${++_sequence}';
      final investmentId = '${_context.entity.name}-investment-${++_sequence}';
      final createdAt = _now().toUtc();
      account.balances[amount.currency] =
          account.balances[amount.currency]! - amount.minorUnits;
      account.investments.insert(
        0,
        InvestorInvestment(
          id: investmentId,
          projectId: project.id,
          projectName: project.name,
          location: '${project.city}, ${project.country}',
          amount: amount,
          earned: MonetaryAmount(0, amount.currency),
          projectedPayout: projection.payout,
          createdAt: createdAt,
          status: InvestorInvestmentStatus.active,
          recordedMilestone: InvestmentMilestoneStage.confirmed,
          progressBasisPoints: project.fundedBasisPoints,
          imageAsset: project.heroAsset ?? project.imageAsset,
          category: project.category,
          durationMonths: project.durationMonths,
          payoutEveryMonths: projection.payoutEveryMonths,
          annualRateBasisPoints: projection.annualRateBasisPoints,
          thumbnailAsset: project.thumbnailAsset,
        ),
      );
      account.transactions.insert(
        0,
        InvestorTransaction(
          id: transactionId,
          title: project.name,
          kind: InvestorTransactionKind.investment,
          status: InvestorTransactionStatus.successful,
          amount: MonetaryAmount(-amount.minorUnits, amount.currency),
          fee: MonetaryAmount(0, amount.currency),
          createdAt: createdAt,
          reference: transactionId,
          projectId: project.id,
          projectTerms: InvestorTransactionProject(
            name: project.name,
            distributionPayout: projection.payments.first,
            payoutEveryMonths: projection.payoutEveryMonths,
            projection: projection,
            durationMonths: project.durationMonths,
          ),
          description: 'Simulated investment',
        ),
      );
      account.notifications.insert(
        0,
        InvestorNotification(
          id: '${_context.entity.name}-notification-${++_sequence}',
          title: 'Investment confirmed',
          kind: InvestorNotificationKind.investment,
          message:
              'Your simulated investment in ${project.name} is in your portfolio.',
          createdAt: createdAt,
          destination: InvestorDestination.investment,
          targetId: investmentId,
        ),
      );
      final receipt = InvestorOperationReceipt(
        transactionId: transactionId,
        investmentId: investmentId,
      );
      account.receipts[operationId] = receipt;
      account.requests[operationId] = signature;
      return Success(receipt);
    },
    changed: const {
      InvestorDataKind.wallet,
      InvestorDataKind.portfolio,
      InvestorDataKind.transactions,
      InvestorDataKind.notifications,
    },
  );

  AppFailure? _authorize(
    MonetaryAmount amount,
    String operationId,
    String pin, {
    bool simulateBiometric = false,
  }) {
    if (!RegExp(r'^[a-z]+-operation-\d+$').hasMatch(operationId) ||
        !operationId.startsWith('${_context.entity.name}-')) {
      return const AppFailure(
        FailureKind.validation,
        'This confirmation has expired. Please start again.',
      );
    }
    if (!(simulateBiometric
        ? (authorization?.simulateBiometric() ?? true)
        : (authorization?.verifyPin(pin) ?? (pin == '1234')))) {
      return const AppFailure(
        FailureKind.validation,
        'Incorrect PIN. Please try again.',
        fields: {'pin': 'Incorrect PIN'},
      );
    }
    if (amount.minorUnits <= 0 ||
        amount.minorUnits > 25000000 ||
        scenario == MockScenario.validationFailure) {
      return const AppFailure(
        FailureKind.validation,
        'Enter an amount greater than zero and no more than 250,000.',
        fields: {'amount': 'Check the amount'},
      );
    }
    return null;
  }

  @override
  Future<Result<InvestorOperationReceipt>> addMoney({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  }) => _run(
    (account) {
      final validation = _authorize(
        amount,
        operationId,
        pin,
        simulateBiometric: simulateBiometric,
      );
      if (validation != null) return Failure(validation);
      if (amount.currency != Currency.zar) {
        return const Failure(
          AppFailure(FailureKind.validation, 'Only ZAR is supported.'),
        );
      }
      final signature =
          'topUp|$methodId|${amount.currency.name}|${amount.minorUnits}';
      final replay = _replay(account, operationId, signature);
      if (replay != null) return replay;
      final method = methodId == InvestorDepositAccount.method.id
          ? InvestorDepositAccount.method
          : account.methods
                .where((method) => method.id == methodId)
                .firstOrNull;
      if (method == null || scenario == MockScenario.paymentMethodUnavailable) {
        return const Failure(
          AppFailure(
            FailureKind.validation,
            'Select an available payment method.',
          ),
        );
      }
      final fee = method.kind == PaymentMethodKind.card
          ? InvestorTransferFees.cardTopUp(amount)
          : MonetaryAmount(0, amount.currency);
      account.balances[amount.currency] =
          (account.balances[amount.currency] ?? 0) + amount.minorUnits;
      if (!method.reusable) {
        account.methods.removeWhere((item) => item.id == method.id);
      }
      return Success(
        _recordTransfer(
          account,
          amount,
          fee,
          method,
          operationId,
          InvestorTransactionKind.topUp,
        ),
      );
    },
    changed: const {
      InvestorDataKind.wallet,
      InvestorDataKind.transactions,
      InvestorDataKind.methods,
    },
  );

  @override
  Future<Result<InvestorOperationReceipt>> withdraw({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  }) => _run((account) {
    final validation = _authorize(
      amount,
      operationId,
      pin,
      simulateBiometric: simulateBiometric,
    );
    if (validation != null) return Failure(validation);
    final signature =
        'withdrawal|$methodId|${amount.currency.name}|${amount.minorUnits}';
    final replay = _replay(account, operationId, signature);
    if (replay != null) return replay;
    if (scenario == MockScenario.withdrawalUnavailable ||
        account.verification != VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.forbidden,
          'Withdrawals are unavailable until verification is complete.',
        ),
      );
    }
    final methods = account.methods.where(
      (method) =>
          method.id == methodId && method.kind == PaymentMethodKind.bankAccount,
    );
    if (methods.isEmpty) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Add a bank account before withdrawing.',
        ),
      );
    }
    if (amount.currency != InvestorTransferFees.withdrawal.currency ||
        amount.minorUnits <= InvestorTransferFees.withdrawal.minorUnits) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This demo supports ZAR withdrawals greater than the 1.50 processing fee.',
        ),
      );
    }
    if (amount.minorUnits > (account.balances[amount.currency] ?? 0)) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'The amount exceeds your available balance.',
          fields: {'amount': 'Insufficient balance'},
        ),
      );
    }
    account.balances[amount.currency] =
        account.balances[amount.currency]! - amount.minorUnits;
    return Success(
      _recordTransfer(
        account,
        MonetaryAmount(-amount.minorUnits, amount.currency),
        InvestorTransferFees.withdrawal,
        methods.first,
        operationId,
        InvestorTransactionKind.withdrawal,
      ),
    );
  }, changed: const {InvestorDataKind.wallet, InvestorDataKind.transactions});

  InvestorOperationReceipt _recordTransfer(
    _Account account,
    MonetaryAmount amount,
    MonetaryAmount fee,
    InvestorPaymentMethod method,
    String operationId,
    InvestorTransactionKind kind,
  ) {
    final id = '${_context.entity.name}-transaction-${++_sequence}';
    account.transactions.insert(
      0,
      InvestorTransaction(
        id: id,
        title: kind == InvestorTransactionKind.topUp
            ? 'Wallet Top - Up'
            : 'Withdrawal to bank',
        kind: kind,
        status: InvestorTransactionStatus.successful,
        amount: amount,
        fee: fee,
        createdAt: _now().toUtc(),
        reference: id,
        methodId: method.id,
        paymentMethod: method,
        paymentMethodIsDestination:
            method.kind == PaymentMethodKind.bankAccount,
        description: 'Simulation only. No money was moved.',
      ),
    );
    final receipt = InvestorOperationReceipt(transactionId: id);
    account.receipts[operationId] = receipt;
    account.requests[operationId] =
        '${kind.name}|${method.id}|${amount.currency.name}|${amount.minorUnits.abs()}';
    return receipt;
  }

  @override
  Future<Result<InvestorPaymentMethod>> addCard({
    required String cardNumber,
    required String holder,
    required String expiry,
    required String securityCode,
    bool reusable = true,
  }) => _run((account) {
    final digits = cardNumber.replaceAll(' ', '');
    final normalizedExpiry = expiry.replaceAll(RegExp(r'\s'), '');
    if (!_validCard(digits) ||
        holder.trim().isEmpty ||
        !_validExpiry(normalizedExpiry) ||
        !RegExp(r'^\d{3,4}$').hasMatch(securityCode)) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Check the card details and try again.',
        ),
      );
    }
    final method = InvestorPaymentMethod(
      id: '${_context.entity.name}-card-${++_sequence}',
      kind: PaymentMethodKind.card,
      name: digits.startsWith('4') ? 'Visa' : 'Mastercard',
      lastFour: digits.substring(digits.length - 4),
      holder: holder.trim(),
      expiry: normalizedExpiry,
      reusable: reusable,
      isDefault:
          reusable &&
          !account.methods.any(
            (method) =>
                method.kind == PaymentMethodKind.card && method.isDefault,
          ),
    );
    account.methods.add(method);
    return Success(method);
  }, changed: const {InvestorDataKind.methods});

  Result<InvestorOperationReceipt>? _replay(
    _Account account,
    String id,
    String signature,
  ) {
    final receipt = account.receipts[id];
    if (receipt == null) return null;
    if (account.requests[id] != signature) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'The confirmation details changed. Start a new confirmation.',
        ),
      );
    }
    return Success(receipt);
  }

  bool _validExpiry(String expiry) {
    if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final expiration = DateTime(
      2000 + int.parse(parts[1]),
      int.parse(parts[0]) + 1,
    );
    return expiration.isAfter(_now());
  }

  bool _validCard(String number) {
    if (!RegExp(r'^\d{13,19}$').hasMatch(number)) return false;
    var sum = 0;
    var doubleDigit = false;
    for (var index = number.length - 1; index >= 0; index--) {
      var digit = int.parse(number[index]);
      if (doubleDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleDigit = !doubleDigit;
    }
    return sum > 0 && sum % 10 == 0;
  }

  @override
  Future<Result<InvestorPaymentMethod>> addBankAccount({
    required String bank,
    required String accountNumber,
    required String accountType,
    required String branchCode,
    required String holder,
  }) => _run((account) {
    if (bank.trim().isEmpty ||
        holder.trim().isEmpty ||
        accountType.trim().isEmpty ||
        !RegExp(r'^\d{6,16}$').hasMatch(accountNumber) ||
        !RegExp(r'^\d{6}$').hasMatch(branchCode)) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Check the bank account details and try again.',
        ),
      );
    }
    final method = InvestorPaymentMethod(
      id: '${_context.entity.name}-bank-${++_sequence}',
      kind: PaymentMethodKind.bankAccount,
      name: bank,
      lastFour: accountNumber.substring(accountNumber.length - 4),
      holder: holder.trim(),
      bankType: accountType,
      branchCode: branchCode,
      isDefault: !account.methods.any(
        (method) =>
            method.kind == PaymentMethodKind.bankAccount && method.isDefault,
      ),
    );
    account.methods.add(method);
    return Success(method);
  }, changed: const {InvestorDataKind.methods});

  @override
  Future<Result<void>> removePaymentMethod(String id) => _run((account) {
    if (!account.methods.any((method) => method.id == id)) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This payment method could not be found.',
        ),
      );
    }
    account.methods.removeWhere((method) => method.id == id);
    return const Success(null);
  }, changed: const {InvestorDataKind.methods});

  @override
  Future<Result<void>> setDefaultPaymentMethod(String id, bool isDefault) =>
      _run((account) {
        final selected = account.methods
            .where((method) => method.id == id)
            .firstOrNull;
        if (selected == null || !selected.reusable) {
          return const Failure(
            AppFailure(
              FailureKind.notFound,
              'This saved payment method could not be found.',
            ),
          );
        }
        for (var index = 0; index < account.methods.length; index++) {
          final method = account.methods[index];
          if (method.id == id || isDefault && method.kind == selected.kind) {
            account.methods[index] = method.withDefault(
              method.id == id && isDefault,
            );
          }
        }
        return const Success(null);
      }, changed: const {InvestorDataKind.methods});

  @override
  bool get balanceVisible =>
      _context.scope == null || _account(_context.entity).balanceVisible;

  @override
  void setBalanceVisible(bool visible) {
    if (_disposed || _context.scope == null) return;
    _account(_context.entity).balanceVisible = visible;
    _emit(const {InvestorDataKind.privacy});
  }

  Future<Result<void>> simulatePrincipalReturn(String investmentId) => _run(
    (account) {
      final index = account.investments.indexWhere(
        (item) => item.id == investmentId,
      );
      if (index < 0) {
        return const Failure(
          AppFailure(
            FailureKind.notFound,
            'This investment could not be found.',
          ),
        );
      }
      final holding = account.investments[index];
      if (!holding.holdsPrincipal) return const Success(null);
      account.balances[holding.amount.currency] =
          (account.balances[holding.amount.currency] ?? 0) +
          holding.amount.minorUnits;
      account.investments[index] = holding.withPrincipalReturned();
      final id = '${_context.entity.name}-refund-${++_sequence}';
      account.transactions.insert(
        0,
        InvestorTransaction(
          id: id,
          title: holding.projectName,
          kind: InvestorTransactionKind.refund,
          status: InvestorTransactionStatus.successful,
          amount: holding.amount,
          fee: MonetaryAmount(0, holding.amount.currency),
          createdAt: _now().toUtc(),
          reference: id,
          projectId: holding.projectId,
          description: 'Simulated principal return',
        ),
      );
      return const Success(null);
    },
    changed: const {
      InvestorDataKind.wallet,
      InvestorDataKind.portfolio,
      InvestorDataKind.transactions,
    },
  );

  @override
  void setVerification(VerificationStatus status, {EntityType? entity}) {
    if (_disposed || _context.scope == null) return;
    _account(entity ?? _context.entity).verification = status;
    _emit(const {InvestorDataKind.verification});
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final cancellation in _pending.toList()) {
      cancellation.cancel();
    }
    unawaited(_scopeChanges.cancel());
    _accounts.clear();
    unawaited(_changes.close());
  }
}

final class _Account {
  _Account({
    required this.balances,
    required this.verification,
    required this.methods,
    required this.transactions,
    required this.investments,
    required this.notifications,
  });

  factory _Account.create(
    EntityType entity,
    MockScenario scenario,
    bool empty,
  ) {
    final amount = empty || scenario == MockScenario.lowBalance ? 0 : 1018201;
    final verification = switch (scenario) {
      MockScenario.incompleteKyc => VerificationStatus.incomplete,
      MockScenario.pendingVerification => VerificationStatus.pending,
      MockScenario.rejectedVerification =>
        VerificationStatus.correctionRequired,
      _ => VerificationStatus.verified,
    };
    return _Account(
      balances: {Currency.zar: amount},
      verification: verification,
      methods: empty || scenario == MockScenario.paymentMethodUnavailable
          ? []
          : [
              InvestorPaymentMethod(
                id: '${entity.name}-visa',
                kind: PaymentMethodKind.card,
                name: 'Visa',
                lastFour: '2526',
                holder: 'Babatunde Yusuf',
                expiry: '09/27',
                isDefault: true,
              ),
              InvestorPaymentMethod(
                id: '${entity.name}-bank',
                kind: PaymentMethodKind.bankAccount,
                name: 'Access Bank',
                lastFour: '0119',
                holder: 'Babatunde Yusuf',
                bankType: 'Savings',
                branchCode: '250655',
                isDefault: true,
              ),
            ],
      transactions: empty || scenario == MockScenario.noTransactions
          ? []
          : investorTransactionFixtures(entity),
      investments: empty || scenario == MockScenario.noPortfolio
          ? []
          : [
              for (var index = 0; index < 3; index++)
                InvestorInvestment(
                  id: '${entity.name}-saffron-$index',
                  projectId: 'saffron-towers',
                  projectName: 'Saffron Towers',
                  location: 'Capetown, South Africa',
                  amount: const MonetaryAmount(100000, Currency.zar),
                  earned: const MonetaryAmount(7250, Currency.zar),
                  projectedPayout: const MonetaryAmount(121750, Currency.zar),
                  createdAt: DateTime.utc(2026, index + 1, 23, 11, 12),
                  status: InvestorInvestmentStatus.active,
                  recordedMilestone: index == 1
                      ? InvestmentMilestoneStage.planned
                      : InvestmentMilestoneStage.foundation,
                  thumbnailAsset: [
                    AppAssets.projectSaffronResidenceThumbnail,
                    AppAssets.projectLissanaVilla,
                    AppAssets.projectSaffronResortThumbnail,
                  ][index],
                  progressBasisPoints: 6500,
                  imageAsset: AppAssets.investorProjectHero,
                ),
              for (var index = 0; index < 5; index++)
                InvestorInvestment(
                  id: '${entity.name}-completed-saffron-$index',
                  projectId: 'saffron-towers',
                  projectName: 'Saffron Towers',
                  location: 'Capetown, South Africa',
                  amount: const MonetaryAmount(100000, Currency.zar),
                  earned: const MonetaryAmount(70050, Currency.zar),
                  projectedPayout: const MonetaryAmount(170050, Currency.zar),
                  createdAt: DateTime.utc(2024, index + 1, 23, 11, 12),
                  status: InvestorInvestmentStatus.completed,
                  thumbnailAsset: index == 0
                      ? AppAssets.projectSaffronResidenceThumbnail
                      : AppAssets.projectLissanaVilla,
                  progressBasisPoints: 10000,
                  imageAsset: AppAssets.investorProjectHero,
                ),
              InvestorInvestment(
                id: '${entity.name}-underfunded-saffron',
                projectId: 'saffron-towers',
                projectName: 'Saffron Towers',
                location: 'Capetown, South Africa',
                amount: const MonetaryAmount(70250, Currency.zar),
                earned: const MonetaryAmount(0, Currency.zar),
                projectedPayout: const MonetaryAmount(70250, Currency.zar),
                createdAt: DateTime.utc(2026, 3, 23, 11, 12),
                status: InvestorInvestmentStatus.underfunded,
                thumbnailAsset: AppAssets.projectSaffronResidenceThumbnail,
                progressBasisPoints: 3800,
                imageAsset: AppAssets.investorProjectHero,
              ),
            ],
      notifications: empty || scenario == MockScenario.noNotifications
          ? []
          : [
              InvestorNotification(
                id: '${entity.name}-target-reached',
                title: 'Target reached',
                kind: InvestorNotificationKind.targetReached,
                message: 'Saffron Towers just hit 100% funding.',
                createdAt: DateTime.utc(2026, 6, 7, 22, 22),
                timeLabel: '2m',
                destination: scenario == MockScenario.noPortfolio
                    ? InvestorDestination.project
                    : InvestorDestination.investment,
                targetId: scenario == MockScenario.noPortfolio
                    ? 'saffron-towers'
                    : '${entity.name}-saffron-0',
                fundingMilestone: const InvestorFundingMilestone(
                  projectName: 'Saffron Towers',
                  location: 'Capetown, South Africa',
                  imageAsset: AppAssets.investorProjectHero,
                  raised: MonetaryAmount(320000000, Currency.zar),
                  investors: 2041,
                  daysToClose: 14,
                  nextSteps: [
                    'Funds released to project escrow',
                    'Construction to begin within 30 days',
                    'First distribution: Aug 15',
                    'Maturity: Oct 2027',
                  ],
                ),
              ),
              InvestorNotification(
                id: '${entity.name}-distribution',
                title: 'Quarterly distribution',
                kind: InvestorNotificationKind.distribution,
                message: '+R 362.50 from Marula Heights credited.',
                createdAt: DateTime.utc(2026, 6, 7, 22, 22),
                timeLabel: '2m',
                destination: InvestorDestination.wallet,
              ),
              InvestorNotification(
                id: '${entity.name}-new-project',
                title: 'New project: Azure Bay',
                kind: InvestorNotificationKind.newProject,
                message: 'Hospitality project just listed.',
                createdAt: DateTime.utc(2026, 6, 6, 22, 24),
                timeLabel: '1d',
                read: true,
                destination: InvestorDestination.project,
                targetId: 'azure-bay',
              ),
              InvestorNotification(
                id: '${entity.name}-withdrawal-sent',
                title: 'Withdrawal sent',
                kind: InvestorNotificationKind.withdrawal,
                message: 'R 4,985 sent to Standard Bank.',
                createdAt: DateTime.utc(2026, 6, 5, 22, 24),
                timeLabel: '2d',
                read: true,
                destination: InvestorDestination.wallet,
              ),
              InvestorNotification(
                id: '${entity.name}-verify-identity',
                title: 'Verify identity',
                kind: InvestorNotificationKind.verification,
                message: 'Complete KYC to unlock larger investments.',
                createdAt: DateTime.utc(2026, 6, 4, 22, 24),
                timeLabel: '3d',
                read: true,
                destination: InvestorDestination.verification,
              ),
            ],
    );
  }

  bool balanceVisible = true;
  final Map<Currency, int> balances;
  VerificationStatus verification;
  final List<InvestorPaymentMethod> methods;
  final List<InvestorTransaction> transactions;
  final List<InvestorInvestment> investments;
  List<InvestorNotification> notifications;
  final Map<String, InvestorOperationReceipt> receipts = {};
  final Map<String, String> requests = {};

  InvestorAccountSnapshot get snapshot => InvestorAccountSnapshot(
    balanceVisible: balanceVisible,
    asOf:
        [
          ...investments.map((item) => item.createdAt),
          ...transactions.map((item) => item.createdAt),
        ].fold<DateTime>(
          DateTime.utc(2026, 7, 1),
          (latest, date) => date.isAfter(latest) ? date : latest,
        ),
    balances: balances,
    investments: investments,
    transactions: transactions,
    notifications: notifications,
    paymentMethods: methods,
    verification: verification,
  );
}
