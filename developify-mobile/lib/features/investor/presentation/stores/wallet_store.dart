import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'wallet_store.g.dart';

class WalletStore = WalletStoreBase with _$WalletStore;

abstract class WalletStoreBase with Store, Lifecycle {
  WalletStoreBase(this._repository) {
    balanceVisible = _repository.balanceVisible;
    _changes = _repository.changes.listen((event) {
      if (isDisposed) return;
      runInAction(() => balanceVisible = _repository.balanceVisible);
      if (event.kinds.contains(InvestorDataKind.privacy)) return;
      if (isDisposed ||
          !event.kinds.any(
            const {
              InvestorDataKind.scope,
              InvestorDataKind.privacy,
              InvestorDataKind.wallet,
              InvestorDataKind.transactions,
              InvestorDataKind.methods,
            }.contains,
          )) {
        return;
      }
      if (event.kinds.contains(InvestorDataKind.scope)) {
        runInAction(() => data = null);
      }
      unawaited(load());
    });
  }
  final InvestorAccountRepository _repository;
  late final StreamSubscription<InvestorAccountChange> _changes;
  @observable
  bool balanceVisible = true;
  @action
  void toggleBalance() => _repository.setBalanceVisible(!balanceVisible);
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  InvestorAccountSnapshot? data;
  @observable
  String? error;

  @action
  Future<void> load() async {
    if (isDisposed) return;
    final request = beginRequest();
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.snapshot();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          data = value;
          status = value.transactions.isEmpty
              ? LoadStatus.empty
              : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}
