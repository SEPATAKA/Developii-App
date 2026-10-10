import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class HomeEmptyProperties extends StatelessWidget {
  const HomeEmptyProperties({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.only(top: 16.w),
      child: SizedBox(
        width: 281.w,
        child: Column(
          children: [
            SvgPicture.asset(
              AppAssets.homeEmptyProperties,
              width: 148.w,
              height: 132.009.w,
              semanticsLabel: 'A property held in your hand',
            ),
            SizedBox(height: 51.w),
            Text(
              'No Properties Yet',
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.black,
                height: 17 / 14,
              ),
            ),
            SizedBox(height: 16.w),
            Text(
              "You haven't listed any properties yet. Add your first property to start reaching potential tenants or buyers.",
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w500,
                color: AppColors.muted,
                height: 17 / 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
