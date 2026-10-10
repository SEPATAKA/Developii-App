import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';

Future<void> showSignupResultSheet(
  BuildContext context, {
  required InvestorSignupStore store,
  bool accountReady = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: !accountReady,
  enableDrag: !accountReady,
  barrierColor: AppColors.blackAlpha168,
  backgroundColor: AppColors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(8.w),
      topRight: Radius.circular(5.w),
    ),
  ),
  builder: (context) => Observer(
    builder: (_) => PopScope(
      canPop: !store.busy,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: math.min(
            (accountReady ? 515 : 502).w + MediaQuery.paddingOf(context).bottom,
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
                                    onTap: () {
                                      if (!store.busy) Navigator.pop(context);
                                    },
                                    child: SizedBox.square(
                                      dimension: 44,
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
                            accountReady
                                ? 'Congratulations! Your account is ready!'
                                : 'You’re verified',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.text(
                              29.32836,
                              weight: FontWeight.w700,
                              height: 35 / 29.32836,
                            ),
                          ),
                        ),
                        SizedBox(height: 5.866.w),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (accountReady ? 57 : 38).w,
                          ),
                          child: SizedBox(
                            width: (accountReady ? 350 : 295.239).w,
                            child: Text(
                              accountReady
                                  ? 'Welcome to Developify! Continue to open your demo investor account.'
                                  : 'Your email is confirmed. Let’s set up your security and you’re ready to invest',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.text(
                                16,
                                color: AppColors.muted,
                                height: 19 / 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 38.44.w),
                        const AppIcon(AppAssets.investorSuccess, size: 128),
                        SizedBox(height: 24.w),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Observer(
                    builder: (_) => Column(
                      children: [
                        InlineError(store.error),
                        AppButton(
                          label: 'Continue',
                          loading: store.busy,
                          onPressed: accountReady
                              ? () async {
                                  final done = await store.finish();
                                  if (context.mounted && done) {
                                    Navigator.pop(context);
                                  }
                                }
                              : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: (accountReady ? 0 : 10).w),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
