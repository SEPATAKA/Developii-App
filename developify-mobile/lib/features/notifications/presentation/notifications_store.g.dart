// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$NotificationsStore on NotificationsStoreBase, Store {
  Computed<int>? _$unreadCountComputed;

  @override
  int get unreadCount => (_$unreadCountComputed ??= Computed<int>(
    () => super.unreadCount,
    name: 'NotificationsStoreBase.unreadCount',
  )).value;

  late final _$statusAtom = Atom(
    name: 'NotificationsStoreBase.status',
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
    name: 'NotificationsStoreBase.items',
    context: context,
  );

  @override
  List<AppNotification> get items {
    _$itemsAtom.reportRead();
    return super.items;
  }

  @override
  set items(List<AppNotification> value) {
    _$itemsAtom.reportWrite(value, super.items, () {
      super.items = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'NotificationsStoreBase.error',
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

  late final _$markingReadAtom = Atom(
    name: 'NotificationsStoreBase.markingRead',
    context: context,
  );

  @override
  bool get markingRead {
    _$markingReadAtom.reportRead();
    return super.markingRead;
  }

  @override
  set markingRead(bool value) {
    _$markingReadAtom.reportWrite(value, super.markingRead, () {
      super.markingRead = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'NotificationsStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$markReadAsyncAction = AsyncAction(
    'NotificationsStoreBase.markRead',
    context: context,
  );

  @override
  Future<bool> markRead([String? id]) {
    return _$markReadAsyncAction.run(() => super.markRead(id));
  }

  @override
  String toString() {
    return '''
status: ${status},
items: ${items},
error: ${error},
markingRead: ${markingRead},
unreadCount: ${unreadCount}
    ''';
  }
}
