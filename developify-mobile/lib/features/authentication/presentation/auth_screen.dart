import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/assets/app_assets.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/app_icon.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/auth_store.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/auth_social_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.store,
    this.returning = false,
    this.routePrefix = '',
    this.showSocial = true,
  });
  final AuthStore store;
  final bool returning;
  final String routePrefix;
  final bool showSocial;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passwordFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    if (widget.returning) widget.store.prepareReturning();
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    widget.store.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.store.status == LoadStatus.loading) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('${widget.routePrefix}${Routes.welcome}');
    }
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) => PopScope(
      canPop: widget.store.status != LoadStatus.loading,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: widget.returning
              ? PreferredSize(
                  preferredSize: Size.fromHeight(44.w),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 44.w,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12.w),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: widget.store.status == LoadStatus.loading
                                ? null
                                : () => context.goNamed(
                                    '${widget.routePrefix}${Routes.signIn}',
                                  ),
                            child: SizedBox(
                              height: 44.w,
                              child: Padding(
                                padding: EdgeInsets.only(top: 7.w),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text:
                                              'Not ${widget.store.returningName}, ',
                                        ),
                                        TextSpan(
                                          text: 'Logout?',
                                          style:
                                              widget.routePrefix == 'investor-'
                                              ? AppTextStyles.text(
                                                  16,
                                                  weight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                  height: 19 / 16,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                    style: AppTextStyles.text(
                                      16,
                                      weight: widget.routePrefix == 'investor-'
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: AppColors.muted,
                                      height: 19 / 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : AppPageAppBar(onBack: _back),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          (widget.returning ? 12 : 13).w,
                          (widget.returning ? 20 : 17).w,
                          (widget.returning ? 12 : 9).w,
                          0,
                        ),
                        child: _credentials(),
                      ),
                      if (!widget.returning)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 22.w),
                            Center(
                              child: InkWell(
                                key: const ValueKey('auth-sign-up'),
                                onTap: widget.store.status == LoadStatus.loading
                                    ? null
                                    : () => context.pushNamed(
                                        '${widget.routePrefix}${Routes.signUp}',
                                      ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 44,
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    widthFactor: 1,
                                    heightFactor: 1,
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: 'Don’t have an account?  ',
                                          ),
                                          TextSpan(
                                            text: 'Sign Up',
                                            style: AppTextStyles.text(
                                              16,
                                              weight: FontWeight.w600,
                                              color: AppColors.primary,
                                              height: 19 / 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.text(
                                        16,
                                        color: AppColors.muted,
                                        height: 19 / 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
  );

  Widget _credentials() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        widget.returning ? 'Welcome ${widget.store.returningName}' : 'Sign In',
        style: AppTextStyles.text(
          32,
          weight: FontWeight.w700,
          color: AppColors.black,
          height: 38 / 32,
        ),
      ),
      SizedBox(height: 17.w),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 343.w),
        child: Text(
          widget.returning
              ? 'Enter your password to log into your account'
              : 'Sign in to securely access your account, manage your activities, and enjoy a seamless experience tailored just for you.',
          style: AppTextStyles.text(
            16,
            color: widget.returning ? AppColors.black : AppColors.muted,
            height: 19 / 16,
          ),
        ),
      ),
      SizedBox(height: 24.w),
      AutofillGroup(
        child: Column(
          children: [
            if (!widget.returning) ...[
              Observer(
                builder: (_) => AppField(
                  label: 'Email Address',
                  hint: 'e.g Thomashook@gmail.com',
                  value: widget.store.email,
                  readOnly: widget.store.status == LoadStatus.loading,
                  onChanged: widget.store.setEmail,
                  error: widget.store.emailError,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
              ),
              SizedBox(height: 22.w),
            ],
            Observer(
              builder: (_) => AppField(
                label: 'Password',
                focusNode: _passwordFocus,
                hint: 'Min. of 8 characters',
                value: widget.store.password,
                readOnly: widget.store.status == LoadStatus.loading,
                onChanged: widget.store.setPassword,
                obscure: !widget.store.passwordVisible,
                error: widget.store.passwordError,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => widget.store.signIn(),
                suffix: PasswordVisibilityButton(
                  visible: widget.store.passwordVisible,
                  onPressed: widget.store.toggleVisibility,
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 4.5.w),
      SizedBox(
        height: 44.w,
        child: InkWell(
          onTap: widget.store.status == LoadStatus.loading
              ? null
              : () => context.pushNamed(
                  '${widget.routePrefix}${Routes.recovery}',
                ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.text(
                16,
                weight: FontWeight.w600,
                color: AppColors.primary,
                height: 19 / 16,
              ),
            ),
          ),
        ),
      ),
      Observer(builder: (_) => InlineError(widget.store.error)),
      SizedBox(height: (widget.returning ? 34.5 : 9.5).w),
      Padding(
        padding: EdgeInsets.only(right: widget.returning ? 0 : 2.w),
        child: Observer(
          builder: (_) => AppButton(
            key: const ValueKey('auth-submit'),
            label: widget.returning ? 'Log in' : 'Sign In',
            loading: widget.store.status == LoadStatus.loading,
            onPressed: widget.store.canSubmit
                ? () => widget.store.signIn()
                : null,
          ),
        ),
      ),
      if (widget.returning) ...[
        SizedBox(height: 24.w),
        Center(
          child: InkWell(
            onTap: () {
              if (widget.store.status == LoadStatus.loading) return;
              _passwordFocus.requestFocus();
              showFeedback(
                context,
                'Enter your password to log into your account',
              );
            },
            child: SizedBox(
              height: 44.w,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppAssets.authBiometric, size: 24),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      'Use Biometric / Face ID',
                      style: AppTextStyles.text(
                        16,
                        weight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 19 / 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ] else if (widget.showSocial) ...[
        SizedBox(height: 55.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 13.w),
          child: SizedBox(
            height: 22.w,
            child: Row(
              children: [
                const Expanded(child: Divider(height: 1, thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Text(
                    'or',
                    style: AppTextStyles.text(
                      14,
                      color: AppColors.muted,
                      height: 22 / 14,
                    ).copyWith(letterSpacing: -1.sp),
                  ),
                ),
                const Expanded(child: Divider(height: 1, thickness: 1)),
              ],
            ),
          ),
        ),
        SizedBox(height: 28.w),
        Observer(
          builder: (_) => AuthSocialButton(
            provider: 'Google',
            icon: AppAssets.authGoogle,
            onPressed: widget.store.status == LoadStatus.loading
                ? null
                : () => widget.store.signIn(socialProvider: 'Google'),
          ),
        ),
        SizedBox(height: 16.w),
        Observer(
          builder: (_) => AuthSocialButton(
            provider: 'Apple',
            icon: AppAssets.authApple,
            onPressed: widget.store.status == LoadStatus.loading
                ? null
                : () => widget.store.signIn(socialProvider: 'Apple'),
          ),
        ),
      ],
    ],
  );
}
