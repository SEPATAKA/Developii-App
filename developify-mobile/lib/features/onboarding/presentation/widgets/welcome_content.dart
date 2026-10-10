import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';

class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.darkTeal,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: safeTop + 420.w,
              child: Image.asset(
                AppAssets.welcomeProperty,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                opacity: const AlwaysStoppedAnimation(.07),
                excludeFromSemantics: true,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: safeTop + 25.w),
                Padding(
                  padding: EdgeInsets.only(left: 17.w),
                  child: const OnboardingBrand(light: true),
                ),
                SizedBox(height: 106.495.w),
                Padding(
                  padding: EdgeInsets.only(left: 19.w, right: 31.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turn your land into\nincome.',
                        style: AppTextStyles.text(
                          32,
                          weight: FontWeight.w700,
                          color: AppColors.lime,
                        ),
                      ),
                      SizedBox(height: 17.w),
                      Text(
                        "Submit your property to Developify. If it fits a viable development, we'll fund it — you keep a share of the returns.",
                        style: AppTextStyles.text(16, color: AppColors.surface),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 56.w),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeFeatures extends StatelessWidget {
  const WelcomeFeatures({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(19.w, 32.w, 19.w, 20.w),
    child: SizedBox(
      width: 247.w,
      child: Column(
        children: [
          for (final (index, item) in const [
            (
              AppAssets.welcomeUpfrontCost,
              'Zero upfront cost',
              'We handle the development.',
            ),
            (
              AppAssets.welcomeLeaseSale,
              'Choose lease or sale',
              'Keep title or exit cleanly.',
            ),
            (
              AppAssets.welcomeInvestors,
              'Backed by investors',
              '2,000+ verified investors.',
            ),
          ].indexed) ...[
            if (index > 0) SizedBox(height: 26.w),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: 44.w),
              child: Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(14.w),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: [11.5, 12.0, 8.5][index].w,
                          top: (index == 1 ? 12.4 : 11.4).w,
                          child: Image.asset(
                            item.$1,
                            key: ValueKey('welcome-feature-artwork-$index'),
                            width: 20.w,
                            height: 20.w,
                            cacheWidth: 80,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 19.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: AppTextStyles.text(
                            16,
                            weight: FontWeight.w600,
                            color: AppColors.gray900,
                            height: 19 / 16,
                          ),
                        ),
                        SizedBox(height: 5.0068.w),
                        Text(
                          item.$3,
                          style: AppTextStyles.text(
                            14,
                            weight: FontWeight.w500,
                            color: AppColors.muted,
                            height: 16 / 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
