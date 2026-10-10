import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

abstract final class KycReviewPlan {
  static List<KycFieldDefinition> declarations(EntityType entity) =>
      switch (entity) {
        EntityType.individual => naturalDeclarations,
        EntityType.trust => trustDeclarations,
        _ => const [],
      };

  static const naturalDeclarations = [
    KycFieldDefinition(
      'reviewWealth',
      'Assets lawfully acquired, unconnected to bribery or misuse of public funds',
      kind: KycFieldKind.toggle,
      visibleWhen: 'pep',
      visibleValue: KycTaxPlan.pepYes,
    ),
    KycFieldDefinition(
      'reviewMonitoring',
      'Consent to enhanced ongoing monitoring under FICA s.26B',
      kind: KycFieldKind.toggle,
      visibleWhen: 'pep',
      visibleValue: KycTaxPlan.pepYes,
    ),
    KycFieldDefinition(
      'reviewPepChanges',
      '30-day notification if PEP status or position changes',
      kind: KycFieldKind.toggle,
      visibleWhen: 'pep',
      visibleValue: KycTaxPlan.pepYes,
    ),
    KycFieldDefinition(
      'reviewConsent',
      'I consent to Developify processing my personal\ndata for KYC and AML compliance, including sharing with regulators where legally required',
      kind: KycFieldKind.toggle,
    ),
  ];

  static const trustDeclarations = [
    KycFieldDefinition(
      'reviewAccuracy',
      'All information provided is true and complete. False statements may result in account termination and reporting to the FIC.',
      kind: KycFieldKind.toggle,
    ),
    KycFieldDefinition(
      'reviewSanctions',
      'I confirm no trustee, founder, or beneficiary is on the UN, EU, OFAC or HM Treasury sanctions lists.',
      kind: KycFieldKind.toggle,
    ),
    KycFieldDefinition(
      'reviewConsent',
      'I consent to Developify processing the trust’s personal data for KYC / AML compliance, including sharing with SARS, FIC, and the Master of the High Court where legally required.',
      kind: KycFieldKind.toggle,
    ),
    KycFieldDefinition(
      'reviewChanges',
      'I will notify Developify within 30 days of any change in trustees, trust deed, or banking details.',
      kind: KycFieldKind.toggle,
    ),
  ];
}
