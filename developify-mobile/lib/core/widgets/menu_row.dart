import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.trailing,
    this.danger = false,
  });
  final String title;
  final String? subtitle;
  final String? icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;
  @override
  Widget build(BuildContext context) => Material(
    color: danger ? AppColors.errorSurface : AppColors.surface,
    borderRadius: BorderRadius.circular(12.r),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        constraints: BoxConstraints(minHeight: 68.h),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40.r,
                height: 40.r,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: danger ? AppColors.errorSurface : AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon!,
                  size: 22,
                  color: danger ? AppColors.error : AppColors.primary,
                ),
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
                      14,
                      weight: FontWeight.w600,
                      color: danger ? AppColors.error : AppColors.text,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle!,
                      style: AppTextStyles.text(12, color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (trailing != null)
              trailing!
            else if (!danger)
              const AppIcon(
                AppAssets.chevronRight,
                size: 20,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    ),
  );
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key, required this.child, this.warning = false});
  final Widget child;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(14.r),
    decoration: BoxDecoration(
      color: warning ? AppColors.warningSurface : AppColors.surface,
      border: Border.all(
        color: warning ? AppColors.warningSurface : AppColors.border,
      ),
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: child,
  );
}
