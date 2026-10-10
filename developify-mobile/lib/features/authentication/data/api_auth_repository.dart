import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/storage/token_storage.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/investor_registration.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(
    this._client,
    this._tokens, {
    this.firebaseAuth,
    this.firebaseAuthRequired = false,
  });
  final ApiClient _client;
  final TokenStorage _tokens;
  final FirebaseAuth? firebaseAuth;
  final bool firebaseAuthRequired;
  String? _recoveryChallengeId;
  String? _recoveryEmail;
  InvestorRegistration? _pendingInvestorRegistration;
  bool _emailVerificationPending = false;

  @override
  bool get emailVerificationPending => _emailVerificationPending;

  @override
  bool get usesFirebaseEmailLink => firebaseAuthRequired;

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
  }) async {
    if (firebaseAuthRequired && firebaseAuth == null) {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is not configured for this build.',
        ),
      );
    }
    if (firebaseAuthRequired) {
      try {
        final auth = firebaseAuth!;
        UserCredential credential;
        try {
          credential = await auth.createUserWithEmailAndPassword(
            email: registration.email.trim(),
            password: registration.password,
          );
        } on FirebaseAuthException catch (error) {
          if (error.code != 'email-already-in-use') rethrow;
          credential = await auth.signInWithEmailAndPassword(
            email: registration.email.trim(),
            password: registration.password,
          );
        }
        final user = credential.user;
        if (user == null) {
          return const Failure(
            AppFailure(
              FailureKind.unauthenticated,
              'Firebase did not return a registered user.',
            ),
          );
        }
        await user.updateDisplayName(registration.name.trim());
        await user.reload();
        final activeUser = auth.currentUser;
        if (activeUser != null && !activeUser.emailVerified) {
          await activeUser.sendEmailVerification();
        }
      } on FirebaseAuthException catch (error) {
        return Failure(_firebaseAuthFailure(error, registration: true));
      } on FirebaseException {
        return const Failure(
          AppFailure(
            FailureKind.configuration,
            'Firebase Authentication is unavailable in this build.',
          ),
        );
      }
    }
    final result = await _client.request<String>(
      path: '/v1/auth/register/investor/begin',
      method: 'POST',
      authenticated: false,
      data: {
        'name': registration.name,
        'email': registration.email,
        'phone': registration.phone,
        'firebaseAuth': firebaseAuthRequired,
        if (!firebaseAuthRequired) 'password': registration.password,
        'entity': registration.entity.name,
        'nonResident': registration.nonResident,
        'countryCode': registration.countryCode,
      },
      decode: (json) =>
          (json as Map<String, Object?>)['challengeId'] as String? ?? '',
    );
    if (result case Success()) _pendingInvestorRegistration = registration;
    return result;
  }

  @override
  Future<Result<void>> verifyInvestorRegistration(
    String challengeId,
    String code, {
    Cancellation? cancellation,
  }) async {
    if (firebaseAuthRequired) {
      final user = firebaseAuth?.currentUser;
      if (user == null ||
          user.email?.toLowerCase().trim() !=
              _pendingInvestorRegistration?.email.toLowerCase().trim()) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Sign in again to verify this registration.',
          ),
        );
      }
      try {
        await user.reload();
        if (firebaseAuth?.currentUser?.emailVerified != true) {
          return const Failure(
            AppFailure(
              FailureKind.unauthenticated,
              'Open the verification link in your email, then try again.',
            ),
          );
        }
        await firebaseAuth?.currentUser?.getIdToken(true);
        return const Success(null);
      } on FirebaseAuthException catch (error) {
        return Failure(_firebaseAuthFailure(error));
      } on FirebaseException {
        return const Failure(
          AppFailure(
            FailureKind.configuration,
            'Firebase Authentication is unavailable in this build.',
          ),
        );
      }
    }
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
    if (firebaseAuthRequired) {
      return _completeFirebaseInvestorRegistration(challengeId);
    }
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

  Future<Result<AppUser>> _completeFirebaseInvestorRegistration(
    String challengeId,
  ) async {
    final auth = firebaseAuth;
    final registration = _pendingInvestorRegistration;
    if (auth == null || registration == null) {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase registration is unavailable. Restart account creation.',
        ),
      );
    }
    try {
      User? user = auth.currentUser;
      if (user?.email?.toLowerCase().trim() !=
          registration.email.toLowerCase().trim()) {
        UserCredential credential;
        try {
          credential = await auth.createUserWithEmailAndPassword(
            email: registration.email.trim(),
            password: registration.password,
          );
        } on FirebaseAuthException catch (error) {
          if (error.code != 'email-already-in-use') rethrow;
          credential = await auth.signInWithEmailAndPassword(
            email: registration.email.trim(),
            password: registration.password,
          );
        }
        user = credential.user;
      }
      if (user == null) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Firebase did not return a registered user.',
          ),
        );
      }
      await user.updateDisplayName(registration.name.trim());
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Could not obtain a Firebase registration token.',
          ),
        );
      }
      final result = await _client.request<Object?>(
        path: '/v1/auth/register/investor/complete',
        method: 'POST',
        authenticated: false,
        data: {'challengeId': challengeId, 'idToken': idToken},
        decode: (json) => json,
      );
      if (result case Success(:final value)) {
        final response = Map<String, Object?>.from(value as Map);
        final refreshedToken = await auth.currentUser?.getIdToken(true);
        if (refreshedToken != null) response['accessToken'] = refreshedToken;
        _pendingInvestorRegistration = null;
        return await _storeSession(response);
      }
      return result as Failure<AppUser>;
    } on FirebaseAuthException catch (error) {
      return Failure(_firebaseAuthFailure(error, registration: true));
    } on FirebaseException {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is unavailable in this build.',
        ),
      );
    }
  }

  AppFailure _firebaseAuthFailure(
    FirebaseAuthException error, {
    bool registration = false,
  }) {
    final message = switch (error.code) {
      'email-already-in-use' =>
        registration
            ? 'A Firebase account already exists for this email. Sign in instead.'
            : 'An account with this email already exists.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Invalid email or password.',
      'weak-password' => 'Choose a stronger password.',
      'invalid-email' => 'Enter a valid email address.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'network-request-failed' =>
        'Unable to reach Firebase. Check your connection and try again.',
      'user-disabled' => 'This account is disabled.',
      _ =>
        registration
            ? 'Firebase account creation failed. Please try again.'
            : 'Firebase sign-in failed. Please try again.',
    };
    return AppFailure(
      error.code == 'network-request-failed'
          ? FailureKind.network
          : FailureKind.unauthenticated,
      message,
    );
  }

  Future<Result<AppUser>> _firebaseSignIn(String email, String password) async {
    final auth = firebaseAuth;
    if (auth == null) {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is not configured for this build.',
        ),
      );
    }
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Firebase did not return a signed-in user.',
          ),
        );
      }
      await user.reload();
      final refreshedUser = auth.currentUser;
      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await user.sendEmailVerification();
        await auth.signOut();
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Verify your email using the link we just sent, then sign in again.',
          ),
        );
      }
      final idToken = await refreshedUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Could not obtain a Firebase sign-in token.',
          ),
        );
      }
      final result = await _client.request<Object?>(
        path: '/v1/auth/firebase/session',
        method: 'POST',
        authenticated: false,
        data: {'idToken': idToken},
        decode: (json) => json,
      );
      if (result case Success(:final value)) return await _storeSession(value);
      return result as Failure<AppUser>;
    } on FirebaseAuthException catch (error) {
      return Failure(_firebaseAuthFailure(error));
    } on FirebaseException {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is unavailable in this build.',
        ),
      );
    }
  }

  @override
  void cancelInvestorRegistration(String challengeId) {
    if (firebaseAuthRequired) unawaited(firebaseAuth?.signOut());
    _pendingInvestorRegistration = null;
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
    _pendingInvestorRegistration = null;
    _emailVerificationPending = false;
    if (firebaseAuthRequired) {
      unawaited(firebaseAuth?.signOut());
    }
  }

  @override
  Future<Result<AppUser>> registerLandowner(
    LandownerRegistration registration,
  ) {
    if (firebaseAuthRequired) return _registerFirebaseLandowner(registration);
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

  Future<Result<AppUser>> _registerFirebaseLandowner(
    LandownerRegistration registration,
  ) async {
    final auth = firebaseAuth;
    if (auth == null) {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is not configured for this build.',
        ),
      );
    }
    try {
      late final UserCredential credential;
      var newFirebaseAccount = true;
      try {
        credential = await auth.createUserWithEmailAndPassword(
          email: registration.email.trim(),
          password: registration.password,
        );
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        newFirebaseAccount = false;
        credential = await auth.signInWithEmailAndPassword(
          email: registration.email.trim(),
          password: registration.password,
        );
      }
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Firebase did not return a registered user.',
          ),
        );
      }
      await user.updateDisplayName(registration.name.trim());
      if (newFirebaseAccount && !user.emailVerified) {
        await user.sendEmailVerification();
      }
      final idToken = await user.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        return const Failure(
          AppFailure(
            FailureKind.unauthenticated,
            'Could not obtain a Firebase registration token.',
          ),
        );
      }
      final result = await _client.request<Object?>(
        path: '/v1/auth/register/landowner',
        method: 'POST',
        authenticated: false,
        data: {
          'name': registration.name,
          'email': registration.email.trim(),
          'phone': registration.phone,
          'countryCode': 'ZA',
          'entity': registration.entity.name,
          'idToken': idToken,
        },
        decode: (json) => json,
      );
      if (result case Success(:final value)) {
        _emailVerificationPending = true;
        await auth.signOut();
        return Success(_user((value as Map<String, Object?>)['user']));
      }
      return result as Failure<AppUser>;
    } on FirebaseAuthException catch (error) {
      return Failure(_firebaseAuthFailure(error, registration: true));
    } on FirebaseException {
      return const Failure(
        AppFailure(
          FailureKind.configuration,
          'Firebase Authentication is unavailable in this build.',
        ),
      );
    }
  }

  @override
  Future<Result<AppUser>> signIn(String email, String password) {
    if (firebaseAuthRequired) {
      return _firebaseSignIn(email, password).then((result) {
        if (result case Success()) _emailVerificationPending = false;
        return result;
      });
    }
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
        AppFailure(
          FailureKind.validation,
          'Start recovery with an email first.',
        ),
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
