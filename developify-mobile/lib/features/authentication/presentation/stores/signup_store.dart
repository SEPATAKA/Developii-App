import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/landowner_registration.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

part 'signup_store.g.dart';

class SignupStore = SignupStoreBase with _$SignupStore;

enum SignupAppearance { empty, filled, accepted, invalid }

abstract class SignupStoreBase with Store, Lifecycle {
  SignupStoreBase(this._repository, this._session);
  final AuthRepository _repository;
  final SessionService _session;

  @observable
  String name = '';
  @observable
  String email = '';
  @observable
  String phone = '';
  @observable
  String countryCode = 'US';
  @observable
  String dialCode = '+1';
  @observable
  String password = '';
  @observable
  String confirmation = '';
  @observable
  bool passwordVisible = false;
  @observable
  bool confirmationVisible = false;
  @observable
  bool acceptedTerms = false;
  @observable
  bool choosingEntity = false;
  @observable
  EntityType? entity;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  String? error;
  @observable
  bool invalidCredentials = false;

  @computed
  bool get detailsFilled => canAttemptDetails && phone.trim().isNotEmpty;
  @computed
  bool get canAttemptDetails =>
      name.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      password.isNotEmpty &&
      confirmation.isNotEmpty;
  @computed
  SignupAppearance get appearance => invalidCredentials
      ? SignupAppearance.invalid
      : detailsFilled
      ? acceptedTerms
            ? SignupAppearance.accepted
            : SignupAppearance.filled
      : SignupAppearance.empty;
  @computed
  int get passwordStrength {
    if (password.isEmpty) return 0;
    return [
      password.length >= 8,
      RegExp('[a-z]').hasMatch(password),
      RegExp('[A-Z]').hasMatch(password),
      RegExp('[0-9]').hasMatch(password),
    ].where((value) => value).length;
  }

  void _clearError() {
    error = null;
    invalidCredentials = false;
  }

  @action
  void setName(String value) {
    name = value;
    _clearError();
  }

  @action
  void setEmail(String value) {
    email = value;
    _clearError();
  }

  @action
  void setPhone(String value) {
    phone = value;
    _clearError();
  }

  @action
  void setCountry(String code, String prefix) {
    countryCode = code;
    dialCode = prefix;
  }

  @action
  void setPassword(String value) {
    password = value;
    _clearError();
  }

  @action
  void setConfirmation(String value) {
    confirmation = value;
    _clearError();
  }

  @action
  void togglePassword() => passwordVisible = !passwordVisible;
  @action
  void toggleConfirmation() => confirmationVisible = !confirmationVisible;
  @action
  void acceptTerms(bool value) {
    acceptedTerms = value;
    error = null;
  }

  @action
  void selectEntity(EntityType value) {
    entity = value;
    error = null;
  }

  @action
  void returnToDetails() {
    choosingEntity = false;
    error = null;
  }

  @action
  bool continueToEntity() {
    error =
        Validation.required(name, 'your full name') ??
        Validation.email(email) ??
        (phone.replaceAll(RegExp(r'\D'), '').length < 7
            ? 'Enter a valid phone number'
            : null) ??
        Validation.password(password) ??
        (confirmation != password ? 'Passwords do not match' : null) ??
        (!acceptedTerms ? 'Agree to the Landowner Terms to continue' : null);
    invalidCredentials =
        Validation.password(password) != null || confirmation != password;
    if (error != null) return false;
    choosingEntity = true;
    return true;
  }

  @action
  Future<bool> createAccount() async {
    if (isDisposed || status == LoadStatus.loading) return false;
    if (!continueToEntity()) return false;
    final owner = entity;
    if (owner == null) {
      error = 'Choose who owns the land';
      return false;
    }
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.registerLandowner(
      LandownerRegistration(
        name: name,
        email: email,
        phone: '$dialCode $phone',
        password: password,
        entity: owner,
      ),
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      switch (result) {
        case Success(:final value):
          status = LoadStatus.success;
          password = '';
          confirmation = '';
          _session.signIn(value, experience: Experience.landowner);
          return true;
        case Failure(:final error):
          status = LoadStatus.error;
          this.error = error.message;
          if (error.kind == FailureKind.validation) {
            invalidCredentials = true;
            choosingEntity = false;
          }
          return false;
      }
    });
  }
}
