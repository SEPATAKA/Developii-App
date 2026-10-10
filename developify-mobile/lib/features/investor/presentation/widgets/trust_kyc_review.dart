import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/models/monetary_amount.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/utils/date_format.dart';
import 'package:developify_mobile/core/utils/money.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/domain/investor_account.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_models.dart';
import 'package:developify_mobile/features/investor/domain/kyc/kyc_review.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/kyc_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_allocation_form.dart';

class TrustKycReview extends StatelessWidget {
  const TrustKycReview({
    super.key,
    required this.store,
    required this.onBack,
    required this.onExit,
  });
  final KycStore store;
  final VoidCallback onBack;
  final VoidCallback onExit;

  String _value(String key) => store.draft!.values[key]?.isNotEmpty == true
      ? store.draft!.values[key]!
      : 'Not provided';
  String _date(String key) {
    final date = DateTime.tryParse(store.draft!.values[key] ?? '');
    return date == null
        ? 'Not provided'
        : AppDateFormat.slashDate(date).replaceAll(' / ', ' ');
  }

  String _amount(String key, {bool compact = false}) {
    final amount = MonetaryAmount.tryParse(
      store.draft!.values[key] ?? '',
      Currency.zar,
    );
    return amount == null
        ? 'Not provided'
        : compact
        ? Money.compact(amount)
        : Money.amount(
            amount,
            decimals: amount.minorUnits % 100 != 0,
            spaceAfterSymbol: true,
          );
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final draft = store.draft!;
      final trustees = draft.members
          .where((member) => member.role == KycMemberRole.trustee)
          .toList();
      final beneficiaries = draft.members
          .where((member) => member.role == KycMemberRole.beneficiary)
          .toList();
      final signed = trustees.where((member) => member.signed).length;
      final editable = store.editable && !store.busy;
      final pending = draft.status == VerificationStatus.pending;
      final approved = draft.status == VerificationStatus.verified;
      return Scaffold(
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(12.w, 12.w, 12.w, 18.w),
          child: pending || approved
              ? AppButton(
                  label: approved ? 'Explore Projects' : 'Back to Home',
                  onPressed: () => context.goNamed(
                    approved ? InvestorRoutes.explore : InvestorRoutes.home,
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save & exit',
                        style: AppButtonStyle.secondary,
                        onPressed: store.busy ? null : onExit,
                      ),
                    ),
                    SizedBox(width: 18.w),
                    Expanded(
                      child: AppButton(
                        label: 'Submit',
                        loading: store.busy,
                        onPressed: store.canSubmit
                            ? () => _submit(context)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.darkTeal,
                    image: DecorationImage(
                      image: AssetImage(AppAssets.investorKycMesh),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppPageAppBar(
                          title: 'Final Review',
                          appearance: AppHeaderAppearance.dark,
                          onBack: onBack,
                          backAsset: AppAssets.investorReviewBack,
                          backAssetSize: 33,
                          leadingInset: 20,
                          topInset: 10,
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 10.w, 12.w, 36.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 6.w,
                                children: [
                                  Text(
                                    '2. Trust',
                                    style: AppTextStyles.text(
                                      16,
                                      color: AppColors.mintBorder,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _value('trustName'),
                                    style: AppTextStyles.text(
                                      16,
                                      color: AppColors.mintBorder,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.w),
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: 57.6.sp),
                                child: Text(
                                  approved
                                      ? 'Verification complete'
                                      : pending
                                      ? 'Your application is in review'
                                      : 'Almost there - review\neverything',
                                  style: AppTextStyles.text(
                                    24,
                                    weight: FontWeight.w600,
                                    color: AppColors.mint,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.w),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${store.completed} of ${store.steps.length} requirements complete',
                                      style: AppTextStyles.text(
                                        14,
                                        color: AppColors.mintBorder,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${(store.progress * 100).round()}%',
                                    style: AppTextStyles.text(
                                      14,
                                      color: AppColors.mintBorder,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.w),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20.r),
                                child: LinearProgressIndicator(
                                  value: store.progress,
                                  minHeight: 6.w,
                                  backgroundColor: AppColors.mintBorder,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(12.w, 17.w, 12.w, 60.w),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InvestorSurface(
                      color:
                          draft.status == VerificationStatus.correctionRequired
                          ? AppColors.warningSurface
                          : AppColors.emerald50,
                      border:
                          draft.status == VerificationStatus.correctionRequired
                          ? AppColors.investorPepBorder
                          : AppColors.mintBorder,
                      radius: 14,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.w,
                      ),
                      child: Text(
                        draft.status == VerificationStatus.correctionRequired
                            ? draft.correction ??
                                  'Review the requested corrections before submitting again.'
                            : pending
                            ? 'Submission is simulated. Pending trustee checks and signatures must be resolved before approval.'
                            : approved
                            ? 'This trust’s verification is complete in the demo.'
                            : 'Tap any section below to edit. Submit for a simulated review and track pending requirements from your application status.',
                        style: AppTextStyles.text(
                          13,
                          height: 14 / 13,
                          color:
                              draft.status ==
                                  VerificationStatus.correctionRequired
                              ? AppColors.warning
                              : AppColors.mintText,
                        ),
                      ),
                    ),
                    SizedBox(height: 18.w),
                    InvestorSurface(
                      color: AppColors.white,
                      border: AppColors.border,
                      radius: 10,
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _value('trustName'),
                            style: AppTextStyles.text(
                              16,
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8.w),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 6.w,
                            children: [
                              Text(
                                _value('trustRegistration'),
                                style: AppTextStyles.text(
                                  14,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                _value(
                                  'masterOffice',
                                ).replaceFirst(RegExp(r' \([A-Z]+\)$'), ''),
                                style: AppTextStyles.text(
                                  14,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                'Registered ${_date('trustRegistered')}',
                                style: AppTextStyles.text(
                                  14,
                                  color: AppColors.description,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 14.w),
                          Row(
                            children: [
                              for (final (index, item) in [
                                ('Trustees', '${trustees.length}'),
                                ('Beneficiaries', '${beneficiaries.length}'),
                                (
                                  'Capital',
                                  _amount('trustCapital', compact: true),
                                ),
                              ].indexed) ...[
                                if (index > 0)
                                  Container(
                                    width: 1,
                                    height: 42.w,
                                    color: AppColors.borderStrong,
                                  ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        item.$1,
                                        style: AppTextStyles.text(
                                          14,
                                          color: AppColors.iconMuted,
                                        ),
                                      ),
                                      SizedBox(height: 6.w),
                                      Text(
                                        item.$2,
                                        style: AppTextStyles.text(
                                          16,
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _section(
                      '1. Trust Deed',
                      'deed',
                      _document(
                        'trustDeed',
                        'Uploaded in demo',
                        showSize: true,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.w,
                      ),
                    ),
                    _section(
                      '2. Letter of Authority',
                      'authority',
                      _document(
                        'lettersAuthority',
                        'Issued ${_date('authorityIssued')} · ${_value('trusteeCount')} trustees named',
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.w,
                      ),
                    ),
                    _section(
                      '3. Trustee Resolution',
                      'resolution',
                      Column(
                        children: [
                          _row('Date', _date('resolutionDate')),
                          _row(
                            'Investment cap',
                            '${_amount('investmentCap')} / year',
                          ),
                          _row('Authorised signatory', _value('signatory')),
                          _divider(),
                          _inline(
                            'Signatures',
                            '$signed of ${trustees.length} collected',
                          ),
                          for (final member in trustees)
                            Padding(
                              padding: EdgeInsets.only(top: 12.w),
                              child: Row(
                                children: [
                                  if (member.signed)
                                    const _ReviewCheck(selected: true)
                                  else
                                    SizedBox(width: 32.w, height: 17.w),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      '${member.name} · ${member.details?.position.isNotEmpty == true ? member.details!.position : 'Trustee'}',
                                      style: AppTextStyles.text(
                                        14,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    member.signed
                                        ? member.resolutionSignature.signedAt ==
                                                  null
                                              ? 'Signed'
                                              : AppDateFormat.dayMonth(
                                                  member
                                                      .resolutionSignature
                                                      .signedAt!,
                                                )
                                        : 'Pending',
                                    style: AppTextStyles.text(
                                      12,
                                      color: member.signed
                                          ? AppColors.mintText
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(16.w, 12.w, 16.w, 23.w),
                    ),
                    _section(
                      '4. Trustees ID & Address',
                      'trustees',
                      Column(
                        children: [
                          for (final (index, member) in trustees.indexed) ...[
                            if (index > 0) SizedBox(height: 16.w),
                            _trustee(member),
                          ],
                          if (trustees.isEmpty)
                            _row('Trustees', 'Not provided'),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 19.w,
                      ),
                    ),
                    _section(
                      '5. Founder & Beneficiaries',
                      'beneficiaries',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Founder',
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                          SizedBox(height: 10.w),
                          _inline(
                            _value('founderName'),
                            'ID ${_value('founderIdentity')}',
                            strong: true,
                            trailing: _value('founderCountry') == 'South Africa'
                                ? 'ZA'
                                : _value('founderCountry'),
                          ),
                          _divider(),
                          _inline(
                            'Beneficiaries',
                            'Interest ${kycShareLabel(beneficiaries.fold(0, (sum, member) => sum + member.shareBasisPoints))}',
                            strong: true,
                          ),
                          SizedBox(height: 8.w),
                          for (final member in beneficiaries)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.w),
                              child: _inline(
                                member.name,
                                member.relationship,
                                strong: true,
                                trailing: kycShareLabel(
                                  member.shareBasisPoints,
                                ),
                                trailingColor: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _section(
                      '6. Source of Trust Funds',
                      'funds',
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.w,
                            children: [
                              for (final source
                                  in (draft.values['fundSources'] ?? '')
                                      .split('|')
                                      .where((source) => source.isNotEmpty))
                                _ReviewBadge(switch (source) {
                                  'Property sale proceeds' => 'Property Sale',
                                  'Investment portfolio rollover' =>
                                    'Portfolio rollover',
                                  _ => source,
                                }, tone: _ReviewTone.mint),
                            ],
                          ),
                          SizedBox(height: 8.w),
                          _row(
                            'Approximate trust capital',
                            _amount('trustCapital'),
                          ),
                          _row(
                            'Planned annual investment',
                            _amount('annualInvestment'),
                          ),
                          _row(
                            'Evidence upload',
                            draft.documentsFor('fundsEvidence').isEmpty
                                ? 'Not provided'
                                : draft
                                      .documentsFor('fundsEvidence')
                                      .map((document) => document.name)
                                      .join('\n'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 9.w),
                    Text(
                      'Final Declaration',
                      style: AppTextStyles.text(14, weight: FontWeight.w500),
                    ),
                    SizedBox(height: 14.w),
                    for (final field in KycReviewPlan.trustDeclarations) ...[
                      Semantics(
                        checked: draft.values[field.key] == 'true',
                        label: field.label,
                        child: InkWell(
                          key: ValueKey(field.key),
                          borderRadius: BorderRadius.circular(10.r),
                          onTap: editable
                              ? () => store.edit(
                                  field.key,
                                  draft.values[field.key] == 'true'
                                      ? 'false'
                                      : 'true',
                                )
                              : null,
                          child: InvestorSurface(
                            color: AppColors.investorCard,
                            border: AppColors.border,
                            radius: 10,
                            padding: EdgeInsets.fromLTRB(6.w, 14.w, 14.w, 14.w),
                            child: Row(
                              children: [
                                _ReviewCheck(
                                  selected: draft.values[field.key] == 'true',
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    field.label,
                                    style: AppTextStyles.text(14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.w),
                    ],
                    InvestorSurface(
                      color: AppColors.warningSurface,
                      border: AppColors.investorPepBorder,
                      radius: 14,
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 13.w,
                      ),
                      child: Text(
                        'Pending items won’t block submission. Verification can’t complete until they’re resolved. Reminders are simulated in this demo.',
                        style: AppTextStyles.text(
                          12,
                          height: 17 / 12,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    if (store.error != null) InlineError(store.error),
                    if (pending) ...[
                      SizedBox(height: 16.w),
                      Text(
                        'Mock verification controls',
                        style: AppTextStyles.text(12, color: AppColors.muted),
                      ),
                      Wrap(
                        spacing: 12.w,
                        children: [
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () => store.simulateReview(true),
                            child: const Text('Simulate approval'),
                          ),
                          TextButton(
                            onPressed: store.busy
                                ? null
                                : () => store.simulateReview(false),
                            child: const Text('Request correction'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _section(
    String title,
    String step,
    Widget child, {
    EdgeInsetsGeometry? padding,
  }) => Padding(
    padding: EdgeInsets.only(top: 18.w),
    child: Semantics(
      button: store.editable,
      label: 'Edit $title',
      child: InkWell(
        onTap: store.editable && !store.busy
            ? () => store.selectStep(step)
            : null,
        borderRadius: BorderRadius.circular(10.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTextStyles.text(14, weight: FontWeight.w500)),
            SizedBox(
              height:
                  (step == 'trustees'
                          ? 10
                          : step == 'beneficiaries'
                          ? 22
                          : step == 'funds'
                          ? 23
                          : 18)
                      .w,
            ),
            InvestorSurface(
              color: AppColors.investorCard,
              border: AppColors.border,
              radius: 10,
              padding:
                  padding ??
                  (step == 'funds'
                      ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.w)
                      : EdgeInsets.all(16.w)),
              child: child,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _document(String key, String detail, {bool showSize = false}) {
    final document = store.draft!.documents[key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                document?.name ?? 'Document required',
                style: AppTextStyles.text(14, weight: FontWeight.w600),
              ),
            ),
            SizedBox(width: 12.w),
            _ReviewBadge(
              document == null
                  ? 'Required'
                  : document.rejection != null
                  ? 'Action needed'
                  : 'Uploaded',
              tone: document != null && document.rejection == null
                  ? _ReviewTone.success
                  : _ReviewTone.error,
            ),
          ],
        ),
        SizedBox(height: 4.w),
        Text(
          document == null
              ? 'Not provided'
              : showSize
              ? '$detail · ${(document.bytes / 1024 / 1024).toStringAsFixed(1)}MB'
              : detail,
          style: AppTextStyles.text(14, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _trustee(KycMember member) {
    final complete = member.identityVerified && member.addressVerified;
    return Row(
      children: [
        CircleAvatar(
          radius: 20.w,
          backgroundColor: AppColors.mint,
          child: Text(
            '${member.firstName.characters.firstOrNull ?? ''}${member.lastName.characters.firstOrNull ?? ''}'
                .toUpperCase(),
            style: AppTextStyles.text(
              16,
              weight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.name,
                style: AppTextStyles.text(14, weight: FontWeight.w600),
              ),
              SizedBox(height: 4.w),
              Text(
                complete
                    ? 'ID & Address complete'
                    : member.identityVerified
                    ? 'Address missing'
                    : 'Awaiting upload',
                style: AppTextStyles.text(14, color: AppColors.muted),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _ReviewBadge(
          complete
              ? 'Uploaded'
              : member.identityVerified
              ? 'Action needed'
              : 'Pending',
          tone: complete
              ? _ReviewTone.success
              : member.identityVerified
              ? _ReviewTone.error
              : _ReviewTone.pending,
        ),
      ],
    );
  }

  Widget _inline(
    String label,
    String detail, {
    bool strong = false,
    String? trailing,
    Color? trailingColor,
  }) => LayoutBuilder(
    builder: (context, constraints) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: strong
                      ? AppTextStyles.text(14, weight: FontWeight.w600)
                      : null,
                ),
                TextSpan(text: '  ·  $detail'),
              ],
            ),
            style: AppTextStyles.text(14, color: AppColors.muted),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: 12.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth * .35),
            child: Text(
              trailing,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: trailingColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.w),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.text(14, color: AppColors.muted),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTextStyles.text(
              14,
              weight: FontWeight.w600,
              color: valueColor ?? AppColors.text,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _divider() => Padding(
    padding: EdgeInsets.symmetric(vertical: 12.w),
    child: const Divider(height: 1, color: AppColors.borderStrong),
  );

  Future<void> _submit(BuildContext context) async {
    final success = await store.submit();
    if (!context.mounted || !success) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.modalScrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.r)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 19.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 74.w,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 32.w,
                        right: 4.w,
                        child: InvestorIconButton(
                          asset: AppAssets.recoverySuccessClose,
                          size: 33,
                          label: 'Close',
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox.square(
                  dimension: 96.w,
                  child: const Center(
                    child: AppIcon(AppAssets.investorSuccess, size: 88),
                  ),
                ),
                SizedBox(height: 16.w),
                Text(
                  'Submitted for review',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(28, weight: FontWeight.w700),
                ),
                SizedBox(height: 6.w),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    'Your trust application has been submitted in the demo. You can view its status and any pending requirements.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.text(16, color: AppColors.muted),
                  ),
                ),
                SizedBox(height: 37.w),
                AppButton(
                  label: 'Back to Home',
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.goNamed(InvestorRoutes.home);
                  },
                ),
                SizedBox(height: 16.w),
                AppButton(
                  label: 'View Status',
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ReviewTone { success, error, pending, mint }

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge(this.label, {required this.tone});
  final String label;
  final _ReviewTone tone;
  @override
  Widget build(BuildContext context) {
    final (surface, text, border) = switch (tone) {
      _ReviewTone.success => (
        AppColors.successSurface,
        AppColors.successBadgeText,
        null,
      ),
      _ReviewTone.error => (
        AppColors.actionRequiredSurface,
        AppColors.error,
        AppColors.actionRequiredBorder,
      ),
      _ReviewTone.pending => (
        AppColors.pendingBadgeSurface,
        AppColors.warning,
        AppColors.pendingBadgeBorder,
      ),
      _ReviewTone.mint => (
        AppColors.mintBorder,
        AppColors.investorCommercial,
        AppColors.mintBadgeBorder,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (border == null ? 8 : 7).w,
        vertical: (border == null ? 4 : 3).w,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14.r),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(
        label,
        style: AppTextStyles.text(12, height: 16 / 12, color: text),
      ),
    );
  }
}

class _ReviewCheck extends StatelessWidget {
  const _ReviewCheck({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 32.w,
    child: Center(
      child: AppIcon(
        selected
            ? AppAssets.investorCheckboxChecked
            : AppAssets.investorCheckboxUnchecked,
        size: selected ? 32 : 20,
      ),
    ),
  );
}
