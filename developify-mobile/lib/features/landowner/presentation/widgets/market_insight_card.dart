import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class MarketInsightCard extends StatelessWidget {
  const MarketInsightCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: 102.w),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.tealCard,
      borderRadius: BorderRadius.circular(16.w),
    ),
    child: Stack(
      children: [
        Positioned(
          left: 245.079.w,
          top: 7.079.w,
          width: 124.w,
          height: 95.w,
          child: SvgPicture.asset(AppAssets.marketGrowth),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(17.w, 16.w, 17.w, 21.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Randburg demand is up 18%',
                style: AppTextStyles.text(
                  15,
                  weight: FontWeight.w600,
                  color: AppColors.lime,
                  height: 17 / 15,
                ),
              ),
              SizedBox(height: 9.w),
              SizedBox(
                width: 252.w,
                child: Text(
                  'Three new developments within 4 km of Malibongwe Erf 4412 this quarter. Land here is valued higher.',
                  style: AppTextStyles.text(
                    12,
                    color: AppColors.white,
                    height: 13 / 12,
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
