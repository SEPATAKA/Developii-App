import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<void> showRecoverySuccessSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.blackAlpha168,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.w),
          topRight: Radius.circular(5.w),
        ),
      ),
      builder: (_) => const RecoverySuccessSheet(),
    );

class RecoverySuccessSheet extends StatelessWidget {
  const RecoverySuccessSheet({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.min(
        502.w + MediaQuery.paddingOf(context).bottom,
        constraints.maxHeight,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 100.694.w,
                      child: Stack(
                        children: [
                          Positioned(
                            right: 15.613.w,
                            top: 32.283.w,
                            child: Semantics(
                              button: true,
                              label: 'Close',
                              child: InkResponse(
                                onTap: () => Navigator.pop(context),
                                child: SizedBox.square(
                                  dimension: 44.w,
                                  child: const Center(
                                    child: AppIcon(
                                      AppAssets.recoverySuccessClose,
                                      size: 35,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 322.612.w,
                      child: Text(
                        'Congratulations! Your Password is Changed.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          29.32836,
                          weight: FontWeight.w700,
                          height: 35 / 29.32836,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.866.w),
                    SizedBox(
                      width: 295.239.w,
                      child: Text(
                        'Your password has been successfully updated. You can now log in with your new password.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          16,
                          color: AppColors.muted,
                          height: 19 / 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 31.44.w),
                    const AppIcon(AppAssets.recoverySuccess, size: 128),
                    SizedBox(height: 24.w),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: AppButton(
                label: 'Login Now',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: 10.w),
          ],
        ),
      ),
    ),
  );
}
