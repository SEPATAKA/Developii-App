import 'package:developify_mobile/features/investor/presentation/widgets/investor_property_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_components.dart';

class InvestorProjectSummary extends StatelessWidget {
  const InvestorProjectSummary({
    super.key,
    required this.name,
    required this.location,
    required this.image,
    required this.statistics,
    this.badge,
    this.progress,
    this.fundingStatistics = false,
  });

  final String name;
  final String location;
  final String image;
  final List<(String, String, Color?)> statistics;
  final String? badge;
  final int? progress;
  final bool fundingStatistics;

  @override
  Widget build(BuildContext context) => InvestorSurface(
    radius: 20,
    border: AppColors.border,
    padding: EdgeInsets.only(top: 4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, right: 5.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: InvestorPropertyImage(
              image,
              height: 149.w,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            13.w,
            (badge == null ? 20 : 21).w,
            (fundingStatistics ? 13 : 16).w,
            21.w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: AppTextStyles.text(16, weight: FontWeight.w700),
                    ),
                  ),
                  if (badge != null) ...[
                    SizedBox(width: 8.w),
                    Container(
                      constraints: BoxConstraints(
                        minWidth: 95.w,
                        minHeight: 24.w,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.w,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(30.r),
                        border: Border.all(
                          color: AppColors.mintBorder,
                          width: .83.w,
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: AppTextStyles.text(12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 4.w),
              Text(
                location.replaceFirst(', ', '  •  '),
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w400,
                  color: AppColors.muted,
                ),
              ),
              if (progress != null) ...[
                SizedBox(height: 13.w),
                InvestorProgress(progress!),
                SizedBox(height: 13.w),
              ] else
                SizedBox(height: 16.w),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 42.w),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      for (final (index, statistic) in statistics.indexed) ...[
                        if (index > 0)
                          VerticalDivider(
                            width: 1.w,
                            thickness: 1.w,
                            color: AppColors.borderStrong,
                          ),
                        Expanded(
                          flex: fundingStatistics
                              ? [75, 143, 125][index]
                              : [98, 110, 130][index],
                          child: Align(
                            alignment: fundingStatistics && index == 0
                                ? Alignment.centerLeft
                                : fundingStatistics && index == 2
                                ? Alignment.centerRight
                                : Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: fundingStatistics && index == 0 ? 1.w : 0,
                                right: fundingStatistics && index == 2
                                    ? 6.w
                                    : 0,
                              ),
                              child: SizedBox(
                                width: fundingStatistics && index == 2
                                    ? 90.w
                                    : null,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      fundingStatistics && index == 0
                                      ? CrossAxisAlignment.start
                                      : CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      statistic.$1,
                                      style: AppTextStyles.text(
                                        14,
                                        weight: FontWeight.w400,
                                        color: AppColors.iconMuted,
                                      ),
                                    ),
                                    SizedBox(height: 5.w),
                                    Text(
                                      statistic.$2,
                                      style: AppTextStyles.text(
                                        16,
                                        weight: FontWeight.w700,
                                        color:
                                            statistic.$3 ?? AppColors.gray900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
