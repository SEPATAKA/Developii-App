import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({
    super.key,
    required this.title,
    this.icon,
    required this.onTap,
    this.subtitle,
    this.subtitleWidget,
    this.danger = false,
    this.trailing,
  });
  final String title;
  final String? icon;
  final VoidCallback? onTap;
  final String? subtitle;
  final Widget? subtitleWidget;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: danger ? AppColors.errorTint : AppColors.surface,
    borderRadius: BorderRadius.circular(12.w),
    child: InkWell(
      key: ValueKey('profile-menu-$title'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.w),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.w),
          border: danger
              ? null
              : Border.all(color: AppColors.border, width: 1.w),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(15.w, 16.w, 16.w, 16.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 40.w),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: danger ? AppColors.errorSurface : AppColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: AppIcon(icon!, size: 24)),
                  ),
                  SizedBox(width: 10.w),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.text(
                          16,
                          weight: FontWeight.w600,
                          color: danger ? AppColors.error : AppColors.black,
                          height: 19 / 16,
                        ),
                      ),
                      if (subtitle != null || subtitleWidget != null) ...[
                        SizedBox(height: 5.5.w),
                        subtitleWidget ??
                            Text(
                              subtitle!,
                              style: AppTextStyles.text(
                                12,
                                weight: FontWeight.w500,
                                color: AppColors.iconMuted,
                                height: 14 / 12,
                              ),
                            ),
                        SizedBox(height: 1.5.w),
                      ],
                    ],
                  ),
                ),
                if (!danger) ...[
                  SizedBox(width: 12.w),
                  trailing ??
                      const AppIcon(AppAssets.profileMenuChevron, size: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
