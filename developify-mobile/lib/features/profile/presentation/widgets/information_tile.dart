import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class InformationTile extends StatelessWidget {
  const InformationTile({
    super.key,
    required this.title,
    required this.onTap,
    this.answer,
    this.expanded = false,
    this.link = false,
  });
  final String title;
  final String? answer;
  final VoidCallback onTap;
  final bool expanded;
  final bool link;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: link ? null : expanded,
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.w),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.w),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16.w,
            (expanded ? 16 : 10).w,
            16.w,
            (expanded ? 8 : 10).w,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.text(
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.text,
                        height: (expanded ? 21 : 27) / 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SizedBox(
                    width: 24.w,
                    height: (expanded ? 21 : 27).w,
                    child: OverflowBox(
                      maxHeight: 24.w,
                      minHeight: 24.w,
                      child: RotatedBox(
                        quarterTurns: link
                            ? 3
                            : expanded
                            ? 2
                            : 0,
                        child: const AppIcon(AppAssets.faqChevron),
                      ),
                    ),
                  ),
                ],
              ),
              if (expanded && answer != null)
                SizedBox(
                  width: 279.w,
                  child: Text(
                    answer!,
                    style: AppTextStyles.text(
                      12,
                      color: AppColors.mutedNeutral,
                      height: 16 / 12,
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

class SupportContactTile extends StatelessWidget {
  const SupportContactTile({
    super.key,
    required this.label,
    required this.asset,
    required this.onTap,
  });
  final String label;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.w),
      side: const BorderSide(color: AppColors.border),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.w),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.319403.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35.247761.w,
              height: 35.247761.w,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Center(child: AppIcon(asset, size: 20)),
            ),
            SizedBox(height: 3.304477.w),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.text(
                label == 'Email' || label == 'Twitter' ? 13 : 14,
                weight: FontWeight.w600,
                color: AppColors.text,
                height:
                    14.319403 /
                    (label == 'Email' || label == 'Twitter' ? 13 : 14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
