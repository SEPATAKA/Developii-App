import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

abstract final class KycDemoFixtures {
  static const naturalProofOfAccount = {
    'bank': 'United Bank of Africa',
    'accountName': 'Thomas Crown',
    'accountType': 'Current',
    'accountNumber': '1234567890',
    'branchCode': '112022',
  };

  static KycIdentitySummary sampleIdentity([AppUser? user]) =>
      KycIdentitySummary(
        name: user?.name ?? 'Babatunde Yusuf',
        birthDate: DateTime(1992, 6, 14),
        nationality: 'South African',
        residence: user?.address ?? 'Cape Town, South Africa',
      );

  static KycDraft verified(EntityType entity, DateTime now) {
    final steps = KycPlans.steps(entity);
    final values = <String, String>{};
    for (final step in steps) {
      for (final field in step.fields.where(
        (field) => field.visibleWhen == null,
      )) {
        values[field.key] =
            _values[field.key] ??
            switch (field.kind) {
              KycFieldKind.choice ||
              KycFieldKind.multipleChoice => field.options.first,
              KycFieldKind.toggle => field.required ? 'true' : 'false',
              KycFieldKind.date => '2026-05-04',
              KycFieldKind.amount => '100000',
              KycFieldKind.number => '22',
              KycFieldKind.email => 'bafreka@gmail.com',
              _ => 'Marula',
            };
      }
    }
    if (entity == EntityType.company) values['membersPresent'] = '1';
    for (final declaration in KycReviewPlan.declarations(entity)) {
      values[declaration.key] = 'true';
    }
    if (entity == EntityType.stokvel) {
      values['signatory'] = 'Chairperson + Treasurer';
    }
    return KycDraft(
      entity: entity,
      identitySummary: entity == EntityType.individual
          ? sampleIdentity()
          : null,
      status: VerificationStatus.verified,
      submissionId: 'demo-verification-${entity.name}',
      values: values,
      completedSteps: steps.map((step) => step.id).toSet(),
      verifiedSteps: steps.map((step) => step.id).toSet(),
      documents: {
        for (final document in steps.expand((step) => step.documents))
          document.key: KycDocument(
            id: 'demo-${document.key}',
            name:
                '${_documentNames[document.key] ?? document.title.replaceAll(' ', '_')}.pdf',
            bytes: 120 * 1024,
            mimeType: 'application/pdf',
            uploadedAt: now,
          ),
      },
      members: [
        for (final role in steps.expand((step) => step.memberRoles).toSet())
          KycMember(
            id: 'demo-${role.name}',
            firstName: 'Adaeze',
            lastName: 'Okoye',
            role: role,
            identityNumber: '920314',
            email: 'adaeze@example.test',
            shareBasisPoints:
                role == KycMemberRole.shareholder ||
                    role == KycMemberRole.beneficiary
                ? 10000
                : 0,
            identityVerified: true,
            addressVerified: true,
            resolutionSignature: KycResolutionSignature(
              status: KycSignatureStatus.signed,
              signedAt: now,
            ),
          ),
      ],
    );
  }

  static const _values = {
    'trustName': 'Okoye Family Trust',
    'trustRegistration': 'IT 4421/2019',
    'trustRegistered': '2019-07-14',
    'trusteeCount': '3',
    'signatory': 'Adaeze Okoye',
    'meetingLocation': 'Cape Town',
    'founderName': 'Adaeze Okoye',
    'founderIdentity': '920314',
    'companyName': 'Marula (Pty) Ltd',
    'companyRegistration': '2019/4421/07',
    'registeredAddress': '14 Protea Ave, Randburg',
    'industry': 'Property development',
    'auditor': 'Accounting officer',
    'stokvelName': 'Ubuntu Property Stokvel',
    'founded': '2018-02-01',
    'memberCount': '28',
    'nasasaId': 'NSA-44219',
    'accountName': 'Babatunde Yusuf',
    'accountNumber': '0000000119',
    'branchCode': '250655',
    'occupation': 'Employed',
    'employer': 'Marula',
    'tin': '9012048127',
  };
  static const _documentNames = {
    'cipc': 'CIPC_CoR14_3_Marula',
    'trustDeed': 'Trust_Deed',
    'trustResolution': 'Trustee_Resolution',
    'minutes': 'Minutes_for_investment',
  };
}
