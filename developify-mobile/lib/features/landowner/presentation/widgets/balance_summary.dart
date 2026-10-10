import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

class BalanceSummary extends StatelessWidget {
  const BalanceSummary({
    super.key,
    required this.label,
    required this.amount,
    required this.payout,
    required this.visible,
    required this.onVisibilityChanged,
    this.payoutTiming,
    this.trailingSpace = 0,
  });
  final String label;
  final String amount;
  final String? payout;
  final String? payoutTiming;
  final double trailingSpace;
  final bool visible;
  final VoidCallback onVisibilityChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: trailingSpace.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.text(
                    14,
                    color: AppColors.white,
                    height: 20 / 14,
                  ).copyWith(letterSpacing: -.56.sp),
                ),
              ),
              SizedBox(width: 4.w),
              Semantics(
                button: true,
                label: visible ? 'Hide balance' : 'Show balance',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onVisibilityChanged,
                  child: AppIcon(
                    visible ? AppAssets.balanceEye : AppAssets.balanceEyeClosed,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.w),
        Semantics(
          label: label,
          value: visible ? amount : 'Hidden',
          child: ExcludeSemantics(
            child: Text(
              visible ? amount : '****',
              style: AppTextStyles.text(
                36,
                weight: FontWeight.w600,
                color: AppColors.white,
                height: 43 / 36,
              ).copyWith(letterSpacing: visible ? -1.44.sp : 1.sp),
            ),
          ),
        ),
        SizedBox(height: 4.w),
        Wrap(
          spacing: 4.w,
          runSpacing: 2.w,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Next Payouts:',
              softWrap: false,
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: AppColors.lime,
                height: 20 / 14,
              ).copyWith(letterSpacing: -.56.sp),
            ),
            Text(
              payout == null
                  ? 'No payout scheduled'
                  : visible
                  ? payout!
                  : '****',
              style: AppTextStyles.text(
                14,
                weight: FontWeight.w600,
                color: AppColors.mint,
                height: 20 / 14,
              ).copyWith(letterSpacing: -.56.sp),
            ),
            if (payout != null && payoutTiming != null)
              Text(
                payoutTiming!,
                softWrap: false,
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w600,
                  color: AppColors.mint,
                  height: 20 / 14,
                ).copyWith(letterSpacing: -.56.sp),
              ),
          ],
        ),
      ],
    ),
  );
}
