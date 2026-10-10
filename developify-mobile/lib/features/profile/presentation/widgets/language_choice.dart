import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class LanguageChoice extends StatelessWidget {
  const LanguageChoice({
    super.key,
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: Material(
      color: selected ? AppColors.mint : AppColors.slate50,
      borderRadius: BorderRadius.circular(8.w),
      child: InkWell(
        key: ValueKey('language-$label'),
        borderRadius: BorderRadius.circular(8.w),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.w),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1.w)
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              8.w,
              (selected ? 20 : 18.5).w,
              (selected ? 11 : 10).w,
              (selected ? 20 : 18.5).w,
            ),
            child: Row(
              children: [
                AppIcon(flag, size: 24),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.gray900,
                      height: 17 / 14,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                AppIcon(
                  selected
                      ? AppAssets.languageSelected
                      : AppAssets.languageUnselected,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
