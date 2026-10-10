import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'transactions_store.g.dart';

class TransactionsStore = TransactionsStoreBase with _$TransactionsStore;

abstract class TransactionsStoreBase with Store, Lifecycle {
  TransactionsStoreBase(this._repository) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed ||
          !event.kinds.any(
            const {
              InvestorDataKind.scope,
              InvestorDataKind.transactions,
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
  LoadStatus status = LoadStatus.initial;
  @observable
  InvestorAccountSnapshot? data;
  @observable
  String? error;
  @observable
  InvestorTransactionKind? filter;
  @computed
  List<InvestorTransaction> get transactions {
    final items =
        data?.transactions
            .where((item) => filter == null || item.kind == filter)
            .toList() ??
        <InvestorTransaction>[];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @action
  void setFilter(InvestorTransactionKind? value) => filter = value;

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
