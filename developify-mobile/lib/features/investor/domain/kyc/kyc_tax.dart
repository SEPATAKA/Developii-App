import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_options.dart';

enum KycTaxSection {
  residency,
  pep,
  wealth;

  static KycTaxSection? tryParse(String? value) {
    for (final section in values) {
      if (section.name == value) return section;
    }
    return null;
  }
}

abstract final class KycTaxPlan {
  static const pepYes = 'Yes, I am or related';
  static const pepNo = 'No I’m not a PEP';
  static const sanctions =
      'I can confirm that I am not on, and not associated with anyone on, the UN, EU, OFAC, or HM Treasury sanctions lists.';
  static const declaration =
      'All information I’ve provided is true and complete. I understand that false statements may result in account termination and reporting to authorities';
  static const certification =
      'I certify the information above is accurate. I’ll notify Developify within 30 days if my tax residency or TIN changes';
  static const wealthDocument = KycDocumentDefinition(
    'pepWealthProof',
    'Upload Supporting Documents (Recommended)',
    required: false,
  );

  static const fields = [
    KycFieldDefinition(
      'taxCountry',
      'Country of tax residency',
      hint: 'Select country',
      kind: KycFieldKind.choice,
      options: KycOptions.countries,
    ),
    KycFieldDefinition(
      'tin',
      'Tax Identification Number (TIN)',
      hint: 'Enter TIN',
    ),
    KycFieldDefinition(
      'secondaryTax',
      'I have a secondary tax residency',
      kind: KycFieldKind.toggle,
      required: false,
    ),
    KycFieldDefinition(
      'pep',
      'Politically Exposed Person',
      kind: KycFieldKind.choice,
      options: [pepNo, pepYes],
    ),
    ...pepFields,
    ...wealthFields,
    ...declarations,
  ];
  static const declarations = [
    KycFieldDefinition('sanctions', sanctions, kind: KycFieldKind.toggle),
    KycFieldDefinition('declaration', declaration, kind: KycFieldKind.toggle),
  ];
  static const residencyFields = [
    KycFieldDefinition(
      'secondaryTaxCountry',
      'Country of tax residency',
      hint: 'Select country',
      kind: KycFieldKind.choice,
      options: KycOptions.countries,
    ),
    KycFieldDefinition(
      'secondaryReason',
      'Reasons for tax residency',
      hint: 'Enter reason',
    ),
    KycFieldDefinition(
      'secondaryTinType',
      'TIN Type',
      hint: 'Select TIN type',
      kind: KycFieldKind.choice,
      options: [
        'Tax identification number',
        'Social security number',
        'Other tax identifier',
      ],
    ),
    KycFieldDefinition(
      'secondaryTinFormat',
      'TIN Format',
      hint: 'E.g. 5 digits',
    ),
    KycFieldDefinition(
      'secondaryTin',
      'Tax Identification Number',
      hint: 'E.g. ABCDEFGH271012',
    ),
    KycFieldDefinition(
      'secondaryResidentSince',
      'Became resident on',
      hint: 'Select date',
      kind: KycFieldKind.date,
    ),
    KycFieldDefinition(
      'secondaryStatus',
      'Status',
      hint: 'Select status',
      kind: KycFieldKind.choice,
      options: ['Current', 'Former'],
    ),
    KycFieldDefinition(
      'usPerson',
      'I am a US person for FATCA purposes',
      kind: KycFieldKind.toggle,
      required: false,
    ),
    KycFieldDefinition(
      'secondaryCertification',
      certification,
      kind: KycFieldKind.toggle,
    ),
  ];
  static const pepFields = [
    KycFieldDefinition(
      'pepRelationship',
      'Your relationship to the PEP',
      kind: KycFieldKind.choice,
      options: ['Self', 'Family member', 'Close associate'],
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepType',
      'Type of PEP',
      kind: KycFieldKind.choice,
      options: ['Domestic PEP', 'Foreign PEP', 'International organisation'],
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepCountry',
      'Country of Office',
      hint: 'Select country',
      kind: KycFieldKind.choice,
      options: KycOptions.countries,
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepPosition',
      'Position / Title',
      hint: 'Enter position',
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepOrganization',
      'Organisation / Department',
      hint: 'Enter organisation',
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepStart',
      'Start Date',
      hint: 'Select date',
      kind: KycFieldKind.date,
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepStatus',
      'Status',
      hint: 'Select status',
      kind: KycFieldKind.choice,
      options: ['Current', 'Former'],
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
  ];
  static const wealthFields = [
    KycFieldDefinition(
      'pepName',
      'Full Name of the PEP',
      hint: 'Enter name',
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepIdentityRelationship',
      'Relationship',
      hint: 'Select',
      kind: KycFieldKind.choice,
      options: [
        'Self',
        'Spouse',
        'Parent',
        'Child',
        'Sibling',
        'In-law',
        'Business partner',
        'Lawyer',
        'Advisor',
        'Agent',
        'Other',
      ],
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepIdentity',
      'PEP’s ID (Optional)',
      hint: 'Select',
      required: false,
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepWealth',
      'Briefly describe how you accumulated the wealth you are investing',
      hint: 'State reasons',
      kind: KycFieldKind.multiline,
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
    KycFieldDefinition(
      'pepNetWorth',
      'Estimated net worth (ZAR)',
      hint: 'Enter amount',
      kind: KycFieldKind.amount,
      visibleWhen: 'pep',
      visibleValue: pepYes,
    ),
  ];

  static List<KycFieldDefinition> sectionFields(KycTaxSection section) =>
      switch (section) {
        KycTaxSection.residency => residencyFields,
        KycTaxSection.pep => pepFields,
        KycTaxSection.wealth => [...wealthFields, ...declarations],
      };
}
