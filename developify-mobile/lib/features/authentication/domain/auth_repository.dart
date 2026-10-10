import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/authentication/domain/investor_registration.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';

abstract interface class AuthRepository {
  Future<Result<String>> beginInvestorRegistration(
    InvestorRegistration registration, {
    Cancellation? cancellation,
  });
  Future<Result<void>> verifyInvestorRegistration(
    String challengeId,
    String code, {
    Cancellation? cancellation,
  });
  Future<Result<AppUser>> completeInvestorRegistration(
    String challengeId, {
    Cancellation? cancellation,
  });
  void cancelInvestorRegistration(String challengeId);
  void clearSession();
  Future<Result<AppUser>> registerLandowner(LandownerRegistration registration);
  Future<Result<AppUser>> signIn(String email, String password);
  Future<Result<AppUser>> socialSignIn(String provider);
  Future<Result<void>> requestRecovery(String email);
  Future<Result<void>> verifyRecovery(String code);
  Future<Result<void>> resetPassword(String password);
}
