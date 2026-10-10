import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/domain/investor_project_content.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class ProjectDeveloperCard extends StatelessWidget {
  const ProjectDeveloperCard({
    super.key,
    required this.profile,
    this.onTap,
    this.verified = false,
  });
  final InvestorDeveloperProfile profile;
  final VoidCallback? onTap;
  final bool verified;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.investorCard,
    borderRadius: BorderRadius.circular(11.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11.r),
      child: InvestorSurface(
        radius: 11,
        border: AppColors.border,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.w),
        child: Row(
          children: [
            Container(
              width: 45.w,
              height: 45.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint,
              ),
              child: Center(
                child: Text(
                  profile.initials,
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w600,
                    letterSpacing: -.32,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: AppTextStyles.text(14, weight: FontWeight.w500),
                  ),
                  SizedBox(height: 6.w),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 4.w,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 130.w),
                        child: Text(
                          verified
                              ? 'Verified Developer'
                              : '${profile.completedProjects} projects completed',
                          style: AppTextStyles.text(14, color: AppColors.muted),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppIcon(
                            AppAssets.investorDeveloperStar,
                            size: 20,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            (profile.ratingTenths / 10).toStringAsFixed(1),
                            style: AppTextStyles.text(
                              14,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              SizedBox(width: 6.w),
              const AppIcon(
                AppAssets.investorNext,
                size: 20,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
