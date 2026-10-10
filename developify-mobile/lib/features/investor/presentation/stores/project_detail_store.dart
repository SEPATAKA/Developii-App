import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'project_detail_store.g.dart';

class InvestorProjectDetailStore = InvestorProjectDetailStoreBase
    with _$InvestorProjectDetailStore;

abstract class InvestorProjectDetailStoreBase with Store, Lifecycle {
  InvestorProjectDetailStoreBase(this._repository, this._accounts) {
    _changes = _repository.changes.listen((_) {
      if (!isDisposed) {
        runInAction(() {
          favourite = _repository.favouriteIds.contains(project?.id);
          if (project != null) {
            project = _repository.currentProject(project!.id);
          }
        });
      }
    });
    _accountChanges = _accounts.changes.listen((event) {
      final id = _investmentId;
      if (isDisposed ||
          id == null ||
          !event.affects(InvestorDataKind.portfolio)) {
        return;
      }
      if (event.kinds.contains(InvestorDataKind.scope)) {
        runInAction(() {
          investment = null;
          project = null;
          tab = 0;
        });
      }
      unawaited(loadInvestment(id));
    });
  }
  final InvestorCatalogRepository _repository;
  final InvestorAccountRepository _accounts;
  late final StreamSubscription<void> _changes;
  late final StreamSubscription<InvestorAccountChange> _accountChanges;
  String? _investmentId;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  InvestorProject? project;
  @observable
  InvestorInvestment? investment;
  @observable
  List<InvestorProject> relatedProjects = const [];
  @observable
  String? error;
  @observable
  bool favourite = false;
  @observable
  int tab = 0;
  /// Project section tabs: Overview(0)–Plans(5), Documents(6) when included.
  static const maxSectionTab = 6;

  @action
  void selectTab(int value) {
    if (value >= 0 && value <= maxSectionTab) tab = value;
  }

  @action
  Future<void> load(String id, {bool includeRelated = false}) async {
    if (isDisposed) return;
    final request = beginRequest();
    _investmentId = null;
    investment = null;
    tab = 0;
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.project(id);
    if (!isCurrent(request)) return;
    final related = includeRelated && result.isSuccess
        ? await _repository.projects()
        : null;
    if (!isCurrent(request)) return;
    if (related case Failure(:final error)) {
      runInAction(() {
        this.error = error.message;
        status = LoadStatus.error;
      });
      return;
    }
    runInAction(() {
      switch (result) {
        case Success(:final value):
          project = value;
          relatedProjects = related is Success<List<InvestorProject>>
              ? related.value
              : const [];
          favourite = _repository.favouriteIds.contains(id);
          status = LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<void> loadInvestment(String id) async {
    if (isDisposed) return;
    final request = beginRequest();
    if (_investmentId != id) tab = 0;
    _investmentId = id;
    status = LoadStatus.loading;
    error = null;
    project = null;
    investment = null;
    final account = await _accounts.snapshot();
    if (!isCurrent(request)) return;
    if (account case Failure(:final error)) {
      this.error = error.message;
      status = LoadStatus.error;
      return;
    }
    final holding = (account as Success<InvestorAccountSnapshot>)
        .value
        .investments
        .where((item) => item.id == id)
        .firstOrNull;
    if (holding == null) {
      error = 'This investment could not be found.';
      status = LoadStatus.error;
      return;
    }
    final result = await _repository.project(holding.projectId);
    if (!isCurrent(request)) return;
    switch (result) {
      case Success(:final value):
        project = value;
        investment = holding;
        favourite = _repository.favouriteIds.contains(value.id);
        status = LoadStatus.success;
      case Failure(:final error):
        this.error = error.message;
        status = LoadStatus.error;
    }
  }

  @action
  Future<void> toggleFavourite() async {
    final projectId = project?.id;
    if (projectId == null || isDisposed) return;
    final result = await _repository.setFavourite(projectId, !favourite);
    if (isDisposed || project?.id != projectId) return;
    runInAction(() {
      if (result case Failure(
        :final error,
      ) when error.kind != FailureKind.cancelled) {
        this.error = error.message;
      } else {
        favourite = _repository.favouriteIds.contains(projectId);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    unawaited(_accountChanges.cancel());
    super.dispose();
  }
}
