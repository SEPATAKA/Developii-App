import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class KycIdentityDocuments extends StatelessWidget {
  const KycIdentityDocuments({
    super.key,
    required this.onSelected,
    this.chooseId = false,
  });
  final ValueChanged<String> onSelected;
  final bool chooseId;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        chooseId ? 'Which ID will you use?' : 'Required Documents',
        style: AppTextStyles.text(
          32,
          weight: FontWeight.w700,
          color: AppColors.black,
        ),
      ),
      SizedBox(height: 7.w),
      Text(
        'Please provide the following documents. Ensure they are all valid and unaltered.',
        style: AppTextStyles.text(16, color: AppColors.muted),
      ),
      SizedBox(height: 27.w),
      for (final (title, asset, step) in [
        (
          chooseId
              ? 'International Passport'
              : 'Government ID / International Passport',
          AppAssets.investorPassport,
          'identity',
        ),
        ('Proof of residence', AppAssets.investorResidence, 'address'),
        (
          'Proof of account (bank statement)',
          AppAssets.investorAccountProof,
          'bank',
        ),
      ]) ...[
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            onTap: () => onSelected(step),
            borderRadius: BorderRadius.circular(10.r),
            child: InvestorSurface(
              radius: 10,
              border: AppColors.border,
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 16.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 39.w),
                child: Row(
                  children: [
                    AppIcon(asset, size: 24),
                    SizedBox(width: step == 'identity' ? 8.w : 16.w),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    const AppIcon(AppAssets.chevronRight, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 14.w),
      ],
      SizedBox(height: 8.w),
      InvestorSurface(
        radius: 14,
        border: AppColors.border,
        padding: EdgeInsets.fromLTRB(18.w, 9.w, 18.w, 9.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tips for a clean scan',
              style: AppTextStyles.text(
                12,
                weight: FontWeight.w500,
                height: 17 / 12,
              ),
            ),
            SizedBox(height: 11.w),
            for (final (index, tip) in const [
              'Plain background, bring natural light',
              'No glare on the laminate',
              'All four corners visible',
            ].indexed) ...[
              if (index != 0) SizedBox(height: 7.w),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Text(
                  '•  $tip',
                  style: AppTextStyles.text(12, height: 17 / 12),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
