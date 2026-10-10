import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/services/session_service.dart';
part 'onboarding_store.g.dart';

class OnboardingStore = OnboardingStoreBase with _$OnboardingStore;

abstract class OnboardingStoreBase with Store {
  OnboardingStoreBase(this._session);
  final SessionService _session;
  @observable
  int page = 0;
  @computed
  bool get isLast => page == 3;
  @action
  void setPage(int value) {
    if (value >= 0 && value <= 3) page = value;
  }

  @action
  bool next() {
    if (!isLast) {
      page++;
      return false;
    }
    _session.completeOnboarding();
    return true;
  }

  @action
  void finish() => _session.completeOnboarding();
}
