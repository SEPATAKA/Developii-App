import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';

part 'recovery_store.g.dart';

class RecoveryStore = RecoveryStoreBase with _$RecoveryStore;

abstract class RecoveryStoreBase with Store, Lifecycle {
  RecoveryStoreBase(this._repository);
  final AuthRepository _repository;
  Timer? _timer;
  @observable
  String email = '';
  @observable
  String code = '';
  @observable
  String password = '';
  @observable
  String confirmation = '';
  @observable
  bool passwordVisible = false;
  @observable
  bool confirmationVisible = false;
  @observable
  int stage = 0;
  @observable
  int resendSeconds = 0;
  @observable
  bool submitted = false;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  String? error;
  @observable
  bool codeRejected = false;
  @observable
  bool passwordRejected = false;
  @computed
  String get maskedEmail {
    final parts = email.trim().split('@');
    if (parts.length != 2 || parts.first.isEmpty) return email;
    final name = parts.first;
    final suffix = name.length > 4 ? name.substring(name.length - 4) : '';
    return '${name[0]}***$suffix@${parts[1]}';
  }

  @computed
  bool get passwordInvalid =>
      passwordRejected || confirmation.isNotEmpty && password != confirmation;
  @computed
  int get passwordStrength => [
    password.length >= 8,
    RegExp(r'[a-z]').hasMatch(password),
    RegExp(r'[A-Z]').hasMatch(password),
    RegExp(r'[0-9]').hasMatch(password),
    !passwordInvalid && RegExp(r'[^a-zA-Z0-9]').hasMatch(password),
  ].where((satisfied) => satisfied).length;
  @computed
  String? get emailError => submitted ? Validation.email(email) : null;
  @computed
  bool get canContinue => switch (stage) {
    0 => Validation.email(email) == null,
    1 => RegExp(r'^\d{6}$').hasMatch(code) && !codeRejected,
    _ =>
      Validation.password(password) == null &&
          password == confirmation &&
          !passwordRejected,
  };
  @action
  void setEmail(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    email = value;
    error = null;
  }

  @action
  void setCode(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    code = value;
    error = null;
    codeRejected = false;
  }

  @action
  void setPassword(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    password = value;
    error = null;
    passwordRejected = false;
  }

  @action
  void setConfirmation(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    confirmation = value;
    error = null;
    passwordRejected = false;
  }

  @action
  void togglePassword() {
    if (!isDisposed && status != LoadStatus.loading) {
      passwordVisible = !passwordVisible;
    }
  }

  @action
  void toggleConfirmation() {
    if (!isDisposed && status != LoadStatus.loading) {
      confirmationVisible = !confirmationVisible;
    }
  }

  @action
  void back() {
    if (isDisposed) return;
    if (stage > 0 && status != LoadStatus.loading) {
      stage--;
      submitted = false;
      error = null;
      codeRejected = false;
      passwordRejected = false;
      code = '';
      password = '';
      confirmation = '';
      passwordVisible = false;
      confirmationVisible = false;
      if (stage == 0) _timer?.cancel();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    resendSeconds = 48;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isDisposed) {
        timer.cancel();
        return;
      }
      runInAction(() {
        if (resendSeconds > 0) resendSeconds--;
        if (resendSeconds == 0) timer.cancel();
      });
    });
  }

  @action
  Future<bool> submit() async {
    if (isDisposed || status == LoadStatus.loading) return false;
    submitted = true;
    if (!canContinue) {
      error = switch (stage) {
        0 => Validation.email(email),
        1 => 'Enter the 6-digit verification code',
        _ => Validation.password(password) ?? 'Passwords do not match',
      };
      return false;
    }
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await switch (stage) {
      0 => _repository.requestRecovery(email),
      1 => _repository.verifyRecovery(code),
      _ => _repository.resetPassword(password),
    };
    if (!isCurrent(request)) return false;
    return runInAction(() {
      if (result case Failure(:final error)) {
        status = LoadStatus.error;
        this.error = error.message;
        codeRejected = stage == 1 && error.kind == FailureKind.validation;
        passwordRejected = stage == 2 && error.kind == FailureKind.validation;
        return false;
      }
      status = LoadStatus.success;
      if (stage == 0) _startCountdown();
      if (stage == 1) _timer?.cancel();
      if (stage < 2) {
        stage++;
        submitted = false;
        return false;
      }
      password = '';
      confirmation = '';
      return true;
    });
  }

  @action
  Future<void> resend() async {
    if (isDisposed || resendSeconds > 0 || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    final request = beginRequest();
    final result = await _repository.requestRecovery(email);
    if (!isCurrent(request)) return;
    runInAction(() {
      if (result case Failure(:final error)) {
        status = LoadStatus.error;
        this.error = error.message;
      } else {
        status = LoadStatus.success;
        error = null;
        codeRejected = false;
        code = '';
        _startCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    code = '';
    password = '';
    confirmation = '';
    passwordVisible = false;
    confirmationVisible = false;
    super.dispose();
  }
}
