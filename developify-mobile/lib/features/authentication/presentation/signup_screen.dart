import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/password_strength_meter.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/phone_number_field.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/signup_store.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/landowner_consent.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/landowner_entity_choices.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.store});
  final SignupStore store;
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.store.choosingEntity) {
      widget.store.returnToDetails();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.welcome);
    }
  }

  Future<void> _terms() async {
    final accepted = await context.pushNamed<bool>(
      Routes.legal,
      queryParameters: {'return': 'signup'},
    );
    if (mounted && accepted == true) widget.store.acceptTerms(true);
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final choosing = widget.store.choosingEntity;
      return PopScope<Object?>(
        canPop: !choosing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && choosing) widget.store.returnToDetails();
        },
        child: Scaffold(
          appBar: AppPageAppBar(
            title: choosing ? 'Who owns the land?' : 'Create landowner account',
            leadingInset: 22,
            titleCenterOffset: choosing ? -7 : 5,
            onBack: _back,
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                key: ValueKey(
                  choosing ? 'signup-entity-scroll' : 'signup-form-scroll',
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (choosing)
                          Padding(
                            padding: EdgeInsets.fromLTRB(12.w, 19.w, 12.w, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 343.w,
                                  child: Text(
                                    "Pick the entity that legally holds the property. This determines the extra documents you'll need.",
                                    style: AppTextStyles.text(
                                      16,
                                      color: AppColors.muted,
                                      height: 19 / 16,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 19.w),
                                Observer(
                                  builder: (_) => LandownerEntityChoices(
                                    selected: widget.store.entity,
                                    onChanged: widget.store.selectEntity,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _SignupDetails(store: widget.store, onTerms: _terms),
                        Observer(
                          builder: (_) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: InlineError(widget.store.error),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 24.w, 12.w, 13.w),
                          child: Observer(
                            builder: (_) => AppButton(
                              key: const ValueKey('create-landowner-account'),
                              label: 'Create account',
                              loading:
                                  widget.store.status == LoadStatus.loading,
                              onPressed: choosing
                                  ? () =>
                                        unawaited(widget.store.createAccount())
                                  : widget.store.canAttemptDetails
                                  ? widget.store.continueToEntity
                                  : null,
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
        ),
      );
    },
  );
}

class _SignupDetails extends StatelessWidget {
  const _SignupDetails({required this.store, required this.onTerms});
  final SignupStore store;
  final VoidCallback onTerms;

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final (
        left,
        right,
        top,
        fieldsGap,
        consentGap,
        meterWidth,
      ) = switch (store.appearance) {
        SignupAppearance.empty => (12.0, 12.0, 26.0, 19.0, 32.0, 360.0),
        SignupAppearance.filled => (14.0, 13.0, 24.0, 24.0, 28.0, 360.0),
        SignupAppearance.accepted => (14.0, 14.0, 19.0, 15.0, 33.0, 360.0),
        SignupAppearance.invalid => (12.0, 12.0, 19.0, 31.0, 19.0, 369.0),
      };
      return Padding(
        padding: EdgeInsets.fromLTRB(left.w, top.w, right.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 343.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get started',
                    style: AppTextStyles.text(
                      32,
                      weight: FontWeight.w700,
                      color: AppColors.black,
                      height: 38 / 32,
                    ),
                  ),
                  SizedBox(height: 7.w),
                  Text(
                    "Takes about 2 minutes. You'll submit property documents after your account is set up",
                    style: AppTextStyles.text(
                      16,
                      color: AppColors.muted,
                      height: 19 / 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: fieldsGap.w),
            _SignupFields(store: store),
            SizedBox(height: 14.w),
            Align(
              alignment:
                  store.appearance == SignupAppearance.empty ||
                      store.appearance == SignupAppearance.invalid
                  ? Alignment.centerLeft
                  : Alignment.center,
              child: SizedBox(
                width: meterWidth.w,
                child: Observer(
                  builder: (_) => PasswordStrengthMeter(
                    filledSegments: store.passwordStrength,
                    invalid: store.invalidCredentials,
                  ),
                ),
              ),
            ),
            SizedBox(height: consentGap.w),
            Observer(
              builder: (_) => LandownerConsent(
                accepted: store.acceptedTerms,
                onChanged: store.acceptTerms,
                onTerms: onTerms,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SignupFields extends StatelessWidget {
  const _SignupFields({required this.store});
  final SignupStore store;

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      children: [
        for (final (index, field) in [
          Observer(
            builder: (_) => AppField(
              label: 'Full Name',
              hint: 'Enter Full Name',
              value: store.name,
              onChanged: store.setName,
              autofillHints: const [AutofillHints.name],
            ),
          ),
          Observer(
            builder: (_) => AppField(
              label: 'Email Address',
              hint: 'e.g Thomashook@gmail.com',
              value: store.email,
              onChanged: store.setEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
          ),
          Observer(
            builder: (_) => PhoneNumberField(
              value: store.phone,
              countryCode: store.countryCode,
              onChanged: store.setPhone,
              onCountryChanged: store.setCountry,
            ),
          ),
          Observer(
            builder: (_) => AppField(
              label: 'Password',
              hint: 'Min. of 8 characters',
              value: store.password,
              onChanged: store.setPassword,
              obscure: !store.passwordVisible,
              invalid: store.invalidCredentials,
              errorColor: AppColors.rose600,
              fillColor: store.invalidCredentials
                  ? AppColors.rose100
                  : AppColors.surface,
              autofillHints: const [AutofillHints.newPassword],
              suffix: PasswordVisibilityButton(
                solid: true,
                visible: store.passwordVisible,
                onPressed: store.togglePassword,
                color: store.invalidCredentials ? AppColors.errorDark : null,
              ),
            ),
          ),
          Observer(
            builder: (_) => AppField(
              label: 'Confirm Password',
              hint: 'Min. of 8 characters',
              value: store.confirmation,
              onChanged: store.setConfirmation,
              obscure: !store.confirmationVisible,
              invalid: store.invalidCredentials,
              errorColor: AppColors.rose600,
              fillColor: store.invalidCredentials
                  ? AppColors.rose100
                  : AppColors.surface,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => store.continueToEntity(),
              suffix: PasswordVisibilityButton(
                solid: true,
                visible: store.confirmationVisible,
                onPressed: store.toggleConfirmation,
                color: store.invalidCredentials ? AppColors.errorDark : null,
              ),
            ),
          ),
        ].indexed) ...[
          if (index > 0) SizedBox(height: 21.w),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 67.w),
            child: field,
          ),
        ],
      ],
    ),
  );
}
