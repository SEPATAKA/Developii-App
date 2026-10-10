import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';

enum PushDestination { notifications, property }

final class PushTarget {
  const PushTarget(this.destination, {this.id});
  final PushDestination destination;
  final String? id;

  // Shape validation does not authorize resource access. Deferred routing and
  // backend membership checks remain integration work; see the notification guide.
  static PushTarget? fromPlaceholder(Map<String, dynamic>? data) {
    if (data == null) return null;
    final destination = data['destination'];
    final id = data['id'];
    if (destination == 'notifications') {
      return const PushTarget(PushDestination.notifications);
    }
    if (destination == 'property' &&
        id is String &&
        RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id)) {
      return PushTarget(PushDestination.property, id: id);
    }
    return null;
  }
}

abstract interface class PushNotificationService {
  bool get isConfigured;
  Stream<PushTarget> get taps;
  Stream<PushTarget> get foreground;
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> setExternalUserId(String id);
  Future<void> removeExternalUserId();
  Future<void> addTags(Map<String, String> tags);
  Future<void> removeTags(List<String> keys);
  Future<void> dispose();
}

final class OneSignalPushService implements PushNotificationService {
  OneSignalPushService(this._appId);
  final String _appId;
  final _taps = StreamController<PushTarget>.broadcast();
  final _foreground = StreamController<PushTarget>.broadcast();
  bool _initialized = false;
  bool _disposed = false;
  @override
  bool get isConfigured => _initialized;
  @override
  Stream<PushTarget> get taps => _taps.stream;
  @override
  Stream<PushTarget> get foreground => _foreground.stream;

  @override
  Future<void> initialize() async {
    if (_initialized || _disposed || _appId.trim().isEmpty) return;
    try {
      await OneSignal.Debug.setLogLevel(OSLogLevel.none);
      await OneSignal.initialize(_appId);
      OneSignal.Notifications.addClickListener(_onTap);
      OneSignal.Notifications.addForegroundWillDisplayListener(_onForeground);
      _initialized = true;
    } on Object {
      _initialized = false;
    }
  }

  void _onTap(OSNotificationClickEvent event) {
    final target = PushTarget.fromPlaceholder(
      event.notification.additionalData,
    );
    if (!_disposed && target != null) _taps.add(target);
  }

  void _onForeground(OSNotificationWillDisplayEvent event) {
    final target = PushTarget.fromPlaceholder(
      event.notification.additionalData,
    );
    if (!_disposed && target != null) _foreground.add(target);
  }

  @override
  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      return await OneSignal.Notifications.requestPermission(false);
    } on Object {
      return false;
    }
  }

  Future<void> _safely(Future<void> Function() action) async {
    if (!_initialized || _disposed) return;
    try {
      await action();
    } on Object {
      return;
    }
  }

  @override
  Future<void> setExternalUserId(String id) =>
      _safely(() => OneSignal.login(id));
  @override
  Future<void> removeExternalUserId() => _safely(OneSignal.logout);
  @override
  Future<void> addTags(Map<String, String> tags) =>
      _safely(() => OneSignal.User.addTags(tags));
  @override
  Future<void> removeTags(List<String> keys) =>
      _safely(() => OneSignal.User.removeTags(keys));
  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_initialized) {
      OneSignal.Notifications.removeClickListener(_onTap);
      OneSignal.Notifications.removeForegroundWillDisplayListener(
        _onForeground,
      );
    }
    await _taps.close();
    await _foreground.close();
  }
}
