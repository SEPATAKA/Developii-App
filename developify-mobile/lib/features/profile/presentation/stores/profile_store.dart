import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/core/utils/validation.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'profile_store.g.dart';

class ProfileStore = ProfileStoreBase with _$ProfileStore;

abstract class ProfileStoreBase with Store, Lifecycle {
  ProfileStoreBase(this._repository);
  final ProfileRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  AppUser? user;
  @observable
  String? error;
  @observable
  Map<String, String> errors = const {};
  @observable
  bool saving = false;
  @observable
  bool dirty = false;
  @observable
  bool samplePhotoSelected = false;
  @observable
  ProfilePreferences preferences = const ProfilePreferences();
  @observable
  PayoutAccount? payoutAccount;

  @action
  Future<void> load() async {
    if (isDisposed || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.load();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          user = value;
          preferences = _repository.preferences;
          payoutAccount = _repository.payoutAccount;
          status = LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  void edit(String key, String value) {
    if (isDisposed || saving) return;
    user = switch (key) {
      'name' => user?.copyWith(name: value),
      'email' => user?.copyWith(email: value),
      'phone' => user?.copyWith(phone: value),
      'address' => user?.copyWith(address: value),
      'country' => user?.copyWith(countryCode: value),
      _ => user,
    };
    dirty = true;
    if (errors.containsKey(key)) errors = Map.of(errors)..remove(key);
  }

  @action
  void selectPhoto() {
    if (isDisposed || saving) return;
    samplePhotoSelected = true;
    user = user?.copyWith(hasProfilePhoto: true);
    dirty = true;
  }

  @action
  void setEntity(EntityType entity) {
    if (isDisposed || saving) return;
    user = user?.copyWith(entity: entity);
    dirty = true;
  }

  @action
  Future<bool> save() async {
    final profile = user;
    if (profile == null || isDisposed || saving) return false;
    errors = {
      if (profile.name.trim().isEmpty) 'name': 'Enter your name',
      'email': ?Validation.email(profile.email),
      if (profile.phone.trim().isEmpty) 'phone': 'Enter your phone number',
    };
    if (errors.isNotEmpty) return false;
    saving = true;
    error = null;
    final result = await _repository.update(profile);
    if (isDisposed) return false;
    return runInAction(() {
      saving = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      dirty = false;
      return true;
    });
  }

  @action
  Future<bool> togglePreference(
    String key,
    bool value, {
    bool channel = false,
  }) async {
    if (isDisposed || saving) return false;
    saving = true;
    error = null;
    final next = ProfilePreferences(
      channels: channel
          ? (Map.of(preferences.channels)..[key] = value)
          : preferences.channels,
      topics: !channel
          ? (Map.of(preferences.topics)..[key] = value)
          : preferences.topics,
      language: preferences.language,
    );
    final result = await _repository.updatePreferences(next);
    if (isDisposed) return false;
    return runInAction(() {
      saving = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      preferences = next;
      return true;
    });
  }

  @action
  Future<bool> setLanguage(String language) async {
    if (isDisposed || saving) return false;
    saving = true;
    error = null;
    final next = ProfilePreferences(
      channels: preferences.channels,
      topics: preferences.topics,
      language: language,
    );
    final result = await _repository.updatePreferences(next);
    if (isDisposed) return false;
    return runInAction(() {
      saving = false;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      preferences = next;
      return true;
    });
  }
}
