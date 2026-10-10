import 'dart:async';

import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class ApiInvestorAccountRepository implements InvestorAccountRepository {
  ApiInvestorAccountRepository(this._client, this._context);

  final ApiClient _client;
  final InvestorAccountContext _context;
  final _changes = StreamController<InvestorAccountChange>.broadcast();
  bool _balanceVisible = true;
  InvestorAccountSnapshot? _snapshot;
  int _sequence = 0;

  String get _entity => _context.entity.name;

  @override
  Stream<InvestorAccountChange> get changes => _changes.stream;

  @override
  bool get balanceVisible => _balanceVisible;

  @override
  void setBalanceVisible(bool visible) {
    _balanceVisible = visible;
    _changes.add(const InvestorAccountChange({InvestorDataKind.privacy}));
  }

  InvestorTransaction _mapTx(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final kindName = map['kind'] as String? ?? 'topUp';
    final kind = InvestorTransactionKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => InvestorTransactionKind.topUp,
    );
    final statusName = map['status'] as String? ?? 'pending';
    final status = InvestorTransactionStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => InvestorTransactionStatus.pending,
    );
    final amount = (map['amountCents'] as num?)?.toInt() ?? 0;
    final fee = (map['feeCents'] as num?)?.toInt() ?? 0;
    return InvestorTransaction(
      id: map['id'] as String? ?? '',
      title: kind.name,
      kind: kind,
      status: status,
      amount: MonetaryAmount(amount, Currency.zar),
      fee: MonetaryAmount(fee, Currency.zar),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      reference: map['reference'] as String? ?? '',
      projectId: map['projectId'] as String?,
      methodId: map['methodId'] as String?,
    );
  }

  InvestorInvestment _mapInvestment(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final amount = (map['amountCents'] as num?)?.toInt() ?? 0;
    final rate = (map['rateBps'] as num?)?.toInt() ?? 0;
    final term = (map['termMonths'] as num?)?.toInt() ?? 36;
    final principal = MonetaryAmount(amount, Currency.zar);
    final projection = InvestmentProjection(
      principal: principal,
      annualRateBasisPoints: rate,
      termMonths: term,
      payoutEveryMonths: InvestmentPolicy.payoutEveryMonths,
    );
    final statusName = map['status'] as String? ?? 'active';
    return InvestorInvestment(
      id: map['id'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      projectName: map['projectName'] as String? ?? 'Project',
      location: map['town'] as String? ?? '',
      amount: principal,
      earned: MonetaryAmount(0, Currency.zar),
      projectedPayout: projection.payout,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      status: InvestorInvestmentStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => InvestorInvestmentStatus.active,
      ),
      progressBasisPoints: 2500,
      imageAsset: AppAssets.investorProjectHero,
      durationMonths: term,
      annualRateBasisPoints: rate,
      principalReturned: !(map['principalHeld'] as bool? ?? true),
    );
  }

  InvestorNotification _mapNotification(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final kindName = map['kind'] as String? ?? 'updates';
    final kind = InvestorNotificationKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => InvestorNotificationKind.newProject,
    );
    return InvestorNotification(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      destination: InvestorDestination.wallet,
      kind: kind,
      read: map['read'] as bool? ?? false,
    );
  }

  InvestorPaymentMethod _mapMethod(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final kindName = map['kind'] as String? ?? 'bankAccount';
    return InvestorPaymentMethod(
      id: map['id'] as String? ?? '',
      kind: PaymentMethodKind.values.firstWhere(
        (k) => k.name == kindName,
        orElse: () => PaymentMethodKind.bankAccount,
      ),
      name: map['name'] as String? ?? '',
      lastFour: map['lastFour'] as String? ?? '',
      holder: map['holder'] as String? ?? '',
      expiry: map['expiry'] as String? ?? '',
      bankType: map['bankType'] as String? ?? '',
      branchCode: map['branchCode'] as String? ?? '',
      reusable: map['reusable'] as bool? ?? true,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  InvestorAccountSnapshot _mapSnapshot(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final available = (map['availableCents'] as num?)?.toInt() ?? 0;
    final verificationName =
        map['verificationStatus'] as String? ?? 'incomplete';
    return InvestorAccountSnapshot(
      balances: {Currency.zar: available},
      investments: ((map['investments'] as List<dynamic>?) ?? const [])
          .map(_mapInvestment)
          .toList(),
      transactions: ((map['transactions'] as List<dynamic>?) ?? const [])
          .map(_mapTx)
          .toList(),
      notifications: ((map['notifications'] as List<dynamic>?) ?? const [])
          .map(_mapNotification)
          .toList(),
      paymentMethods: ((map['paymentMethods'] as List<dynamic>?) ?? const [])
          .map(_mapMethod)
          .toList(),
      verification: VerificationStatus.values.firstWhere(
        (v) => v.name == verificationName,
        orElse: () => VerificationStatus.incomplete,
      ),
      asOf: DateTime.now().toUtc(),
      balanceVisible: _balanceVisible,
    );
  }

  @override
  Future<Result<InvestorAccountSnapshot>> snapshot() async {
    final result = await _client.request(
      path: '/v1/wallet/snapshot',
      query: {'entity': _entity},
      decode: _mapSnapshot,
    );
    if (result case Success(:final value)) {
      _snapshot = value;
      _changes.add(
        const InvestorAccountChange({
          InvestorDataKind.wallet,
          InvestorDataKind.portfolio,
          InvestorDataKind.transactions,
          InvestorDataKind.notifications,
          InvestorDataKind.methods,
          InvestorDataKind.verification,
        }),
      );
    }
    return result;
  }

  @override
  Future<Result<InvestorTransaction>> transaction(String id) {
    return _client.request(
      path: '/v1/wallet/transactions/$id',
      query: {'entity': _entity},
      decode: _mapTx,
    );
  }

  @override
  Future<Result<InvestorInvestment>> investment(String id) {
    return _client.request(
      path: '/v1/wallet/investments/$id',
      query: {'entity': _entity},
      decode: _mapInvestment,
    );
  }

  @override
  Future<Result<InvestorNotification>> notification(String id) async {
    final snap = _snapshot ??
        ((await snapshot()) is Success<InvestorAccountSnapshot>
            ? (await snapshot() as Success<InvestorAccountSnapshot>).value
            : null);
    final found = snap?.notifications.where((n) => n.id == id).firstOrNull;
    if (found == null) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'Notification not found.'),
      );
    }
    return Success(found);
  }

  @override
  Future<Result<void>> markNotificationsRead([String? id]) {
    return _client.request(
      path: '/v1/wallet/notifications/read',
      method: 'POST',
      data: {'id': id},
      decode: (_) {},
    );
  }

  @override
  String newOperationId() =>
      '${_context.entity.name}-operation-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';

  @override
  Future<Result<InvestorOperationReceipt>> invest({
    required InvestorProject project,
    required MonetaryAmount amount,
    required String operationId,
    required String pin,
    InvestmentProjection? quote,
    bool simulateBiometric = false,
  }) async {
    String? quoteId;
    final quoteResult = await _client.request<Object?>(
      path: '/v1/investments/quotes',
      method: 'POST',
      data: {
        'projectId': project.id,
        'amountCents': amount.minorUnits,
        'entity': _entity,
      },
      decode: (json) => json,
    );
    if (quoteResult case Success(:final value)) {
      quoteId = (value as Map<String, Object?>)['id'] as String?;
    }
    final result = await _client.request<Object?>(
      path: '/v1/investments',
      method: 'POST',
      data: {
        'projectId': project.id,
        'amountCents': amount.minorUnits,
        'operationId': operationId,
        'pin': pin,
        'quoteId': quoteId,
        'entity': _entity,
      },
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      final map = value as Map<String, Object?>? ?? const {};
      await snapshot();
      return Success(
        InvestorOperationReceipt(
          transactionId: map['transactionId'] as String? ??
              map['receiptId'] as String? ??
              '',
          investmentId: map['investmentId'] as String?,
        ),
      );
    }
    return result as Failure<InvestorOperationReceipt>;
  }

  @override
  Future<Result<InvestorOperationReceipt>> addMoney({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  }) async {
    final result = await _client.request<Object?>(
      path: '/v1/wallet/add-money',
      method: 'POST',
      data: {
        'amountCents': amount.minorUnits,
        'methodId': methodId,
        'operationId': operationId,
        'pin': pin,
        'entity': _entity,
      },
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      final map = value as Map<String, Object?>? ?? const {};
      await snapshot();
      return Success(
        InvestorOperationReceipt(
          transactionId: map['id'] as String? ?? '',
        ),
      );
    }
    return result as Failure<InvestorOperationReceipt>;
  }

  @override
  Future<Result<InvestorOperationReceipt>> withdraw({
    required MonetaryAmount amount,
    required String methodId,
    required String operationId,
    required String pin,
    bool simulateBiometric = false,
  }) async {
    final result = await _client.request<Object?>(
      path: '/v1/wallet/withdraw',
      method: 'POST',
      data: {
        'amountCents': amount.minorUnits,
        'methodId': methodId,
        'operationId': operationId,
        'pin': pin,
        'entity': _entity,
      },
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      final map = value as Map<String, Object?>? ?? const {};
      await snapshot();
      return Success(
        InvestorOperationReceipt(
          transactionId: map['id'] as String? ?? '',
        ),
      );
    }
    return result as Failure<InvestorOperationReceipt>;
  }

  @override
  Future<Result<InvestorPaymentMethod>> addCard({
    required String cardNumber,
    required String holder,
    required String expiry,
    required String securityCode,
    bool reusable = true,
  }) {
    return _client.request(
      path: '/v1/wallet/payment-methods/card',
      method: 'POST',
      data: {
        'cardNumber': cardNumber,
        'holder': holder,
        'expiry': expiry,
        'securityCode': securityCode,
        'reusable': reusable,
      },
      decode: _mapMethod,
    );
  }

  @override
  Future<Result<InvestorPaymentMethod>> addBankAccount({
    required String bank,
    required String accountNumber,
    required String accountType,
    required String branchCode,
    required String holder,
  }) {
    return _client.request(
      path: '/v1/wallet/payment-methods/bank',
      method: 'POST',
      data: {
        'bank': bank,
        'accountNumber': accountNumber,
        'accountType': accountType,
        'branchCode': branchCode,
        'holder': holder,
        'entity': _entity,
      },
      decode: _mapMethod,
    );
  }

  @override
  Future<Result<void>> removePaymentMethod(String id) {
    return _client.request(
      path: '/v1/wallet/payment-methods/$id',
      method: 'DELETE',
      query: {'entity': _entity},
      decode: (_) {},
    );
  }

  @override
  Future<Result<void>> setDefaultPaymentMethod(String id, bool isDefault) {
    return _client.request(
      path: '/v1/wallet/payment-methods/$id/default',
      method: 'PATCH',
      data: {'isDefault': isDefault, 'entity': _entity},
      decode: (_) {},
    );
  }

  @override
  void setVerification(VerificationStatus status, {EntityType? entity}) {
    _changes.add(const InvestorAccountChange({InvestorDataKind.verification}));
  }

  @override
  void dispose() {
    _changes.close();
  }
}
