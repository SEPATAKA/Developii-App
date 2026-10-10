// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestmentStore on InvestmentStoreBase, Store {
  Computed<MonetaryAmount?>? _$amountComputed;

  @override
  MonetaryAmount? get amount => (_$amountComputed ??= Computed<MonetaryAmount?>(
    () => super.amount,
    name: 'InvestmentStoreBase.amount',
  )).value;
  Computed<MonetaryAmount?>? _$projectedPayoutComputed;

  @override
  MonetaryAmount? get projectedPayout =>
      (_$projectedPayoutComputed ??= Computed<MonetaryAmount?>(
        () => super.projectedPayout,
        name: 'InvestmentStoreBase.projectedPayout',
      )).value;
  Computed<bool>? _$requiresVerificationComputed;

  @override
  bool get requiresVerification =>
      (_$requiresVerificationComputed ??= Computed<bool>(
        () => super.requiresVerification,
        name: 'InvestmentStoreBase.requiresVerification',
      )).value;
  Computed<bool>? _$validAmountComputed;

  @override
  bool get validAmount => (_$validAmountComputed ??= Computed<bool>(
    () => super.validAmount,
    name: 'InvestmentStoreBase.validAmount',
  )).value;

  late final _$_quoteInvalidatedAtom = Atom(
    name: 'InvestmentStoreBase._quoteInvalidated',
    context: context,
  );

  @override
  bool get _quoteInvalidated {
    _$_quoteInvalidatedAtom.reportRead();
    return super._quoteInvalidated;
  }

  @override
  set _quoteInvalidated(bool value) {
    _$_quoteInvalidatedAtom.reportWrite(value, super._quoteInvalidated, () {
      super._quoteInvalidated = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'InvestmentStoreBase.status',
    context: context,
  );

  @override
  LoadStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(LoadStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$projectAtom = Atom(
    name: 'InvestmentStoreBase.project',
    context: context,
  );

  @override
  InvestorProject? get project {
    _$projectAtom.reportRead();
    return super.project;
  }

  @override
  set project(InvestorProject? value) {
    _$projectAtom.reportWrite(value, super.project, () {
      super.project = value;
    });
  }

  late final _$accountAtom = Atom(
    name: 'InvestmentStoreBase.account',
    context: context,
  );

  @override
  InvestorAccountSnapshot? get account {
    _$accountAtom.reportRead();
    return super.account;
  }

  @override
  set account(InvestorAccountSnapshot? value) {
    _$accountAtom.reportWrite(value, super.account, () {
      super.account = value;
    });
  }

  late final _$amountTextAtom = Atom(
    name: 'InvestmentStoreBase.amountText',
    context: context,
  );

  @override
  String get amountText {
    _$amountTextAtom.reportRead();
    return super.amountText;
  }

  @override
  set amountText(String value) {
    _$amountTextAtom.reportWrite(value, super.amountText, () {
      super.amountText = value;
    });
  }

  late final _$amountErrorAtom = Atom(
    name: 'InvestmentStoreBase.amountError',
    context: context,
  );

  @override
  String? get amountError {
    _$amountErrorAtom.reportRead();
    return super.amountError;
  }

  @override
  set amountError(String? value) {
    _$amountErrorAtom.reportWrite(value, super.amountError, () {
      super.amountError = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'InvestmentStoreBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$agreedAtom = Atom(
    name: 'InvestmentStoreBase.agreed',
    context: context,
  );

  @override
  bool get agreed {
    _$agreedAtom.reportRead();
    return super.agreed;
  }

  @override
  set agreed(bool value) {
    _$agreedAtom.reportWrite(value, super.agreed, () {
      super.agreed = value;
    });
  }

  late final _$stageAtom = Atom(
    name: 'InvestmentStoreBase.stage',
    context: context,
  );

  @override
  InvestmentStage get stage {
    _$stageAtom.reportRead();
    return super.stage;
  }

  @override
  set stage(InvestmentStage value) {
    _$stageAtom.reportWrite(value, super.stage, () {
      super.stage = value;
    });
  }

  late final _$receiptAtom = Atom(
    name: 'InvestmentStoreBase.receipt',
    context: context,
  );

  @override
  InvestorOperationReceipt? get receipt {
    _$receiptAtom.reportRead();
    return super.receipt;
  }

  @override
  set receipt(InvestorOperationReceipt? value) {
    _$receiptAtom.reportWrite(value, super.receipt, () {
      super.receipt = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'InvestmentStoreBase.load',
    context: context,
  );

  @override
  Future<void> load(
    String id, {
    String? initialAmount,
    String? initialAmountCents,
  }) {
    return _$loadAsyncAction.run(
      () => super.load(
        id,
        initialAmount: initialAmount,
        initialAmountCents: initialAmountCents,
      ),
    );
  }

  late final _$refreshBalanceAsyncAction = AsyncAction(
    'InvestmentStoreBase.refreshBalance',
    context: context,
  );

  @override
  Future<void> refreshBalance() {
    return _$refreshBalanceAsyncAction.run(() => super.refreshBalance());
  }

  late final _$confirmAsyncAction = AsyncAction(
    'InvestmentStoreBase.confirm',
    context: context,
  );

  @override
  Future<bool> confirm(String pin, {bool simulateBiometric = false}) {
    return _$confirmAsyncAction.run(
      () => super.confirm(pin, simulateBiometric: simulateBiometric),
    );
  }

  late final _$InvestmentStoreBaseActionController = ActionController(
    name: 'InvestmentStoreBase',
    context: context,
  );

  @override
  bool prepareQuote() {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.prepareQuote',
    );
    try {
      return super.prepareQuote();
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void editAmount(String value) {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.editAmount',
    );
    try {
      return super.editAmount(value);
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAgreement(bool value) {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.setAgreement',
    );
    try {
      return super.setAgreement(value);
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool review() {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.review',
    );
    try {
      return super.review();
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void adjustAmount() {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.adjustAmount',
    );
    try {
      return super.adjustAmount();
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void authorize() {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.authorize',
    );
    try {
      return super.authorize();
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelAuthorization() {
    final _$actionInfo = _$InvestmentStoreBaseActionController.startAction(
      name: 'InvestmentStoreBase.cancelAuthorization',
    );
    try {
      return super.cancelAuthorization();
    } finally {
      _$InvestmentStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
project: ${project},
account: ${account},
amountText: ${amountText},
amountError: ${amountError},
error: ${error},
agreed: ${agreed},
stage: ${stage},
receipt: ${receipt},
amount: ${amount},
projectedPayout: ${projectedPayout},
requiresVerification: ${requiresVerification},
validAmount: ${validAmount}
    ''';
  }
}
