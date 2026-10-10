import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/domain/investor_account_context.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_entity_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/kyc_identity_documents.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class KycIntroductionScreen extends StatelessWidget {
  const KycIntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'KYC Verification',
    titleCenterOffset: 4.5,
    headerLeadingInset: 21.5,
    headerTopInset: 17,
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'Start Verification',
          onPressed: () => context.pushNamed(InvestorRoutes.kycEntity),
        ),
        SizedBox(height: 19.w),
        AppButton(
          label: 'I’ll do this later',
          style: AppButtonStyle.secondary,
          onPressed: () => context.goNamed(InvestorRoutes.home),
        ),
      ],
    ),
    child: ListView(
      padding: EdgeInsets.only(top: 27.w, bottom: 24.w),
      children: [
        Text(
          'Verify once, Invest Forever',
          style: AppTextStyles.text(
            32,
            weight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 7.w),
        Text(
          'Prepare your investor documents. Verification is simulated in this session.',
          style: AppTextStyles.text(16, color: AppColors.muted),
        ),
        SizedBox(height: 46.w),
        for (final label in const [
          'Government ID or Passport',
          'Live Selfie / Biometrics',
          'Recent proof of address',
          'Source of funds & tax info',
        ])
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 0, 0, 20.w),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.text(
                      16,
                      weight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class KycEntityScreen extends StatefulWidget {
  const KycEntityScreen({super.key, required this.accountContext});
  final InvestorAccountContext accountContext;
  @override
  State<KycEntityScreen> createState() => _KycEntityScreenState();
}

class _KycEntityScreenState extends State<KycEntityScreen> {
  late EntityType? selected;
  late bool nonResident;

  @override
  void initState() {
    super.initState();
    nonResident = widget.accountContext.nonResident;
    selected = nonResident ? null : widget.accountContext.entity;
  }

  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'Who is investing?',
    headerLeadingInset: 21.5,
    headerTopInset: 17,
    bottom: AppButton(
      label: 'Continue',
      onPressed: selected == null && !nonResident
          ? null
          : () {
              final entity = selected ?? EntityType.individual;
              widget.accountContext.selectEntity(
                entity,
                nonResident: nonResident,
              );
              if (entity == EntityType.individual) {
                context.pushNamed(InvestorRoutes.kycDocuments);
              } else {
                context.pushNamed(
                  InvestorRoutes.kyc,
                  pathParameters: {
                    'entity': entity.name,
                    'step': 'overview',
                  },
                );
              }
            },
    ),
    child: ListView(
      padding: EdgeInsets.only(top: 27.w, bottom: 24.w),
      children: [
        Text(
          'Select Investment',
          style: AppTextStyles.text(
            32,
            weight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 7.w),
        Text(
          'Choose the type of investor. Each card shows who it’s for and the documents to prepare.',
          style: AppTextStyles.text(16, color: AppColors.muted),
        ),
        SizedBox(height: 28.w),
        for (final entry in const [
          (
            EntityType.individual,
            'Natural Person',
            'Most common',
            '7 requirements · personal funds',
            'For investors using personal funds. Verification is simulated in this session.',
            AppColors.primary,
            AppColors.mintHighlight,
            114.0,
          ),
          (
            EntityType.trust,
            'Trust',
            'Custom',
            '6 requirements · trust funds',
            'Trust Deed + Letters of Authority + trustee KYC.',
            AppColors.violetBright,
            AppColors.violetBrightAlpha13,
            99.0,
          ),
          (
            EntityType.company,
            'Company / SPV',
            'Corporate',
            '6 requirements · company funds',
            'CIPC, MOI, Share register and more',
            AppColors.blueStrong,
            AppColors.bluePale,
            98.0,
          ),
          (
            EntityType.stokvel,
            'Stokvel / Group',
            'Pooled',
            '6 requirements · pooled funds',
            'Constitution, resolutions and office bearer KYC.',
            AppColors.navy,
            AppColors.navyAlpha18,
            98.0,
          ),
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 15.w),
            child: InvestorEntityChoice(
              fullPage: true,
              title: entry.$2,
              badge: entry.$3,
              subtitle: entry.$4,
              description: entry.$5,
              badgeColor: entry.$6,
              badgeBackground: entry.$7,
              minHeight: entry.$8,
              selected: selected == entry.$1,
              onTap: () => setState(() {
                selected = entry.$1;
                nonResident = false;
              }),
            ),
          ),
        InvestorEntityChoice(
          fullPage: true,
          title: 'Non-Resident / Diaspora',
          badge: 'Overlay',
          subtitle: 'Combines with any base entity',
          description: 'Additional identity and residency details.',
          badgeColor: AppColors.diasporaBadge,
          badgeBackground: AppColors.diasporaBadgeBackground,
          minHeight: 110,
          selected: nonResident,
          toggle: true,
          onTap: () => setState(() {
            nonResident = !nonResident;
            if (nonResident) selected = null;
          }),
        ),
      ],
    ),
  );
}

class KycRequiredDocumentsScreen extends StatelessWidget {
  const KycRequiredDocumentsScreen({super.key});
  @override
  Widget build(BuildContext context) => InvestorPage(
    title: 'Government ID',
    titleCenterOffset: 8,
    headerLeadingInset: 21.5,
    headerTopInset: 17,
    child: SingleChildScrollView(
      padding: EdgeInsets.only(top: 27.w, bottom: 24.w),
      child: KycIdentityDocuments(
        onSelected: (step) => context.pushNamed(
          InvestorRoutes.kyc,
          pathParameters: {'entity': EntityType.individual.name, 'step': step},
        ),
      ),
    ),
  );
}
