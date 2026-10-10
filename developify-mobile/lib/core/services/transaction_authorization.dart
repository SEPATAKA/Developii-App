import 'package:developify_mobile/core/services/session_service.dart';

abstract interface class TransactionAuthorization {
  bool verifyPin(String pin);
  bool simulateBiometric();
  bool setPin(String pin);
  void dispose();
}

// Demo-only local authorization. Production transactions require a
// server-verified challenge regardless of local PIN/biometric success.
final class MockTransactionAuthorization implements TransactionAuthorization {
  MockTransactionAuthorization(this._session) {
    _userId = _session.user?.id;
    _session.addListener(_sessionChanged);
  }
  final SessionService _session;
  String? _userId;
  String _pin = '1234';
  @override
  bool verifyPin(String pin) => _session.isAuthenticated && pin == _pin;
  @override
  bool simulateBiometric() => _session.isAuthenticated;
  @override
  bool setPin(String pin) {
    if (!_session.isAuthenticated || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false;
    }
    _pin = pin;
    return true;
  }

  void _sessionChanged() {
    if (_userId == _session.user?.id) return;
    _userId = _session.user?.id;
    _pin = '1234';
  }

  @override
  void dispose() {
    _pin = '';
    _session.removeListener(_sessionChanged);
  }
}
