import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';

Future<void> showPayoutSuccessSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.blackAlpha168,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.w)),
      ),
      builder: (_) => const PayoutSuccessSheet(),
    );

class PayoutSuccessSheet extends StatelessWidget {
  const PayoutSuccessSheet({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: math.min(
        473.w + MediaQuery.paddingOf(context).bottom,
        constraints.maxHeight,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 135.w,
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
              const AppIcon(AppAssets.payoutSuccess, size: 107.61146),
              SizedBox(height: 36.20557.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  'Bank Account Added',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    29.495958,
                    weight: FontWeight.w700,
                    height: 35 / 29.495958,
                  ),
                ),
              ),
              SizedBox(height: 5.899193.w),
              SizedBox(
                width: 308.75436.w,
                child: Text(
                  'Your bank account  has been successfully linked. You can now use it for payouts.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16.09143,
                    color: AppColors.muted,
                    height: 19 / 16.09143,
                  ),
                ),
              ),
              SizedBox(height: 45.w),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AppButton(
                  label: 'Done',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SizedBox(height: 22.28363.w),
            ],
          ),
        ),
      ),
    ),
  );
}
