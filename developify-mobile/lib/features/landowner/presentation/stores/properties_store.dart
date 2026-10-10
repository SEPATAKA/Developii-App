import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
part 'properties_store.g.dart';

class PropertiesStore = PropertiesStoreBase with _$PropertiesStore;

abstract class PropertiesStoreBase with Store, Lifecycle {
  PropertiesStoreBase(this._repository) {
    _changes = _repository.changes.listen((_) {
      if (!isDisposed) unawaited(load());
    });
  }
  late final StreamSubscription<void> _changes;
  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }

  final LandownerRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  List<Property> items = const [];
  @observable
  PropertyStatus? filter;
  @observable
  String query = '';
  @observable
  String? error;
  @computed
  List<Property> get visibleItems => items
      .where(
        (item) =>
            (filter == null || item.status == filter) &&
            '${item.name} ${item.town} ${item.erf}'.toLowerCase().contains(
              query.trim().toLowerCase(),
            ),
      )
      .toList(growable: false);
  @action
  void setFilter(PropertyStatus? value) => filter = value;
  @action
  void search(String value) => query = value;
  @action
  Future<void> load() async {
    if (isDisposed || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.properties();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          items = value;
          status = value.isEmpty ? LoadStatus.empty : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }
}
