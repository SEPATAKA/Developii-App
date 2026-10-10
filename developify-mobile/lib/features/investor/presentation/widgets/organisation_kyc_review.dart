import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class CompanyKycReviewDetails extends StatelessWidget {
  const CompanyKycReviewDetails({super.key, required this.store});
  final KycStore store;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (id, title) in const [
        ('registration', 'Company Identity'),
        ('moi', 'MOI Details'),
        ('shareholders', 'Shareholders'),
        ('resolution', 'Board Resolution'),
        ('directors', 'Directors & Ultimate Beneficial Owners'),
        ('funds', 'Source of funds'),
      ])
        _ReviewSection(store: store, stepId: id, title: title),
    ],
  );
}

class StokvelKycReviewDetails extends StatelessWidget {
  const StokvelKycReviewDetails({super.key, required this.store});
  final KycStore store;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (id, title) in const [
        ('constitution', 'Stokvel Basics'),
        ('resolution', 'Resolution to Invest'),
        ('officers', 'Office Bearers'),
        ('register', 'Member register (summary)'),
        ('bank', 'Account Details'),
        ('funds', 'Contributions Structure'),
      ])
        _ReviewSection(store: store, stepId: id, title: title),
    ],
  );
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.store,
    required this.stepId,
    required this.title,
  });
  final KycStore store;
  final String stepId;
  final String title;

  String _value(KycFieldDefinition field) {
    final value = store.draft!.values[field.key] ?? '';
    if (value.isEmpty) {
      return field.kind == KycFieldKind.toggle ? 'No' : 'Not provided';
    }
    return switch (field.kind) {
      KycFieldKind.toggle => value == 'true' ? 'Yes' : 'No',
      KycFieldKind.date => switch (DateTime.tryParse(value)) {
        final date? => AppDateFormat.dayFirstDate(date),
        _ => value,
      },
      KycFieldKind.amount => switch (MonetaryAmount.tryParse(
        value,
        Currency.zar,
      )) {
        final amount? => Money.amount(amount),
        _ => value,
      },
      _ => value.replaceAll('|', ', '),
    };
  }

  @override
  Widget build(BuildContext context) {
    final draft = store.draft!;
    final step = store.steps.firstWhere((step) => step.id == stepId);
    return Padding(
      key: ValueKey('review-section-$stepId'),
      padding: EdgeInsets.only(bottom: 20.w),
      child: InvestorSurface(
        color: AppColors.investorCard,
        border: AppColors.borderStrong,
        radius: 10,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.text(16, weight: FontWeight.w600),
                  ),
                ),
                if (store.editable)
                  TextButton(
                    key: ValueKey('review-edit-$stepId'),
                    onPressed: store.busy
                        ? null
                        : () => store.selectStep(stepId),
                    child: const Text('Edit'),
                  ),
              ],
            ),
            for (final field in step.fields.where(
              (field) => field.visible(draft.values),
            ))
              _ReviewValue(
                field.label.isEmpty && field.key == 'fundSources'
                    ? 'Primary Source'
                    : field.label,
                _value(field),
              ),
            for (final member in draft.members.where(step.includesMember))
              _ReviewMember(
                member: member,
                signature: stepId == 'resolution',
                allocation: stepId == 'shareholders',
              ),
            for (final definition in step.documents) ...[
              SizedBox(height: 12.w),
              Text(
                definition.title,
                style: AppTextStyles.text(13, color: AppColors.muted),
              ),
              if (draft.documentsFor(definition.key).isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 6.w),
                  child: Text(
                    definition.required ? 'Required' : 'Not provided',
                    style: AppTextStyles.text(14),
                  ),
                ),
              for (final document in draft.documentsFor(definition.key))
                KycReviewDocument(document: document),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewMember extends StatelessWidget {
  const _ReviewMember({
    required this.member,
    required this.signature,
    required this.allocation,
  });
  final KycMember member;
  final bool signature;
  final bool allocation;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 12.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.borderStrong),
        SizedBox(height: 12.w),
        Text(
          member.name,
          style: AppTextStyles.text(14, weight: FontWeight.w600),
        ),
        _ReviewValue(
          'Role',
          member.details?.position.isNotEmpty == true
              ? member.details!.position
              : member.role.label,
        ),
        _ReviewValue('ID / Passport number', member.identityNumber),
        if (member.email.isNotEmpty) _ReviewValue('Email', member.email),
        if (signature)
          _ReviewValue('Signature', switch (member.resolutionSignature.status) {
            KycSignatureStatus.signed => 'Signed in demo',
            KycSignatureStatus.awaiting => 'Awaiting signature',
            KycSignatureStatus.notRequested => 'Not requested',
          }),
        if (allocation) ...[
          _ReviewValue(
            'Ownership',
            '${(member.shareBasisPoints / 100).toStringAsFixed(2)}%',
          ),
          if (member.details case final details?) ...[
            _ReviewValue('Share class', details.shareClass),
            _ReviewValue('Number of shares', '${details.numberOfShares}'),
            _ReviewValue('Total issued shares', '${details.issuedShares}'),
            _ReviewValue('Also a director', details.isDirector ? 'Yes' : 'No'),
          ],
        ],
        if (!signature) ...[
          _ReviewValue(
            'Identity',
            member.identityVerified ? 'Complete' : 'Required',
          ),
          _ReviewValue(
            'Proof of address',
            member.addressVerified ? 'Complete' : 'Required',
          ),
          for (final document
              in member.details?.documents.values ?? <KycDocument>[])
            KycReviewDocument(document: document),
        ],
      ],
    ),
  );
}

class _ReviewValue extends StatelessWidget {
  const _ReviewValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: AppTextStyles.text(13, color: AppColors.muted)),
        SizedBox(height: 4.w),
        Text(
          value.isEmpty ? 'Not provided' : value,
          style: AppTextStyles.text(14, weight: FontWeight.w500, height: 1.3),
        ),
      ],
    ),
  );
}

class KycReviewDocument extends StatelessWidget {
  const KycReviewDocument({super.key, required this.document});
  final KycDocument document;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 8.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const AppIcon(AppAssets.investorDocumentPdf, size: 22),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${(document.bytes / 1024).ceil()} KB · ${document.rejection == null ? 'Uploaded' : 'Action needed'}',
                style: AppTextStyles.text(12, color: AppColors.muted),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.w),
        Text(
          document.name,
          style: AppTextStyles.text(14, weight: FontWeight.w500, height: 1.3),
        ),
        if (document.rejection case final rejection?) ...[
          SizedBox(height: 6.w),
          Text(
            rejection,
            style: AppTextStyles.text(13, color: AppColors.error),
          ),
        ],
      ],
    ),
  );
}
