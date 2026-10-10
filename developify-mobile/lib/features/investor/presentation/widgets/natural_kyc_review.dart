import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_actions.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_tax_components.dart';

class NaturalKycReview extends StatelessWidget {
  const NaturalKycReview({
    super.key,
    required this.store,
    required this.onBack,
  });
  final KycStore store;
  final VoidCallback onBack;

  String _value(String key) {
    final value = store.draft!.values[key]?.trim() ?? '';
    return value.isEmpty ? 'Not provided' : value.replaceAll('|', ', ');
  }

  String _document(String key) {
    final document = store.draft!.documents[key];
    if (document == null) return 'Not provided';
    final size = document.bytes >= 1024 * 1024
        ? '${(document.bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
        : '${(document.bytes / 1024).ceil()} KB';
    return '${document.name} · $size';
  }

  String _date(String key) {
    final date = DateTime.tryParse(store.draft!.values[key] ?? '');
    return date == null ? 'Not provided' : AppDateFormat.dayFirstDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final draft = store.draft!;
    final pep = draft.values['pep'] == KycTaxPlan.pepYes;
    final income = MonetaryAmount.tryParse(
      draft.values['annualIncome'] ?? '',
      Currency.zar,
    );
    final declarations = KycReviewPlan.naturalDeclarations.where(
      (field) => field.visible(draft.values),
    );
    return InvestorPage(
      title: 'Review & Submit',
      headerLeadingInset: 21.5,
      onBack: onBack,
      bottom: AppButton(
        label: pep ? 'Submit for verification' : 'Continue',
        loading: store.busy,
        onPressed: store.canSubmit
            ? () async {
                final success = await store.submit();
                if (context.mounted && success) {
                  showFeedback(context, 'Verification submission simulated.');
                }
              }
            : null,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 23.w, bottom: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Almost there',
              style: AppTextStyles.text(
                32,
                weight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 10.w),
            Text(
              'Check the details below before submitting for review',
              style: AppTextStyles.body,
            ),
            SizedBox(height: 24.w),
            _section('PERSONAL'),
            _ReviewDetails(
              rows: [
                ('Name', draft.identitySummary?.name ?? 'Not provided'),
                (
                  'DOB',
                  draft.identitySummary == null
                      ? 'Not provided'
                      : AppDateFormat.dayFirstDate(
                          draft.identitySummary!.birthDate,
                        ),
                ),
                (
                  'Nationality',
                  draft.identitySummary?.nationality ?? 'Not provided',
                ),
                (
                  'Residence',
                  draft.identitySummary?.residence ?? 'Not provided',
                ),
              ],
            ),
            SizedBox(height: 20.w),
            _section('DOCUMENTS'),
            _ReviewDetails(
              onTap: store.busy ? null : () => store.selectStep('identity'),
              label: 'Review identity documents',
              rows: [
                ('Passport', _document('identityFront')),
                ('Live selfie', _document('selfie')),
                ('Address Proof', _document('addressProof')),
              ],
            ),
            SizedBox(height: 20.w),
            _section('PROFILE'),
            _ReviewDetails(
              rows: [
                ('Source of Funds', _value('fundSources')),
                ('Employer', _value('employer')),
                (
                  'Annual Income',
                  income == null ? 'Not provided' : Money.amount(income),
                ),
                (
                  'Tax Residency',
                  '${_value('taxCountry')} · TIN ${_value('tin')}',
                ),
                ('PEP Status', pep ? 'Yes' : 'No'),
              ],
              onTap: store.busy ? null : () => store.selectStep('tax'),
              label: 'Review tax and PEP details',
            ),
            if (pep) ..._pepDetails(context),
            SizedBox(height: 12.w),
            if (pep) _section('PEP DECLARATIONS'),
            for (final field in declarations) ...[
              _ReviewDeclaration(
                field: field,
                selected: draft.values[field.key] == 'true',
                onTap: store.busy
                    ? null
                    : () => store.edit(
                        field.key,
                        draft.values[field.key] == 'true' ? 'false' : 'true',
                      ),
              ),
              if (store.errors[field.key] case final error?) InlineError(error),
              if (field != declarations.last) SizedBox(height: 12.w),
            ],
            if (pep) ...[
              SizedBox(height: 16.w),
              InvestorSurface(
                color: AppColors.mint,
                border: AppColors.emerald100,
                radius: 10,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
                child: Text(
                  'This is a simulated submission. No KYC checks are performed and no completion time is promised.',
                  style: AppTextStyles.text(12, color: AppColors.emerald900),
                ),
              ),
            ],
            if (store.error != null) InlineError(store.error),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: EdgeInsets.only(bottom: 12.w),
    child: Text(title, style: AppTextStyles.text(14, weight: FontWeight.w500)),
  );

  List<Widget> _pepDetails(BuildContext context) {
    final document = store.draft!.documents[KycTaxPlan.wealthDocument.key];
    final netWorth = MonetaryAmount.tryParse(
      store.draft!.values['pepNetWorth'] ?? '',
      Currency.zar,
    );
    return [
      SizedBox(height: 28.w),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'POLITICALLY EXPOSED\nPERSON (PEP)',
              style: AppTextStyles.text(14, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              'ENHANCED DUE DILIGENCE',
              textAlign: TextAlign.right,
              style: AppTextStyles.text(14, color: AppColors.warning),
            ),
          ),
        ],
      ),
      SizedBox(height: 18.w),
      const KycTaxNotice(
        pep: true,
        text:
            'You confirmed PEP status. Check the additional details below carefully before submitting this simulated verification profile. No information is sent to an external verification service.',
      ),
      SizedBox(height: 18.w),
      _ReviewDetails(
        rows: [
          ('PEP Status', 'Yes'),
          ('Relationship to PEP', _value('pepRelationship')),
          ('Type of PEP', _value('pepType')),
        ],
      ),
      SizedBox(height: 20.w),
      _section('POSITION HELD'),
      _ReviewDetails(
        rows: [
          ('Title', _value('pepPosition')),
          ('Organisation', _value('pepOrganization')),
          ('Country', _value('pepCountry')),
          ('Start Date', _date('pepStart')),
          ('Status', _value('pepStatus')),
        ],
      ),
      SizedBox(height: 24.w),
      _section('SOURCE OF WEALTH'),
      InvestorSurface(
        radius: 10,
        color: AppColors.surface,
        border: AppColors.border,
        padding: EdgeInsets.fromLTRB(12.w, 16.w, 12.w, 8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Narrative',
              style: AppTextStyles.text(14, color: AppColors.muted),
            ),
            SizedBox(height: 12.w),
            Text(_value('pepWealth'), style: AppTextStyles.text(14)),
            SizedBox(height: 22.w),
            const Divider(height: 1, color: AppColors.borderStrong),
            _ReviewDetailsRow(
              label: 'Estimated net worth',
              value: netWorth == null
                  ? 'Not provided'
                  : Money.amount(
                      netWorth,
                      decimals: false,
                      spaceAfterSymbol: true,
                    ),
            ),
          ],
        ),
      ),
      SizedBox(height: 24.w),
      _section('SUPPORTING DOCUMENTS'),
      InvestorDocumentTile(
        title: KycTaxPlan.wealthDocument.title,
        document: document,
        centered: true,
        showTitle: false,
        enabled: !store.busy,
        uploadAttempt: store.documentUploads[KycTaxPlan.wealthDocument.key],
        onRetry: store.busy
            ? null
            : () => store.retryUpload(KycTaxPlan.wealthDocument.key),
        onCancel: () => store.cancelUpload(KycTaxPlan.wealthDocument.key),
        onChoose: () => KycDocumentActions(
          store,
        ).choose(context, KycTaxPlan.wealthDocument),
        onDelete: () => KycDocumentActions(
          store,
        ).remove(context, KycTaxPlan.wealthDocument),
      ),
    ];
  }
}

class _ReviewDetails extends StatelessWidget {
  const _ReviewDetails({required this.rows, this.onTap, this.label});
  final List<(String, String)> rows;
  final VoidCallback? onTap;
  final String? label;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: label,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 4.w),
          child: Column(
            children: [
              for (final (index, row) in rows.indexed)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: index < rows.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.borderStrong),
                          )
                        : null,
                  ),
                  child: _ReviewDetailsRow(label: row.$1, value: row.$2),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReviewDetailsRow extends StatelessWidget {
  const _ReviewDetailsRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: 43.w),
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.muted,
                height: 17 / 14,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.text,
                height: 17 / 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewDeclaration extends StatelessWidget {
  const _ReviewDeclaration({
    required this.field,
    required this.selected,
    required this.onTap,
  });
  final KycFieldDefinition field;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    enabled: onTap != null,
    child: Material(
      color: field.key == 'reviewConsent'
          ? AppColors.border
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: field.key == 'reviewConsent'
              ? AppColors.borderStrong
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (field.key == 'reviewConsent' ? 78 : 66).w,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(7.w, 12.w, 16.w, 12.w),
            child: Row(
              children: [
                SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: Center(
                    child: AppIcon(
                      selected
                          ? AppAssets.investorCheckboxChecked
                          : AppAssets.investorCheckboxUnchecked,
                      size: selected ? 32 : 20,
                    ),
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: Text(
                    field.label,
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
