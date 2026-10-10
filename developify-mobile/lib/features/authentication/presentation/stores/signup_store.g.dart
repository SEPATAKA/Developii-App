// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SignupStore on SignupStoreBase, Store {
  Computed<bool>? _$detailsFilledComputed;

  @override
  bool get detailsFilled => (_$detailsFilledComputed ??= Computed<bool>(
    () => super.detailsFilled,
    name: 'SignupStoreBase.detailsFilled',
  )).value;
  Computed<bool>? _$canAttemptDetailsComputed;

  @override
  bool get canAttemptDetails => (_$canAttemptDetailsComputed ??= Computed<bool>(
    () => super.canAttemptDetails,
    name: 'SignupStoreBase.canAttemptDetails',
  )).value;
  Computed<SignupAppearance>? _$appearanceComputed;

  @override
  SignupAppearance get appearance =>
      (_$appearanceComputed ??= Computed<SignupAppearance>(
        () => super.appearance,
        name: 'SignupStoreBase.appearance',
      )).value;
  Computed<int>? _$passwordStrengthComputed;

  @override
  int get passwordStrength => (_$passwordStrengthComputed ??= Computed<int>(
    () => super.passwordStrength,
    name: 'SignupStoreBase.passwordStrength',
  )).value;

  late final _$nameAtom = Atom(name: 'SignupStoreBase.name', context: context);

  @override
  String get name {
    _$nameAtom.reportRead();
    return super.name;
  }

  @override
  set name(String value) {
    _$nameAtom.reportWrite(value, super.name, () {
      super.name = value;
    });
  }

  late final _$emailAtom = Atom(
    name: 'SignupStoreBase.email',
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

  late final _$phoneAtom = Atom(
    name: 'SignupStoreBase.phone',
    context: context,
  );

  @override
  String get phone {
    _$phoneAtom.reportRead();
    return super.phone;
  }

  @override
  set phone(String value) {
    _$phoneAtom.reportWrite(value, super.phone, () {
      super.phone = value;
    });
  }

  late final _$countryCodeAtom = Atom(
    name: 'SignupStoreBase.countryCode',
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

  late final _$dialCodeAtom = Atom(
    name: 'SignupStoreBase.dialCode',
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

  late final _$passwordAtom = Atom(
    name: 'SignupStoreBase.password',
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
    name: 'SignupStoreBase.confirmation',
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
    name: 'SignupStoreBase.passwordVisible',
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
    name: 'SignupStoreBase.confirmationVisible',
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

  late final _$acceptedTermsAtom = Atom(
    name: 'SignupStoreBase.acceptedTerms',
    context: context,
  );

  @override
  bool get acceptedTerms {
    _$acceptedTermsAtom.reportRead();
    return super.acceptedTerms;
  }

  @override
  set acceptedTerms(bool value) {
    _$acceptedTermsAtom.reportWrite(value, super.acceptedTerms, () {
      super.acceptedTerms = value;
    });
  }

  late final _$choosingEntityAtom = Atom(
    name: 'SignupStoreBase.choosingEntity',
    context: context,
  );

  @override
  bool get choosingEntity {
    _$choosingEntityAtom.reportRead();
    return super.choosingEntity;
  }

  @override
  set choosingEntity(bool value) {
    _$choosingEntityAtom.reportWrite(value, super.choosingEntity, () {
      super.choosingEntity = value;
    });
  }

  late final _$entityAtom = Atom(
    name: 'SignupStoreBase.entity',
    context: context,
  );

  @override
  EntityType? get entity {
    _$entityAtom.reportRead();
    return super.entity;
  }

  @override
  set entity(EntityType? value) {
    _$entityAtom.reportWrite(value, super.entity, () {
      super.entity = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'SignupStoreBase.status',
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
    name: 'SignupStoreBase.error',
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

  late final _$invalidCredentialsAtom = Atom(
    name: 'SignupStoreBase.invalidCredentials',
    context: context,
  );

  @override
  bool get invalidCredentials {
    _$invalidCredentialsAtom.reportRead();
    return super.invalidCredentials;
  }

  @override
  set invalidCredentials(bool value) {
    _$invalidCredentialsAtom.reportWrite(value, super.invalidCredentials, () {
      super.invalidCredentials = value;
    });
  }

  late final _$createAccountAsyncAction = AsyncAction(
    'SignupStoreBase.createAccount',
    context: context,
  );

  @override
  Future<bool> createAccount() {
    return _$createAccountAsyncAction.run(() => super.createAccount());
  }

  late final _$SignupStoreBaseActionController = ActionController(
    name: 'SignupStoreBase',
    context: context,
  );

  @override
  void setName(String value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setName',
    );
    try {
      return super.setName(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmail(String value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setEmail',
    );
    try {
      return super.setEmail(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPhone(String value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setPhone',
    );
    try {
      return super.setPhone(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCountry(String code, String prefix) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setCountry',
    );
    try {
      return super.setCountry(code, prefix);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConfirmation(String value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.setConfirmation',
    );
    try {
      return super.setConfirmation(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void togglePassword() {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.togglePassword',
    );
    try {
      return super.togglePassword();
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConfirmation() {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.toggleConfirmation',
    );
    try {
      return super.toggleConfirmation();
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void acceptTerms(bool value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.acceptTerms',
    );
    try {
      return super.acceptTerms(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectEntity(EntityType value) {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.selectEntity',
    );
    try {
      return super.selectEntity(value);
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void returnToDetails() {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.returnToDetails',
    );
    try {
      return super.returnToDetails();
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool continueToEntity() {
    final _$actionInfo = _$SignupStoreBaseActionController.startAction(
      name: 'SignupStoreBase.continueToEntity',
    );
    try {
      return super.continueToEntity();
    } finally {
      _$SignupStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
name: ${name},
email: ${email},
phone: ${phone},
countryCode: ${countryCode},
dialCode: ${dialCode},
password: ${password},
confirmation: ${confirmation},
passwordVisible: ${passwordVisible},
confirmationVisible: ${confirmationVisible},
acceptedTerms: ${acceptedTerms},
choosingEntity: ${choosingEntity},
entity: ${entity},
status: ${status},
error: ${error},
invalidCredentials: ${invalidCredentials},
detailsFilled: ${detailsFilled},
canAttemptDetails: ${canAttemptDetails},
appearance: ${appearance},
passwordStrength: ${passwordStrength}
    ''';
  }
}
