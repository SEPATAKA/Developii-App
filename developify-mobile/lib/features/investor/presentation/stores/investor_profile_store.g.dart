// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_profile_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestorProfileStore on InvestorProfileStoreBase, Store {
  Computed<int>? _$kycTotalComputed;

  @override
  int get kycTotal => (_$kycTotalComputed ??= Computed<int>(
    () => super.kycTotal,
    name: 'InvestorProfileStoreBase.kycTotal',
  )).value;
  Computed<int>? _$kycCompletedComputed;

  @override
  int get kycCompleted => (_$kycCompletedComputed ??= Computed<int>(
    () => super.kycCompleted,
    name: 'InvestorProfileStoreBase.kycCompleted',
  )).value;
  Computed<MonetaryAmount>? _$investedComputed;

  @override
  MonetaryAmount get invested =>
      (_$investedComputed ??= Computed<MonetaryAmount>(
        () => super.invested,
        name: 'InvestorProfileStoreBase.invested',
      )).value;
  Computed<MonetaryAmount>? _$earnedComputed;

  @override
  MonetaryAmount get earned => (_$earnedComputed ??= Computed<MonetaryAmount>(
    () => super.earned,
    name: 'InvestorProfileStoreBase.earned',
  )).value;

  late final _$balanceVisibleAtom = Atom(
    name: 'InvestorProfileStoreBase.balanceVisible',
    context: context,
  );

  @override
  bool get balanceVisible {
    _$balanceVisibleAtom.reportRead();
    return super.balanceVisible;
  }

  @override
  set balanceVisible(bool value) {
    _$balanceVisibleAtom.reportWrite(value, super.balanceVisible, () {
      super.balanceVisible = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'InvestorProfileStoreBase.status',
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

  late final _$userAtom = Atom(
    name: 'InvestorProfileStoreBase.user',
    context: context,
  );

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

  late final _$accountAtom = Atom(
    name: 'InvestorProfileStoreBase.account',
    context: context,
  );

  @override
  InvestorAccountSnapshot? get account {
    _$accountAtom.reportRead();
    return super.account;
  }

  @override
  set account(InvestorAccountSnapshot? value) {
    _$accountAtom.reportWrite(value, super.account, () {
      super.account = value;
    });
  }

  late final _$verificationAtom = Atom(
    name: 'InvestorProfileStoreBase.verification',
    context: context,
  );

  @override
  KycDraft? get verification {
    _$verificationAtom.reportRead();
    return super.verification;
  }

  @override
  set verification(KycDraft? value) {
    _$verificationAtom.reportWrite(value, super.verification, () {
      super.verification = value;
    });
  }

  late final _$entityAtom = Atom(
    name: 'InvestorProfileStoreBase.entity',
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

  late final _$nonResidentAtom = Atom(
    name: 'InvestorProfileStoreBase.nonResident',
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

  late final _$languageAtom = Atom(
    name: 'InvestorProfileStoreBase.language',
    context: context,
  );

  @override
  String get language {
    _$languageAtom.reportRead();
    return super.language;
  }

  @override
  set language(String value) {
    _$languageAtom.reportWrite(value, super.language, () {
      super.language = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'InvestorProfileStoreBase.error',
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

  late final _$loadAsyncAction = AsyncAction(
    'InvestorProfileStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$InvestorProfileStoreBaseActionController = ActionController(
    name: 'InvestorProfileStoreBase',
    context: context,
  );

  @override
  void selectEntity(EntityType value, {bool? nonResident}) {
    final _$actionInfo = _$InvestorProfileStoreBaseActionController.startAction(
      name: 'InvestorProfileStoreBase.selectEntity',
    );
    try {
      return super.selectEntity(value, nonResident: nonResident);
    } finally {
      _$InvestorProfileStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
balanceVisible: ${balanceVisible},
status: ${status},
user: ${user},
account: ${account},
verification: ${verification},
entity: ${entity},
nonResident: ${nonResident},
language: ${language},
error: ${error},
kycTotal: ${kycTotal},
kycCompleted: ${kycCompleted},
invested: ${invested},
earned: ${earned}
    ''';
  }
}
