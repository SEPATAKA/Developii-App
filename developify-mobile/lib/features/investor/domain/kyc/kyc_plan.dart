import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_options.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

enum NaturalPersonKycStep {
  overview,
  identity,
  selfie,
  address,
  bank,
  funds,
  tax,
  review,
}

enum TrustKycStep {
  overview,
  deed,
  authority,
  resolution,
  trustees,
  beneficiaries,
  funds,
  review,
}

enum CompanyKycStep {
  overview,
  registration,
  moi,
  shareholders,
  resolution,
  directors,
  funds,
  review,
}

enum StokvelKycStep {
  overview,
  constitution,
  resolution,
  officers,
  register,
  bank,
  funds,
  review,
}

abstract final class KycPlans {
  static const countries = KycOptions.countries;
  static const banks = [
    'Standard Bank',
    'ABSA',
    'FNB',
    'Nedbank',
    'Capitec',
    'Access Bank',
    'United Bank of Africa',
  ];
  static String entityName(EntityType entity) => switch (entity) {
    EntityType.individual => 'Natural Person',
    EntityType.trust => 'Trust',
    EntityType.company => 'Company / SPV',
    EntityType.stokvel => 'Stokvel / Investment group',
  };
  static List<KycStepDefinition> steps(EntityType entity) => switch (entity) {
    EntityType.individual => naturalPerson,
    EntityType.trust => trust,
    EntityType.company => company,
    EntityType.stokvel => stokvel,
  };
  static List<String> states(EntityType entity) => switch (entity) {
    EntityType.individual =>
      NaturalPersonKycStep.values.map((value) => value.name).toList(),
    EntityType.trust => TrustKycStep.values.map((value) => value.name).toList(),
    EntityType.company =>
      CompanyKycStep.values.map((value) => value.name).toList(),
    EntityType.stokvel =>
      StokvelKycStep.values.map((value) => value.name).toList(),
  };
  static bool validState(EntityType entity, String state) =>
      states(entity).contains(state);

  static const naturalPerson = [
    KycStepDefinition(
      id: 'identity',
      title: 'Government ID',
      description:
          'Please provide the following documents. Ensure they are all valid and unaltered.',
      section: 'Which ID will you use?',
      fields: [
        KycFieldDefinition(
          'idType',
          'ID Type',
          hint: 'Select ID',
          kind: KycFieldKind.choice,
          options: ['International passport'],
        ),
      ],
      documents: [
        KycDocumentDefinition('identityFront', 'Photo ID Card (Front)'),
        KycDocumentDefinition('identityBack', 'Photo ID Card (Back)'),
      ],
    ),
    KycStepDefinition(
      id: 'selfie',
      title: 'Live Selfie / Biometrics',
      description: 'Complete a live selfie to confirm your identity.',
      section: 'Live Selfie',
      documents: [KycDocumentDefinition('selfie', 'Live selfie')],
    ),
    KycStepDefinition(
      id: 'address',
      title: 'Proof of address',
      description:
          'Upload a document showing your name and home address, issued in the last 3 months',
      section: 'Address Verification',
      acceptedDocuments: [
        'Utility bill (Electric, water, Internet)',
        'Bank or credit card statement',
        'Tenancy agreement (registered)',
      ],
      documents: [KycDocumentDefinition('addressProof', 'Upload')],
    ),
    KycStepDefinition(
      id: 'bank',
      title: 'Proof of account',
      description:
          'A document confirming the bank account that’s in your name. We use this to pay out distributions and withdrawals.',
      section: 'Enter Details',
      fields: [
        KycFieldDefinition(
          'bank',
          'Bank',
          kind: KycFieldKind.choice,
          options: banks,
        ),
        KycFieldDefinition(
          'accountName',
          'Account Name',
          hint: 'Enter Full Name',
        ),
        KycFieldDefinition(
          'accountType',
          'Account Type',
          kind: KycFieldKind.choice,
          options: ['Savings', 'Current', 'Cheque'],
        ),
        KycFieldDefinition(
          'accountNumber',
          'Acc Number',
          hint: 'Enter Details',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'branchCode',
          'Branch Code',
          hint: 'Enter Code',
          kind: KycFieldKind.number,
        ),
      ],
      acceptedDocuments: [
        'Bank confirmation letter (Signed & stamped)',
        'Bank-stamped account statement (< 3 months)',
        'Letter from your bank manager on letterhead',
        'Screenshot from your banking app showing name, account number & branch',
      ],
      documents: [KycDocumentDefinition('bankProof', 'Upload')],
    ),
    KycStepDefinition(
      id: 'funds',
      title: 'Source of funds',
      description:
          'Required by FICA, help us understand how you earn or hold the money you’re investing.',
      section: 'Primary Source (Select all that apply)',
      fields: [
        KycFieldDefinition(
          'fundSources',
          '',
          kind: KycFieldKind.multipleChoice,
          options: [
            'Salary / Employment Income',
            'Investment returns',
            'Inheritance returns',
            'Sale of property',
            'Savings',
          ],
        ),
        KycFieldDefinition(
          'occupation',
          'Occupation',
          hint: 'Select Occupation',
          kind: KycFieldKind.choice,
          options: ['Employed', 'Self-employed', 'Retired', 'Student', 'Other'],
        ),
        KycFieldDefinition('employer', 'Employer', hint: 'Enter employer'),
        KycFieldDefinition(
          'annualIncome',
          'Annual Income (Rands)',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'expectedActivity',
          'Expected Activity (Rands)',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
      ],
    ),
    KycStepDefinition(
      id: 'tax',
      title: 'Tax & PEP Declaration',
      description: '',
      section: 'TAX RESIDENCY',
      fields: KycTaxPlan.fields,
      documents: [KycTaxPlan.wealthDocument],
    ),
  ];
  static const trust = [
    KycStepDefinition(
      id: 'deed',
      title: 'Trust Deed',
      description:
          'Upload the stamped, signed Trust Deed exactly as registered with the Master of the High Court',
      section: 'Trust Details',
      fields: [
        KycFieldDefinition(
          'trustName',
          'Registered name of Trust',
          hint: 'Enter registered name',
        ),
        KycFieldDefinition(
          'masterOffice',
          'Master of the High Court Office',
          hint: 'Select location',
          kind: KycFieldKind.choice,
          options: [
            'Cape Town (WC)',
            'Pretoria (GP)',
            'Johannesburg (GP)',
            'Durban (KZN)',
            'Pietermaritzburg (KZN)',
            'Bloemfontein (FS)',
            'Makhanda / Grahamstown',
            'Mbombela / Nelspruit (MP)',
          ],
        ),
        KycFieldDefinition(
          'trustType',
          'Trust Type',
          hint: 'Select trust type',
          kind: KycFieldKind.choice,
          options: [
            'Inter vivos - Family / Discretionary',
            'Inter vivos - Vested (fixed %)',
            'Inter vivos - Bewind trust',
            'Testamentary',
            'Special Trust Type A (person with disability)',
            'Special Trust Type B (minor relatives)',
            'Charity',
          ],
        ),
        KycFieldDefinition(
          'trustRegistration',
          'Registration No',
          hint: 'Enter Reg No',
        ),
        KycFieldDefinition(
          'trustRegistered',
          'Date Registered',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
      ],
      documents: [KycDocumentDefinition('trustDeed', 'Trust Deed')],
    ),
    KycStepDefinition(
      id: 'authority',
      title: 'Letters of Authority',
      description:
          'Current Letters of Authority issued by the Master of the High Court listing all serving trustees',
      section: 'Document Details',
      fields: [
        KycFieldDefinition(
          'authorityIssued',
          'Date Issued',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'trusteeCount',
          'Number of trustees named',
          hint: 'Enter Number',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'issuingOffice',
          'Issuing Office',
          hint: 'Enter Office',
        ),
        KycFieldDefinition(
          'reissued',
          'Letters re-issued in the last 12 months',
          kind: KycFieldKind.toggle,
          required: false,
        ),
      ],
      documents: [
        KycDocumentDefinition('lettersAuthority', 'Letters of Authority'),
      ],
    ),
    KycStepDefinition(
      id: 'resolution',
      title: 'Trustee Resolution',
      description:
          'A signed resolution authorising the trust to invest via Developify',
      section: 'Resolution Details',
      fields: [
        KycFieldDefinition(
          'resolutionDate',
          'Date of Resolution',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'meetingLocation',
          'Meeting location',
          hint: 'Enter Location',
        ),
        KycFieldDefinition(
          'investmentCap',
          'Authorised Investment Cap (ZAR)',
          hint: 'R - Enter Amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'signatory',
          'Authorised Signatory',
          hint: 'Enter Name of Signatory',
        ),
      ],
      documents: [
        KycDocumentDefinition('trustResolution', 'Upload Signed Resolution'),
      ],
      memberRoles: [KycMemberRole.trustee],
    ),
    KycStepDefinition(
      id: 'trustees',
      title: 'Trustee KYC',
      description:
          'Every serving trustee needs to submit ID and a proof of address (< 3 months). Tap a trustee to complete their registration.',
      section: 'All Serving Trustees',
      memberRoles: [KycMemberRole.trustee],
    ),
    KycStepDefinition(
      id: 'beneficiaries',
      title: 'Founder & Beneficiaries',
      description:
          'Identify the founder and every beneficiary with their share of beneficial interest.',
      section: 'Founder',
      fields: [
        KycFieldDefinition(
          'founderName',
          'Founder full name',
          hint: 'Enter full name',
        ),
        KycFieldDefinition(
          'founderIdentity',
          'ID / Passport No',
          hint: 'Enter ID number',
        ),
        KycFieldDefinition(
          'founderCountry',
          'Country',
          kind: KycFieldKind.choice,
          options: countries,
        ),
      ],
      memberRoles: [KycMemberRole.beneficiary],
      requiresAllocation: true,
    ),
    KycStepDefinition(
      id: 'funds',
      title: 'Source of funds',
      description:
          'Explain the origin of the trust’s capital. We may ask for supporting documents.',
      section: 'Primary Source (Select all that apply)',
      fields: [
        KycFieldDefinition(
          'fundSources',
          '',
          kind: KycFieldKind.multipleChoice,
          options: [
            'Property sale proceeds',
            'Investment portfolio rollover',
            'Settlor Contributions',
            'Inheritance',
            'Business sale proceeds',
          ],
        ),
        KycFieldDefinition(
          'trustCapital',
          'Approximate trust capital (ZAR)',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'annualInvestment',
          'Planned annual investment',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
      ],
      documents: [
        KycDocumentDefinition(
          'fundsEvidence',
          'Supporting Evidence',
          multiple: true,
        ),
      ],
    ),
  ];
  static const company = [
    KycStepDefinition(
      id: 'registration',
      title: 'CIPC Registration',
      description:
          'Provide your CIPC disclosure certificate (CoR 14.3) or equivalent registration documents.',
      section: 'Company Identity',
      fields: [
        KycFieldDefinition(
          'companyName',
          'Registered name',
          hint: 'Enter registered name',
        ),
        KycFieldDefinition(
          'tradingName',
          'Trading name (if Different)',
          hint: 'Enter Trading name',
          required: false,
        ),
        KycFieldDefinition(
          'companyRegistration',
          'Registration No',
          hint: 'Enter Reg No',
        ),
        KycFieldDefinition(
          'incorporated',
          'Date Incorporated',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'companyType',
          'Company type',
          hint: 'Select type',
          kind: KycFieldKind.choice,
          options: [
            'Private company',
            'Public company',
            'SPV',
            'Holding company',
          ],
        ),
        KycFieldDefinition(
          'vat',
          'VAT no (Optional)',
          hint: 'Enter VAT no',
          required: false,
        ),
        KycFieldDefinition(
          'registeredAddress',
          'Registered address',
          hint: 'Enter Address',
        ),
        KycFieldDefinition(
          'industry',
          'Industry / SIC code',
          hint: 'Enter Industry',
        ),
      ],
      documents: [KycDocumentDefinition('cipc', 'CIPC Registration')],
    ),
    KycStepDefinition(
      id: 'moi',
      title: 'Memorandum of Incorporation',
      description:
          'Upload the most recently adopted MOI for the company. We’ll flag any restrictive clauses.',
      section: 'MOI DETAILS',
      fields: [
        KycFieldDefinition(
          'moiDate',
          'MOI version / adoption date',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'shareCapital',
          'Authorised share capital',
          hint: 'Enter share capital',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'preemptiveRights',
          'Pre-emptive rights enabled',
          kind: KycFieldKind.toggle,
          required: false,
        ),
        KycFieldDefinition(
          'transferRestrictions',
          'Restrictions on transfer of shares',
          kind: KycFieldKind.toggle,
          required: false,
        ),
        KycFieldDefinition(
          'externalDirectors',
          'External directors permitted',
          kind: KycFieldKind.toggle,
          required: false,
        ),
      ],
      documents: [KycDocumentDefinition('moi', 'Memorandum of Incorporation')],
    ),
    KycStepDefinition(
      id: 'shareholders',
      title: 'Share Register',
      description:
          'List every shareholder. Any holding >5% will also need individual KYC.',
      section: 'Shareholders',
      memberRoles: [KycMemberRole.shareholder],
      requiresAllocation: true,
      documents: [KycDocumentDefinition('shareRegister', 'Share Register')],
    ),
    KycStepDefinition(
      id: 'resolution',
      title: 'Board Resolution',
      description:
          'A board resolution authorising the company to open an account and invest via Developify.',
      section: 'Resolution Details',
      fields: [
        KycFieldDefinition(
          'meetingDate',
          'Meeting Date',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'membersPresent',
          'Members Present',
          hint: 'No of directors present',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'signatory',
          'Authorized Signatory',
          hint: 'Enter signatory',
        ),
        KycFieldDefinition(
          'investmentCap',
          'Investment Cap',
          hint: 'R 0 / Year',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'resolutionNotes',
          'Notes',
          hint: 'Enter notes',
          required: false,
          kind: KycFieldKind.multiline,
        ),
      ],
      documents: [KycDocumentDefinition('boardResolution', 'Board Resolution')],
      memberRoles: [KycMemberRole.director],
    ),
    KycStepDefinition(
      id: 'directors',
      title: 'Directors & UBO',
      description:
          'Every director and every ultimate beneficial owner >5% needs an ID and proof of address.',
      section: 'Directors & Ultimate Beneficial Owners',
      memberRoles: [KycMemberRole.director, KycMemberRole.shareholder],
    ),
    KycStepDefinition(
      id: 'funds',
      title: 'Source of funds',
      description:
          'Explain the origin of the company’s capital. We may ask for supporting documents.',
      section: 'Primary Source (Select all that apply)',
      fields: [
        KycFieldDefinition(
          'fundSources',
          '',
          kind: KycFieldKind.multipleChoice,
          options: [
            'Retained earnings',
            'Capital raise / equity injection',
            'Bank loan',
            'Assets sale proceeds',
            'Inter-company loan',
          ],
        ),
        KycFieldDefinition(
          'annualTurnover',
          'Last filed annual turnover (ZAR)',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'auditor',
          'Auditor / accounting officer',
          hint: 'Enter Auditor',
        ),
        KycFieldDefinition(
          'annualInvestment',
          'Planned annual investment',
          hint: 'Enter Amount',
          kind: KycFieldKind.amount,
        ),
      ],
      documents: [
        KycDocumentDefinition(
          'fundsEvidence',
          'Supporting Evidence',
          multiple: true,
        ),
      ],
    ),
  ];
  static const stokvel = [
    KycStepDefinition(
      id: 'constitution',
      title: 'Stokvel constitution',
      description:
          'Upload the constitution or founding documents signed by your founding members.',
      section: 'Stokvel Basics',
      fields: [
        KycFieldDefinition('stokvelName', 'Stokvel name', hint: 'Enter name'),
        KycFieldDefinition(
          'founded',
          'Founded',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'memberCount',
          'Members',
          hint: 'No of Members',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'stokvelType',
          'Stokvel type',
          hint: 'Select type',
          kind: KycFieldKind.choice,
          options: ['Savings', 'Investment', 'Property', 'Burial society'],
        ),
        KycFieldDefinition(
          'nasasa',
          'Affiliated to NASASA?',
          hint: 'Yes / No',
          kind: KycFieldKind.choice,
          options: ['Yes', 'No'],
          required: false,
        ),
        KycFieldDefinition(
          'nasasaId',
          'If yes',
          hint: 'Enter member ID',
          required: false,
        ),
      ],
      documents: [
        KycDocumentDefinition('constitution', 'Stokvel constitution'),
      ],
    ),
    KycStepDefinition(
      id: 'resolution',
      title: 'Resolution to Invest',
      description:
          'Signed minutes / resolution showing members agreed to invest via Developify',
      section: 'Resolution Details',
      fields: [
        KycFieldDefinition(
          'meetingDate',
          'Meeting Date',
          hint: 'YYYY-MM-DD',
          kind: KycFieldKind.date,
        ),
        KycFieldDefinition(
          'membersPresent',
          'Members',
          hint: 'No of Members',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'authorisedAmount',
          'Authorised amount',
          hint: 'Enter amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'signatory',
          'Authorised signatories',
          hint: 'Select type',
          kind: KycFieldKind.choice,
          options: ['Chairperson + Treasurer'],
        ),
      ],
      documents: [
        KycDocumentDefinition('minutes', 'Upload signed minutes / resolution'),
      ],
    ),
    KycStepDefinition(
      id: 'officers',
      title: 'Chair & treasurer KYC',
      description: 'ID and proof of address (< 3 months) for both\nbearers.',
      section: 'Office Bearers',
      memberRoles: [KycMemberRole.chairperson, KycMemberRole.treasurer],
    ),
    KycStepDefinition(
      id: 'register',
      title: 'Member register',
      description: 'Provide the names and ID numbers of all stokvel members.',
      section: 'Member register (summary)',
      documents: [
        KycDocumentDefinition('memberRegister', 'Member register (summary)'),
      ],
    ),
    KycStepDefinition(
      id: 'bank',
      title: 'Stokvel bank account',
      description:
          'A bank confirmation letter in the stokvel’s registered name, dated within the last 3 months',
      section: 'Account Details',
      fields: [
        KycFieldDefinition(
          'bank',
          'Bank Type',
          kind: KycFieldKind.choice,
          options: banks,
        ),
        KycFieldDefinition(
          'accountNumber',
          'Account No',
          hint: 'Enter No',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'branchCode',
          'Branch Code',
          hint: 'Enter BC',
          kind: KycFieldKind.number,
        ),
        KycFieldDefinition(
          'accountName',
          'Account Name',
          hint: 'Enter account name',
        ),
        KycFieldDefinition(
          'useForWithdrawals',
          'Use this account for withdrawals',
          kind: KycFieldKind.toggle,
          required: false,
        ),
      ],
      documents: [
        KycDocumentDefinition('bankProof', 'Upload Bank confirmation letter'),
      ],
    ),
    KycStepDefinition(
      id: 'funds',
      title: 'Source of funds',
      description:
          'For stokvels the source of funds is your members’ contributions.',
      section: 'Contributions Structure',
      fields: [
        KycFieldDefinition(
          'frequency',
          'Contribution Frequency',
          hint: 'e.g Daily, weekly & monthly',
          kind: KycFieldKind.choice,
          options: ['Daily', 'Weekly', 'Monthly'],
        ),
        KycFieldDefinition(
          'contribution',
          'Contribution amount per member',
          hint: 'Enter amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'annualFlow',
          'Total annual flow',
          hint: 'Enter amount',
          kind: KycFieldKind.amount,
        ),
        KycFieldDefinition(
          'fundSources',
          'Member Contribution Origin',
          kind: KycFieldKind.multipleChoice,
          options: [
            'Salaries',
            'Self-employed income',
            'Investments',
            'Savings',
          ],
        ),
      ],
      documents: [
        KycDocumentDefinition(
          'statements',
          'Upload last 3 months of bank statements',
        ),
      ],
    ),
  ];
}
