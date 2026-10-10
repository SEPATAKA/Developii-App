import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class KycSelectionCard extends StatelessWidget {
  const KycSelectionCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.declaration = false,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool declaration;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    enabled: onTap != null,
    child: Material(
      color: selected
          ? AppColors.mint
          : declaration
          ? AppColors.border
          : AppColors.investorCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : declaration
              ? AppColors.borderStrong
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (declaration ? 78.w : 58.w).clamp(58, double.infinity),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.w),
            child: Row(
              children: [
                SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: Center(
                    child: AppIcon(
                      selected
                          ? AppAssets.investorCheckboxChecked
                          : AppAssets.investorCheckboxUnchecked,
                      size: selected ? 32 : 20,
                    ),
                  ),
                ),
                SizedBox(width: (declaration ? 8 : 15).w),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
