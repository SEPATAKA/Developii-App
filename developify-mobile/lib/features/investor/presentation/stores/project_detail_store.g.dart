// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_detail_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InvestorProjectDetailStore on InvestorProjectDetailStoreBase, Store {
  late final _$statusAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.status',
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

  late final _$projectAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.project',
    context: context,
  );

  @override
  InvestorProject? get project {
    _$projectAtom.reportRead();
    return super.project;
  }

  @override
  set project(InvestorProject? value) {
    _$projectAtom.reportWrite(value, super.project, () {
      super.project = value;
    });
  }

  late final _$investmentAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.investment',
    context: context,
  );

  @override
  InvestorInvestment? get investment {
    _$investmentAtom.reportRead();
    return super.investment;
  }

  @override
  set investment(InvestorInvestment? value) {
    _$investmentAtom.reportWrite(value, super.investment, () {
      super.investment = value;
    });
  }

  late final _$relatedProjectsAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.relatedProjects',
    context: context,
  );

  @override
  List<InvestorProject> get relatedProjects {
    _$relatedProjectsAtom.reportRead();
    return super.relatedProjects;
  }

  @override
  set relatedProjects(List<InvestorProject> value) {
    _$relatedProjectsAtom.reportWrite(value, super.relatedProjects, () {
      super.relatedProjects = value;
    });
  }

  late final _$errorAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.error',
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

  late final _$favouriteAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.favourite',
    context: context,
  );

  @override
  bool get favourite {
    _$favouriteAtom.reportRead();
    return super.favourite;
  }

  @override
  set favourite(bool value) {
    _$favouriteAtom.reportWrite(value, super.favourite, () {
      super.favourite = value;
    });
  }

  late final _$tabAtom = Atom(
    name: 'InvestorProjectDetailStoreBase.tab',
    context: context,
  );

  @override
  int get tab {
    _$tabAtom.reportRead();
    return super.tab;
  }

  @override
  set tab(int value) {
    _$tabAtom.reportWrite(value, super.tab, () {
      super.tab = value;
    });
  }

  late final _$loadAsyncAction = AsyncAction(
    'InvestorProjectDetailStoreBase.load',
    context: context,
  );

  @override
  Future<void> load(String id, {bool includeRelated = false}) {
    return _$loadAsyncAction.run(
      () => super.load(id, includeRelated: includeRelated),
    );
  }

  late final _$loadInvestmentAsyncAction = AsyncAction(
    'InvestorProjectDetailStoreBase.loadInvestment',
    context: context,
  );

  @override
  Future<void> loadInvestment(String id) {
    return _$loadInvestmentAsyncAction.run(() => super.loadInvestment(id));
  }

  late final _$toggleFavouriteAsyncAction = AsyncAction(
    'InvestorProjectDetailStoreBase.toggleFavourite',
    context: context,
  );

  @override
  Future<void> toggleFavourite() {
    return _$toggleFavouriteAsyncAction.run(() => super.toggleFavourite());
  }

  late final _$InvestorProjectDetailStoreBaseActionController =
      ActionController(
        name: 'InvestorProjectDetailStoreBase',
        context: context,
      );

  @override
  void selectTab(int value) {
    final _$actionInfo = _$InvestorProjectDetailStoreBaseActionController
        .startAction(name: 'InvestorProjectDetailStoreBase.selectTab');
    try {
      return super.selectTab(value);
    } finally {
      _$InvestorProjectDetailStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
project: ${project},
investment: ${investment},
relatedProjects: ${relatedProjects},
error: ${error},
favourite: ${favourite},
tab: ${tab}
    ''';
  }
}
