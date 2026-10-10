import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
part 'earnings_store.g.dart';

class EarningsStore = EarningsStoreBase with _$EarningsStore;

abstract class EarningsStoreBase with Store, Lifecycle {
  EarningsStoreBase(this._repository) {
    balanceVisible = _repository.balanceVisible;
    _visibility = _repository.balanceVisibilityChanges.listen((visible) {
      if (!isDisposed) runInAction(() => balanceVisible = visible);
    });
  }
  late final StreamSubscription<bool> _visibility;
  @override
  void dispose() {
    unawaited(_visibility.cancel());
    super.dispose();
  }

  final LandownerRepository _repository;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  EarningsSummary? data;
  @observable
  String? error;
  @observable
  bool balanceVisible = true;
  @action
  void toggleBalance() => _repository.setBalanceVisible(!balanceVisible);
  @action
  Future<void> load() async {
    if (isDisposed || status == LoadStatus.loading) return;
    status = LoadStatus.loading;
    error = null;
    final request = beginRequest();
    final result = await _repository.earnings();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          data = value;
          status = value.payouts.isEmpty
              ? LoadStatus.empty
              : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }
}
