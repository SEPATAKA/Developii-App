import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/onboarding/presentation/widgets/onboarding_chrome.dart';
import 'package:developify_mobile/features/profile/presentation/stores/information_store.dart';

class OnboardingTermsScreen extends StatelessWidget {
  const OnboardingTermsScreen({
    super.key,
    required this.store,
    required this.sections,
    required this.onContinue,
    this.brandAsset,
    this.declaration =
        'This information is used only for identity verification and is transmitted securely using 128-bit encyrption',
  });
  final InformationStore store;
  final List<(String, String)> sections;
  final VoidCallback onContinue;
  final String declaration;
  final String? brandAsset;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 12.w, top: 17.w),
              child: OnboardingBrand(symbolAsset: brandAsset),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('landowner-terms-content'),
                padding: EdgeInsets.fromLTRB(20.w, 26.495.w, 30.w, 27.w),
                children: [
                  Text(
                    'Terms of Service',
                    style: AppTextStyles.text(
                      25,
                      weight: FontWeight.w600,
                      color: AppColors.gray900,
                    ),
                  ),
                  SizedBox(height: 24.w),
                  for (final (index, section) in sections.indexed) ...[
                    if (index > 0) SizedBox(height: 12.w),
                    Text(
                      section.$1,
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w500,
                        color: AppColors.gray900,
                        height: 19 / 16,
                      ),
                    ),
                    SizedBox(height: 4.w),
                    if (index < 2)
                      Text(
                        section.$2,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.muted,
                          height: 20 / 14,
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 21.w,
                            child: Center(
                              child: Text(
                                '·',
                                style: AppTextStyles.text(
                                  14,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              section.$2,
                              style: AppTextStyles.text(
                                14,
                                weight: FontWeight.w500,
                                color: AppColors.muted,
                                height: 20 / 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: AppColors.disabled,
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: 20.w),
          child: Padding(
            padding: EdgeInsets.only(top: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Observer(
                    builder: (_) => Semantics(
                      checked: store.acceptedTerms,
                      label: 'Agree to the Terms of Service',
                      child: InkWell(
                        key: const ValueKey('terms-declaration'),
                        onTap: () => store.acceptTerms(!store.acceptedTerms),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppIcon(
                                store.acceptedTerms
                                    ? AppAssets.termsChecked
                                    : AppAssets.termsUnchecked,
                                size: 22,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  declaration,
                                  style: AppTextStyles.text(
                                    14,
                                    weight: FontWeight.w500,
                                    color: AppColors.mutedCool,
                                    height: 17 / 14,
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
                SizedBox(height: 2.w),
                Padding(
                  padding: EdgeInsets.only(left: 16.w, right: 8.w),
                  child: Observer(
                    builder: (_) => AppButton(
                      key: const ValueKey('terms-continue'),
                      label: 'Continue',
                      onPressed: store.acceptedTerms ? onContinue : null,
                      disabledBackgroundColor: AppColors.secondaryButton,
                      disabledForegroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
