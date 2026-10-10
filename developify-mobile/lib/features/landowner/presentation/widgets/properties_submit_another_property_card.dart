import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/dashed_border.dart';

class PropertiesSubmitAnotherPropertyCard extends StatelessWidget {
  const PropertiesSubmitAnotherPropertyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16.w),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.w),
      child: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: AppColors.borderStrong,
          radius: 16.w,
          strokeWidth: 2.w,
          dashLength: 8.w,
          gapLength: 8.w,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(21.w, 14.w, 16.w, 13.705883.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43.294117.w,
                height: 43.294117.w,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: AppIcon(AppAssets.propertiesSubmitAnother),
                ),
              ),
              SizedBox(width: 32.705883.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Submit another property',
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w600,
                          height: 16 / 14,
                          color: AppColors.deepInk,
                        ),
                      ),
                      SizedBox(height: 5.w),
                      Text(
                        'No limit, No upfront cost',
                        style: AppTextStyles.text(
                          12,
                          weight: FontWeight.w500,
                          height: 14 / 12,
                          color: AppColors.muted,
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
  );
}
