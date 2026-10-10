import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_plan.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

abstract final class KycValidation {
  static Map<String, String> progressStep(
    KycDraft draft,
    KycStepDefinition definition, {
    DateTime? now,
  }) {
    final errors = step(draft, definition, now: now);
    if (draft.entity == EntityType.trust &&
        ['resolution', 'trustees'].contains(definition.id) &&
        draft.members.any(definition.includesMember)) {
      errors.remove('members');
    }
    return errors;
  }

  static Map<String, String> submission(KycDraft draft, {DateTime? now}) => {
    for (final definition in KycPlans.steps(draft.entity))
      ...progressStep(draft, definition, now: now),
    ...fields(draft.values, KycReviewPlan.declarations(draft.entity), now: now),
  };

  static Map<String, String> step(
    KycDraft draft,
    KycStepDefinition step, {
    DateTime? now,
  }) {
    final errors = step.id == 'resolution'
        ? resolutionFields(draft, step, now: now)
        : fields(draft.values, step.fields, now: now);
    if (draft.entity == EntityType.stokvel) {
      final total = int.tryParse(draft.values['memberCount'] ?? '');
      if (step.id == 'constitution' && (total == null || total < 1)) {
        errors['memberCount'] = 'Enter at least one member.';
      }
    }
    if (step.id == 'tax' && draft.values['secondaryTax'] == 'true') {
      if (draft.taxResidencies.isEmpty) {
        errors['secondaryTax'] = 'Add a secondary tax residency to continue.';
      }
      final countries = <String>{draft.values['taxCountry'] ?? ''};
      for (final residency in draft.taxResidencies) {
        if (!countries.add(residency.country) ||
            fields(
              residency.formValues,
              KycTaxPlan.residencyFields,
              now: now,
            ).isNotEmpty) {
          errors['secondaryTax'] = 'Review the secondary tax residencies.';
        }
      }
    }
    for (final document in step.documents) {
      if (document.key == 'pepWealthProof' &&
          draft.values['pep'] != KycTaxPlan.pepYes) {
        continue;
      }
      final uploaded = draft.documentsFor(document.key);
      if (document.required && uploaded.isEmpty) {
        errors[document.key] = 'Add this document to continue.';
      }
      for (final file in uploaded) {
        if (file.rejection != null) errors[document.key] = file.rejection!;
      }
    }
    if (step.memberRoles.isNotEmpty) {
      final members = draft.members.where(step.includesMember).toList();
      if (members.isEmpty) {
        errors['members'] = 'Add the required members to continue.';
      }
      if (step.id == 'officers') {
        for (final role in step.memberRoles) {
          if (!members.any((member) => member.role == role)) {
            errors['members'] = 'Add a chairperson and a treasurer.';
          }
        }
      }
      if (step.requiresAllocation &&
          members.fold(0, (total, member) => total + member.shareBasisPoints) !=
              10000) {
        errors['allocation'] = 'The total allocation must equal 100%.';
      }
      if (step.requiresAllocation &&
          members.any((member) {
            final pending = draft.values['allocation:${member.id}'];
            return pending != null &&
                int.tryParse(pending) != member.shareBasisPoints;
          })) {
        errors['allocation'] = 'Save the allocation changes before continuing.';
      }
      if (['trustees', 'directors', 'officers'].contains(step.id) &&
          members.any(
            (member) =>
                (member.role != KycMemberRole.shareholder ||
                    member.details?.isDirector == true ||
                    member.shareBasisPoints > 500) &&
                (!member.identityVerified || !member.addressVerified),
          )) {
        errors['members'] =
            'Complete the ID and address checks for each required member.';
      }
      if (step.id == 'resolution' && members.any((member) => !member.signed)) {
        errors['members'] =
            'All authorised signatories must sign the resolution.';
      }
    }
    return errors;
  }

  static Map<String, String> fields(
    Map<String, String> values,
    List<KycFieldDefinition> definitions, {
    DateTime? now,
    bool ignoreVisibility = false,
  }) {
    final errors = <String, String>{};
    for (final field in definitions.where(
      (field) => ignoreVisibility || field.visible(values),
    )) {
      final value = values[field.key]?.trim() ?? '';
      if (field.required &&
          (value.isEmpty ||
              field.kind == KycFieldKind.toggle && value != 'true')) {
        errors[field.key] = field.kind == KycFieldKind.toggle
            ? 'Please confirm before continuing.'
            : 'This field is required';
        continue;
      }
      if (value.isEmpty) continue;
      final valid = switch (field.kind) {
        KycFieldKind.email => RegExp(
          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
        ).hasMatch(value),
        KycFieldKind.phone => RegExp(r'^\+?[0-9 ]{8,18}$').hasMatch(value),
        KycFieldKind.number =>
          RegExp(r'^\d+$').hasMatch(value) && value.length <= 24,
        KycFieldKind.amount =>
          (MonetaryAmount.tryParse(value, Currency.zar)?.minorUnits ?? 0) > 0,
        KycFieldKind.date => validDate(value, now ?? DateTime.now()),
        KycFieldKind.choice => field.options.contains(value),
        KycFieldKind.multipleChoice =>
          value.split('|').every(field.options.contains),
        _ => value.length <= 2000,
      };
      if (!valid) {
        errors[field.key] = 'Enter a valid ${field.label.toLowerCase()}';
      }
    }
    return errors;
  }

  static Map<String, String> resolutionFields(
    KycDraft draft,
    KycStepDefinition step, {
    DateTime? now,
  }) {
    final errors = fields(draft.values, step.fields, now: now);
    if (draft.entity == EntityType.company ||
        draft.entity == EntityType.stokvel) {
      final present = int.tryParse(draft.values['membersPresent'] ?? '');
      final total = draft.entity == EntityType.company
          ? draft.members.where(step.includesMember).length
          : int.tryParse(draft.values['memberCount'] ?? '');
      if (present == null || present < 1 || total != null && present > total) {
        errors['membersPresent'] =
            'Enter a valid count within the total membership.';
      }
    }
    return errors;
  }

  static Map<String, String> taxSection(
    KycDraft draft,
    KycTaxSection section, {
    DateTime? now,
  }) {
    final errors = fields(
      draft.values,
      KycTaxPlan.sectionFields(section),
      now: now,
      ignoreVisibility: true,
    );
    if (section == KycTaxSection.wealth) {
      final rejection =
          draft.documents[KycTaxPlan.wealthDocument.key]?.rejection;
      if (rejection != null) errors[KycTaxPlan.wealthDocument.key] = rejection;
    }
    if (section == KycTaxSection.residency) {
      final country = draft.values['secondaryTaxCountry'];
      if (country == draft.values['taxCountry'] ||
          draft.taxResidencies.any(
            (residency) =>
                residency.country == country &&
                residency.id != draft.values['editingTaxResidency'],
          )) {
        errors['secondaryTaxCountry'] = 'This country is already on file.';
      }
    }
    return errors;
  }

  static bool validDate(String text, DateTime now) {
    final date = DateTime.tryParse(text);
    if (date == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return false;
    }
    return date.toIso8601String().startsWith(text) &&
        !date.isAfter(now) &&
        date.year >= 1900;
  }

  static String? document({
    required String name,
    required int bytes,
    required String mimeType,
  }) {
    if (name.trim().isEmpty ||
        name.length > 160 ||
        name.contains('/') ||
        name.contains('\\')) {
      return 'Choose a valid file name.';
    }
    if (bytes <= 0 || bytes > 5 * 1024 * 1024) {
      return 'Choose a file no larger than 5MB.';
    }
    final extension = name.split('.').last.toLowerCase();
    final expected = switch (extension) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      _ => null,
    };
    if (expected == null || mimeType != expected) {
      return 'Choose a PNG, JPG or PDF file.';
    }
    return null;
  }

  static Map<String, String> member(KycMember member) => {
    if (member.firstName.trim().isEmpty) 'firstName': 'Enter a first name',
    if (member.lastName.trim().isEmpty) 'lastName': 'Enter a last name',
    if (member.identityNumber.trim().isEmpty)
      'identityNumber': 'Enter an ID / passport number',
    if (member.shareBasisPoints < 0 || member.shareBasisPoints > 10000)
      'share': 'Enter a percentage between 0 and 100',
    if (member.email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(member.email))
      'email': 'Enter a valid email address',
    if (!KycPlans.countries.contains(member.country))
      'country': 'Select a country',
  };
}
