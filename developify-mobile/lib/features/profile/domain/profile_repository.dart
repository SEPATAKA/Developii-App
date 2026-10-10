import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class PayoutAccount {
  const PayoutAccount({
    required this.bank,
    required this.number,
    required this.type,
    required this.branchCode,
    required this.holder,
  });
  final String bank;
  final String number;
  final String type;
  final String branchCode;
  final String holder;
  String get lastFour =>
      number.length > 4 ? number.substring(number.length - 4) : number;
}

final class ProfilePreferences {
  const ProfilePreferences({
    this.channels = const {
      'Push Notification': true,
      'Email': true,
      'SMS': true,
    },
    this.topics = const {
      'Investment Confirmations': true,
      'New projects matching my interest': true,
      'Distribution payments': true,
      'Wallet activity': true,
      'Marketing & tips': true,
    },
    this.language = 'English (UK)',
  });
  final Map<String, bool> channels;
  final Map<String, bool> topics;
  final String language;
}

abstract interface class ProfileRepository {
  void dispose();
  void clearSession();
  Stream<SecurityPreferences> get securityChanges;
  SecurityPreferences get securityPreferences;
  void saveSecurityPreferences(SecurityPreferences value);
  Future<Result<AppUser>> load();
  Future<Result<AppUser>> update(AppUser user);
  PayoutAccount? get payoutAccount;
  ProfilePreferences get preferences;
  Future<Result<void>> updatePreferences(ProfilePreferences preferences);
  Future<Result<void>> updatePayout(PayoutAccount account);
  Future<Result<void>> updateSecurity(String action, {String? pin});
}

final class SecurityPreferences {
  const SecurityPreferences({
    this.biometrics = const {
      'Use for login': false,
      'Use for investment': false,
      'Use for withdrawals': false,
    },
    this.twoFactorEnabled = false,
    this.previousDevices = const ['previous-1', 'previous-2'],
  });
  final Map<String, bool> biometrics;
  final bool twoFactorEnabled;
  final List<String> previousDevices;
}
