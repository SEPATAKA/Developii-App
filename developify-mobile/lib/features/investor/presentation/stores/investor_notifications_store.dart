import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'investor_notifications_store.g.dart';

class InvestorNotificationsStore = InvestorNotificationsStoreBase
    with _$InvestorNotificationsStore;

abstract class InvestorNotificationsStoreBase with Store, Lifecycle {
  InvestorNotificationsStoreBase(this._repository) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed ||
          !event.kinds.any(
            const {
              InvestorDataKind.scope,
              InvestorDataKind.notifications,
            }.contains,
          )) {
        return;
      }
      if (event.kinds.contains(InvestorDataKind.scope)) {
        runInAction(() {
          data = null;
          filter = null;
          saving = false;
          _saveVersion++;
        });
      }
      unawaited(load());
    });
  }
  final InvestorAccountRepository _repository;
  late final StreamSubscription<InvestorAccountChange> _changes;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  InvestorAccountSnapshot? data;
  @observable
  String? error;
  @observable
  InvestorNotificationFilter? filter;
  @observable
  bool saving = false;
  int _saveVersion = 0;
  @computed
  List<InvestorNotification> get notifications =>
      data?.notifications
          .where((item) => filter == null || item.category == filter)
          .toList() ??
      const [];
  @action
  void setFilter(InvestorNotificationFilter? value) => filter = value;
  @action
  Future<bool> markRead([String? id]) async {
    if (isDisposed || saving) return false;
    final version = ++_saveVersion;
    saving = true;
    final result = await _repository.markNotificationsRead(id);
    if (isDisposed || version != _saveVersion) return false;
    return runInAction(() {
      saving = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      return true;
    });
  }

  @action
  Future<void> load() async {
    if (isDisposed) return;
    final request = beginRequest();
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.snapshot();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          data = value;
          status = value.notifications.isEmpty
              ? LoadStatus.empty
              : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}
