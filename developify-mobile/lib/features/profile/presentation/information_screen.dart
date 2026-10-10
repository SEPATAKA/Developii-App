import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/features/profile/presentation/widgets/information_tile.dart';
import 'package:developify_mobile/features/profile/presentation/stores/information_store.dart';
import 'package:developify_mobile/features/onboarding/presentation/onboarding_terms_screen.dart';

enum InformationPage { help, about, privacy, terms, onboardingTerms }

class InformationScreen extends StatelessWidget {
  const InformationScreen({
    super.key,
    required this.page,
    required this.store,
    this.onConsentAccepted,
    this.routePrefix = '',
  });
  final InformationPage page;
  final InformationStore store;
  final VoidCallback? onConsentAccepted;
  final String routePrefix;
  String get _title => switch (page) {
    InformationPage.help => 'Help & Support',
    InformationPage.about => 'About Developify',
    InformationPage.privacy => 'Privacy Policy',
    InformationPage.terms => 'Terms & Condition',
    InformationPage.onboardingTerms => 'Terms of Service',
  };
  @override
  Widget build(BuildContext context) {
    if (page == InformationPage.onboardingTerms) {
      return OnboardingTermsScreen(
        store: store,
        brandAsset: routePrefix == 'investor-'
            ? AppAssets.investorBrandSymbol
            : null,
        sections: _onboardingTerms,
        declaration: routePrefix == 'investor-'
            ? 'I have read and agree to the Terms of Service. Identity verification in this app is simulated.'
            : 'This information is used only for identity verification and is transmitted securely using 128-bit encyrption',
        onContinue:
            onConsentAccepted ??
            () => context.goNamed('$routePrefix${Routes.signUp}'),
      );
    }
    return AppPage(
      title: _title,
      headerLeadingInset: 22,
      titleCenterOffset: routePrefix == 'investor-'
          ? switch (page) {
              InformationPage.privacy => -11,
              InformationPage.terms => 4,
              _ => 0,
            }
          : 0,
      onBack: routePrefix == 'investor-'
          ? () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(
                  '$routePrefix${page == InformationPage.help || page == InformationPage.about ? Routes.profile : Routes.about}',
                );
              }
            }
          : null,
      child: switch (page) {
        InformationPage.help => _help(context),
        InformationPage.about => _about(context),
        _ => _legal(),
      },
    );
  }

  Widget _help(BuildContext context) => ListView(
    padding: EdgeInsets.only(top: 23.w, bottom: 18.w),
    children: [
      for (var i = 0; i < _questions.length; i++) ...[
        if (i > 0) SizedBox(height: 12.w),
        Observer(
          builder: (_) => InformationTile(
            key: ValueKey('help-question-$i'),
            title: _questions[i].$1,
            answer: _questions[i].$2,
            expanded: store.expandedQuestion == i,
            onTap: () => store.toggleQuestion(i),
          ),
        ),
      ],
      SizedBox(height: 26.w),
      Text(
        'CONTACT US',
        style: AppTextStyles.text(
          13.217911,
          weight: FontWeight.w600,
          color: AppColors.text,
          height: 14.319403 / 13.217911,
        ),
      ),
      SizedBox(height: 11.w),
      for (final row in [
        [
          ('Email', AppAssets.helpEmail),
          ('Instagram', AppAssets.helpInstagram),
          ('Facebook', AppAssets.helpFacebook),
        ],
        [
          ('Twitter', AppAssets.helpTwitter),
          ('Live Chat', AppAssets.helpLiveChat),
          ('Call Us', AppAssets.helpCall),
        ],
      ]) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) SizedBox(width: 11.014925.w),
              Expanded(
                child: SupportContactTile(
                  label: row[i].$1,
                  asset: row[i].$2,
                  onTap: () {
                    if (row[i].$1 == 'Live Chat') {
                      context.pushNamed('$routePrefix${Routes.chat}');
                    } else {
                      showFeedback(
                        context,
                        'Support contact details are awaiting confirmation.',
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 11.489556.w),
      ],
    ],
  );

  Widget _about(BuildContext context) => ListView(
    padding: EdgeInsets.only(top: 29.w, bottom: 24.w),
    children: [
      const Center(child: AppIcon(AppAssets.aboutBrand, size: 101.410065)),
      SizedBox(height: 30.w),
      Text(
        'Developify',
        textAlign: TextAlign.center,
        style: AppTextStyles.text(
          20,
          weight: FontWeight.w700,
          color: AppColors.gray900,
          height: 23 / 20,
        ),
      ),
      SizedBox(height: 20.w),
      Text(
        'Version 1.0.0 · Build 2026.06.15',
        textAlign: TextAlign.center,
        style: AppTextStyles.text(
          14,
          weight: FontWeight.w500,
          color: AppColors.gray900,
          height: 16 / 14,
        ),
      ),
      SizedBox(height: 17.w),
      Center(
        child: SizedBox(
          width: 234.w,
          child: Text(
            'Built with care to make property\ninvestment accessible, transparent, and\nsecure for everyone.',
            textAlign: TextAlign.center,
            style: AppTextStyles.text(
              14,
              color: AppColors.muted,
              height: 18 / 14,
            ),
          ),
        ),
      ),
      SizedBox(height: 28.w),
      InformationTile(
        title: 'Terms & Condition',
        link: true,
        onTap: () => context.pushNamed('$routePrefix${Routes.terms}'),
      ),
      SizedBox(height: 12.w),
      InformationTile(
        title: 'Privacy Policy',
        link: true,
        onTap: () => context.pushNamed('$routePrefix${Routes.privacy}'),
      ),
    ],
  );

  Widget _legal() {
    if (page == InformationPage.terms) {
      return ListView(
        padding: EdgeInsets.fromLTRB(10.w, 20.w, 12.w, 12.w),
        children: [
          for (var i = 0; i < _terms.length; i++) ...[
            if (i > 0) SizedBox(height: 20.w),
            Text(
              _terms[i].$2,
              style: AppTextStyles.text(
                16,
                color: AppColors.gray900,
                height: 25 / 16,
              ),
            ),
          ],
        ],
      );
    }
    return ListView(
      padding: EdgeInsets.only(top: 14.w, bottom: 4.w),
      children: [
        Text(
          _privacy[0].$2,
          style: AppTextStyles.text(
            16,
            color: AppColors.gray900,
            height: 25 / 16,
          ),
        ),
        SizedBox(height: 32.w),
        for (var i = 1; i < _privacy.length; i++) ...[
          if (i > 1) SizedBox(height: 24.w),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24.w,
                child: Text(
                  '$i.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w600,
                    color: AppColors.gray900,
                    height: 27 / 16,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _privacy[i].$1.substring(3),
                  style: AppTextStyles.text(
                    16,
                    weight: FontWeight.w600,
                    color: AppColors.gray900,
                    height: 27 / 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: (i < 3 ? 12 : 6).w),
          if (i < 3)
            for (final (index, line) in _privacy[i].$2.split('\n').indexed) ...[
              if (index > 0) SizedBox(height: 8.w),
              _privacyBullet(line.substring(3), highlightLabel: i == 1),
            ]
          else
            Text(
              _privacy[i].$2,
              style: AppTextStyles.text(
                16,
                color: AppColors.muted,
                height: 25 / 16,
              ),
            ),
        ],
      ],
    );
  }

  Widget _privacyBullet(String text, {required bool highlightLabel}) {
    final colon = text.indexOf(':');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 25.w,
          child: Center(
            child: Container(
              width: (highlightLabel ? 4 : 2).w,
              height: (highlightLabel ? 4 : 2).w,
              decoration: BoxDecoration(
                color: highlightLabel ? AppColors.gray900 : AppColors.muted,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (highlightLabel && colon >= 0) ...[
                  TextSpan(
                    text: text.substring(0, colon + 1),
                    style: const TextStyle(color: AppColors.gray900),
                  ),
                  TextSpan(text: text.substring(colon + 1)),
                ] else
                  TextSpan(text: text),
              ],
            ),
            style: AppTextStyles.text(
              16,
              color: AppColors.muted,
              height: 25 / 16,
            ),
          ),
        ),
      ],
    );
  }

  static const _questions = [
    (
      'What can I do with this app?',
      'You can search properties, post listings, save favorites, contact sellers or agents.',
    ),
    (
      'Are the property listings verified?',
      'Submitted properties go through viability and document review before approval.',
    ),
    (
      'Is there a cost to use the app?',
      'You can submit your land at no upfront cost. Any proposal will explain its terms.',
    ),
    (
      'Can I edit or delete my listing?',
      'You can edit your saved draft before submitting. Contact the property team for help with a submitted property.',
    ),
    (
      'How do I save properties I like?',
      'Saved investment properties will be available in the future Investor experience.',
    ),
    (
      'How do I upgrade to premium?',
      'There is no premium upgrade in the Landowner experience.',
    ),
    (
      'How do I get support?',
      'Open Live Chat to speak with the property team.',
    ),
  ];
  static const _onboardingTerms = [
    (
      'Overview',
      'Welcome to Developify! By creating an account and utilizing our platform, you agree to adhere to these Terms of Service. Please review them thoroughly before engaging with our services.',
    ),
    (
      'User Eligibility',
      'To access our services, you must be at least 18 years old and comply with the laws applicable in your jurisdiction. By registering, you confirm that you meet these criteria.',
    ),
    (
      'Account Creation',
      'You must provide accurate and current information during the registration process. It is your responsibility to protect your account credentials. We reserve the right to suspend or terminate accounts that violate these Terms of Service.',
    ),
    (
      'Investment Warning',
      'The content available on this platform is for educational and informational purposes only. We do not provide financial, legal, or tax advice. You are responsible for conducting your own due diligence before making any investment decisions. Investments carry risks, and past performance does not guarantee future results.',
    ),
  ];
  static const _privacy = [
    (
      '',
      'We value your trust and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and protect your data when you use our app.',
    ),
    (
      '1. Information We Collect',
      '•  Personal Details: Name, email, phone number, address.\n•  Usage Data: App interactions, preferences, and search history.\n•  Device Info: IP address, device type, operating system.',
    ),
    (
      '2. How We Use Your Data',
      '•  To improve your app experience.\n•  To personalize recommendations and offers.\n•  To process payments and orders.',
    ),
    (
      '3. Data Security',
      'We do not sell your personal data. We may share limited data with trusted partners to process payments or improve services, under strict confidentiality.',
    ),
    (
      '4. Sharing Your Information',
      'We do not sell your personal data. We may share limited data with trusted partners to process payments or improve services, under strict confidentiality.',
    ),
    (
      '5. Cookies & Tracking',
      'We use cookies to enhance app functionality and analyze usage patterns. You can manage cookie preferences in your device settings.',
    ),
  ];
  static const _terms = [
    (
      '',
      'By accessing or using this Real Estate Mobile App, you agree to comply with and be bound by these Terms & Conditions. If you do not agree, please do not use the app. This app allows users to search, view, post, and manage real estate listings. You agree to use the app only for lawful purposes and in accordance with applicable laws.',
    ),
    (
      '1. User Accounts',
      'You are responsible for maintaining the confidentiality of your login details. You agree to provide accurate and complete information during registration. The app reserves the right to suspend or terminate accounts for misuse or false information.',
    ),
    (
      '2. Property Listings',
      'Property details are provided by owners, agents, or developers. The app does not guarantee the accuracy, completeness, or legality of listings. Users are advised to independently verify property information before making decisions.',
    ),
  ];
}
