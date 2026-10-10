import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
part 'property_detail_store.g.dart';

class PropertyDetailStore = PropertyDetailStoreBase with _$PropertyDetailStore;

abstract class PropertyDetailStoreBase with Store, Lifecycle {
  PropertyDetailStoreBase(this._repository);
  final LandownerRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  Property? property;
  @observable
  String? error;
  @action
  Future<void> load(String id) async {
    if (isDisposed) return;
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.property(id);
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          property = value;
          status = LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }
}
