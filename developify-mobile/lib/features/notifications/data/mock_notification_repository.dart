import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_request_scope.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/features/notifications/domain/notification_repository.dart';

final class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository(this.behavior);
  final MockBehavior behavior;
  final _requests = MockRequestScope();
  Future<Result<T>> _run<T>(T Function() operation) =>
      _requests.run(behavior, operation);
  List<AppNotification> _notifications = List.of(_initialNotifications);
  static const _initialNotifications = [
    AppNotification(
      id: 'approved',
      title: 'Approved',
      body: 'Sea point was approved. Funding starts today',
      time: '2m',
      kind: NotificationKind.approved,
      propertyId: 'sea-point',
    ),
    AppNotification(
      id: 'distribution',
      title: 'Quartely distribution',
      body: '+R 362.50 from Marula Heights credited.',
      time: '2m',
      kind: NotificationKind.distribution,
    ),
    AppNotification(
      id: 'investor',
      title: 'New investor joined',
      body: 'Sea Point sunset - 24 Investor now',
      time: '1d',
      kind: NotificationKind.investor,
      unread: false,
      propertyId: 'sea-point',
    ),
    AppNotification(
      id: 'payout',
      title: 'Payout Scheduled',
      body: 'R 4,985 lease payments - 15 Aug 2026',
      time: '2d',
      kind: NotificationKind.payout,
      unread: false,
    ),
    AppNotification(
      id: 'identity',
      title: 'Verify identity',
      body: 'Complete KYC to unlock larger investments.',
      time: '3d',
      kind: NotificationKind.identity,
      unread: false,
    ),
  ];
  final List<ChatMessage> _messages = List.of(_initialMessages);
  static const _initialMessages = [
    ChatMessage(
      id: 'm1',
      text:
          'Hi Themba! Reviewed the Malibongwe erf — looks promising. Access road in place?',
      time: '10:04',
      outgoing: false,
    ),
    ChatMessage(
      id: 'm2',
      text: 'Yes, tarred road from Beyers Naudé Dr. ~300m from plot.',
      time: '10:18',
      outgoing: true,
    ),
    ChatMessage(
      id: 'm3',
      text:
          'Great. Could you upload the SDP too? Not required, but helps us fast-track.',
      time: '10:04',
      outgoing: false,
    ),
    ChatMessage(
      id: 'm4',
      text: 'sure , will do this evening.',
      time: '10:18',
      outgoing: true,
    ),
  ];
  @override
  void clearSession() {
    _requests.cancel();
    _notifications = List.of(_initialNotifications);
    _messages
      ..clear()
      ..addAll(_initialMessages);
  }

  @override
  Future<Result<List<AppNotification>>> list() =>
      _run(() => behavior.empty ? [] : List.unmodifiable(_notifications));
  @override
  Future<Result<void>> markRead(String id) => _run(() {
    _notifications = _notifications
        .map((n) => n.id == id ? n.markRead() : n)
        .toList();
  });
  @override
  Future<Result<void>> markAllRead() => _run(() {
    _notifications = _notifications.map((n) => n.markRead()).toList();
  });
  @override
  Future<Result<List<ChatMessage>>> messages() =>
      _run(() => List.unmodifiable(_messages));
  @override
  Future<Result<ChatMessage>> sendLocalMessage(String text) => _run(() {
    final message = ChatMessage(
      id: 'local-${_messages.length}',
      text: text.trim(),
      time: 'Now',
      outgoing: true,
    );
    _messages.add(message);
    return message;
  });
}
