import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/investor/data/kyc_demo_fixtures.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

Future<void> seedInvestorMemberFrame(
  KycRepository repository,
  String node,
) async {
  KycDocument document(String name) => KycDocument(
    id: name,
    name: name,
    bytes: 120 * 1024,
    mimeType: 'application/pdf',
    uploadedAt: DateTime(2026, 7, 14),
  );
  if (['59009', '59280', '59559'].contains(node)) {
    const entity = EntityType.trust;
    final current = (await repository.load(entity) as Success<KycDraft>).value;
    final values = {
      ...KycDemoFixtures.verified(entity, DateTime(2026, 7, 22)).values,
      'trustName': 'Okoye Family Trust',
      'trustRegistered': '2026-07-14',
      'masterOffice': 'Cape Town (WC)',
      'authorityIssued': '2026-07-22',
      'trusteeCount': '3',
      'resolutionDate': '2026-07-18',
      'investmentCap': '5000000',
      'signatory': 'Adaeze Okoye',
      'founderName': 'Chidi Okoye',
      'founderIdentity': '362729817632629',
      'founderCountry': 'South Africa',
      'trustCapital': '12500000',
      'annualInvestment': '1000000',
      'fundSources': 'Property sale proceeds|Investment portfolio rollover',
      for (final field in KycReviewPlan.trustDeclarations)
        field.key: node == '59009' ? 'false' : 'true',
    };
    repository.save(current.copyWith(values: values));
    for (final slot in KycPlans.steps(
      entity,
    ).expand((step) => step.documents)) {
      final result = await repository.upload(
        entity,
        slot.key,
        name: switch (slot.key) {
          'trustDeed' => 'Okoye_Family_Trust_Deed.pdf',
          'lettersAuthority' => 'Letter_of_Authority_2026.pdf',
          'trustResolution' => 'Signed_resolution.pdf',
          'fundsEvidence' => 'Sasfin_TrustPortfolio_Apr2026.pdf',
          _ => '${slot.key}.pdf',
        },
        bytes: slot.key == 'trustDeed' ? 2202009 : 120 * 1024,
        mimeType: 'application/pdf',
      );
      if (result is! Success<KycDraft>) {
        throw StateError('Unable to seed trust review documents.');
      }
    }
    for (final (index, name) in ['Adaeze', 'Dennis', 'Lerato'].indexed) {
      for (final role in [KycMemberRole.trustee, KycMemberRole.beneficiary]) {
        repository.saveMember(
          entity,
          KycMember(
            id: 'review-${role.name}-$index',
            firstName: name,
            lastName: 'Okoye',
            role: role,
            identityNumber: 'mock-review-$index',
            email: '${name.toLowerCase()}@example.test',
            birthDate: '2000-02-02',
            relationship: index == 0 ? 'Daughter' : 'Son',
            shareBasisPoints: role == KycMemberRole.beneficiary
                ? [4500, 3500, 2000][index]
                : 0,
            identityVerified: index < 2,
            addressVerified: index == 0,
            inviteSent: index == 2,
            details: KycMemberDetails(
              position: index == 0 ? 'Chair' : 'Trustee',
            ),
          ),
        );
      }
    }
    final request = await repository.requestResolutionSignatures(entity);
    if (request is! Success<KycDraft>) {
      throw StateError('Unable to seed trust review signatures.');
    }
    for (final id in ['review-trustee-0', 'review-trustee-1']) {
      final result = await repository.simulateResolutionSignature(entity, id);
      if (result is! Success<KycDraft>) {
        throw StateError('Unable to seed trust review signatures.');
      }
    }
    final ready = (await repository.load(entity) as Success<KycDraft>).value;
    final errors = KycValidation.submission(ready)
      ..removeWhere(
        (key, value) =>
            node == '59009' &&
            KycReviewPlan.trustDeclarations.any((field) => field.key == key),
      );
    if (errors.isNotEmpty) {
      throw StateError('Incomplete trust review fixture: $errors');
    }
    repository.save(ready.copyWith(currentStep: 'review'));
    return;
  }
  if (node == '83906') {
    final current =
        (await repository.load(EntityType.stokvel) as Success<KycDraft>).value;
    repository.save(
      current.copyWith(
        values: {
          ...current.values,
          'meetingDate': '2026-05-04',
          'memberCount': '22',
          'membersPresent': '22',
          'authorisedAmount': '100000',
          'signatory': 'Chairperson + Treasurer',
        },
      ),
    );
    final upload = await repository.upload(
      EntityType.stokvel,
      'minutes',
      name: 'Minutes for investment.pdf',
      bytes: 120 * 1024,
      mimeType: 'application/pdf',
    );
    if (upload is! Success<KycDraft>) {
      throw StateError('The completed Stokvel resolution fixture failed.');
    }
  }
  KycMember member(
    String id,
    String name,
    KycMemberRole role, {
    int share = 0,
    bool identity = false,
    bool address = false,
    bool invited = false,
    bool director = false,
    String position = '',
  }) {
    final names = name.split(' ');
    return KycMember(
      id: id,
      firstName: names.first,
      lastName: names.skip(1).join(' '),
      role: role,
      identityNumber: 'mock-$id',
      email: '$id@example.test',
      shareBasisPoints: share,
      birthDate: '2000-02-02',
      relationship: role == KycMemberRole.beneficiary ? 'Daughter' : '',
      identityVerified: identity,
      addressVerified: address,
      inviteSent: invited,
      details: KycMemberDetails(
        isDirector: director,
        position: position,
        shareClass: 'Ordinary',
        numberOfShares: share ~/ 10,
        issuedShares: 1000,
        documents: {
          if (identity) 'identity': document('Passport.pdf'),
          if (address) 'address': document('Proof_of_address.pdf'),
        },
      ),
    );
  }

  if ([
    '54144',
    '54254',
    '54364',
    '56619',
    '56805',
    '56991',
    '80931',
    '81662',
    '81740',
    '81875',
  ].contains(node)) {
    final trust = [
      '54144',
      '54254',
      '54364',
      '56619',
      '56805',
      '56991',
    ].contains(node);
    final entity = trust ? EntityType.trust : EntityType.company;
    final role = trust ? KycMemberRole.trustee : KycMemberRole.director;
    for (final (index, name) in [
      'Adaeze Okoye',
      'Sipho Khumalo',
      if (trust) 'Thandi Ndlovu',
    ].indexed) {
      repository.saveMember(
        entity,
        member(
          'resolution-$index',
          name,
          role,
          position: index == 0
              ? trust
                    ? 'Chair trustee'
                    : 'CEO'
              : role == KycMemberRole.trustee
              ? 'Trustee'
              : 'Director',
        ),
      );
    }
    if (!['54144', '54254', '54364', '56619', '80931'].contains(node)) {
      final current =
          (await repository.load(entity) as Success<KycDraft>).value;
      repository.save(
        current.copyWith(
          values: {
            ...current.values,
            if (trust) ...{
              'resolutionDate': '2026-05-03',
              'meetingLocation': 'Sea Point, Cape Town',
              'investmentCap': '5000000',
              'signatory': 'Adaeze Okoye (Chair Trustee)',
            } else ...{
              'meetingDate': '2026-07-11',
              'membersPresent': '2',
              'signatory': 'Adaeze Okoye (CEO)',
              'investmentCap': '10000000',
              'resolutionNotes':
                  'Approves opening of investment account with Developify (Pty) Ltd and authorises CEO to sign all related documents.',
            },
          },
        ),
      );
      if (node != '81662') {
        final request = await repository.requestResolutionSignatures(entity);
        if (request is! Success<KycDraft>) {
          throw StateError('Unable to seed the signature request.');
        }
        for (final signer in request.value.members.take(2)) {
          final result = await repository.simulateResolutionSignature(
            entity,
            signer.id,
          );
          if (result is! Success<KycDraft>) {
            throw StateError('Unable to seed the simulated signature.');
          }
          repository.saveMember(
            entity,
            result.value.members
                .firstWhere((member) => member.id == signer.id)
                .copyWith(
                  resolutionSignature: KycResolutionSignature(
                    status: KycSignatureStatus.signed,
                    requestedAt: DateTime(2026, 5, 3),
                    signedAt: DateTime(2026, 5, 3),
                  ),
                ),
          );
        }
      }
      if (node == '56991' || node == '81875') {
        final result = await repository.upload(
          entity,
          trust ? 'trustResolution' : 'boardResolution',
          name: trust ? 'Signed_resolution.pdf' : 'Board_resolution_signed.pdf',
          bytes: 120 * 1024,
          mimeType: 'application/pdf',
        );
        if (result is! Success<KycDraft>) {
          throw StateError('Unable to seed the resolution document.');
        }
      }
    }
    return;
  }

  if ([
    '57190',
    '58158',
    '58607',
    '81009',
    '80353',
    '81480',
    '83727',
  ].contains(node)) {
    final entity = ['81009', '80353', '81480'].contains(node)
        ? EntityType.company
        : node == '83727'
        ? EntityType.stokvel
        : EntityType.trust;
    await repository.load(entity);
    final members = switch (node) {
      '57190' => [
        member(
          'reference-a',
          'Adaeze Okoye',
          KycMemberRole.trustee,
          identity: true,
          address: true,
        ),
        member(
          'reference-b',
          'Sipho Kumalo',
          KycMemberRole.trustee,
          invited: true,
        ),
        member(
          'reference-c',
          'Adaeze Okoye',
          KycMemberRole.trustee,
          identity: true,
        ),
      ],
      '58158' || '58607' => [
        member(
          'reference-a',
          'Adaeze Okoye',
          KycMemberRole.beneficiary,
          share: 4500,
        ),
        member(
          'reference-b',
          'Adaeze Okoye',
          KycMemberRole.beneficiary,
          share: 3500,
        ),
        member(
          'reference-c',
          'Adaeze Okoye',
          KycMemberRole.beneficiary,
          share: 2000,
        ),
      ],
      '83727' => [
        member(
          'reference-a',
          'Nomthandazo Hadebe',
          KycMemberRole.chairperson,
          identity: true,
          address: true,
        ),
        member(
          'reference-b',
          'Bongani Mthembu',
          KycMemberRole.treasurer,
          identity: true,
        ),
      ],
      '81480' => [
        member(
          'reference-a',
          'Adaeze Okoye',
          KycMemberRole.shareholder,
          share: 5700,
          director: true,
        ),
        member(
          'reference-b',
          'Sipho Khumalo',
          KycMemberRole.shareholder,
          share: 2210,
          director: true,
        ),
        member(
          'reference-c',
          'Crescent Holdings',
          KycMemberRole.shareholder,
          share: 830,
        ),
        member(
          'reference-d',
          'Lerato Dlamini',
          KycMemberRole.shareholder,
          share: 460,
        ),
        member(
          'reference-e',
          'Nomvula Malangu',
          KycMemberRole.shareholder,
          share: 800,
        ),
      ],
      _ => [
        member(
          'reference-a',
          'Adaeze Okoye',
          KycMemberRole.shareholder,
          share: 6200,
          director: true,
          position: 'CEO',
          identity: true,
          address: true,
        ),
        member(
          'reference-b',
          'Sipho Khumalo',
          KycMemberRole.shareholder,
          share: 2400,
          director: true,
          position: 'Chairperson',
          identity: true,
        ),
        member(
          'reference-c',
          'Crescent Holdings (pty) Ltd',
          KycMemberRole.shareholder,
          share: 900,
        ),
        member(
          'reference-d',
          'Lerato Dlamini',
          KycMemberRole.shareholder,
          share: 500,
          invited: true,
        ),
      ],
    };
    for (final item in members) {
      repository.saveMember(entity, item);
    }
  }
  if (['58358', '58473', '81364', '57456', '57633'].contains(node)) {
    final shareholder = node == '81364';
    final invitation = node == '57456' || node == '57633';
    final role = shareholder
        ? KycMemberRole.shareholder
        : invitation
        ? KycMemberRole.trustee
        : KycMemberRole.beneficiary;
    final entity = shareholder ? EntityType.company : EntityType.trust;
    if (invitation) {
      final current =
          (await repository.load(entity) as Success<KycDraft>).value;
      repository.save(
        current.copyWith(
          values: {
            ...current.values,
            'trustName': 'Okoye Family Trust',
            'founderName': 'Adaeze',
          },
        ),
      );
    }
    final now = DateTime.now();
    repository.saveMemberDraft(
      entity,
      'new-${role.name}',
      KycMemberDraft(
        id: 'reference-new',
        role: role,
        values: {
          'country': 'South Africa',
          if (!shareholder && !invitation)
            'birthDate': '${now.year - 13}-02-02',
          if (invitation) ...{
            'email': node == '57456'
                ? 'thandi.kampala@example.co.za'
                : 'thandi.ndlovu@example.co.za',
            'phone': '+27 82 411 7822',
            'firstName': 'Thandi',
            'lastName': 'Ndlovu',
            'message': node == '57633'
                ? 'Hi Thandi — welcome to the trust. Please sign when you get a moment. — Adaeze'
                : '',
            'attach-appointment': 'true',
            'attach-resolution': 'true',
            'attach-trustDeed': 'true',
            if (node == '57456') ...{
              'sms': 'true',
              'reminders': 'true',
              'opened': 'true',
              'attach-amendment': 'true',
            },
          },
        },
        documents: {
          if (node == '58473')
            for (final key in ['identity', 'guardian', 'relationship'])
              key: document('SARS assets declarations.pdf'),
          if (shareholder) ...{
            'identity': document('Passport.pdf'),
            'address': document('Proof_of_address.pdf'),
            'shareCertificate': document('Certificate.pdf'),
          },
        },
      ),
    );
  }
}
