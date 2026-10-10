import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/profile/domain/profile_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
part 'investor_profile_store.g.dart';

class InvestorProfileStore = InvestorProfileStoreBase
    with _$InvestorProfileStore;

abstract class InvestorProfileStoreBase with Store, Lifecycle {
  InvestorProfileStoreBase(
    this._profile,
    this._accounts,
    this._kyc,
    this._context,
  ) {
    balanceVisible = _accounts.balanceVisible;
    _accountChanges = _accounts.changes.listen((event) {
      if (isDisposed) return;
      runInAction(() => balanceVisible = _accounts.balanceVisible);
      if (event.kinds.contains(InvestorDataKind.privacy)) return;
      if (event.kinds.contains(InvestorDataKind.scope) && !isDisposed) {
        runInAction(() {
          user = null;
          account = null;
          verification = null;
        });
      }
      if (!isDisposed) unawaited(load());
    });
    _kycChanges = _kyc.changes.listen((_) {
      if (!isDisposed) unawaited(load());
    });
  }
  final ProfileRepository _profile;
  final InvestorAccountRepository _accounts;
  final KycRepository _kyc;
  final InvestorAccountContext _context;
  late final StreamSubscription<InvestorAccountChange> _accountChanges;
  late final StreamSubscription<KycChange> _kycChanges;
  @observable
  bool balanceVisible = true;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  AppUser? user;
  @observable
  InvestorAccountSnapshot? account;
  @observable
  KycDraft? verification;
  @observable
  EntityType entity = EntityType.individual;
  @observable
  bool nonResident = false;
  @observable
  String language = 'English (UK)';
  @observable
  String? error;
  @computed
  int get kycTotal =>
      KycPlans.steps(entity).length + (entity == EntityType.individual ? 1 : 0);
  @computed
  int get kycCompleted =>
      (verification?.completedSteps.length ?? 0) +
      (entity == EntityType.individual ? 1 : 0);
  @computed
  MonetaryAmount get invested => MonetaryAmount(
    account?.investments
            .where((item) => item.amount.currency == Currency.zar)
            .fold<int>(0, (total, item) => total + item.amount.minorUnits) ??
        0,
    Currency.zar,
  );
  @computed
  MonetaryAmount get earned => MonetaryAmount(
    account?.investments
            .where((item) => item.earned.currency == Currency.zar)
            .fold<int>(0, (total, item) => total + item.earned.minorUnits) ??
        0,
    Currency.zar,
  );
  @action
  Future<void> load() async {
    if (isDisposed) return;
    final request = beginRequest();
    entity = _context.entity;
    nonResident = _context.nonResident;
    status = LoadStatus.loading;
    error = null;
    final results = await (
      _profile.load(),
      _accounts.snapshot(),
      _kyc.load(entity),
    ).wait;
    if (!isCurrent(request)) return;
    runInAction(() {
      if (results.$1 case Success(:final value)) user = value;
      if (results.$2 case Success(:final value)) account = value;
      if (results.$3 case Success(:final value)) verification = value;
      for (final result in [results.$1, results.$2, results.$3]) {
        if (result case Failure(:final error)) {
          this.error = error.message;
        }
      }
      language = _profile.preferences.language;
      status = error == null ? LoadStatus.success : LoadStatus.error;
    });
  }

  @action
  void selectEntity(EntityType value, {bool? nonResident}) {
    if (isDisposed) return;
    _context.selectEntity(value, nonResident: nonResident);
  }

  bool nonResidentFor(EntityType entity) => _context.nonResidentFor(entity);

  @override
  void dispose() {
    unawaited(_accountChanges.cancel());
    unawaited(_kycChanges.cancel());
    user = null;
    account = null;
    verification = null;
    super.dispose();
  }
}
