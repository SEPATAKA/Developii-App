import 'dart:async';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/utils/cancellation.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/investor_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

final class MockKycRepository implements KycRepository {
  MockKycRepository(
    this.behavior,
    this._context,
    this._accounts, {
    this.scenario = MockScenario.success,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _userId = _context.scope?.userId;
    _scopeChanges = _context.changes.listen((scope) {
      for (final operation in _pending.toList()) {
        operation.cancel();
      }
      if (_userId != scope?.userId) {
        _drafts.clear();
        _userId = scope?.userId;
      }
      if (!_disposed) _changes.add(const KycChange(null));
    });
  }
  final MockBehavior behavior;
  final MockScenario scenario;
  final InvestorAccountContext _context;
  final InvestorAccountRepository _accounts;
  final DateTime Function() _now;
  final _drafts = <EntityType, KycDraft>{};
  final _pending = <Cancellation>{};
  final _changes = StreamController<KycChange>.broadcast();
  late final StreamSubscription<InvestorScope?> _scopeChanges;
  String? _userId;
  int _sequence = 0;
  bool _disposed = false;
  @override
  Stream<KycChange> get changes => _changes.stream;

  KycDraft _draft(EntityType entity) => _drafts.putIfAbsent(entity, () {
    if (scenario == MockScenario.incompleteKyc ||
        (_userId?.startsWith('local-investor-') ?? false)) {
      return KycDraft(
        entity: entity,
        completedSteps: entity == EntityType.individual ? {'selfie'} : {},
        verifiedSteps: entity == EntityType.individual ? {'selfie'} : {},
        documents: entity == EntityType.individual
            ? {
                'selfie': KycDocument(
                  id: 'login-selfie',
                  name: 'Live_selfie.jpg',
                  bytes: 120000,
                  mimeType: 'image/jpeg',
                  uploadedAt: _now(),
                ),
              }
            : {},
      );
    }
    final complete = KycDemoFixtures.verified(entity, _now()).copyWith(
      identitySummary: entity == EntityType.individual
          ? KycDemoFixtures.sampleIdentity(_context.user)
          : null,
    );
    if (scenario == MockScenario.pendingVerification) {
      return complete.copyWith(
        status: VerificationStatus.pending,
        verifiedSteps: entity == EntityType.individual ? {'selfie'} : {},
      );
    }
    if (scenario == MockScenario.rejectedVerification) {
      final key = complete.documents.keys.first;
      final original = complete.documents[key]!;
      return complete.copyWith(
        status: VerificationStatus.correctionRequired,
        completedSteps: complete.completedSteps.difference({
          KycPlans.steps(entity).first.id,
        }),
        verifiedSteps: complete.verifiedSteps.difference({
          KycPlans.steps(entity).first.id,
        }),
        correction:
            'The uploaded document is not legible. Please replace it and submit again.',
        documents: {
          ...complete.documents,
          key: KycDocument(
            id: original.id,
            name: original.name,
            bytes: original.bytes,
            mimeType: original.mimeType,
            uploadedAt: original.uploadedAt,
            rejection: 'This document is not legible. Please replace it.',
          ),
        },
      );
    }
    return complete;
  });
  AppFailure? get _accessError => _disposed || _context.scope == null
      ? const AppFailure(FailureKind.unauthenticated, 'Sign in to continue.')
      : null;
  Result<KycDraft> _publish(KycDraft draft) {
    final previous = _drafts[draft.entity];
    if (previous != null) {
      final verified = {
        for (final step in KycPlans.steps(draft.entity))
          if (draft.verifiedSteps.contains(step.id) &&
              draft.completedSteps.contains(step.id) &&
              (!previous.verifiedSteps.contains(step.id) ||
                  _sameRequirement(previous, draft, step)))
            step.id,
      };
      if (verified.length != draft.verifiedSteps.length ||
          !verified.containsAll(draft.verifiedSteps)) {
        draft = draft.copyWith(verifiedSteps: verified);
      }
    }
    _drafts[draft.entity] = draft;
    _changes.add(KycChange(draft.entity));
    return Success(draft);
  }

  bool _sameRequirement(
    KycDraft previous,
    KycDraft next,
    KycStepDefinition step,
  ) {
    if (step.fields.any(
          (field) => previous.values[field.key] != next.values[field.key],
        ) ||
        step.documents.any(
          (document) => !_sameRecords(
            previous.documentsFor(document.key),
            next.documentsFor(document.key),
          ),
        )) {
      return false;
    }
    if (step.id == 'tax' &&
        !_sameRecords(previous.taxResidencies, next.taxResidencies)) {
      return false;
    }
    return _sameRecords(
      previous.members.where(step.includesMember).toList(),
      next.members.where(step.includesMember).toList(),
    );
  }

  bool _sameRecords<T>(List<T> previous, List<T> next) =>
      previous.length == next.length &&
      previous.indexed.every((entry) => identical(entry.$2, next[entry.$1]));

  Future<Result<KycDraft>> _run(
    EntityType entity,
    Result<KycDraft> Function() action, {
    Cancellation? callerCancellation,
  }) async {
    if (_accessError case final error?) return Failure(error);
    final scope = _context.scope!;
    final cancellation = Cancellation();
    final stopListening = callerCancellation?.listen(cancellation.cancel);
    _pending.add(cancellation);
    try {
      final gate = await behavior.run(() => true, cancellation: cancellation);
      if (gate case Failure(:final error)) return Failure(error);
      if (!_context.isCurrent(scope) || _disposed) {
        return const Failure(
          AppFailure(
            FailureKind.cancelled,
            'The selected profile changed. Please try again.',
          ),
        );
      }
      return action();
    } finally {
      stopListening?.call();
      _pending.remove(cancellation);
    }
  }

  @override
  Future<Result<KycDraft>> load(EntityType entity) =>
      _run(entity, () => Success(_draft(entity)));

  @override
  Result<KycDraft> save(KycDraft draft) {
    if (_accessError case final error?) return Failure(error);
    final previous = _draft(draft.entity);
    if (previous.status == VerificationStatus.pending ||
        previous.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    if (!KycPlans.validState(draft.entity, draft.currentStep)) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This verification step could not be found.',
        ),
      );
    }
    if (draft.revision < previous.revision) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application changed. Reload it before editing.',
        ),
      );
    }
    final resolution = KycPlans.steps(
      draft.entity,
    ).where((step) => step.id == 'resolution').firstOrNull;
    final changedResolution =
        resolution?.fields.any(
          (field) => previous.values[field.key] != draft.values[field.key],
        ) ??
        false;
    final updated = previous.copyWith(
      values: draft.values,
      taxResidencies: draft.taxResidencies,
      taxResidencyEdits: draft.taxResidencyEdits,
      memberDrafts: draft.memberDrafts,
      currentStep: draft.currentStep,
      members: [
        for (final member in previous.members)
          if (changedResolution && resolution!.includesMember(member))
            member.copyWith(resolutionSignature: const KycResolutionSignature())
          else
            member,
      ],
      clearCorrection: true,
      status: VerificationStatus.incomplete,
    );
    return _publish(
      updated.copyWith(
        completedSteps: {
          for (final step in KycPlans.steps(draft.entity))
            if (KycValidation.step(updated, step, now: _now()).isEmpty) step.id,
        },
      ),
    );
  }

  KycDocumentDefinition? _documentDefinition(EntityType entity, String key) =>
      KycPlans.steps(entity)
          .expand((step) => step.documents)
          .where((document) => document.key == key)
          .firstOrNull;
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
  }) => _run(entity, () {
    final definition = _documentDefinition(entity, key);
    if (definition == null) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This document slot could not be found.',
        ),
      );
    }
    if (append && (!definition.multiple || documentId != null)) {
      return const Failure(
        AppFailure(FailureKind.validation, 'Choose a valid document slot.'),
      );
    }
    final validation = KycValidation.document(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (validation != null) {
      return Failure(AppFailure(FailureKind.validation, validation));
    }
    final draft = _draft(entity);
    final existing = draft.documentsFor(key);
    if (documentId != null &&
        !existing.any((document) => document.id == documentId)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This document could not be found.'),
      );
    }
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    final document = KycDocument(
      id: 'document-${++_sequence}',
      name: name,
      bytes: bytes,
      mimeType: mimeType,
      uploadedAt: _now(),
    );
    final files = append || existing.isEmpty
        ? [...existing, document]
        : [
            for (final file in existing)
              if (file.id == (documentId ?? existing.first.id))
                document
              else
                file,
          ];
    return _publish(
      draft.copyWith(
        documents: {...draft.documents, key: files.first},
        additionalDocuments: {
          ...draft.additionalDocuments,
          if (files.length > 1) key: files.skip(1).toList(),
        },
        identitySummary:
            entity == EntityType.individual && key == 'identityFront'
            ? KycDemoFixtures.sampleIdentity(_context.user)
            : null,
        status: VerificationStatus.incomplete,
        clearCorrection: true,
      ),
    );
  }, callerCancellation: cancellation);
  @override
  Result<KycDraft> deleteDocument(
    EntityType entity,
    String key, {
    String? documentId,
  }) {
    if (_accessError case final error?) return Failure(error);
    final draft = _draft(entity);
    final existing = draft.documentsFor(key);
    if (existing.isEmpty ||
        documentId != null &&
            !existing.any((document) => document.id == documentId)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This document could not be found.'),
      );
    }
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    final changedSteps = KycPlans.steps(entity)
        .where((step) => step.documents.any((document) => document.key == key))
        .map((step) => step.id);
    final remaining = documentId == null
        ? <KycDocument>[]
        : existing.where((document) => document.id != documentId).toList();
    final documents = {...draft.documents}..remove(key);
    final additionalDocuments = {...draft.additionalDocuments}..remove(key);
    if (remaining.isNotEmpty) documents[key] = remaining.first;
    if (remaining.length > 1) {
      additionalDocuments[key] = remaining.skip(1).toList();
    }
    return _publish(
      draft.copyWith(
        documents: documents,
        additionalDocuments: additionalDocuments,
        clearIdentitySummary:
            entity == EntityType.individual && key == 'identityFront',
        completedSteps: {...draft.completedSteps}..removeAll(changedSteps),
        status: VerificationStatus.incomplete,
      ),
    );
  }

  @override
  Result<KycDraft> saveAllocations(
    EntityType entity,
    KycMemberRole role,
    Map<String, int> allocations,
  ) {
    if (_accessError case final error?) return Failure(error);
    final draft = _draft(entity);
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    final members = draft.members
        .where((member) => member.role == role)
        .toList();
    if (members.isEmpty ||
        ![
          KycMemberRole.beneficiary,
          KycMemberRole.shareholder,
        ].contains(role) ||
        allocations.length != members.length ||
        members.any((member) => !allocations.containsKey(member.id)) ||
        allocations.values.any((amount) => amount < 0 || amount > 10000) ||
        allocations.values.fold(0, (sum, value) => sum + value) != 10000) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'The total allocation must equal 100%.',
          fields: {'allocation': 'The total allocation must equal 100%.'},
        ),
      );
    }
    for (final member in members) {
      final issued = member.details?.issuedShares ?? 0;
      if (role == KycMemberRole.shareholder &&
          issued > 0 &&
          allocations[member.id]! * issued % 10000 != 0) {
        return const Failure(
          AppFailure(
            FailureKind.validation,
            'Each holding must represent a whole number of shares.',
          ),
        );
      }
    }
    return _publish(
      draft.copyWith(
        members: [
          for (final member in draft.members)
            if (allocations.containsKey(member.id))
              member.copyWith(
                shareBasisPoints: allocations[member.id],
                details:
                    member.details == null || role != KycMemberRole.shareholder
                    ? null
                    : member.details!.withShares(
                        allocations[member.id]! *
                            member.details!.issuedShares ~/
                            10000,
                      ),
              )
            else
              member,
        ],
        values: {...draft.values}
          ..removeWhere(
            (key, value) =>
                members.any((member) => key == 'allocation:${member.id}'),
          ),
        memberDrafts: {...draft.memberDrafts}
          ..removeWhere((key, value) => allocations.containsKey(value.id)),
        completedSteps: {...draft.completedSteps}
          ..removeAll(
            KycPlans.steps(entity)
                .where((step) => step.memberRoles.contains(role))
                .map((step) => step.id),
          ),
      ),
    );
  }

  @override
  Result<KycDraft> saveMemberDraft(
    EntityType entity,
    String key,
    KycMemberDraft member,
  ) {
    if (_accessError case final error?) return Failure(error);
    final draft = _draft(entity);
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    if (KycMemberPlan.role(entity, member.role.name) == null ||
        (key != member.id && key != 'new-${member.role.name}')) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This member could not be found.'),
      );
    }
    return _publish(
      draft.copyWith(memberDrafts: {...draft.memberDrafts, key: member}),
    );
  }

  @override
  Future<Result<KycDraft>> uploadMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey, {
    required String name,
    required int bytes,
    required String mimeType,
  }) => _run(entity, () {
    final member = _draft(entity).memberDrafts[draftKey];
    if (member == null ||
        !KycMemberPlan.documents(
          member,
          _now(),
        ).any((slot) => slot.key == documentKey)) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This document slot could not be found.',
        ),
      );
    }
    final error = KycValidation.document(
      name: name,
      bytes: bytes,
      mimeType: mimeType,
    );
    if (error != null) {
      return Failure(AppFailure(FailureKind.validation, error));
    }
    return saveMemberDraft(
      entity,
      draftKey,
      member.copyWith(
        documents: {
          ...member.documents,
          documentKey: KycDocument(
            id: 'member-document-${++_sequence}',
            name: name,
            bytes: bytes,
            mimeType: mimeType,
            uploadedAt: _now(),
          ),
        },
      ),
    );
  });

  @override
  Result<KycDraft> deleteMemberDocument(
    EntityType entity,
    String draftKey,
    String documentKey,
  ) {
    if (_accessError case final error?) return Failure(error);
    final member = _draft(entity).memberDrafts[draftKey];
    if (member == null || !member.documents.containsKey(documentKey)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This document could not be found.'),
      );
    }
    return saveMemberDraft(
      entity,
      draftKey,
      member.copyWith(documents: {...member.documents}..remove(documentKey)),
    );
  }

  @override
  Result<KycDraft> saveMember(EntityType entity, KycMember member) {
    if (_accessError case final error?) return Failure(error);
    final errors = KycValidation.member(member);
    if (errors.isNotEmpty) {
      return Failure(
        AppFailure(
          FailureKind.validation,
          'Check the member details.',
          fields: errors,
        ),
      );
    }
    final draft = _draft(entity);
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    if (!KycPlans.steps(
      entity,
    ).any((step) => step.memberRoles.contains(member.role))) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This member role does not apply to this entity.',
        ),
      );
    }
    final previous = draft.members
        .where((value) => value.id == member.id)
        .firstOrNull;
    final resolution = KycPlans.steps(
      entity,
    ).where((step) => step.id == 'resolution').firstOrNull;
    final wasSignatory =
        previous != null && (resolution?.includesMember(previous) ?? false);
    final isSignatory = resolution?.includesMember(member) ?? false;
    final changedSignatory =
        wasSignatory != isSignatory ||
        isSignatory &&
            previous != null &&
            (previous.firstName != member.firstName ||
                previous.lastName != member.lastName ||
                previous.identityNumber != member.identityNumber ||
                previous.email != member.email ||
                previous.details?.position != member.details?.position);
    final members = [
      for (final value in draft.members)
        if (value.id == member.id) member else value,
      if (previous == null) member,
    ];
    if (members.length > 100 ||
        members
                .where(
                  (value) =>
                      value.role == member.role &&
                      value.identityNumber == member.identityNumber,
                )
                .length >
            1) {
      return const Failure(
        AppFailure(FailureKind.validation, 'This member is already listed.'),
      );
    }
    return _publish(
      draft.copyWith(
        members: [
          for (final value in members)
            if (changedSignatory &&
                (resolution?.includesMember(value) ?? false))
              value.copyWith(
                resolutionSignature: const KycResolutionSignature(),
              )
            else
              value,
        ],
        memberDrafts: {...draft.memberDrafts}
          ..removeWhere((key, value) => value.id == member.id),
        completedSteps: {...draft.completedSteps}
          ..removeAll(
            KycPlans.steps(entity)
                .where(
                  (step) =>
                      step.includesMember(member) ||
                      previous != null && step.includesMember(previous),
                )
                .map((step) => step.id),
          ),
      ),
    );
  }

  @override
  Result<KycDraft> deleteMember(EntityType entity, String id) {
    if (_accessError case final error?) return Failure(error);
    final draft = _draft(entity);
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    if (!draft.members.any((member) => member.id == id)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This member could not be found.'),
      );
    }
    final resolution = KycPlans.steps(
      entity,
    ).where((step) => step.id == 'resolution').firstOrNull;
    final removedSignatory = draft.members.any(
      (member) =>
          member.id == id && (resolution?.includesMember(member) ?? false),
    );
    return _publish(
      draft.copyWith(
        members: [
          for (final member in draft.members.where((member) => member.id != id))
            if (removedSignatory &&
                (resolution?.includesMember(member) ?? false))
              member.copyWith(
                resolutionSignature: const KycResolutionSignature(),
              )
            else
              member,
        ],
        memberDrafts: {...draft.memberDrafts}
          ..removeWhere((key, value) => value.id == id),
        invitationReceipts: {...draft.invitationReceipts}..remove(id),
        completedSteps: {...draft.completedSteps}
          ..removeAll(
            KycPlans.steps(entity)
                .where((step) => step.memberRoles.isNotEmpty)
                .map((step) => step.id),
          ),
      ),
    );
  }

  @override
  Future<Result<KycDraft>> invite(EntityType entity, KycInvite invite) =>
      _run(entity, () {
        final draft = _draft(entity);
        final existing = draft.members
            .where((member) => member.id == invite.memberId)
            .firstOrNull;
        final editor = draft.memberDrafts.values
            .where((member) => member.id == invite.memberId)
            .firstOrNull;
        if (existing == null && editor == null) {
          return const Failure(
            AppFailure(FailureKind.notFound, 'This member could not be found.'),
          );
        }
        if (draft.status == VerificationStatus.pending ||
            draft.status == VerificationStatus.verified) {
          return const Failure(
            AppFailure(
              FailureKind.validation,
              'This application has already been submitted.',
            ),
          );
        }
        final errors = KycMemberPlan.validateInvite(
          invite,
          trust: entity == EntityType.trust,
        );
        if (errors.isNotEmpty) {
          return Failure(
            AppFailure(
              FailureKind.validation,
              'Check the invitation details.',
              fields: errors,
            ),
          );
        }
        final sentAt = _now();
        return _publish(
          draft.copyWith(
            invitationReceipts: {
              ...draft.invitationReceipts,
              invite.memberId: KycInviteReceipt(
                reference: 'INV-${entity.name.toUpperCase()}-${++_sequence}',
                memberId: invite.memberId,
                email: invite.email,
                phone: invite.sendSms ? invite.phone : null,
                sentAt: sentAt,
                expiresAt: sentAt.add(const Duration(days: 18)),
              ),
            },
            members: [
              for (final member in draft.members)
                if (member.id == invite.memberId)
                  member.copyWith(inviteSent: true)
                else
                  member,
              if (existing == null)
                KycMember(
                  id: editor!.id,
                  firstName: editor.values['firstName'] ?? '',
                  lastName: editor.values['lastName'] ?? '',
                  identityNumber: editor.values['identityNumber'] ?? '',
                  role: editor.role,
                  email: invite.email,
                  country: editor.values['country'] ?? 'South Africa',
                  inviteSent: true,
                ),
            ],
            memberDrafts: {
              for (final entry in draft.memberDrafts.entries)
                if (entry.value.id != invite.memberId) entry.key: entry.value,
              invite.memberId: ?editor,
            },
          ),
        );
      });
  @override
  Future<Result<KycDraft>> requestResolutionSignatures(
    EntityType entity, {
    String? memberId,
  }) => _run(entity, () {
    final draft = _draft(entity);
    final step = KycPlans.steps(entity)
        .where((step) => step.id == 'resolution' && step.memberRoles.isNotEmpty)
        .firstOrNull;
    if (step == null) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This entity does not have an individual signing flow.',
        ),
      );
    }
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    final errors = KycValidation.resolutionFields(draft, step, now: _now());
    final members = draft.members.where(step.includesMember).toList();
    if (members.isEmpty ||
        memberId != null && !members.any((member) => member.id == memberId)) {
      errors['members'] = 'Add the required signatories before continuing.';
    }
    if (errors.isNotEmpty) {
      return Failure(
        AppFailure(
          FailureKind.validation,
          'Complete the resolution details before requesting signatures.',
          fields: errors,
        ),
      );
    }
    final requestedAt = _now();
    return _publish(
      draft.copyWith(
        members: [
          for (final member in draft.members)
            if (step.includesMember(member) &&
                !member.signed &&
                (memberId == null || member.id == memberId))
              member.copyWith(
                resolutionSignature: KycResolutionSignature(
                  status: KycSignatureStatus.awaiting,
                  requestedAt: requestedAt,
                ),
              )
            else
              member,
        ],
      ),
    );
  });

  @override
  Future<Result<KycDraft>> simulateResolutionSignature(
    EntityType entity,
    String memberId,
  ) => _run(entity, () {
    final draft = _draft(entity);
    final step = KycPlans.steps(entity)
        .where((step) => step.id == 'resolution' && step.memberRoles.isNotEmpty)
        .firstOrNull;
    final member = draft.members
        .where((member) => member.id == memberId)
        .firstOrNull;
    if (step == null || member == null || !step.includesMember(member)) {
      return const Failure(
        AppFailure(FailureKind.notFound, 'This signatory could not be found.'),
      );
    }
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'This application has already been submitted.',
        ),
      );
    }
    if (member.signed) return Success(draft);
    if (member.resolutionSignature.status != KycSignatureStatus.awaiting ||
        KycValidation.resolutionFields(draft, step, now: _now()).isNotEmpty) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Request a signature for the current resolution first.',
        ),
      );
    }
    return _publish(
      draft.copyWith(
        members: [
          for (final value in draft.members)
            if (value.id == memberId)
              value.copyWith(
                resolutionSignature: KycResolutionSignature(
                  status: KycSignatureStatus.signed,
                  requestedAt: value.resolutionSignature.requestedAt,
                  signedAt: _now(),
                ),
              )
            else
              value,
        ],
      ),
    );
  });

  @override
  Future<Result<KycDraft>> submit(EntityType entity) => _run(entity, () {
    final draft = _draft(entity);
    if (draft.status == VerificationStatus.pending ||
        draft.status == VerificationStatus.verified) {
      return Success(draft);
    }
    final errors = KycValidation.submission(draft, now: _now());
    if (errors.isNotEmpty || scenario == MockScenario.validationFailure) {
      return Failure(
        AppFailure(
          FailureKind.validation,
          'Complete the required details before submitting.',
          fields: errors,
        ),
      );
    }
    final submitted = draft.copyWith(
      status: VerificationStatus.pending,
      currentStep: 'review',
      submissionId: 'verification-${entity.name}-${++_sequence}',
      clearCorrection: true,
    );
    _accounts.setVerification(VerificationStatus.pending, entity: entity);
    return _publish(submitted);
  });
  @override
  Future<Result<KycDraft>> simulateRequirementApproval(
    EntityType entity,
    String stepId,
  ) => _run(entity, () {
    final draft = _draft(entity);
    final step = KycPlans.steps(
      entity,
    ).where((step) => step.id == stepId).firstOrNull;
    if (step == null) {
      return const Failure(
        AppFailure(
          FailureKind.notFound,
          'This verification requirement could not be found.',
        ),
      );
    }
    final errors = KycValidation.step(draft, step, now: _now());
    if (!draft.completedSteps.contains(stepId) || errors.isNotEmpty) {
      return Failure(
        AppFailure(
          FailureKind.validation,
          'Complete the requirement before simulating approval.',
          fields: errors,
        ),
      );
    }
    return _publish(
      draft.copyWith(verifiedSteps: {...draft.verifiedSteps, stepId}),
    );
  });

  @override
  Future<Result<KycDraft>> simulateReview(
    EntityType entity, {
    required bool approved,
  }) => _run(entity, () {
    final draft = _draft(entity);
    if (draft.status != VerificationStatus.pending) {
      return const Failure(
        AppFailure(
          FailureKind.validation,
          'Submit the application before reviewing it.',
        ),
      );
    }
    if (approved) {
      final errors = <String, String>{
        for (final step in KycPlans.steps(entity))
          ...KycValidation.step(draft, step, now: _now()),
      };
      if (errors.isNotEmpty) {
        return Failure(
          AppFailure(
            FailureKind.validation,
            'Resolve the pending verification items before simulating approval.',
            fields: errors,
          ),
        );
      }
    }
    final status = approved
        ? VerificationStatus.verified
        : VerificationStatus.correctionRequired;
    _accounts.setVerification(status, entity: entity);
    final documents = {...draft.documents};
    if (!approved && documents.isNotEmpty) {
      final key =
          documents.keys.where((key) => key != 'selfie').firstOrNull ??
          documents.keys.first;
      final document = documents[key]!;
      documents[key] = KycDocument(
        id: document.id,
        name: document.name,
        bytes: document.bytes,
        mimeType: document.mimeType,
        uploadedAt: document.uploadedAt,
        rejection: 'This document is not legible. Please replace it.',
      );
    }
    return _publish(
      draft.copyWith(
        status: status,
        documents: documents,
        completedSteps: approved ? draft.completedSteps : {},
        verifiedSteps: approved ? draft.completedSteps : {},
        correction: approved
            ? null
            : 'The uploaded document is not legible. Please replace it and submit again.',
        clearCorrection: approved,
      ),
    );
  });
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final operation in _pending.toList()) {
      operation.cancel();
    }
    _drafts.clear();
    unawaited(_scopeChanges.cancel());
    unawaited(_changes.close());
  }
}
