import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';

class SignupHeading extends StatelessWidget {
  const SignupHeading({super.key, required this.title, this.centered = false});
  final String title;
  final bool centered;
  @override
  Widget build(BuildContext context) => Text(
    title,
    textAlign: centered ? TextAlign.center : TextAlign.start,
    style: AppTextStyles.text(
      32,
      weight: FontWeight.w700,
      color: AppColors.black,
      height: 38 / 32,
    ),
  );
}

class SignupSecurityContent extends StatelessWidget {
  const SignupSecurityContent({super.key, required this.store});
  final InvestorSignupStore store;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final stage = store.stage;
      final biometric = stage == InvestorSignupStage.biometrics;
      final setup = biometric || stage == InvestorSignupStage.face;
      final completed = stage == InvestorSignupStage.complete;
      return Padding(
        padding: EdgeInsets.only(
          top:
              (biometric
                      ? 17
                      : setup
                      ? 29
                      : 26)
                  .w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: biometric ? 13.w : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignupHeading(
                    title: completed
                        ? 'Account ready'
                        : biometric
                        ? 'Set Up Biometrics'
                        : setup
                        ? 'Setup Face ID'
                        : 'Verification in progress',
                  ),
                  SizedBox(height: 7.w),
                  SizedBox(
                    width: 343.w,
                    child: Text(
                      completed
                          ? 'Your demo investor profile is ready. Continue to open your account.'
                          : biometric
                          ? 'Enable fingerprint authentication to access your account faster and add an extra layer of security to your app experience.'
                          : setup
                          ? 'Activate Face ID for a faster, safer, and more convenient way to access your investments.'
                          : 'Avoid closing the app while we securely confirm your identity for a safe and seamless experience.',
                      style: AppTextStyles.text(
                        16,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height:
                  (biometric
                          ? 89.5
                          : setup
                          ? 76.5
                          : 102)
                      .w,
            ),
            Center(
              child: completed
                  ? const AppIcon(AppAssets.investorSuccess, size: 128)
                  : setup
                  ? Padding(
                      padding: EdgeInsets.only(left: (biometric ? 2 : 8).w),
                      child: SvgPicture.asset(
                        biometric
                            ? AppAssets.investorFingerprintSetup
                            : AppAssets.investorFaceSetup,
                        width: 176.w,
                        height: 165.w,
                        excludeFromSemantics: true,
                      ),
                    )
                  : SizedBox.square(
                      dimension: 84.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CircularProgressIndicator(
                              value: store.faceProgress / 100,
                              strokeWidth: 4.w,
                              strokeAlign:
                                  CircularProgressIndicator.strokeAlignInside,
                              backgroundColor: AppColors.primary.withValues(
                                alpha: .12,
                              ),
                              color: AppColors.primary,
                              semanticsLabel: 'Simulated identity check',
                            ),
                          ),
                          const AppIcon(
                            AppAssets.investorFaceVerification,
                            size: 35,
                          ),
                        ],
                      ),
                    ),
            ),
            if (!setup && !completed) ...[
              SizedBox(height: 24.w),
              Center(
                child: Text(
                  store.faceProgress == 100
                      ? 'Face Verification Completed'
                      : 'In Progress (${store.faceProgress}%)',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.text(
                    14,
                    weight: FontWeight.w500,
                    color: AppColors.black,
                    height: 17 / 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class SignupFingerprintContent extends StatelessWidget {
  const SignupFingerprintContent({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SvgPicture.asset(
                  AppAssets.investorFingerprintBeam,
                  width: 393.w,
                  height: 523.w,
                  fit: BoxFit.fill,
                ),
              ),
              Column(
                children: [
                  SizedBox(height: 45.w),
                  const SignupHeading(title: 'Fingerprint', centered: true),
                  SizedBox(height: 7.w),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 57.w),
                    child: Text(
                      'Tap the fingerprint to try demo setup. No sensor is used.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.text(
                        16,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    ),
                  ),
                  const Spacer(flex: 5),
                  SizedBox(height: 144.w),
                  Semantics(
                    button: true,
                    label: 'Simulate fingerprint setup',
                    child: InkResponse(
                      onTap: onContinue,
                      child: SizedBox.square(
                        dimension: 120.w,
                        child: Transform.translate(
                          offset: Offset(12.w, 18.w),
                          child: OverflowBox(
                            maxWidth: 152.w,
                            maxHeight: 156.w,
                            child: Image.asset(
                              AppAssets.investorFingerprintScan,
                              width: 152.w,
                              height: 156.w,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45.w),
                    child: Text(
                      'By trying demo setup, read our',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.text(
                        16,
                        color: AppColors.muted,
                        height: 19 / 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45.w),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          style: _legalLinkStyle,
                          onPressed: () => context.pushNamed('investor-terms'),
                          child: const Text('Terms'),
                        ),
                        Text(' & ', style: AppTextStyles.body),
                        TextButton(
                          style: _legalLinkStyle,
                          onPressed: () =>
                              context.pushNamed('investor-privacy'),
                          child: const Text('Privacy'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.w),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  ButtonStyle get _legalLinkStyle => TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(44, 44),
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.text(16),
  );
}

class SignupCameraPreview extends StatelessWidget {
  const SignupCameraPreview({
    super.key,
    required this.onBack,
    required this.onCapture,
  });
  final VoidCallback onBack;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                      height: 44.w,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 2.w,
                            top: -5.w,
                            child: Semantics(
                              button: true,
                              label: 'Back',
                              child: InkResponse(
                                onTap: onBack,
                                child: SizedBox.square(
                                  dimension: 44,
                                  child: const Center(
                                    child: AppIcon(
                                      AppAssets.investorCameraBack,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(50.w, 8.w, 50.w, 0),
                              child: Text(
                                'Verify your identity',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.text(
                                  16,
                                  weight: FontWeight.w500,
                                  color: AppColors.white,
                                  height: 19 / 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5.w),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        'Demo preview · sample image',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.text(
                          14,
                          weight: FontWeight.w500,
                          color: AppColors.borderStrong,
                          height: 17 / 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 98.w),
                    Padding(
                      padding: EdgeInsets.only(right: 19.w),
                      child: Image.asset(
                        AppAssets.investorFacePreview,
                        width: 240.w,
                        height: 240.w,
                        semanticLabel:
                            'Sample portrait for simulated face verification',
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: 40.w),
                    Padding(
                      padding: EdgeInsets.only(right: 19.w),
                      child: Semantics(
                        button: true,
                        label: 'Simulate face capture',
                        child: InkResponse(
                          onTap: onCapture,
                          child: Container(
                            width: 80.w,
                            height: 80.w,
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.black,
                                  width: 2.w,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 56.w),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
