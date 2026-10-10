// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TransferStore on TransferStoreBase, Store {
  Computed<List<InvestorPaymentMethod>>? _$methodsComputed;

  @override
  List<InvestorPaymentMethod> get methods =>
      (_$methodsComputed ??= Computed<List<InvestorPaymentMethod>>(
        () => super.methods,
        name: 'TransferStoreBase.methods',
      )).value;
  Computed<InvestorPaymentMethod?>? _$methodComputed;

  @override
  InvestorPaymentMethod? get method =>
      (_$methodComputed ??= Computed<InvestorPaymentMethod?>(
        () => super.method,
        name: 'TransferStoreBase.method',
      )).value;
  Computed<MonetaryAmount?>? _$amountComputed;

  @override
  MonetaryAmount? get amount => (_$amountComputed ??= Computed<MonetaryAmount?>(
    () => super.amount,
    name: 'TransferStoreBase.amount',
  )).value;
  Computed<bool>? _$validAmountComputed;

  @override
  bool get validAmount => (_$validAmountComputed ??= Computed<bool>(
    () => super.validAmount,
    name: 'TransferStoreBase.validAmount',
  )).value;
  Computed<String?>? _$inputErrorComputed;

  @override
  String? get inputError => (_$inputErrorComputed ??= Computed<String?>(
    () => super.inputError,
    name: 'TransferStoreBase.inputError',
  )).value;
  Computed<MonetaryAmount>? _$feeComputed;

  @override
  MonetaryAmount get fee => (_$feeComputed ??= Computed<MonetaryAmount>(
    () => super.fee,
    name: 'TransferStoreBase.fee',
  )).value;
  Computed<MonetaryAmount>? _$receivedComputed;

  @override
  MonetaryAmount get received =>
      (_$receivedComputed ??= Computed<MonetaryAmount>(
        () => super.received,
        name: 'TransferStoreBase.received',
      )).value;

  late final _$kindAtom = Atom(
    name: 'TransferStoreBase.kind',
    context: context,
  );

  @override
  InvestorTransferKind get kind {
    _$kindAtom.reportRead();
    return super.kind;
  }

  @override
  set kind(InvestorTransferKind value) {
    _$kindAtom.reportWrite(value, super.kind, () {
      super.kind = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'TransferStoreBase.status',
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

  late final _$stageAtom = Atom(
    name: 'TransferStoreBase.stage',
    context: context,
  );

  @override
  TransferStage get stage {
    _$stageAtom.reportRead();
    return super.stage;
  }

  @override
  set stage(TransferStage value) {
    _$stageAtom.reportWrite(value, super.stage, () {
      super.stage = value;
    });
  }

  late final _$accountAtom = Atom(
    name: 'TransferStoreBase.account',
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
    name: 'TransferStoreBase.amountText',
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

  late final _$methodIdAtom = Atom(
    name: 'TransferStoreBase.methodId',
    context: context,
  );

  @override
  String? get methodId {
    _$methodIdAtom.reportRead();
    return super.methodId;
  }

  @override
  set methodId(String? value) {
    _$methodIdAtom.reportWrite(value, super.methodId, () {
      super.methodId = value;
    });
  }

  late final _$paymentKindAtom = Atom(
    name: 'TransferStoreBase.paymentKind',
    context: context,
  );

  @override
  PaymentMethodKind get paymentKind {
    _$paymentKindAtom.reportRead();
    return super.paymentKind;
  }

  @override
  set paymentKind(PaymentMethodKind value) {
    _$paymentKindAtom.reportWrite(value, super.paymentKind, () {
      super.paymentKind = value;
    });
  }

  late final _$amountErrorAtom = Atom(
    name: 'TransferStoreBase.amountError',
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
    name: 'TransferStoreBase.error',
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

  late final _$receiptAtom = Atom(
    name: 'TransferStoreBase.receipt',
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
    'TransferStoreBase.load',
    context: context,
  );

  @override
  Future<void> load(InvestorTransferKind value) {
    return _$loadAsyncAction.run(() => super.load(value));
  }

  late final _$refreshMethodsAsyncAction = AsyncAction(
    'TransferStoreBase.refreshMethods',
    context: context,
  );

  @override
  Future<void> refreshMethods() {
    return _$refreshMethodsAsyncAction.run(() => super.refreshMethods());
  }

  late final _$confirmAsyncAction = AsyncAction(
    'TransferStoreBase.confirm',
    context: context,
  );

  @override
  Future<bool> confirm(String pin, {bool simulateBiometric = false}) {
    return _$confirmAsyncAction.run(
      () => super.confirm(pin, simulateBiometric: simulateBiometric),
    );
  }

  late final _$TransferStoreBaseActionController = ActionController(
    name: 'TransferStoreBase',
    context: context,
  );

  @override
  void editAmount(String value) {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.editAmount',
    );
    try {
      return super.editAmount(value);
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectMethod(String value) {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.selectMethod',
    );
    try {
      return super.selectMethod(value);
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void chooseKind(PaymentMethodKind value) {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.chooseKind',
    );
    try {
      return super.chooseKind(value);
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showPaymentTypes() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.showPaymentTypes',
    );
    try {
      return super.showPaymentTypes();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showBankDetails() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.showBankDetails',
    );
    try {
      return super.showBankDetails();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void leaveBankDetails() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.leaveBankDetails',
    );
    try {
      return super.leaveBankDetails();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool review() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.review',
    );
    try {
      return super.review();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void adjustAmount() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.adjustAmount',
    );
    try {
      return super.adjustAmount();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void authorize() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.authorize',
    );
    try {
      return super.authorize();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelAuthorization() {
    final _$actionInfo = _$TransferStoreBaseActionController.startAction(
      name: 'TransferStoreBase.cancelAuthorization',
    );
    try {
      return super.cancelAuthorization();
    } finally {
      _$TransferStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
kind: ${kind},
status: ${status},
stage: ${stage},
account: ${account},
amountText: ${amountText},
methodId: ${methodId},
paymentKind: ${paymentKind},
amountError: ${amountError},
error: ${error},
receipt: ${receipt},
methods: ${methods},
method: ${method},
amount: ${amount},
validAmount: ${validAmount},
inputError: ${inputError},
fee: ${fee},
received: ${received}
    ''';
  }
}
