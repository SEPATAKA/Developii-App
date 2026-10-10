// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earnings_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EarningsStore on EarningsStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'EarningsStoreBase.status',
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
    name: 'EarningsStoreBase.data',
    context: context,
  );

  @override
  EarningsSummary? get data {
    _$dataAtom.reportRead();
    return super.data;
  }

  @override
  set data(EarningsSummary? value) {
    _$dataAtom.reportWrite(value, super.data, () {
      super.data = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'EarningsStoreBase.error',
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

  late final _$balanceVisibleAtom = Atom(
    name: 'EarningsStoreBase.balanceVisible',
    context: context,
  );

  @override
  bool get balanceVisible {
    _$balanceVisibleAtom.reportRead();
    return super.balanceVisible;
  }

  @override
  set balanceVisible(bool value) {
    _$balanceVisibleAtom.reportWrite(value, super.balanceVisible, () {
      super.balanceVisible = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'EarningsStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$EarningsStoreBaseActionController = ActionController(
    name: 'EarningsStoreBase',
    context: context,
  );

  @override
  void toggleBalance() {
    final _$actionInfo = _$EarningsStoreBaseActionController.startAction(
      name: 'EarningsStoreBase.toggleBalance',
    );
    try {
      return super.toggleBalance();
    } finally {
      _$EarningsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
data: ${data},
error: ${error},
balanceVisible: ${balanceVisible}
    ''';
  }
}
