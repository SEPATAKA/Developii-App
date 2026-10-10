// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investor_home_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestorHomeStore on InvestorHomeStoreBase, Store {
  Computed<PortfolioAnalytics?>? _$portfolioComputed;

  @override
  PortfolioAnalytics? get portfolio =>
      (_$portfolioComputed ??= Computed<PortfolioAnalytics?>(
        () => super.portfolio,
        name: 'InvestorHomeStoreBase.portfolio',
      )).value;

  late final _$balanceVisibleAtom = Atom(
    name: 'InvestorHomeStoreBase.balanceVisible',
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
    name: 'InvestorHomeStoreBase.status',
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
    name: 'InvestorHomeStoreBase.data',
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

  late final _$projectsAtom = Atom(
    name: 'InvestorHomeStoreBase.projects',
    context: context,
  );

  @override
  List<InvestorProject> get projects {
    _$projectsAtom.reportRead();
    return super.projects;
  }

  @override
  set projects(List<InvestorProject> value) {
    _$projectsAtom.reportWrite(value, super.projects, () {
      super.projects = value;
    });
  }

  late final _$favouritesAtom = Atom(
    name: 'InvestorHomeStoreBase.favourites',
    context: context,
  );

  @override
  Set<String> get favourites {
    _$favouritesAtom.reportRead();
    return super.favourites;
  }

  @override
  set favourites(Set<String> value) {
    _$favouritesAtom.reportWrite(value, super.favourites, () {
      super.favourites = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'InvestorHomeStoreBase.error',
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

  late final _$loadAsyncAction = AsyncAction(
    'InvestorHomeStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$toggleFavouriteAsyncAction = AsyncAction(
    'InvestorHomeStoreBase.toggleFavourite',
    context: context,
  );

  @override
  Future<void> toggleFavourite(String id) {
    return _$toggleFavouriteAsyncAction.run(() => super.toggleFavourite(id));
  }

  late final _$InvestorHomeStoreBaseActionController = ActionController(
    name: 'InvestorHomeStoreBase',
    context: context,
  );

  @override
  void toggleBalance() {
    final _$actionInfo = _$InvestorHomeStoreBaseActionController.startAction(
      name: 'InvestorHomeStoreBase.toggleBalance',
    );
    try {
      return super.toggleBalance();
    } finally {
      _$InvestorHomeStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
balanceVisible: ${balanceVisible},
status: ${status},
data: ${data},
projects: ${projects},
favourites: ${favourites},
error: ${error},
portfolio: ${portfolio}
    ''';
  }
}
