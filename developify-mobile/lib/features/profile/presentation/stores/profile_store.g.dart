// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ProfileStore on ProfileStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'ProfileStoreBase.status',
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

  late final _$userAtom = Atom(name: 'ProfileStoreBase.user', context: context);

  @override
  AppUser? get user {
    _$userAtom.reportRead();
    return super.user;
  }

  @override
  set user(AppUser? value) {
    _$userAtom.reportWrite(value, super.user, () {
      super.user = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'ProfileStoreBase.error',
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

  late final _$errorsAtom = Atom(
    name: 'ProfileStoreBase.errors',
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

  late final _$savingAtom = Atom(
    name: 'ProfileStoreBase.saving',
    context: context,
  );

  @override
  bool get saving {
    _$savingAtom.reportRead();
    return super.saving;
  }

  @override
  set saving(bool value) {
    _$savingAtom.reportWrite(value, super.saving, () {
      super.saving = value;
    });
  }

  late final _$dirtyAtom = Atom(
    name: 'ProfileStoreBase.dirty',
    context: context,
  );

  @override
  bool get dirty {
    _$dirtyAtom.reportRead();
    return super.dirty;
  }

  @override
  set dirty(bool value) {
    _$dirtyAtom.reportWrite(value, super.dirty, () {
      super.dirty = value;
    });
  }

  late final _$samplePhotoSelectedAtom = Atom(
    name: 'ProfileStoreBase.samplePhotoSelected',
    context: context,
  );

  @override
  bool get samplePhotoSelected {
    _$samplePhotoSelectedAtom.reportRead();
    return super.samplePhotoSelected;
  }

  @override
  set samplePhotoSelected(bool value) {
    _$samplePhotoSelectedAtom.reportWrite(value, super.samplePhotoSelected, () {
      super.samplePhotoSelected = value;
    });
  }

  late final _$preferencesAtom = Atom(
    name: 'ProfileStoreBase.preferences',
    context: context,
  );

  @override
  ProfilePreferences get preferences {
    _$preferencesAtom.reportRead();
    return super.preferences;
  }

  @override
  set preferences(ProfilePreferences value) {
    _$preferencesAtom.reportWrite(value, super.preferences, () {
      super.preferences = value;
    });
  }

  late final _$payoutAccountAtom = Atom(
    name: 'ProfileStoreBase.payoutAccount',
    context: context,
  );

  @override
  PayoutAccount? get payoutAccount {
    _$payoutAccountAtom.reportRead();
    return super.payoutAccount;
  }

  @override
  set payoutAccount(PayoutAccount? value) {
    _$payoutAccountAtom.reportWrite(value, super.payoutAccount, () {
      super.payoutAccount = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'ProfileStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$saveAsyncAction = AsyncAction(
    'ProfileStoreBase.save',
    context: context,
  );

  @override
  Future<bool> save() {
    return _$saveAsyncAction.run(() => super.save());
  }

  late final _$togglePreferenceAsyncAction = AsyncAction(
    'ProfileStoreBase.togglePreference',
    context: context,
  );

  @override
  Future<bool> togglePreference(
    String key,
    bool value, {
    bool channel = false,
  }) {
    return _$togglePreferenceAsyncAction.run(
      () => super.togglePreference(key, value, channel: channel),
    );
  }

  late final _$setLanguageAsyncAction = AsyncAction(
    'ProfileStoreBase.setLanguage',
    context: context,
  );

  @override
  Future<bool> setLanguage(String language) {
    return _$setLanguageAsyncAction.run(() => super.setLanguage(language));
  }

  late final _$ProfileStoreBaseActionController = ActionController(
    name: 'ProfileStoreBase',
    context: context,
  );

  @override
  void edit(String key, String value) {
    final _$actionInfo = _$ProfileStoreBaseActionController.startAction(
      name: 'ProfileStoreBase.edit',
    );
    try {
      return super.edit(key, value);
    } finally {
      _$ProfileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectPhoto() {
    final _$actionInfo = _$ProfileStoreBaseActionController.startAction(
      name: 'ProfileStoreBase.selectPhoto',
    );
    try {
      return super.selectPhoto();
    } finally {
      _$ProfileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setEntity(EntityType entity) {
    final _$actionInfo = _$ProfileStoreBaseActionController.startAction(
      name: 'ProfileStoreBase.setEntity',
    );
    try {
      return super.setEntity(entity);
    } finally {
      _$ProfileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
user: ${user},
error: ${error},
errors: ${errors},
saving: ${saving},
dirty: ${dirty},
samplePhotoSelected: ${samplePhotoSelected},
preferences: ${preferences},
payoutAccount: ${payoutAccount}
    ''';
  }
}
