import 'dart:async';

import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/features/landowner/domain/landowner_repository.dart';
import 'package:developify_mobile/features/landowner/domain/property.dart';
import 'package:developify_mobile/features/landowner/domain/submission_draft.dart';

final class ApiLandownerRepository implements LandownerRepository {
  ApiLandownerRepository(this._client);
  final ApiClient _client;
  final _changes = StreamController<void>.broadcast();
  final _balanceVisibility = StreamController<bool>.broadcast();
  final Map<String, SubmissionDraft> _drafts = {};
  bool _balanceVisible = true;

  Property _mapProperty(Object? json) {
    final map = json as Map<String, Object?>? ?? const {};
    final statusName = map['status'] as String? ?? 'draft';
    return Property(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      town: map['town'] as String? ?? '',
      status: PropertyStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => PropertyStatus.draft,
      ),
      size: map['size'] as String? ?? '',
      fundingPercent: (map['fundingPercent'] as num?)?.toInt() ?? 0,
      draftStep: (map['draftStep'] as num?)?.toInt() ?? 1,
      erf: map['erf'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  @override
  bool get balanceVisible => _balanceVisible;

  @override
  Stream<bool> get balanceVisibilityChanges => _balanceVisibility.stream;

  @override
  void setBalanceVisible(bool visible) {
    _balanceVisible = visible;
    _balanceVisibility.add(visible);
  }

  @override
  void clearSession() {
    _drafts.clear();
  }

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> dispose() async {
    await _changes.close();
    await _balanceVisibility.close();
  }

  @override
  Future<Result<LandownerOverview>> overview() {
    return _client.request(
      path: '/v1/landowner/overview',
      decode: (json) {
        final map = json as Map<String, Object?>? ?? const {};
        final properties = ((map['properties'] as List<dynamic>?) ?? const [])
            .map(_mapProperty)
            .toList();
        return LandownerOverview(
          properties: properties,
          earnedCents: (map['earnedCents'] as num?)?.toInt() ?? 0,
          propertyCount: (map['propertyCount'] as num?)?.toInt() ?? properties.length,
          approvedCount: (map['approvedCount'] as num?)?.toInt() ?? 0,
          nextPayoutCents: (map['nextPayoutCents'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }

  @override
  Future<Result<List<Property>>> properties() {
    return _client.request(
      path: '/v1/landowner/properties',
      decode: (json) =>
          ((json as List<dynamic>?) ?? const []).map(_mapProperty).toList(),
    );
  }

  @override
  Future<Result<Property>> property(String id) {
    return _client.request(
      path: '/v1/landowner/properties/$id',
      decode: _mapProperty,
    );
  }

  @override
  Future<Result<EarningsSummary>> earnings() {
    return _client.request(
      path: '/v1/landowner/earnings',
      decode: (json) {
        final map = json as Map<String, Object?>? ?? const {};
        final payouts = ((map['payouts'] as List<dynamic>?) ?? const []).map((
          raw,
        ) {
          final p = raw as Map<String, Object?>? ?? const {};
          return Payout(
            id: p['id'] as String? ?? '',
            propertyName: p['propertyName'] as String? ?? '',
            amountCents: (p['amountCents'] as num?)?.toInt() ?? 0,
            period: p['period'] as String? ?? '',
            date: p['date'] as String? ?? '',
          );
        }).toList();
        return EarningsSummary(
          payouts: payouts,
          totalCents: (map['totalCents'] as num?)?.toInt() ?? 0,
          nextPayoutCents: (map['nextPayoutCents'] as num?)?.toInt() ?? 0,
        );
      },
    );
  }

  @override
  SubmissionDraft readDraft(String id) {
    return _drafts[id] ?? SubmissionDraft(id: id);
  }

  @override
  void saveDraft(SubmissionDraft draft) {
    _drafts[draft.id] = draft;
    unawaited(
      _client.request(
        path: '/v1/landowner/drafts/${draft.id}',
        method: 'PUT',
        data: {
          'step': draft.step,
          'payload': {
            'name': draft.name,
            'number': draft.propertyNumber,
            'type': draft.propertyType,
            'size': draft.size,
            'unit': draft.unit,
            'address': draft.address,
            'city': draft.city,
            'town': draft.town,
            'country': draft.country,
            'province': draft.province,
            'postal': draft.postalCode,
            'notes': draft.notes,
            'price': draft.price,
            'erf': draft.propertyNumber,
          },
        },
        decode: (_) {},
      ),
    );
  }

  @override
  Future<Result<String>> submit(SubmissionDraft draft) async {
    saveDraft(draft);
    final result = await _client.request<Object?>(
      path: '/v1/landowner/submit',
      method: 'POST',
      data: {'draftKey': draft.id},
      decode: (json) => json,
    );
    if (result case Success(:final value)) {
      _changes.add(null);
      return Success(
        (value as Map<String, Object?>)['propertyId'] as String? ?? '',
      );
    }
    return result as Failure<String>;
  }
}
