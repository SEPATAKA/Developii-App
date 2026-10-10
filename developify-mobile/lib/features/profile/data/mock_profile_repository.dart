import 'dart:async';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/core/services/mock_request_scope.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this.behavior, this._session, {this.authorization}) {
    if (behavior.empty) _account = null;
  }
  final MockBehavior behavior;
  final _securityChanges = StreamController<SecurityPreferences>.broadcast(
    sync: true,
  );
  final _requests = MockRequestScope();
  Future<Result<T>> _run<T>(T Function() operation) =>
      _requests.run(behavior, operation);
  final SessionService _session;
  final TransactionAuthorization? authorization;
  SecurityPreferences _security = const SecurityPreferences();
  @override
  SecurityPreferences get securityPreferences => _security;
  @override
  Stream<SecurityPreferences> get securityChanges => _securityChanges.stream;
  @override
  void saveSecurityPreferences(SecurityPreferences value) {
    if (_securityChanges.isClosed) return;
    _security = value;
    _securityChanges.add(value);
  }

  @override
  void dispose() {
    _requests.cancel();
    unawaited(_securityChanges.close());
  }

  PayoutAccount? _account = _initialAccount;
  PayoutAccount? _freshPayout;
  static const _initialAccount = PayoutAccount(
    bank: 'Standard Bank',
    number: '0000001293',
    type: 'Cheque / Current',
    branchCode: '051001',
    holder: 'Themba Nkosi',
  );
  ProfilePreferences _preferences = const ProfilePreferences();
  @override
  void clearSession() {
    _requests.cancel();
    saveSecurityPreferences(const SecurityPreferences());
    _preferences = const ProfilePreferences();
    _freshPayout = null;
    _account = behavior.empty ? null : _initialAccount;
  }

  @override
  PayoutAccount? get payoutAccount =>
      isFreshLocalAccount(_session.user?.id) ? _freshPayout : _account;
  @override
  ProfilePreferences get preferences => _preferences;

  @override
  Future<Result<AppUser>> load() {
    final currentUser = _session.user;

    if (currentUser == null) {
      return _run(
        () =>
            throw StateError('No logged-in user found. Please sign in again.'),
      );
    }

    return _run(() => currentUser);
  }

  @override
  Future<Result<AppUser>> update(AppUser user) {
    final currentUser = _session.user;

    if (currentUser == null || currentUser.id != user.id) {
      return Future.value(
        const Failure(
          AppFailure(
            FailureKind.validation,
            'No matching logged-in user. Please sign in again.',
          ),
        ),
      );
    }

    return _run(() {
      _session.updateUser(user);
      return user;
    });
  }

  @override
  Future<Result<void>> updatePreferences(ProfilePreferences preferences) =>
      _run(() {
        _preferences = preferences;
      });
  @override
  Future<Result<void>> updatePayout(PayoutAccount account) => _run(() {
    if (isFreshLocalAccount(_session.user?.id)) {
      _freshPayout = account;
    } else {
      _account = account;
    }
  });
  @override
  Future<Result<void>> updateSecurity(String action, {String? pin}) async {
    if (action == 'change-pin' &&
        (pin == null || !RegExp(r'^\d{4}$').hasMatch(pin))) {
      return const Failure(
        AppFailure(FailureKind.validation, 'Enter a 4-digit PIN'),
      );
    }
    return _run(() {
      if (action == 'change-pin') authorization?.setPin(pin!);
    });
  }
}
