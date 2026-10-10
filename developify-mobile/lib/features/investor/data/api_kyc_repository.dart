import 'dart:async';

import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/network/api_client.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

/// Live KYC adapter. Sync `save*` methods update a local cache and enqueue
/// persistence so store APIs stay unchanged.
final class ApiKycRepository implements KycRepository {
  ApiKycRepository(this._client);
  final ApiClient _client;
  final _changes = StreamController<KycChange>.broadcast();
  final Map<EntityType, KycDraft> _drafts = {};

  @override
  Stream<KycChange> get changes => _changes.stream;

  KycDraft _mapDraft(Object? json, EntityType entity) {
    final map = json as Map<String, Object?>? ?? const {};
    final fields = map['fields'];
    final values = <String, String>{};
    if (fields is Map) {
      for (final entry in fields.entries) {
        values['${entry.key}'] = '${entry.value}';
      }
    }
    final statusName = map['status'] as String? ?? 'incomplete';
    final documents = <String, KycDocument>{};
    for (final raw in (map['documents'] as List<dynamic>? ?? const [])) {
      final doc = raw as Map<String, Object?>? ?? const {};
      final key = doc['key'] as String? ?? 'document';
      documents[key] = KycDocument(
        id: doc['id'] as String? ?? key,
        name: doc['name'] as String? ?? key,
        mimeType: doc['mimeType'] as String? ?? 'application/octet-stream',
        bytes: (doc['sizeBytes'] as num?)?.toInt() ?? 0,
        uploadedAt: DateTime.now().toUtc(),
      );
    }
    return KycDraft(
      entity: entity,
      values: values,
      documents: documents,
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => VerificationStatus.incomplete,
      ),
      submissionId: map['id'] as String?,
      correction: map['reviewNote'] as String?,
    );
  }

  Future<void> _persist(EntityType entity, KycDraft draft) async {
    await _client.request(
      path: '/v1/kyc/${entity.name}',
      method: 'PUT',
      data: {'fields': draft.values},
      decode: (_) {},
    );
  }

  @override
  Future<Result<KycDraft>> load(EntityType entity) async {
    final result = await _client.request(
      path: '/v1/kyc/${entity.name}',
      decode: (json) => _mapDraft(json, entity),
    );
    if (result case Success(:final value)) {
      _drafts[entity] = value;
      _changes.add(KycChange(entity));
    }
    return result;
  }

  @override
  Result<KycDraft> save(KycDraft draft) {
    _drafts[draft.entity] = draft;
    unawaited(_persist(draft.entity, draft));
    _changes.add(KycChange(draft.entity));
    return Success(draft);
  }

  @override
  Future<Result<KycDraft>> upload(
    EntityType entity,
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
    Cancellation? cancellation,
    bool append = false,
    String? documentId,
  }) async {
    final presign = await _client.request<Object?>(
      path: '/v1/documents/presign',
      method: 'POST',
      data: {
        'name': name,
        'mimeType': mimeType,
        'prefix': 'kyc/${entity.name}',
      },
      decode: (json) => json,
    );
    if (presign is Failure) return Failure((presign as Failure).error);
    final storageKey =
        ((presign as Success).value as Map)['storageKey'] as String? ?? name;
    final result = await _client.request(
      path: '/v1/kyc/${entity.name}/documents',
      method: 'POST',
      data: {
        'key': key,
        'name': name,
        'mimeType': mimeType,
        'sizeBytes': bytes,
        'storageKey': storageKey,
      },
      decode: (json) => _mapDraft(json, entity),
    );
    if (result case Success(:final value)) {
      _drafts[entity] = value;
      _changes.add(KycChange(entity));
    }
    return result;
  }

  @override
  Result<KycDraft> deleteDocument(
    EntityType entity,
    String key, {
    String? documentId,
  }) {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    final docs = Map<String, KycDocument>.from(current.documents)..remove(key);
    final next = current.copyWith(documents: docs);
    return save(next);
  }

  @override
  Result<KycDraft> saveMember(EntityType entity, KycMember member) {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    final members = [...current.members.where((m) => m.id != member.id), member];
    return save(current.copyWith(members: members));
  }

  @override
  Result<KycDraft> saveAllocations(
    EntityType entity,
    KycMemberRole role,
    Map<String, int> allocations,
  ) {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    final members = current.members
        .map(
          (m) => m.role == role && allocations.containsKey(m.id)
              ? m.copyWith(shareBasisPoints: allocations[m.id])
              : m,
        )
        .toList();
    return save(current.copyWith(members: members));
  }

  @override
  Result<KycDraft> saveMemberDraft(
    EntityType entity,
    String key,
    KycMemberDraft draft,
  ) {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    final drafts = Map<String, KycMemberDraft>.from(current.memberDrafts)
      ..[key] = draft;
    return save(current.copyWith(memberDrafts: drafts));
  }

  @override
  Future<Result<KycDraft>> uploadMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey, {
    required String name,
    required int bytes,
    required String mimeType,
  }) {
    return upload(
      entity,
      documentKey,
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
  }

  @override
  Result<KycDraft> deleteMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey,
  ) {
    return deleteDocument(entity, documentKey);
  }

  @override
  Result<KycDraft> deleteMember(EntityType entity, String id) {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    return save(
      current.copyWith(members: current.members.where((m) => m.id != id).toList()),
    );
  }

  @override
  Future<Result<KycDraft>> invite(EntityType entity, KycInvite invite) async {
    final result = await _client.request(
      path: '/v1/kyc/${entity.name}/invites',
      method: 'POST',
      data: {'email': invite.email, 'role': 'member'},
      decode: (json) => _mapDraft(json, entity),
    );
    if (result case Success(:final value)) {
      _drafts[entity] = value;
      _changes.add(KycChange(entity));
    }
    return result;
  }

  @override
  Future<Result<KycDraft>> requestResolutionSignatures(
    EntityType entity, {
    String? memberId,
  }) async {
    return Success(_drafts[entity] ?? KycDraft(entity: entity));
  }

  @override
  Future<Result<KycDraft>> simulateResolutionSignature(
    EntityType entity,
    String memberId,
  ) async {
    return Success(_drafts[entity] ?? KycDraft(entity: entity));
  }

  @override
  Future<Result<KycDraft>> submit(EntityType entity) async {
    await _persist(entity, _drafts[entity] ?? KycDraft(entity: entity));
    final result = await _client.request(
      path: '/v1/kyc/${entity.name}/submit',
      method: 'POST',
      decode: (json) => _mapDraft(json, entity),
    );
    if (result case Success(:final value)) {
      _drafts[entity] = value;
      _changes.add(KycChange(entity));
    }
    return result;
  }

  @override
  Future<Result<KycDraft>> simulateRequirementApproval(
    EntityType entity,
    String stepId,
  ) async {
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    final next = current.copyWith(
      verifiedSteps: {...current.verifiedSteps, stepId},
    );
    return save(next);
  }

  @override
  Future<Result<KycDraft>> simulateReview(
    EntityType entity, {
    required bool approved,
  }) async {
    // Production review is admin-driven; keep local status for tests only.
    final current = _drafts[entity] ?? KycDraft(entity: entity);
    return save(
      current.copyWith(
        status: approved
            ? VerificationStatus.verified
            : VerificationStatus.correctionRequired,
      ),
    );
  }

  @override
  void dispose() {
    _changes.close();
  }
}
