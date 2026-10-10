// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_detail_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PropertyDetailStore on PropertyDetailStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'PropertyDetailStoreBase.status',
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

  late final _$propertyAtom = Atom(
    name: 'PropertyDetailStoreBase.property',
    context: context,
  );

  @override
  Property? get property {
    _$propertyAtom.reportRead();
    return super.property;
  }

  @override
  set property(Property? value) {
    _$propertyAtom.reportWrite(value, super.property, () {
      super.property = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'PropertyDetailStoreBase.error',
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
    'PropertyDetailStoreBase.load',
    context: context,
  );

  @override
  Future<void> load(String id) {
    return _$loadAsyncAction.run(() => super.load(id));
  }

  @override
  String toString() {
    return '''
status: ${status},
property: ${property},
error: ${error}
    ''';
  }
}
