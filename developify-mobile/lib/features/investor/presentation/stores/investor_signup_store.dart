import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/core/services/transaction_authorization.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/authentication/domain/auth_repository.dart';
import 'package:developify_mobile/features/authentication/domain/investor_registration.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'investor_signup_store.g.dart';

enum InvestorSignupStage {
  details,
  verification,
  verified,
  pin,
  biometrics,
  fingerprint,
  face,
  faceCamera,
  faceProcessing,
  faceComplete,
  complete,
}

class InvestorSignupStore = InvestorSignupStoreBase with _$InvestorSignupStore;

abstract class InvestorSignupStoreBase with Store, Lifecycle {
  InvestorSignupStoreBase(
    this._repository,
    this._session,
    this._authorization, {
    this.entity = EntityType.individual,
  }) {
    if (entity == EntityType.company) {
      representatives = const [
        InvestorRepresentative(name: '', identityNumber: ''),
      ];
    }
  }
  final AuthRepository _repository;
  final SessionService _session;
  final TransactionAuthorization _authorization;
  final Cancellation _cancellation = Cancellation();
  Timer? _resendTimer;
  Timer? _faceTimer;
  String? _challenge;
  @observable
  EntityType entity;
  @observable
  InvestorSignupStage stage = InvestorSignupStage.details;
  @observable
  Map<String, String> values = const {};
  @observable
  Map<String, String> errors = const {};
  @observable
  List<InvestorRepresentative> representatives = const [];
  @observable
  String dialCode = '+1';
  @observable
  String countryCode = 'US';
  @observable
  String code = '';
  @observable
  bool codeRejected = false;
  @observable
  String pin = '';
  @observable
  bool passwordVisible = false;
  @observable
  bool confirmationVisible = false;
  @observable
  bool nonResident = false;
  @observable
  bool busy = false;
  @observable
  String? error;
  @observable
  int resendSeconds = 0;
  @observable
  int faceProgress = 0;
  @computed
  int get stepNumber => switch (stage) {
    InvestorSignupStage.details => 1,
    InvestorSignupStage.verification || InvestorSignupStage.verified => 2,
    InvestorSignupStage.pin => 3,
    InvestorSignupStage.biometrics || InvestorSignupStage.fingerprint => 4,
    _ => 5,
  };
  @computed
  bool get detailsFilled => [
    'name',
    'email',
    'phone',
    'password',
    'confirmation',
    if (entity == EntityType.company) 'registration',
  ].every((key) => (values[key] ?? '').trim().isNotEmpty);
  @computed
  int get passwordStrength => [
    (values['password'] ?? '').length >= 8,
    RegExp('[a-z]').hasMatch(values['password'] ?? ''),
    RegExp('[A-Z]').hasMatch(values['password'] ?? ''),
    RegExp('[0-9]').hasMatch(values['password'] ?? ''),
    RegExp(r'[^a-zA-Z0-9]').hasMatch(values['password'] ?? ''),
  ].where((valid) => valid).length;
  @action
  void edit(String key, String value) {
    if (isDisposed || busy || stage != InvestorSignupStage.details) return;
    values = {...values, key: value};
    errors = {...errors}..remove(key);
    error = null;
  }

  @action
  void setCountry(String code, String prefix) {
    if (isDisposed || busy || stage != InvestorSignupStage.details) return;
    countryCode = code;
    dialCode = prefix;
  }

  @action
  void setCode(String value) {
    if (isDisposed || busy || stage != InvestorSignupStage.verification) return;
    code = value;
    codeRejected = false;
    error = null;
  }

  @action
  void setPin(String value) {
    if (isDisposed || busy || stage != InvestorSignupStage.pin) return;
    pin = value;
    error = null;
  }

  @action
  void togglePassword() {
    if (!isDisposed && !busy) passwordVisible = !passwordVisible;
  }

  @action
  void toggleConfirmation() {
    if (!isDisposed && !busy) confirmationVisible = !confirmationVisible;
  }

  @action
  void addRepresentative() {
    if (isDisposed ||
        busy ||
        stage != InvestorSignupStage.details ||
        entity != EntityType.company) {
      return;
    }
    if (representatives.length < 20) {
      representatives = [
        ...representatives,
        const InvestorRepresentative(name: '', identityNumber: ''),
      ];
    }
  }

  @action
  void updateRepresentative(int index, {String? name, String? identityNumber}) {
    if (isDisposed || busy || stage != InvestorSignupStage.details) return;
    if (index < 0 || index >= representatives.length) return;
    representatives = [
      for (var i = 0; i < representatives.length; i++)
        if (i == index)
          InvestorRepresentative(
            name: name ?? representatives[i].name,
            identityNumber: identityNumber ?? representatives[i].identityNumber,
          )
        else
          representatives[i],
    ];
  }

  @action
  void removeRepresentative(int index) {
    if (isDisposed ||
        busy ||
        stage != InvestorSignupStage.details ||
        index < 0 ||
        index >= representatives.length) {
      return;
    }
    representatives = representatives.length == 1
        ? const [InvestorRepresentative(name: '', identityNumber: '')]
        : ([...representatives]..removeAt(index));
  }

  @action
  Future<bool> createProfile() async {
    if (busy || isDisposed || stage != InvestorSignupStage.details) {
      return false;
    }
    final checks = {
      'name': Validation.required(values['name'] ?? '', 'your full name'),
      'email': Validation.email(values['email'] ?? ''),
      'phone': (values['phone'] ?? '').replaceAll(RegExp(r'\D'), '').length < 7
          ? 'Enter a valid phone number'
          : null,
      'password': Validation.password(values['password'] ?? ''),
      'confirmation': values['password'] != values['confirmation']
          ? 'Passwords do not match'
          : null,
      if (entity == EntityType.company)
        'registration': Validation.required(
          values['registration'] ?? '',
          'registration number',
        ),
      if (entity == EntityType.company)
        'representatives':
            representatives.isEmpty ||
                representatives.any(
                  (representative) =>
                      representative.name.trim().isEmpty ||
                      representative.identityNumber.trim().isEmpty,
                )
            ? 'Enter a name and ID for each representative.'
            : null,
    };
    errors = {
      for (final entry in checks.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    if (errors.isNotEmpty) return false;
    final request = beginRequest();
    busy = true;
    error = null;
    if (_challenge != null) _repository.cancelInvestorRegistration(_challenge!);
    final result = await _repository.beginInvestorRegistration(
      InvestorRegistration(
        name: values['name']!,
        email: values['email']!,
        phone: '$dialCode ${values['phone']}',
        password: values['password']!,
        entity: entity,
        registrationNumber: values['registration'] ?? '',
        representatives: representatives,
        nonResident: nonResident,
        countryCode: countryCode,
      ),
      cancellation: _cancellation,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      _challenge = (result as Success<String>).value;
      stage = InvestorSignupStage.verification;
      code = '';
      codeRejected = false;
      _countdown();
      return true;
    });
  }

  void _countdown() {
    _resendTimer?.cancel();
    resendSeconds = 48;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
  void resend() {
    if (!isDisposed &&
        !busy &&
        resendSeconds == 0 &&
        stage == InvestorSignupStage.verification) {
      code = '';
      error = null;
      codeRejected = false;
      _countdown();
    }
  }

  @action
  Future<bool> verify() async {
    if (busy ||
        isDisposed ||
        codeRejected ||
        _challenge == null ||
        stage != InvestorSignupStage.verification) {
      return false;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      error = 'Enter the six-digit verification code.';
      return false;
    }
    final request = beginRequest();
    busy = true;
    error = null;
    final result = await _repository.verifyInvestorRegistration(
      _challenge!,
      code,
      cancellation: _cancellation,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        codeRejected = error.kind == FailureKind.validation;
        return false;
      }
      _resendTimer?.cancel();
      stage = InvestorSignupStage.verified;
      codeRejected = false;
      return true;
    });
  }

  @action
  void continueVerified() {
    if (!isDisposed && !busy && stage == InvestorSignupStage.verified) {
      code = '';
      stage = InvestorSignupStage.pin;
    }
  }

  @action
  bool continuePin() {
    if (isDisposed || busy || stage != InvestorSignupStage.pin) return false;
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      error = 'Enter a four-digit PIN.';
      return false;
    }
    error = null;
    stage = InvestorSignupStage.biometrics;
    return true;
  }

  @action
  void beginFingerprint() {
    if (!isDisposed && !busy && stage == InvestorSignupStage.biometrics) {
      stage = InvestorSignupStage.fingerprint;
    }
  }

  @action
  void continueBiometrics() {
    if (!isDisposed &&
        !busy &&
        (stage == InvestorSignupStage.biometrics ||
            stage == InvestorSignupStage.fingerprint)) {
      stage = InvestorSignupStage.face;
    }
  }

  @action
  void beginFace() {
    if (isDisposed || busy || stage != InvestorSignupStage.face) return;
    stage = InvestorSignupStage.faceCamera;
  }

  @action
  void captureFace({bool reduceMotion = false}) {
    if (isDisposed || busy || stage != InvestorSignupStage.faceCamera) return;
    if (reduceMotion) {
      faceProgress = 100;
      stage = InvestorSignupStage.faceComplete;
      return;
    }
    stage = InvestorSignupStage.faceProcessing;
    faceProgress = 5;
    _faceTimer?.cancel();
    _faceTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (isDisposed) {
        timer.cancel();
        return;
      }
      runInAction(() {
        faceProgress = (faceProgress + 5).clamp(0, 100);
        if (faceProgress == 100) {
          timer.cancel();
          stage = InvestorSignupStage.faceComplete;
        }
      });
    });
  }

  @action
  void completeSecurity() {
    if (isDisposed ||
        busy ||
        (stage != InvestorSignupStage.face &&
            stage != InvestorSignupStage.faceComplete)) {
      return;
    }
    stage = InvestorSignupStage.complete;
  }

  @action
  void back() {
    if (isDisposed || busy) return;
    error = null;
    codeRejected = false;
    stage = switch (stage) {
      InvestorSignupStage.details => InvestorSignupStage.details,
      InvestorSignupStage.verification ||
      InvestorSignupStage.verified => InvestorSignupStage.details,
      InvestorSignupStage.pin => InvestorSignupStage.verified,
      InvestorSignupStage.biometrics => InvestorSignupStage.pin,
      InvestorSignupStage.fingerprint => InvestorSignupStage.biometrics,
      InvestorSignupStage.face => InvestorSignupStage.biometrics,
      InvestorSignupStage.faceCamera => InvestorSignupStage.face,
      InvestorSignupStage.faceProcessing => InvestorSignupStage.faceCamera,
      InvestorSignupStage.faceComplete ||
      InvestorSignupStage.complete => InvestorSignupStage.face,
    };
    _faceTimer?.cancel();
    if (stage == InvestorSignupStage.details) {
      _resendTimer?.cancel();
      code = '';
      pin = '';
    }
  }

  @action
  Future<bool> finish() async {
    if (busy ||
        isDisposed ||
        stage != InvestorSignupStage.complete ||
        _challenge == null ||
        !RegExp(r'^\d{4}$').hasMatch(pin)) {
      return false;
    }
    final request = beginRequest();
    busy = true;
    error = null;
    final result = await _repository.completeInvestorRegistration(
      _challenge!,
      cancellation: _cancellation,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      _session.signIn(
        (result as Success<AppUser>).value,
        experience: Experience.investor,
      );
      _authorization.setPin(pin);
      pin = '';
      code = '';
      codeRejected = false;
      values = const {};
      _challenge = null;
      return true;
    });
  }

  @override
  void dispose() {
    _cancellation.cancel();
    _resendTimer?.cancel();
    _faceTimer?.cancel();
    if (_challenge != null) _repository.cancelInvestorRegistration(_challenge!);
    values = const {};
    representatives = const [];
    passwordVisible = false;
    confirmationVisible = false;
    pin = '';
    code = '';
    codeRejected = false;
    super.dispose();
  }
}
