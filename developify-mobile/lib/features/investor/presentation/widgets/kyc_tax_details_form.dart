import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_tax.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_document_actions.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_fields.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_form_panel.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_selection_card.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_tax_components.dart';

class KycTaxDetailsForm extends StatelessWidget {
  const KycTaxDetailsForm({
    super.key,
    required this.store,
    required this.section,
  });
  final KycStore store;
  final KycTaxSection section;

  Widget _field(String key) => KycField(
    grouped: true,
    showChoiceIndicator: false,
    multilineLines: key == 'pepWealth' ? 6 : 3,
    multilineHeight: key == 'pepWealth' ? 129 : null,
    labelSpacing: key == 'pepWealth' ? 11 : 4,
    outline: key == 'pepWealth',
    toggleSubtitle: key == 'usPerson'
        ? 'US citizen, green-card holder, or US-resident alien'
        : null,
    contentPadding: key == 'pepWealth'
        ? EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w)
        : null,
    definition: KycTaxPlan.sectionFields(
      section,
    ).firstWhere((field) => field.key == key),
    value: store.draft!.values[key] ?? '',
    error: store.errors[key],
    enabled: store.editable && !store.busy,
    onChanged: (value) => store.edit(key, value),
  );
  Widget _title(String text, {double lineHeight = 22}) => Text(
    text,
    style: AppTextStyles.text(
      14,
      weight: FontWeight.w500,
      height: lineHeight / 14,
    ),
  );
  Widget _helper(String text, {Color color = AppColors.muted}) => Text(
    text,
    style: AppTextStyles.text(
      12,
      weight: FontWeight.w500,
      height: 17 / 12,
      color: color,
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: switch (section) {
      KycTaxSection.residency => _residency(context),
      KycTaxSection.pep => _pep(),
      KycTaxSection.wealth => _wealth(context),
    },
  );

  List<Widget> _residency(BuildContext context) => [
    const KycTaxNotice(
      text:
          'Under FATCA & CRS we report foreign tax residents to their home revenue authorities. Add every country where you’re tax resident; most users have one, some have two or more.',
    ),
    SizedBox(height: 28.w),
    _title('Your Residencies on file'),
    SizedBox(height: 8.w),
    InvestorSurface(
      radius: 10,
      border: AppColors.border,
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.w),
      child: Row(
        children: [
          if (store.draft!.values['taxCountry'] == 'South Africa') ...[
            const AppIcon(AppAssets.investorTaxFlag, size: 25),
            SizedBox(width: 11.5.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.draft!.values['taxCountry'] ??
                      'Primary residency not provided',
                  style: AppTextStyles.text(14, weight: FontWeight.w500),
                ),
                SizedBox(height: 5.w),
                _helper(
                  (store.draft!.values['tin'] ?? '').isNotEmpty
                      ? 'TIN ${store.draft!.values['tin']}'
                      : 'Add your primary tax details on the previous screen.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    for (final residency in store.draft!.taxResidencies) ...[
      SizedBox(height: 10.w),
      InvestorSurface(
        radius: 10,
        padding: EdgeInsets.only(left: 16.w, top: 6.w, bottom: 6.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    residency.country,
                    style: AppTextStyles.text(14, weight: FontWeight.w500),
                  ),
                  _helper('TIN ${residency.tin}'),
                ],
              ),
            ),
            TextButton(
              onPressed: store.busy || !store.editable
                  ? null
                  : () => store.beginTaxResidency(residency.id),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: store.busy || !store.editable
                  ? null
                  : () => _remove(context, residency),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    ],
    SizedBox(height: 18.w),
    _title(
      store.draft!.values['editingTaxResidency'] == null
          ? 'ADD ANOTHER RESIDENCY'
          : 'EDIT RESIDENCY',
    ),
    SizedBox(height: 8.w),
    KycFormPanel(
      spacing: 20,
      borderColor: AppColors.border,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.w),
      children: [
        _field('secondaryTaxCountry'),
        _field('secondaryReason'),
        _helper(
          'Common reasons: Citizenship, Permanent Residency, Employment, Study, Family / Spouse.',
        ),
      ],
    ),
    SizedBox(height: 24.w),
    _title('TAX IDENTIFICATION'),
    SizedBox(height: 8.w),
    KycFormPanel(
      spacing: 21,
      borderColor: AppColors.border,
      children: [
        _field('secondaryTinType'),
        _field('secondaryTinFormat'),
        _field('secondaryTin'),
      ],
    ),
    SizedBox(height: 18.w),
    _title('PERIOD'),
    SizedBox(height: 8.w),
    KycFormPanel(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
      children: [
        KycTaxFieldRow(
          children: [
            _field('secondaryResidentSince'),
            _field('secondaryStatus'),
          ],
        ),
      ],
    ),
    SizedBox(height: 18.w),
    _title('FATCA & CRS'),
    SizedBox(height: 8.w),
    KycFormPanel(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
      children: [_field('usPerson')],
    ),
    SizedBox(height: 18.w),
    _title('Self Certification'),
    SizedBox(height: 8.w),
    KycSelectionCard(
      declaration: true,
      label: KycTaxPlan.certification,
      selected: store.draft!.values['secondaryCertification'] == 'true',
      onTap: store.busy || !store.editable
          ? null
          : () => store.edit(
              'secondaryCertification',
              store.draft!.values['secondaryCertification'] == 'true'
                  ? 'false'
                  : 'true',
            ),
    ),
    if (store.errors['secondaryCertification'] case final error?)
      InlineError(error),
  ];

  List<Widget> _pep() => [
    _notice,
    SizedBox(height: 27.w),
    _title('1. YOUR RELATIONSHIP TO THE PEP'),
    SizedBox(height: 8.w),
    for (final (index, option) in const [
      ('Self', 'I am the PEP myself', 'You hold the prominent public function'),
      (
        'Family member',
        'Family member of a PEP',
        'Spouse, parent, child, siblings, in-law',
      ),
      (
        'Close associate',
        'Close associate',
        'Business partner, lawyer, advisor, agent.',
      ),
    ].indexed) ...[
      if (index > 0) SizedBox(height: 14.w),
      KycTaxChoice(
        label: option.$2,
        subtitle: option.$3,
        radio: true,
        selected: store.draft!.values['pepRelationship'] == option.$1,
        onTap: store.busy || !store.editable
            ? null
            : () => store.edit('pepRelationship', option.$1),
      ),
    ],
    if (store.errors['pepRelationship'] case final error?) InlineError(error),
    SizedBox(height: 18.w),
    _title('2. TYPE OF PEP'),
    SizedBox(height: 8.w),
    Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: KycTaxFieldRow(
        gap: 15,
        children: [
          for (final option in const [
            ('Domestic PEP', 'Domestic', 'South African'),
            ('Foreign PEP', 'Foreign', 'Outside SA'),
            (
              'International organisation',
              'International',
              'UN, IMF, World Bank',
            ),
          ])
            KycTaxChoice(
              label: option.$2,
              subtitle: option.$3,
              centered: true,
              selected: store.draft!.values['pepType'] == option.$1,
              onTap: store.busy || !store.editable
                  ? null
                  : () => store.edit('pepType', option.$1),
            ),
        ],
      ),
    ),
    if (store.errors['pepType'] case final error?) InlineError(error),
    SizedBox(height: 16.w),
    _title('3. POSITION HELD', lineHeight: 17),
    SizedBox(height: 8.w),
    KycFormPanel(
      spacing: 0,
      borderColor: AppColors.border,
      padding: EdgeInsets.fromLTRB(18.w, 22.w, 18.w, 21.w),
      children: [
        _field('pepCountry'),
        SizedBox(height: 21.w),
        _field('pepPosition'),
        SizedBox(height: 16.w),
        _helper(
          'Includes: Head of State, Minister, MP, Judge, Senior Military Officer, Central Bank Officer, Senior Diplomat',
        ),
        SizedBox(height: 21.w),
        _field('pepOrganization'),
        SizedBox(height: 13.w),
        KycTaxFieldRow(children: [_field('pepStart'), _field('pepStatus')]),
        SizedBox(height: 14.w),
        _helper(
          'If former: PEP status applies for 12 months after leaving the position',
        ),
      ],
    ),
  ];

  List<Widget> _wealth(BuildContext context) => [
    _notice,
    SizedBox(height: 28.w),
    Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: _title('4. PEP’S IDENTITY (IF RELATED)', lineHeight: 17),
    ),
    SizedBox(height: 10.w),
    KycFormPanel(
      spacing: 0,
      borderColor: AppColors.border,
      padding: EdgeInsets.fromLTRB(18.w, 22.w, 15.w, 22.w),
      children: [
        Padding(
          padding: EdgeInsets.only(left: 1.w, right: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field('pepName'),
              SizedBox(height: 6.w),
              _helper(
                'If you’re the PEP, please enter your name',
                color: AppColors.investorPepHint,
              ),
            ],
          ),
        ),
        SizedBox(height: 23.w),
        KycTaxFieldRow(
          gap: 8,
          children: [_field('pepIdentityRelationship'), _field('pepIdentity')],
        ),
        SizedBox(height: 15.w),
        _helper('Your PEP’s ID helps speed up KYC processes'),
      ],
    ),
    SizedBox(height: 18.w),
    Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: _title('5. Source of wealth', lineHeight: 17),
    ),
    SizedBox(height: 10.w),
    KycFormPanel(
      spacing: 16,
      borderColor: AppColors.border,
      padding: EdgeInsets.fromLTRB(18.w, 16.w, 20.w, 24.w),
      children: [_field('pepWealth'), _field('pepNetWorth')],
    ),
    SizedBox(height: 21.w),
    InvestorDocumentTile(
      centered: true,
      title: KycTaxPlan.wealthDocument.title,
      helperText:
          'Bank statements, tax returns, declaration of assets.\nwith a maximum file size of 5MB.',
      document: store.draft!.documents[KycTaxPlan.wealthDocument.key],
      uploadAttempt: store.documentUploads[KycTaxPlan.wealthDocument.key],
      onRetry: store.busy
          ? null
          : () => store.retryUpload(KycTaxPlan.wealthDocument.key),
      onCancel: () => store.cancelUpload(KycTaxPlan.wealthDocument.key),
      loading: store.uploading == KycTaxPlan.wealthDocument.key,
      enabled: !store.busy && store.editable,
      error: store.errors[KycTaxPlan.wealthDocument.key],
      onChoose: () =>
          KycDocumentActions(store).choose(context, KycTaxPlan.wealthDocument),
      onDelete: () =>
          KycDocumentActions(store).remove(context, KycTaxPlan.wealthDocument),
    ),
    SizedBox(height: 15.w),
    KycTaxDeclarations(store: store),
  ];

  Widget get _notice => const KycTaxNotice(
    pep: true,
    text:
        'Because you’re a PEP (or closely related to one), we’re required\nto run Enhanced Due Diligence. Tell us a bit more - this is treated with strict confidentiality',
  );

  Future<void> _remove(BuildContext context, KycTaxResidency residency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove tax residency?'),
        content: Text(
          '${residency.country} will be removed from this application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) {
      store.deleteTaxResidency(residency.id);
    }
  }
}
