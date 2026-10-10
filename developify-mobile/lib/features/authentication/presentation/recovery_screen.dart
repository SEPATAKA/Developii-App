import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:developify_mobile/app/router/route_names.dart';
import 'package:developify_mobile/core/errors/result.dart';
import 'package:developify_mobile/core/theme/app_theme.dart';
import 'package:developify_mobile/core/widgets/app_button.dart';
import 'package:developify_mobile/core/widgets/app_chrome.dart';
import 'package:developify_mobile/core/widgets/app_field.dart';
import 'package:developify_mobile/core/widgets/password_visibility_button.dart';
import 'package:developify_mobile/core/widgets/password_strength_meter.dart';
import 'package:developify_mobile/core/widgets/states.dart';
import 'package:developify_mobile/core/widgets/feedback.dart';
import 'package:developify_mobile/features/authentication/presentation/stores/recovery_store.dart';
import 'package:developify_mobile/features/authentication/presentation/widgets/recovery_success_sheet.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key, required this.store, this.routePrefix = ''});
  final RecoveryStore store;
  final String routePrefix;
  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>?
  _notice;
  late final _password = TextEditingController(text: widget.store.password);
  late final _confirmation = TextEditingController(
    text: widget.store.confirmation,
  );

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    widget.store.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.store.status == LoadStatus.loading) return;
    _notice?.close();
    _notice = null;
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.store.stage > 0) {
      widget.store.back();
      _password.clear();
      _confirmation.clear();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('${widget.routePrefix}${Routes.signIn}');
    }
  }

  Future<void> _submit() async {
    _notice?.close();
    _notice = null;
    FocusManager.instance.primaryFocus?.unfocus();
    final stage = widget.store.stage;
    final complete = await widget.store.submit();
    if (mounted &&
        widget.routePrefix == 'investor-' &&
        stage == 0 &&
        widget.store.stage == 1) {
      final notice = showSimulationNotice(
        context,
        'Demo recovery: use 123456. No email is sent.',
      );
      _notice = notice;
      unawaited(
        notice.closed.then((_) {
          if (identical(_notice, notice)) _notice = null;
        }),
      );
    }
    if (!mounted || !complete) return;
    _password.clear();
    _confirmation.clear();
    await showRecoverySuccessSheet(context);
    if (mounted) context.goNamed('${widget.routePrefix}${Routes.signIn}');
  }

  @override
  Widget build(BuildContext context) => Observer(
    builder: (_) {
      final stage = widget.store.stage;
      final codeRejected = widget.store.codeRejected;
      return PopScope(
        canPop: stage == 0 && widget.store.status != LoadStatus.loading,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
          appBar: AppPageAppBar(onBack: _back),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (_, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            13.w,
                            (stage == 1 && !codeRejected ? 21 : 18).w,
                            (stage == 0 ? 12 : 14).w,
                            0,
                          ),
                          child: _content(),
                        ),
                        const Spacer(),
                        SizedBox(height: 24.w),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          child: Observer(
                            builder: (_) => AppButton(
                              key: const ValueKey('recovery-continue'),
                              label: 'Continue',
                              loading:
                                  widget.store.status == LoadStatus.loading,
                              onPressed: widget.store.canContinue
                                  ? _submit
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(
                          height:
                              (MediaQuery.viewInsetsOf(context).bottom > 0
                                      ? 76
                                      : 14)
                                  .w,
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

  Widget _content() {
    final store = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            'Recover your account',
            'Confirm account reset',
            'Set a new password',
          ][store.stage],
          style: AppTextStyles.text(
            32,
            weight: FontWeight.w700,
            color: AppColors.black,
            height: 38 / 32,
          ),
        ),
        SizedBox(height: 17.w),
        Observer(
          builder: (_) => ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: widget.routePrefix == 'investor-'
                  ? (store.stage == 0 ? 76 : 38).w
                  : 0,
            ),
            child: Text(
              store.stage == 0
                  ? 'Enter the email address linked to your account to receive a secure verification code or recovery instructions and regain access to your account quickly and safely.'
                  : 'Enter verification code sent  to  ${store.maskedEmail} regain access to your account quickly and safely.',
              style: AppTextStyles.text(
                16,
                color: store.stage < 2
                    ? AppColors.muted
                    : store.password.isEmpty
                    ? AppColors.neutral500
                    : AppColors.neutral600,
                height: 19 / 16,
              ),
            ),
          ),
        ),
        SizedBox(height: (store.stage == 2 ? 21 : 31).w),
        if (store.stage == 0)
          Observer(
            builder: (_) => AppField(
              label: 'Email Address',
              hint: 'e.g Thomashook@gmail.com',
              value: store.email,
              readOnly: store.status == LoadStatus.loading,
              onChanged: store.setEmail,
              error: store.emailError,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          )
        else if (store.stage == 1) ...[
          Observer(
            builder: (_) => CodeField(
              length: 6,
              enabled: store.status != LoadStatus.loading,
              value: store.code,
              onChanged: store.setCode,
              invalid: store.codeRejected,
              onSubmitted: _submit,
            ),
          ),
          SizedBox(height: (store.codeRejected ? 10.5 : 5.5).w),
          Observer(
            builder: (_) => SizedBox(
              height: 44.w,
              child: Center(
                child: InkWell(
                  onTap: store.resendSeconds == 0 ? store.resend : null,
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
                            height: 19 / 16,
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
        ] else ...[
          for (var i = 0; i < 2; i++) ...[
            if (i > 0) SizedBox(height: 21.w),
            Observer(
              builder: (_) => AppField(
                label: i == 0 ? 'Password' : 'Confirm new Password',
                hint: 'Min. of 8 characters',
                value: i == 0 ? store.password : store.confirmation,
                controller: i == 0 ? _password : _confirmation,
                readOnly: store.status == LoadStatus.loading,
                onChanged: i == 0 ? store.setPassword : store.setConfirmation,
                obscure: !(i == 0
                    ? store.passwordVisible
                    : store.confirmationVisible),
                invalid: store.passwordInvalid,
                errorColor: AppColors.rose600,
                fillColor: store.passwordInvalid
                    ? AppColors.rose100
                    : AppColors.surface,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: i == 0
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: i == 0 ? null : (_) => _submit(),
                suffix: PasswordVisibilityButton(
                  visible: i == 0
                      ? store.passwordVisible
                      : store.confirmationVisible,
                  onPressed: i == 0
                      ? store.togglePassword
                      : store.toggleConfirmation,
                ),
              ),
            ),
          ],
          SizedBox(height: 21.w),
          Observer(
            builder: (_) => SizedBox(
              width: (store.passwordInvalid ? 364.5 : 360).w,
              child: PasswordStrengthMeter(
                filledSegments: store.passwordStrength,
                invalid: store.passwordInvalid,
                activeColor: AppColors.green500,
                labelColor: AppColors.placeholder,
                barLeadingInset: store.passwordInvalid ? 4.5 : 0,
              ),
            ),
          ),
        ],
        Observer(
          builder: (_) => InlineError(
            store.codeRejected || store.passwordRejected ? null : store.error,
          ),
        ),
      ],
    );
  }
}

class CodeField extends StatefulWidget {
  const CodeField({
    super.key,
    required this.length,
    required this.value,
    required this.onChanged,
    this.obscure = false,
    this.invalid = false,
    this.onSubmitted,
    this.enabled = true,
  });
  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final bool invalid;
  final VoidCallback? onSubmitted;
  final bool enabled;
  @override
  State<CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<CodeField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  final _focus = FocusNode();
  @override
  void didUpdateWidget(covariant CodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.obscure ? 'Security code' : 'Verification code',
    hint: widget.invalid ? 'Incorrect code' : null,
    child: SizedBox(
      height: 55.245285.w.clamp(
        MediaQuery.textScalerOf(context).scale(49.sp) + 6.245.w,
        double.infinity,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Row(
                  children: [
                    for (var index = 0; index < widget.length; index++) ...[
                      if (index > 0) SizedBox(width: 6.90566.w),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.invalid
                                ? AppColors.rose100
                                : AppColors.surface,
                            border: Border.all(
                              color: widget.invalid
                                  ? AppColors.rose600
                                  : AppColors.borderStrong,
                              width: .8632076.w,
                            ),
                            borderRadius: BorderRadius.circular(20.716982.w),
                          ),
                          child: widget.obscure && index < widget.value.length
                              ? Container(
                                  width: 10.w,
                                  height: 10.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: widget.invalid
                                        ? AppColors.rose600
                                        : AppColors.body,
                                  ),
                                )
                              : Text(
                                  index < widget.value.length
                                      ? widget.value[index]
                                      : '',
                                  style: AppTextStyles.text(
                                    41.433964,
                                    weight: FontWeight.w700,
                                    color: widget.invalid
                                        ? AppColors.rose600
                                        : AppColors.body,
                                    height: 49 / 41.433964,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: TextField(
              controller: _controller,
              readOnly: !widget.enabled,
              focusNode: _focus,
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSubmitted?.call(),
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              obscureText: widget.obscure,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: widget.obscure
                  ? null
                  : const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(widget.length),
              ],
              style: AppTextStyles.text(24, color: AppColors.transparent),
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: AppColors.transparent,
                filled: true,
                labelText: null,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
