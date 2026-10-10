import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'kyc_store.g.dart';

class KycStore = KycStoreBase with _$KycStore;

abstract class KycStoreBase with Store, Lifecycle {
  KycStoreBase(this._repository, this.entity) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed || event.entity != null) return;
      beginRequest();
      _uploadCancellation?.cancel();
      _uploadCancellation = null;
      runInAction(() {
        draft = null;
        busy = false;
        uploading = null;
        errors = const {};
        documentUploads = const {};
      });
      unawaited(load());
    });
  }
  final KycRepository _repository;
  Cancellation? _uploadCancellation;
  final EntityType entity;
  late final StreamSubscription<KycChange> _changes;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  KycDraft? draft;
  @observable
  String? error;
  @observable
  Map<String, String> errors = const {};
  @observable
  bool busy = false;
  @observable
  String? uploading;
  @observable
  Map<String, KycUploadAttempt> documentUploads = const {};
  @observable
  String selectedStep = 'overview';
  @observable
  bool hasUnsavedChanges = false;
  @observable
  bool reviewingStep = false;
  @computed
  List<KycStepDefinition> get steps => KycPlans.steps(entity);
  @computed
  KycStepDefinition? get step {
    for (final value in steps) {
      if (value.id == selectedStep) return value;
    }
    return null;
  }

  @computed
  bool get editable =>
      draft?.status != VerificationStatus.pending &&
      draft?.status != VerificationStatus.verified;
  @computed
  int get completed => draft?.completedSteps.length ?? 0;
  @computed
  bool get canContinue =>
      !busy &&
      editable &&
      draft != null &&
      step != null &&
      !step!.documents.any(
        (document) => documentUploads.containsKey(document.key),
      ) &&
      KycValidation.progressStep(draft!, step!).isEmpty;
  @computed
  bool get canSubmit =>
      !busy &&
      editable &&
      draft != null &&
      documentUploads.isEmpty &&
      KycValidation.submission(draft!).isEmpty;
  @computed
  double get progress =>
      steps.isEmpty ? 0 : (completed / steps.length).clamp(0, 1);
  @computed
  List<KycMember> get members =>
      draft?.members
          .where((member) => step?.includesMember(member) ?? false)
          .toList() ??
      const [];

  @action
  Future<void> load({String? requestedStep}) async {
    if (isDisposed) return;
    final request = beginRequest();
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.load(entity);
    if (!isCurrent(request)) return;
    runInAction(() {
      if (_accept(result)) {
        final target = requestedStep ?? draft!.currentStep;
        if (!KycPlans.validState(entity, target)) {
          error = 'This verification step could not be found.';
          status = LoadStatus.error;
          return;
        }
        selectedStep = target;
        status = LoadStatus.success;
      } else {
        status = LoadStatus.error;
      }
    });
  }

  bool _accept(Result<KycDraft> result) {
    switch (result) {
      case Success(:final value):
        draft = value;
        error = null;
        return true;
      case Failure(:final error):
        this.error = error.message;
        errors = error.fields;
        return false;
    }
  }

  @action
  bool selectStep(String id) {
    if (busy || !KycPlans.validState(entity, id) || draft == null) return false;
    if (selectedStep == 'review' && id != 'review' && id != 'overview') {
      reviewingStep = true;
    } else if (id == 'overview' || id == 'review') {
      reviewingStep = false;
    }
    selectedStep = id;
    errors = const {};
    error = null;
    if (editable) _accept(_repository.save(draft!.copyWith(currentStep: id)));
    return true;
  }

  @action
  void edit(String key, String value) {
    if (!editable || busy || draft == null) return;
    final values = {...draft!.values, key: value};
    final taxEdits = {...draft!.taxResidencyEdits};
    if (entity == EntityType.individual &&
        KycTaxPlan.residencyFields.any((field) => field.key == key)) {
      taxEdits[values['editingTaxResidency'] ?? 'new'] = {
        for (final field in KycTaxPlan.residencyFields)
          field.key: ?values[field.key],
      };
    }
    final next = draft!.copyWith(values: values, taxResidencyEdits: taxEdits);
    _accept(_repository.save(next));
    errors = {...errors}..remove(key);
    hasUnsavedChanges = true;
  }

  @action
  bool continueStep() {
    final current = step;
    if (current == null || draft == null || busy) return false;
    if (current.documents.any(
      (document) => documentUploads.containsKey(document.key),
    )) {
      error = 'Retry or remove the failed document upload before continuing.';
      return false;
    }
    errors = KycValidation.progressStep(draft!, current);
    if (errors.isNotEmpty) {
      error = 'Complete the highlighted fields to continue.';
      return false;
    }
    if (!_accept(_repository.save(draft!))) return false;
    final index = steps.indexOf(current);
    hasUnsavedChanges = false;
    return selectStep(
      reviewingStep
          ? 'review'
          : index + 1 < steps.length
          ? steps[index + 1].id
          : 'review',
    );
  }

  bool canSaveTaxSection(KycTaxSection section) =>
      !isDisposed &&
      entity == EntityType.individual &&
      editable &&
      !busy &&
      draft != null &&
      KycValidation.taxSection(draft!, section).isEmpty;

  @action
  void beginTaxResidency(String? id) {
    if (isDisposed ||
        entity != EntityType.individual ||
        draft == null ||
        !editable ||
        busy) {
      return;
    }
    final matches = draft!.taxResidencies.where(
      (residency) => residency.id == id,
    );
    if (id != null && matches.isEmpty) {
      error = 'This tax residency could not be found.';
      status = LoadStatus.error;
      return;
    }
    final values = {...draft!.values}..remove('editingTaxResidency');
    for (final field in KycTaxPlan.residencyFields) {
      values.remove(field.key);
    }
    values.addAll(
      draft!.taxResidencyEdits[id ?? 'new'] ??
          (id == null ? const {} : matches.single.formValues),
    );
    if (id != null) values['editingTaxResidency'] = id;
    if (_accept(_repository.save(draft!.copyWith(values: values)))) {
      errors = const {};
    }
  }

  @action
  bool saveTaxSection(KycTaxSection section) {
    if (isDisposed ||
        entity != EntityType.individual ||
        !editable ||
        busy ||
        draft == null) {
      return false;
    }
    errors = KycValidation.taxSection(draft!, section);
    if (errors.isNotEmpty) {
      error = 'Complete the highlighted fields to continue.';
      return false;
    }
    final values = {...draft!.values};
    final residencies = [...draft!.taxResidencies];
    final taxEdits = {...draft!.taxResidencyEdits};
    if (section == KycTaxSection.residency) {
      final residency = KycTaxResidency(
        country: values['secondaryTaxCountry']!.trim(),
        reason: values['secondaryReason']!.trim(),
        tinType: values['secondaryTinType']!,
        tinFormat: values['secondaryTinFormat']!.trim(),
        tin: values['secondaryTin']!.trim(),
        residentSince: DateTime.parse(values['secondaryResidentSince']!),
        status: values['secondaryStatus']!,
        usPerson: values['usPerson'] == 'true',
        certified: values['secondaryCertification'] == 'true',
      );
      final index = residencies.indexWhere(
        (item) => item.id == values['editingTaxResidency'],
      );
      if (index >= 0) {
        residencies[index] = residency;
      } else {
        residencies.add(residency);
      }
      for (final field in KycTaxPlan.residencyFields) {
        values.remove(field.key);
      }
      taxEdits.remove(values['editingTaxResidency'] ?? 'new');
      values.remove('editingTaxResidency');
      values['secondaryTax'] = 'true';
    } else {
      values['pep'] = KycTaxPlan.pepYes;
    }
    final accepted = _accept(
      _repository.save(
        draft!.copyWith(
          values: values,
          taxResidencies: residencies,
          taxResidencyEdits: taxEdits,
        ),
      ),
    );
    if (accepted) hasUnsavedChanges = false;
    return accepted;
  }

  @action
  bool deleteTaxResidency(String id) {
    if (isDisposed ||
        entity != EntityType.individual ||
        !editable ||
        busy ||
        draft == null) {
      return false;
    }
    final values = {...draft!.values};
    if (values['editingTaxResidency'] == id) {
      values.remove('editingTaxResidency');
      for (final field in KycTaxPlan.residencyFields) {
        values.remove(field.key);
      }
    }
    final accepted = _accept(
      _repository.save(
        draft!.copyWith(
          values: values,
          taxResidencyEdits: {...draft!.taxResidencyEdits}..remove(id),
          taxResidencies: draft!.taxResidencies
              .where((item) => item.id != id)
              .toList(),
        ),
      ),
    );
    if (accepted) hasUnsavedChanges = true;
    return accepted;
  }

  @action
  bool saveAndExit() {
    if (draft == null || busy) return false;
    hasUnsavedChanges = false;
    return !editable || _accept(_repository.save(draft!));
  }

  @action
  Future<bool> upload(
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
    bool append = false,
    String? documentId,
  }) async {
    if (!editable || busy || isDisposed) return false;
    final request = beginRequest();
    uploading = key;
    busy = true;
    error = null;
    errors = {...errors}..remove(key);
    documentUploads = {
      ...documentUploads,
      key: KycUploadAttempt(
        name: name,
        bytes: bytes,
        mimeType: mimeType,
        append: append,
        documentId: documentId,
      ),
    };
    final cancellation = Cancellation();
    _uploadCancellation = cancellation;
    final result = await _repository.upload(
      entity,
      key,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      cancellation: cancellation,
      append: append,
      documentId: documentId,
    );
    if (!isCurrent(request)) return false;
    return runInAction(() {
      uploading = null;
      _uploadCancellation = null;
      busy = false;
      final accepted = _accept(result);
      if (accepted) {
        documentUploads = {...documentUploads}..remove(key);
        errors = {...errors}..remove(key);
        hasUnsavedChanges = true;
      } else {
        documentUploads = {
          ...documentUploads,
          key: KycUploadAttempt(
            name: name,
            bytes: bytes,
            mimeType: mimeType,
            status: KycUploadStatus.failed,
            error: error,
            append: append,
            documentId: documentId,
          ),
        };
      }
      return accepted;
    });
  }

  @action
  void cancelUpload(String key) {
    if (isDisposed || !documentUploads.containsKey(key)) return;
    if (uploading == key) {
      beginRequest();
      _uploadCancellation?.cancel();
      _uploadCancellation = null;
      uploading = null;
      busy = false;
    }
    documentUploads = {...documentUploads}..remove(key);
    errors = {...errors}..remove(key);
    error = null;
  }

  @action
  Future<bool> retryUpload(String key) {
    final attempt = documentUploads[key];
    if (attempt == null || attempt.status != KycUploadStatus.failed) {
      return Future.value(false);
    }
    return upload(
      key,
      name: attempt.name,
      bytes: attempt.bytes,
      mimeType: attempt.mimeType,
      append: attempt.append,
      documentId: attempt.documentId,
    );
  }

  @action
  bool deleteDocument(String key, {String? documentId}) {
    if (!editable || busy || isDisposed) return false;
    return _accept(
      _repository.deleteDocument(entity, key, documentId: documentId),
    );
  }

  @action
  bool saveMember(KycMember member) {
    if (!editable || busy) return false;
    return _accept(_repository.saveMember(entity, member));
  }

  @action
  bool deleteMember(String id) {
    if (!editable || busy) return false;
    return _accept(_repository.deleteMember(entity, id));
  }

  @action
  Future<bool> submit() {
    if (documentUploads.isNotEmpty) {
      error = 'Retry or remove the failed document uploads before submitting.';
      return Future.value(false);
    }
    return _perform(() => _repository.submit(entity));
  }

  @action
  Future<bool> requestSignatures({String? memberId}) => _perform(
    () => _repository.requestResolutionSignatures(entity, memberId: memberId),
  );
  @action
  Future<bool> simulateSignature(String memberId) =>
      _perform(() => _repository.simulateResolutionSignature(entity, memberId));
  @action
  Future<bool> simulateReview(bool approved) =>
      _perform(() => _repository.simulateReview(entity, approved: approved));

  @action
  Future<bool> simulateIdentityCheck() {
    if (entity != EntityType.individual ||
        selectedStep != 'identity' ||
        !canContinue) {
      return Future.value(false);
    }
    if (!_accept(_repository.save(draft!))) return Future.value(false);
    return _perform(
      () => _repository.simulateRequirementApproval(entity, 'identity'),
    );
  }

  Future<bool> _perform(Future<Result<KycDraft>> Function() action) async {
    if (busy || isDisposed) return false;
    final request = beginRequest();
    busy = true;
    error = null;
    errors = const {};
    final result = await action();
    if (!isCurrent(request)) return false;
    return runInAction(() {
      busy = false;
      return _accept(result);
    });
  }

  @override
  void dispose() {
    _uploadCancellation?.cancel();
    _uploadCancellation = null;
    documentUploads = const {};
    unawaited(_changes.cancel());
    draft = null;
    super.dispose();
  }
}
