import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<void> showSecuritySuccessSheet(
  BuildContext context, {
  required String title,
  required String message,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  barrierColor: AppColors.blackAlpha168,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
  ),
  builder: (_) => SecuritySuccessSheet(title: title, message: message),
);

class SecuritySuccessSheet extends StatelessWidget {
  const SecuritySuccessSheet({
    super.key,
    required this.title,
    required this.message,
  });
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.min(
        414.w + MediaQuery.paddingOf(context).bottom,
        constraints.maxHeight,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 92.w,
                child: Stack(
                  children: [
                    Positioned(
                      right: 15.638.w,
                      top: 32.2575.w,
                      child: Semantics(
                        label: 'Close',
                        button: true,
                        child: InkResponse(
                          onTap: () => Navigator.pop(context),
                          child: const SizedBox.square(
                            dimension: 44,
                            child: Center(
                              child: AppIcon(
                                AppAssets.payoutSuccessClose,
                                size: 32.2612,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const AppIcon(AppAssets.securitySuccess, size: 100.0247),
              SizedBox(height: 36.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 21.w),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    29.32836,
                    weight: FontWeight.w700,
                    height: 35 / 29.32836,
                  ),
                ),
              ),
              SizedBox(height: 6.w),
              SizedBox(
                width: 349.99.w,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16,
                    color: AppColors.muted,
                    height: 19 / 16,
                  ),
                ),
              ),
              SizedBox(height: 54.9753.w),
              Padding(
                padding: EdgeInsets.only(left: 10.w, right: 9.w),
                child: AppButton(
                  label: 'Done',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: 4.w),
            ],
          ),
        ),
      ),
    ),
  );
}
