import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_repository.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';
import 'investor_member_fixtures.dart';

const investorEntityDocumentFrames =
    <String, (EntityType, String, double, String?)>{
      '55856': (EntityType.trust, 'authority', 1053, null),
      '55923': (EntityType.trust, 'authority', 1053, 'lettersAuthority'),
      '56425': (EntityType.trust, 'deed', 948, null),
      '56516': (EntityType.trust, 'deed', 1104, 'trustDeed'),
      '80184': (EntityType.company, 'registration', 1171, null),
      '80825': (EntityType.company, 'registration', 1171, 'cipc'),
      '80663': (EntityType.company, 'moi', 972, null),
      '80738': (EntityType.company, 'moi', 972, 'moi'),
      '80502': (EntityType.company, 'shareholders', 1118, 'shareRegister'),
      '83814': (EntityType.stokvel, 'constitution', 1118, 'constitution'),
      '84418': (EntityType.stokvel, 'bank', 852, null),
      '84500': (EntityType.stokvel, 'bank', 977, 'bankProof'),
      '58787': (EntityType.trust, 'funds', 1294, 'fundsEvidence'),
      '58898': (EntityType.trust, 'funds', 852, 'fundsEvidence'),
      '82119': (EntityType.company, 'funds', 1454, 'fundsEvidence'),
      '82231': (EntityType.company, 'funds', 852, 'fundsEvidence'),
      '84174': (EntityType.stokvel, 'funds', 1152, 'statements'),
    };

Future<void> seedInvestorEntityDocumentFrame(
  KycRepository repository,
  String node,
) async {
  final definition = investorEntityDocumentFrames[node];
  if (definition == null) return;
  final (entity, step, _, document) = definition;
  if (node == '80502') await seedInvestorMemberFrame(repository, '80353');
  final current = (await repository.load(entity) as Success<KycDraft>).value;
  final values = <String, String>{
    ...current.values,
    if (step == 'authority') ...{
      'authorityIssued': '2026-07-18',
      'issuingOffice': 'Master of the High Court - Cape Town',
      'trusteeCount': '3',
      'reissued': 'true',
    },
    if (step == 'deed') ...{
      'trustName': 'Okoye Family Trust',
      'trustRegistration': 'IT 4421/2019',
      'trustRegistered': '2019-07-14',
      'masterOffice': 'Cape Town (WC)',
      'trustType': 'Inter vivos - Family / Discretionary',
    },
    if (step == 'moi') ...{
      'preemptiveRights': 'true',
      'transferRestrictions': 'true',
      'externalDirectors': 'true',
    },
    if (step == 'constitution') ...{
      'stokvelName': 'Ubuntu Property Stokvel',
      'founded': '2018-02-01',
      'memberCount': '28',
      'stokvelType': 'Investment',
      'nasasa': 'Yes',
      'nasasaId': 'NSA-44219',
    },
    if (step == 'bank') ...{
      'bank': 'Standard Bank',
      'accountNumber': '041882109',
      'branchCode': '051001',
      'accountName': 'Ubuntu Property Stokvel',
      'useForWithdrawals': 'true',
    },
    if (step == 'funds' && entity == EntityType.trust) ...{
      'fundSources': 'Property sale proceeds|Investment portfolio rollover',
      'trustCapital': '12500000',
      'annualInvestment': '1000000',
    },
    if (step == 'funds' && entity == EntityType.company) ...{
      'fundSources': 'Retained earnings|Capital raise / equity injection',
      'annualTurnover': '38400000',
      'auditor': 'BDO South Africa',
      'annualInvestment': '6000000',
    },
  };
  if (repository.save(current.copyWith(values: values, currentStep: step))
      is! Success<KycDraft>) {
    throw StateError('Unable to seed entity document fields.');
  }
  if (document == null) return;
  final result = await repository.upload(
    entity,
    document,
    name: switch (document) {
      'lettersAuthority' => 'Letters_of_Authority.pdf',
      'trustDeed' => 'SARS assets declarations.pdf',
      'cipc' => 'CIPC_CoR14_3_Marula.pdf',
      'moi' => 'Marula_MOI_v3.pdf',
      'shareRegister' => 'Share_register_documents.pdf',
      'constitution' => 'CIPC_CoR14_3_Marula.pdf',
      'bankProof' => 'Minutes for investment.pdf',
      'fundsEvidence' => 'SARS assets declarations.pdf',
      'statements' => 'Minutes for investment.pdf',
      _ => '$document.pdf',
    },
    bytes: 120 * 1024,
    mimeType: 'application/pdf',
  );
  if (result is! Success<KycDraft>) {
    throw StateError('Unable to seed entity document $document.');
  }
}
