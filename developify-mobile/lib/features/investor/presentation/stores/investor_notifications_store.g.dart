// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_notifications_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestorNotificationsStore on InvestorNotificationsStoreBase, Store {
  Computed<List<InvestorNotification>>? _$notificationsComputed;

  @override
  List<InvestorNotification> get notifications =>
      (_$notificationsComputed ??= Computed<List<InvestorNotification>>(
        () => super.notifications,
        name: 'InvestorNotificationsStoreBase.notifications',
      )).value;

  late final _$statusAtom = Atom(
    name: 'InvestorNotificationsStoreBase.status',
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
    name: 'InvestorNotificationsStoreBase.data',
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
    name: 'InvestorNotificationsStoreBase.error',
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
    name: 'InvestorNotificationsStoreBase.filter',
    context: context,
  );

  @override
  InvestorNotificationFilter? get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(InvestorNotificationFilter? value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$savingAtom = Atom(
    name: 'InvestorNotificationsStoreBase.saving',
    context: context,
  );

  @override
  bool get saving {
    _$savingAtom.reportRead();
    return super.saving;
  }

  @override
  set saving(bool value) {
    _$savingAtom.reportWrite(value, super.saving, () {
      super.saving = value;
    });
  }

  late final _$markReadAsyncAction = AsyncAction(
    'InvestorNotificationsStoreBase.markRead',
    context: context,
  );

  @override
  Future<bool> markRead([String? id]) {
    return _$markReadAsyncAction.run(() => super.markRead(id));
  }

  late final _$loadAsyncAction = AsyncAction(
    'InvestorNotificationsStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$InvestorNotificationsStoreBaseActionController =
      ActionController(
        name: 'InvestorNotificationsStoreBase',
        context: context,
      );

  @override
  void setFilter(InvestorNotificationFilter? value) {
    final _$actionInfo = _$InvestorNotificationsStoreBaseActionController
        .startAction(name: 'InvestorNotificationsStoreBase.setFilter');
    try {
      return super.setFilter(value);
    } finally {
      _$InvestorNotificationsStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
data: ${data},
error: ${error},
filter: ${filter},
saving: ${saving},
notifications: ${notifications}
    ''';
  }
}
