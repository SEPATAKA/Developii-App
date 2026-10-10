import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_member_plan.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_member_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_actions.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';

class KycMemberForm extends StatelessWidget {
  const KycMemberForm({super.key, required this.store});
  final KycMemberStore store;
  @override
  Widget build(BuildContext context) {
    final role = store.draft!.role;
    final beneficiary = role == KycMemberRole.beneficiary;
    final shareholder = role == KycMemberRole.shareholder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (beneficiary) ...[
          Text(
            'Identify the founder and every beneficiary with their share of beneficial interest.',
            style: AppTextStyles.text(16, color: AppColors.muted),
          ),
          SizedBox(height: 27.w),
        ],
        _heading('1. Identity'),
        KycFormPanel(
          spacing: beneficiary
              ? 20
              : shareholder
              ? 16
              : 22,
          padding: beneficiary
              ? EdgeInsets.fromLTRB(19.w, 20.w, 14.w, 12.w)
              : shareholder
              ? EdgeInsets.fromLTRB(18.w, 20.w, 18.w, 12.w)
              : null,
          children: [
            _row(context, [KycMemberPlan.firstName, KycMemberPlan.lastName]),
            if (shareholder)
              Column(
                children: [
                  _row(context, [
                    KycMemberPlan.identity,
                    KycMemberPlan.country,
                  ]),
                  SizedBox(height: 4.w),
                  _field(KycMemberPlan.director),
                ],
              )
            else
              _row(context, [
                KycMemberPlan.identity,
                beneficiary ? KycMemberPlan.birthDate : KycMemberPlan.country,
              ]),
            if (beneficiary)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(KycMemberPlan.relationship),
                  SizedBox(height: 8.w),
                  Text(
                    'Spouse, Child, Grandchild, Siblings, Other family, unrelated',
                    style: AppTextStyles.text(12, color: AppColors.muted),
                  ),
                ],
              ),
            if (!beneficiary && !shareholder) ...[
              _field(KycMemberPlan.email),
              _field(KycMemberPlan.position),
            ],
          ],
        ),
        if (beneficiary && store.age != null && store.age! < 18) ...[
          SizedBox(height: 22.w),
          InvestorSurface(
            color: AppColors.warningSurface,
            border: AppColors.investorPepBorder,
            radius: 14,
            padding: EdgeInsets.fromLTRB(18.w, 18.w, 18.w, 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'The beneficiary is a minor (${store.age} yrs)',
                  style: AppTextStyles.text(
                    12,
                    weight: FontWeight.w600,
                    color: AppColors.investorVerificationText,
                  ),
                ),
                SizedBox(height: 8.w),
                Text(
                  'Detected from date of birth. A parent or legal guardian must be nominated to receive distributions on their behalf until age 18.',
                  style: AppTextStyles.text(
                    12,
                    height: 17 / 12,
                    color: AppColors.investorVerificationText,
                  ),
                ),
                SizedBox(height: 14.w),
                InvestorSurface(
                  color: AppColors.white,
                  radius: 10,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _field(KycMemberPlan.guardianFields.first),
                      SizedBox(height: 22.w),
                      _row(
                        context,
                        KycMemberPlan.guardianFields.skip(1).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (shareholder) ...[
          SizedBox(height: 20.w),
          _heading('2. Shareholding'),
          KycFormPanel(
            spacing: 16,
            padding: EdgeInsets.fromLTRB(18.w, 20.w, 18.w, 33.w),
            children: [
              _field(KycMemberPlan.shareFields[0]),
              _row(context, KycMemberPlan.shareFields.sublist(1, 3)),
              _field(KycMemberPlan.shareFields[3]),
              _field(KycMemberPlan.shareFields[4]),
            ],
          ),
        ],
        SizedBox(height: 20.w),
        if (beneficiary) ...[
          _heading('2. Supporting Documents'),
          SizedBox(height: 8.w),
        ],
        for (final (index, definition) in store.documents.indexed) ...[
          if (index > 0)
            SizedBox(
              height:
                  (beneficiary
                          ? 14
                          : shareholder &&
                                store.draft!.documents[definition.key] != null
                          ? 10
                          : 16)
                      .w,
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: beneficiary ? 5.w : 0),
            child: InvestorDocumentTile(
              centered: true,
              title: definition.title,
              showTitle: beneficiary,
              titleSpacing: beneficiary ? 8 : null,
              titleLineHeight: beneficiary ? 17 / 14 : null,
              chooseLabel: beneficiary ? 'Choose a file' : definition.title,
              minimumHeight: 111,
              helperText: beneficiary
                  ? 'Ensure your ID is in PNG, JPG or PDF with a maximum file size of 5MB.'
                  : definition.key == 'shareCertificate'
                  ? 'Proof of the shareholding'
                  : shareholder
                  ? store.values['isDirector'] == 'true'
                        ? 'Required for directors and UBOs > 5%'
                        : 'Required for UBOs > 5%'
                  : 'Ensure your file is in PNG, JPG or PDF. Maximum size: 5MB.',
              document: store.draft!.documents[definition.key],
              enabled: store.editable && !store.busy,
              loading: store.uploading == definition.key,
              error: store.errors[definition.key],
              onChoose: () =>
                  KycDocumentActions.member(store).choose(context, definition),
              onDelete: () =>
                  KycDocumentActions.member(store).remove(context, definition),
            ),
          ),
        ],
      ],
    );
  }

  Widget _heading(String title) => Padding(
    padding: EdgeInsets.only(left: 5.w, bottom: 12.w),
    child: Text(title, style: AppTextStyles.text(14, weight: FontWeight.w500)),
  );
  Widget _field(KycFieldDefinition field) => KycField(
    key: ValueKey('member-${field.key}'),
    definition: field,
    value: store.values[field.key] ?? '',
    grouped: true,
    showChoiceIndicator: false,
    enabled: store.editable && !store.busy,
    error: store.errors[field.key],
    onChanged: (value) => store.edit(field.key, value),
  );
  Widget _row(BuildContext context, List<KycFieldDefinition> fields) {
    if (MediaQuery.textScalerOf(context).scale(14) > 18) {
      return Column(
        children: [
          for (final (index, field) in fields.indexed) ...[
            if (index > 0) SizedBox(height: 18.w),
            _field(field),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, field) in fields.indexed) ...[
          if (index > 0) SizedBox(width: 8.w),
          Expanded(child: _field(field)),
        ],
      ],
    );
  }
}
