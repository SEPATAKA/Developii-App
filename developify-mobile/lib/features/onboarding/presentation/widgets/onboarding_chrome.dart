import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';

class OnboardingBrand extends StatelessWidget {
  const OnboardingBrand({super.key, this.light = false, this.symbolAsset});
  final bool light;
  final String? symbolAsset;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 128.w,
    height: 29.505.w,
    child: Stack(
      children: [
        Positioned(
          left: 1.552.w,
          top: 3.695.w,
          width: 20.76.w,
          height: 22.115.w,
          child: SvgPicture.asset(
            symbolAsset ??
                (light ? AppAssets.brandSymbolLight : AppAssets.brandSymbol),
          ),
        ),
        Positioned(
          left: 27.624.w,
          top: -.079.w,
          width: 98.929.w,
          child: Text(
            'developify',
            textScaler: TextScaler.noScaling,
            style: AppTextStyles.text(
              21.261,
              weight: FontWeight.w700,
              color: light ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: 12.w, top: 17.w, right: 21.w),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const OnboardingBrand(),
        OnboardingPageIndicator(page: page),
      ],
    ),
  );
}

class SplashBrand extends StatelessWidget {
  const SplashBrand({super.key, this.landownerPortal = false});
  final bool landownerPortal;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('splash-brand'),
    width: 295.w,
    height: 68.w,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 3.5768.w,
          top: 8.516.w,
          width: 47.8464.w,
          height: 50.9679.w,
          child: SvgPicture.asset(
            landownerPortal
                ? AppAssets.brandSymbolSplash
                : AppAssets.investorSplashSymbol,
          ),
        ),
        Positioned(
          left: 63.6645.w,
          top: -.18167.w,
          width: 228.w,
          child: Text(
            'developify',
            textScaler: TextScaler.noScaling,
            style: AppTextStyles.text(
              49,
              weight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
        if (landownerPortal)
          Positioned(
            left: 95.w,
            top: 59.w,
            child: Text(
              'Landowner Portal',
              style: AppTextStyles.text(16, color: AppColors.lime),
            ),
          ),
      ],
    ),
  );
}

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Page ${page + 1} of 4',
    child: SizedBox(
      key: const ValueKey('onboarding-indicator'),
      width: 73.w,
      height: 7.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var index = 0; index < 4; index++)
            Container(
              key: ValueKey('onboarding-dot-$index'),
              width: (index == page ? 40 : 7).w,
              height: 7.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.5.w),
                color: index == page
                    ? AppColors.primary
                    : AppColors.borderStrong,
              ),
            ),
        ],
      ),
    ),
  );
}

class OnboardingActionArea extends StatelessWidget {
  const OnboardingActionArea({
    super.key,
    required this.onNext,
    required this.onSkip,
    this.left = 12,
    this.isLast = false,
  });
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final double left;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(left.w, 16.w, (24 - left).w, 6.w),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          key: const ValueKey('onboarding-next'),
          label: isLast ? 'Continue' : 'Get started',
          onPressed: onNext,
        ),
        SizedBox(height: 15.w),
        AppButton(
          key: const ValueKey('onboarding-skip'),
          label: 'Skip',
          style: AppButtonStyle.secondary,
          onPressed: onSkip,
        ),
      ],
    ),
  );
}
