import 'package:developify_mobile/features/investor/domain/investment_policy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/investor_entity_sheet.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';

class InvestorOnboardingScreen extends StatefulWidget {
  const InvestorOnboardingScreen({super.key});
  @override
  State<InvestorOnboardingScreen> createState() =>
      _InvestorOnboardingScreenState();
}

class _InvestorOnboardingScreenState extends State<InvestorOnboardingScreen> {
  final _pages = PageController();
  int page = 0;
  static const _content = [
    (
      AppAssets.investorOnboardingProperties,
      'Invest in real properties, from R${InvestmentPolicy.minimumMajorUnits}',
      'Fund verified development from Africa and earn projected returns at completion',
    ),
    (
      AppAssets.investorOnboardingProgress,
      'Track every brick. Live progress.',
      'Watch your funded projects grow in real time with updates and milestone reports.',
    ),
    (
      AppAssets.investorOnboardingWithdrawal,
      'Withdraw to your bank in minutes.',
      'Cash out your wallet anytime, fast, secure to the bank account you trust',
    ),
  ];
  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    context.goNamed('investor-onboarding-terms');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 66.w,
            child: Stack(
              children: [
                Positioned(
                  left: 12.w,
                  top: 17.w,
                  child: const OnboardingBrand(
                    symbolAsset: AppAssets.investorBrandSymbol,
                  ),
                ),
                Positioned(
                  right: 21.w,
                  top: 9.7525.w,
                  child: Semantics(
                    button: true,
                    label: 'Onboarding page ${page + 1} of 3. Next page',
                    child: InkWell(
                      onTap: () => _pages.animateToPage(
                        (page + 1) % _content.length,
                        duration: AppDurations.motion(
                          context,
                          AppDurations.page,
                        ),
                        curve: Curves.easeOut,
                      ),
                      child: SizedBox(
                        width: 62.w,
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (
                              var index = 0;
                              index < _content.length;
                              index++
                            )
                              AnimatedContainer(
                                duration: AppDurations.motion(
                                  context,
                                  AppDurations.state,
                                ),
                                width: (index == page ? 40 : 7).w,
                                height: 7.w,
                                decoration: BoxDecoration(
                                  color: index == page
                                      ? AppColors.primary
                                      : AppColors.borderStrong,
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _content.length,
              onPageChanged: (value) => setState(() => page = value),
              itemBuilder: (context, index) {
                final item = _content[index];
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.asset(
                          item.$1,
                          width: 369.w,
                          height: 406.w,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
                      SizedBox(height: 18.w),
                      Padding(
                        padding: EdgeInsets.only(
                          left: [2.0, 5.0, 8.0][index].w,
                          right: [24.0, 21.0, 18.0][index].w,
                        ),
                        child: Text(
                          item.$2,
                          style: AppTextStyles.text(
                            32,
                            weight: FontWeight.w700,
                            height: 38 / 32,
                          ),
                        ),
                      ),
                      SizedBox(height: 17.w),
                      Padding(
                        padding: EdgeInsets.only(
                          left: [2.0, 5.0, 8.0][index].w,
                          right: [24.0, 21.0, 18.0][index].w,
                        ),
                        child: Text(
                          item.$3,
                          style: AppTextStyles.text(
                            16,
                            color: AppColors.muted,
                            height: 19 / 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.w),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              (page == 1 ? 14 : 12).w,
              14.w,
              (page == 1 ? 10 : 12).w,
              6.w,
            ),
            child: Column(
              children: [
                AppButton(label: 'Get started', onPressed: _finish),
                SizedBox(height: 15.w),
                AppButton(
                  label: 'Skip',
                  style: AppButtonStyle.secondary,
                  onPressed: _finish,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class InvestorWelcomeScreen extends StatelessWidget {
  const InvestorWelcomeScreen({super.key, this.fromOnboarding = false});
  final bool fromOnboarding;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12.w,
                0,
                12.w,
                fromOnboarding ? 12.w : 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: fromOnboarding
                            ? Image.asset(
                                AppAssets.investorWelcome,
                                width: double.infinity,
                                height: 408.w,
                                fit: BoxFit.cover,
                                excludeFromSemantics: true,
                              )
                            : SvgPicture.asset(
                                AppAssets.investorWelcomeIllustration,
                                width: 369.w,
                                height: 406.w,
                                excludeFromSemantics: true,
                              ),
                      ),
                      SizedBox(height: (fromOnboarding ? 19 : 21).w),
                      SizedBox(
                        width: 343.w,
                        child: Text(
                          'Welcome to the future of property',
                          style: AppTextStyles.text(
                            32,
                            weight: FontWeight.w700,
                            height: 38 / 32,
                          ),
                        ),
                      ),
                      SizedBox(height: 17.w),
                      SizedBox(
                        width: 343.w,
                        child: Text(
                          'Join 38,000+ investors building portfolios of physical, income-producing real estate.',
                          style: AppTextStyles.text(
                            16,
                            color: AppColors.muted,
                            height: 19 / 16,
                          ),
                        ),
                      ),
                      SizedBox(height: 31.w),
                      AppButton(
                        label: 'Create account',
                        onPressed: () async {
                          final choice = await showInvestorEntitySheet(
                            context,
                            initial: null,
                          );
                          if (context.mounted && choice != null) {
                            await context.pushNamed(
                              InvestorRoutes.signUp,
                              queryParameters: {
                                'entity': choice.entity.name,
                                if (choice.nonResident) 'nonResident': 'true',
                              },
                            );
                          }
                        },
                      ),
                      SizedBox(height: 15.w),
                      AppButton(
                        label: 'I already have an account',
                        style: AppButtonStyle.secondary,
                        onPressed: () =>
                            context.pushNamed(InvestorRoutes.signIn),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: (fromOnboarding ? 6 : 16).w),
                    child: SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Text(
                            'By continuing, you agree to our ',
                            style: AppTextStyles.text(
                              16,
                              color: AppColors.muted,
                            ),
                          ),
                          TextButton(
                            style: _legalLinkStyle,
                            onPressed: () =>
                                context.pushNamed('investor-terms'),
                            child: const Text('Terms'),
                          ),
                          Text(
                            '&',
                            style: AppTextStyles.text(
                              16,
                              color: AppColors.muted,
                            ),
                          ),
                          TextButton(
                            style: _legalLinkStyle,
                            onPressed: () =>
                                context.pushNamed('investor-privacy'),
                            child: const Text('Privacy'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  ButtonStyle get _legalLinkStyle => TextButton.styleFrom(
    padding: EdgeInsets.zero,
    alignment: Alignment.bottomCenter,
    minimumSize: const Size(44, 44),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.text(16),
  );
}
