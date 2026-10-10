import 'package:developify_mobile/features/shared/domain/app_user.dart';

typedef KycChecklistItem = ({String step, String title, String subtitle});

abstract final class KycChecklistContent {
  static int number(EntityType entity) => switch (entity) {
    EntityType.individual => 1,
    EntityType.trust => 2,
    EntityType.company => 3,
    EntityType.stokvel => 4,
  };

  static double rowHeight(EntityType entity, int index) => switch (entity) {
    EntityType.individual => [90.0, 71.0, 91.0, 71.0, 71.0, 71.0][index],
    EntityType.trust => [70.0, 89.0, 91.0, 71.0, 72.0, 71.0][index],
    EntityType.company => [70.0, 76.0, 79.0, 94.0, 72.0, 71.0][index],
    EntityType.stokvel => [70.0, 88.0, 78.0, 67.0, 72.0, 71.0][index],
  };

  static double textGap(EntityType entity, String step) =>
      switch ((entity, step)) {
        (EntityType.trust, 'beneficiaries') => 3,
        (EntityType.company, 'shareholders') => 0,
        (EntityType.company, 'directors') => 2,
        (EntityType.stokvel, 'officers') => 5,
        (EntityType.stokvel, 'register') => 0,
        (EntityType.stokvel, 'bank') => 2,
        _ => 7,
      };

  static List<KycChecklistItem> items(EntityType entity) => switch (entity) {
    EntityType.individual => const [
      (
        step: 'identity',
        title: 'Valid SA ID or Passport',
        subtitle: 'Government-issued ID by the South African Government',
      ),
      (
        step: 'selfie',
        title: 'Live selfie / Biometrics verification',
        subtitle: 'Verified at login',
      ),
      (
        step: 'address',
        title: 'Proof of residential address (< 3 Months)',
        subtitle: 'Utility bill, bank statements',
      ),
      (
        step: 'contact',
        title: 'Mobile & Email Verification',
        subtitle: 'Verified at login',
      ),
      (
        step: 'tax',
        title: 'Sanctions, PEP & Adverse media',
        subtitle: 'UN, EU, OFAC, HMT screening',
      ),
      (
        step: 'funds',
        title: 'Source of Funds declaration',
        subtitle: 'Salary, business, etc.',
      ),
    ],
    EntityType.trust => const [
      (step: 'deed', title: 'Trust Deed', subtitle: 'Stamped and signed copy'),
      (
        step: 'authority',
        title: 'Letters of Authority (Master of the\nHigh Court)',
        subtitle: 'Current letters naming all trustees',
      ),
      (
        step: 'resolution',
        title: 'Trustee resolution authorising investment',
        subtitle: 'Signed by all serving trustees',
      ),
      (
        step: 'trustees',
        title: 'ID & Proof of address for all trustees',
        subtitle: 'One pack per trustee (< 3 months)',
      ),
      (
        step: 'beneficiaries',
        title: 'Identification of founder & beneficiaries',
        subtitle: 'Names, IDs, beneficial-interest %',
      ),
      (
        step: 'funds',
        title: 'Source of Funds declaration',
        subtitle: 'Origin of trust capital',
      ),
    ],
    EntityType.company => const [
      (
        step: 'registration',
        title: 'CIPC registration documents',
        subtitle: 'CoR 14.3 / 14.1 disclosure certificate',
      ),
      (
        step: 'moi',
        title: 'Memorandum of Incorporation',
        subtitle: 'Current adopted MOI',
      ),
      (
        step: 'shareholders',
        title: 'Share register',
        subtitle: 'Showing all shareholders and holdings',
      ),
      (
        step: 'resolution',
        title: 'Board resolution authorising investment',
        subtitle: 'Signed by the chairperson + secretary',
      ),
      (
        step: 'directors',
        title: 'ID & Proof of address for directors\n& UBOs',
        subtitle: 'For every director and > 5% UBO',
      ),
      (
        step: 'funds',
        title: 'Source of Funds declaration',
        subtitle: 'Retained earnings, capital raise etc.',
      ),
    ],
    EntityType.stokvel => const [
      (
        step: 'constitution',
        title: 'Constitution or founding documents',
        subtitle: 'Signed by founding members',
      ),
      (
        step: 'resolution',
        title: 'Resolution authorising investment',
        subtitle: 'Minutes signed by chairperson & secretary',
      ),
      (
        step: 'officers',
        title: 'ID & Proof of address for chairperson & treasurer',
        subtitle: 'One pack each < 3 months old',
      ),
      (
        step: 'register',
        title: 'Member register (summary)',
        subtitle: 'Names + ID of all members',
      ),
      (
        step: 'bank',
        title: 'Proof of stokvel bank accounts',
        subtitle: 'Bank confirmation letters in the stokvel’s name',
      ),
      (
        step: 'funds',
        title: 'Source of Funds declaration',
        subtitle: 'Average monthly contributions, terms',
      ),
    ],
  };

  static String introduction(EntityType entity) => switch (entity) {
    EntityType.individual =>
      'Provide your identity, residential address and declarations. Documents and verification are simulated in this session.',
    EntityType.trust =>
      'Upload the trust’s founding document plus KYC for every trustee. Document checks are simulated in this session.',
    EntityType.company =>
      'We collect company filings plus KYC for every director and ultimate beneficial owner (UBO > 5%).',
    EntityType.stokvel =>
      'Provide the founding documents, office-bearer KYC and pooled bank account. Document checks are simulated in this session.',
  };

  static String reminder(EntityType entity, {bool verified = false}) => verified
      ? 'Your investor profile is verified for this simulated session.'
      : switch (entity) {
          EntityType.individual =>
            'Complete each requirement before submitting. Your documents and verification results remain simulated in this session.',
          EntityType.trust =>
            'You can save and return during this simulated session.',
          EntityType.company =>
            'For a director or UBO who is a foreign national, include their country and residency details.',
          EntityType.stokvel =>
            'Save and return after adding the documents for your office bearers and members.',
        };
}
