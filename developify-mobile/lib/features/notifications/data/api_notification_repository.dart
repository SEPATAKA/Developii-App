import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';

final class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);
  final ApiClient _client;

  AppNotification _mapNotification(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final kindName = map['kind'] as String? ?? 'investor';
    final kind = NotificationKind.values.firstWhere(
      (k) => k.name == kindName,
      orElse: () => NotificationKind.investor,
    );
    final created =
        DateTime.tryParse(map['createdAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    return AppNotification(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      time: created.toLocal().toString(),
      kind: kind,
      unread: !(map['read'] as bool? ?? false),
    );
  }

  ChatMessage _mapMessage(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final created =
        DateTime.tryParse(map['createdAt'] as String? ?? '') ??
        DateTime.now().toUtc();
    return ChatMessage(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
      time: created.toLocal().toString(),
      outgoing: !(map['fromSupport'] as bool? ?? false),
    );
  }

  @override
  void clearSession() {}

  @override
  Future<Result<List<AppNotification>>> list() {
    return _client.request(
      path: '/v1/notifications',
      decode: (json) =>
          ((json as List<dynamic>?) ?? const []).map(_mapNotification).toList(),
    );
  }

  @override
  Future<Result<void>> markRead(String id) {
    return _client.request(
      path: '/v1/notifications/$id/read',
      method: 'POST',
      decode: (_) {},
    );
  }

  @override
  Future<Result<void>> markAllRead() {
    return _client.request(
      path: '/v1/notifications/read-all',
      method: 'POST',
      decode: (_) {},
    );
  }

  @override
  Future<Result<List<ChatMessage>>> messages() {
    return _client.request(
      path: '/v1/notifications/chat/messages',
      decode: (json) =>
          ((json as List<dynamic>?) ?? const []).map(_mapMessage).toList(),
    );
  }

  @override
  Future<Result<ChatMessage>> sendLocalMessage(String text) {
    return _client.request(
      path: '/v1/notifications/chat/messages',
      method: 'POST',
      data: {'text': text},
      decode: _mapMessage,
    );
  }
}
