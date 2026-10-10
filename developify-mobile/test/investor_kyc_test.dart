import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late MockInvestorAccountRepository accounts;
  late MockKycRepository repository;
  late MockBehavior behavior;
  final now = DateTime(2026, 9, 12);
  const user = AppUser(
    id: 'kyc-user',
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
      now: () => now,
    );
  });
  tearDown(() async {
    repository.dispose();
    accounts.dispose();
    context.dispose();
    session.dispose();
  });
  Future<KycDraft> draft(EntityType entity) async =>
      (await repository.load(entity) as Success<KycDraft>).value;
  Future<void> fill(EntityType entity) async {
    var current = await draft(entity);
    final values = <String, String>{};
    for (final step in KycPlans.steps(entity)) {
      for (final field in step.fields.where(
        (field) => field.visibleWhen == null,
      )) {
        values[field.key] = switch (field.kind) {
          KycFieldKind.choice ||
          KycFieldKind.multipleChoice => field.options.first,
          KycFieldKind.toggle => field.required ? 'true' : 'false',
          KycFieldKind.date => '2024-01-10',
          KycFieldKind.amount => '100000',
          KycFieldKind.number => '123456',
          KycFieldKind.email => 'investor@example.test',
          _ => 'Example Holdings',
        };
      }
    }
    expect(
      repository.save(current.copyWith(values: values)),
      isA<Success<KycDraft>>(),
    );
    for (final declaration in KycReviewPlan.declarations(entity)) {
      values[declaration.key] = 'true';
    }
    current = await draft(entity);
    repository.save(current.copyWith(values: values));
    for (final step in KycPlans.steps(entity)) {
      for (final document in step.documents) {
        expect(
          await repository.upload(
            entity,
            document.key,
            name: '${document.key}.pdf',
            bytes: 120 * 1024,
            mimeType: 'application/pdf',
          ),
          isA<Success<KycDraft>>(),
        );
      }
    }
    final roles = KycPlans.steps(
      entity,
    ).expand((step) => step.memberRoles).toSet();
    for (final role in roles) {
      expect(
        repository.saveMember(
          entity,
          KycMember(
            id: role.name,
            firstName: 'Adaeze',
            lastName: 'Okoye',
            role: role,
            identityNumber: 'mock-${role.name}',
            email: 'member@example.test',
            shareBasisPoints:
                role == KycMemberRole.shareholder ||
                    role == KycMemberRole.beneficiary
                ? 10000
                : 0,
            identityVerified: true,
            addressVerified: true,
          ),
        ),
        isA<Success<KycDraft>>(),
      );
    }
    current = await draft(entity);
    if (entity == EntityType.company) {
      repository.save(
        current.copyWith(values: {...current.values, 'membersPresent': '1'}),
      );
    }
    if (entity == EntityType.company || entity == EntityType.trust) {
      expect(
        await repository.requestResolutionSignatures(entity),
        isA<Success<KycDraft>>(),
      );
      current = await draft(entity);
      final resolution = KycPlans.steps(
        entity,
      ).firstWhere((step) => step.id == 'resolution');
      for (final member in current.members.where(resolution.includesMember)) {
        expect(
          await repository.simulateResolutionSignature(entity, member.id),
          isA<Success<KycDraft>>(),
        );
      }
      current = await draft(entity);
    }
    expect(
      repository.save(current.copyWith(currentStep: 'review')),
      isA<Success<KycDraft>>(),
    );
  }

  test(
    'Requirement readiness and approval are separate and edits invalidate only affected approval',
    () async {
      const entity = EntityType.individual;
      expect(
        await repository.simulateRequirementApproval(entity, 'identity'),
        isA<Failure<KycDraft>>(),
      );
      await fill(entity);
      var current = await draft(entity);
      expect(current.completedSteps, contains('identity'));
      expect(current.verifiedSteps, isNot(contains('identity')));
      expect(
        await repository.simulateRequirementApproval(entity, 'identity'),
        isA<Success<KycDraft>>(),
      );
      expect(
        await repository.simulateRequirementApproval(entity, 'address'),
        isA<Success<KycDraft>>(),
      );
      current = await draft(entity);
      expect(current.status, VerificationStatus.incomplete);
      expect(current.verifiedSteps, containsAll(['identity', 'address']));
      repository.save(
        current.copyWith(
          values: {
            ...current.values,
            'accountName': 'Changed bank account name',
          },
        ),
      );
      current = await draft(entity);
      expect(current.verifiedSteps, containsAll(['identity', 'address']));
      await repository.upload(
        entity,
        'identityFront',
        name: 'New_passport.pdf',
        bytes: 120000,
        mimeType: 'application/pdf',
      );
      current = await draft(entity);
      expect(current.completedSteps, contains('identity'));
      expect(current.verifiedSteps, isNot(contains('identity')));
      expect(current.verifiedSteps, contains('address'));
      expect(
        await repository.simulateRequirementApproval(entity, 'unknown'),
        isA<Failure<KycDraft>>(),
      );
      expect((await draft(EntityType.trust)).verifiedSteps, isEmpty);
    },
  );

  test(
    'Caller supplied draft flags cannot forge requirement approval',
    () async {
      const entity = EntityType.stokvel;
      await fill(entity);
      var current = await draft(entity);
      expect(current.completedSteps, contains('register'));
      repository.save(current.copyWith(verifiedSteps: current.completedSteps));
      current = await draft(entity);
      expect(current.verifiedSteps, isEmpty);
      expect(
        await repository.simulateRequirementApproval(entity, 'register'),
        isA<Success<KycDraft>>(),
      );
      current = await draft(entity);
      expect(current.verifiedSteps, {'register'});
      repository.deleteDocument(entity, 'memberRegister');
      current = await draft(entity);
      expect(current.verifiedSteps, isEmpty);
      expect(current.completedSteps, isNot(contains('register')));
      session.signOut();
      expect(
        await repository.simulateRequirementApproval(entity, 'register'),
        isA<Failure<KycDraft>>(),
      );
    },
  );

  test(
    'Trust review requires every declaration and returns edited sections to review',
    () async {
      await fill(EntityType.trust);
      final store = KycStore(repository, EntityType.trust);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'review');
      expect(store.canSubmit, isTrue);
      for (final declaration in KycReviewPlan.trustDeclarations) {
        store.edit(declaration.key, 'false');
        expect(store.canSubmit, isFalse, reason: declaration.key);
        expect(await store.submit(), isFalse);
        expect(store.errors, contains(declaration.key));
        store.edit(declaration.key, 'true');
      }
      expect(store.selectStep('funds'), isTrue);
      expect(store.reviewingStep, isTrue);
      store.edit('annualInvestment', '250000');
      expect(store.continueStep(), isTrue);
      expect(store.selectedStep, 'review');
      expect(store.reviewingStep, isFalse);
      expect(store.draft!.values['annualInvestment'], '250000');
      expect(store.canSubmit, isTrue);
    },
  );

  test(
    'Natural review requires consent and applies PEP declarations conditionally',
    () async {
      await fill(EntityType.individual);
      final store = KycStore(repository, EntityType.individual);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'review');
      store.edit('reviewConsent', 'false');
      expect(store.canSubmit, isFalse);
      expect(await store.submit(), isFalse);
      expect(store.errors, contains('reviewConsent'));
      store.edit('reviewConsent', 'true');
      for (final field in KycReviewPlan.naturalDeclarations.where(
        (field) => field.key != 'reviewConsent',
      )) {
        store.edit(field.key, 'false');
      }
      expect(store.canSubmit, isTrue);
      for (final entry in {
        'pep': KycTaxPlan.pepYes,
        'pepRelationship': 'Self',
        'pepType': 'Domestic PEP',
        'pepCountry': 'South Africa',
        'pepPosition': 'Mayor',
        'pepOrganization': 'City Council',
        'pepStart': '2024-02-01',
        'pepStatus': 'Current',
        'pepName': 'Example Investor',
        'pepIdentityRelationship': 'Self',
        'pepWealth': 'Employment and savings',
        'pepNetWorth': '1200000',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      for (final field in KycReviewPlan.naturalDeclarations.where(
        (field) => field.key != 'reviewConsent',
      )) {
        expect(await store.submit(), isFalse);
        expect(store.errors, contains(field.key));
        store.edit(field.key, 'true');
      }
      expect(store.canSubmit, isTrue);
      store.edit('pep', KycTaxPlan.pepNo);
      store.edit('reviewWealth', 'false');
      expect(store.canSubmit, isTrue);
      expect(await store.submit(), isTrue);
      expect(store.draft!.status, VerificationStatus.pending);
    },
  );

  test(
    'Sample identity summary follows a successful upload and cannot be forged by saving a draft',
    () async {
      const entity = EntityType.individual;
      expect((await draft(entity)).identitySummary, isNull);
      await repository.upload(
        entity,
        'identityFront',
        name: 'sample-passport.jpg',
        bytes: 120 * 1024,
        mimeType: 'image/jpeg',
      );
      var current = await draft(entity);
      expect(current.identitySummary!.name, user.name);
      expect(current.identitySummary!.residence, user.address);
      expect(current.identitySummary!.birthDate, DateTime(1992, 6, 14));
      repository.save(
        current.copyWith(
          identitySummary: KycIdentitySummary(
            name: 'Forged',
            birthDate: DateTime(1900),
            nationality: 'Forged',
            residence: 'Forged',
          ),
        ),
      );
      current = await draft(entity);
      expect(current.identitySummary!.name, user.name);
      repository.deleteDocument(entity, 'identityFront');
      expect((await draft(entity)).identitySummary, isNull);
      behavior.failNext();
      expect(
        await repository.upload(
          entity,
          'identityFront',
          name: 'retry.jpg',
          bytes: 120 * 1024,
          mimeType: 'image/jpeg',
        ),
        isA<Failure<KycDraft>>(),
      );
      expect((await draft(entity)).identitySummary, isNull);
      session.signOut();
      session.signIn(user);
      await Future<void>.delayed(Duration.zero);
      expect((await draft(entity)).identitySummary, isNull);
    },
  );

  test(
    'Trust can submit pending trustee checks but approval requires their resolution',
    () async {
      await fill(EntityType.trust);
      final store = KycStore(repository, EntityType.trust);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'review');
      final member = store.draft!.members.firstWhere(
        (member) => member.role == KycMemberRole.trustee,
      );
      store.saveMember(
        member.copyWith(
          identityVerified: false,
          resolutionSignature: const KycResolutionSignature(
            status: KycSignatureStatus.awaiting,
          ),
        ),
      );
      expect(store.canSubmit, isTrue);
      expect(await store.submit(), isTrue);
      expect(await store.simulateReview(true), isFalse);
      expect(store.draft!.status, VerificationStatus.pending);
      expect(store.error, contains('Resolve the pending'));
      expect(await store.simulateReview(false), isTrue);
      expect(store.draft!.status, VerificationStatus.correctionRequired);
      final rejected = store.draft!.documents.entries.firstWhere(
        (entry) => entry.value.rejection != null,
      );
      expect(
        await store.upload(
          rejected.key,
          name: 'corrected.pdf',
          bytes: 1200,
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(
        store.saveMember(
          store.draft!.members
              .firstWhere((value) => value.id == member.id)
              .copyWith(identityVerified: true),
        ),
        isTrue,
      );
      expect(await store.requestSignatures(), isTrue);
      expect(await store.simulateSignature(member.id), isTrue);
      expect(await store.submit(), isTrue);
      expect(await store.simulateReview(true), isTrue);
      expect(store.draft!.status, VerificationStatus.verified);
    },
  );

  test(
    'secondary residencies validate, edit, resume and remain isolated',
    () async {
      final store = KycStore(repository, EntityType.individual);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'tax');
      store.edit('taxCountry', 'South Africa');
      store.edit('secondaryTax', 'true');
      expect(store.saveTaxSection(KycTaxSection.residency), isFalse);
      void enterResidency(String country) {
        for (final entry in {
          'secondaryTaxCountry': country,
          'secondaryReason': 'Employment',
          'secondaryTinType': 'Tax identification number',
          'secondaryTinFormat': '10 digits',
          'secondaryTin': '1234567890',
          'secondaryResidentSince': '2023-07-02',
          'secondaryStatus': 'Current',
          'usPerson': 'false',
          'secondaryCertification': 'true',
        }.entries) {
          store.edit(entry.key, entry.value);
        }
      }

      enterResidency('South Africa');
      expect(store.saveTaxSection(KycTaxSection.residency), isFalse);
      expect(
        store.errors['secondaryTaxCountry'],
        'This country is already on file.',
      );
      store.edit('secondaryTaxCountry', 'United Kingdom');
      expect(store.saveTaxSection(KycTaxSection.residency), isTrue);
      expect(store.draft!.values['secondaryTin'], isNull);
      enterResidency('Nigeria');
      expect(store.saveTaxSection(KycTaxSection.residency), isTrue);
      expect(store.draft!.taxResidencies, hasLength(2));
      enterResidency('Nigeria');
      expect(store.saveTaxSection(KycTaxSection.residency), isFalse);
      store.beginTaxResidency('united-kingdom');
      expect(store.errors, isEmpty);
      store.edit('secondaryTin', '9988776655');
      expect(store.saveTaxSection(KycTaxSection.residency), isTrue);
      await store.load(requestedStep: 'tax');
      expect(store.draft!.taxResidencies.first.tin, '9988776655');
      expect(store.draft!.taxResidencies, hasLength(2));
      store.beginTaxResidency('united-kingdom');
      store.edit('secondaryReason', 'Family');
      expect(store.saveAndExit(), isTrue);
      final resumed = KycStore(repository, EntityType.individual);
      addTearDown(resumed.dispose);
      await resumed.load(requestedStep: 'tax');
      expect(resumed.draft!.values['secondaryReason'], 'Family');
      expect(resumed.draft!.taxResidencies.first.reason, 'Employment');
      resumed.beginTaxResidency(null);
      expect(resumed.draft!.values['secondaryTaxCountry'], 'Nigeria');
      expect(resumed.draft!.values['secondaryReason'], 'Employment');
      resumed.edit('secondaryReason', 'New residency draft');
      resumed.beginTaxResidency('nigeria');
      resumed.edit('secondaryTin', '1122334455');
      resumed.beginTaxResidency('united-kingdom');
      expect(resumed.draft!.values['secondaryReason'], 'Family');
      resumed.beginTaxResidency(null);
      expect(resumed.draft!.values['secondaryReason'], 'New residency draft');
      resumed.beginTaxResidency('nigeria');
      expect(resumed.draft!.values['secondaryTin'], '1122334455');
      expect(resumed.deleteTaxResidency('united-kingdom'), isTrue);
      expect(resumed.draft!.taxResidencies.single.country, 'Nigeria');
      expect((await draft(EntityType.company)).taxResidencies, isEmpty);
      session.signOut();
      session.signIn(user);
      await Future<void>.delayed(Duration.zero);
      await resumed.load(requestedStep: 'tax');
      expect(resumed.draft!.taxResidencies, isEmpty);
      expect(resumed.draft!.taxResidencyEdits, isEmpty);
    },
  );

  test(
    'PEP completion requires role, wealth and declarations only when applicable',
    () async {
      final store = KycStore(repository, EntityType.individual);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'tax');
      for (final entry in {
        'taxCountry': 'South Africa',
        'tin': '1234567890',
        'pep': KycTaxPlan.pepNo,
        'sanctions': 'true',
        'declaration': 'true',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(store.canContinue, isTrue);
      store.edit('pep', KycTaxPlan.pepYes);
      expect(store.canContinue, isFalse);
      expect(store.saveTaxSection(KycTaxSection.pep), isFalse);
      for (final entry in {
        'pepRelationship': 'Self',
        'pepType': 'Domestic PEP',
        'pepCountry': 'South Africa',
        'pepPosition': 'Mayor',
        'pepOrganization': 'City Council',
        'pepStart': '2024-02-01',
        'pepStatus': 'Current',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(store.saveTaxSection(KycTaxSection.pep), isTrue);
      expect(store.canContinue, isFalse);
      for (final entry in {
        'pepName': 'Example Investor',
        'pepIdentityRelationship': 'Self',
        'pepWealth': 'Employment and savings',
        'pepNetWorth': '-2',
      }.entries) {
        store.edit(entry.key, entry.value);
      }
      expect(store.saveTaxSection(KycTaxSection.wealth), isFalse);
      store.edit('pepNetWorth', '1200000');
      expect(store.saveTaxSection(KycTaxSection.wealth), isTrue);
      expect(store.canContinue, isTrue);
      store.edit('secondaryTax', 'true');
      expect(store.canContinue, isFalse);
      store.edit('secondaryTax', 'false');
      expect(store.canContinue, isTrue);
      store.edit('pepName', '');
      expect(store.canContinue, isFalse);
      store.edit('pep', KycTaxPlan.pepNo);
      expect(store.canContinue, isTrue);
    },
  );

  for (final entity in EntityType.values) {
    test(
      '${entity.name} validates, saves, resumes, submits and completes its own KYC steps',
      () async {
        context.selectEntity(entity);
        expect(await repository.submit(entity), isA<Failure<KycDraft>>());
        await fill(entity);
        final first = KycStore(repository, entity);
        await first.load();
        expect(first.selectedStep, 'review');
        expect(first.completed, KycPlans.steps(entity).length);
        first.dispose();
        final resumed = KycStore(repository, entity);
        await resumed.load();
        expect(resumed.selectedStep, 'review');
        expect(await resumed.submit(), true, reason: resumed.error);
        final submission = resumed.draft!.submissionId;
        expect(resumed.draft!.status, VerificationStatus.pending);
        expect(await resumed.submit(), true);
        expect(resumed.draft!.submissionId, submission);
        expect(await resumed.simulateReview(true), true);
        expect(resumed.draft!.status, VerificationStatus.verified);
        final account =
            (await accounts.snapshot() as Success<InvestorAccountSnapshot>)
                .value;
        expect(account.verification, VerificationStatus.verified);
        expect(resumed.editable, false);
        resumed.dispose();
      },
    );
  }
  test(
    'Documents validate type, size and slot, and support replacement and deletion',
    () async {
      const entity = EntityType.individual;
      for (final input in [
        ('proof.exe', 120, 'application/pdf'),
        ('proof.pdf', 6 * 1024 * 1024, 'application/pdf'),
        ('proof.pdf', 120, 'image/png'),
        ('../proof.pdf', 120, 'application/pdf'),
      ]) {
        expect(
          await repository.upload(
            entity,
            'identityFront',
            name: input.$1,
            bytes: input.$2,
            mimeType: input.$3,
          ),
          isA<Failure<KycDraft>>(),
        );
      }
      expect(
        await repository.upload(
          entity,
          'unknown',
          name: 'proof.pdf',
          bytes: 120,
          mimeType: 'application/pdf',
        ),
        isA<Failure<KycDraft>>(),
      );
      expect(
        await repository.upload(
          entity,
          'identityFront',
          name: 'front.jpg',
          bytes: 120,
          mimeType: 'image/jpeg',
        ),
        isA<Success<KycDraft>>(),
      );
      final firstId = (await draft(entity)).documents['identityFront']!.id;
      expect(
        await repository.upload(
          entity,
          'identityFront',
          name: 'replacement.png',
          bytes: 160,
          mimeType: 'image/png',
        ),
        isA<Success<KycDraft>>(),
      );
      expect(
        (await draft(entity)).documents['identityFront']!.id,
        isNot(firstId),
      );
      expect(
        repository.deleteDocument(entity, 'identityFront'),
        isA<Success<KycDraft>>(),
      );
      expect(
        (await draft(entity)).documents.containsKey('identityFront'),
        false,
      );
    },
  );
  test(
    'A rejected document must be replaced before a corrected application can be submitted',
    () async {
      const entity = EntityType.individual;
      await fill(entity);
      expect(await repository.submit(entity), isA<Success<KycDraft>>());
      expect(
        await repository.simulateReview(entity, approved: false),
        isA<Success<KycDraft>>(),
      );
      final rejected = await draft(entity);
      expect(rejected.status, VerificationStatus.correctionRequired);
      final slot = rejected.documents.entries
          .singleWhere((entry) => entry.value.rejection != null)
          .key;
      expect(await repository.submit(entity), isA<Failure<KycDraft>>());
      expect(
        await repository.upload(
          entity,
          slot,
          name: 'replacement.jpg',
          bytes: 120000,
          mimeType: 'image/jpeg',
        ),
        isA<Success<KycDraft>>(),
      );
      expect(await repository.submit(entity), isA<Success<KycDraft>>());
      expect(
        await repository.simulateReview(entity, approved: true),
        isA<Success<KycDraft>>(),
      );
      expect((await draft(entity)).status, VerificationStatus.verified);
    },
  );
  test(
    'Failed upload can be retried and disposed stores do not accept late updates',
    () async {
      final store = KycStore(repository, EntityType.individual);
      await store.load();
      behavior.failNext();
      expect(
        await store.upload(
          'identityFront',
          name: 'front.jpg',
          bytes: 120,
          mimeType: 'image/jpeg',
        ),
        false,
      );
      expect(store.error, isNotNull);
      expect(store.draft!.documents.containsKey('identityFront'), false);
      expect(
        await store.upload(
          'identityFront',
          name: 'front.jpg',
          bytes: 120,
          mimeType: 'image/jpeg',
        ),
        true,
      );
      final pending = store.load();
      store.dispose();
      await pending;
      expect(store.draft, isNull);
    },
  );
  test(
    'Entity and user changes keep drafts isolated and cancel pending uploads',
    () async {
      const individual = EntityType.individual;
      final initial = await draft(individual);
      expect(
        repository.save(
          initial.copyWith(values: {'idType': 'South African ID'}),
        ),
        isA<Success<KycDraft>>(),
      );
      final pending = repository.upload(
        individual,
        'identityFront',
        name: 'front.jpg',
        bytes: 120,
        mimeType: 'image/jpeg',
      );
      context.selectEntity(EntityType.trust);
      expect(await pending, isA<Failure<KycDraft>>());
      expect((await draft(EntityType.trust)).values, isEmpty);
      context.selectEntity(individual);
      expect((await draft(individual)).values['idType'], 'South African ID');
      session.signOut();
      session.signIn(user);
      expect((await draft(individual)).values, isEmpty);
    },
  );
  test(
    'Share allocation, required member checks and simulated invites are validated',
    () async {
      const entity = EntityType.company;
      context.selectEntity(entity);
      await fill(entity);
      final existing = (await draft(entity)).members.firstWhere(
        (member) => member.role == KycMemberRole.shareholder,
      );
      expect(
        repository.saveMember(
          entity,
          KycMember(
            id: existing.id,
            firstName: existing.firstName,
            lastName: existing.lastName,
            role: existing.role,
            identityNumber: existing.identityNumber,
            shareBasisPoints: 6200,
            identityVerified: true,
            addressVerified: true,
          ),
        ),
        isA<Success<KycDraft>>(),
      );
      expect(await repository.submit(entity), isA<Failure<KycDraft>>());
      expect(
        await repository.invite(
          entity,
          KycInvite(email: 'invalid', memberId: existing.id),
        ),
        isA<Failure<KycDraft>>(),
      );
      expect(
        await repository.invite(
          entity,
          KycInvite(email: 'member@example.test', memberId: existing.id),
        ),
        isA<Success<KycDraft>>(),
      );
      expect(
        (await draft(
          entity,
        )).members.firstWhere((member) => member.id == existing.id).inviteSent,
        true,
      );
      expect(
        repository.deleteMember(entity, existing.id),
        isA<Success<KycDraft>>(),
      );
    },
  );

  test(
    'Cancelling a pending document prevents a late repository write',
    () async {
      final store = KycStore(repository, EntityType.individual);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'address');
      final operation = store.upload(
        'addressProof',
        name: 'Electricity bill.pdf',
        bytes: 120 * 1024,
        mimeType: 'application/pdf',
      );
      expect(
        store.documentUploads['addressProof']!.status,
        KycUploadStatus.uploading,
      );
      expect(store.busy, isTrue);
      expect(store.canContinue, isFalse);
      store.cancelUpload('addressProof');
      expect(await operation, isFalse);
      expect(store.busy, isFalse);
      expect(store.documentUploads, isEmpty);
      expect(
        (await draft(
          EntityType.individual,
        )).documents.containsKey('addressProof'),
        isFalse,
      );
    },
  );

  test(
    'Failed document retries preserve the file and wait for repository success',
    () async {
      final store = KycStore(repository, EntityType.individual);
      addTearDown(store.dispose);
      await store.load(requestedStep: 'address');
      behavior.failNext();
      expect(
        await store.upload(
          'addressProof',
          name: 'Electricity bill.pdf',
          bytes: 120 * 1024,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      final attempt = store.documentUploads['addressProof']!;
      expect(attempt.status, KycUploadStatus.failed);
      expect(attempt.error, isNotEmpty);
      expect(store.canContinue, isFalse);
      expect(store.draft!.documents.containsKey('addressProof'), isFalse);
      final retry = store.retryUpload('addressProof');
      expect(
        store.documentUploads['addressProof']!.status,
        KycUploadStatus.uploading,
      );
      expect(store.draft!.documents.containsKey('addressProof'), isFalse);
      expect(await retry, isTrue);
      expect(store.documentUploads, isEmpty);
      expect(store.draft!.documents['addressProof']!.name, attempt.name);
      expect(store.canContinue, isTrue);
      expect(await store.retryUpload('addressProof'), isFalse);
    },
  );

  test(
    'Discarding or cancelling a failed replacement preserves the reviewed file',
    () async {
      const entity = EntityType.individual;
      await repository.upload(
        entity,
        'addressProof',
        name: 'Original.pdf',
        bytes: 120 * 1024,
        mimeType: 'application/pdf',
      );
      repository.save(await draft(entity));
      await repository.simulateRequirementApproval(entity, 'address');
      final original = (await draft(entity)).documents['addressProof'];
      final store = KycStore(repository, entity);
      await store.load(requestedStep: 'address');
      behavior.failNext();
      expect(
        await store.upload(
          'addressProof',
          name: 'Replacement.pdf',
          bytes: 140 * 1024,
          mimeType: 'application/pdf',
        ),
        isFalse,
      );
      expect(store.canContinue, isFalse);
      expect(store.continueStep(), isFalse);
      expect(await store.submit(), isFalse);
      store.cancelUpload('addressProof');
      expect(store.canContinue, isTrue);
      expect(store.draft!.documents['addressProof'], same(original));
      expect(store.draft!.verifiedSteps, contains('address'));
      final operation = store.upload(
        'addressProof',
        name: 'Replacement.pdf',
        bytes: 140 * 1024,
        mimeType: 'application/pdf',
      );
      store.dispose();
      expect(await operation, isFalse);
      expect(store.documentUploads, isEmpty);
      final after = await draft(entity);
      expect(after.documents['addressProof'], same(original));
      expect(after.verifiedSteps, contains('address'));
    },
  );
}
