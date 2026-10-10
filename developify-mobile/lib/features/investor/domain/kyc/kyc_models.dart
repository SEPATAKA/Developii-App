import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

enum KycFieldKind {
  text,
  email,
  phone,
  number,
  amount,
  date,
  choice,
  toggle,
  multiline,
  multipleChoice,
}

enum KycMemberRole {
  trustee,
  beneficiary,
  shareholder,
  director,
  chairperson,
  treasurer,
}

final class KycFieldDefinition {
  const KycFieldDefinition(
    this.key,
    this.label, {
    this.hint = '',
    this.kind = KycFieldKind.text,
    this.required = true,
    this.options = const [],
    this.helper,
    this.visibleWhen,
    this.visibleValue = 'true',
  });
  final String key;
  final String label;
  final String hint;
  final KycFieldKind kind;
  final bool required;
  final List<String> options;
  final String? helper;
  final String? visibleWhen;
  final String visibleValue;
  bool visible(Map<String, String> values) =>
      visibleWhen == null || values[visibleWhen] == visibleValue;
}

final class KycDocumentDefinition {
  const KycDocumentDefinition(
    this.key,
    this.title, {
    this.required = true,
    this.multiple = false,
  });
  final String key;
  final String title;
  final bool required;
  final bool multiple;
}

final class KycStepDefinition {
  const KycStepDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.section,
    this.fields = const [],
    this.documents = const [],
    this.memberRoles = const [],
    this.requiresAllocation = false,
    this.acceptedDocuments = const [],
  });
  final String id;
  final String title;
  final String description;
  final String section;
  final List<KycFieldDefinition> fields;
  final List<KycDocumentDefinition> documents;
  final List<KycMemberRole> memberRoles;
  final bool requiresAllocation;
  final List<String> acceptedDocuments;

  bool permitsMemberRole(KycMemberRole role) =>
      memberRoles.contains(role) ||
      role == KycMemberRole.shareholder &&
          memberRoles.contains(KycMemberRole.director);

  bool includesMember(KycMember member) =>
      memberRoles.contains(member.role) ||
      member.role == KycMemberRole.shareholder &&
          member.details?.isDirector == true &&
          memberRoles.contains(KycMemberRole.director);
}

enum KycUploadStatus { uploading, failed }

final class KycUploadAttempt {
  const KycUploadAttempt({
    required this.name,
    required this.bytes,
    required this.mimeType,
    this.status = KycUploadStatus.uploading,
    this.error,
    this.append = false,
    this.documentId,
  });
  final String name;
  final int bytes;
  final String mimeType;
  final KycUploadStatus status;
  final String? error;
  final bool append;
  final String? documentId;
}

final class KycDocument {
  const KycDocument({
    required this.id,
    required this.name,
    required this.bytes,
    required this.mimeType,
    required this.uploadedAt,
    this.rejection,
  });
  final String id;
  final String name;
  final int bytes;
  final String mimeType;
  final DateTime uploadedAt;
  final String? rejection;
}

enum KycSignatureStatus { notRequested, awaiting, signed }

final class KycResolutionSignature {
  const KycResolutionSignature({
    this.status = KycSignatureStatus.notRequested,
    this.requestedAt,
    this.signedAt,
  });
  final KycSignatureStatus status;
  final DateTime? requestedAt;
  final DateTime? signedAt;
}

final class KycMember {
  const KycMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.identityNumber,
    this.email = '',
    this.country = 'South Africa',
    this.relationship = '',
    this.birthDate = '',
    this.shareBasisPoints = 0,
    this.identityVerified = false,
    this.addressVerified = false,
    this.inviteSent = false,
    this.resolutionSignature = const KycResolutionSignature(),
    this.details,
  });
  final String id;
  final String firstName;
  final String lastName;
  final KycMemberRole role;
  final String identityNumber;
  final String email;
  final String country;
  final String relationship;
  final String birthDate;
  final int shareBasisPoints;
  final bool identityVerified;
  final bool addressVerified;
  final bool inviteSent;
  final KycResolutionSignature resolutionSignature;
  bool get signed => resolutionSignature.status == KycSignatureStatus.signed;
  final KycMemberDetails? details;
  String get name => '$firstName $lastName'.trim().isEmpty
      ? email
      : '$firstName $lastName'.trim();
  KycMember copyWith({
    bool? identityVerified,
    bool? addressVerified,
    bool? inviteSent,
    KycResolutionSignature? resolutionSignature,
    int? shareBasisPoints,
    KycMemberDetails? details,
  }) => KycMember(
    id: id,
    firstName: firstName,
    lastName: lastName,
    role: role,
    identityNumber: identityNumber,
    email: email,
    country: country,
    relationship: relationship,
    birthDate: birthDate,
    shareBasisPoints: shareBasisPoints ?? this.shareBasisPoints,
    identityVerified: identityVerified ?? this.identityVerified,
    addressVerified: addressVerified ?? this.addressVerified,
    inviteSent: inviteSent ?? this.inviteSent,
    resolutionSignature: resolutionSignature ?? this.resolutionSignature,
    details: details ?? this.details,
  );
}

final class KycMemberDetails {
  KycMemberDetails({
    this.guardianName = '',
    this.guardianIdentity = '',
    this.guardianCountry = '',
    this.shareClass = '',
    this.numberOfShares = 0,
    this.issuedShares = 0,
    this.acquiredOn,
    this.acquisition = '',
    this.isDirector = false,
    this.position = '',
    Map<String, KycDocument> documents = const {},
  }) : documents = Map.unmodifiable(documents);
  final String guardianName;
  final String guardianIdentity;
  final String guardianCountry;
  final String shareClass;
  final int numberOfShares;
  final int issuedShares;
  final DateTime? acquiredOn;
  final String acquisition;
  final bool isDirector;
  final String position;
  final Map<String, KycDocument> documents;

  KycMemberDetails withShares(int count) => KycMemberDetails(
    guardianName: guardianName,
    guardianIdentity: guardianIdentity,
    guardianCountry: guardianCountry,
    shareClass: shareClass,
    numberOfShares: count,
    issuedShares: issuedShares,
    acquiredOn: acquiredOn,
    acquisition: acquisition,
    isDirector: isDirector,
    position: position,
    documents: documents,
  );
}

final class KycMemberDraft {
  KycMemberDraft({
    required this.id,
    required this.role,
    Map<String, String> values = const {},
    Map<String, KycDocument> documents = const {},
  }) : values = Map.unmodifiable(values),
       documents = Map.unmodifiable(documents);
  final String id;
  final KycMemberRole role;
  final Map<String, String> values;
  final Map<String, KycDocument> documents;
  KycMemberDraft copyWith({
    Map<String, String>? values,
    Map<String, KycDocument>? documents,
  }) => KycMemberDraft(
    id: id,
    role: role,
    values: values ?? this.values,
    documents: documents ?? this.documents,
  );
}

final class KycIdentitySummary {
  const KycIdentitySummary({
    required this.name,
    required this.birthDate,
    required this.nationality,
    required this.residence,
  });
  final String name;
  final DateTime birthDate;
  final String nationality;
  final String residence;
}

final class KycDraft {
  KycDraft({
    required this.entity,
    this.currentStep = 'overview',
    Map<String, String> values = const {},
    Map<String, KycDocument> documents = const {},
    Map<String, List<KycDocument>> additionalDocuments = const {},
    List<KycMember> members = const [],
    List<KycTaxResidency> taxResidencies = const [],
    Map<String, Map<String, String>> taxResidencyEdits = const {},
    Map<String, KycMemberDraft> memberDrafts = const {},
    Map<String, KycInviteReceipt> invitationReceipts = const {},
    Set<String> completedSteps = const {},
    Set<String> verifiedSteps = const {},
    this.status = VerificationStatus.incomplete,
    this.revision = 0,
    this.submissionId,
    this.correction,
    this.identitySummary,
  }) : values = Map.unmodifiable(values),
       documents = Map.unmodifiable(documents),
       additionalDocuments = Map.unmodifiable({
         for (final entry in additionalDocuments.entries)
           entry.key: List<KycDocument>.unmodifiable(entry.value),
       }),
       members = List.unmodifiable(members),
       taxResidencies = List.unmodifiable(taxResidencies),
       taxResidencyEdits = Map.unmodifiable({
         for (final entry in taxResidencyEdits.entries)
           entry.key: Map<String, String>.unmodifiable(entry.value),
       }),
       memberDrafts = Map.unmodifiable(memberDrafts),
       invitationReceipts = Map.unmodifiable(invitationReceipts),
       completedSteps = Set.unmodifiable(completedSteps),
       verifiedSteps = Set.unmodifiable(verifiedSteps);
  final EntityType entity;
  final String currentStep;
  final Map<String, String> values;
  final Map<String, KycDocument> documents;
  final Map<String, List<KycDocument>> additionalDocuments;
  List<KycDocument> documentsFor(String key) =>
      List.unmodifiable([?documents[key], ...?additionalDocuments[key]]);
  final List<KycMember> members;
  final List<KycTaxResidency> taxResidencies;
  final Map<String, Map<String, String>> taxResidencyEdits;
  final Map<String, KycMemberDraft> memberDrafts;
  final Map<String, KycInviteReceipt> invitationReceipts;
  final Set<String> completedSteps;
  final Set<String> verifiedSteps;
  final VerificationStatus status;
  final int revision;
  final String? submissionId;
  final String? correction;
  final KycIdentitySummary? identitySummary;
  KycDraft copyWith({
    String? currentStep,
    Map<String, String>? values,
    Map<String, KycDocument>? documents,
    Map<String, List<KycDocument>>? additionalDocuments,
    List<KycMember>? members,
    List<KycTaxResidency>? taxResidencies,
    Map<String, Map<String, String>>? taxResidencyEdits,
    Map<String, KycMemberDraft>? memberDrafts,
    Map<String, KycInviteReceipt>? invitationReceipts,
    Set<String>? completedSteps,
    Set<String>? verifiedSteps,
    VerificationStatus? status,
    String? submissionId,
    String? correction,
    bool clearCorrection = false,
    KycIdentitySummary? identitySummary,
    bool clearIdentitySummary = false,
  }) => KycDraft(
    entity: entity,
    currentStep: currentStep ?? this.currentStep,
    values: values ?? this.values,
    documents: documents ?? this.documents,
    additionalDocuments: additionalDocuments ?? this.additionalDocuments,
    members: members ?? this.members,
    taxResidencies: taxResidencies ?? this.taxResidencies,
    taxResidencyEdits: taxResidencyEdits ?? this.taxResidencyEdits,
    memberDrafts: memberDrafts ?? this.memberDrafts,
    invitationReceipts: invitationReceipts ?? this.invitationReceipts,
    completedSteps: completedSteps ?? this.completedSteps,
    verifiedSteps: verifiedSteps ?? this.verifiedSteps,
    status: status ?? this.status,
    revision: revision + 1,
    submissionId: submissionId ?? this.submissionId,
    correction: clearCorrection ? null : correction ?? this.correction,
    identitySummary: clearIdentitySummary
        ? null
        : identitySummary ?? this.identitySummary,
  );
}

final class KycTaxResidency {
  const KycTaxResidency({
    required this.country,
    required this.reason,
    required this.tinType,
    required this.tinFormat,
    required this.tin,
    required this.residentSince,
    required this.status,
    required this.usPerson,
    required this.certified,
  });
  final String country;
  final String reason;
  final String tinType;
  final String tinFormat;
  final String tin;
  final DateTime residentSince;
  final String status;
  final bool usPerson;
  final bool certified;
  String get id => country.toLowerCase().replaceAll(' ', '-');
  Map<String, String> get formValues => {
    'secondaryTaxCountry': country,
    'secondaryReason': reason,
    'secondaryTinType': tinType,
    'secondaryTinFormat': tinFormat,
    'secondaryTin': tin,
    'secondaryResidentSince': residentSince.toIso8601String().substring(0, 10),
    'secondaryStatus': status,
    'usPerson': usPerson.toString(),
    'secondaryCertification': certified.toString(),
  };
}

final class KycChange {
  const KycChange(this.entity);
  final EntityType? entity;
}

final class KycInviteReceipt {
  const KycInviteReceipt({
    required this.reference,
    required this.memberId,
    required this.email,
    required this.phone,
    required this.sentAt,
    required this.expiresAt,
  });
  final String reference;
  final String memberId;
  final String email;
  final String? phone;
  final DateTime sentAt;
  final DateTime expiresAt;
}

final class KycInvite {
  const KycInvite({
    required this.email,
    required this.memberId,
    this.phone = '',
    this.message = '',
    this.sendSms = false,
    this.reminders = false,
    this.notifyOpened = false,
    this.attachments = const {},
  });
  final String email;
  final String memberId;
  final String phone;
  final String message;
  final bool sendSms;
  final bool reminders;
  final bool notifyOpened;
  final Set<String> attachments;
}
