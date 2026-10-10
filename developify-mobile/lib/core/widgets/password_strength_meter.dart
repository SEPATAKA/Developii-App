import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.filledSegments,
    this.invalid = false,
    this.labelColor,
    this.activeColor = AppColors.successBright,
    this.barLeadingInset = 0,
  });
  final int filledSegments;
  final bool invalid;
  final Color? labelColor;
  final Color activeColor;
  final double barLeadingInset;

  @override
  Widget build(BuildContext context) {
    final barColor = invalid ? AppColors.errorDark : activeColor;
    final textColor =
        labelColor ??
        (invalid
            ? AppColors.errorDark
            : filledSegments == 0
            ? AppColors.placeholder
            : AppColors.primary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: barLeadingInset.w),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 360.w),
              child: Row(
                children: [
                  for (var index = 0; index < 5; index++) ...[
                    if (index > 0) SizedBox(width: 10.w),
                    Expanded(
                      child: Container(
                        key: ValueKey('strength-segment-$index'),
                        height: 7.w,
                        decoration: BoxDecoration(
                          color: index < filledSegments
                              ? barColor
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(500.w),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 19.w),
        Wrap(
          spacing: 6.w,
          children: [
            for (final label in [
              'Strong,',
              'At least 8 characters,',
              'Mix case & Numbers',
            ])
              Text(
                label,
                style: AppTextStyles.text(
                  14,
                  weight: FontWeight.w500,
                  color: textColor,
                  height: 17 / 14,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
