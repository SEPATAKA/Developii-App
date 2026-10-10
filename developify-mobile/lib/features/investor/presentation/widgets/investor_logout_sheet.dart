import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<bool?> showInvestorLogoutSheet(
  BuildContext context,
) => showModalBottomSheet<bool>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppColors.white,
  barrierColor: AppColors.modalScrim,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(8.w),
      topRight: Radius.circular(5.w),
    ),
  ),
  builder: (context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.min(448.w, constraints.maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              height: 78.w,
              child: Stack(
                children: [
                  Positioned(
                    right: 15.5.w,
                    top: 31.5.w,
                    child: Semantics(
                      button: true,
                      label: 'Close',
                      child: InkResponse(
                        onTap: () => Navigator.pop(context, false),
                        child: const SizedBox.square(
                          dimension: 44,
                          child: Center(
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 11.w),
                      child: const AppIcon(
                        AppAssets.investorLogoutConfirmation,
                        size: 62,
                      ),
                    ),
                    SizedBox(height: 19.w),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        'Log out of Developify',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          24,
                          weight: FontWeight.w700,
                          color: AppColors.body,
                          height: 29 / 24,
                        ),
                      ),
                    ),
                    SizedBox(height: 5.8652.w),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 41.5.w),
                      child: Text(
                        'You’ll need to log in again to access your account.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          16,
                          color: AppColors.muted,
                          height: 19 / 16,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.w),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10.w, 12.w, 9.w, 20.w),
              child: Column(
                children: [
                  AppButton(
                    label: 'Logout',
                    style: AppButtonStyle.danger,
                    backgroundColor: AppColors.investorLogoutButton,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                  SizedBox(height: 12.w),
                  AppButton(
                    label: 'Cancel',
                    backgroundColor: AppColors.errorSurface,
                    foregroundColor: AppColors.black,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
