import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';

class SignupProgressHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const SignupProgressHeader({
    super.key,
    required this.step,
    required this.onBack,
    required this.textScaler,
  });
  final int step;
  final VoidCallback onBack;
  final TextScaler textScaler;

  @override
  Size get preferredSize =>
      Size.fromHeight(math.max(64.w, 47.w + textScaler.scale(17.sp)));

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.white,
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Stack(
          children: [
            Positioned(
              left: 13.w - (44 - 33.w) / 2,
              top: 17.w - (44 - 33.w) / 2,
              child: AppBackButton(onPressed: onBack),
            ),
            Positioned(
              left: 71.w,
              right: 13.w,
              top: 19.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(500.w),
                    child: LinearProgressIndicator(
                      value: step / 10,
                      minHeight: 4.w,
                      backgroundColor: AppColors.borderStrong,
                      color: AppColors.primary,
                      semanticsLabel: 'Account setup, step $step of 10',
                    ),
                  ),
                  SizedBox(height: 8.w),
                  Text(
                    'Step $step of 10',
                    style: AppTextStyles.text(
                      14,
                      weight: FontWeight.w500,
                      color: AppColors.iconMuted,
                      height: 17 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
