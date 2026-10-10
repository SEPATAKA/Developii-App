import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class InvestorProfileHeader extends StatelessWidget {
  const InvestorProfileHeader({
    super.key,
    required this.user,
    required this.entityLabel,
    required this.invested,
    required this.earned,
    required this.projectCount,
    required this.onBack,
    required this.onSelectEntity,
  });
  final AppUser user;
  final String entityLabel;
  final String invested;
  final String earned;
  final int projectCount;
  final VoidCallback onBack;
  final VoidCallback onSelectEntity;

  @override
  Widget build(BuildContext context) => MeshBackground(
    asset: AppAssets.investorProfileMesh,
    child: Column(
      children: [
        AppPageAppBar(
          title: 'Profile',
          backAsset: AppAssets.investorBack,
          appearance: AppHeaderAppearance.dark,
          leadingInset: 9,
          topInset: 14,
          titleCenterOffset: -5,
          onBack: onBack,
        ),
        SizedBox(height: 10.5.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Switch investor profile, $entityLabel',
                  child: InkWell(
                    onTap: onSelectEntity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            user.hasProfilePhoto
                                ? AppAssets.investorProfileAvatar
                                : AppAssets.profileAvatarPlaceholder,
                            width: 46.w,
                            height: 46.w,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 4.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: AppTextStyles.text(
                                    16,
                                    weight: FontWeight.w700,
                                    color: AppColors.surface,
                                    height: 19 / 16,
                                  ),
                                ),
                                SizedBox(height: 6.w),
                                Text(
                                  user.email,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w500,
                                    color: AppColors.iconMuted,
                                    height: 17 / 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 9.w),
              Container(
                constraints: BoxConstraints(
                  minWidth: 81.w,
                  minHeight: 34.1719.w,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 10.125.w,
                  vertical: 7.59375.w,
                ),
                decoration: BoxDecoration(
                  color: AppColors.investorProfileTier,
                  borderRadius: BorderRadius.circular(148.078125.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(AppAssets.investorTier, size: 18.984375),
                    SizedBox(width: 3.796875.w),
                    Text(
                      'Tier 1',
                      style: AppTextStyles.text(
                        12.65625,
                        weight: FontWeight.w700,
                        color: AppColors.mintBorder,
                        height: 15 / 12.65625,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 35.6465.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, stat) in [
                ('Invested', invested),
                ('Projects', '$projectCount'),
                ('Earned', earned),
              ].indexed) ...[
                if (index > 0) SizedBox(width: 6.7596.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(4.w, 16.418.w, 4.w, 14.2899.w),
                    decoration: BoxDecoration(
                      color: AppColors.investorProfileStat,
                      borderRadius: BorderRadius.circular(15.w),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stat.$1,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            12.5552635,
                            color: AppColors.white,
                            height: 15 / 12.5552635,
                          ),
                        ),
                        Text(
                          stat.$2,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.text(
                            15.452631,
                            weight: FontWeight.w600,
                            color: AppColors.primary,
                            height: 19 / 15.452631,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 28.1456.w),
      ],
    ),
  );
}
