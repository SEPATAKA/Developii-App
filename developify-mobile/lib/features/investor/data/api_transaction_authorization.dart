import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';

/// Live PIN authorization: local check for UX; server re-verifies on writes.
final class ApiTransactionAuthorization implements TransactionAuthorization {
  ApiTransactionAuthorization(this._session, this._client) {
    _userId = _session.user?.id;
    _session.addListener(_sessionChanged);
  }

  final SessionService _session;
  final ApiClient _client;
  String? _userId;
  String? _cachedPin;

  @override
  bool verifyPin(String pin) {
    if (!_session.isAuthenticated) return false;
    if (_cachedPin != null) return pin == _cachedPin;
    return RegExp(r'^\d{4,}$').hasMatch(pin);
  }

  @override
  bool simulateBiometric() => _session.isAuthenticated;

  @override
  bool setPin(String pin) {
    if (!_session.isAuthenticated || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false;
    }
    _cachedPin = pin;
    _client.request(
      path: '/v1/users/me/security',
      method: 'POST',
      data: {'action': 'setPin', 'pin': pin},
      decode: (_) {},
    );
    return true;
  }

  void _sessionChanged() {
    if (_userId == _session.user?.id) return;
    _userId = _session.user?.id;
    _cachedPin = null;
  }

  @override
  void dispose() {
    _cachedPin = null;
    _session.removeListener(_sessionChanged);
  }
}
