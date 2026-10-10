// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ExploreStore on ExploreStoreBase, Store {
  Computed<List<InvestorProject>>? _$suggestedResultsComputed;

  @override
  List<InvestorProject> get suggestedResults =>
      (_$suggestedResultsComputed ??= Computed<List<InvestorProject>>(
        () => super.suggestedResults,
        name: 'ExploreStoreBase.suggestedResults',
      )).value;
  Computed<ProjectFilter>? _$filterComputed;

  @override
  ProjectFilter get filter => (_$filterComputed ??= Computed<ProjectFilter>(
    () => super.filter,
    name: 'ExploreStoreBase.filter',
  )).value;
  Computed<List<InvestorProject>>? _$resultsComputed;

  @override
  List<InvestorProject> get results =>
      (_$resultsComputed ??= Computed<List<InvestorProject>>(
        () => super.results,
        name: 'ExploreStoreBase.results',
      )).value;

  late final _$statusAtom = Atom(
    name: 'ExploreStoreBase.status',
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

  late final _$projectsAtom = Atom(
    name: 'ExploreStoreBase.projects',
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

  late final _$errorAtom = Atom(
    name: 'ExploreStoreBase.error',
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

  late final _$queryAtom = Atom(
    name: 'ExploreStoreBase.query',
    context: context,
  );

  @override
  String get query {
    _$queryAtom.reportRead();
    return super.query;
  }

  @override
  set query(String value) {
    _$queryAtom.reportWrite(value, super.query, () {
      super.query = value;
    });
  }

  late final _$categoryAtom = Atom(
    name: 'ExploreStoreBase.category',
    context: context,
  );

  @override
  ProjectCategory? get category {
    _$categoryAtom.reportRead();
    return super.category;
  }

  @override
  set category(ProjectCategory? value) {
    _$categoryAtom.reportWrite(value, super.category, () {
      super.category = value;
    });
  }

  late final _$locationAtom = Atom(
    name: 'ExploreStoreBase.location',
    context: context,
  );

  @override
  String get location {
    _$locationAtom.reportRead();
    return super.location;
  }

  @override
  set location(String value) {
    _$locationAtom.reportWrite(value, super.location, () {
      super.location = value;
    });
  }

  late final _$minimumReturnAtom = Atom(
    name: 'ExploreStoreBase.minimumReturn',
    context: context,
  );

  @override
  int get minimumReturn {
    _$minimumReturnAtom.reportRead();
    return super.minimumReturn;
  }

  @override
  set minimumReturn(int value) {
    _$minimumReturnAtom.reportWrite(value, super.minimumReturn, () {
      super.minimumReturn = value;
    });
  }

  late final _$sortAtom = Atom(name: 'ExploreStoreBase.sort', context: context);

  @override
  ProjectSort get sort {
    _$sortAtom.reportRead();
    return super.sort;
  }

  @override
  set sort(ProjectSort value) {
    _$sortAtom.reportWrite(value, super.sort, () {
      super.sort = value;
    });
  }

  late final _$minimumInvestmentAtom = Atom(
    name: 'ExploreStoreBase.minimumInvestment',
    context: context,
  );

  @override
  int get minimumInvestment {
    _$minimumInvestmentAtom.reportRead();
    return super.minimumInvestment;
  }

  @override
  set minimumInvestment(int value) {
    _$minimumInvestmentAtom.reportWrite(value, super.minimumInvestment, () {
      super.minimumInvestment = value;
    });
  }

  late final _$maximumInvestmentAtom = Atom(
    name: 'ExploreStoreBase.maximumInvestment',
    context: context,
  );

  @override
  int get maximumInvestment {
    _$maximumInvestmentAtom.reportRead();
    return super.maximumInvestment;
  }

  @override
  set maximumInvestment(int value) {
    _$maximumInvestmentAtom.reportWrite(value, super.maximumInvestment, () {
      super.maximumInvestment = value;
    });
  }

  late final _$fundingAtom = Atom(
    name: 'ExploreStoreBase.funding',
    context: context,
  );

  @override
  Set<ProjectFundingStatus> get funding {
    _$fundingAtom.reportRead();
    return super.funding;
  }

  @override
  set funding(Set<ProjectFundingStatus> value) {
    _$fundingAtom.reportWrite(value, super.funding, () {
      super.funding = value;
    });
  }

  late final _$favouritesOnlyAtom = Atom(
    name: 'ExploreStoreBase.favouritesOnly',
    context: context,
  );

  @override
  bool get favouritesOnly {
    _$favouritesOnlyAtom.reportRead();
    return super.favouritesOnly;
  }

  @override
  set favouritesOnly(bool value) {
    _$favouritesOnlyAtom.reportWrite(value, super.favouritesOnly, () {
      super.favouritesOnly = value;
    });
  }

  late final _$favouritesAtom = Atom(
    name: 'ExploreStoreBase.favourites',
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

  late final _$recentSearchesAtom = Atom(
    name: 'ExploreStoreBase.recentSearches',
    context: context,
  );

  @override
  List<String> get recentSearches {
    _$recentSearchesAtom.reportRead();
    return super.recentSearches;
  }

  @override
  set recentSearches(List<String> value) {
    _$recentSearchesAtom.reportWrite(value, super.recentSearches, () {
      super.recentSearches = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'ExploreStoreBase.load',
    context: context,
  );

  @override
  Future<void> load() {
    return _$loadAsyncAction.run(() => super.load());
  }

  late final _$toggleFavouriteAsyncAction = AsyncAction(
    'ExploreStoreBase.toggleFavourite',
    context: context,
  );

  @override
  Future<void> toggleFavourite(String id) {
    return _$toggleFavouriteAsyncAction.run(() => super.toggleFavourite(id));
  }

  late final _$ExploreStoreBaseActionController = ActionController(
    name: 'ExploreStoreBase',
    context: context,
  );

  @override
  void search(String value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.search',
    );
    try {
      return super.search(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void submitSearch() {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.submitSearch',
    );
    try {
      return super.submitSearch();
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectCategory(ProjectCategory? value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.selectCategory',
    );
    try {
      return super.selectCategory(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLocation(String value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.setLocation',
    );
    try {
      return super.setLocation(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setReturn(int value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.setReturn',
    );
    try {
      return super.setReturn(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSort(ProjectSort value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.setSort',
    );
    try {
      return super.setSort(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setInvestmentRange(int minimum, int maximum) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.setInvestmentRange',
    );
    try {
      return super.setInvestmentRange(minimum, maximum);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleFunding(ProjectFundingStatus value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.toggleFunding',
    );
    try {
      return super.toggleFunding(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyFilter(ProjectFilter value) {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.applyFilter',
    );
    try {
      return super.applyFilter(value);
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleFavourites() {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.toggleFavourites',
    );
    try {
      return super.toggleFavourites();
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetFilters() {
    final _$actionInfo = _$ExploreStoreBaseActionController.startAction(
      name: 'ExploreStoreBase.resetFilters',
    );
    try {
      return super.resetFilters();
    } finally {
      _$ExploreStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
projects: ${projects},
error: ${error},
query: ${query},
category: ${category},
location: ${location},
minimumReturn: ${minimumReturn},
sort: ${sort},
minimumInvestment: ${minimumInvestment},
maximumInvestment: ${maximumInvestment},
funding: ${funding},
favouritesOnly: ${favouritesOnly},
favourites: ${favourites},
recentSearches: ${recentSearches},
suggestedResults: ${suggestedResults},
filter: ${filter},
results: ${results}
    ''';
  }
}
