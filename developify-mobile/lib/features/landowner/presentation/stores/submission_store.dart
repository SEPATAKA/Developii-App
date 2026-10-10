import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/submission_draft.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'submission_store.g.dart';

class SubmissionStore = SubmissionStoreBase with _$SubmissionStore;

abstract class SubmissionStoreBase with Store, Lifecycle {
  SubmissionStoreBase(this._repository, String draftId)
    : draft = _repository.readDraft(draftId);
  final LandownerRepository _repository;
  @observable
  SubmissionDraft draft;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  Map<String, String> errors = const {};
  @observable
  String? error;
  @observable
  bool dirty = false;
  @computed
  int get step => draft.step;
  @computed
  double get progress => step / 10;

  @action
  void update(SubmissionDraft value) {
    draft = value;
    dirty = true;
    error = null;
  }

  @action
  void setField(String key, String value) {
    update(switch (key) {
      'name' => draft.copyWith(name: value),
      'number' => draft.copyWith(propertyNumber: value),
      'type' => draft.copyWith(propertyType: value),
      'size' => draft.copyWith(size: value),
      'unit' => draft.copyWith(unit: value),
      'deeds' => draft.copyWith(deedsOffice: value),
      'address' => draft.copyWith(address: value),
      'city' => draft.copyWith(city: value),
      'town' => draft.copyWith(town: value),
      'country' => draft.copyWith(country: value),
      'monthly' => draft.copyWith(monthlyLease: value),
      'province' => draft.copyWith(province: value),
      'postal' => draft.copyWith(postalCode: value),
      'latitude' => draft.copyWith(latitude: value),
      'longitude' => draft.copyWith(longitude: value),
      'deal' => draft.copyWith(deal: value),
      'price' => draft.copyWith(price: value),
      'notes' => draft.copyWith(notes: value),
      _ => draft,
    });
    if (errors.containsKey(key)) errors = Map.of(errors)..remove(key);
  }

  @action
  void setStep(int value) {
    if (value < 1 || value > 9) return;
    draft = draft.copyWith(step: value);
    errors = const {};
    error = null;
  }

  @action
  void addSamplePhotos() {
    update(
      draft.copyWith(
        photos: List.generate(
          4,
          (i) => LocalAttachment(
            id: 'photo-$i',
            name: '${['North', 'South', 'East', 'West'][i]} boundary',
          ),
        ),
      ),
    );
  }

  @action
  void removePhoto(String id) => update(
    draft.copyWith(
      photos: draft.photos.where((photo) => photo.id != id).toList(),
    ),
  );
  @action
  void addDocument(String key) {
    final documents = Map<String, LocalAttachment>.of(draft.documents);
    documents[key] = LocalAttachment(
      id: key,
      name: switch (key) {
        'title' => 'TD_Erf4412_2019.pdf',
        'rates' => 'CityJoburg_Rates_May.p',
        'identity' => 'Themba_ID_Certified.pdf',
        'valuation' => 'Valuation_Report.pdf',
        'zoning' => 'TD_Erf4412_2019.pdf',
        _ => '$key.pdf',
      },
    );
    update(draft.copyWith(documents: documents));
  }

  @action
  void removeDocument(String key) {
    final documents = Map.of(draft.documents)..remove(key);
    update(
      draft.copyWith(
        documents: documents,
        coOwners: documents.keys.any((key) => key.startsWith('co-owner')),
      ),
    );
  }

  @action
  void save() {
    _repository.saveDraft(draft);
    dirty = false;
  }

  String? _moneyError(String value, String label) {
    final trimmed = value.trim();
    if (!RegExp(r'^(?:R\s*)?\d+(?:,\d{3})*(?:\.\d+)?$').hasMatch(trimmed)) {
      return 'Enter a valid $label';
    }
    return Validation.positiveNumber(
      trimmed.replaceAll(RegExp(r'[R,\s]'), ''),
      label,
    );
  }

  Map<String, String> validateStep(int currentStep) {
    final failures = <String, String>{};
    void check(String key, String? message) {
      if (message != null) failures[key] = message;
    }

    switch (currentStep) {
      case 1:
        check('name', Validation.required(draft.name, 'a property name'));
        check(
          'number',
          Validation.required(draft.propertyNumber, 'a property number'),
        );
        check(
          'type',
          Validation.required(draft.propertyType, 'a property type'),
        );
        check('size', Validation.positiveNumber(draft.size, 'property size'));
        check('unit', Validation.required(draft.unit, 'a unit'));
        check(
          'deeds',
          Validation.required(draft.deedsOffice, 'a deeds office'),
        );
      case 2:
        check(
          'address',
          Validation.required(draft.address, 'the street address'),
        );
        check('city', Validation.required(draft.city, 'the city'));
        check('province', Validation.required(draft.province, 'the province'));
        final lat = double.tryParse(draft.latitude);
        final lng = double.tryParse(draft.longitude);
        if (lat == null || !lat.isFinite || lat < -90 || lat > 90) {
          failures['latitude'] = 'Enter a valid latitude';
        }
        if (lng == null || !lng.isFinite || lng < -180 || lng > 180) {
          failures['longitude'] = 'Enter a valid longitude';
        }
      case 3:
        if (draft.photos.length < 4) {
          failures['photos'] = 'Add at least 4 site photos';
        }
      case 7:
        final required = draft.entity == EntityType.trust
            ? ['trustees', 'trust-resolution', 'trust-mandate', 'trust-deed']
            : ['identity'];
        if (draft.coOwners &&
            !draft.documents.keys.any((key) => key.startsWith('co-owner'))) {
          required.add('co-owner');
        }
        for (final key in required) {
          if (!draft.documents.containsKey(key)) {
            failures[key] = 'Attach the required document';
          }
        }
      case 8:
        if (draft.price.trim().isNotEmpty) {
          check('price', _moneyError(draft.price, 'amount'));
        }
        if (draft.monthlyLease.trim().isNotEmpty) {
          check('monthly', _moneyError(draft.monthlyLease, 'monthly amount'));
        }
        if (draft.hasValuation && !draft.documents.containsKey('valuation')) {
          failures['valuation'] = 'Attach the valuation report';
        }
      case 9:
        if (!draft.accepted) {
          failures['accepted'] = 'Confirm the declaration before submitting';
        }
    }
    return failures;
  }

  @action
  bool next() {
    errors = validateStep(step);
    if (errors.isNotEmpty) return false;
    save();
    return true;
  }

  @action
  Future<String?> submit() async {
    if (isDisposed || status == LoadStatus.loading) return null;
    for (var current = 1; current <= 9; current++) {
      final failures = validateStep(current);
      if (failures.isNotEmpty) {
        errors = failures;
        error = 'Review step $current before submitting.';
        return null;
      }
    }
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.submit(draft);
    if (!isCurrent(request)) return null;
    return runInAction(() {
      switch (result) {
        case Success(:final value):
          dirty = false;
          status = LoadStatus.success;
          return value;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
          return null;
      }
    });
  }
}
