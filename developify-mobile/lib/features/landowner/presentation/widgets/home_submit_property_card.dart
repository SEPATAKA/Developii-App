import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class HomeSubmitPropertyCard extends StatelessWidget {
  const HomeSubmitPropertyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.mint,
    borderRadius: BorderRadius.circular(14.w),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12.w, 17.w, 12.w, 18.705883.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mintBorder),
          borderRadius: BorderRadius.circular(14.w),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 43.294117.w,
              height: 43.294117.w,
              decoration: const BoxDecoration(
                color: AppColors.growthSurface,
                shape: BoxShape.circle,
              ),
              child: const Center(child: AppIcon(AppAssets.homeSubmitProperty)),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 268.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Submit a new property',
                      style: AppTextStyles.text(
                        15.059,
                        weight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 6.w),
                    Text(
                      'Get a viability decision in 5-10 business days',
                      style: AppTextStyles.text(
                        13.176,
                        color: AppColors.mintText,
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
  );
}
