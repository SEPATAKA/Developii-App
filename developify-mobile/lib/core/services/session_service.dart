import 'dart:async';
import 'dart:convert';
import 'package:developify_mobile/core/storage/session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class SessionService extends ChangeNotifier {
  SessionService({this.storage, DateTime Function()? now})
    : _now = now ?? DateTime.now;
  final SessionStorage? storage;
  final DateTime Function() _now;
  DateTime? _expiresAt;
  Timer? _expiryTimer;
  bool _monitoringExpiry = false;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  bool get restoring => _restoring;
  bool _restoring = false;
  Object? persistenceError;
  Future<void> get persistenceComplete => _writes;

  Future<void> restore() async {
    final sessionStorage = storage;
    if (sessionStorage == null) return;
    _restoring = true;
    try {
      final raw = await sessionStorage.read();
      if (_disposed || raw == null) return;
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['version'] != 1) return;
      _onboardingComplete = value['onboardingComplete'] == true;
      _lastUser = _decodeUser(value['returningUser']);
      _expiresAt = DateTime.tryParse(value['expiresAt'] as String? ?? '');
      final restored = _decodeUser(value['user']);
      if (_expiresAt?.isAfter(_now()) ?? false) {
        _user = restored;
        _scheduleExpiry();
      } else {
        _lastUser = restored ?? _lastUser;
      }
      // A restored login starts in Investor; portal selection is session-local.
      _experience = Experience.investor;
    } on Object catch (error) {
      persistenceError = error;
    } finally {
      _restoring = false;
      if (!_disposed) notifyListeners();
    }
  }

  static Map<String, Object?>? _encodeUser(AppUser? user) => user == null
      ? null
      : {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'address': user.address,
          'entity': user.entity.name,
          'hasProfilePhoto': user.hasProfilePhoto,
          'countryCode': user.countryCode,
          'nonResident': user.nonResident,
        };
  static AppUser? _decodeUser(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final entity = EntityType.values
        .where((e) => e.name == raw['entity'])
        .firstOrNull;
    if (entity == null ||
        raw['id'] is! String ||
        (raw['id'] as String).isEmpty ||
        raw['email'] is! String ||
        raw['name'] is! String) {
      return null;
    }
    return AppUser(
      id: raw['id'] as String,
      name: raw['name'] as String,
      email: raw['email'] as String,
      phone: raw['phone'] as String? ?? '',
      address: raw['address'] as String? ?? '',
      entity: entity,
      hasProfilePhoto: raw['hasProfilePhoto'] == true,
      countryCode: raw['countryCode'] as String? ?? 'ZA',
      nonResident: raw['nonResident'] == true,
    );
  }

  void _save() {
    final sessionStorage = storage;
    if (sessionStorage == null || _restoring) return;
    final record = jsonEncode({
      'version': 1,
      'onboardingComplete': _onboardingComplete,
      'user': _encodeUser(_user),
      'returningUser': _encodeUser(_lastUser),
      'expiresAt': _expiresAt?.toUtc().toIso8601String(),
    });
    _writes = _writes.then((_) => sessionStorage.write(record)).catchError((
      Object error,
    ) {
      persistenceError = error;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    final expiresAt = _expiresAt;
    if (!_monitoringExpiry || _user == null || expiresAt == null) return;
    _expiryTimer = Timer(expiresAt.difference(_now()), () {
      if (!_disposed) signOut();
    });
  }

  void startExpiryMonitoring() {
    _monitoringExpiry = true;
    _scheduleExpiry();
  }

  void stopExpiryMonitoring() {
    _monitoringExpiry = false;
    _expiryTimer?.cancel();
  }

  bool _onboardingComplete = false;
  AppUser? _user;
  AppUser? _lastUser;
  Experience _experience = Experience.investor;

  bool get onboardingComplete => _onboardingComplete;
  bool get isAuthenticated =>
      _user != null && (_expiresAt == null || _expiresAt!.isAfter(_now()));
  AppUser? get user => isAuthenticated ? _user : null;
  AppUser? get returningUser => _lastUser;
  Experience get experience => _experience;

  void completeOnboarding() {
    _onboardingComplete = true;
    _save();
    notifyListeners();
  }

  void signIn(AppUser user, {Experience? experience, DateTime? expiresAt}) {
    _onboardingComplete = true;
    _user = user;
    _expiresAt = expiresAt ?? _now().add(const Duration(hours: 24));
    _scheduleExpiry();
    if (experience != null) _experience = experience;
    _save();
    notifyListeners();
  }

  void selectExperience(Experience value, {bool notify = true}) {
    if (_experience == value) return;
    _experience = value;
    if (notify) notifyListeners();
  }

  void updateUser(AppUser user) {
    if (_user?.id != user.id) return;
    _user = user;
    _save();
    notifyListeners();
  }

  void signOut() {
    _expiryTimer?.cancel();
    _lastUser = _user;
    _user = null;
    _experience = Experience.investor;
    _expiresAt = null;
    _save();
    notifyListeners();
  }
}
