import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class SecurityDeviceCard extends StatelessWidget {
  const SecurityDeviceCard({
    super.key,
    required this.current,
    required this.expanded,
    required this.onToggle,
    required this.onRemove,
  });
  final bool current;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12.w),
    ),
    padding: EdgeInsets.fromLTRB(
      19.w,
      (current ? 11 : 19).w,
      (current ? 16 : 20).w,
      (current ? 11 : 19).w,
    ),
    child: Row(
      children: [
        const AppIcon(AppAssets.securityDevicePhone),
        SizedBox(width: (current ? 19 : 16).w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'iphone 15 Pro',
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.text,
                  height: 17 / 14,
                ),
              ),
              SizedBox(height: 4.w),
              Text(
                'iOS 17.4',
                style: AppTextStyles.text(
                  12,
                  weight: FontWeight.w500,
                  color: AppColors.iconMuted,
                  height: 14 / 12,
                ),
              ),
              SizedBox(height: (current ? 10 : 6).w),
              Wrap(
                spacing: (current ? 20 : 5).w,
                children: [
                  for (final text
                      in current
                          ? ['Lagos, Nigeria', '3 days ago']
                          : ['3 days ago', 'Lagos, Nigeria'])
                    Text(
                      text,
                      style: AppTextStyles.text(
                        12,
                        weight: FontWeight.w500,
                        color: AppColors.muted,
                        height: 14 / 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  constraints: BoxConstraints(minWidth: (current ? 95 : 71).w),
                  padding: EdgeInsets.symmetric(
                    horizontal: (current ? 8 : 10).w,
                    vertical: 3.w,
                  ),
                  decoration: BoxDecoration(
                    color: current ? AppColors.successLight : AppColors.amber50,
                    borderRadius: BorderRadius.circular(99.w),
                    border: Border.all(
                      color: current ? AppColors.lime : AppColors.amber300,
                      width: .5.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (current) ...[
                        SizedBox.square(
                          dimension: 16.w,
                          child: Center(
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.successForest,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        current ? 'ACTIVE NOW' : 'INACTIVE',
                        style: AppTextStyles.text(
                          10,
                          weight: FontWeight.w600,
                          color: current
                              ? AppColors.successForestDark
                              : AppColors.warning,
                          height: 16 / 10,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 9.w),
                SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: OverflowBox(
                    maxWidth: 44,
                    maxHeight: 44,
                    child: Semantics(
                      button: true,
                      label: expanded
                          ? 'Collapse device details'
                          : 'Expand device details',
                      child: InkResponse(
                        onTap: onToggle,
                        child: SizedBox.square(
                          dimension: 44,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: expanded ? 2 : 0,
                              child: const AppIcon(
                                AppAssets.securityDeviceChevron,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!current && expanded) ...[
              SizedBox(height: 7.w),
              SizedBox(
                width: 24.w,
                height: 24.w,
                child: OverflowBox(
                  maxWidth: 44,
                  maxHeight: 44,
                  child: Semantics(
                    button: true,
                    label: 'Remove previous device',
                    child: InkResponse(
                      onTap: onRemove,
                      child: const SizedBox.square(
                        dimension: 44,
                        child: Center(
                          child: AppIcon(AppAssets.securityDeviceRemove),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(height: (current ? 36 : 0).w),
          ],
        ),
      ],
    ),
  );
}
