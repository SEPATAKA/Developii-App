import 'dart:async';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_drafts.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'investment_store.g.dart';

enum InvestmentStage {
  amount,
  review,
  authorizing,
  processing,
  success,
  failure,
}

class InvestmentStore = InvestmentStoreBase with _$InvestmentStore;

abstract class InvestmentStoreBase with Store, Lifecycle {
  InvestmentStoreBase(this._catalog, this._account, this._drafts) {
    _changes = _account.changes.listen((event) {
      if (isDisposed) return;
      if (event.kinds.contains(InvestorDataKind.scope)) {
        unawaited(load(_projectId));
      } else if (event.kinds.contains(InvestorDataKind.wallet) &&
          stage == InvestmentStage.amount) {
        unawaited(refreshBalance());
      }
    });
    _catalogChanges = _catalog.changes.listen((_) {
      if (isDisposed) return;
      runInAction(() {
        project = _catalog.currentProject(_projectId);
        _checkQuote();
        if (project == null) {
          status = LoadStatus.error;
          error = 'This project is no longer available.';
        }
      });
    });
  }
  final InvestorCatalogRepository _catalog;
  final InvestorAccountRepository _account;
  final InvestorDrafts _drafts;
  late final StreamSubscription<InvestorAccountChange> _changes;
  late final StreamSubscription<void> _catalogChanges;
  String _projectId = '';
  String? _operationId;
  InvestmentProjection? _quote;
  @observable
  bool _quoteInvalidated = false;
  int _balanceVersion = 0;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  InvestorProject? project;
  @observable
  InvestorAccountSnapshot? account;
  @observable
  String amountText = '';
  @observable
  String? amountError;
  @observable
  String? error;
  @observable
  bool agreed = false;
  @observable
  InvestmentStage stage = InvestmentStage.amount;
  @observable
  InvestorOperationReceipt? receipt;
  @computed
  MonetaryAmount? get amount => MonetaryAmount.tryParse(
    amountText,
    project?.minimumInvestment.currency ?? Currency.zar,
  );
  @computed
  MonetaryAmount? get projectedPayout =>
      project == null || amount == null || !project!.supportsProjection
      ? null
      : project!.projectedPayout(amount!);
  @computed
  bool get requiresVerification =>
      account != null && account!.verification != VerificationStatus.verified;
  @computed
  bool get validAmount {
    final value = amount;
    final current = project;
    return value != null &&
        !_quoteInvalidated &&
        current != null &&
        current.validateInvestment(value) == null;
  }

  @action
  Future<void> load(
    String id, {
    String? initialAmount,
    String? initialAmountCents,
  }) async {
    if (isDisposed) return;
    _projectId = id;
    final request = beginRequest();
    _balanceVersion++;
    status = LoadStatus.loading;
    project = null;
    account = null;
    error = null;
    stage = InvestmentStage.amount;
    receipt = null;
    _operationId = null;
    final draft = _drafts.investment(id);
    _quote = draft.quote;
    _quoteInvalidated = false;
    final cents = initialAmountCents == null
        ? null
        : int.tryParse(initialAmountCents);
    if (initialAmountCents != null &&
        (cents == null ||
            cents < 0 ||
            !RegExp(r'^\d{1,14}$').hasMatch(initialAmountCents))) {
      error =
          'This investment amount is invalid. Go back and enter an amount again.';
      status = LoadStatus.error;
      return;
    }
    amountText = cents == null
        ? initialAmount ?? draft.amount
        : '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
    agreed = draft.agreed;
    final results = await (_catalog.project(id), _account.snapshot()).wait;
    if (!isCurrent(request)) return;
    runInAction(() {
      if (results.$1 case Failure(:final error)) {
        this.error = error.message;
        status = LoadStatus.error;
        return;
      }
      if (results.$2 case Failure(:final error)) {
        this.error = error.message;
        status = LoadStatus.error;
        return;
      }
      project = (results.$1 as Success<InvestorProject>).value;
      _checkQuote();
      account = (results.$2 as Success<InvestorAccountSnapshot>).value;
      status = LoadStatus.success;
    });
  }

  @action
  Future<void> refreshBalance() async {
    if (isDisposed) return;
    final version = ++_balanceVersion;
    final result = await _account.snapshot();
    if (isDisposed || version != _balanceVersion) return;
    if (result case Success(:final value)) runInAction(() => account = value);
  }

  void _save() => _drafts.saveInvestment(
    _projectId,
    InvestmentDraft(amount: amountText, agreed: agreed, quote: _quote),
  );
  void _checkQuote() {
    final current = project;
    final value = amount;
    if (_quote == null || current == null || value == null) return;
    if (!current.supportsProjection ||
        !_quote!.matches(current.projection(value))) {
      _quoteInvalidated = true;
      agreed = false;
      error =
          'The project terms changed. Enter the amount again to review a new quote.';
      if (stage != InvestmentStage.processing) stage = InvestmentStage.amount;
    }
  }

  @action
  bool prepareQuote() {
    _checkQuote();
    if (!validAmount) return false;
    _quote ??= project!.projection(amount!);
    _save();
    return true;
  }

  @action
  void editAmount(String value) {
    if (stage == InvestmentStage.processing) return;
    amountText = value;
    _quote = null;
    _quoteInvalidated = false;
    agreed = false;
    amountError = null;
    error = null;
    if (value.isNotEmpty) {
      amountError = amount == null
          ? 'Enter a valid amount with at most two decimal places.'
          : project?.validateInvestment(amount!);
    }
    _operationId = null;
    _save();
  }

  @action
  void setAgreement(bool value) {
    if (stage == InvestmentStage.processing) return;
    agreed = value;
    _save();
  }

  @action
  bool review() {
    final value = amount;
    final p = project;
    final validation = p == null
        ? 'Select an available project.'
        : value == null
        ? 'Enter a valid amount with at most two decimal places.'
        : p.validateInvestment(value);
    if (validation != null) {
      amountError = validation;
      return false;
    }
    if (requiresVerification) {
      error = 'Complete verification before investing.';
      return false;
    }
    if (value!.minorUnits >
        (account?.balance(value.currency).minorUnits ?? 0)) {
      amountError = 'Your wallet balance is too low. Add funds to continue.';
      return false;
    }
    error = null;
    amountError = null;
    if (!prepareQuote()) return false;
    stage = InvestmentStage.review;
    return true;
  }

  @action
  void adjustAmount() {
    if (stage != InvestmentStage.processing) {
      stage = InvestmentStage.amount;
      error = null;
    }
  }

  @action
  void authorize() {
    if (agreed &&
        (stage == InvestmentStage.review || stage == InvestmentStage.failure)) {
      stage = InvestmentStage.authorizing;
      error = null;
    }
  }

  @action
  void cancelAuthorization() {
    if (stage == InvestmentStage.authorizing) stage = InvestmentStage.review;
  }

  @action
  Future<bool> confirm(String pin, {bool simulateBiometric = false}) async {
    final p = project;
    final value = amount;
    if (isDisposed ||
        !agreed ||
        p == null ||
        value == null ||
        stage != InvestmentStage.authorizing) {
      return false;
    }
    final request = beginRequest();
    stage = InvestmentStage.processing;
    error = null;
    _operationId ??= _account.newOperationId();
    final result = await _account.invest(
      project: p,
      amount: value,
      operationId: _operationId!,
      pin: pin,
      quote: _quote,
      simulateBiometric: simulateBiometric,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      switch (result) {
        case Success(:final value):
          receipt = value;
          stage = InvestmentStage.success;
          _drafts.clearInvestment(_projectId);
          return true;
        case Failure(:final error):
          this.error = error.message;
          stage = error.fields.containsKey('pin')
              ? InvestmentStage.authorizing
              : InvestmentStage.failure;
          return false;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    unawaited(_catalogChanges.cancel());
    super.dispose();
  }
}
