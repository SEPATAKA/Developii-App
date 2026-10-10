import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/authentication/domain/investor_registration.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';

final class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this.behavior);

  final MockBehavior behavior;

  bool _recoveryRequested = false;
  bool _recoveryVerified = false;

  static const demoUser = AppUser(
    id: 'demo-landowner',
    name: 'Babatunde Yusuf',
    email: 'bafreka@gmail.com',
  );

  final _registrations = <String, AppUser>{};
  final _verifiedRegistrations = <String>{};

  int _registrationSequence = 0;
  int _landownerSequence = 0;

  @override
  Future<Result<String>> beginInvestorRegistration(
    InvestorRegistration registration, {
    Cancellation? cancellation,
  }) {
    final error =
        Validation.required(registration.name, 'your full name') ??
        Validation.email(registration.email) ??
        Validation.password(registration.password) ??
        (registration.phone.replaceAll(RegExp(r'\D'), '').length < 7
            ? 'Enter a valid phone number'
            : null) ??
        (registration.entity == EntityType.company &&
                (registration.registrationNumber.trim().isEmpty ||
                    registration.representatives.isEmpty ||
                    registration.representatives.any(
                      (person) =>
                          person.name.trim().isEmpty ||
                          person.identityNumber.trim().isEmpty,
                    ))
            ? 'Enter company registration and representative details'
            : null);

    if (error != null) {
      return Future.value(Failure(AppFailure(FailureKind.validation, error)));
    }

    return behavior.run(() {
      final id = 'registration-${++_registrationSequence}';

      _registrations[id] = AppUser(
        id: 'local-investor-$id',
        name: registration.name.trim(),
        email: registration.email.trim(),
        phone: registration.phone.trim(),
        entity: registration.entity,
        nonResident: registration.nonResident,
        countryCode: registration.countryCode,
        address: '',
        hasProfilePhoto: false,
      );

      return id;
    }, cancellation: cancellation);
  }

  @override
  Future<Result<void>> verifyInvestorRegistration(
    String challengeId,
    String code, {
    Cancellation? cancellation,
  }) {
    if (!_registrations.containsKey(challengeId) || code != '123456') {
      return Future.value(
        const Failure(
          AppFailure(
            FailureKind.validation,
            'Incorrect code. Use 123456 in this simulation.',
          ),
        ),
      );
    }

    return behavior.run(() {
      _verifiedRegistrations.add(challengeId);
    }, cancellation: cancellation);
  }

  @override
  Future<Result<AppUser>> completeInvestorRegistration(
    String challengeId, {
    Cancellation? cancellation,
  }) {
    final user = _registrations[challengeId];

    if (user == null || !_verifiedRegistrations.contains(challengeId)) {
      return Future.value(
        const Failure(
          AppFailure(
            FailureKind.validation,
            'Verify your email address before continuing.',
          ),
        ),
      );
    }

    return behavior.run(() {
      cancelInvestorRegistration(challengeId);
      return user;
    }, cancellation: cancellation);
  }

  @override
  void cancelInvestorRegistration(String challengeId) {
    _registrations.remove(challengeId);
    _verifiedRegistrations.remove(challengeId);
  }

  @override
  void clearSession() {
    _registrations.clear();
    _verifiedRegistrations.clear();
    _recoveryRequested = false;
    _recoveryVerified = false;
  }

  @override
  Future<Result<AppUser>> registerLandowner(
    LandownerRegistration registration,
  ) {
    final error =
        Validation.required(registration.name, 'your full name') ??
        Validation.email(registration.email) ??
        Validation.password(registration.password) ??
        Validation.required(registration.phone, 'your phone number');

    if (error != null) {
      return Future.value(Failure(AppFailure(FailureKind.validation, error)));
    }

    return behavior.run(
      () => AppUser(
        id: 'local-landowner-${++_landownerSequence}',
        name: registration.name.trim(),
        email: registration.email.trim(),
        phone: registration.phone.trim(),
        entity: registration.entity,
        address: '',
        hasProfilePhoto: false,
      ),
    );
  }

  @override
  Future<Result<AppUser>> signIn(String email, String password) {
    final error =
        Validation.email(email) ??
        (password.isEmpty ? 'Enter your password' : null);

    if (error != null) {
      return Future.value(Failure(AppFailure(FailureKind.validation, error)));
    }

    return behavior.run(() => demoUser.copyWith(email: email.trim()));
  }

  @override
  Future<Result<AppUser>> socialSignIn(String provider) {
    return behavior.run(() => demoUser);
  }

  @override
  Future<Result<void>> requestRecovery(String email) async {
    final error = Validation.email(email);

    if (error != null) {
      return Failure(AppFailure(FailureKind.validation, error));
    }

    return behavior.run(() {
      _recoveryRequested = true;
      _recoveryVerified = false;
    });
  }

  @override
  Future<Result<void>> verifyRecovery(String code) {
    if (!_recoveryRequested || code != '123456') {
      return Future.value(
        const Failure(AppFailure(FailureKind.validation, 'Incorrect code.')),
      );
    }

    return behavior.run(() {
      _recoveryVerified = true;
    });
  }

  @override
  Future<Result<void>> resetPassword(String password) {
    if (!_recoveryVerified) {
      return Future.value(
        const Failure(
          AppFailure(
            FailureKind.validation,
            'Verify your recovery code first.',
          ),
        ),
      );
    }

    final error = Validation.password(password);

    if (error != null) {
      return Future.value(Failure(AppFailure(FailureKind.validation, error)));
    }

    return behavior.run(() {
      _recoveryRequested = false;
      _recoveryVerified = false;
    });
  }
}
