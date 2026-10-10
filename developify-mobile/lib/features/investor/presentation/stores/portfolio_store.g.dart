// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$PortfolioStore on PortfolioStoreBase, Store {
  Computed<PortfolioAnalytics?>? _$analyticsComputed;

  @override
  PortfolioAnalytics? get analytics =>
      (_$analyticsComputed ??= Computed<PortfolioAnalytics?>(
        () => super.analytics,
        name: 'PortfolioStoreBase.analytics',
      )).value;
  Computed<List<InvestorInvestment>>? _$investmentsComputed;

  @override
  List<InvestorInvestment> get investments =>
      (_$investmentsComputed ??= Computed<List<InvestorInvestment>>(
        () => super.investments,
        name: 'PortfolioStoreBase.investments',
      )).value;

  late final _$balanceVisibleAtom = Atom(
    name: 'PortfolioStoreBase.balanceVisible',
    context: context,
  );

  @override
  bool get balanceVisible {
    _$balanceVisibleAtom.reportRead();
    return super.balanceVisible;
  }

  @override
  set balanceVisible(bool value) {
    _$balanceVisibleAtom.reportWrite(value, super.balanceVisible, () {
      super.balanceVisible = value;
    });
  }

  late final _$statusAtom = Atom(
    name: 'PortfolioStoreBase.status',
    context: context,
  );

  @override
  LoadStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(LoadStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$dataAtom = Atom(
    name: 'PortfolioStoreBase.data',
    context: context,
  );

  @override
  InvestorAccountSnapshot? get data {
    _$dataAtom.reportRead();
    return super.data;
  }

  @override
  set data(InvestorAccountSnapshot? value) {
    _$dataAtom.reportWrite(value, super.data, () {
      super.data = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'PortfolioStoreBase.error',
    context: context,
  );

  @override
  String? get error {
    _$errorAtom.reportRead();
    return super.error;
  }

  @override
  set error(String? value) {
    _$errorAtom.reportWrite(value, super.error, () {
      super.error = value;
    });
  }

  late final _$filterAtom = Atom(
    name: 'PortfolioStoreBase.filter',
    context: context,
  );

  @override
  InvestorInvestmentStatus get filter {
    _$filterAtom.reportRead();
    return super.filter;
  }

  @override
  set filter(InvestorInvestmentStatus value) {
    _$filterAtom.reportWrite(value, super.filter, () {
      super.filter = value;
    });
  }

  late final _$periodAtom = Atom(
    name: 'PortfolioStoreBase.period',
    context: context,
  );

  @override
  PortfolioPeriod get period {
    _$periodAtom.reportRead();
    return super.period;
  }

  @override
  set period(PortfolioPeriod value) {
    _$periodAtom.reportWrite(value, super.period, () {
      super.period = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'PortfolioStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$PortfolioStoreBaseActionController = ActionController(
    name: 'PortfolioStoreBase',
    context: context,
  );

  @override
  void toggleBalance() {
    final _$actionInfo = _$PortfolioStoreBaseActionController.startAction(
      name: 'PortfolioStoreBase.toggleBalance',
    );
    try {
      return super.toggleBalance();
    } finally {
      _$PortfolioStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPeriod(PortfolioPeriod value) {
    final _$actionInfo = _$PortfolioStoreBaseActionController.startAction(
      name: 'PortfolioStoreBase.setPeriod',
    );
    try {
      return super.setPeriod(value);
    } finally {
      _$PortfolioStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFilter(InvestorInvestmentStatus value) {
    final _$actionInfo = _$PortfolioStoreBaseActionController.startAction(
      name: 'PortfolioStoreBase.setFilter',
    );
    try {
      return super.setFilter(value);
    } finally {
      _$PortfolioStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
balanceVisible: ${balanceVisible},
status: ${status},
data: ${data},
error: ${error},
filter: ${filter},
period: ${period},
analytics: ${analytics},
investments: ${investments}
    ''';
  }
}
