import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class PayoutNotice extends StatelessWidget {
  const PayoutNotice({
    super.key,
    required this.message,
    this.verification = false,
    this.overview = false,
  });
  final String message;
  final bool verification;
  final bool overview;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: (verification ? 63 : 80).w),
    padding: EdgeInsets.fromLTRB(
      (verification
              ? 12
              : overview
              ? 13
              : 14)
          .w,
      (verification
              ? 11
              : overview
              ? 16
              : 13)
          .w,
      (verification ? 17 : 14).w,
      (verification
              ? 16
              : overview
              ? 11
              : 14)
          .w,
    ),
    decoration: BoxDecoration(
      color: verification ? AppColors.skyTint : AppColors.warningSurface,
      borderRadius: BorderRadius.circular(14.w),
      border: Border.all(
        color: verification ? AppColors.skyBorder : AppColors.warningPale,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!verification) ...[
          SizedBox(
            width: 19.w,
            height: 22.w,
            child: const Center(
              child: AppIcon(AppAssets.payoutWarning, size: 19),
            ),
          ),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.text(
              verification ? 12 : 14,
              weight: verification ? FontWeight.w400 : FontWeight.w500,
              color: verification ? AppColors.text : AppColors.amber900,
              height: verification ? 17 / 12 : 17 / 14,
            ),
          ),
        ),
      ],
    ),
  );
}
