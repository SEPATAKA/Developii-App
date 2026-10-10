// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_methods_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PaymentMethodsStore on PaymentMethodsStoreBase, Store {
  Computed<bool>? _$savingComputed;

  @override
  bool get saving => (_$savingComputed ??= Computed<bool>(
    () => super.saving,
    name: 'PaymentMethodsStoreBase.saving',
  )).value;
  Computed<bool>? _$cardCompleteComputed;

  @override
  bool get cardComplete => (_$cardCompleteComputed ??= Computed<bool>(
    () => super.cardComplete,
    name: 'PaymentMethodsStoreBase.cardComplete',
  )).value;
  Computed<bool>? _$bankCompleteComputed;

  @override
  bool get bankComplete => (_$bankCompleteComputed ??= Computed<bool>(
    () => super.bankComplete,
    name: 'PaymentMethodsStoreBase.bankComplete',
  )).value;

  late final _$statusAtom = Atom(
    name: 'PaymentMethodsStoreBase.status',
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

  late final _$methodsAtom = Atom(
    name: 'PaymentMethodsStoreBase.methods',
    context: context,
  );

  @override
  List<InvestorPaymentMethod> get methods {
    _$methodsAtom.reportRead();
    return super.methods;
  }

  @override
  set methods(List<InvestorPaymentMethod> value) {
    _$methodsAtom.reportWrite(value, super.methods, () {
      super.methods = value;
    });
  }

  late final _$valuesAtom = Atom(
    name: 'PaymentMethodsStoreBase.values',
    context: context,
  );

  @override
  Map<String, String> get values {
    _$valuesAtom.reportRead();
    return super.values;
  }

  @override
  set values(Map<String, String> value) {
    _$valuesAtom.reportWrite(value, super.values, () {
      super.values = value;
    });
  }

  late final _$errorsAtom = Atom(
    name: 'PaymentMethodsStoreBase.errors',
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

  late final _$errorAtom = Atom(
    name: 'PaymentMethodsStoreBase.error',
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

  late final _$mutationAtom = Atom(
    name: 'PaymentMethodsStoreBase.mutation',
    context: context,
  );

  @override
  PaymentMethodMutation? get mutation {
    _$mutationAtom.reportRead();
    return super.mutation;
  }

  @override
  set mutation(PaymentMethodMutation? value) {
    _$mutationAtom.reportWrite(value, super.mutation, () {
      super.mutation = value;
    });
  }

  late final _$formRevisionAtom = Atom(
    name: 'PaymentMethodsStoreBase.formRevision',
    context: context,
  );

  @override
  int get formRevision {
    _$formRevisionAtom.reportRead();
    return super.formRevision;
  }

  @override
  set formRevision(int value) {
    _$formRevisionAtom.reportWrite(value, super.formRevision, () {
      super.formRevision = value;
    });
  }

  late final _$lastSavedIdAtom = Atom(
    name: 'PaymentMethodsStoreBase.lastSavedId',
    context: context,
  );

  @override
  String? get lastSavedId {
    _$lastSavedIdAtom.reportRead();
    return super.lastSavedId;
  }

  @override
  set lastSavedId(String? value) {
    _$lastSavedIdAtom.reportWrite(value, super.lastSavedId, () {
      super.lastSavedId = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'PaymentMethodsStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$saveAsyncAction = AsyncAction(
    'PaymentMethodsStoreBase.save',
    context: context,
  );

  @override
  Future<bool> save(PaymentMethodKind kind) {
    return _$saveAsyncAction.run(() => super.save(kind));
  }

  late final _$removeAsyncAction = AsyncAction(
    'PaymentMethodsStoreBase.remove',
    context: context,
  );

  @override
  Future<bool> remove(String id) {
    return _$removeAsyncAction.run(() => super.remove(id));
  }

  late final _$setDefaultAsyncAction = AsyncAction(
    'PaymentMethodsStoreBase.setDefault',
    context: context,
  );

  @override
  Future<bool> setDefault(String id, bool isDefault) {
    return _$setDefaultAsyncAction.run(() => super.setDefault(id, isDefault));
  }

  late final _$PaymentMethodsStoreBaseActionController = ActionController(
    name: 'PaymentMethodsStoreBase',
    context: context,
  );

  @override
  void edit(String key, String value) {
    final _$actionInfo = _$PaymentMethodsStoreBaseActionController.startAction(
      name: 'PaymentMethodsStoreBase.edit',
    );
    try {
      return super.edit(key, value);
    } finally {
      _$PaymentMethodsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
methods: ${methods},
values: ${values},
errors: ${errors},
error: ${error},
mutation: ${mutation},
formRevision: ${formRevision},
lastSavedId: ${lastSavedId},
saving: ${saving},
cardComplete: ${cardComplete},
bankComplete: ${bankComplete}
    ''';
  }
}
