import 'dart:async';

import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_project.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class ApiInvestorCatalogRepository implements InvestorCatalogRepository {
  ApiInvestorCatalogRepository(this._client, this._context) {
    _load();
  }

  final ApiClient _client;
  final InvestorAccountContext _context;
  final _changes = StreamController<void>.broadcast();
  final Map<String, InvestorProject> _projects = {};
  final Set<String> _favourites = {};
  final List<String> _searches = [];
  DateTime _asOf = DateTime.now().toUtc();

  EntityType get _entity => _context.entity;

  Future<void> _load() async {
    final projects = await _client.request<List<Object?>>(
      path: '/v1/catalog/projects',
      decode: (json) => (json as List<dynamic>? ?? const []).cast<Object?>(),
    );
    if (projects case Success(:final value)) {
      _projects
        ..clear()
        ..addEntries(
          value.map((raw) {
            final project = _mapProject(raw);
            return MapEntry(project.id, project);
          }),
        );
      _asOf = DateTime.now().toUtc();
      _changes.add(null);
    }
    final favs = await _client.request<List<Object?>>(
      path: '/v1/catalog/favourites',
      query: {'entity': _entity.name},
      decode: (json) => (json as List<dynamic>? ?? const []).cast<Object?>(),
    );
    if (favs case Success(:final value)) {
      _favourites
        ..clear()
        ..addAll(value.map((e) => e.toString()));
      _changes.add(null);
    }
    final searches = await _client.request<List<Object?>>(
      path: '/v1/catalog/searches',
      decode: (json) => (json as List<dynamic>? ?? const []).cast<Object?>(),
    );
    if (searches case Success(:final value)) {
      _searches
        ..clear()
        ..addAll(value.map((e) => e.toString()));
    }
  }

  InvestorProject _mapProject(Object? json, {bool favourite = false}) {
    final map = json as Map<String, Object?>? ?? const {};
    final capacity = (map['capacityCents'] as num?)?.toInt() ?? 0;
    final funded = (map['fundedCents'] as num?)?.toInt() ?? 0;
    final remaining = (map['remainingCents'] as num?)?.toInt() ??
        (capacity - funded).clamp(0, capacity);
    final id = map['id'] as String? ?? '';
    final description = map['description'] as String? ?? '';
    final developerName = map['developer'] as String? ?? 'Developify Projects';
    return InvestorProject(
      id: id,
      name: map['name'] as String? ?? '',
      city: map['town'] as String? ?? '',
      country: 'South Africa',
      area: map['town'] as String? ?? '',
      category: ProjectCategory.residential,
      imageAsset: AppAssets.investorProjectHero,
      target: MonetaryAmount(capacity, Currency.zar),
      maximumInvestment: MonetaryAmount(
        remaining.clamp(InvestmentPolicy.minimum.minorUnits, capacity),
        Currency.zar,
      ),
      annualReturnBasisPoints: (map['annualRateBps'] as num?)?.toInt() ?? 0,
      durationMonths: (map['termMonths'] as num?)?.toInt() ??
          InvestmentPolicy.termMonths,
      raised: MonetaryAmount(funded, Currency.zar),
      acceptingInvestments: map['status'] == 'open',
      description: description,
      developer: developerName,
      isFavourite: favourite || _favourites.contains(id),
      publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? ''),
      content: _mapContent(map['content'], description, developerName),
    );
  }

  InvestorProjectContent? _mapContent(
    Object? raw,
    String description,
    String developerName,
  ) {
    if (raw is! Map) return null;
    final map = Map<String, Object?>.from(raw);
    final developerRaw = map['developer'];
    final developerMap = developerRaw is Map
        ? Map<String, Object?>.from(developerRaw)
        : null;
    final name = developerMap?['name'] as String? ??
        (developerRaw is String ? developerRaw : developerName);
    final locationRaw = map['location'];
    final locationMap = locationRaw is Map
        ? Map<String, Object?>.from(locationRaw)
        : null;
    final plansRaw = map['plans'];
    final documentsRaw = map['documents'];
    final updatesRaw = map['updates'];
    final factsRaw = map['facts'];
    return InvestorProjectContent(
      description: map['description'] as String? ?? description,
      facts: {
        if (factsRaw is Map)
          for (final entry in factsRaw.entries)
            '${entry.key}': '${entry.value}',
      },
      developer: InvestorDeveloperProfile(
        name: name,
        initials: developerMap?['initials'] as String? ??
            (name.isEmpty ? 'DP' : name[0].toUpperCase()),
        description: developerMap?['description'] as String? ?? '',
        completedProjects:
            (developerMap?['completedProjects'] as num?)?.toInt() ?? 0,
        returnBasisPoints:
            (developerMap?['returnBasisPoints'] as num?)?.toInt() ?? 0,
        onTimePercent: (developerMap?['onTimePercent'] as num?)?.toInt() ?? 0,
        ratingTenths: (developerMap?['ratingTenths'] as num?)?.toInt() ?? 0,
        pastProjectIds: [
          if (developerMap?['pastProjectIds'] is List)
            for (final id in developerMap!['pastProjectIds'] as List)
              id.toString(),
        ],
      ),
      updates: [
        if (updatesRaw is List)
          for (final item in updatesRaw)
            if (item is Map)
              InvestorProjectUpdate(
                id: item['id'] as String? ?? '',
                title: item['title'] as String? ?? '',
                message: item['message'] as String? ?? '',
                imageAsset: item['imageAsset'] as String? ??
                    AppAssets.investorUpdatePlanning,
                publishedAt:
                    DateTime.tryParse(item['publishedAt'] as String? ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
                events: [
                  if (item['events'] is List)
                    for (final event in item['events'] as List)
                      if (event is Map)
                        InvestorProjectEvent(
                          title: event['title'] as String? ?? '',
                          message: event['message'] as String? ?? '',
                          occurredAt: DateTime.tryParse(
                                event['occurredAt'] as String? ?? '',
                              ) ??
                              DateTime.fromMillisecondsSinceEpoch(
                                0,
                                isUtc: true,
                              ),
                        ),
                ],
              ),
      ],
      documents: [
        if (documentsRaw is List)
          for (final item in documentsRaw)
            if (item is Map)
              InvestorProjectDocument(
                id: item['id'] as String? ?? '',
                name: item['name'] as String? ?? '',
              ),
      ],
      location: locationMap == null
          ? null
          : InvestorProjectLocation(
              address: locationMap['address'] as String? ?? '',
              city: locationMap['city'] as String? ?? '',
              region: locationMap['region'] as String? ?? '',
              country: locationMap['country'] as String? ?? '',
              mapAsset: locationMap['mapAsset'] as String? ?? AppAssets.siteMap,
              linkUrl: locationMap['linkUrl'] as String? ?? '',
              linkLabel: locationMap['linkLabel'] as String? ?? 'Open in Maps',
            ),
      plans: [
        if (plansRaw is List)
          for (final item in plansRaw)
            if (item is Map)
              InvestorProjectPlan(
                id: item['id'] as String? ?? '',
                title: item['title'] as String? ?? '',
                description: item['description'] as String? ?? '',
                imageAsset: item['imageAsset'] as String? ??
                    AppAssets.investorUpdatePlanning,
              ),
      ],
    );
  }

  @override
  DateTime get asOf => _asOf;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<Result<List<InvestorProject>>> projects() async {
    await _load();
    final list = _projects.values
        .map((p) => p.isFavourite == _favourites.contains(p.id)
            ? p
            : InvestorProject(
                id: p.id,
                name: p.name,
                city: p.city,
                country: p.country,
                area: p.area,
                category: p.category,
                imageAsset: p.imageAsset,
                target: p.target,
                maximumInvestment: p.maximumInvestment,
                annualReturnBasisPoints: p.annualReturnBasisPoints,
                durationMonths: p.durationMonths,
                raised: p.raised,
                acceptingInvestments: p.acceptingInvestments,
                description: p.description,
                developer: p.developer,
                isFavourite: _favourites.contains(p.id),
                publishedAt: p.publishedAt,
                content: p.content,
              ))
        .toList();
    return Success(list);
  }

  @override
  Future<Result<InvestorProject>> project(String id) async {
    final result = await _client.request(
      path: '/v1/catalog/projects/$id',
      decode: (json) =>
          _mapProject(json, favourite: _favourites.contains(id)),
    );
    if (result case Success(:final value)) {
      _projects[id] = value;
    }
    return result;
  }

  @override
  Set<String> get favouriteIds => Set.unmodifiable(_favourites);

  @override
  List<String> get recentSearches => List.unmodifiable(_searches);

  @override
  List<String> get suggestedProjectIds =>
      _projects.values.take(3).map((p) => p.id).toList();

  @override
  void rememberSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _searches.remove(q);
    _searches.insert(0, q);
    if (_searches.length > 10) _searches.removeLast();
    _client.request(
      path: '/v1/catalog/searches',
      method: 'POST',
      data: {'query': q},
      decode: (_) {},
    );
  }

  @override
  Future<Result<void>> setFavourite(String id, bool favourite) async {
    final result = await _client.request(
      path: '/v1/catalog/favourites',
      method: 'POST',
      data: {
        'projectId': id,
        'favourite': favourite,
        'entity': _entity.name,
      },
      decode: (_) {},
    );
    if (result.isSuccess) {
      if (favourite) {
        _favourites.add(id);
      } else {
        _favourites.remove(id);
      }
      _changes.add(null);
    }
    return result;
  }

  @override
  InvestorProject? currentProject(String id) => _projects[id];

  @override
  Result<void> contribute(String id, MonetaryAmount amount) {
    // Capacity is owned by the server after invest; local cache refreshed on load.
    final project = _projects[id];
    if (project?.raised != null) {
      _projects[id] = project!.withFunding(
        raised: MonetaryAmount(
          project.raised!.minorUnits + amount.minorUnits,
          Currency.zar,
        ),
      );
      _changes.add(null);
    }
    return const Success(null);
  }

  @override
  void dispose() {
    _changes.close();
  }
}
