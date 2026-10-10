import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'payment_methods_store.g.dart';

enum PaymentMethodMutation { add, remove, setDefault }

class PaymentMethodsStore = PaymentMethodsStoreBase with _$PaymentMethodsStore;

abstract class PaymentMethodsStoreBase with Store, Lifecycle {
  PaymentMethodsStoreBase(this._repository) {
    _changes = _repository.changes.listen((event) {
      if (isDisposed || !event.affects(InvestorDataKind.methods)) return;
      if (event.kinds.contains(InvestorDataKind.scope)) {
        beginRequest();
        _loadVersion++;
        runInAction(() {
          values = const {};
          methods = const [];
          mutation = null;
          errors = const {};
          error = null;
          lastSavedId = null;
          formRevision++;
        });
      }
      unawaited(load());
    });
  }
  final InvestorAccountRepository _repository;
  late final StreamSubscription<InvestorAccountChange> _changes;
  int _loadVersion = 0;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  List<InvestorPaymentMethod> methods = const [];
  @observable
  Map<String, String> values = const {};
  @observable
  Map<String, String> errors = const {};
  @observable
  String? error;
  @observable
  PaymentMethodMutation? mutation;
  @computed
  bool get saving => mutation != null;
  @observable
  int formRevision = 0;
  @observable
  String? lastSavedId;
  @computed
  bool get cardComplete => [
    'holder',
    'number',
    'expiry',
    'cvv',
  ].every((key) => (values[key] ?? '').trim().isNotEmpty);
  @computed
  bool get bankComplete => [
    'holder',
    'bank',
    'number',
    'type',
    'branch',
  ].every((key) => (values[key] ?? '').trim().isNotEmpty);
  @action
  void edit(String key, String value) {
    values = {...values, key: value};
    errors = {...errors}..remove(key);
    error = null;
  }

  @action
  Future<void> load() async {
    if (isDisposed) return;
    final version = ++_loadVersion;
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.snapshot();
    if (isDisposed || version != _loadVersion) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          methods = value.paymentMethods;
          status = methods.isEmpty ? LoadStatus.empty : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<bool> save(PaymentMethodKind kind) async {
    if (saving || isDisposed) return false;
    final keys = kind == PaymentMethodKind.card
        ? ['holder', 'number', 'expiry', 'cvv']
        : ['holder', 'bank', 'number', 'type', 'branch'];
    errors = {
      for (final key in keys)
        if ((values[key] ?? '').trim().isEmpty) key: 'This field is required',
    };
    if (errors.isNotEmpty) return false;
    final request = beginRequest();
    mutation = PaymentMethodMutation.add;
    error = null;
    final result = await (kind == PaymentMethodKind.card
        ? _repository.addCard(
            cardNumber: values['number']!,
            holder: values['holder']!,
            expiry: values['expiry']!,
            securityCode: values['cvv']!,
            reusable: values['save'] == 'true',
          )
        : _repository.addBankAccount(
            bank: values['bank']!,
            accountNumber: values['number']!,
            accountType: values['type']!,
            branchCode: values['branch']!,
            holder: values['holder']!,
          ));
    if (!isCurrent(request)) return false;
    return runInAction(() {
      mutation = null;
      if (result case Failure(:final error)) {
        this.error = error.message;
        errors = error.fields;
        return false;
      }
      lastSavedId = (result as Success<InvestorPaymentMethod>).value.id;
      values = const {};
      errors = const {};
      formRevision++;
      return true;
    });
  }

  @action
  Future<bool> remove(String id) async {
    if (saving || isDisposed) return false;
    final request = beginRequest();
    mutation = PaymentMethodMutation.remove;
    error = null;
    final result = await _repository.removePaymentMethod(id);
    if (!isCurrent(request)) return false;
    return runInAction(() {
      mutation = null;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      return true;
    });
  }

  @action
  Future<bool> setDefault(String id, bool isDefault) async {
    if (saving || isDisposed) return false;
    final request = beginRequest();
    mutation = PaymentMethodMutation.setDefault;
    error = null;
    final result = await _repository.setDefaultPaymentMethod(id, isDefault);
    if (!isCurrent(request)) return false;
    return runInAction(() {
      mutation = null;
      if (result case Failure(:final error)) {
        this.error = error.message;
        return false;
      }
      return true;
    });
  }

  @override
  void dispose() {
    values = const {};
    unawaited(_changes.cancel());
    super.dispose();
  }
}
