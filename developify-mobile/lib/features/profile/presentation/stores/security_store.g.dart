// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SecurityStore on SecurityStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'SecurityStoreBase.status',
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

  late final _$passwordAtom = Atom(
    name: 'SecurityStoreBase.password',
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

  late final _$newPasswordAtom = Atom(
    name: 'SecurityStoreBase.newPassword',
    context: context,
  );

  @override
  String get newPassword {
    _$newPasswordAtom.reportRead();
    return super.newPassword;
  }

  @override
  set newPassword(String value) {
    _$newPasswordAtom.reportWrite(value, super.newPassword, () {
      super.newPassword = value;
    });
  }

  late final _$confirmationAtom = Atom(
    name: 'SecurityStoreBase.confirmation',
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

  late final _$pinAtom = Atom(name: 'SecurityStoreBase.pin', context: context);

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

  late final _$codeAtom = Atom(
    name: 'SecurityStoreBase.code',
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

  late final _$phoneAtom = Atom(
    name: 'SecurityStoreBase.phone',
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

  late final _$visibleAtom = Atom(
    name: 'SecurityStoreBase.visible',
    context: context,
  );

  @override
  bool get visible {
    _$visibleAtom.reportRead();
    return super.visible;
  }

  @override
  set visible(bool value) {
    _$visibleAtom.reportWrite(value, super.visible, () {
      super.visible = value;
    });
  }

  late final _$stageAtom = Atom(
    name: 'SecurityStoreBase.stage',
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

  late final _$previousDevicesAtom = Atom(
    name: 'SecurityStoreBase.previousDevices',
    context: context,
  );

  @override
  List<String> get previousDevices {
    _$previousDevicesAtom.reportRead();
    return super.previousDevices;
  }

  @override
  set previousDevices(List<String> value) {
    _$previousDevicesAtom.reportWrite(value, super.previousDevices, () {
      super.previousDevices = value;
    });
  }

  late final _$expandedDevicesAtom = Atom(
    name: 'SecurityStoreBase.expandedDevices',
    context: context,
  );

  @override
  Set<String> get expandedDevices {
    _$expandedDevicesAtom.reportRead();
    return super.expandedDevices;
  }

  @override
  set expandedDevices(Set<String> value) {
    _$expandedDevicesAtom.reportWrite(value, super.expandedDevices, () {
      super.expandedDevices = value;
    });
  }

  late final _$twoFactorEnabledAtom = Atom(
    name: 'SecurityStoreBase.twoFactorEnabled',
    context: context,
  );

  @override
  bool get twoFactorEnabled {
    _$twoFactorEnabledAtom.reportRead();
    return super.twoFactorEnabled;
  }

  @override
  set twoFactorEnabled(bool value) {
    _$twoFactorEnabledAtom.reportWrite(value, super.twoFactorEnabled, () {
      super.twoFactorEnabled = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'SecurityStoreBase.error',
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
    name: 'SecurityStoreBase.codeRejected',
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

  late final _$biometricsAtom = Atom(
    name: 'SecurityStoreBase.biometrics',
    context: context,
  );

  @override
  Map<String, bool> get biometrics {
    _$biometricsAtom.reportRead();
    return super.biometrics;
  }

  @override
  set biometrics(Map<String, bool> value) {
    _$biometricsAtom.reportWrite(value, super.biometrics, () {
      super.biometrics = value;
    });
  }

  late final _$performAsyncAction = AsyncAction(
    'SecurityStoreBase.perform',
    context: context,
  );

  @override
  Future<bool> perform(String action) {
    return _$performAsyncAction.run(() => super.perform(action));
  }

  late final _$SecurityStoreBaseActionController = ActionController(
    name: 'SecurityStoreBase',
    context: context,
  );

  @override
  void setPassword(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNewPassword(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setNewPassword',
    );
    try {
      return super.setNewPassword(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConfirmation(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setConfirmation',
    );
    try {
      return super.setConfirmation(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPin(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setPin',
    );
    try {
      return super.setPin(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCode(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setCode',
    );
    try {
      return super.setCode(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPhone(String value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.setPhone',
    );
    try {
      return super.setPhone(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleVisible() {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.toggleVisible',
    );
    try {
      return super.toggleVisible();
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleDevice(String id) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.toggleDevice',
    );
    try {
      return super.toggleDevice(id);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeDevice(String id) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.removeDevice',
    );
    try {
      return super.removeDevice(id);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void enableTwoFactor(bool value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.enableTwoFactor',
    );
    try {
      return super.enableTwoFactor(value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void nextStage() {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.nextStage',
    );
    try {
      return super.nextStage();
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void previousStage() {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.previousStage',
    );
    try {
      return super.previousStage();
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleBiometric(String key, bool value) {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.toggleBiometric',
    );
    try {
      return super.toggleBiometric(key, value);
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void refreshPreferences() {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.refreshPreferences',
    );
    try {
      return super.refreshPreferences();
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearSensitive() {
    final _$actionInfo = _$SecurityStoreBaseActionController.startAction(
      name: 'SecurityStoreBase.clearSensitive',
    );
    try {
      return super.clearSensitive();
    } finally {
      _$SecurityStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
password: ${password},
newPassword: ${newPassword},
confirmation: ${confirmation},
pin: ${pin},
code: ${code},
phone: ${phone},
visible: ${visible},
stage: ${stage},
previousDevices: ${previousDevices},
expandedDevices: ${expandedDevices},
twoFactorEnabled: ${twoFactorEnabled},
error: ${error},
codeRejected: ${codeRejected},
biometrics: ${biometrics}
    ''';
  }
}
