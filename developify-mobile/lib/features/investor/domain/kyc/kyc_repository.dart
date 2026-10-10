import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

abstract interface class KycRepository {
  Stream<KycChange> get changes;
  Future<Result<KycDraft>> load(EntityType entity);
  Result<KycDraft> save(KycDraft draft);
  Future<Result<KycDraft>> upload(
    EntityType entity,
    String key, {
    required String name,
    required int bytes,
    required String mimeType,
    Cancellation? cancellation,
    bool append = false,
    String? documentId,
  });
  Result<KycDraft> deleteDocument(
    EntityType entity,
    String key, {
    String? documentId,
  });
  Result<KycDraft> saveMember(EntityType entity, KycMember member);
  Result<KycDraft> saveAllocations(
    EntityType entity,
    KycMemberRole role,
    Map<String, int> allocations,
  );
  Result<KycDraft> saveMemberDraft(
    EntityType entity,
    String key,
    KycMemberDraft draft,
  );
  Future<Result<KycDraft>> uploadMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey, {
    required String name,
    required int bytes,
    required String mimeType,
  });
  Result<KycDraft> deleteMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey,
  );
  Result<KycDraft> deleteMember(EntityType entity, String id);
  Future<Result<KycDraft>> invite(EntityType entity, KycInvite invite);
  Future<Result<KycDraft>> requestResolutionSignatures(
    EntityType entity, {
    String? memberId,
  });
  Future<Result<KycDraft>> simulateResolutionSignature(
    EntityType entity,
    String memberId,
  );
  Future<Result<KycDraft>> submit(EntityType entity);
  Future<Result<KycDraft>> simulateRequirementApproval(
    EntityType entity,
    String stepId,
  );
  Future<Result<KycDraft>> simulateReview(
    EntityType entity, {
    required bool approved,
  });
  void dispose();
}
