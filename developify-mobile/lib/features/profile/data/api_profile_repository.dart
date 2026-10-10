import 'dart:async';

import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(
    this._client,
    this._session, {
    required TransactionAuthorization authorization,
  }) : _authorization = authorization;

  final ApiClient _client;
  final SessionService _session;
  final TransactionAuthorization _authorization;
  final _securityChanges = StreamController<SecurityPreferences>.broadcast();
  SecurityPreferences _security = const SecurityPreferences();
  ProfilePreferences _preferences = const ProfilePreferences();
  PayoutAccount? _payout;

  @override
  void dispose() {
    _securityChanges.close();
  }

  @override
  void clearSession() {
    _security = const SecurityPreferences();
    _preferences = const ProfilePreferences();
    _payout = null;
  }

  @override
  Stream<SecurityPreferences> get securityChanges => _securityChanges.stream;

  @override
  SecurityPreferences get securityPreferences => _security;

  @override
  void saveSecurityPreferences(SecurityPreferences value) {
    _security = value;
    _securityChanges.add(value);
  }

  AppUser _mapUser(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    return AppUser(
      id: map['id'] as String? ?? _session.user?.id ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      entity: EntityType.values.firstWhere(
        (e) => e.name == map['entity'],
        orElse: () => EntityType.individual,
      ),
      hasProfilePhoto: map['hasProfilePhoto'] as bool? ?? false,
      countryCode: map['countryCode'] as String? ?? 'ZA',
      nonResident: map['nonResident'] as bool? ?? false,
    );
  }

  @override
  Future<Result<AppUser>> load() {
    return _client.request(path: '/v1/users/me', decode: _mapUser);
  }

  @override
  Future<Result<AppUser>> update(AppUser user) {
    return _client.request(
      path: '/v1/users/me',
      method: 'PATCH',
      data: {
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
        'countryCode': user.countryCode,
        'hasProfilePhoto': user.hasProfilePhoto,
        'nonResident': user.nonResident,
      },
      decode: _mapUser,
    );
  }

  @override
  PayoutAccount? get payoutAccount => _payout;

  @override
  ProfilePreferences get preferences => _preferences;

  @override
  Future<Result<void>> updatePreferences(ProfilePreferences preferences) async {
    final result = await _client.request(
      path: '/v1/users/me/preferences',
      method: 'PATCH',
      data: {
        'channels': preferences.channels,
        'topics': preferences.topics,
        'language': preferences.language,
      },
      decode: (_) {},
    );
    if (result.isSuccess) _preferences = preferences;
    return result;
  }

  @override
  Future<Result<void>> updatePayout(PayoutAccount account) async {
    final result = await _client.request(
      path: '/v1/users/me/payout',
      method: 'PATCH',
      data: {
        'bank': account.bank,
        'number': account.number,
        'type': account.type,
        'branchCode': account.branchCode,
        'holder': account.holder,
      },
      decode: (_) {},
    );
    if (result.isSuccess) _payout = account;
    return result;
  }

  @override
  Future<Result<void>> updateSecurity(String action, {String? pin}) async {
    final result = await _client.request(
      path: '/v1/users/me/security',
      method: 'POST',
      data: {'action': action, 'pin': pin},
      decode: (_) {},
    );
    if (result.isSuccess && action == 'setPin' && pin != null) {
      _authorization.setPin(pin);
    }
    return result;
  }
}
