import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';
part 'chat_store.g.dart';

class ChatStore = ChatStoreBase with _$ChatStore;

abstract class ChatStoreBase with Store, Lifecycle {
  ChatStoreBase(this._repository);
  final NotificationRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  List<ChatMessage> messages = const [];
  @observable
  String draft = '';
  @observable
  bool sending = false;
  @observable
  String? error;
  @action
  void setDraft(String value) => draft = value;
  @action
  Future<void> load() async {
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.messages();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          messages = value;
          status = value.isEmpty ? LoadStatus.empty : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<bool> send() async {
    if (isDisposed || sending || draft.trim().isEmpty) return false;
    final text = draft;
    sending = true;
    error = null;
    final result = await _repository.sendLocalMessage(text);
    if (isDisposed) return false;
    return runInAction(() {
      sending = false;
      switch (result) {
        case Success(:final value):
          messages = [...messages, value];
          if (draft == text) draft = '';
          return true;
        case Failure(:final error):
          this.error = error.message;
          return false;
      }
    });
  }
}
