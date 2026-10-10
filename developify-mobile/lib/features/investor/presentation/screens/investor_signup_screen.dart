import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/authentication/presentation/recovery_screen.dart';
import 'package:developify_mobile/features/investor/presentation/investor_route_names.dart';
import 'package:developify_mobile/features/investor/presentation/stores/investor_signup_store.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/signup_details.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/signup_progress_header.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/signup_result_sheet.dart';
import 'package:developify_mobile/features/investor/presentation/widgets/signup_security_content.dart';
import 'package:developify_mobile/features/shared/domain/app_user.dart';

class InvestorSignupScreen extends StatefulWidget {
  const InvestorSignupScreen({super.key, required this.store});
  final InvestorSignupStore store;
  @override
  State<InvestorSignupScreen> createState() => _InvestorSignupScreenState();
}

class _InvestorSignupScreenState extends State<InvestorSignupScreen> {
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>?
  _notice;
  InvestorSignupStore get store => widget.store;
  late final _changeContact = TapGestureRecognizer()..onTap = _back;

  @override
  void dispose() {
    _changeContact.dispose();
    super.dispose();
  }

  void _back() {
    if (store.busy) return;
    _notice?.close();
    _notice = null;
    FocusManager.instance.primaryFocus?.unfocus();
    if (store.stage != InvestorSignupStage.details) {
      store.back();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(InvestorRoutes.welcome);
    }
  }

  Future<void> _create() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await store.createProfile();
    if (mounted && store.stage == InvestorSignupStage.verification) {
      final notice = showSimulationNotice(
        context,
        'Demo verification: use 123456. No email or SMS is sent.',
      );
      _notice = notice;
      unawaited(
        notice.closed.then((_) {
          if (identical(_notice, notice)) _notice = null;
        }),
      );
    }
  }

  Future<void> _verify() async {
    _notice?.close();
    _notice = null;
    FocusManager.instance.primaryFocus?.unfocus();
    final success = await store.verify();
    if (!mounted || !success) return;
    await showSignupResultSheet(context, store: store);
    if (mounted) store.continueVerified();
  }

  Future<void> _complete() async {
    if (store.stage != InvestorSignupStage.complete) store.completeSecurity();
    if (store.stage == InvestorSignupStage.complete) {
      await showSignupResultSheet(context, store: store, accountReady: true);
    }
  }

  void _continuePin() {
    if (store.continuePin()) FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final stage = store.stage;
      final companyDetails =
          stage == InvestorSignupStage.details &&
          store.entity == EntityType.company;
      final multipleRepresentatives =
          companyDetails && store.representatives.length > 1;
      final singleRepresentative =
          companyDetails && store.representatives.length == 1;
      return PopScope(
        canPop: !store.busy && stage == InvestorSignupStage.details,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: stage == InvestorSignupStage.faceCamera
            ? SignupCameraPreview(
                onBack: _back,
                onCapture: () => store.captureFace(
                  reduceMotion: MediaQuery.disableAnimationsOf(context),
                ),
              )
            : AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.dark,
                child: Scaffold(
                  appBar: SignupProgressHeader(
                    step: store.stepNumber,
                    onBack: _back,
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                  body: SafeArea(
                    top: false,
                    child: stage == InvestorSignupStage.fingerprint
                        ? SignupFingerprintContent(
                            onContinue: store.continueBiometrics,
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                                  key: ValueKey('signup-scroll-${stage.name}'),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12.w,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (stage ==
                                                InvestorSignupStage.details)
                                              SignupDetails(store: store)
                                            else if (stage ==
                                                    InvestorSignupStage
                                                        .verification ||
                                                stage ==
                                                    InvestorSignupStage
                                                        .verified)
                                              Observer(
                                                builder: (_) => _verification(),
                                              )
                                            else if (stage ==
                                                InvestorSignupStage.pin)
                                              Observer(builder: (_) => _pin())
                                            else
                                              SignupSecurityContent(
                                                store: store,
                                              ),
                                            Observer(
                                              builder: (_) =>
                                                  InlineError(store.error),
                                            ),
                                            const Spacer(),
                                            SizedBox(
                                              height: multipleRepresentatives
                                                  ? 50.w
                                                  : 24.w,
                                            ),
                                            Observer(
                                              builder: (_) => _actions(),
                                            ),
                                            SizedBox(
                                              height: singleRepresentative
                                                  ? 33.w
                                                  : 6.w,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          ),
                  ),
                ),
              ),
      );
    },
  );

  Widget _verification() => Padding(
    padding: EdgeInsets.fromLTRB(2.w, 21.w, 0, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupHeading(title: 'Verification'),
        SizedBox(height: 7.w),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Enter the code sent to\n'),
              TextSpan(
                text:
                    '${store.values['email']} / ${store.dialCode} ${store.values['phone']}.  ',
                style: AppTextStyles.text(16, weight: FontWeight.w700),
              ),
              TextSpan(
                text: 'Change',
                recognizer: _changeContact,
                style: AppTextStyles.text(16, color: AppColors.primary),
              ),
            ],
          ),
          style: AppTextStyles.text(
            16,
            color: AppColors.muted,
            height: 19 / 16,
          ),
        ),
        SizedBox(height: 19.w),
        CodeField(
          length: 6,
          enabled: !store.busy,
          value: store.code,
          invalid: store.codeRejected,
          onChanged: store.setCode,
          onSubmitted: _verify,
        ),
        SizedBox(height: 17.w),
        Semantics(
          button: true,
          child: InkWell(
            onTap: store.resendSeconds == 0 && !store.busy
                ? () {
                    store.resend();
                    showFeedback(
                      context,
                      'Verification code simulated. Use 123456.',
                    );
                  }
                : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Align(
                alignment: Alignment.center,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Didn’t get it?  '),
                      TextSpan(
                        text: store.resendSeconds > 0
                            ? 'Resend in 0:${store.resendSeconds.toString().padLeft(2, '0')}'
                            : 'Resend code',
                        style: AppTextStyles.text(
                          16,
                          weight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  style: AppTextStyles.text(
                    16,
                    color: AppColors.iconMuted,
                    height: 19 / 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _pin() => Padding(
    padding: EdgeInsets.fromLTRB(2.w, 19.w, 0, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SignupHeading(title: 'Create 4-digit PIN'),
        SizedBox(height: 7.w),
        SizedBox(
          width: 343.w,
          child: Text(
            'Create a 4-digit pin to authorize investment and withdrawals',
            style: AppTextStyles.text(
              16,
              color: AppColors.muted,
              height: 19 / 16,
            ),
          ),
        ),
        SizedBox(height: 25.w),
        Center(
          child: SizedBox(
            width: 241.698.w,
            child: CodeField(
              length: 4,
              value: store.pin,
              obscure: true,
              invalid: store.error != null,
              onChanged: store.setPin,
              onSubmitted: _continuePin,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actions() {
    final stage = store.stage;
    if (stage == InvestorSignupStage.faceProcessing) {
      return const SizedBox.shrink();
    }
    final VoidCallback? action = switch (stage) {
      InvestorSignupStage.details => store.detailsFilled ? _create : null,
      InvestorSignupStage.verification =>
        store.code.length == 6 && !store.codeRejected ? _verify : null,
      InvestorSignupStage.verified => store.continueVerified,
      InvestorSignupStage.pin => store.pin.length == 4 ? _continuePin : null,
      InvestorSignupStage.biometrics => store.beginFingerprint,
      InvestorSignupStage.face => store.beginFace,
      InvestorSignupStage.faceComplete ||
      InvestorSignupStage.complete => _complete,
      _ => null,
    };
    return Column(
      children: [
        AppButton(
          key: const ValueKey('investor-signup-continue'),
          label: switch (stage) {
            InvestorSignupStage.details => 'Create account',
            InvestorSignupStage.verification => 'Verify',
            _ => 'Continue',
          },
          loading: store.busy,
          onPressed: action,
        ),
        if (stage == InvestorSignupStage.biometrics ||
            stage == InvestorSignupStage.face) ...[
          SizedBox(height: 19.w),
          AppButton(
            label: 'Maybe Later',
            style: AppButtonStyle.secondary,
            onPressed: stage == InvestorSignupStage.biometrics
                ? store.continueBiometrics
                : _complete,
          ),
        ],
      ],
    );
  }
}
