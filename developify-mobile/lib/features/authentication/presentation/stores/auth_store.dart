import 'package:mobx/mobx.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';

part 'auth_store.g.dart';

class AuthStore = AuthStoreBase with _$AuthStore;

abstract class AuthStoreBase with Store, Lifecycle {
  AuthStoreBase(
    this._repository,
    this._session, {
    this.experience = Experience.landowner,
  });

  final Experience experience;
  final AuthRepository _repository;
  final SessionService _session;

  String get returningName {
    final name = _session.returningUser?.name.trim() ?? '';
    if (name.isEmpty) return '';
    return name.split(RegExp(r'\s+')).first;
  }

  @action
  void prepareReturning() {
    email = _session.returningUser?.email ?? '';
  }

  @observable
  String email = '';

  @observable
  String password = '';

  @observable
  bool passwordVisible = false;

  @observable
  bool submitted = false;

  @observable
  LoadStatus status = LoadStatus.initial;

  @observable
  String? error;

  @computed
  String? get emailError => submitted ? Validation.email(email) : null;

  @computed
  String? get passwordError =>
      submitted && password.isEmpty ? 'Enter your password' : null;

  @computed
  bool get canSubmit => Validation.email(email) == null && password.isNotEmpty;

  @action
  void setEmail(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    email = value;
    error = null;
  }

  @action
  void setPassword(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    password = value;
    error = null;
  }

  @action
  void toggleVisibility() {
    if (!isDisposed && status != LoadStatus.loading) {
      passwordVisible = !passwordVisible;
    }
  }

  @action
  Future<bool> signIn({String? socialProvider}) async {
    if (isDisposed || status == LoadStatus.loading) return false;

    submitted = true;

    if (socialProvider == null && !canSubmit) return false;

    status = LoadStatus.loading;
    error = null;

    final request = beginRequest();

    try {
      final result = socialProvider == null
          ? await _repository.signIn(email.trim(), password)
          : await _repository.socialSignIn(socialProvider);

      if (!isCurrent(request) || isDisposed) return false;

      return runInAction(() {
        switch (result) {
          case Success(:final value):
            status = LoadStatus.success;
            password = '';
            _session.signIn(value, experience: experience);
            return true;

          case Failure(:final error):
            status = LoadStatus.error;
            this.error = error.message;
            return false;
        }
      });
    } catch (_) {
      if (!isCurrent(request) || isDisposed) return false;

      return runInAction(() {
        status = LoadStatus.error;
        error = 'Unable to sign in. Check your connection and try again.';
        return false;
      });
    }
  }

  @override
  void dispose() {
    password = '';
    passwordVisible = false;
    super.dispose();
  }
}
