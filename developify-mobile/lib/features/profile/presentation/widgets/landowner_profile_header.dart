import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class LandownerProfileHeader extends StatelessWidget {
  const LandownerProfileHeader({
    super.key,
    required this.user,
    required this.onBack,
    this.propertyCount = 0,
    this.approvedCount = 0,
    this.earnedLabel = 'R0',
  });
  final AppUser user;
  final VoidCallback onBack;
  final int propertyCount;
  final int approvedCount;
  final String earnedLabel;

  @override
  Widget build(BuildContext context) => MeshBackground(
    asset: AppAssets.landownerProfileMesh,
    child: ColoredBox(
      color: AppColors.neutralTrack.withValues(alpha: .01),
      child: Column(
        children: [
          AppPageAppBar(
            title: 'Profile',
            backAsset: AppAssets.profileBack,
            appearance: AppHeaderAppearance.dark,
            leadingInset: 9,
            topInset: 14,
            titleCenterOffset: -5,
            onBack: onBack,
          ),
          SizedBox(height: 10.5.w),
          Padding(
            padding: EdgeInsets.only(left: 13.w, right: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: Image.asset(
                    user.hasProfilePhoto
                        ? AppAssets.avatar
                        : AppAssets.profileAvatarPlaceholder,
                    width: 46.w,
                    height: 46.w,
                    fit: BoxFit.cover,
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
                SizedBox(width: 44.w),
                Padding(
                  padding: EdgeInsets.only(top: 1.5.w),
                  child: Container(
                    width: 136.w,
                    constraints: BoxConstraints(minHeight: 32.w),
                    padding: EdgeInsets.fromLTRB(
                      15.6171875.w,
                      10.7127075.w,
                      5.w,
                      8.2872925.w,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.investorCommercial.withValues(alpha: .3),
                      borderRadius: BorderRadius.circular(122.602318.w),
                    ),
                    child: Text(
                      '${user.entity.name[0].toUpperCase()}${user.entity.name.substring(1)}  Landowner',
                      style: AppTextStyles.text(
                        10.47883,
                        weight: FontWeight.w700,
                        color: AppColors.mintBorder,
                        height: 13 / 10.47883,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 67.5.w),
          Padding(
            padding: EdgeInsets.only(left: 13.w, right: 14.w),
            child: Row(
              children: [
                for (final entry in [
                  ('$propertyCount', 'Properties'),
                  ('$approvedCount', 'Approved'),
                  (earnedLabel, 'Earned'),
                ].indexed) ...[
                  if (entry.$1 > 0) SizedBox(width: 6.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(
                        top: (entry.$1 == 1 ? 16.418457 : 15).w,
                        bottom: (entry.$1 == 1 ? 14.581543 : 16).w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(15.w),
                      ),
                      child: Column(
                        children: [
                          Text(
                            entry.$2.$1,
                            style: AppTextStyles.text(
                              15.452631,
                              weight: FontWeight.w600,
                              color: AppColors.primary,
                              height: 19 / 15.452631,
                            ),
                          ),
                          Text(
                            entry.$2.$2,
                            style: AppTextStyles.text(
                              12,
                              color: AppColors.white,
                              height: 14 / 12,
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
          SizedBox(height: 45.w),
        ],
      ),
    ),
  );
}
