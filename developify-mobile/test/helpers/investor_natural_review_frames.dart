import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

const investorNaturalReviewFrames = {'53047', '53211', '53372', '53660'};

Future<void> seedInvestorNaturalReviewFrame(
  KycRepository repository,
  String node,
) async {
  if (!investorNaturalReviewFrames.contains(node)) return;
  const entity = EntityType.individual;
  final pep = node == '53372' || node == '53660';
  final checked = node == '53047' || node == '53660';
  Future<KycDraft> current() async =>
      (await repository.load(entity) as Success<KycDraft>).value;
  void requireSuccess(Result<KycDraft> result) {
    if (result case Failure(:final error)) throw StateError(error.message);
  }

  requireSuccess(
    repository.save(
      (await current()).copyWith(
        values: {
          ...KycDemoFixtures.verified(entity, DateTime(2026, 7, 22)).values,
          'idType': 'International passport',
          'fundSources': KycPlans.naturalPerson
              .firstWhere((step) => step.id == 'funds')
              .fields
              .first
              .options
              .first,
          'employer': 'Northwind Studio',
          'annualIncome': '600000',
          'taxCountry': 'South Africa',
          'tin': '1234567890',
          'pep': pep ? KycTaxPlan.pepYes : KycTaxPlan.pepNo,
          'pepRelationship': 'Self',
          'pepType': 'Domestic PEP',
          'pepCountry': 'South Africa',
          'pepPosition': 'Member of Parliament',
          'pepOrganization': 'Parliament of South Africa',
          'pepStart': '2026-06-30',
          'pepStatus': 'Current',
          'pepName': 'Babatunde Yusuf',
          'pepIdentityRelationship': 'Self',
          'pepWealth':
              'Salary from Parliament since 2019 plus prior earnings as a senior consultant at Deloitte (2012–2018) and inheritance received from my late father in 2016.',
          'pepNetWorth': '10000000',
          for (final field in KycReviewPlan.naturalDeclarations)
            field.key: checked.toString(),
        },
      ),
    ),
  );
  for (final slot in KycPlans.naturalPerson.expand((step) => step.documents)) {
    if (slot.key == 'pepWealthProof' && !pep) continue;
    requireSuccess(
      await repository.upload(
        entity,
        slot.key,
        name: switch (slot.key) {
          'identityFront' => 'passport_jp.jpg',
          'identityBack' => 'passport_reverse.jpg',
          'selfie' => 'selfie.jpg',
          'addressProof' => 'bill_Apr.pdf',
          'bankProof' => 'Account Confirmation.pdf',
          'pepWealthProof' => 'SARS assets declarations.pdf',
          _ => '${slot.key}.pdf',
        },
        bytes: switch (slot.key) {
          'identityFront' => 1887437,
          'selfie' => 4404019,
          'addressProof' => 512 * 1024,
          _ => 120 * 1024,
        },
        mimeType: {'identityFront', 'identityBack', 'selfie'}.contains(slot.key)
            ? 'image/jpeg'
            : 'application/pdf',
      ),
    );
  }
  requireSuccess(
    repository.save((await current()).copyWith(currentStep: 'review')),
  );
}
