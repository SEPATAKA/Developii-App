import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'dart:async';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_project_content.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class MockInvestorCatalogRepository implements InvestorCatalogRepository {
  MockInvestorCatalogRepository(
    this.behavior,
    this._context, {
    this.scenario = MockScenario.success,
  }) {
    _userId = _context.scope?.userId;
    _subscription = _context.changes.listen((scope) {
      for (final request in _pending.toList()) {
        request.cancel();
      }
      if (scope?.userId != _userId) {
        _favourites.clear();
        _confirmedFavourites.clear();
        _confirmedVersions.clear();
        _favouriteVersions.clear();
        _searchHistory.clear();
        _userId = scope?.userId;
      }
      _changes.add(null);
    });
  }
  final MockBehavior behavior;
  final MockScenario scenario;
  final InvestorAccountContext _context;
  @override
  DateTime get asOf => DateTime.utc(2026, 6, 7);
  final _changes = StreamController<void>.broadcast(sync: true);
  final _favourites = <EntityType, Set<String>>{};
  final _searchHistory = <EntityType, List<String>>{};
  final _pending = <Cancellation>{};
  final _favouriteVersions = <String, int>{};
  final _confirmedFavourites = <String, bool>{};
  final _confirmedVersions = <String, int>{};
  late final StreamSubscription<InvestorScope?> _subscription;
  String? _userId;
  bool _disposed = false;
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Set<String> get favouriteIds =>
      Set.unmodifiable(_favourites[_context.entity] ?? const <String>{});

  @override
  List<String> get recentSearches => List.unmodifiable(
    _searchHistory[_context.entity] ??
        const [
          'Cape Town',
          'Durban',
          'Hospitality',
          r'UnderR1k',
          'Residential',
        ],
  );

  @override
  List<String> get suggestedProjectIds => const [
    'marula-heights',
    'lissana-villa',
    'saffron-hospitality',
  ];

  @override
  void rememberSearch(String query) {
    if (_disposed || _context.scope == null) return;
    final value = query.trim();
    if (value.isEmpty || value.length > 120) return;
    _searchHistory[_context.entity] = [
      value,
      ...recentSearches.where(
        (item) => item.toLowerCase() != value.toLowerCase(),
      ),
    ].take(5).toList(growable: false);
    _changes.add(null);
  }

  Future<Result<T>> _read<T>(T Function() read) async {
    final scope = _context.scope;
    if (_disposed || scope == null) {
      return const Failure(
        AppFailure(FailureKind.unauthenticated, 'Sign in to continue.'),
      );
    }
    final cancellation = Cancellation();
    _pending.add(cancellation);
    try {
      final result = await behavior.run(read, cancellation: cancellation);
      if (!_context.isCurrent(scope)) {
        return const Failure(
          AppFailure(FailureKind.cancelled, 'The selected profile changed.'),
        );
      }
      return result;
    } finally {
      _pending.remove(cancellation);
    }
  }

  @override
  Future<Result<List<InvestorProject>>> projects() => _read(
    () => behavior.empty || scenario == MockScenario.noProjects
        ? const []
        : List.unmodifiable(_projects),
  );

  @override
  Future<Result<InvestorProject>> project(String id) async {
    final result = await _read(
      () => _projects.where((project) => project.id == id).firstOrNull,
    );
    return switch (result) {
      Success(:final value)
          when value != null && scenario != MockScenario.missingItem =>
        Success(value),
      Failure(:final error) => Failure(error),
      _ => const Failure(
        AppFailure(FailureKind.notFound, 'This project could not be found.'),
      ),
    };
  }

  @override
  Future<Result<void>> setFavourite(String id, bool favourite) async {
    if (!_projects.any((project) => project.id == id)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This project could not be found.'),
      );
    }
    final scope = _context.scope;
    if (scope == null) {
      return const Failure(
        AppFailure(FailureKind.unauthenticated, 'Sign in to continue.'),
      );
    }
    final key = '${scope.userId}:${scope.entity.name}:$id';
    final version = (_favouriteVersions[key] ?? 0) + 1;
    _favouriteVersions[key] = version;
    final ids = _favourites.putIfAbsent(scope.entity, () => {});
    _confirmedFavourites.putIfAbsent(key, () => ids.contains(id));
    favourite ? ids.add(id) : ids.remove(id);
    _changes.add(null);
    final result = await _read<void>(() {});
    if (!_disposed &&
        _context.isCurrent(scope) &&
        result.isSuccess &&
        version > (_confirmedVersions[key] ?? 0)) {
      _confirmedVersions[key] = version;
      _confirmedFavourites[key] = favourite;
    }
    if (!_disposed &&
        scope.userId == _userId &&
        _favouriteVersions[key] == version &&
        !result.isSuccess) {
      (_confirmedFavourites[key] ?? false) ? ids.add(id) : ids.remove(id);
      if (_context.isCurrent(scope)) _changes.add(null);
    }
    return result;
  }

  @override
  InvestorProject? currentProject(String id) =>
      scenario == MockScenario.missingItem
      ? null
      : _projects.where((p) => p.id == id).firstOrNull;

  @override
  Result<void> contribute(String id, MonetaryAmount amount) {
    final project = currentProject(id);
    if (_disposed || _context.scope == null) {
      return const Failure(
        AppFailure(FailureKind.unauthenticated, 'Sign in to continue.'),
      );
    }
    if (project == null) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This project could not be found.'),
      );
    }
    final error = project.validateInvestment(amount);
    if (error != null) {
      return Failure(AppFailure(FailureKind.validation, error));
    }
    _projects[_projects.indexOf(project)] = project.withFunding(
      raised: project.raised! + amount,
    );
    _changes.add(null);
    return const Success(null);
  }

  void simulateFunding(
    String id,
    MonetaryAmount? raised, {
    bool? acceptingInvestments,
  }) {
    final project = currentProject(id);
    if (_disposed || project == null) return;
    _projects[_projects.indexOf(project)] = project.withFunding(
      raised: raised,
      acceptingInvestments: acceptingInvestments,
    );
    _changes.add(null);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final request in _pending.toList()) {
      request.cancel();
    }
    unawaited(_subscription.cancel());
    _favourites.clear();
    _searchHistory.clear();
    unawaited(_changes.close());
  }

  final _projects = <InvestorProject>[
    _project(
      'marula-heights',
      'Marula Heights',
      'Lagos',
      'Nigeria',
      'Lekki Phase 2',
      ProjectCategory.residential,
      AppAssets.projectMarulaHeights,
      target: 240000000,
      exploreOrder: 3,
      thumbnail: AppAssets.projectSaffronResidenceThumbnail,
    ),
    _project(
      'saffron-towers',
      'Saffron Towers',
      'Capetown',
      'South Africa',
      'Northlands',
      ProjectCategory.residential,
      AppAssets.projectSaffronTowers,
      thumbnail: AppAssets.projectSaffronResidenceThumbnail,
      hero: AppAssets.investorProjectHero,
      roi: 1450,
      target: 240000000,
      closesAt: DateTime.utc(2026, 8, 30),
      exploreOrder: 0,
    ),
    _project(
      'saffron-hospitality',
      'Saffron Towers',
      'Capetown',
      'South Africa',
      'Northlands',
      ProjectCategory.hospitality,
      AppAssets.investorProjectHero,
      thumbnail: AppAssets.projectSaffronResortThumbnail,
      hero: AppAssets.investorProjectHero,
      roi: 1140,
      exploreOrder: 1,
    ),
    _project(
      'coastline-villas',
      'Coastline Villas',
      'Accra',
      'Ghana',
      'Accra',
      ProjectCategory.commercial,
      AppAssets.projectCoastlineVillas,
      fullyFunded: true,
      exploreOrder: 2,
    ),
    _project(
      'azure-bay',
      'Azure Bay Resort',
      'Lagos',
      'Nigeria',
      'Lekki Phase 2',
      ProjectCategory.hospitality,
      AppAssets.projectMarulaHeights,
      target: 240000000,
      publishedAt: DateTime.utc(2026, 6, 6),
      exploreOrder: 4,
    ),
    _project(
      'lissana-villa',
      'Lissana Villa',
      'Capetown',
      'South Africa',
      'Northlands',
      ProjectCategory.residential,
      AppAssets.projectLissanaVilla,
      roi: 1570,
      exploreOrder: 5,
    ),
  ];

  static InvestorProject _project(
    String id,
    String name,
    String city,
    String country,
    String area,
    ProjectCategory category,
    String image, {
    int target = 75000000,
    int roi = 1450,
    bool fullyFunded = false,
    String? thumbnail,
    String? hero,
    DateTime? publishedAt,
    DateTime? closesAt,
    required int exploreOrder,
  }) => InvestorProject(
    id: id,
    name: name,
    city: city,
    country: country,
    area: area,
    category: category,
    imageAsset: image,
    thumbnailAsset: thumbnail,
    heroAsset: hero,
    publishedAt: publishedAt,
    closesAt: closesAt,
    exploreOrder: exploreOrder,
    content: id == 'saffron-towers' || id == 'marula-heights'
        ? createMockProjectContent(id)
        : null,
    target: MonetaryAmount(target, Currency.zar),

    maximumInvestment: const MonetaryAmount(25000000, Currency.zar),
    annualReturnBasisPoints: roi,
    durationMonths: InvestmentPolicy.termMonths,
    raised: MonetaryAmount(
      fullyFunded ? target : target * 65 ~/ 100,
      Currency.zar,
    ),
    description: id == 'marula-heights' || id == 'saffron-towers'
        ? 'Marula Heights is a 42-unit boutique apartment complex on a leafy half-acre in Lekki Phase 2. Construction begins Q3 with handover in 18 months. All units pre-leased through a hospitality operator.'
        : 'Detailed project information is not available.',
    developer: 'Palm & Brick Capital',
  );
}
