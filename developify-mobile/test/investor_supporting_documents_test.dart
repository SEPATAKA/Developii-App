import 'package:flutter_test/flutter_test.dart';
import 'package:developify_mobile/app/environment/app_environment.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/services/mock_behavior.dart';
import 'package:developify_mobile/core/services/session_service.dart';
import 'package:developify_mobile/features/investor/data/mock_investor_account_repository.dart';
import 'package:developify_mobile/features/investor/data/mock_kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

void main() {
  late SessionService session;
  late InvestorAccountContext context;
  late MockInvestorAccountRepository accounts;
  late MockKycRepository repository;
  late MockBehavior behavior;
  setUp(() {
    session = SessionService()
      ..signIn(
        const AppUser(
          id: 'supporting-documents',
          name: 'Investor',
          email: 'investor@example.test',
        ),
      );
    context = InvestorAccountContext(session);
    behavior = MockBehavior(delay: Duration.zero);
    accounts = MockInvestorAccountRepository(behavior, context);
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
  Future<KycDraft> load(EntityType entity) async =>
      (await repository.load(entity) as Success<KycDraft>).value;
  Future<KycStore> createStore(EntityType entity) async {
    final store = KycStore(repository, entity);
    addTearDown(store.dispose);
    await store.load(requestedStep: 'funds');
    store.edit('fundSources', store.step!.fields.first.options.first);
    if (entity == EntityType.trust) {
      store.edit('trustCapital', '12500000');
    } else {
      store.edit('annualTurnover', '38400000');
      store.edit('auditor', 'BDO South Africa');
    }
    store.edit('annualInvestment', '1000000');
    return store;
  }

  Future<bool> upload(KycStore store, String name, {String? documentId}) =>
      store.upload(
        'fundsEvidence',
        name: name,
        bytes: 120 * 1024,
        mimeType: 'application/pdf',
        append: documentId == null,
        documentId: documentId,
      );

  for (final entity in [EntityType.trust, EntityType.company]) {
    test(
      '${entity.name} evidence keeps files, replaces by ID and deletes one',
      () async {
        final store = await createStore(entity);
        expect(await upload(store, 'Statements.pdf'), isTrue);
        expect(store.saveAndExit(), isTrue);
        expect(
          await repository.simulateRequirementApproval(entity, 'funds'),
          isA<Success<KycDraft>>(),
        );
        await store.load(requestedStep: 'funds');
        expect(store.draft!.verifiedSteps, contains('funds'));
        expect(await upload(store, 'Sale_agreement.pdf'), isTrue);
        expect(store.draft!.verifiedSteps, isNot(contains('funds')));
        final files = store.draft!.documentsFor('fundsEvidence');
        expect(files.map((file) => file.name), [
          'Statements.pdf',
          'Sale_agreement.pdf',
        ]);
        expect(files.map((file) => file.id).toSet(), hasLength(2));
        expect(() => files.clear(), throwsUnsupportedError);
        expect(
          () => store.draft!.additionalDocuments['fundsEvidence']!.clear(),
          throwsUnsupportedError,
        );
        expect(store.canContinue, isTrue);
        expect(
          await upload(
            store,
            'Signed_sale_agreement.pdf',
            documentId: files.last.id,
          ),
          isTrue,
        );
        final replaced = store.draft!.documentsFor('fundsEvidence');
        expect(replaced.first, same(files.first));
        expect(replaced.last.name, 'Signed_sale_agreement.pdf');
        expect(
          store.deleteDocument('fundsEvidence', documentId: files.first.id),
          isTrue,
        );
        expect(store.draft!.documents['fundsEvidence'], same(replaced.last));
        expect(store.draft!.additionalDocuments, isEmpty);
        expect(store.canContinue, isTrue);
        expect(
          store.deleteDocument('fundsEvidence', documentId: replaced.last.id),
          isTrue,
        );
        expect(store.draft!.documentsFor('fundsEvidence'), isEmpty);
        expect(store.canContinue, isFalse);
      },
    );

    test(
      '${entity.name} failed evidence retries preserve append and replacement intent',
      () async {
        final store = await createStore(entity);
        expect(await upload(store, 'Statements.pdf'), isTrue);
        final original = store.draft!.documentsFor('fundsEvidence').single;
        behavior.failNext();
        expect(await upload(store, 'Sale_agreement.pdf'), isFalse);
        expect(store.draft!.documentsFor('fundsEvidence'), [original]);
        expect(store.canContinue, isFalse);
        expect(store.documentUploads['fundsEvidence']!.append, isTrue);
        expect(await store.retryUpload('fundsEvidence'), isTrue);
        final second = store.draft!.documentsFor('fundsEvidence').last;
        behavior.failNext();
        expect(
          await upload(store, 'Signed_sale.pdf', documentId: second.id),
          isFalse,
        );
        expect(store.draft!.documentsFor('fundsEvidence'), [original, second]);
        expect(await store.retryUpload('fundsEvidence'), isTrue);
        expect(store.draft!.documentsFor('fundsEvidence'), hasLength(2));
        expect(
          store.draft!.documentsFor('fundsEvidence').last.name,
          'Signed_sale.pdf',
        );
        behavior.failNext();
        expect(await upload(store, 'Cancelled.pdf'), isFalse);
        store.cancelUpload('fundsEvidence');
        expect(store.canContinue, isTrue);
        expect(store.draft!.documentsFor('fundsEvidence'), hasLength(2));
      },
    );

    test(
      '${entity.name} evidence rejects forged, stale and invalid document writes',
      () async {
        final store = await createStore(entity);
        expect(await upload(store, 'Statements.pdf'), isTrue);
        final original = store.draft!.documentsFor('fundsEvidence').single;
        final forged = store.draft!.copyWith(
          additionalDocuments: {
            'fundsEvidence': [original],
          },
        );
        expect(repository.save(forged), isA<Success<KycDraft>>());
        expect((await load(entity)).documentsFor('fundsEvidence'), [original]);
        expect(
          await upload(store, 'Replacement.pdf', documentId: 'missing'),
          isFalse,
        );
        store.cancelUpload('fundsEvidence');
        expect(
          store.deleteDocument('fundsEvidence', documentId: 'missing'),
          isFalse,
        );
        expect(
          await store.upload(
            'fundsEvidence',
            name: 'Large.pdf',
            bytes: 6 * 1024 * 1024,
            mimeType: 'application/pdf',
            append: true,
          ),
          isFalse,
        );
        store.cancelUpload('fundsEvidence');
        expect((await load(entity)).documentsFor('fundsEvidence'), [original]);
        final rejected = KycDocument(
          id: 'rejected',
          name: 'Rejected.pdf',
          bytes: 100,
          mimeType: 'application/pdf',
          uploadedAt: DateTime(2026),
          rejection: 'Replace this evidence.',
        );
        final definition = KycPlans.steps(
          entity,
        ).firstWhere((step) => step.id == 'funds');
        expect(
          KycValidation.step(
            store.draft!.copyWith(
              additionalDocuments: {
                'fundsEvidence': [rejected],
              },
            ),
            definition,
          )['fundsEvidence'],
          'Replace this evidence.',
        );
        final other = entity == EntityType.trust
            ? EntityType.company
            : EntityType.trust;
        expect((await load(other)).documentsFor('fundsEvidence'), isEmpty);
        session.signOut();
        await Future<void>.delayed(Duration.zero);
        session.signIn(
          const AppUser(
            id: 'next-user',
            name: 'New Investor',
            email: 'next@example.test',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect((await load(entity)).documentsFor('fundsEvidence'), isEmpty);
      },
    );
  }

  test('A single-document requirement rejects append requests', () async {
    expect(
      await repository.upload(
        EntityType.trust,
        'trustDeed',
        name: 'Deed.pdf',
        bytes: 1024,
        mimeType: 'application/pdf',
        append: true,
      ),
      isA<Failure<KycDraft>>(),
    );
    expect((await load(EntityType.trust)).documents, isEmpty);
  });
}
