import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'dart:async';
import 'package:mobx/mobx.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/utils/lifecycle.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
part 'explore_store.g.dart';

class ExploreStore = ExploreStoreBase with _$ExploreStore;

abstract class ExploreStoreBase with Store, Lifecycle {
  ExploreStoreBase(this._repository) {
    _changes = _repository.changes.listen((_) {
      if (!isDisposed) {
        runInAction(() {
          favourites = _repository.favouriteIds;
          projects = projects
              .map((p) => _repository.currentProject(p.id))
              .whereType<InvestorProject>()
              .toList();
          recentSearches = _repository.recentSearches;
        });
      }
    });
  }
  final InvestorCatalogRepository _repository;
  late final StreamSubscription<void> _changes;
  @observable
  LoadStatus status = LoadStatus.initial;
  @observable
  List<InvestorProject> projects = const [];
  @observable
  String? error;
  @observable
  String query = '';
  @observable
  ProjectCategory? category;
  @observable
  String location = '';
  @observable
  int minimumReturn = 0;
  @observable
  ProjectSort sort = ProjectSort.trending;
  @observable
  int minimumInvestment = InvestmentPolicy.minimumMajorUnits;
  @observable
  int maximumInvestment = 50000;
  @observable
  Set<ProjectFundingStatus> funding = const {};
  @observable
  bool favouritesOnly = false;
  @observable
  Set<String> favourites = const {};
  @observable
  List<String> recentSearches = const [];
  @computed
  List<InvestorProject> get suggestedResults => [
    for (final id in _repository.suggestedProjectIds)
      ...projects.where((project) => project.id == id),
  ];
  @computed
  ProjectFilter get filter => ProjectFilter(
    category: category,
    location: location,
    minimumReturnBasisPoints: minimumReturn,
    sort: sort,
    minimumInvestment: minimumInvestment,
    maximumInvestment: maximumInvestment,
    funding: funding,
  );
  @computed
  List<InvestorProject> get results {
    final term = query.trim().toLowerCase().replaceAll('cape town', 'capetown');
    final underOneThousand = term.replaceAll(' ', '') == 'underr1k';
    final place = location.toLowerCase().replaceAll('cape town', 'capetown');
    final result = projects.where((project) {
      final text =
          '${project.name} ${project.city} ${project.country} ${project.category.name}'
              .toLowerCase();
      return (term.isEmpty ||
              text.contains(term) ||
              (underOneThousand &&
                  project.minimumInvestment.currency == Currency.zar &&
                  project.minimumInvestment.minorUnits < 100000)) &&
          (category == null || project.category == category) &&
          (place.isEmpty || text.contains(place)) &&
          project.annualReturnBasisPoints >= minimumReturn &&
          ((minimumInvestment == InvestmentPolicy.minimumMajorUnits &&
                  maximumInvestment == 50000) ||
              (project.minimumInvestment.currency == Currency.zar &&
                  project.minimumInvestment.minorUnits >=
                      minimumInvestment * 100 &&
                  (maximumInvestment == 50000 ||
                      project.minimumInvestment.minorUnits <=
                          maximumInvestment * 100))) &&
          (funding.isEmpty ||
              funding.any(
                (status) => switch (status) {
                  ProjectFundingStatus.open =>
                    project.fundedBasisPoints < 10000,
                  ProjectFundingStatus.targetReached =>
                    project.fundedBasisPoints >= 10000,
                  ProjectFundingStatus.newToday =>
                    project.publishedAt != null &&
                        project.publishedAt!.year == _repository.asOf.year &&
                        project.publishedAt!.month == _repository.asOf.month &&
                        project.publishedAt!.day == _repository.asOf.day,
                },
              )) &&
          (!favouritesOnly || favourites.contains(project.id));
    }).toList();
    switch (sort) {
      case ProjectSort.trending:
        result.sort((a, b) => a.exploreOrder.compareTo(b.exploreOrder));
      case ProjectSort.newest:
        result.sort(
          (a, b) =>
              _compareDates(b.publishedAt, a.publishedAt, descending: true),
        );
      case ProjectSort.closingSoon:
        result.sort((a, b) => _compareDates(a.closesAt, b.closesAt));
      case ProjectSort.returnRate:
        result.sort(
          (a, b) =>
              b.annualReturnBasisPoints.compareTo(a.annualReturnBasisPoints),
        );
      case ProjectSort.minimumInvestment:
        result.sort(
          (a, b) => a.minimumInvestment.currency == b.minimumInvestment.currency
              ? a.minimumInvestment.compareTo(b.minimumInvestment)
              : a.minimumInvestment.currency.code.compareTo(
                  b.minimumInvestment.currency.code,
                ),
        );
      case ProjectSort.fundingProgress:
        result.sort(
          (a, b) => b.fundedBasisPoints.compareTo(a.fundedBasisPoints),
        );
    }
    return result;
  }

  @action
  void search(String value) => query = value;
  @action
  void submitSearch() => _repository.rememberSearch(query);
  @action
  void selectCategory(ProjectCategory? value) => category = value;
  @action
  void setLocation(String value) => location = value;
  @action
  void setReturn(int value) => minimumReturn = value;
  @action
  void setSort(ProjectSort value) => sort = value;
  @action
  void setInvestmentRange(int minimum, int maximum) {
    minimumInvestment = minimum.clamp(
      InvestmentPolicy.minimumMajorUnits,
      50000,
    );
    maximumInvestment = maximum.clamp(minimumInvestment, 50000);
  }

  @action
  void toggleFunding(ProjectFundingStatus value) {
    funding = Set.unmodifiable(
      funding.contains(value)
          ? (Set<ProjectFundingStatus>.of(funding)..remove(value))
          : {...funding, value},
    );
  }

  @action
  void applyFilter(ProjectFilter value) {
    category = value.category;
    location = value.location;
    minimumReturn = value.minimumReturnBasisPoints;
    minimumInvestment = value.minimumInvestment;
    maximumInvestment = value.maximumInvestment;
    funding = value.funding;
    sort = value.sort;
  }

  @action
  void toggleFavourites() => favouritesOnly = !favouritesOnly;
  @action
  void resetFilters() {
    category = null;
    location = '';
    minimumReturn = 0;
    sort = ProjectSort.trending;
    minimumInvestment = InvestmentPolicy.minimumMajorUnits;
    maximumInvestment = 50000;
    funding = const {};
    favouritesOnly = false;
  }

  @action
  Future<void> load() async {
    if (isDisposed) return;
    final request = beginRequest();
    status = LoadStatus.loading;
    error = null;
    final result = await _repository.projects();
    if (!isCurrent(request)) return;
    runInAction(() {
      switch (result) {
        case Success(:final value):
          projects = value;
          favourites = _repository.favouriteIds;
          projects = projects
              .map((p) => _repository.currentProject(p.id))
              .whereType<InvestorProject>()
              .toList();
          recentSearches = _repository.recentSearches;
          status = value.isEmpty ? LoadStatus.empty : LoadStatus.success;
        case Failure(:final error):
          this.error = error.message;
          status = LoadStatus.error;
      }
    });
  }

  @action
  Future<void> toggleFavourite(String id) async {
    if (isDisposed) return;
    error = null;
    final result = await _repository.setFavourite(id, !favourites.contains(id));
    if (isDisposed) return;
    if (result case Failure(
      :final error,
    ) when error.kind != FailureKind.cancelled) {
      runInAction(() => this.error = error.message);
    }
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }

  static int _compareDates(
    DateTime? a,
    DateTime? b, {
    bool descending = false,
  }) {
    if (a == null) return b == null ? 0 : (descending ? -1 : 1);
    if (b == null) return descending ? 1 : -1;
    return a.compareTo(b);
  }
}
