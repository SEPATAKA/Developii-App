import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
part 'security_store.g.dart';

class SecurityStore = SecurityStoreBase with _$SecurityStore;

abstract class SecurityStoreBase with Store, Lifecycle {
  SecurityStoreBase(this._repository) {
    biometrics = _repository.securityPreferences.biometrics;
    previousDevices = _repository.securityPreferences.previousDevices;
    expandedDevices = previousDevices.toSet();
    twoFactorEnabled = _repository.securityPreferences.twoFactorEnabled;
    _preferencesSubscription = _repository.securityChanges.listen(
      (_) => refreshPreferences(),
    );
  }
  final ProfileRepository _repository;
  late final StreamSubscription<SecurityPreferences> _preferencesSubscription;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  String password = '';
  @observable
  String newPassword = '';
  @observable
  String confirmation = '';
  @observable
  String pin = '';
  @observable
  String code = '';
  @observable
  String phone = '';
  @observable
  bool visible = false;
  @observable
  int stage = 0;
  @observable
  List<String> previousDevices = const ['previous-1', 'previous-2'];
  @observable
  Set<String> expandedDevices = const {};
  @observable
  bool twoFactorEnabled = false;
  @observable
  String? error;
  @observable
  bool codeRejected = false;
  @observable
  Map<String, bool> biometrics = const {
    'Use for login': false,
    'Use for investment': false,
    'Use for withdrawals': false,
  };

  @action
  void setPassword(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    password = value;
    error = null;
  }

  @action
  void setNewPassword(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    newPassword = value;
    error = null;
  }

  @action
  void setConfirmation(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    confirmation = value;
    error = null;
  }

  @action
  void setPin(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    pin = value;
    error = null;
  }

  @action
  void setCode(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    code = value;
    codeRejected = false;
    error = null;
  }

  @action
  void setPhone(String value) {
    if (isDisposed || status == LoadStatus.loading) return;
    phone = value;
    error = null;
  }

  @action
  void toggleVisible() => visible = !visible;
  @action
  void toggleDevice(String id) => expandedDevices = expandedDevices.contains(id)
      ? (Set.of(expandedDevices)..remove(id))
      : {...expandedDevices, id};
  @action
  void removeDevice(String id) {
    if (isDisposed || !previousDevices.contains(id)) return;
    previousDevices = previousDevices.where((value) => value != id).toList();
    _savePreferences();
  }

  @action
  void enableTwoFactor(bool value) {
    if (isDisposed) return;
    twoFactorEnabled = value;
    _savePreferences();
  }

  @action
  void nextStage() {
    if (isDisposed || status == LoadStatus.loading) return;
    stage++;
    code = '';
    codeRejected = false;
    error = null;
  }

  @action
  void previousStage() {
    if (isDisposed || status == LoadStatus.loading) return;
    if (stage > 0) stage--;
    code = '';
    codeRejected = false;
    error = null;
  }

  @action
  void toggleBiometric(String key, bool value) {
    if (isDisposed || !biometrics.containsKey(key)) return;
    biometrics = Map.of(biometrics)..[key] = value;
    _savePreferences();
  }

  @action
  void refreshPreferences() {
    if (isDisposed) return;
    final preferences = _repository.securityPreferences;
    biometrics = preferences.biometrics;
    previousDevices = preferences.previousDevices;
    twoFactorEnabled = preferences.twoFactorEnabled;
    expandedDevices = expandedDevices
        .where((id) => id == 'current' || previousDevices.contains(id))
        .toSet();
  }

  @action
  void clearSensitive() {
    password = '';
    newPassword = '';
    confirmation = '';
    pin = '';
    code = '';
    phone = '';
    visible = false;
  }

  @override
  void dispose() {
    unawaited(_preferencesSubscription.cancel());
    clearSensitive();
    super.dispose();
  }

  void _savePreferences() => _repository.saveSecurityPreferences(
    SecurityPreferences(
      biometrics: Map.unmodifiable(biometrics),
      twoFactorEnabled: twoFactorEnabled,
      previousDevices: List.unmodifiable(previousDevices),
    ),
  );

  @action
  Future<bool> perform(String action) async {
    if (isDisposed || status == LoadStatus.loading) return false;
    error = switch (action) {
      'verify-password' => Validation.password(password),
      'change-password' =>
        Validation.password(password) ??
            Validation.password(newPassword) ??
            (newPassword != confirmation ? 'Passwords do not match' : null),
      'change-pin' =>
        RegExp(r'^\d{4}$').hasMatch(pin) ? null : 'Enter a 4-digit PIN',
      'send-code' =>
        phone.replaceAll(RegExp(r'\D'), '').length >= 7
            ? null
            : 'Enter a valid phone number',
      'verify-code' =>
        code == '123456'
            ? null
            : 'Incorrect verification code. Please try again.',
      'link-authenticator' =>
        RegExp(r'^\d{6}$').hasMatch(code.replaceAll(' ', ''))
            ? null
            : 'Enter a 6-digit code',
      _ => null,
    };
    codeRejected = action == 'verify-code' && error != null;
    if (error != null) return false;
    status = LoadStatus.loading;
    final request = beginRequest();
    final result = await _repository.updateSecurity(
      action,
      pin: action == 'change-pin' ? pin : null,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      if (result case Failure(:final error)) {
        status = LoadStatus.error;
        this.error = error.message;
        return false;
      }
      status = LoadStatus.success;
      if (action == 'verify-code') enableTwoFactor(true);
      if (action == 'change-password') {
        previousDevices = const [];
        expandedDevices = expandedDevices.intersection({'current'});
        _savePreferences();
      }
      return true;
    });
  }

  bool canPerform(String action) =>
      !isDisposed &&
      status != LoadStatus.loading &&
      switch (action) {
        'verify-password' => Validation.password(password) == null,
        'change-password' =>
          Validation.password(password) == null &&
              Validation.password(newPassword) == null &&
              newPassword == confirmation,
        'change-pin' => RegExp(r'^\d{4}$').hasMatch(pin),
        'send-code' => phone.replaceAll(RegExp(r'\D'), '').length >= 7,
        'verify-code' => RegExp(r'^\d{6}$').hasMatch(code),
        'link-authenticator' => RegExp(
          r'^\d{6}$',
        ).hasMatch(code.replaceAll(' ', '')),
        _ => false,
      };
}
