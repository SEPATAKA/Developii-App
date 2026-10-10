import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_transfer_fees.dart';
part 'transfer_store.g.dart';

enum TransferStage {
  method,
  bankDetails,
  amount,
  review,
  authorizing,
  processing,
  success,
  failure,
}

class TransferStore = TransferStoreBase with _$TransferStore;

abstract class TransferStoreBase with Store, Lifecycle {
  TransferStoreBase(this._repository, this._drafts) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed) return;
      if (event.kinds.contains(InvestorDataKind.scope)) {
        unawaited(load(kind));
      } else if (event.kinds.contains(InvestorDataKind.methods)) {
        unawaited(refreshMethods());
      }
    });
  }
  final InvestorAccountRepository _repository;
  final InvestorDrafts _drafts;
  late final StreamSubscription<InvestorAccountChange> _changes;
  String? _operationId;
  int _methodsVersion = 0;
  TransferStage _detailsReturnStage = TransferStage.method;
  @observable
  InvestorTransferKind kind = InvestorTransferKind.topUp;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  TransferStage stage = TransferStage.method;
  @observable
  InvestorAccountSnapshot? account;
  @observable
  String amountText = '';
  @observable
  String? methodId;
  @observable
  PaymentMethodKind paymentKind = PaymentMethodKind.card;
  @observable
  String? amountError;
  @observable
  String? error;
  @observable
  InvestorOperationReceipt? receipt;
  @computed
  List<InvestorPaymentMethod> get methods => [
    ...?account?.paymentMethods.where(
      (method) =>
          method.kind ==
          (kind == InvestorTransferKind.topUp
              ? PaymentMethodKind.card
              : PaymentMethodKind.bankAccount),
    ),
    if (kind == InvestorTransferKind.topUp) InvestorDepositAccount.method,
  ];
  @computed
  InvestorPaymentMethod? get method =>
      methods.where((method) => method.id == methodId).firstOrNull;
  @computed
  MonetaryAmount? get amount =>
      MonetaryAmount.tryParse(amountText, Currency.zar);
  @computed
  bool get validAmount =>
      amount != null &&
      amount!.minorUnits >
          (kind == InvestorTransferKind.withdrawal
              ? InvestorTransferFees.withdrawal.minorUnits
              : 0) &&
      amount!.minorUnits <= 25000000;
  @computed
  String? get inputError => amountText.isNotEmpty && !validAmount
      ? kind == InvestorTransferKind.withdrawal
            ? 'Enter more than the 1.50 withdrawal fee and no more than 250,000.'
            : 'Enter an amount greater than zero and no more than 250,000.'
      : amountError;
  @computed
  MonetaryAmount get fee => kind == InvestorTransferKind.withdrawal
      ? InvestorTransferFees.withdrawal
      : method?.kind == PaymentMethodKind.card
      ? InvestorTransferFees.cardTopUp(
          amount ?? const MonetaryAmount(0, Currency.zar),
        )
      : const MonetaryAmount(0, Currency.zar);
  @computed
  MonetaryAmount get received => kind == InvestorTransferKind.withdrawal
      ? MonetaryAmount(
          ((amount?.minorUnits ?? 0) - fee.minorUnits).clamp(0, 25000000),
          Currency.zar,
        )
      : amount ?? const MonetaryAmount(0, Currency.zar);
  @action
  Future<void> load(InvestorTransferKind value) async {
    if (isDisposed) return;
    final request = beginRequest();
    _methodsVersion++;
    kind = value;
    status = LoadStatus.loading;
    account = null;
    error = null;
    receipt = null;
    _operationId = null;
    _detailsReturnStage = TransferStage.method;
    final draft = _drafts.transfer(value);
    amountText = draft.amount;
    methodId = draft.methodId;
    paymentKind =
        kind == InvestorTransferKind.withdrawal ||
            methodId == InvestorDepositAccount.method.id
        ? PaymentMethodKind.bankAccount
        : PaymentMethodKind.card;
    stage = value == InvestorTransferKind.topUp
        ? TransferStage.method
        : TransferStage.amount;
    final result = await _repository.snapshot();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          account = value;
          methodId =
              method?.id ??
              (kind == InvestorTransferKind.withdrawal
                  ? null
                  : _preferredMethod(paymentKind)?.id);
          status = LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<void> refreshMethods() async {
    if (isDisposed) return;
    final version = ++_methodsVersion;
    final result = await _repository.snapshot();
    if (isDisposed || version != _methodsVersion) return;
    if (result case Success(:final value)) {
      runInAction(() {
        final previousId = methodId;
        account = value;
        final retainedId = method?.id;
        methodId =
            retainedId ??
            (kind == InvestorTransferKind.withdrawal
                ? null
                : _preferredMethod(paymentKind)?.id);
        if (previousId != null &&
            retainedId == null &&
            (stage == TransferStage.review ||
                stage == TransferStage.authorizing)) {
          stage = TransferStage.amount;
          error =
              'The selected payment method is no longer available. Review your payment method before continuing.';
        }
      });
    }
  }

  InvestorPaymentMethod? _preferredMethod(PaymentMethodKind kind) {
    final available = methods.where((method) => method.kind == kind);
    return available.where((method) => method.isDefault).firstOrNull ??
        available.firstOrNull;
  }

  void _save() => _drafts.saveTransfer(
    kind,
    TransferDraft(amount: amountText, methodId: methodId),
  );
  @action
  void editAmount(String value) {
    if (stage == TransferStage.processing) return;
    amountText = value;
    amountError = null;
    error = null;
    _operationId = null;
    _save();
  }

  @action
  void selectMethod(String value) {
    if (stage == TransferStage.processing ||
        !methods.any((method) => method.id == value)) {
      return;
    }
    methodId = value;
    paymentKind = method!.kind;
    error = null;
    _operationId = null;
    _save();
  }

  @action
  void chooseKind(PaymentMethodKind value) {
    if (stage == TransferStage.processing) return;
    if (kind == InvestorTransferKind.withdrawal &&
        value != PaymentMethodKind.bankAccount) {
      return;
    }
    paymentKind = value;
    methodId = _preferredMethod(value)?.id;
    stage = TransferStage.amount;
    _save();
  }

  @action
  void showPaymentTypes() {
    if (kind == InvestorTransferKind.topUp &&
        stage != TransferStage.processing) {
      stage = TransferStage.method;
      error = null;
      amountError = null;
    }
  }

  @action
  void showBankDetails() {
    if (kind != InvestorTransferKind.topUp ||
        (stage != TransferStage.method && stage != TransferStage.amount)) {
      return;
    }
    _detailsReturnStage = stage;
    stage = TransferStage.bankDetails;
  }

  @action
  void leaveBankDetails() {
    if (stage == TransferStage.bankDetails) stage = _detailsReturnStage;
  }

  @action
  bool review() {
    final value = amount;
    if (value == null || !validAmount) {
      amountError = kind == InvestorTransferKind.withdrawal
          ? 'Enter more than the 1.50 withdrawal fee and no more than 250,000.'
          : 'Enter an amount greater than zero and no more than 250,000.';
      return false;
    }
    if (method == null) {
      error = 'Add or select a payment method to continue.';
      return false;
    }
    if (kind == InvestorTransferKind.withdrawal) {
      if (account?.verification != VerificationStatus.verified) {
        error = 'Complete verification before withdrawing.';
        return false;
      }
      if (value.minorUnits >
          (account?.balance(value.currency).minorUnits ?? 0)) {
        amountError = 'The amount exceeds your available balance.';
        return false;
      }
    }
    error = null;
    amountError = null;
    stage = TransferStage.review;
    return true;
  }

  @action
  void adjustAmount() {
    if (stage != TransferStage.processing) stage = TransferStage.amount;
  }

  @action
  void authorize() {
    if (stage == TransferStage.review || stage == TransferStage.failure) {
      stage = TransferStage.authorizing;
      error = null;
    }
  }

  @action
  void cancelAuthorization() {
    if (stage == TransferStage.authorizing) stage = TransferStage.review;
  }

  @action
  Future<bool> confirm(String pin, {bool simulateBiometric = false}) async {
    final value = amount;
    final id = methodId;
    if (isDisposed ||
        value == null ||
        id == null ||
        stage != TransferStage.authorizing) {
      return false;
    }
    final request = beginRequest();
    stage = TransferStage.processing;
    error = null;
    _operationId ??= _repository.newOperationId();
    final result = await (kind == InvestorTransferKind.topUp
        ? _repository.addMoney(
            amount: value,
            methodId: id,
            operationId: _operationId!,
            pin: pin,
            simulateBiometric: simulateBiometric,
          )
        : _repository.withdraw(
            amount: value,
            methodId: id,
            operationId: _operationId!,
            pin: pin,
            simulateBiometric: simulateBiometric,
          ));
    if (!isCurrent(request)) return false;
    return runInAction(() {
      switch (result) {
        case Success(:final value):
          receipt = value;
          stage = TransferStage.success;
          _drafts.clearTransfer(kind);
          return true;
        case Failure(:final error):
          this.error = error.message;
          stage = error.fields.containsKey('pin')
              ? TransferStage.authorizing
              : TransferStage.failure;
          return false;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}
