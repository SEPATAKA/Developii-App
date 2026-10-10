// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'properties_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PropertiesStore on PropertiesStoreBase, Store {
  Computed<List<Property>>? _$visibleItemsComputed;

  @override
  List<Property> get visibleItems =>
      (_$visibleItemsComputed ??= Computed<List<Property>>(
        () => super.visibleItems,
        name: 'PropertiesStoreBase.visibleItems',
      )).value;

  late final _$statusAtom = Atom(
    name: 'PropertiesStoreBase.status',
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

  late final _$itemsAtom = Atom(
    name: 'PropertiesStoreBase.items',
    context: context,
  );

  @override
  List<Property> get items {
    _$itemsAtom.reportRead();
    return super.items;
  }

  @override
  set items(List<Property> value) {
    _$itemsAtom.reportWrite(value, super.items, () {
      super.items = value;
    });
  }

  late final _$filterAtom = Atom(
    name: 'PropertiesStoreBase.filter',
    context: context,
  );

  @override
  PropertyStatus? get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(PropertyStatus? value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$queryAtom = Atom(
    name: 'PropertiesStoreBase.query',
    context: context,
  );

  @override
  String get query {
    _$queryAtom.reportRead();
    return super.query;
  }

  @override
  set query(String value) {
    _$queryAtom.reportWrite(value, super.query, () {
      super.query = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'PropertiesStoreBase.error',
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

  late final _$loadAsyncAction = AsyncAction(
    'PropertiesStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$PropertiesStoreBaseActionController = ActionController(
    name: 'PropertiesStoreBase',
    context: context,
  );

  @override
  void setFilter(PropertyStatus? value) {
    final _$actionInfo = _$PropertiesStoreBaseActionController.startAction(
      name: 'PropertiesStoreBase.setFilter',
    );
    try {
      return super.setFilter(value);
    } finally {
      _$PropertiesStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void search(String value) {
    final _$actionInfo = _$PropertiesStoreBaseActionController.startAction(
      name: 'PropertiesStoreBase.search',
    );
    try {
      return super.search(value);
    } finally {
      _$PropertiesStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
items: ${items},
filter: ${filter},
query: ${query},
error: ${error},
visibleItems: ${visibleItems}
    ''';
  }
}
