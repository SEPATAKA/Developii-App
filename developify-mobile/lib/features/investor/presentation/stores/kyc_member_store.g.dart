// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_member_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$KycMemberStore on KycMemberStoreBase, Store {
  Computed<bool>? _$editableComputed;

  @override
  bool get editable => (_$editableComputed ??= Computed<bool>(
    () => super.editable,
    name: 'KycMemberStoreBase.editable',
  )).value;
  Computed<Map<String, String>>? _$valuesComputed;

  @override
  Map<String, String> get values =>
      (_$valuesComputed ??= Computed<Map<String, String>>(
        () => super.values,
        name: 'KycMemberStoreBase.values',
      )).value;
  Computed<KycMember?>? _$memberComputed;

  @override
  KycMember? get member => (_$memberComputed ??= Computed<KycMember?>(
    () => super.member,
    name: 'KycMemberStoreBase.member',
  )).value;
  Computed<int?>? _$ageComputed;

  @override
  int? get age => (_$ageComputed ??= Computed<int?>(
    () => super.age,
    name: 'KycMemberStoreBase.age',
  )).value;
  Computed<List<KycDocumentDefinition>>? _$documentsComputed;

  @override
  List<KycDocumentDefinition> get documents =>
      (_$documentsComputed ??= Computed<List<KycDocumentDefinition>>(
        () => super.documents,
        name: 'KycMemberStoreBase.documents',
      )).value;
  Computed<bool>? _$canSaveComputed;

  @override
  bool get canSave => (_$canSaveComputed ??= Computed<bool>(
    () => super.canSave,
    name: 'KycMemberStoreBase.canSave',
  )).value;
  Computed<int>? _$shareBasisPointsComputed;

  @override
  int get shareBasisPoints => (_$shareBasisPointsComputed ??= Computed<int>(
    () => super.shareBasisPoints,
    name: 'KycMemberStoreBase.shareBasisPoints',
  )).value;
  Computed<int>? _$totalAllocationComputed;

  @override
  int get totalAllocation => (_$totalAllocationComputed ??= Computed<int>(
    () => super.totalAllocation,
    name: 'KycMemberStoreBase.totalAllocation',
  )).value;
  Computed<bool>? _$canInviteComputed;

  @override
  bool get canInvite => (_$canInviteComputed ??= Computed<bool>(
    () => super.canInvite,
    name: 'KycMemberStoreBase.canInvite',
  )).value;

  late final _$statusAtom = Atom(
    name: 'KycMemberStoreBase.status',
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

  late final _$applicationAtom = Atom(
    name: 'KycMemberStoreBase.application',
    context: context,
  );

  @override
  KycDraft? get application {
    _$applicationAtom.reportRead();
    return super.application;
  }

  @override
  set application(KycDraft? value) {
    _$applicationAtom.reportWrite(value, super.application, () {
      super.application = value;
    });
  }

  late final _$draftAtom = Atom(
    name: 'KycMemberStoreBase.draft',
    context: context,
  );

  @override
  KycMemberDraft? get draft {
    _$draftAtom.reportRead();
    return super.draft;
  }

  @override
  set draft(KycMemberDraft? value) {
    _$draftAtom.reportWrite(value, super.draft, () {
      super.draft = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'KycMemberStoreBase.error',
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
    name: 'KycMemberStoreBase.errors',
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

  late final _$busyAtom = Atom(
    name: 'KycMemberStoreBase.busy',
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

  late final _$uploadingAtom = Atom(
    name: 'KycMemberStoreBase.uploading',
    context: context,
  );

  @override
  String? get uploading {
    _$uploadingAtom.reportRead();
    return super.uploading;
  }

  @override
  set uploading(String? value) {
    _$uploadingAtom.reportWrite(value, super.uploading, () {
      super.uploading = value;
    });
  }

  late final _$allocationsAtom = Atom(
    name: 'KycMemberStoreBase.allocations',
    context: context,
  );

  @override
  Map<String, int> get allocations {
    _$allocationsAtom.reportRead();
    return super.allocations;
  }

  @override
  set allocations(Map<String, int> value) {
    _$allocationsAtom.reportWrite(value, super.allocations, () {
      super.allocations = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'KycMemberStoreBase.load',
    context: context,
  );

  @override
  Future<void> load(KycMemberRole role, {String? id}) {
    return _$loadAsyncAction.run(() => super.load(role, id: id));
  }

  late final _$uploadAsyncAction = AsyncAction(
    'KycMemberStoreBase.upload',
    context: context,
  );

  @override
  Future<bool> upload(
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
  }) {
    return _$uploadAsyncAction.run(
      () => super.upload(key, name: name, bytes: bytes, mimeType: mimeType),
    );
  }

  late final _$inviteAsyncAction = AsyncAction(
    'KycMemberStoreBase.invite',
    context: context,
  );

  @override
  Future<bool> invite() {
    return _$inviteAsyncAction.run(() => super.invite());
  }

  late final _$KycMemberStoreBaseActionController = ActionController(
    name: 'KycMemberStoreBase',
    context: context,
  );

  @override
  void edit(String key, String value) {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.edit',
    );
    try {
      return super.edit(key, value);
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool save() {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.save',
    );
    try {
      return super.save();
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void allocate(String id, double value) {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.allocate',
    );
    try {
      return super.allocate(id, value);
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool saveAllocations() {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.saveAllocations',
    );
    try {
      return super.saveAllocations();
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool deleteDocument(String key) {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.deleteDocument',
    );
    try {
      return super.deleteDocument(key);
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool validateInvite() {
    final _$actionInfo = _$KycMemberStoreBaseActionController.startAction(
      name: 'KycMemberStoreBase.validateInvite',
    );
    try {
      return super.validateInvite();
    } finally {
      _$KycMemberStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
application: ${application},
draft: ${draft},
error: ${error},
errors: ${errors},
busy: ${busy},
uploading: ${uploading},
allocations: ${allocations},
editable: ${editable},
values: ${values},
member: ${member},
age: ${age},
documents: ${documents},
canSave: ${canSave},
shareBasisPoints: ${shareBasisPoints},
totalAllocation: ${totalAllocation},
canInvite: ${canInvite}
    ''';
  }
}
