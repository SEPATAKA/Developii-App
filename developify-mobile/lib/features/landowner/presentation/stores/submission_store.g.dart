// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'submission_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SubmissionStore on SubmissionStoreBase, Store {
  Computed<int>? _$stepComputed;

  @override
  int get step => (_$stepComputed ??= Computed<int>(
    () => super.step,
    name: 'SubmissionStoreBase.step',
  )).value;
  Computed<double>? _$progressComputed;

  @override
  double get progress => (_$progressComputed ??= Computed<double>(
    () => super.progress,
    name: 'SubmissionStoreBase.progress',
  )).value;

  late final _$draftAtom = Atom(
    name: 'SubmissionStoreBase.draft',
    context: context,
  );

  @override
  SubmissionDraft get draft {
    _$draftAtom.reportRead();
    return super.draft;
  }

  @override
  set draft(SubmissionDraft value) {
    _$draftAtom.reportWrite(value, super.draft, () {
      super.draft = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'SubmissionStoreBase.status',
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

  late final _$errorsAtom = Atom(
    name: 'SubmissionStoreBase.errors',
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

  late final _$errorAtom = Atom(
    name: 'SubmissionStoreBase.error',
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

  late final _$dirtyAtom = Atom(
    name: 'SubmissionStoreBase.dirty',
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

  late final _$submitAsyncAction = AsyncAction(
    'SubmissionStoreBase.submit',
    context: context,
  );

  @override
  Future<String?> submit() {
    return _$submitAsyncAction.run(() => super.submit());
  }

  late final _$SubmissionStoreBaseActionController = ActionController(
    name: 'SubmissionStoreBase',
    context: context,
  );

  @override
  void update(SubmissionDraft value) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.update',
    );
    try {
      return super.update(value);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setField(String key, String value) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.setField',
    );
    try {
      return super.setField(key, value);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setStep(int value) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.setStep',
    );
    try {
      return super.setStep(value);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addSamplePhotos() {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.addSamplePhotos',
    );
    try {
      return super.addSamplePhotos();
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removePhoto(String id) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.removePhoto',
    );
    try {
      return super.removePhoto(id);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addDocument(String key) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.addDocument',
    );
    try {
      return super.addDocument(key);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeDocument(String key) {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.removeDocument',
    );
    try {
      return super.removeDocument(key);
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void save() {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.save',
    );
    try {
      return super.save();
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  bool next() {
    final _$actionInfo = _$SubmissionStoreBaseActionController.startAction(
      name: 'SubmissionStoreBase.next',
    );
    try {
      return super.next();
    } finally {
      _$SubmissionStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
draft: ${draft},
status: ${status},
errors: ${errors},
error: ${error},
dirty: ${dirty},
step: ${step},
progress: ${progress}
    ''';
  }
}
