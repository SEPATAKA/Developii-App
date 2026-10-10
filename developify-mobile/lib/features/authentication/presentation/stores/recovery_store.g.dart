// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$RecoveryStore on RecoveryStoreBase, Store {
  Computed<String>? _$maskedEmailComputed;

  @override
  String get maskedEmail => (_$maskedEmailComputed ??= Computed<String>(
    () => super.maskedEmail,
    name: 'RecoveryStoreBase.maskedEmail',
  )).value;
  Computed<bool>? _$passwordInvalidComputed;

  @override
  bool get passwordInvalid => (_$passwordInvalidComputed ??= Computed<bool>(
    () => super.passwordInvalid,
    name: 'RecoveryStoreBase.passwordInvalid',
  )).value;
  Computed<int>? _$passwordStrengthComputed;

  @override
  int get passwordStrength => (_$passwordStrengthComputed ??= Computed<int>(
    () => super.passwordStrength,
    name: 'RecoveryStoreBase.passwordStrength',
  )).value;
  Computed<String?>? _$emailErrorComputed;

  @override
  String? get emailError => (_$emailErrorComputed ??= Computed<String?>(
    () => super.emailError,
    name: 'RecoveryStoreBase.emailError',
  )).value;
  Computed<bool>? _$canContinueComputed;

  @override
  bool get canContinue => (_$canContinueComputed ??= Computed<bool>(
    () => super.canContinue,
    name: 'RecoveryStoreBase.canContinue',
  )).value;

  late final _$emailAtom = Atom(
    name: 'RecoveryStoreBase.email',
    context: context,
  );

  @override
  String get email {
    _$emailAtom.reportRead();
    return super.email;
  }

  @override
  set email(String value) {
    _$emailAtom.reportWrite(value, super.email, () {
      super.email = value;
    });
  }

  late final _$codeAtom = Atom(
    name: 'RecoveryStoreBase.code',
    context: context,
  );

  @override
  String get code {
    _$codeAtom.reportRead();
    return super.code;
  }

  @override
  set code(String value) {
    _$codeAtom.reportWrite(value, super.code, () {
      super.code = value;
    });
  }

  late final _$passwordAtom = Atom(
    name: 'RecoveryStoreBase.password',
    context: context,
  );

  @override
  String get password {
    _$passwordAtom.reportRead();
    return super.password;
  }

  @override
  set password(String value) {
    _$passwordAtom.reportWrite(value, super.password, () {
      super.password = value;
    });
  }

  late final _$confirmationAtom = Atom(
    name: 'RecoveryStoreBase.confirmation',
    context: context,
  );

  @override
  String get confirmation {
    _$confirmationAtom.reportRead();
    return super.confirmation;
  }

  @override
  set confirmation(String value) {
    _$confirmationAtom.reportWrite(value, super.confirmation, () {
      super.confirmation = value;
    });
  }

  late final _$passwordVisibleAtom = Atom(
    name: 'RecoveryStoreBase.passwordVisible',
    context: context,
  );

  @override
  bool get passwordVisible {
    _$passwordVisibleAtom.reportRead();
    return super.passwordVisible;
  }

  @override
  set passwordVisible(bool value) {
    _$passwordVisibleAtom.reportWrite(value, super.passwordVisible, () {
      super.passwordVisible = value;
    });
  }

  late final _$confirmationVisibleAtom = Atom(
    name: 'RecoveryStoreBase.confirmationVisible',
    context: context,
  );

  @override
  bool get confirmationVisible {
    _$confirmationVisibleAtom.reportRead();
    return super.confirmationVisible;
  }

  @override
  set confirmationVisible(bool value) {
    _$confirmationVisibleAtom.reportWrite(value, super.confirmationVisible, () {
      super.confirmationVisible = value;
    });
  }

  late final _$stageAtom = Atom(
    name: 'RecoveryStoreBase.stage',
    context: context,
  );

  @override
  int get stage {
    _$stageAtom.reportRead();
    return super.stage;
  }

  @override
  set stage(int value) {
    _$stageAtom.reportWrite(value, super.stage, () {
      super.stage = value;
    });
  }

  late final _$resendSecondsAtom = Atom(
    name: 'RecoveryStoreBase.resendSeconds',
    context: context,
  );

  @override
  int get resendSeconds {
    _$resendSecondsAtom.reportRead();
    return super.resendSeconds;
  }

  @override
  set resendSeconds(int value) {
    _$resendSecondsAtom.reportWrite(value, super.resendSeconds, () {
      super.resendSeconds = value;
    });
  }

  late final _$submittedAtom = Atom(
    name: 'RecoveryStoreBase.submitted',
    context: context,
  );

  @override
  bool get submitted {
    _$submittedAtom.reportRead();
    return super.submitted;
  }

  @override
  set submitted(bool value) {
    _$submittedAtom.reportWrite(value, super.submitted, () {
      super.submitted = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'RecoveryStoreBase.status',
    context: context,
  );

  @override
  LoadStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(LoadStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'RecoveryStoreBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$codeRejectedAtom = Atom(
    name: 'RecoveryStoreBase.codeRejected',
    context: context,
  );

  @override
  bool get codeRejected {
    _$codeRejectedAtom.reportRead();
    return super.codeRejected;
  }

  @override
  set codeRejected(bool value) {
    _$codeRejectedAtom.reportWrite(value, super.codeRejected, () {
      super.codeRejected = value;
    });
  }

  late final _$passwordRejectedAtom = Atom(
    name: 'RecoveryStoreBase.passwordRejected',
    context: context,
  );

  @override
  bool get passwordRejected {
    _$passwordRejectedAtom.reportRead();
    return super.passwordRejected;
  }

  @override
  set passwordRejected(bool value) {
    _$passwordRejectedAtom.reportWrite(value, super.passwordRejected, () {
      super.passwordRejected = value;
    });
  }

  late final _$submitAsyncAction = AsyncAction(
    'RecoveryStoreBase.submit',
    context: context,
  );

  @override
  Future<bool> submit() {
    return _$submitAsyncAction.run(() => super.submit());
  }

  late final _$resendAsyncAction = AsyncAction(
    'RecoveryStoreBase.resend',
    context: context,
  );

  @override
  Future<void> resend() {
    return _$resendAsyncAction.run(() => super.resend());
  }

  late final _$RecoveryStoreBaseActionController = ActionController(
    name: 'RecoveryStoreBase',
    context: context,
  );

  @override
  void setEmail(String value) {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.setEmail',
    );
    try {
      return super.setEmail(value);
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCode(String value) {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.setCode',
    );
    try {
      return super.setCode(value);
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConfirmation(String value) {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.setConfirmation',
    );
    try {
      return super.setConfirmation(value);
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void togglePassword() {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.togglePassword',
    );
    try {
      return super.togglePassword();
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConfirmation() {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.toggleConfirmation',
    );
    try {
      return super.toggleConfirmation();
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void back() {
    final _$actionInfo = _$RecoveryStoreBaseActionController.startAction(
      name: 'RecoveryStoreBase.back',
    );
    try {
      return super.back();
    } finally {
      _$RecoveryStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
email: ${email},
code: ${code},
password: ${password},
confirmation: ${confirmation},
passwordVisible: ${passwordVisible},
confirmationVisible: ${confirmationVisible},
stage: ${stage},
resendSeconds: ${resendSeconds},
submitted: ${submitted},
status: ${status},
error: ${error},
codeRejected: ${codeRejected},
passwordRejected: ${passwordRejected},
maskedEmail: ${maskedEmail},
passwordInvalid: ${passwordInvalid},
passwordStrength: ${passwordStrength},
emailError: ${emailError},
canContinue: ${canContinue}
    ''';
  }
}
