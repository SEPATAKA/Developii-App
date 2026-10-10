import 'package:mobx/mobx.dart';
part 'information_store.g.dart';

class InformationStore = InformationStoreBase with _$InformationStore;

abstract class InformationStoreBase with Store {
  @observable
  int? expandedQuestion = 0;
  @observable
  bool acceptedTerms = false;
  @action
  void toggleQuestion(int index) =>
      expandedQuestion = expandedQuestion == index ? null : index;
  @action
  void acceptTerms(bool value) => acceptedTerms = value;
}
