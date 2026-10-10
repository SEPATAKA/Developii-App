import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/natural_tax_form.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_identity_documents.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_identity_photo.dart';

class NaturalKycForm extends StatelessWidget {
  const NaturalKycForm({
    super.key,
    required this.store,
    required this.onUpload,
    required this.onDelete,
  });
  final KycStore store;
  final ValueChanged<KycDocumentDefinition> onUpload;
  final ValueChanged<KycDocumentDefinition> onDelete;

  @override
  Widget build(BuildContext context) {
    final step = store.step!;
    return Padding(
      padding: EdgeInsets.only(
        top:
            (store.selectedStep == 'tax'
                    ? 17
                    : store.selectedStep == 'funds'
                    ? 23
                    : 27)
                .w,
        bottom: 24.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...switch (step.id) {
            'identity' => _identity(),
            'address' => _address(),
            'bank' => _bank(),
            'funds' => _funds(),
            'tax' => [NaturalTaxForm(store: store)],
            _ => [
              _heading(step.title),
              SizedBox(height: 20.w),
              for (final document in step.documents) _document(document),
            ],
          },
          if (store.error != null &&
              !store.documentUploads.values.any(
                (attempt) => attempt.error == store.error,
              ))
            InlineError(store.error),
        ],
      ),
    );
  }

  Widget _heading(String title) => Text(
    title,
    style: AppTextStyles.text(
      32,
      weight: FontWeight.w700,
      color: AppColors.black,
    ),
  );
  Widget _description(String text) =>
      Text(text, style: AppTextStyles.text(16, color: AppColors.muted));
  Widget _field(String key) {
    final field = store.step!.fields.firstWhere((field) => field.key == key);
    return KycField(
      grouped:
          store.selectedStep == 'funds' ||
          store.selectedStep == 'tax' ||
          (store.selectedStep == 'bank' &&
              (key != 'bank' || (store.draft!.values['bank'] ?? '').isEmpty)),
      showChoiceIndicator: store.selectedStep != 'bank',
      definition: field,
      value: store.draft!.values[key] ?? '',
      error: store.errors[key],
      enabled: !store.busy,
      onChanged: (value) => store.edit(key, value),
    );
  }

  Widget _document(KycDocumentDefinition document) => InvestorDocumentTile(
    centered: true,
    title: document.title,
    document: store.draft!.documents[document.key],
    uploadAttempt: store.documentUploads[document.key],
    onRetry: store.busy ? null : () => store.retryUpload(document.key),
    onCancel: () => store.cancelUpload(document.key),
    loading: store.uploading == document.key,
    enabled: !store.busy,
    error: store.errors[document.key],
    onChoose: () => onUpload(document),
    onDelete: () => onDelete(document),
  );

  List<Widget> _identity() {
    if ((store.draft!.values['idType'] ?? '').isEmpty) {
      return [
        KycIdentityDocuments(
          chooseId: true,
          onSelected: (step) => step == 'identity'
              ? store.edit('idType', 'International passport')
              : store.selectStep(step),
        ),
      ];
    }
    return [
      _heading('Upload your identity'),
      SizedBox(height: 7.w),
      _description(
        'Upload a clear photo of your government-issued ID to secure your account and access full features.',
      ),
      SizedBox(height: 19.w),
      _identityDocument(store.step!.documents[0]),
      SizedBox(height: _hasPhoto(store.step!.documents[0]) ? 20.w : 25.w),
      _identityDocument(store.step!.documents[1]),
    ];
  }

  bool _hasPhoto(KycDocumentDefinition document) =>
      store.draft!.documents[document.key]?.mimeType.startsWith('image/') ==
          true &&
      !store.documentUploads.containsKey(document.key);

  Widget _identityDocument(KycDocumentDefinition document) =>
      _hasPhoto(document)
      ? KycIdentityPhoto(
          title: document.title,
          back: document.key == 'identityBack',
          checking: store.busy && store.uploading == null,
          onRetake: store.busy ? null : () => onUpload(document),
        )
      : _document(document);

  List<Widget> _address() => [
    _heading('Address Verification'),
    SizedBox(height: 7.w),
    Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text:
                'Upload a document showing your name and home address, issued in the last ',
          ),
          TextSpan(
            text: '3 months',
            style: AppTextStyles.text(
              16,
              weight: FontWeight.w700,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
      style: AppTextStyles.text(16, color: AppColors.muted),
    ),
    SizedBox(height: 18.w),
    _acceptedDocuments(),
    SizedBox(height: 13.w),
    _document(store.step!.documents.single),
  ];

  Widget _acceptedDocuments() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Accepted Documents',
        style: AppTextStyles.text(
          14,
          weight: FontWeight.w500,
          color: AppColors.text,
          height: 22 / 14,
        ),
      ),
      SizedBox(height: 10.w),
      InvestorSurface(
        radius: 10,
        border: AppColors.border,
        padding: EdgeInsets.fromLTRB(
          13.w,
          (store.selectedStep == 'bank' ? 27 : 15).w,
          13.w,
          (store.selectedStep == 'bank' ? 14 : 15).w,
        ),
        child: Column(
          children: [
            for (final (index, document)
                in store.step!.acceptedDocuments.indexed) ...[
              if (index != 0) SizedBox(height: 10.w),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(AppAssets.investorDocumentAccepted, size: 24),
                  SizedBox(width: (store.selectedStep == 'bank' ? 11 : 19).w),
                  Expanded(
                    child: Text(
                      document,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ],
  );

  List<Widget> _bank() => [
    _description(store.step!.description),
    SizedBox(height: ((store.draft!.values['bank'] ?? '').isEmpty ? 40 : 30).w),
    _acceptedDocuments(),
    SizedBox(
      height:
          ((store.draft!.values['bank'] ?? '').isEmpty
                  ? 27
                  : store.draft!.documents.containsKey('bankProof')
                  ? 33
                  : 23)
              .w,
    ),
    Text(
      'Enter Details',
      style: AppTextStyles.text(
        14,
        weight: FontWeight.w500,
        color: AppColors.text,
        height: 22 / 14,
      ),
    ),
    SizedBox(height: 8.w),
    InvestorSurface(
      radius: 10,
      border: AppColors.borderStrong,
      padding: EdgeInsets.fromLTRB(18.w, 20.w, 18.w, 26.w),
      child: Column(
        children: [
          _field('bank'),
          SizedBox(height: 20.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('accountNumber')),
              SizedBox(width: 19.w),
              Expanded(child: _field('branchCode')),
            ],
          ),
          SizedBox(height: 14.w),
          _field('accountName'),
          SizedBox(height: 16.w),
          _field('accountType'),
        ],
      ),
    ),
    SizedBox(height: 24.w),
    _document(store.step!.documents.single),
    if (store.draft!.documents.containsKey('bankProof') ||
        store.documentUploads.containsKey('bankProof')) ...[
      SizedBox(
        height: (store.draft!.documents.containsKey('bankProof') ? 32 : 22).w,
      ),
      InvestorSurface(
        color: AppColors.warningSurface,
        border: AppColors.kycWarningBorder,
        radius: 14,
        padding: EdgeInsets.fromLTRB(19.w, 13.w, 12.w, 13.w),
        child: Text(
          'It is essential that the account name you choose matches your legal name as it appears on your identification document without any deviations. This ensures consistency and avoids any potential issues during verification processes.',
          style: AppTextStyles.text(
            12,
            weight: FontWeight.w500,
            color: AppColors.investorPepText,
            height: 17 / 12,
          ),
        ),
      ),
    ],
  ];

  List<Widget> _funds() => [
    _heading('Source of funds'),
    SizedBox(height: 7.w),
    _description(store.step!.description),
    SizedBox(height: 23.w),
    Text(
      store.step!.section,
      style: AppTextStyles.text(14, weight: FontWeight.w500),
    ),
    SizedBox(height: 12.w),
    _field('fundSources'),
    SizedBox(height: 24.w),
    Text('EMPLOYMENT', style: AppTextStyles.label),
    SizedBox(height: 12.w),
    KycFormPanel(
      spacing: 21,
      borderColor: AppColors.border,
      padding: EdgeInsets.fromLTRB(18.w, 20.w, 18.w, 26.w),
      children: [
        for (final key in ['occupation', 'employer', 'annualIncome'])
          _field(key),
      ],
    ),
    SizedBox(height: 24.w),
    Text('EXPECTED ACTIVITY', style: AppTextStyles.label),
    SizedBox(height: 12.w),
    KycFormPanel(
      borderColor: AppColors.border,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.w),
      children: [_field('expectedActivity')],
    ),
  ];
}
