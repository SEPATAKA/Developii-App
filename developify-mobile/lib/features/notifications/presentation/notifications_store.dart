import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';
part 'notifications_store.g.dart';

class NotificationsStore = NotificationsStoreBase with _$NotificationsStore;

abstract class NotificationsStoreBase with Store, Lifecycle {
  NotificationsStoreBase(this._repository);
  final NotificationRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  List<AppNotification> items = const [];
  @observable
  String? error;
  @observable
  bool markingRead = false;
  @computed
  int get unreadCount => items.where((item) => item.unread).length;
  @action
  Future<void> load() async {
    if (isDisposed || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.list();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          items = value;
          status = value.isEmpty ? LoadStatus.empty : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<bool> markRead([String? id]) async {
    if (isDisposed || markingRead) return false;
    markingRead = true;
    error = null;
    final result = id == null
        ? await _repository.markAllRead()
        : await _repository.markRead(id);
    if (isDisposed) return false;
    return runInAction(() {
      markingRead = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      items = items
          .map((n) => id == null || n.id == id ? n.markRead() : n)
          .toList();
      return true;
    });
  }
}
