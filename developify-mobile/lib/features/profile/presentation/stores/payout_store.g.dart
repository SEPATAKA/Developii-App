// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payout_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PayoutStore on PayoutStoreBase, Store {
  Computed<bool>? _$dirtyComputed;

  @override
  bool get dirty => (_$dirtyComputed ??= Computed<bool>(
    () => super.dirty,
    name: 'PayoutStoreBase.dirty',
  )).value;
  Computed<bool>? _$canSubmitComputed;

  @override
  bool get canSubmit => (_$canSubmitComputed ??= Computed<bool>(
    () => super.canSubmit,
    name: 'PayoutStoreBase.canSubmit',
  )).value;

  late final _$bankAtom = Atom(name: 'PayoutStoreBase.bank', context: context);

  @override
  String get bank {
    _$bankAtom.reportRead();
    return super.bank;
  }

  @override
  set bank(String value) {
    _$bankAtom.reportWrite(value, super.bank, () {
      super.bank = value;
    });
  }

  late final _$numberAtom = Atom(
    name: 'PayoutStoreBase.number',
    context: context,
  );

  @override
  String get number {
    _$numberAtom.reportRead();
    return super.number;
  }

  @override
  set number(String value) {
    _$numberAtom.reportWrite(value, super.number, () {
      super.number = value;
    });
  }

  late final _$typeAtom = Atom(name: 'PayoutStoreBase.type', context: context);

  @override
  String get type {
    _$typeAtom.reportRead();
    return super.type;
  }

  @override
  set type(String value) {
    _$typeAtom.reportWrite(value, super.type, () {
      super.type = value;
    });
  }

  late final _$branchAtom = Atom(
    name: 'PayoutStoreBase.branch',
    context: context,
  );

  @override
  String get branch {
    _$branchAtom.reportRead();
    return super.branch;
  }

  @override
  set branch(String value) {
    _$branchAtom.reportWrite(value, super.branch, () {
      super.branch = value;
    });
  }

  late final _$proofAttachedAtom = Atom(
    name: 'PayoutStoreBase.proofAttached',
    context: context,
  );

  @override
  bool get proofAttached {
    _$proofAttachedAtom.reportRead();
    return super.proofAttached;
  }

  @override
  set proofAttached(bool value) {
    _$proofAttachedAtom.reportWrite(value, super.proofAttached, () {
      super.proofAttached = value;
    });
  }

  late final _$errorsAtom = Atom(
    name: 'PayoutStoreBase.errors',
    context: context,
  );

  @override
  Map<String, String> get errors {
    _$errorsAtom.reportRead();
    return super.errors;
  }

  @override
  set errors(Map<String, String> value) {
    _$errorsAtom.reportWrite(value, super.errors, () {
      super.errors = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'PayoutStoreBase.status',
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

  late final _$errorAtom = Atom(
    name: 'PayoutStoreBase.error',
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

  late final _$submitAsyncAction = AsyncAction(
    'PayoutStoreBase.submit',
    context: context,
  );

  @override
  Future<bool> submit() {
    return _$submitAsyncAction.run(() => super.submit());
  }

  late final _$PayoutStoreBaseActionController = ActionController(
    name: 'PayoutStoreBase',
    context: context,
  );

  @override
  void setBank(String value) {
    final _$actionInfo = _$PayoutStoreBaseActionController.startAction(
      name: 'PayoutStoreBase.setBank',
    );
    try {
      return super.setBank(value);
    } finally {
      _$PayoutStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNumber(String value) {
    final _$actionInfo = _$PayoutStoreBaseActionController.startAction(
      name: 'PayoutStoreBase.setNumber',
    );
    try {
      return super.setNumber(value);
    } finally {
      _$PayoutStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setType(String value) {
    final _$actionInfo = _$PayoutStoreBaseActionController.startAction(
      name: 'PayoutStoreBase.setType',
    );
    try {
      return super.setType(value);
    } finally {
      _$PayoutStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBranch(String value) {
    final _$actionInfo = _$PayoutStoreBaseActionController.startAction(
      name: 'PayoutStoreBase.setBranch',
    );
    try {
      return super.setBranch(value);
    } finally {
      _$PayoutStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void attachProof(bool value) {
    final _$actionInfo = _$PayoutStoreBaseActionController.startAction(
      name: 'PayoutStoreBase.attachProof',
    );
    try {
      return super.attachProof(value);
    } finally {
      _$PayoutStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
bank: ${bank},
number: ${number},
type: ${type},
branch: ${branch},
proofAttached: ${proofAttached},
errors: ${errors},
status: ${status},
error: ${error},
dirty: ${dirty},
canSubmit: ${canSubmit}
    ''';
  }
}
