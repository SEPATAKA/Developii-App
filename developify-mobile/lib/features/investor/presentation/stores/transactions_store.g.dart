// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transactions_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$TransactionsStore on TransactionsStoreBase, Store {
  Computed<List<InvestorTransaction>>? _$transactionsComputed;

  @override
  List<InvestorTransaction> get transactions =>
      (_$transactionsComputed ??= Computed<List<InvestorTransaction>>(
        () => super.transactions,
        name: 'TransactionsStoreBase.transactions',
      )).value;

  late final _$statusAtom = Atom(
    name: 'TransactionsStoreBase.status',
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

  late final _$dataAtom = Atom(
    name: 'TransactionsStoreBase.data',
    context: context,
  );

  @override
  InvestorAccountSnapshot? get data {
    _$dataAtom.reportRead();
    return super.data;
  }

  @override
  set data(InvestorAccountSnapshot? value) {
    _$dataAtom.reportWrite(value, super.data, () {
      super.data = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'TransactionsStoreBase.error',
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

  late final _$filterAtom = Atom(
    name: 'TransactionsStoreBase.filter',
    context: context,
  );

  @override
  InvestorTransactionKind? get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(InvestorTransactionKind? value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'TransactionsStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$TransactionsStoreBaseActionController = ActionController(
    name: 'TransactionsStoreBase',
    context: context,
  );

  @override
  void setFilter(InvestorTransactionKind? value) {
    final _$actionInfo = _$TransactionsStoreBaseActionController.startAction(
      name: 'TransactionsStoreBase.setFilter',
    );
    try {
      return super.setFilter(value);
    } finally {
      _$TransactionsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
data: ${data},
error: ${error},
filter: ${filter},
transactions: ${transactions}
    ''';
  }
}
