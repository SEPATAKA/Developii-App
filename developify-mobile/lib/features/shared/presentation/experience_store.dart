import 'package:mobx/mobx.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'experience_store.g.dart';

class ExperienceStore = ExperienceStoreBase with _$ExperienceStore;

abstract class ExperienceStoreBase with Store {
  @observable
  Experience selected = Experience.investor;
  @observable
  bool investorUnavailable = false;
  @action
  void select(Experience value) {
    selected = value;
    investorUnavailable = false;
  }

  @action
  bool confirm() {
    investorUnavailable = false;
    return true;
  }
}
