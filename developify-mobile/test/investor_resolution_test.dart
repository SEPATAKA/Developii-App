import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late MockInvestorAccountRepository accounts;
  late MockKycRepository repository;
  late MockBehavior behavior;
  late DateTime clock;
  late KycStore store;
  const signer = KycMember(
    id: 'adaeze',
    firstName: 'Adaeze',
    lastName: 'Okoye',
    role: KycMemberRole.trustee,
    identityNumber: 'mock-adaeze',
    email: 'adaeze@example.test',
  );
  const second = KycMember(
    id: 'sipho',
    firstName: 'Sipho',
    lastName: 'Khumalo',
    role: KycMemberRole.trustee,
    identityNumber: 'mock-sipho',
    email: 'sipho@example.test',
  );
  const entity = EntityType.trust;
  setUp(() async {
    clock = DateTime(2026, 8, 1);
    session = SessionService()
      ..signIn(
        const AppUser(
          id: 'signing-user',
          name: 'Investor',
          email: 'investor@example.test',
        ),
      );
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
      now: () => clock,
    );
    repository.saveMember(entity, signer);
    repository.saveMember(entity, second);
    store = KycStore(repository, entity);
    await store.load(requestedStep: 'resolution');
    for (final entry in {
      'resolutionDate': '2026-05-03',
      'meetingLocation': 'Cape Town',
      'investmentCap': '5000000',
      'signatory': 'Adaeze Okoye',
    }.entries) {
      store.edit(entry.key, entry.value);
    }
  });
  tearDown(() {
    store.dispose();
    repository.dispose();
    accounts.dispose();
    context.dispose();
    session.dispose();
  });

  Future<void> signAll() async {
    expect(await store.requestSignatures(), isTrue);
    for (final member in store.members.toList()) {
      expect(await store.simulateSignature(member.id), isTrue);
    }
  }

  test(
    'resolution requests, partial signatures, resend and attachment gate remain consistent',
    () async {
      expect(await store.simulateSignature(signer.id), isFalse);
      expect(await store.requestSignatures(), isTrue);
      expect(
        store.members.every(
          (member) =>
              member.resolutionSignature.status == KycSignatureStatus.awaiting,
        ),
        isTrue,
      );
      expect(await store.simulateSignature(signer.id), isTrue);
      final signedAt = store.members.first.resolutionSignature.signedAt;
      clock = clock.add(const Duration(days: 1));
      expect(await store.requestSignatures(), isTrue);
      expect(store.members.first.resolutionSignature.signedAt, signedAt);
      expect(store.members.last.resolutionSignature.requestedAt, clock);
      expect(store.members.last.signed, isFalse);
      expect(await store.simulateSignature(second.id), isTrue);
      expect(store.canContinue, isFalse);
      expect(
        await store.upload(
          'trustResolution',
          name: 'resolution.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(store.canContinue, isTrue);
      expect(store.continueStep(), isTrue);
      expect(store.selectedStep, 'trustees');
      expect(store.draft!.completedSteps, contains('resolution'));
    },
  );

  test(
    'invalid resolution details and wrong signatories cannot create requests',
    () async {
      store.edit('investmentCap', '');
      expect(await store.requestSignatures(), isFalse);
      expect(store.errors, contains('investmentCap'));
      expect(
        store.members.every(
          (member) =>
              member.resolutionSignature.status ==
              KycSignatureStatus.notRequested,
        ),
        isTrue,
      );
      store.edit('investmentCap', '5000000');
      expect(await store.requestSignatures(memberId: 'unknown'), isFalse);
      expect(
        await repository.requestResolutionSignatures(EntityType.stokvel),
        isA<Failure<KycDraft>>(),
      );
      expect(await store.simulateSignature('unknown'), isFalse);
    },
  );

  test(
    'changed resolution terms invalidate all signatures and old signing previews',
    () async {
      await signAll();
      store.edit('meetingLocation', 'Johannesburg');
      expect(store.members.every((member) => !member.signed), isTrue);
      expect(await store.simulateSignature(signer.id), isFalse);
      expect(await store.requestSignatures(), isTrue);
      expect(await store.simulateSignature(signer.id), isTrue);
      store.edit('occupation', 'Employed');
      expect(store.members.first.signed, isTrue);
    },
  );

  test(
    'changing a signatory identity or roster invalidates prior signatures',
    () async {
      await signAll();
      expect(
        store.saveMember(
          const KycMember(
            id: 'adaeze',
            firstName: 'Adaeze',
            lastName: 'Okoye',
            role: KycMemberRole.trustee,
            identityNumber: 'corrected-id',
            email: 'adaeze@example.test',
          ),
        ),
        isTrue,
      );
      expect(store.members.every((member) => !member.signed), isTrue);
      await signAll();
      expect(
        store.saveMember(
          const KycMember(
            id: 'thandi',
            firstName: 'Thandi',
            lastName: 'Ndlovu',
            role: KycMemberRole.trustee,
            identityNumber: 'mock-thandi',
          ),
        ),
        isTrue,
      );
      expect(store.members.every((member) => !member.signed), isTrue);
      await signAll();
      expect(store.deleteMember('thandi'), isTrue);
      expect(store.members.every((member) => !member.signed), isTrue);
    },
  );

  test(
    'draft saves cannot forge uploaded documents or completed resolution steps',
    () async {
      await signAll();
      final forged = store.draft!.copyWith(
        documents: {
          'trustResolution': KycDocument(
            id: 'forged',
            name: 'forged.pdf',
            bytes: 100,
            mimeType: 'application/pdf',
            uploadedAt: clock,
          ),
        },
        completedSteps: {'resolution'},
      );
      final saved = repository.save(forged) as Success<KycDraft>;
      expect(saved.value.documents, isEmpty);
      expect(saved.value.completedSteps, isNot(contains('resolution')));
    },
  );

  test(
    'failed requests and signatures retry without premature success',
    () async {
      behavior.failNext();
      expect(await store.requestSignatures(), isFalse);
      expect(
        store.members.every(
          (member) =>
              member.resolutionSignature.status ==
              KycSignatureStatus.notRequested,
        ),
        isTrue,
      );
      expect(store.busy, isFalse);
      expect(await store.requestSignatures(), isTrue);
      behavior.failNext();
      expect(await store.simulateSignature(signer.id), isFalse);
      expect(store.members.first.signed, isFalse);
      expect(await store.simulateSignature(signer.id), isTrue);
      final signedAt = store.members.first.resolutionSignature.signedAt;
      clock = clock.add(const Duration(days: 1));
      expect(await store.simulateSignature(signer.id), isTrue);
      expect(store.members.first.resolutionSignature.signedAt, signedAt);
    },
  );

  test('a profile switch cancels a pending signature request', () async {
    final pending = repository.requestResolutionSignatures(entity);
    context.selectEntity(EntityType.company);
    expect(await pending, isA<Failure<KycDraft>>());
    context.selectEntity(entity);
    final current = (await repository.load(entity) as Success<KycDraft>).value;
    expect(
      current.members.every(
        (member) =>
            member.resolutionSignature.status ==
            KycSignatureStatus.notRequested,
      ),
      isTrue,
    );
  });
}
