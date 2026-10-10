// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$KycStore on KycStoreBase, Store {
  Computed<List<KycStepDefinition>>? _$stepsComputed;

  @override
  List<KycStepDefinition> get steps =>
      (_$stepsComputed ??= Computed<List<KycStepDefinition>>(
        () => super.steps,
        name: 'KycStoreBase.steps',
      )).value;
  Computed<KycStepDefinition?>? _$stepComputed;

  @override
  KycStepDefinition? get step =>
      (_$stepComputed ??= Computed<KycStepDefinition?>(
        () => super.step,
        name: 'KycStoreBase.step',
      )).value;
  Computed<bool>? _$editableComputed;

  @override
  bool get editable => (_$editableComputed ??= Computed<bool>(
    () => super.editable,
    name: 'KycStoreBase.editable',
  )).value;
  Computed<int>? _$completedComputed;

  @override
  int get completed => (_$completedComputed ??= Computed<int>(
    () => super.completed,
    name: 'KycStoreBase.completed',
  )).value;
  Computed<bool>? _$canContinueComputed;

  @override
  bool get canContinue => (_$canContinueComputed ??= Computed<bool>(
    () => super.canContinue,
    name: 'KycStoreBase.canContinue',
  )).value;
  Computed<bool>? _$canSubmitComputed;

  @override
  bool get canSubmit => (_$canSubmitComputed ??= Computed<bool>(
    () => super.canSubmit,
    name: 'KycStoreBase.canSubmit',
  )).value;
  Computed<double>? _$progressComputed;

  @override
  double get progress => (_$progressComputed ??= Computed<double>(
    () => super.progress,
    name: 'KycStoreBase.progress',
  )).value;
  Computed<List<KycMember>>? _$membersComputed;

  @override
  List<KycMember> get members =>
      (_$membersComputed ??= Computed<List<KycMember>>(
        () => super.members,
        name: 'KycStoreBase.members',
      )).value;

  late final _$statusAtom = Atom(name: 'KycStoreBase.status', context: context);

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

  late final _$draftAtom = Atom(name: 'KycStoreBase.draft', context: context);

  @override
  KycDraft? get draft {
    _$draftAtom.reportRead();
    return super.draft;
  }

  @override
  set draft(KycDraft? value) {
    _$draftAtom.reportWrite(value, super.draft, () {
      super.draft = value;
    });
  }

  late final _$errorAtom = Atom(name: 'KycStoreBase.error', context: context);

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

  late final _$errorsAtom = Atom(name: 'KycStoreBase.errors', context: context);

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

  late final _$busyAtom = Atom(name: 'KycStoreBase.busy', context: context);

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
    name: 'KycStoreBase.uploading',
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

  late final _$documentUploadsAtom = Atom(
    name: 'KycStoreBase.documentUploads',
    context: context,
  );

  @override
  Map<String, KycUploadAttempt> get documentUploads {
    _$documentUploadsAtom.reportRead();
    return super.documentUploads;
  }

  @override
  set documentUploads(Map<String, KycUploadAttempt> value) {
    _$documentUploadsAtom.reportWrite(value, super.documentUploads, () {
      super.documentUploads = value;
    });
  }

  late final _$selectedStepAtom = Atom(
    name: 'KycStoreBase.selectedStep',
    context: context,
  );

  @override
  String get selectedStep {
    _$selectedStepAtom.reportRead();
    return super.selectedStep;
  }

  @override
  set selectedStep(String value) {
    _$selectedStepAtom.reportWrite(value, super.selectedStep, () {
      super.selectedStep = value;
    });
  }

  late final _$hasUnsavedChangesAtom = Atom(
    name: 'KycStoreBase.hasUnsavedChanges',
    context: context,
  );

  @override
  bool get hasUnsavedChanges {
    _$hasUnsavedChangesAtom.reportRead();
    return super.hasUnsavedChanges;
  }

  @override
  set hasUnsavedChanges(bool value) {
    _$hasUnsavedChangesAtom.reportWrite(value, super.hasUnsavedChanges, () {
      super.hasUnsavedChanges = value;
    });
  }

  late final _$reviewingStepAtom = Atom(
    name: 'KycStoreBase.reviewingStep',
    context: context,
  );

  @override
  bool get reviewingStep {
    _$reviewingStepAtom.reportRead();
    return super.reviewingStep;
  }

  @override
  set reviewingStep(bool value) {
    _$reviewingStepAtom.reportWrite(value, super.reviewingStep, () {
      super.reviewingStep = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'KycStoreBase.load',
    context: context,
  );

  @override
  Future<void> load({String? requestedStep}) {
    return _$loadAsyncAction.run(
      () => super.load(requestedStep: requestedStep),
    );
  }

  late final _$uploadAsyncAction = AsyncAction(
    'KycStoreBase.upload',
    context: context,
  );

  @override
  Future<bool> upload(
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
    bool append = false,
    String? documentId,
  }) {
    return _$uploadAsyncAction.run(
      () => super.upload(
        key,
        name: name,
        bytes: bytes,
        mimeType: mimeType,
        append: append,
        documentId: documentId,
      ),
    );
  }

  late final _$KycStoreBaseActionController = ActionController(
    name: 'KycStoreBase',
    context: context,
  );

  @override
  bool selectStep(String id) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.selectStep',
    );
    try {
      return super.selectStep(id);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void edit(String key, String value) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.edit',
    );
    try {
      return super.edit(key, value);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool continueStep() {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.continueStep',
    );
    try {
      return super.continueStep();
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void beginTaxResidency(String? id) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.beginTaxResidency',
    );
    try {
      return super.beginTaxResidency(id);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool saveTaxSection(KycTaxSection section) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.saveTaxSection',
    );
    try {
      return super.saveTaxSection(section);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool deleteTaxResidency(String id) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.deleteTaxResidency',
    );
    try {
      return super.deleteTaxResidency(id);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool saveAndExit() {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.saveAndExit',
    );
    try {
      return super.saveAndExit();
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelUpload(String key) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.cancelUpload',
    );
    try {
      return super.cancelUpload(key);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> retryUpload(String key) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.retryUpload',
    );
    try {
      return super.retryUpload(key);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool deleteDocument(String key, {String? documentId}) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.deleteDocument',
    );
    try {
      return super.deleteDocument(key, documentId: documentId);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool saveMember(KycMember member) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.saveMember',
    );
    try {
      return super.saveMember(member);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool deleteMember(String id) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.deleteMember',
    );
    try {
      return super.deleteMember(id);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> submit() {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.submit',
    );
    try {
      return super.submit();
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> requestSignatures({String? memberId}) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.requestSignatures',
    );
    try {
      return super.requestSignatures(memberId: memberId);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> simulateSignature(String memberId) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.simulateSignature',
    );
    try {
      return super.simulateSignature(memberId);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> simulateReview(bool approved) {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.simulateReview',
    );
    try {
      return super.simulateReview(approved);
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  Future<bool> simulateIdentityCheck() {
    final _$actionInfo = _$KycStoreBaseActionController.startAction(
      name: 'KycStoreBase.simulateIdentityCheck',
    );
    try {
      return super.simulateIdentityCheck();
    } finally {
      _$KycStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
draft: ${draft},
error: ${error},
errors: ${errors},
busy: ${busy},
uploading: ${uploading},
documentUploads: ${documentUploads},
selectedStep: ${selectedStep},
hasUnsavedChanges: ${hasUnsavedChanges},
reviewingStep: ${reviewingStep},
steps: ${steps},
step: ${step},
editable: ${editable},
completed: ${completed},
canContinue: ${canContinue},
canSubmit: ${canSubmit},
progress: ${progress},
members: ${members}
    ''';
  }
}
