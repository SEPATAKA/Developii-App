import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_options.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_validation.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

enum KycMemberSection {
  details,
  allocation,
  invite,
  preview;

  static KycMemberSection? tryParse(String? value) {
    for (final section in values) {
      if (section.name == value) return section;
    }
    return null;
  }
}

extension KycMemberRoleLabel on KycMemberRole {
  String get label => switch (this) {
    KycMemberRole.trustee => 'Trustee',
    KycMemberRole.beneficiary => 'Beneficiary',
    KycMemberRole.shareholder => 'Shareholder',
    KycMemberRole.director => 'Director',
    KycMemberRole.chairperson => 'Chairperson',
    KycMemberRole.treasurer => 'Treasurer',
  };
  String get parentStep => switch (this) {
    KycMemberRole.trustee => 'trustees',
    KycMemberRole.beneficiary => 'beneficiaries',
    KycMemberRole.shareholder => 'shareholders',
    KycMemberRole.director => 'directors',
    KycMemberRole.chairperson || KycMemberRole.treasurer => 'officers',
  };
}

abstract final class KycMemberPlan {
  static KycMemberRole? role(EntityType entity, String? value) {
    for (final role in KycMemberRole.values) {
      if (role.name == value &&
          KycPlans.steps(
            entity,
          ).any((step) => step.memberRoles.contains(role))) {
        return role;
      }
    }
    return null;
  }

  static const firstName = KycFieldDefinition(
    'firstName',
    'First Name',
    hint: 'Enter first name',
  );
  static const lastName = KycFieldDefinition(
    'lastName',
    'Last Name',
    hint: 'Enter last name',
  );
  static const identity = KycFieldDefinition(
    'identityNumber',
    'ID / Passport No',
    hint: 'Enter ID number',
  );
  static const country = KycFieldDefinition(
    'country',
    'Nationality',
    hint: 'Select country',
    kind: KycFieldKind.choice,
    options: KycOptions.countries,
  );
  static const birthDate = KycFieldDefinition(
    'birthDate',
    'Date of birth',
    hint: 'YYYY-MM-DD',
    kind: KycFieldKind.date,
  );
  static const relationship = KycFieldDefinition(
    'relationship',
    'Relationship to founder',
    hint: 'Select',
    kind: KycFieldKind.choice,
    options: [
      'Spouse',
      'Child',
      'Daughter',
      'Son',
      'Grandchild',
      'Sibling',
      'Other family',
      'Unrelated',
    ],
  );
  static const director = KycFieldDefinition(
    'isDirector',
    'Also a director of the company',
    kind: KycFieldKind.toggle,
    required: false,
  );
  static const email = KycFieldDefinition(
    'email',
    'Email Address',
    hint: 'Enter email address',
    kind: KycFieldKind.email,
    required: false,
  );
  static const position = KycFieldDefinition(
    'position',
    'Position / Role',
    hint: 'Enter position',
    required: false,
  );
  static const shareFields = [
    KycFieldDefinition(
      'shareClass',
      'Share class',
      hint: 'Select class',
      kind: KycFieldKind.choice,
      options: ['Ordinary', 'Preference'],
    ),
    KycFieldDefinition(
      'numberOfShares',
      'Number of shares',
      hint: 'Enter no. of shares',
      kind: KycFieldKind.number,
    ),
    KycFieldDefinition(
      'issuedShares',
      'Total shares issued',
      hint: 'Enter total issued',
      kind: KycFieldKind.number,
    ),
    KycFieldDefinition(
      'acquiredOn',
      'Date acquired',
      hint: 'YYYY-MM-DD',
      kind: KycFieldKind.date,
    ),
    KycFieldDefinition('acquisition', 'How acquired', hint: 'Explain'),
  ];
  static const guardianFields = [
    KycFieldDefinition(
      'guardianName',
      'Guardian full name',
      hint: 'Enter full name',
    ),
    KycFieldDefinition(
      'guardianIdentity',
      'ID / Passport No',
      hint: 'Enter ID number',
    ),
    KycFieldDefinition(
      'guardianCountry',
      'Country',
      hint: 'Select country',
      kind: KycFieldKind.choice,
      options: KycOptions.countries,
    ),
  ];

  static List<KycFieldDefinition> identityFields(KycMemberRole role) => [
    firstName,
    lastName,
    identity,
    if (role == KycMemberRole.beneficiary) ...[
      birthDate,
      relationship,
    ] else
      country,
    if (role == KycMemberRole.shareholder) director,
    if (role != KycMemberRole.beneficiary &&
        role != KycMemberRole.shareholder) ...[
      email,
      position,
    ],
  ];

  static int? age(String value, DateTime now) {
    if (!KycValidation.validDate(value, now)) return null;
    final birth = DateTime.parse(value);
    return now.year -
        birth.year -
        (now.month < birth.month ||
                now.month == birth.month && now.day < birth.day
            ? 1
            : 0);
  }

  static int sharesBasisPoints(Map<String, String> values) {
    final count = int.tryParse(values['numberOfShares'] ?? '');
    final total = int.tryParse(values['issuedShares'] ?? '');
    if (count == null ||
        total == null ||
        count < 0 ||
        total <= 0 ||
        count > total ||
        total > 1000000000) {
      return -1;
    }
    return (count * 10000 + total ~/ 2) ~/ total;
  }

  static List<KycDocumentDefinition> documents(
    KycMemberDraft draft,
    DateTime now,
  ) {
    if (draft.role == KycMemberRole.beneficiary) {
      final years = age(draft.values['birthDate'] ?? '', now);
      return [
        const KycDocumentDefinition('identity', 'Birth Certificate or ID copy'),
        KycDocumentDefinition(
          'guardian',
          'Guardian’s ID Copy',
          required: years != null && years < 18,
        ),
        const KycDocumentDefinition(
          'relationship',
          'Proof of relationship (Optional)',
          required: false,
        ),
      ];
    }
    final required =
        draft.role != KycMemberRole.shareholder ||
        draft.values['isDirector'] == 'true' ||
        sharesBasisPoints(draft.values) > 500;
    return [
      KycDocumentDefinition(
        'identity',
        'Upload Certified ID / Passport',
        required: required,
      ),
      KycDocumentDefinition(
        'address',
        'Proof of address (< 3 months)',
        required: required,
      ),
      if (draft.role == KycMemberRole.shareholder)
        const KycDocumentDefinition(
          'shareCertificate',
          'Share certificate / issue resolution',
        ),
    ];
  }

  static Map<String, String> validate(KycMemberDraft draft, DateTime now) {
    final values = draft.values;
    final errors = KycValidation.fields(
      values,
      identityFields(draft.role),
      now: now,
    );
    if (draft.role == KycMemberRole.beneficiary &&
        (age(values['birthDate'] ?? '', now) ?? 18) < 18) {
      errors.addAll(KycValidation.fields(values, guardianFields, now: now));
    }
    if (draft.role == KycMemberRole.shareholder) {
      errors.addAll(KycValidation.fields(values, shareFields, now: now));
      if (sharesBasisPoints(values) <= 0) {
        errors['numberOfShares'] =
            'Enter a positive holding within the total issued shares.';
      }
    }
    for (final definition in documents(draft, now)) {
      final document = draft.documents[definition.key];
      if (definition.required && document == null) {
        errors[definition.key] = 'Add this document to continue.';
      }
      if (document?.rejection case final rejection?) {
        errors[definition.key] = rejection;
      }
    }
    return errors;
  }

  static KycMemberDraft fromMember(KycMember member) {
    final details = member.details;
    return KycMemberDraft(
      id: member.id,
      role: member.role,
      documents: details?.documents ?? const {},
      values: {
        'firstName': member.firstName,
        'lastName': member.lastName,
        'identityNumber': member.identityNumber,
        'country': member.country,
        'email': member.email,
        'birthDate': member.birthDate,
        'relationship': member.relationship,
        'share': (member.shareBasisPoints / 100).toStringAsFixed(2),
        'guardianName': details?.guardianName ?? '',
        'guardianIdentity': details?.guardianIdentity ?? '',
        'guardianCountry': details?.guardianCountry ?? '',
        'shareClass': details?.shareClass ?? '',
        'numberOfShares': details == null ? '' : '${details.numberOfShares}',
        'issuedShares': details == null ? '' : '${details.issuedShares}',
        'acquiredOn':
            details?.acquiredOn?.toIso8601String().substring(0, 10) ?? '',
        'acquisition': details?.acquisition ?? '',
        'isDirector': '${details?.isDirector ?? false}',
        'position': details?.position ?? '',
      },
    );
  }

  static KycMember member(KycMemberDraft draft, {KycMember? previous}) {
    final values = draft.values;
    return KycMember(
      id: draft.id,
      firstName: values['firstName']?.trim() ?? '',
      lastName: values['lastName']?.trim() ?? '',
      role: draft.role,
      identityNumber: values['identityNumber']?.trim() ?? '',
      country: values['country'] ?? 'South Africa',
      email: values['email']?.trim() ?? '',
      birthDate: values['birthDate'] ?? '',
      relationship: values['relationship'] ?? '',
      shareBasisPoints: draft.role == KycMemberRole.shareholder
          ? sharesBasisPoints(values)
          : MonetaryAmount.tryParse(
                  values['share'] ?? '0',
                  Currency.zar,
                )?.minorUnits ??
                0,
      identityVerified:
          draft.documents['identity'] != null &&
          draft.documents['identity']!.rejection == null,
      addressVerified:
          draft.documents['address'] != null &&
          draft.documents['address']!.rejection == null,
      inviteSent: previous?.inviteSent ?? false,
      resolutionSignature:
          previous?.resolutionSignature ?? const KycResolutionSignature(),
      details: KycMemberDetails(
        guardianName: values['guardianName'] ?? '',
        guardianIdentity: values['guardianIdentity'] ?? '',
        guardianCountry: values['guardianCountry'] ?? '',
        shareClass: values['shareClass'] ?? '',
        numberOfShares: int.tryParse(values['numberOfShares'] ?? '') ?? 0,
        issuedShares: int.tryParse(values['issuedShares'] ?? '') ?? 0,
        acquiredOn: DateTime.tryParse(values['acquiredOn'] ?? ''),
        acquisition: values['acquisition'] ?? '',
        isDirector: values['isDirector'] == 'true',
        position: values['position'] ?? '',
        documents: draft.documents,
      ),
    );
  }

  static const inviteAttachments = <String, (String, String, bool)>{
    'appointment': ('T - 104 Acknowledgment of Appointment', '', true),
    'resolution': (
      'T - 105 Resolution of Co - Trustees',
      'Only if you’re using this route',
      false,
    ),
    'amendment': (
      'T - 106 Deed of Amendment',
      'Only if you’re amending the deed',
      false,
    ),
    'trustDeed': (
      'Copy of the founding Trust Deed',
      'So trustee can review context',
      false,
    ),
  };
  static Map<String, String> validateInvite(
    KycInvite invite, {
    required bool trust,
  }) => {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(invite.email))
      'email': 'Enter a valid email address.',
    if ((invite.sendSms || invite.phone.isNotEmpty) &&
        !RegExp(r'^\+?[0-9 ]{8,18}$').hasMatch(invite.phone))
      'phone': 'Enter a valid phone number.',
    if (invite.message.length > 2000)
      'message': 'Use no more than 2,000 characters.',
    if (trust && !invite.attachments.contains('appointment'))
      'attachments': 'Select the appointment acknowledgment.',
    if (invite.attachments.any((key) => !inviteAttachments.containsKey(key)))
      'attachments': 'Choose an available attachment.',
  };
}
