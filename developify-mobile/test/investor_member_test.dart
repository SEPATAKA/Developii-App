import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late MockInvestorAccountRepository accounts;
  late MockKycRepository repository;
  late MockBehavior behavior;
  const user = AppUser(
    id: 'member-tests',
    name: 'Investor',
    email: 'investor@example.test',
  );
  setUp(() {
    session = SessionService()..signIn(user);
    context = InvestorAccountContext(session);
    behavior = MockBehavior(delay: Duration.zero);
    accounts = MockInvestorAccountRepository(
      MockBehavior(delay: Duration.zero),
      context,
    );
    repository = MockKycRepository(
      behavior,
      context,
      accounts,
      scenario: MockScenario.incompleteKyc,
    );
  });
  tearDown(() {
    repository.dispose();
    accounts.dispose();
    context.dispose();
    session.dispose();
  });

  Future<KycMemberStore> editor(
    EntityType entity,
    KycMemberRole role, {
    String? id,
  }) async {
    final store = KycMemberStore(repository, entity);
    addTearDown(store.dispose);
    await store.load(role, id: id);
    return store;
  }

  void values(KycMemberStore store, Map<String, String> fields) {
    for (final entry in fields.entries) {
      store.edit(entry.key, entry.value);
    }
  }

  Future<void> documents(KycMemberStore store) async {
    for (final slot in store.documents.where((document) => document.required)) {
      expect(
        await store.upload(
          slot.key,
          name: '${slot.key}.pdf',
          bytes: 122880,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
    }
  }

  Future<KycDraft> application(EntityType entity) async =>
      (await repository.load(entity) as Success<KycDraft>).value;

  test(
    'minor guardian requirements follow calendar birthdays and reject invalid dates',
    () {
      final now = DateTime(2026, 9, 13);
      expect(KycMemberPlan.age('2008-09-13', now), 18);
      expect(KycMemberPlan.age('2008-09-14', now), 17);
      expect(KycMemberPlan.age('2024-02-31', now), isNull);
      expect(KycMemberPlan.age('2027-01-01', now), isNull);
      expect(KycMemberPlan.age('2000-02-29', now), 26);
      final draft = KycMemberDraft(
        id: 'minor',
        role: KycMemberRole.beneficiary,
        values: const {
          'firstName': 'Adaeze',
          'lastName': 'Okoye',
          'identityNumber': 'mock-1',
          'birthDate': '2013-02-02',
          'relationship': 'Child',
        },
      );
      expect(
        KycMemberPlan.validate(draft, now).keys,
        containsAll([
          'guardianName',
          'guardianIdentity',
          'guardianCountry',
          'identity',
          'guardian',
        ]),
      );
      final adult = draft.copyWith(
        values: {...draft.values, 'birthDate': '2000-02-02'},
      );
      expect(
        KycMemberPlan.validate(adult, now).keys,
        isNot(contains('guardianName')),
      );
      expect(
        KycMemberPlan.documents(
          adult,
          now,
        ).firstWhere((document) => document.key == 'guardian').required,
        isFalse,
      );
    },
  );

  test(
    'beneficiary editor preserves unfinished details and documents across routes',
    () async {
      final store = await editor(EntityType.trust, KycMemberRole.beneficiary);
      values(store, {
        'firstName': 'Adaeze',
        'lastName': 'Okoye',
        'identityNumber': 'mock-1',
        'birthDate': '2013-02-02',
        'relationship': 'Child',
      });
      expect(store.save(), isFalse);
      expect(
        store.errors.keys,
        containsAll(['guardianName', 'guardianIdentity', 'guardianCountry']),
      );
      values(store, {
        'guardianName': 'Thandi Okoye',
        'guardianIdentity': 'guardian-1',
        'guardianCountry': 'South Africa',
      });
      await documents(store);
      final resumed = await editor(EntityType.trust, KycMemberRole.beneficiary);
      expect(resumed.values['guardianName'], 'Thandi Okoye');
      expect(
        resumed.draft!.documents.keys,
        containsAll(['identity', 'guardian']),
      );
      expect(resumed.canSave, isTrue);
      expect(resumed.save(), isTrue);
      final id = resumed.draft!.id;
      expect(
        (await application(
          EntityType.trust,
        )).members.single.details!.guardianName,
        'Thandi Okoye',
      );
      final edit = await editor(
        EntityType.trust,
        KycMemberRole.beneficiary,
        id: id,
      );
      edit.edit('firstName', 'Updated');
      final secondDraft = await editor(
        EntityType.trust,
        KycMemberRole.beneficiary,
      );
      expect(secondDraft.values['firstName'], isNull);
      expect(secondDraft.draft!.id, isNot(id));
      final reopened = await editor(
        EntityType.trust,
        KycMemberRole.beneficiary,
        id: id,
      );
      expect(reopened.values['firstName'], 'Updated');
      expect(reopened.draft!.documents, hasLength(2));
    },
  );

  test(
    'member uploads validate, fail, retry, replace and delete without losing input',
    () async {
      final store = await editor(EntityType.stokvel, KycMemberRole.treasurer);
      values(store, {
        'firstName': 'Bongani',
        'lastName': 'Mthembu',
        'identityNumber': 'mock-2',
      });
      expect(
        await store.upload(
          'identity',
          name: 'bad.exe',
          bytes: 20,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      expect(
        await store.upload(
          'unknown',
          name: 'id.pdf',
          bytes: 20,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      expect(
        await store.upload(
          'identity',
          name: 'id.pdf',
          bytes: 6 * 1024 * 1024,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      behavior.failNext();
      expect(
        await store.upload(
          'identity',
          name: 'id.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      expect(store.values['firstName'], 'Bongani');
      expect(
        await store.upload(
          'identity',
          name: 'id.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      final previous = store.draft!.documents['identity']!.id;
      expect(
        await store.upload(
          'identity',
          name: 'replacement.png',
          bytes: 1400,
          mimeType: 'image/png',
        ),
        isTrue,
      );
      expect(store.draft!.documents['identity']!.id, isNot(previous));
      expect(store.deleteDocument('identity'), isTrue);
      expect(store.draft!.documents, isEmpty);
      expect(store.canSave, isFalse);
    },
  );

  test(
    'shareholding validation derives ownership and requires UBO documents above five percent',
    () async {
      final store = await editor(EntityType.company, KycMemberRole.shareholder);
      values(store, {
        'firstName': 'Adaeze',
        'lastName': 'Okoye',
        'identityNumber': 'mock-share-1',
        'shareClass': 'Ordinary',
        'numberOfShares': '50',
        'issuedShares': '1000',
        'acquiredOn': '2026-01-01',
        'acquisition': 'Founding issue',
      });
      expect(store.shareBasisPoints, 500);
      expect(
        store.documents
            .where((document) => document.required)
            .map((document) => document.key),
        ['shareCertificate'],
      );
      await documents(store);
      expect(store.canSave, isTrue);
      store.edit('isDirector', 'true');
      expect(store.canSave, isFalse);
      expect(
        store.documents.where((document) => document.required),
        hasLength(3),
      );
      store.edit('isDirector', 'false');
      store.edit('numberOfShares', '51');
      expect(store.canSave, isFalse);
      expect(
        store.documents.where((document) => document.required),
        hasLength(3),
      );
      await documents(store);
      for (final count in ['0', '-1', '1001', '1.5', 'NaN']) {
        store.edit('numberOfShares', count);
        expect(store.canSave, isFalse);
      }
      store.edit('numberOfShares', '620');
      store.edit('isDirector', 'true');
      expect(store.save(), isTrue);
      final saved = (await application(EntityType.company)).members.single;
      expect(saved.shareBasisPoints, 6200);
      expect(saved.details!.numberOfShares, 620);
      expect(saved.details!.isDirector, isTrue);
      expect(saved.identityVerified && saved.addressVerified, isTrue);
    },
  );

  test(
    'allocations resume and commit atomically only at one hundred percent',
    () async {
      for (final (id, share) in [('a', 4500), ('b', 5500)]) {
        expect(
          repository.saveMember(
            EntityType.trust,
            KycMember(
              id: id,
              firstName: id,
              lastName: 'Okoye',
              role: KycMemberRole.beneficiary,
              identityNumber: id,
              shareBasisPoints: share,
            ),
          ),
          isA<Success<KycDraft>>(),
        );
      }
      final store = await editor(
        EntityType.trust,
        KycMemberRole.beneficiary,
        id: 'a',
      );
      store.allocate('a', 6000);
      final step = KycPlans.steps(
        EntityType.trust,
      ).singleWhere((step) => step.id == 'beneficiaries');
      expect(
        KycValidation.step(
          await application(EntityType.trust),
          step,
        )['allocation'],
        contains('Save the allocation changes'),
      );
      expect(store.saveAllocations(), isFalse);
      expect(
        (await application(EntityType.trust)).members.first.shareBasisPoints,
        4500,
      );
      final resumed = await editor(
        EntityType.trust,
        KycMemberRole.beneficiary,
        id: 'a',
      );
      expect(resumed.allocations['a'], 6000);
      resumed.allocate('b', 4000);
      expect(resumed.saveAllocations(), isTrue);
      expect(
        KycValidation.step(
          await application(EntityType.trust),
          step,
        )['allocation'],
        isNull,
      );
      expect(
        (await application(
          EntityType.trust,
        )).members.map((member) => member.shareBasisPoints),
        [6000, 4000],
      );
      expect(
        repository.saveAllocations(
          EntityType.trust,
          KycMemberRole.beneficiary,
          {'a': 10000, 'unknown': 0},
        ),
        isA<Failure<KycDraft>>(),
      );
      expect(
        (await application(
          EntityType.trust,
        )).members.map((member) => member.shareBasisPoints),
        [6000, 4000],
      );
    },
  );

  test(
    'a shareholder director signs the same board resolution without a duplicate member',
    () async {
      final director = KycMember(
        id: 'shareholder-director',
        firstName: 'Adaeze',
        lastName: 'Okoye',
        role: KycMemberRole.shareholder,
        identityNumber: 'director-id',
        shareBasisPoints: 4000,
        identityVerified: true,
        addressVerified: true,
        details: KycMemberDetails(isDirector: true),
      );
      final holder = KycMember(
        id: 'holder',
        firstName: 'Sipho',
        lastName: 'Khumalo',
        role: KycMemberRole.shareholder,
        identityNumber: 'holder-id',
        shareBasisPoints: 6000,
      );
      repository.saveMember(EntityType.company, director);
      repository.saveMember(EntityType.company, holder);
      final store = KycStore(repository, EntityType.company);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'resolution');
      expect(store.members.map((member) => member.id), [director.id]);
      for (final entry in {
        'meetingDate': '2026-01-01',
        'membersPresent': '1',
        'signatory': 'Adaeze Okoye',
        'investmentCap': '100000',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(
        await store.upload(
          'boardResolution',
          name: 'resolution.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(store.canContinue, isFalse);
      expect(await store.requestSignatures(), isTrue);
      expect(await store.simulateSignature(director.id), isTrue);
      expect(store.canContinue, isTrue);
      expect(store.continueStep(), isTrue);
      expect(store.draft!.completedSteps, contains('resolution'));
      expect(store.draft!.members, hasLength(2));
      expect(
        store.saveMember(
          store.members
              .firstWhere((member) => member.id == director.id)
              .copyWith(details: KycMemberDetails()),
        ),
        isTrue,
      );
      expect(store.draft!.completedSteps, isNot(contains('resolution')));
      store.selectStep('resolution');
      expect(store.members, isEmpty);
      expect(store.canContinue, isFalse);
    },
  );

  test(
    'Stokvel resolution validates membership counts and the authored signatory choice',
    () async {
      final store = KycStore(repository, EntityType.stokvel);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'resolution');
      for (final entry in {
        'memberCount': '22',
        'membersPresent': '22',
        'meetingDate': '2026-05-04',
        'authorisedAmount': '100000',
        'signatory': 'Chairperson + Treasurer',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(
        await store.upload(
          'minutes',
          name: 'minutes.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(store.canContinue, isTrue);
      for (final invalid in ['0', '23', '-1', '1.5']) {
        store.edit('membersPresent', invalid);
        expect(store.canContinue, isFalse, reason: invalid);
      }
      store.edit('membersPresent', '22');
      store.edit('signatory', 'Unknown');
      expect(store.canContinue, isFalse);
      store.edit('signatory', 'Chairperson + Treasurer');
      expect(store.canContinue, isTrue);
    },
  );

  test(
    'new trustee invitations validate attachments and retry without sending messages',
    () async {
      final store = await editor(EntityType.trust, KycMemberRole.trustee);
      store.edit('email', 'invalid');
      expect(store.canInvite, isFalse);
      values(store, {
        'email': 'trustee@example.test',
        'sms': 'true',
        'phone': '123',
        'attach-appointment': 'true',
      });
      expect(store.validateInvite(), isFalse);
      store.edit('phone', '+27 82 411 7822');
      store.edit('message', 'Welcome to the trust.');
      expect(store.canInvite, isTrue);
      behavior.failNext();
      expect(await store.invite(), isFalse);
      expect((await application(EntityType.trust)).members, isEmpty);
      expect(store.values['message'], 'Welcome to the trust.');
      expect(await store.invite(), isTrue);
      final invited = (await application(EntityType.trust)).members.single;
      expect(invited.name, 'trustee@example.test');
      expect(invited.inviteSent, isTrue);
      expect(invited.identityVerified, isFalse);
      expect(invited.addressVerified, isFalse);
      final reopened = await editor(
        EntityType.trust,
        KycMemberRole.trustee,
        id: invited.id,
      );
      expect(reopened.values['email'], 'trustee@example.test');
      expect(reopened.values['attach-appointment'], 'true');
      expect(reopened.canSave, isFalse);
      final saved = await application(EntityType.trust);
      final receipt = saved.invitationReceipts[invited.id]!;
      expect(receipt.email, 'trustee@example.test');
      expect(receipt.phone, '+27824117822');
      expect(
        receipt.expiresAt.difference(receipt.sentAt),
        const Duration(days: 18),
      );
      expect(receipt.reference, startsWith('INV-TRUST-'));
      expect(() => saved.invitationReceipts.clear(), throwsUnsupportedError);
      repository.save(saved.copyWith(invitationReceipts: {}));
      expect(
        (await application(EntityType.trust)).invitationReceipts[invited.id],
        same(receipt),
      );
      repository.deleteMember(EntityType.trust, invited.id);
      expect((await application(EntityType.trust)).invitationReceipts, isEmpty);
    },
  );

  test(
    'member IDs and roles are checked, and session changes clear sensitive editor state',
    () async {
      final invalid = await editor(EntityType.trust, KycMemberRole.director);
      expect(invalid.status, LoadStatus.error);
      final missing = await editor(
        EntityType.company,
        KycMemberRole.shareholder,
        id: 'missing',
      );
      expect(missing.status, LoadStatus.error);
      final store = await editor(EntityType.trust, KycMemberRole.beneficiary);
      store.edit('firstName', 'Private draft');
      final upload = store.upload(
        'identity',
        name: 'id.pdf',
        bytes: 1000,
        mimeType: 'application/pdf',
      );
      context.selectEntity(EntityType.company);
      expect(await upload, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(store.draft, isNull);
      expect(store.allocations, isEmpty);
      expect((await application(EntityType.company)).memberDrafts, isEmpty);
      session.signOut();
      session.signIn(user);
      await Future<void>.delayed(Duration.zero);
      expect((await application(EntityType.trust)).memberDrafts, isEmpty);
    },
  );

  test(
    'disposed member editors cannot save late uploads or change drafts',
    () async {
      final store = KycMemberStore(repository, EntityType.trust);
      await store.load(KycMemberRole.trustee);
      final upload = store.upload(
        'identity',
        name: 'id.pdf',
        bytes: 1000,
        mimeType: 'application/pdf',
      );
      store.dispose();
      expect(await upload, isFalse);
      store.edit('firstName', 'Late change');
      expect(store.draft, isNull);
      expect(store.save(), isFalse);
    },
  );
}
