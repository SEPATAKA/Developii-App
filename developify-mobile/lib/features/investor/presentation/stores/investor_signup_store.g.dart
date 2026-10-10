// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_signup_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestorSignupStore on InvestorSignupStoreBase, Store {
  Computed<int>? _$stepNumberComputed;

  @override
  int get stepNumber => (_$stepNumberComputed ??= Computed<int>(
    () => super.stepNumber,
    name: 'InvestorSignupStoreBase.stepNumber',
  )).value;
  Computed<bool>? _$detailsFilledComputed;

  @override
  bool get detailsFilled => (_$detailsFilledComputed ??= Computed<bool>(
    () => super.detailsFilled,
    name: 'InvestorSignupStoreBase.detailsFilled',
  )).value;
  Computed<int>? _$passwordStrengthComputed;

  @override
  int get passwordStrength => (_$passwordStrengthComputed ??= Computed<int>(
    () => super.passwordStrength,
    name: 'InvestorSignupStoreBase.passwordStrength',
  )).value;

  late final _$entityAtom = Atom(
    name: 'InvestorSignupStoreBase.entity',
    context: context,
  );

  @override
  EntityType get entity {
    _$entityAtom.reportRead();
    return super.entity;
  }

  @override
  set entity(EntityType value) {
    _$entityAtom.reportWrite(value, super.entity, () {
      super.entity = value;
    });
  }

  late final _$stageAtom = Atom(
    name: 'InvestorSignupStoreBase.stage',
    context: context,
  );

  @override
  InvestorSignupStage get stage {
    _$stageAtom.reportRead();
    return super.stage;
  }

  @override
  set stage(InvestorSignupStage value) {
    _$stageAtom.reportWrite(value, super.stage, () {
      super.stage = value;
    });
  }

  late final _$valuesAtom = Atom(
    name: 'InvestorSignupStoreBase.values',
    context: context,
  );

  @override
  Map<String, String> get values {
    _$valuesAtom.reportRead();
    return super.values;
  }

  @override
  set values(Map<String, String> value) {
    _$valuesAtom.reportWrite(value, super.values, () {
      super.values = value;
    });
  }

  late final _$errorsAtom = Atom(
    name: 'InvestorSignupStoreBase.errors',
    context: context,
  );

  @override
  Map<String, String> get errors {
    _$errorsAtom.reportRead();
    return super.errors;
  }

  @override
  set errors(Map<String, String> value) {
    _$errorsAtom.reportWrite(value, super.errors, () {
      super.errors = value;
    });
  }

  late final _$representativesAtom = Atom(
    name: 'InvestorSignupStoreBase.representatives',
    context: context,
  );

  @override
  List<InvestorRepresentative> get representatives {
    _$representativesAtom.reportRead();
    return super.representatives;
  }

  @override
  set representatives(List<InvestorRepresentative> value) {
    _$representativesAtom.reportWrite(value, super.representatives, () {
      super.representatives = value;
    });
  }

  late final _$dialCodeAtom = Atom(
    name: 'InvestorSignupStoreBase.dialCode',
    context: context,
  );

  @override
  String get dialCode {
    _$dialCodeAtom.reportRead();
    return super.dialCode;
  }

  @override
  set dialCode(String value) {
    _$dialCodeAtom.reportWrite(value, super.dialCode, () {
      super.dialCode = value;
    });
  }

  late final _$countryCodeAtom = Atom(
    name: 'InvestorSignupStoreBase.countryCode',
    context: context,
  );

  @override
  String get countryCode {
    _$countryCodeAtom.reportRead();
    return super.countryCode;
  }

  @override
  set countryCode(String value) {
    _$countryCodeAtom.reportWrite(value, super.countryCode, () {
      super.countryCode = value;
    });
  }

  late final _$codeAtom = Atom(
    name: 'InvestorSignupStoreBase.code',
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

  late final _$codeRejectedAtom = Atom(
    name: 'InvestorSignupStoreBase.codeRejected',
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

  late final _$pinAtom = Atom(
    name: 'InvestorSignupStoreBase.pin',
    context: context,
  );

  @override
  String get pin {
    _$pinAtom.reportRead();
    return super.pin;
  }

  @override
  set pin(String value) {
    _$pinAtom.reportWrite(value, super.pin, () {
      super.pin = value;
    });
  }

  late final _$passwordVisibleAtom = Atom(
    name: 'InvestorSignupStoreBase.passwordVisible',
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
    name: 'InvestorSignupStoreBase.confirmationVisible',
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

  late final _$nonResidentAtom = Atom(
    name: 'InvestorSignupStoreBase.nonResident',
    context: context,
  );

  @override
  bool get nonResident {
    _$nonResidentAtom.reportRead();
    return super.nonResident;
  }

  @override
  set nonResident(bool value) {
    _$nonResidentAtom.reportWrite(value, super.nonResident, () {
      super.nonResident = value;
    });
  }

  late final _$busyAtom = Atom(
    name: 'InvestorSignupStoreBase.busy',
    context: context,
  );

  @override
  bool get busy {
    _$busyAtom.reportRead();
    return super.busy;
  }

  @override
  set busy(bool value) {
    _$busyAtom.reportWrite(value, super.busy, () {
      super.busy = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'InvestorSignupStoreBase.error',
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

  late final _$resendSecondsAtom = Atom(
    name: 'InvestorSignupStoreBase.resendSeconds',
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

  late final _$faceProgressAtom = Atom(
    name: 'InvestorSignupStoreBase.faceProgress',
    context: context,
  );

  @override
  int get faceProgress {
    _$faceProgressAtom.reportRead();
    return super.faceProgress;
  }

  @override
  set faceProgress(int value) {
    _$faceProgressAtom.reportWrite(value, super.faceProgress, () {
      super.faceProgress = value;
    });
  }

  late final _$createProfileAsyncAction = AsyncAction(
    'InvestorSignupStoreBase.createProfile',
    context: context,
  );

  @override
  Future<bool> createProfile() {
    return _$createProfileAsyncAction.run(() => super.createProfile());
  }

  late final _$verifyAsyncAction = AsyncAction(
    'InvestorSignupStoreBase.verify',
    context: context,
  );

  @override
  Future<bool> verify() {
    return _$verifyAsyncAction.run(() => super.verify());
  }

  late final _$finishAsyncAction = AsyncAction(
    'InvestorSignupStoreBase.finish',
    context: context,
  );

  @override
  Future<bool> finish() {
    return _$finishAsyncAction.run(() => super.finish());
  }

  late final _$InvestorSignupStoreBaseActionController = ActionController(
    name: 'InvestorSignupStoreBase',
    context: context,
  );

  @override
  void edit(String key, String value) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.edit',
    );
    try {
      return super.edit(key, value);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCountry(String code, String prefix) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.setCountry',
    );
    try {
      return super.setCountry(code, prefix);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCode(String value) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.setCode',
    );
    try {
      return super.setCode(value);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPin(String value) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.setPin',
    );
    try {
      return super.setPin(value);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void togglePassword() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.togglePassword',
    );
    try {
      return super.togglePassword();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConfirmation() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.toggleConfirmation',
    );
    try {
      return super.toggleConfirmation();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addRepresentative() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.addRepresentative',
    );
    try {
      return super.addRepresentative();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateRepresentative(int index, {String? name, String? identityNumber}) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.updateRepresentative',
    );
    try {
      return super.updateRepresentative(
        index,
        name: name,
        identityNumber: identityNumber,
      );
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeRepresentative(int index) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.removeRepresentative',
    );
    try {
      return super.removeRepresentative(index);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resend() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.resend',
    );
    try {
      return super.resend();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void continueVerified() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.continueVerified',
    );
    try {
      return super.continueVerified();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool continuePin() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.continuePin',
    );
    try {
      return super.continuePin();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginFingerprint() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.beginFingerprint',
    );
    try {
      return super.beginFingerprint();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void continueBiometrics() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.continueBiometrics',
    );
    try {
      return super.continueBiometrics();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginFace() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.beginFace',
    );
    try {
      return super.beginFace();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void captureFace({bool reduceMotion = false}) {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.captureFace',
    );
    try {
      return super.captureFace(reduceMotion: reduceMotion);
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void completeSecurity() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.completeSecurity',
    );
    try {
      return super.completeSecurity();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void back() {
    final _$actionInfo = _$InvestorSignupStoreBaseActionController.startAction(
      name: 'InvestorSignupStoreBase.back',
    );
    try {
      return super.back();
    } finally {
      _$InvestorSignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
entity: ${entity},
stage: ${stage},
values: ${values},
errors: ${errors},
representatives: ${representatives},
dialCode: ${dialCode},
countryCode: ${countryCode},
code: ${code},
codeRejected: ${codeRejected},
pin: ${pin},
passwordVisible: ${passwordVisible},
confirmationVisible: ${confirmationVisible},
nonResident: ${nonResident},
busy: ${busy},
error: ${error},
resendSeconds: ${resendSeconds},
faceProgress: ${faceProgress},
stepNumber: ${stepNumber},
detailsFilled: ${detailsFilled},
passwordStrength: ${passwordStrength}
    ''';
  }
}
