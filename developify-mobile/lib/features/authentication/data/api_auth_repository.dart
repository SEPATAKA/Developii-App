import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/storage/token_storage.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/investor_registration.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._tokens);
  final ApiClient _client;
  final TokenStorage _tokens;
  String? _recoveryChallengeId;
  String? _recoveryEmail;

  AppUser _user(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    return AppUser(
      id: map['id'] as String? ?? '',
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

  Future<Result<AppUser>> _storeSession(Object? json) async {
    final map = json as Map<String, Object?>? ?? const {};
    final access = map['accessToken'] as String?;
    final refresh = map['refreshToken'] as String?;
    if (access != null) await _tokens.writeToken(access);
    if (refresh != null) await _tokens.writeRefreshToken(refresh);
    return Success(_user(map['user']));
  }

  Future<bool> refreshSession() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    final result = await _client.request<Object?>(
      path: '/v1/auth/refresh',
      method: 'POST',
      authenticated: false,
      data: {'refreshToken': refresh},
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      final map = value as Map<String, Object?>? ?? const {};
      final access = map['accessToken'] as String?;
      final nextRefresh = map['refreshToken'] as String?;
      if (access != null) await _tokens.writeToken(access);
      if (nextRefresh != null) await _tokens.writeRefreshToken(nextRefresh);
      return access != null;
    }
    return false;
  }

  @override
  Future<Result<String>> beginInvestorRegistration(
    InvestorRegistration registration, {
    Cancellation? cancellation,
  }) {
    return _client.request(
      path: '/v1/auth/register/investor/begin',
      method: 'POST',
      authenticated: false,
      data: {
        'name': registration.name,
        'email': registration.email,
        'phone': registration.phone,
        'password': registration.password,
        'entity': registration.entity.name,
        'nonResident': registration.nonResident,
        'countryCode': registration.countryCode,
      },
      decode: (json) =>
          (json as Map<String, Object?>)['challengeId'] as String? ?? '',
    );
  }

  @override
  Future<Result<void>> verifyInvestorRegistration(
    String challengeId,
    String code, {
    Cancellation? cancellation,
  }) {
    return _client.request(
      path: '/v1/auth/register/investor/verify',
      method: 'POST',
      authenticated: false,
      data: {'challengeId': challengeId, 'code': code},
      decode: (_) {},
    );
  }

  @override
  Future<Result<AppUser>> completeInvestorRegistration(
    String challengeId, {
    Cancellation? cancellation,
  }) {
    return _client
        .request(
          path: '/v1/auth/register/investor/complete',
          method: 'POST',
          authenticated: false,
          data: {'challengeId': challengeId},
          decode: (json) => json,
        )
        .then((result) async {
          if (result case Success(:final value)) {
            return _storeSession(value);
          }
          return result as Failure<AppUser>;
        });
  }

  @override
  void cancelInvestorRegistration(String challengeId) {
    _client.request(
      path: '/v1/auth/register/investor/cancel',
      method: 'POST',
      authenticated: false,
      data: {'challengeId': challengeId},
      decode: (_) {},
    );
  }

  @override
  void clearSession() {
    _recoveryChallengeId = null;
    _recoveryEmail = null;
  }

  @override
  Future<Result<AppUser>> registerLandowner(LandownerRegistration registration) {
    return _client
        .request(
          path: '/v1/auth/register/landowner',
          method: 'POST',
          authenticated: false,
          data: {
            'name': registration.name,
            'email': registration.email,
            'phone': registration.phone,
            'password': registration.password,
            'countryCode': 'ZA',
          },
          decode: (json) => json,
        )
        .then((result) async {
          if (result case Success(:final value)) return _storeSession(value);
          return result as Failure<AppUser>;
        });
  }

  @override
  Future<Result<AppUser>> signIn(String email, String password) {
    return _client
        .request(
          path: '/v1/auth/sign-in',
          method: 'POST',
          authenticated: false,
          data: {'email': email, 'password': password},
          decode: (json) => json,
        )
        .then((result) async {
          if (result case Success(:final value)) return _storeSession(value);
          return result as Failure<AppUser>;
        });
  }

  @override
  Future<Result<AppUser>> socialSignIn(String provider) {
    return _client.request(
      path: '/v1/auth/social-sign-in',
      method: 'POST',
      authenticated: false,
      data: {'provider': provider},
      decode: (json) => _user((json as Map)['user']),
    );
  }

  @override
  Future<Result<void>> requestRecovery(String email) async {
    _recoveryEmail = email;
    return _client.request(
      path: '/v1/auth/recovery/request',
      method: 'POST',
      authenticated: false,
      data: {'email': email},
      decode: (_) {},
    );
  }

  @override
  Future<Result<void>> verifyRecovery(String code) async {
    final email = _recoveryEmail;
    if (email == null) {
      return const Failure(
        AppFailure(FailureKind.validation, 'Start recovery with an email first.'),
      );
    }
    final result = await _client.request<Object?>(
      path: '/v1/auth/recovery/verify',
      method: 'POST',
      authenticated: false,
      data: {'email': email, 'code': code},
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      _recoveryChallengeId =
          (value as Map<String, Object?>)['challengeId'] as String?;
      return const Success(null);
    }
    return result as Failure<void>;
  }

  @override
  Future<Result<void>> resetPassword(String password) async {
    final challengeId = _recoveryChallengeId;
    if (challengeId == null) {
      return const Failure(
        AppFailure(FailureKind.validation, 'Verify the recovery code first.'),
      );
    }
    return _client.request(
      path: '/v1/auth/recovery/reset',
      method: 'POST',
      authenticated: false,
      data: {'challengeId': challengeId, 'password': password},
      decode: (_) {},
    );
  }
}
