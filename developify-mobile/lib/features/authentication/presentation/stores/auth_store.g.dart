// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AuthStore on AuthStoreBase, Store {
  Computed<String?>? _$emailErrorComputed;

  @override
  String? get emailError => (_$emailErrorComputed ??= Computed<String?>(
    () => super.emailError,
    name: 'AuthStoreBase.emailError',
  )).value;
  Computed<String?>? _$passwordErrorComputed;

  @override
  String? get passwordError => (_$passwordErrorComputed ??= Computed<String?>(
    () => super.passwordError,
    name: 'AuthStoreBase.passwordError',
  )).value;
  Computed<bool>? _$canSubmitComputed;

  @override
  bool get canSubmit => (_$canSubmitComputed ??= Computed<bool>(
    () => super.canSubmit,
    name: 'AuthStoreBase.canSubmit',
  )).value;

  late final _$emailAtom = Atom(name: 'AuthStoreBase.email', context: context);

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

  late final _$passwordAtom = Atom(
    name: 'AuthStoreBase.password',
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

  late final _$passwordVisibleAtom = Atom(
    name: 'AuthStoreBase.passwordVisible',
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

  late final _$submittedAtom = Atom(
    name: 'AuthStoreBase.submitted',
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
    name: 'AuthStoreBase.status',
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

  late final _$errorAtom = Atom(name: 'AuthStoreBase.error', context: context);

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

  late final _$signInAsyncAction = AsyncAction(
    'AuthStoreBase.signIn',
    context: context,
  );

  @override
  Future<bool> signIn({String? socialProvider}) {
    return _$signInAsyncAction.run(
      () => super.signIn(socialProvider: socialProvider),
    );
  }

  late final _$AuthStoreBaseActionController = ActionController(
    name: 'AuthStoreBase',
    context: context,
  );

  @override
  void prepareReturning() {
    final _$actionInfo = _$AuthStoreBaseActionController.startAction(
      name: 'AuthStoreBase.prepareReturning',
    );
    try {
      return super.prepareReturning();
    } finally {
      _$AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEmail(String value) {
    final _$actionInfo = _$AuthStoreBaseActionController.startAction(
      name: 'AuthStoreBase.setEmail',
    );
    try {
      return super.setEmail(value);
    } finally {
      _$AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPassword(String value) {
    final _$actionInfo = _$AuthStoreBaseActionController.startAction(
      name: 'AuthStoreBase.setPassword',
    );
    try {
      return super.setPassword(value);
    } finally {
      _$AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleVisibility() {
    final _$actionInfo = _$AuthStoreBaseActionController.startAction(
      name: 'AuthStoreBase.toggleVisibility',
    );
    try {
      return super.toggleVisibility();
    } finally {
      _$AuthStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
email: ${email},
password: ${password},
passwordVisible: ${passwordVisible},
submitted: ${submitted},
status: ${status},
error: ${error},
emailError: ${emailError},
passwordError: ${passwordError},
canSubmit: ${canSubmit}
    ''';
  }
}
