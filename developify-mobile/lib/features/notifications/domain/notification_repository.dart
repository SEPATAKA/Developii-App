import 'package:developify_mobile/core/errors/result.dart';

enum NotificationKind { approved, distribution, investor, payout, identity }

final class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.unread = true,
    this.propertyId,
  });
  final String id;
  final String title;
  final String body;
  final String time;
  final NotificationKind kind;
  final bool unread;
  final String? propertyId;
  AppNotification markRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    time: time,
    kind: kind,
    unread: false,
    propertyId: propertyId,
  );
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.outgoing,
  });
  final String id;
  final String text;
  final String time;
  final bool outgoing;
}

abstract interface class NotificationRepository {
  void clearSession();
  Future<Result<List<AppNotification>>> list();
  Future<Result<void>> markRead(String id);
  Future<Result<void>> markAllRead();
  Future<Result<List<ChatMessage>>> messages();
  Future<Result<ChatMessage>> sendLocalMessage(String text);
}
